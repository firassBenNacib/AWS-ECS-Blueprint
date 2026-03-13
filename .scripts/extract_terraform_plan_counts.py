#!/usr/bin/env python3
"""Extract add/change/destroy counts from terraform plan text."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("plan_file")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    text = Path(args.plan_file).read_text(encoding="utf-8")
    match = re.search(r"Plan:\s+(\d+)\s+to add,\s+(\d+)\s+to change,\s+(\d+)\s+to destroy\.", text)
    if not match:
        print("0 0 0")
        return 0

    print(" ".join(match.groups()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
