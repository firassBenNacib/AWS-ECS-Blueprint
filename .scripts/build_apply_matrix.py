#!/usr/bin/env python3
"""Build a GitHub Actions apply matrix from saved plan result artifacts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", required=True)
    parser.add_argument("--github-output", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    results = []
    for path in sorted(Path(args.results_dir).glob("*.json")):
        results.append(json.loads(path.read_text()))

    apply_ready = [item for item in results if item.get("status") == "plan_ready"]
    payload = {"include": apply_ready}

    with Path(args.github_output).open("a", encoding="utf-8") as fh:
        fh.write(f"apply_matrix={json.dumps(payload, separators=(',', ':'))}\n")
        fh.write(f"apply_count={len(apply_ready)}\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
