# CLI entrypoint for infra generation


# config/generate_infra/cli.py

import typer
import sys
from pathlib import Path
from .main import run_render_pipeline
from .loader import load_config
from .config_validator import validate_infra_config
from utils.logger import get_logger

app = typer.Typer()
log = get_logger(__name__)

BASE_DIR = Path(__file__).resolve().parent.parent.parent
ENV_PATH = BASE_DIR / "config" / "environments"

@app.command()
def validate(env: str = typer.Argument(..., help="Target environment (e.g., dev or prod)")):
    """
    Validate merged configuration for a specific environment.
    """
    try:
        config = load_config(env)
        validate_infra_config(config)
        log.info(f"[✔] '{env}' config is valid.")
    except Exception as e:
        log.error(f"[✘] Config validation failed: {e}")
        sys.exit(1)

@app.command()
def render(env: str = typer.Argument(..., help="Target environment (e.g., dev or prod)")):
    """
    Render Pulumi modules and K8s manifests for the target environment.
    """
    try:
        config = load_config(env)
        validate_infra_config(config)
        run_render_pipeline(env, config)
        log.info(f"[✔] Infra code successfully rendered for '{env}'.")
    except Exception as e:
        log.error(f"[✘] Rendering failed: {e}")
        sys.exit(1)

@app.command()
def plan(env: str = typer.Argument(..., help="Target environment (e.g., dev or prod)")):
    """
    Print high-level summary of what would be rendered, without writing files.
    """
    try:
        config = load_config(env)
        validate_infra_config(config)
        log.info(f"Planning for environment: {env}")
        log.info(f"  - EKS Version: {config.eks.version}")
        log.info(f"  - Node Groups: {len(config.eks.nodegroups)}")
        log.info(f"  - VPC: {config.vpc.name} / {config.vpc.cidr_block}")
        log.info(f"  - Karpenter Provisioners: {len(config.karpenter.provisioners)}")
        log.info(f"  - Observability Enabled: {config.observability.enabled}")
    except Exception as e:
        log.error(f"[✘] Planning failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    app()

