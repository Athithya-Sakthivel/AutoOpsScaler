# Orchestrates config parsing and infra rendering
from config.generate_infra.loader import load_merged_config
from config.generate_infra.config_validator import validate_config as logical_validate_config
from config.infra_schema.root_schema import InfraConfig
from config.generate_infra.renderer import render_all
from pydantic import ValidationError
from rich import print
import sys


def main(env: str) -> None:
    """Main entrypoint to generate infrastructure for the given environment."""
    print(f"[bold blue]🚀 Starting infrastructure generation for environment: [green]{env}[/green][/bold blue]")

    # Step 1: Load merged base + env config (dict)
    try:
        merged_dict = load_merged_config(env)
    except FileNotFoundError as e:
        print(f"[bold red]❌ Missing config file:[/bold red] {e}")
        sys.exit(1)

    # Step 2: Schema validation using Pydantic
    try:
        config = InfraConfig(**merged_dict)
    except ValidationError as e:
        print(f"[bold red]❌ Schema validation failed:[/bold red]")
        print(e.json(indent=2))
        sys.exit(1)

    # Step 3: Logical validations (cross-field, policy constraints)
    try:
        logical_validate_config(config)
    except Exception as e:
        print(f"[bold red]❌ Logical validation failed:[/bold red] {e}")
        sys.exit(1)

    # Step 4: Render Pulumi infra + K8s manifests
    try:
        render_all(config=config, env=env)
        print(f"[bold green]✅ Infrastructure rendered successfully for environment: [white]{env}[/white][/bold green]")
    except Exception as e:
        print(f"[bold red]❌ Rendering failed:[/bold red] {e}")
        sys.exit(1)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate infrastructure from config")
    parser.add_argument("--env", required=True, help="Environment name to render (e.g., dev, prod)")
    args = parser.parse_args()

    main(args.env)
