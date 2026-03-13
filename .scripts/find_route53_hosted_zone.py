#!/usr/bin/env python3
"""Find the longest matching public Route53 hosted zone suffix for a domain."""

from __future__ import annotations

import json
import subprocess
import sys


def normalize_domain(value: str) -> str:
    return value.strip().lower().rstrip(".")


def main() -> int:
    query = json.load(sys.stdin)
    domain = normalize_domain(query.get("domain", ""))
    if not domain:
        raise SystemExit("domain is required")

    result = subprocess.run(
        ["aws", "route53", "list-hosted-zones", "--output", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    hosted_zones = json.loads(result.stdout).get("HostedZones", [])

    best_match = None
    best_name = ""

    for zone in hosted_zones:
        if zone.get("Config", {}).get("PrivateZone"):
            continue

        zone_name = normalize_domain(zone.get("Name", ""))
        if not zone_name:
            continue

        if domain == zone_name or domain.endswith(f".{zone_name}"):
            if best_match is None or len(zone_name) > len(best_name):
                best_match = zone
                best_name = zone_name

    if best_match is None:
        print(json.dumps({"found": "false", "zone_id": "", "zone_name": ""}))
        return 0

    print(
        json.dumps(
            {
                "found": "true",
                "zone_id": best_match["Id"].split("/")[-1],
                "zone_name": best_name,
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
