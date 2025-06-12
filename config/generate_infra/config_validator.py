# config/generate_infra/config_validator.py

from config.infra_schema.root_schema import InfraConfig
from rich import print
from typing import List


class ConfigValidationError(Exception):
    pass


def validate_config(config: InfraConfig) -> None:
    """Performs cross-field and logical validation on the loaded InfraConfig object."""

    errors: List[str] = []

    # --- Core Logical Validations ---

    # If karpenter is enabled, EKS IRSA must also be enabled
    if config.karpenter.enabled:
        if not config.eks.enable_irsa:
            errors.append("[karpenter] Karpenter requires EKS IRSA to be enabled.")

    # Karpenter provisioner names must be unique
    provisioner_names = [p.name for p in config.karpenter.provisioners]
    if len(provisioner_names) != len(set(provisioner_names)):
        errors.append("[karpenter] Provisioner names must be unique.")

    # If observability is enabled, Grafana must have dashboards or Prometheus must have scrape targets
    if config.observability.enabled:
        if not config.observability.prometheus.scrape_configs and not config.observability.grafana.dashboards:
            errors.append("[observability] At least one scrape config or dashboard must be defined.")

    # VPC validations
    if config.vpc.enable_nat_gateway and not config.vpc.create_private_subnets:
        errors.append("[vpc] NAT Gateway requires private subnets to be enabled.")

    # EKS version should not be below supported version
    min_eks_version = "1.27"
    if config.eks.version < min_eks_version:
        errors.append(f"[eks] EKS version must be >= {min_eks_version}, got: {config.eks.version}")

    # Enforce GPU provisioners to have allowed instance types only
    for p in config.karpenter.provisioners:
        if p.require_gpu and not any("g" in it for it in p.instance_types):
            errors.append(f"[karpenter] GPU provisioner '{p.name}' must use GPU instance types (like g4dn, a10g, etc).")

    # TODO: Add more validations as components are extended

    # --- Final check ---
    if errors:
        print("[bold red]❌ Config validation failed with the following issues:[/bold red]")
        for e in errors:
            print(f"  - {e}")
        raise ConfigValidationError("Config validation failed.")
    else:
        print("[bold green]✅ Config validated successfully![/bold green]")
