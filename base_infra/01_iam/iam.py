#!/usr/bin/env python3
"""
base_infra/01_iam/iam.py

Pulumi IAM provisioning for AutoOpsScaler.

- Loads & validates base_configs/iam.yml via pathlib
- Provisions OIDC providers, IAM Roles, and Instance Profiles per config
- Supports assume_role_policy: github_oidc, irsa, or classic service principal
- Applies global tags for consistency
- Inlines Pydantic models—no external module imports
- Idempotent, error-checked, and uses Pulumi AWS SDK

Usage:
  cd base_infra/01_iam
  pulumi up
"""

import json
import logging
from pathlib import Path
from typing import Optional, List, Dict, Any, Literal

import pulumi
import pulumi_aws as aws
import yaml
from pydantic import BaseModel, Field, validator, root_validator

# Configure logging
logger = logging.getLogger("iam_provisioner")
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


# === Pydantic Models ===

class GlobalTags(BaseModel):
    owner: Optional[str]
    project: str

    @validator("project")
    def must_be_autoopsscaler(cls, v):
        if v != "autoopsscaler":
            raise ValueError("project tag must be 'autoopsscaler'")
        return v


class InlinePolicyStatement(BaseModel):
    Effect: Literal["Allow", "Deny"]
    Action: List[str]
    Resource: Any


class InlinePolicy(BaseModel):
    Version: str
    Statement: List[InlinePolicyStatement]

    @validator("Version")
    def version_ok(cls, v):
        if v != "2012-10-17":
            raise ValueError("Inline policy version must be '2012-10-17'")
        return v


class Role(BaseModel):
    name: Optional[str]
    description: str
    assume_role_policy: Optional[Literal["github_oidc", "irsa"]]
    service_principal: Optional[str]
    managed_policies: Optional[List[str]] = []
    max_session_duration: Optional[int]
    service_account: Optional[str]
    inline_policies: Optional[Dict[str, InlinePolicy]] = {}

    @root_validator
    def check_consistency(cls, values):
        arp, sp, sa = values.get("assume_role_policy"), values.get("service_principal"), values.get("service_account")
        if arp == "github_oidc" and (sp or sa):
            raise ValueError("github_oidc roles must not set service_principal or service_account")
        if arp == "irsa":
            if not sa or sp:
                raise ValueError("irsa roles must set service_account only")
        if arp is None and not sp:
            raise ValueError("roles without assume_role_policy must define service_principal")
        return values

    @validator("max_session_duration")
    def duration_ok(cls, v):
        if v is not None and not (3600 <= v <= 43200):
            raise ValueError("max_session_duration must be 3600–43200")
        return v


class InstanceProfile(BaseModel):
    name: Optional[str]
    role: str


class OIDCProvider(BaseModel):
    url: str
    client_ids: List[str]
    thumbprints: List[str]

    @validator("url")
    def url_https(cls, v):
        if not v.startswith("https://"):
            raise ValueError("OIDC provider URL must start with https://")
        return v

    @validator("client_ids", "thumbprints")
    def non_empty(cls, v):
        if not v:
            raise ValueError("Lists must not be empty")
        return v


class IAMConfig(BaseModel):
    project: str
    global_tags: GlobalTags
    roles: Dict[str, Role]
    instance_profiles: Dict[str, InstanceProfile]
    oidc_providers: Dict[str, OIDCProvider]

    @validator("project")
    def slug_ok(cls, v):
        if v != v.lower() or " " in v:
            raise ValueError("project slug must be lowercase, no spaces")
        return v

    @root_validator
    def check_refs(cls, values):
        roles, ips = values.get("roles", {}), values.get("instance_profiles", {})
        role_names = {r.name or k for k, r in roles.items()}
        for ip_key, ip in ips.items():
            if ip.role not in roles and ip.role not in role_names:
                raise ValueError(f"InstanceProfile '{ip_key}' references unknown role '{ip.role}'")
        if values["global_tags"].project != values["project"]:
            raise ValueError("global_tags.project must match top-level project")
        return values


# === Helpers ===

