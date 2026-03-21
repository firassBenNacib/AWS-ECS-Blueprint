#!/usr/bin/env python3
"""Render a stable Terraform PR summary comment from result JSON files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


STATUS_LABELS = {
    "changes": "changes",
    "no_changes": "no changes",
    "error": "error",
    "skipped": "skipped",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", required=True)
    parser.add_argument("--run-url", required=True)
    parser.add_argument("--checks-url", required=True)
    return parser.parse_args()


def load_results(results_dir: Path) -> list[dict]:
    results = []
    for path in sorted(results_dir.rglob("*.json")):
        results.append(json.loads(path.read_text()))
    return sorted(results, key=lambda item: item.get("label", item.get("slug", "")))


def format_count(value: int | None) -> str:
    if value is None:
        return "-"
    return str(value)


def build_comment(results: list[dict], run_url: str, checks_url: str) -> str:
    lines = [
        "<!-- terraform-pr-plan -->",
        "## Terraform PR Plan",
        "",
        f"Workflow: [current run]({run_url})",
        f"Scanner checks: [pull request checks]({checks_url})",
        "",
    ]

    if not results:
        lines.append("No Terraform plan targets were selected for this pull request.")
        return "\n".join(lines)

    lines.extend(
        [
            "| Target | Status | Add | Change | Destroy | Artifacts |",
            "| --- | --- | ---: | ---: | ---: | --- |",
        ]
    )

    for item in results:
        status = STATUS_LABELS.get(item.get("status", ""), item.get("status", "unknown"))
        plan_artifact = item.get("plan_artifact_name", "-")
        result_artifact = item.get("result_artifact_name", "-")
        artifact_text = f"`{plan_artifact}`, `{result_artifact}` ([run]({run_url}))"
        lines.append(
            "| {target} | {status} | {add} | {change} | {destroy} | {artifacts} |".format(
                target=item.get("label", item.get("slug", "unknown")),
                status=status,
                add=format_count(item.get("add")),
                change=format_count(item.get("change")),
                destroy=format_count(item.get("destroy")),
                artifacts=artifact_text,
            )
        )

    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    results = load_results(Path(args.results_dir))
    print(build_comment(results, args.run_url, args.checks_url))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
