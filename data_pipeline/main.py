# Path: ELT/main.py


import os
import yaml
import logging
import ray
from ray import workflow

from typing import Any, Dict

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "data_pipeline_config.yml")


def load_config(config_path: str) -> Dict[str, Any]:
    """
    Load YAML config and resolve ${env.*} variables from environment.
    """
    with open(config_path, "r") as f:
        raw_config = yaml.safe_load(f)

    def resolve_env_vars(obj):
        if isinstance(obj, dict):
            return {k: resolve_env_vars(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [resolve_env_vars(i) for i in obj]
        elif isinstance(obj, str):
            # Substitute ${env.VAR} with os.environ.get('VAR')
            import re

            pattern = r"\$\{env\.([A-Za-z0-9_]+)\}"
            matches = re.findall(pattern, obj)
            for var in matches:
                env_value = os.environ.get(var, "")
                obj = obj.replace(f"${{env.{var}}}", env_value)
            return obj
        else:
            return obj

    resolved_config = resolve_env_vars(raw_config)
    return resolved_config


def setup_logging(level: str):
    """
    Setup logging with specified level and a standard format.
    """
    numeric_level = getattr(logging, level.upper(), logging.INFO)
    logging.basicConfig(
        level=numeric_level,
        format="%(asctime)s - %(levelname)s - %(name)s - %(message)s",
    )


def init_ray(max_parallel_tasks: int):
    """
    Initialize Ray with resource limits and workflow enabled.
    """
    # ray.init(auto_init=True) can be replaced with explicit config if needed
    ray.init(ignore_reinit_error=True)
    workflow.init()

    # Optionally configure Ray with max_parallel_tasks
    # For now, just log this, as controlling concurrency needs custom Ray actors or queues.
    logging.info(f"Ray initialized with max_parallel_tasks={max_parallel_tasks}")


def main():
    # Step 2: Load config
    config = load_config(CONFIG_PATH)

    # Step 3: Setup logging
    logging_level = config.get("global", {}).get("logging_level", "INFO")
    setup_logging(logging_level)

    logger = logging.getLogger("main")
    logger.info("Starting main orchestration")

    # Validate extract_load enabled
    extract_load_enabled = config.get("extract_load", {}).get("enable", False)
    if not extract_load_enabled:
        logger.warning("extract_load module is disabled in config. Exiting.")
        return

    # Initialize Ray with max_parallel_tasks from config
    max_parallel_tasks = config.get("global", {}).get("max_parallel_tasks", 4)
    init_ray(max_parallel_tasks)

    # Placeholder: orchestrate extract_load modules (to be implemented later)
    logger.info("Setup complete. Ready to orchestrate extract_load modules.")


if __name__ == "__main__":
    main()
