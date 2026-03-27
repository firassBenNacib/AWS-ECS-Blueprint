#!/usr/bin/env python3
"""Check that prod-app and nonprod-app stay structurally aligned."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def extract_module_body(path: Path, module_name: str) -> str:
    text = path.read_text(encoding="utf-8")
    match = re.search(rf'module\s+"{re.escape(module_name)}"\s*\{{', text)
    if not match:
        raise ValueError(f"{path}: module {module_name!r} not found")

    start = match.end()
    depth = 1
    index = start
    while index < len(text) and depth > 0:
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        index += 1

    if depth != 0:
        raise ValueError(f"{path}: unbalanced braces while parsing module {module_name!r}")
    return text[start : index - 1]


def extract_top_level_assignments(body: str) -> set[str]:
    assignments: set[str] = set()
    depth = 0
    for raw_line in body.splitlines():
        line = raw_line.split("#", 1)[0].rstrip()
        if depth == 0:
            match = re.match(r"\s*([A-Za-z0-9_]+)\s*=", line)
            if match:
                assignments.add(match.group(1))
        depth += line.count("{") - line.count("}")
    return assignments


def main() -> int:
    prod_main = ROOT / "prod-app" / "main.tf"
    nonprod_main = ROOT / "nonprod-app" / "main.tf"

    prod_keys = extract_top_level_assignments(extract_module_body(prod_main, "app"))
    nonprod_keys = extract_top_level_assignments(extract_module_body(nonprod_main, "app"))

    only_prod = sorted(prod_keys - nonprod_keys)
    only_nonprod = sorted(nonprod_keys - prod_keys)

    if only_prod or only_nonprod:
        print("Root module parity check failed.")
        if only_prod:
            print("Keys only in prod-app module \"app\":")
            for key in only_prod:
                print(f"  - {key}")
        if only_nonprod:
            print("Keys only in nonprod-app module \"app\":")
            for key in only_nonprod:
                print(f"  - {key}")
        return 1

    print("Root module parity check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
