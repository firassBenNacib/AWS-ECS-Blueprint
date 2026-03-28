#!/usr/bin/env python3
"""Build a GitHub Actions apply matrix from deploy plan result artifacts."""

from __future__ import annotations

import argparse
import json

from path_safety import resolve_existing_dir, resolve_github_output_file


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", required=True)
    parser.add_argument("--github-output", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    results_dir = resolve_existing_dir(args.results_dir, description="deploy results directory")
    github_output = resolve_github_output_file(args.github_output)
    results = []
    for path in sorted(results_dir.glob("*.json")):
        results.append(json.loads(path.read_text(encoding="utf-8")))

    apply_ready = [item for item in results if item.get("status") == "plan_ready"]
    payload = {"include": apply_ready}

    with github_output.open("a", encoding="utf-8") as fh:
        fh.write(f"apply_matrix={json.dumps(payload, separators=(',', ':'))}\n")
        fh.write(f"apply_count={len(apply_ready)}\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
