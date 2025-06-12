# Loads and merges schema + environment overrides


import os
import yaml
import importlib.util
from pathlib import Path
from typing import Any, Dict

from config.infra_schema.root_schema import InfraConfig
from pydantic import ValidationError

ROOT_DIR = Path(__file__).resolve().parent.parent.parent
CONFIG_DIR = ROOT_DIR / "config"
ENV_DIR = CONFIG_DIR / "environments"
BASE_CONFIG_FILE = CONFIG_DIR / "base_config.yaml"

def deep_merge_dicts(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    """Recursively deep merge override into base."""
    result = base.copy()
    for k, v in override.items():
        if isinstance(v, dict) and isinstance(result.get(k), dict):
            result[k] = deep_merge_dicts(result[k], v)
        else:
            result[k] = v
    return result

def load_yaml_config(filepath: Path) -> Dict[str, Any]:
    with filepath.open("r") as f:
        return yaml.safe_load(f) or {}

def load_env_override(env_name: str) -> Dict[str, Any]:
    """Dynamically load config/environments/{env}.py as a dict"""
    module_path = ENV_DIR / f"{env_name}.py"
    if not module_path.exists():
        raise FileNotFoundError(f"Environment override file not found: {module_path}")

    spec = importlib.util.spec_from_file_location(f"config.environments.{env_name}", str(module_path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # type: ignore

    if not hasattr(module, "config"):
        raise AttributeError(f"{module_path} must define a `config` dict")

    return getattr(module, "config")

def load_and_merge_config(env: str) -> InfraConfig:
    base_cfg = load_yaml_config(BASE_CONFIG_FILE)
    override_cfg = load_env_override(env)
    merged_cfg = deep_merge_dicts(base_cfg, override_cfg)

    try:
        return InfraConfig(**merged_cfg)
    except ValidationError as e:
        print("\n❌ Configuration is invalid:\n")
        print(e)
        raise

# For direct CLI/debug use
if __name__ == "__main__":
    import sys
    import json

    if len(sys.argv) != 2:
        print("Usage: python loader.py <env>")
        sys.exit(1)

    env = sys.argv[1]
    cfg = load_and_merge_config(env)
    print("\n✅ Parsed InfraConfig:\n")
    print(json.dumps(cfg.dict(), indent=2))

