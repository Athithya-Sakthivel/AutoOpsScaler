# utils/logger.py

import logging
from rich.console import Console
from rich.logging import RichHandler

_LOG_FORMAT = "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

console = Console()

def get_logger(name: str = "AutoOpsScaler", level: int = logging.INFO) -> logging.Logger:
    """Return a structured, rich-enhanced logger scoped by name."""
    logger = logging.getLogger(name)

    # Prevent duplicate handlers in interactive/debug sessions
    if not logger.handlers:
        handler = RichHandler(console=console, markup=True, show_path=False)
        formatter = logging.Formatter(fmt=_LOG_FORMAT, datefmt=_DATE_FORMAT)
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(level)
        logger.propagate = False  # Avoid double logs from root logger

    return logger
