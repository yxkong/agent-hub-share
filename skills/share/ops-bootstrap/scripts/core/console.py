from __future__ import annotations

import os
import sys
from typing import Any


def color(text: str, name: str) -> str:
    if not sys.stdout.isatty() or os.environ.get("NO_COLOR"):
        return text
    codes = {
        "red": "31",
        "green": "32",
        "yellow": "33",
        "cyan": "36",
    }
    return f"\033[{codes[name]}m{text}\033[0m"


def info(text: str, name: str | None = None) -> None:
    print(color(text, name) if name else text)


def print_list(title: str, values: Any, *, indent: str = "  ") -> None:
    info(f"{indent}{title}:")
    if isinstance(values, list) and values:
        for value in values:
            info(f"{indent}  - {value}")
    elif isinstance(values, dict) and values:
        for key, value in values.items():
            info(f"{indent}  - {key}: {value}")
    else:
        info(f"{indent}  - none")