def load_config() -> IAMConfig:
    cfg_path = Path(__file__).parent.parent.parent / "base_configs" / "iam.yml"
    if not cfg_path.is_file():
        raise FileNotFoundError(f"Config not found: {cfg_path}")
    raw = yaml.safe_load(cfg_path.open(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("Top-level YAML must be a dict")
    cfg = IAMConfig.parse_obj(raw)
    logger.info("IAM configuration validated")
    return cfg


def build_service_assume(role: Role) -> str:
    return json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": role.service_principal},
            "Action": "sts:AssumeRole"
        }]
    })


def build_github_oidc_assume(oidc_arn: str) -> str:
    # Broad trust for GitHub OIDC provider; customize Condition as needed
    return json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Federated": oidc_arn},
            "Action": "sts:AssumeRoleWithWebIdentity"
        }]
    })


def build_irsa_assume(oidc_arn: str, sa: str) -> str:
    namespace, name = sa.split("/", 1)
    prefix = oidc_arn.split("oidc-provider/")[1]
    return json.dumps({
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Federated": oidc_arn},
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    f"{prefix}:sub": f"system:serviceaccount:{namespace}:{name}"
                }
            }
        }]
    })


# === Provisioning ===

def main():
    cfg = load_config()
    tags = cfg.global_tags.dict(exclude_none=True)

    # 1) Create OIDC providers
    oidc_objs: Dict[str, aws.iam.OpenIdConnectProvider] = {}
    for key, o in cfg.oidc_providers.items():
        oidc_objs[key] = aws.iam.OpenIdConnectProvider(
            resource_name=key,
            url=o.url,
            client_id_lists=o.client_ids,
            thumbprint_lists=o.thumbprints,
            tags=tags,
        )

    # 2) Create IAM Roles
    role_objs: Dict[str, aws.iam.Role] = {}
    caller = aws.get_caller_identity()
    for key, role_cfg in cfg.roles.items():
        rname = role_cfg.name or key

        # Determine assume role policy
        if role_cfg.assume_role_policy == "github_oidc":
            # We expect a GitHub OIDC provider entry in cfg.oidc_providers
            if "github" not in oidc_objs:
                raise RuntimeError("Config missing 'github' OIDC provider for GitHub OIDC roles")
            assume = build_github_oidc_assume(oidc_objs["github"].arn)
        elif role_cfg.assume_role_policy == "irsa":
            # We pick the first non-github OIDC provider for IRSA, if any
            irsa_providers = [v for k, v in oidc_objs.items() if k != "github"]
            if not irsa_providers:
                raise RuntimeError("No OIDC provider found for IRSA roles")
            assume = build_irsa_assume(irsa_providers[0].arn, role_cfg.service_account)
        else:
            assume = build_service_assume(role_cfg)

        role = aws.iam.Role(
            resource_name=rname,
            name=rname,
            assume_role_policy=assume,
            description=role_cfg.description,
            max_session_duration=role_cfg.max_session_duration or 3600,
            tags=tags,
        )
        role_objs[key] = role

        # Attach managed policies
        for idx, arn in enumerate(role_cfg.managed_policies or []):
            aws.iam.RolePolicyAttachment(
                resource_name=f"{rname}-mp-{idx}",
                role=role.name,
                policy_arn=arn,
                opts=pulumi.ResourceOptions(parent=role),
            )

        # Attach inline policies
        for pol_name, pol in (role_cfg.inline_policies or {}).items():
            aws.iam.RolePolicy(
                resource_name=f"{rname}-ip-{pol_name}",
                role=role.name,
                policy=pol.json(),
                opts=pulumi.ResourceOptions(parent=role),
            )

    # 3) Create Instance Profiles
    for key, ip in cfg.instance_profiles.items():
        if ip.role not in role_objs:
            raise RuntimeError(f"InstanceProfile '{key}' references unknown role '{ip.role}'")
        aws.iam.InstanceProfile(
            resource_name=ip.name or key,
            name=ip.name or key,
            role=role_objs[ip.role].name,
            tags=tags,
        )

    pulumi.log.info("IAM provisioning complete.")

if __name__ == "__main__":
    main()
