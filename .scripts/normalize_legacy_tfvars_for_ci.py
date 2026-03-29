#!/usr/bin/env python3
"""Normalize known legacy root tfvars keys for CI compatibility."""

from __future__ import annotations

import re
import sys

from path_safety import resolve_existing_file


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: normalize_legacy_tfvars_for_ci.py <tfvars-path>", file=sys.stderr)
        return 2

    path = resolve_existing_file(sys.argv[1], description="tfvars file")
    text = path.read_text(encoding="utf-8")
    changes: list[str] = []

    updated = re.sub(
        r'(?m)^(\s*backend_origin_protocol_policy\s*=\s*)"http-only"(\s*(?:#.*)?)$',
        r'\1"https-only"\2',
        text,
    )
    if updated != text:
        changes.append("normalized backend_origin_protocol_policy=http-only to https-only")
        text = updated

    updated = re.sub(r'(?m)^\s*backend_failover_domain_name\s*=.*(?:\n|$)', "", text)
    if updated != text:
        changes.append("removed legacy backend_failover_domain_name input")
        text = updated

    path.write_text(text, encoding="utf-8")
    print("; ".join(changes))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
