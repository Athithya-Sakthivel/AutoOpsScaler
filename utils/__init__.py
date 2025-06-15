# utils/__init__.py
"""
Utility module initializer for shared helpers like config loader,
structured logger, S3 utilities, and file deduplicator.

Note: Keep this minimal to prevent circular import issues.
Do not import submodules here unless absolutely necessary.
"""

# Optional: expose key utility paths for easier import (deferred to usage)
# Example (commented out to avoid premature load-time resolution):
# from .logger import get_logger
# from .config_loader import load_config
