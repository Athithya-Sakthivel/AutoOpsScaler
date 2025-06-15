import importlib.util
import sys
from pathlib import Path
from functools import lru_cache
from types import ModuleType
from typing import Literal

from rich.console import Console
from rich.traceback import install
from pydantic import ValidationError

install()
console = Console()

# Adjust these paths if structure ever changes
CONFIG_DIR = Path(__file__).resolve().parent.parent / "config"
SCHEMA_DIR = CONFIG_DIR / "infra_schema"
ENV_DIR = CONFIG_DIR / "environments"
SECRETS_TEMPLATE = CONFIG_DIR / "secrets_template.py"

# Add config/ to sys.path so that dynamic imports work cleanly
if str(CONFIG_DIR) not in sys.path:
    sys.path.insert(0, str(CONFIG_DIR))

# Import InfraConfig from root_schema
try:
    spec = importlib.util.spec_from_file_location("root_schema", SCHEMA_DIR / "root_schema.py")
    root_schema = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(root_schema)
    InfraConfig = root_schema.InfraConfig
except Exception as e:
    console.print(f"[bold red]❌ Failed to load root_schema.InfraConfig[/bold red]: {e}")
    raise SystemExit(1)

def _load_env_module(env: Literal["dev", "prod"]) -> ModuleType:
    env_file = ENV_DIR / f"{env}.py"
    if not env_file.exists():
        console.print(f"[bold red]❌ Environment override not found:[/bold red] {env_file}")
        raise FileNotFoundError(f"Missing override file: {env_file}")
    
    spec = importlib.util.spec_from_file_location(f"{env}_overrides", env_file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

@lru_cache(maxsize=2)
def load_config(env: Literal["dev", "prod"] = "dev") -> InfraConfig:
    """
    Loads and validates the full InfraConfig for the given environment.
    This includes base schema + env overrides + secrets template (if present).
    Returns a fully validated `InfraConfig` Pydantic model.
    """
    try:
        # Load overrides as a plain dict from config/environments/{env}.py
        overrides_module = _load_env_module(env)
        if not hasattr(overrides_module, "config_overrides"):
            console.print(f"[yellow]⚠️ No `config_overrides` found in {env}.py. Using empty overrides.[/yellow]")
            config_overrides = {}
        else:
            config_overrides = overrides_module.config_overrides
    except Exception as e:
        console.print(f"[bold red]❌ Failed to load environment overrides for {env}[/bold red]: {e}")
        raise

    try:
        # Load and parse the final config using InfraConfig schema
        config = InfraConfig(**config_overrides)
    except ValidationError as ve:
        console.print("[bold red]❌ Validation failed for InfraConfig[/bold red]")
        console.print(ve.json(indent=2))
        raise

    console.print(f"[green]✅ Loaded and validated InfraConfig for environment:[/green] {env}")
    return config

# Optional: load secrets template (for CI-safe scaffolding or Vault integration)
@lru_cache(maxsize=1)
def load_secrets_template() -> dict:
    """
    Loads the static secrets_template.py (used as a placeholder for Vault or CI).
    Returns a dictionary of secret scaffolding (keys but no values).
    """
    if not SECRETS_TEMPLATE.exists():
        console.print(f"[yellow]⚠️ Secrets template not found at {SECRETS_TEMPLATE}. Skipping.[/yellow]")
        return {}

    try:
        spec = importlib.util.spec_from_file_location("secrets_template", SECRETS_TEMPLATE)
        secrets = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(secrets)
        return getattr(secrets, "SECRETS_TEMPLATE", {})
    except Exception as e:
        console.print(f"[bold red]❌ Failed to load secrets template:[/bold red] {e}")
        return {}
