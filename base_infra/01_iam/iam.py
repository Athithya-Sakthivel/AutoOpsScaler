#!/usr/bin/env python3
"""
base_infra/01_iam/iam.py

Pulumi IAM provisioning for AutoOpsScaler platform.

- Loads and validates base_configs/iam.yml via pathlib
- Defines IAM roles, instance profiles, and OIDC providers with Pulumi AWS provider
- Ensures strict validation, idempotency, and robust error handling
- Uses pathlib exclusively for path operations, no sys.exit()

"""

import logging
from pathlib import Path
from typing import Optional, List, Dict, Any, Literal

import pulumi
import pulumi_aws as aws
import yaml
from pydantic import BaseModel, Field, validator, root_validator

# Configure logging (Pulumi handles logging, but useful for dev/debug)
logger = logging.getLogger("iam_provisioner")
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

# === Pydantic Models (inline, simplified) ===

class GlobalTags(BaseModel):
    owner: Optional[str]
    project: str

    @validator("project")
    def project_must_be_autoopsscaler(cls, v):
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
    def version_must_be_2012_10_17(cls, v):
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
    def check_assume_role_policy_consistency(cls, values):
        arp = values.get("assume_role_policy")
        sp = values.get("service_principal")
        sa = values.get("service_account")

        if arp == "github_oidc":
            if sp is not None or sa is not None:
                raise ValueError("github_oidc roles cannot have service_principal or service_account")

        if arp == "irsa":
            if not sa:
                raise ValueError("irsa roles require service_account")
            if sp is not None:
                raise ValueError("irsa roles cannot have service_principal")

        if arp is None:
            if sp is None:
                raise ValueError("roles without assume_role_policy require service_principal")
            if sa is not None:
                raise ValueError("roles without assume_role_policy cannot have service_account")

        return values

    @validator("max_session_duration")
    def max_session_duration_range(cls, v):
        if v is not None and not (3600 <= v <= 43200):
            raise ValueError("max_session_duration must be between 3600 and 43200")
        return v


class InstanceProfile(BaseModel):
    name: Optional[str]
    role: str


class OIDCProvider(BaseModel):
    url: str
    client_ids: List[str]
    thumbprints: List[str]

    @validator("url")
    def url_must_be_https(cls, v):
        if not v.startswith("https://"):
            raise ValueError("OIDC provider url must start with https://")
        return v

    @validator("client_ids", "thumbprints")
    def lists_not_empty(cls, v):
        if not v or len(v) == 0:
            raise ValueError("List must not be empty")
        return v


class IAMConfig(BaseModel):
    project: str
    global_tags: GlobalTags
    roles: Dict[str, Role]
    instance_profiles: Dict[str, InstanceProfile]
    oidc_providers: Dict[str, OIDCProvider]

    @validator("project")
    def project_slug_lowercase_no_spaces(cls, v):
        if v != v.lower() or " " in v:
            raise ValueError("Project slug must be lowercase and contain no spaces")
        return v

    @root_validator
    def check_roles_and_instance_profiles(cls, values):
        roles = values.get("roles", {})
        instance_profiles = values.get("instance_profiles", {})

        # Validate unique role names (either role.name or dict key)
        role_names = set()
        for key, role in roles.items():
            rname = role.name or key
            if rname in role_names:
                raise ValueError(f"Duplicate role name found: {rname}")
            role_names.add(rname)

        # Instance profiles must reference valid role names
        for ip_key, ip in instance_profiles.items():
            if ip.role not in roles and ip.role not in role_names:
                raise ValueError(f"Instance profile '{ip_key}' references unknown role '{ip.role}'")

        # global_tags.project must match top-level project
        global_tags = values.get("global_tags")
        project = values.get("project")
        if global_tags and global_tags.project != project:
            raise ValueError("global_tags.project must match top-level project")

        return values


# === Helpers ===

