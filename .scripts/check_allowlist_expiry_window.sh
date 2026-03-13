#!/usr/bin/env bash
set -euo pipefail

ALLOWLIST_DIR="${1:-ci/allowlists}"
WARN_DAYS="${2:-14}"

python3 - "$ALLOWLIST_DIR" "$WARN_DAYS" <<'PY'
from datetime import date, timedelta
from pathlib import Path
import sys

allowlist_dir = Path(sys.argv[1])
warn_days = int(sys.argv[2])
today = date.today()
threshold = today + timedelta(days=warn_days)

entries = []

def parse_tfsec(path: Path):
    for idx, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) != 6:
            raise ValueError(f"{path}:{idx}: expected 6 fields")
        rule_id, _, _, owner, ticket, expires_on = parts
        expiry = date.fromisoformat(expires_on)
        entries.append((str(path), idx, rule_id, owner, ticket, expiry))


def parse_checkov(path: Path):
    for idx, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) != 6:
            raise ValueError(f"{path}:{idx}: expected 6 fields")
        check_id, resource, _, owner, ticket, expires_on = parts
        expiry = date.fromisoformat(expires_on)
        entries.append((str(path), idx, f"{check_id}|{resource}", owner, ticket, expiry))

try:
    parse_tfsec(allowlist_dir / "tfsec_ignored_high_allowlist.txt")
    parse_checkov(allowlist_dir / "checkov_skipped_allowlist.txt")
except Exception as exc:
    print(f"Rejected: allowlist parse error: {exc}")
    sys.exit(1)

upcoming = []
expired = []
for file_name, idx, item_id, owner, ticket, expiry in entries:
    if expiry < today:
        expired.append((file_name, idx, item_id, owner, ticket, expiry))
    elif expiry <= threshold:
        upcoming.append((file_name, idx, item_id, owner, ticket, expiry))

if expired:
    print("Rejected: allowlist entries are expired:")
    for file_name, idx, item_id, owner, ticket, expiry in expired:
        print(f"  - {file_name}:{idx} {item_id} owner={owner} ticket={ticket} expired={expiry}")
    sys.exit(1)

if upcoming:
    print(f"Rejected: allowlist entries expire within {warn_days} days:")
    for file_name, idx, item_id, owner, ticket, expiry in upcoming:
        print(f"  - {file_name}:{idx} {item_id} owner={owner} ticket={ticket} expires={expiry}")
    sys.exit(1)

print(f"Allowlist expiry window check passed (no entries expiring within {warn_days} days).")
PY
