#!/usr/bin/env python3
"""Resolve Terraform target matrices for CI workflows."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


ALL_TARGET_TRIGGER_PREFIXES = (
    ".github/workflows/",
    "ci/",
    "modules/",
    ".scripts/",
)


def load_catalog(path: Path) -> list[dict]:
    data = json.loads(path.read_text())
    if not isinstance(data, list) or not data:
        raise ValueError(f"{path} must contain a non-empty JSON array")

    seen_ids = set()
    seen_paths = set()
    seen_slugs = set()
    for item in data:
        if not isinstance(item, dict):
            raise ValueError("catalog entries must be JSON objects")
        for key in (
            "id",
            "label",
            "path",
            "slug",
            "tfvars_file",
            "backend_key",
            "backend_region",
            "role_env_var",
            "deploy_environment",
            "aws_region",
        ):
            if key not in item or not item[key]:
                raise ValueError(f"catalog entry missing required key '{key}'")
        if "backend_config_file" not in item:
            raise ValueError("catalog entry missing required key 'backend_config_file'")
        if item["id"] in seen_ids:
            raise ValueError(f"duplicate target id: {item['id']}")
        if item["path"] in seen_paths:
            raise ValueError(f"duplicate target path: {item['path']}")
        if item["slug"] in seen_slugs:
            raise ValueError(f"duplicate target slug: {item['slug']}")
        seen_ids.add(item["id"])
        seen_paths.add(item["path"])
        seen_slugs.add(item["slug"])
    return data


def catalog_lookup(catalog: list[dict]) -> dict[str, dict]:
    return {item["id"]: dict(item) for item in catalog}


def git_changed_files(base_sha: str, head_sha: str) -> list[str]:
    if not base_sha or not head_sha or set(base_sha) == {"0"}:
        return []
    result = subprocess.run(
        ["git", "diff", "--name-only", f"{base_sha}...{head_sha}"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def select_changed_targets(catalog: list[dict], changed_files: list[str]) -> list[dict]:
    if not changed_files:
        return list(catalog)

    path_map = {item["path"]: item for item in catalog}
    selected_ids: list[str] = []
    select_all = False

    def add_target(target_id: str) -> None:
        if target_id not in selected_ids:
            selected_ids.append(target_id)

    for changed in changed_files:
        if changed.startswith(ALL_TARGET_TRIGGER_PREFIXES):
            select_all = True
            break

        if changed == ".terraform.lock.hcl":
            select_all = True
            break

        if "/" not in changed:
            if changed.endswith(".tf") or changed.endswith(".tf.json"):
                select_all = True
                break
            # Unknown repo-root IaC/CI file: fail safe.
            select_all = True
            break

        matched_target = False
        for target_path, target in sorted(path_map.items(), key=lambda item: len(item[0]), reverse=True):
            if changed == target_path or changed.startswith(f"{target_path}/"):
                add_target(target["id"])
                matched_target = True
                break

        if matched_target:
            continue

    if select_all:
        return list(catalog)

    if not selected_ids:
        return list(catalog)

    by_id = catalog_lookup(catalog)
    return [by_id[target_id] for target_id in selected_ids]


def apply_overrides(
    targets: list[dict],
    tfvars_override: str | None,
    backend_override: str | None,
) -> list[dict]:
    overridden = []
    for item in targets:
        updated = dict(item)
        if tfvars_override:
            updated["tfvars_file"] = tfvars_override
        if backend_override:
            updated["backend_config_file"] = backend_override
        overridden.append(updated)
    return overridden


def filter_live_validation_targets(targets: list[dict], scheduled_only: bool) -> list[dict]:
    filtered = []
    for item in targets:
        if not item.get("live_validation_enabled", False):
            continue
        if scheduled_only and not item.get("live_validation_scheduled", False):
            continue
        filtered.append(item)
    return filtered


def emit(data: list[dict], output_format: str) -> None:
    payload = {"include": data}
    if output_format == "json":
        json.dump(payload, sys.stdout, separators=(",", ":"))
        return
    if output_format == "pretty":
        json.dump(payload, sys.stdout, indent=2)
        return
    if output_format == "count":
        sys.stdout.write(str(len(data)))
        return
    if output_format == "ids":
        sys.stdout.write(",".join(item["id"] for item in data))
        return
    raise ValueError(f"unsupported output format: {output_format}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", default="ci/terraform-targets.json")
    parser.add_argument("--mode", choices=("full", "changed", "single"), required=True)
    parser.add_argument("--target")
    parser.add_argument("--base-sha")
    parser.add_argument("--head-sha")
    parser.add_argument("--tfvars-override")
    parser.add_argument("--backend-override")
    parser.add_argument("--live-validation-only", action="store_true")
    parser.add_argument("--scheduled-live-validation-only", action="store_true")
    parser.add_argument("--output-format", choices=("json", "pretty", "count", "ids"), default="json")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    catalog = load_catalog(Path(args.catalog))

    if args.mode == "full":
        selected = list(catalog)
    elif args.mode == "single":
        if not args.target:
            raise ValueError("--target is required with --mode single")
        by_id = catalog_lookup(catalog)
        if args.target not in by_id:
            raise ValueError(f"unknown target id: {args.target}")
        selected = [by_id[args.target]]
    else:
        changed = git_changed_files(args.base_sha or "", args.head_sha or "")
        selected = select_changed_targets(catalog, changed)

    selected = apply_overrides(
        selected,
        args.tfvars_override,
        args.backend_override,
    )
    if args.live_validation_only or args.scheduled_live_validation_only:
        selected = filter_live_validation_targets(selected, args.scheduled_live_validation_only)
    emit(selected, args.output_format)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