def load_yaml_config(path: Path) -> dict:
    if not path.is_file():
        raise FileNotFoundError(f"Config file not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ValueError("Top-level YAML structure must be a dictionary")
    return data


def get_assume_role_policy_document(role: Role, project_slug: str) -> str:
    """
    Returns JSON policy document string for assume role policy based on the role config.
    """

    import json

    # Use known templates for assume_role_policy values

    if role.assume_role_policy == "github_oidc":
        # GitHub OIDC trust policy (example, update thumbprint and audience accordingly)
        # Pulumi requires JSON string or dict
        doc = {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": {"Federated": f"arn:aws:iam::{aws.get_caller_identity().account_id}:oidc-provider/token.actions.githubusercontent.com"},
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringLike": {
                        "token.actions.githubusercontent.com:sub": "repo:autoopsscaler/*:ref:refs/heads/main"
                    }
                }
            }]
        }
        return json.dumps(doc)

    elif role.assume_role_policy == "irsa":
        # IRSA trust policy for Kubernetes ServiceAccount

        namespace, sa_name = role.service_account.split("/", 1)

        oidc_provider_arn = f"arn:aws:iam::{aws.get_caller_identity().account_id}:oidc-provider/oidc.eks.{aws.config.region}.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"  # Placeholder - user must update or dynamically detect

        # For production, you must replace oidc_provider_arn above with actual cluster OIDC provider ARN, or read from config

        doc = {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": {"Federated": oidc_provider_arn},
                "Action": "sts:AssumeRoleWithWebIdentity",
                "Condition": {
                    "StringEquals": {
                        f"oidc.eks.{aws.config.region}.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041:sub": f"system:serviceaccount:{namespace}:{sa_name}"
                    }
                }
            }]
        }
        return json.dumps(doc)

    else:
        # Classic service principal trust policy
        doc = {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": {"Service": role.service_principal},
                "Action": "sts:AssumeRole"
            }]
        }
        return json.dumps(doc)


def main():
    try:
        base_dir = Path(__file__).parent.parent.parent.resolve()
        config_path = base_dir / "base_configs" / "iam.yml"

        logger.info(f"Loading IAM config from {config_path}")
        raw_cfg = load_yaml_config(config_path)

        iam_config = IAMConfig.parse_obj(raw_cfg)
        logger.info("IAM config validation successful.")

        project_slug = iam_config.project
        global_tags = iam_config.global_tags.dict(exclude_none=True)

        # --- Create IAM Roles ---

        role_objects = {}
        for role_key, role in iam_config.roles.items():
            # Determine role name, fallback to key
            role_name = role.name or role_key

            assume_role_policy_json = get_assume_role_policy_document(role, project_slug)

            # Create AWS IAM Role resource
            role_res = aws.iam.Role(
                resource_name=role_name,
                name=role_name,
                assume_role_policy=assume_role_policy_json,
                description=role.description,
                max_session_duration=role.max_session_duration or 3600,
                tags=global_tags,
                opts=pulumi.ResourceOptions(
                    retain_on_delete=False
                )
            )

            # Attach managed policies if any
            for managed_policy_arn in role.managed_policies or []:
                aws.iam.RolePolicyAttachment(
                    resource_name=f"{role_name}-managedpolicy-{managed_policy_arn.split('/')[-1]}",
                    role=role_res.name,
                    policy_arn=managed_policy_arn,
                    opts=pulumi.ResourceOptions(parent=role_res)
                )

            # Attach inline policies if any
            for inline_name, inline_policy in (role.inline_policies or {}).items():
                aws.iam.RolePolicy(
                    resource_name=f"{role_name}-inlinepolicy-{inline_name}",
                    role=role_res.name,
                    policy=inline_policy.json(),
                    opts=pulumi.ResourceOptions(parent=role_res)
                )

            role_objects[role_key] = role_res

        # --- Create Instance Profiles ---
        for ip_key, ip in iam_config.instance_profiles.items():
            # Map role name to resource
            role_name = ip.role
            if role_name not in role_objects:
                raise ValueError(f"InstanceProfile '{ip_key}' references unknown role '{role_name}'")

            ip_name = ip.name or ip_key

            aws.iam.InstanceProfile(
                resource_name=ip_name,
                name=ip_name,
                role=role_objects[role_name].name,
                tags=global_tags,
                opts=pulumi.ResourceOptions(
                    retain_on_delete=False
                )
            )

        # --- Create OIDC Providers ---
        for oidc_key, oidc in iam_config.oidc_providers.items():
            aws.iam.OpenIdConnectProvider(
                resource_name=oidc_key,
                url=oidc.url,
                client_id_list=oidc.client_ids,
                thumbprint_list=oidc.thumbprints,
                opts=pulumi.ResourceOptions(
                    retain_on_delete=False
                )
            )

        logger.info("Pulumi IAM provisioning complete.")

    except Exception as e:
        logger.error(f"Fatal error in IAM provisioning: {e}")
        raise


if __name__ == "__main__":
    main()
