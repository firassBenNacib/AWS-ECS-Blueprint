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


def format_count(value: int | None) -> str:
    if value is None:
        return "-"
    return str(value)


def format_cost(value: float | None, *, signed: bool = False) -> str:
    if value is None:
        return "-"
    if signed:
        return f"{value:+.2f} USD/mo"
    return f"{value:.2f} USD/mo"


def format_cost_cell(item: dict, field: str, *, signed: bool = False) -> str:
    value = item.get(field)
    if isinstance(value, (int, float)):
        return format_cost(float(value), signed=signed)

    cost_status = item.get("cost_status")
    if cost_status == "skipped":
        return "skipped"
    if cost_status == "error":
        return "error"
    return "-"


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
            "| Target | Status | Add | Change | Destroy | Monthly Cost | Delta | Artifacts |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
        ]
    )

    for item in results:
        status = STATUS_LABELS.get(item.get("status", ""), item.get("status", "unknown"))
        plan_artifact = item.get("plan_artifact_name", "-")
        result_artifact = item.get("result_artifact_name", "-")
        cost_artifact = item.get("cost_artifact_name")
        artifact_names = [f"`{plan_artifact}`", f"`{result_artifact}`"]
        if cost_artifact:
            artifact_names.append(f"`{cost_artifact}`")
        artifact_text = f"{', '.join(artifact_names)} ([run]({run_url}))"
        lines.append(
            "| {target} | {status} | {add} | {change} | {destroy} | {monthly_cost} | {monthly_cost_delta} | {artifacts} |".format(
                target=item.get("label", item.get("slug", "unknown")),
                status=status,
                add=format_count(item.get("add")),
                change=format_count(item.get("change")),
                destroy=format_count(item.get("destroy")),
                monthly_cost=format_cost_cell(item, "monthly_cost"),
                monthly_cost_delta=format_cost_cell(item, "monthly_cost_delta", signed=True),
                artifacts=artifact_text,
            )
        )

    if any(item.get("cost_status") in {"skipped", "error"} for item in results):
        lines.extend(
            [
                "",
                "Cost estimation notes:",
                "- `skipped`: `INFRACOST_API_KEY` was not configured or the target did not reach a usable Terraform plan.",
                "- `error`: Terraform planning succeeded but Infracost did not return a usable cost estimate.",
            ]
        )

    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    results = load_results(Path(args.results_dir))
    print(build_comment(results, args.run_url, args.checks_url))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
