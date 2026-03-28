#!/usr/bin/env python3
"""Extract total/past/diff monthly cost values from Infracost JSON output."""

from __future__ import annotations

import argparse
import json
from decimal import Decimal, InvalidOperation

from path_safety import resolve_existing_file


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("infracost_json")
    return parser.parse_args()


def parse_decimal(value: object) -> Decimal | None:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return Decimal(str(value))
    if isinstance(value, str):
        text = value.strip()
        if not text or text.lower() == "null":
            return None
        try:
            return Decimal(text)
        except InvalidOperation:
            return None
    return None


def get_nested(mapping: dict[str, object], *keys: str) -> object:
    current: object = mapping
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def sum_project_values(projects: list[dict[str, object]], candidates: list[tuple[str, ...]]) -> Decimal | None:
    values: list[Decimal] = []
    for project in projects:
        parsed = None
        for candidate in candidates:
            parsed = parse_decimal(get_nested(project, *candidate))
            if parsed is not None:
                break
        if parsed is not None:
            values.append(parsed)
    if not values:
        return None
    return sum(values, Decimal("0"))


def format_decimal(value: Decimal | None) -> str:
    if value is None:
        return "null"
    normalized = format(value, "f")
    normalized = normalized.rstrip("0").rstrip(".")
    return normalized or "0"


def main() -> int:
    args = parse_args()
    infracost_json = resolve_existing_file(args.infracost_json, description="Infracost JSON file")
    data = json.loads(infracost_json.read_text(encoding="utf-8"))
    projects = data.get("projects") or []
    if not isinstance(projects, list):
        projects = []

    total = parse_decimal(data.get("totalMonthlyCost"))
    past = parse_decimal(data.get("pastTotalMonthlyCost"))
    diff = parse_decimal(data.get("diffTotalMonthlyCost"))

    typed_projects = [project for project in projects if isinstance(project, dict)]

    if total is None:
        total = sum_project_values(
            typed_projects,
            [
                ("breakdown", "totalMonthlyCost"),
                ("totalMonthlyCost",),
            ],
        )

    if past is None:
        past = sum_project_values(
            typed_projects,
            [
                ("pastBreakdown", "totalMonthlyCost"),
                ("pastTotalMonthlyCost",),
            ],
        )

    if diff is None:
        diff = sum_project_values(
            typed_projects,
            [
                ("diff", "totalMonthlyCost"),
                ("diffTotalMonthlyCost",),
            ],
        )

    print(f"{format_decimal(total)} {format_decimal(past)} {format_decimal(diff)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
