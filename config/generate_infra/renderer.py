# Renders Pulumi and K8s manifests from config


import os
import json
from pathlib import Path
from config.infra_schema.root_schema import InfraConfig
from rich import print
from typing import Any, Dict

# Constants for output paths
BASE_INFRA = Path("base_infra")
PULUMI_DIR = BASE_INFRA / "pulumi"
OBSERVABILITY_DIR = BASE_INFRA / "observability"


def write_file(path: Path, content: str) -> None:
    """Write content to file, ensuring parent dirs exist. Overwrites safely."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        f.write("# --- AUTO-GENERATED FILE. DO NOT EDIT. ---\n\n")
        f.write(content)


def render_vpc(config: InfraConfig, env: str) -> None:
    content = f"""# Pulumi VPC config for {env}
vpc_cidr = "{config.vpc.cidr_block}"
subnets = {config.vpc.subnets}
nat_enabled = {config.vpc.enable_nat_gateway}
"""
    write_file(PULUMI_DIR / "vpc" / "network.py", content)


def render_eks(config: InfraConfig, env: str) -> None:
    cluster_py = f"""# EKS cluster for {env}
eks_version = "{config.eks.version}"
enable_irsa = {config.eks.enable_irsa}
"""
    write_file(PULUMI_DIR / "eks" / "cluster.py", cluster_py)

    ng_py = f"""# EKS nodegroups for {env}
node_groups = {config.eks.nodegroups}
"""
    write_file(PULUMI_DIR / "eks" / "nodegroups.py", ng_py)


def render_karpenter(config: InfraConfig, env: str) -> None:
    controller = f"""# Karpenter controller config
enabled = {config.karpenter.enabled}
"""
    write_file(PULUMI_DIR / "karpenter" / "controller.py", controller)

    for p in config.karpenter.provisioners:
        file_name = f"provisioner_{p.name.lower()}.py"
        provisioner_py = f"""# Karpenter provisioner: {p.name}
instance_types = {p.instance_types}
archs = {p.architectures}
zones = {p.availability_zones}
require_gpu = {p.require_gpu}
"""
        write_file(PULUMI_DIR / "karpenter" / file_name, provisioner_py)


def render_observability(config: InfraConfig, env: str) -> None:
    prometheus_config = yaml_dump(config.observability.prometheus.scrape_configs)
    dashboards = json.dumps(config.observability.grafana.dashboards, indent=2)

    write_file(OBSERVABILITY_DIR / "scrape_configs.yaml", prometheus_config)
    write_file(OBSERVABILITY_DIR / "dashboards" / f"{env}.json", dashboards)


def render_pulumi_config(config: InfraConfig, env: str) -> None:
    meta = {
        "env": env,
        "eks_version": config.eks.version,
        "vpc_cidr": config.vpc.cidr_block,
        "karpenter_enabled": config.karpenter.enabled,
    }
    json_str = json.dumps(meta, indent=2)
    write_file(BASE_INFRA / "pulumi_config.json", json_str)


def yaml_dump(data: Any) -> str:
    """Safe YAML dump fallback (no external deps)."""
    import yaml
    return yaml.dump(data, default_flow_style=False)


def render_all(config: InfraConfig, env: str) -> None:
    """Top-level renderer function to render all infra components."""
    print(f"[cyan]🛠 Rendering Pulumi + K8s infra for env:[/cyan] [bold]{env}[/bold]")

    render_vpc(config, env)
    render_eks(config, env)
    render_karpenter(config, env)
    render_observability(config, env)
    render_pulumi_config(config, env)

    print("[bold green]✅ All infra components rendered successfully.[/bold green]")

