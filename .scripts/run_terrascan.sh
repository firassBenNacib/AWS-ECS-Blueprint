#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-.}"
OUT_DIR="${OUT_DIR:-security-reports/terrascan}"
ALLOWLIST_DIR="${ALLOWLIST_DIR:-ci/allowlists}"
TERRASCAN_ALLOWLIST_FILE="${ALLOWLIST_DIR}/terrascan-allowlist.txt"
TERRASCAN_CONFIG_FILE="${TERRASCAN_CONFIG_FILE:-}"
TERRASCAN_FAIL_SEVERITIES="${TERRASCAN_FAIL_SEVERITIES:-HIGH,CRITICAL}"
TERRASCAN_STRICT_ALLOWLIST="${TERRASCAN_STRICT_ALLOWLIST:-false}"
MAX_ALLOWLIST_DAYS="${MAX_ALLOWLIST_DAYS:-90}"

mkdir -p "${OUT_DIR}"

for cmd in terrascan python3; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}"
    exit 1
  fi
done

test -d "${WORKDIR}" || {
  echo "Missing workdir: ${WORKDIR}"
  exit 1
}

test -f "${TERRASCAN_ALLOWLIST_FILE}" || {
  echo "Missing Terrascan allowlist: ${TERRASCAN_ALLOWLIST_FILE}"
  exit 1
}

TERRASCAN_ARGS=(scan -i terraform -d "${WORKDIR}" -o json)
if [[ -n "${TERRASCAN_CONFIG_FILE}" && -f "${TERRASCAN_CONFIG_FILE}" ]]; then
  TERRASCAN_ARGS=(-c "${TERRASCAN_CONFIG_FILE}" "${TERRASCAN_ARGS[@]}")
fi

set +e
terrascan "${TERRASCAN_ARGS[@]}" > "${OUT_DIR}/terrascan.json"
TERRASCAN_EXIT=$?
set -e

if [[ "${TERRASCAN_EXIT}" -eq 1 || "${TERRASCAN_EXIT}" -eq 4 || "${TERRASCAN_EXIT}" -eq 5 ]]; then
  echo "Terrascan scan failed with exit code ${TERRASCAN_EXIT}"
  exit "${TERRASCAN_EXIT}"
fi

python3 - "${OUT_DIR}/terrascan.json" "${TERRASCAN_ALLOWLIST_FILE}" "${TERRASCAN_FAIL_SEVERITIES}" "${MAX_ALLOWLIST_DAYS}" "${TERRASCAN_STRICT_ALLOWLIST}" <<'PY'
import json
import re
import sys
from datetime import date, timedelta
from pathlib import Path

results_path = Path(sys.argv[1])
allowlist_path = Path(sys.argv[2])
fail_severities = {item.strip().upper() for item in sys.argv[3].split(",") if item.strip()}
max_allowlist_days = int(sys.argv[4])
strict_allowlist = sys.argv[5].lower() == "true"

data = json.loads(results_path.read_text() or "{}")
violations = []

if isinstance(data.get("results"), dict):
    violations = data.get("results", {}).get("violations", [])
elif isinstance(data.get("results"), list):
    violations = data.get("results", [])
elif isinstance(data.get("violations"), list):
    violations = data.get("violations", [])

observed = set()
for violation in violations:
    severity = str(violation.get("severity", "")).upper()
    if severity not in fail_severities:
        continue
    rule_id = violation.get("rule_id") or violation.get("rule_name")
    if rule_id:
        observed.add(rule_id)

allowlist_entries = set()
expired_entries = []
window_violations = []
parse_errors = []
today = date.today()
max_expiry = today + timedelta(days=max_allowlist_days)

for idx, raw_line in enumerate(allowlist_path.read_text().splitlines(), start=1):
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue

    parts = [part.strip() for part in line.split("|")]
    if len(parts) != 5:
        parse_errors.append(f"line {idx}: expected 5 pipe-delimited fields, got {len(parts)}")
        continue

    rule_id, justification, owner, ticket, expires_on = parts
    if not rule_id:
        parse_errors.append(f"line {idx}: rule_id is empty")
        continue
    if not owner or not re.fullmatch(r"[a-z0-9][a-z0-9-]{1,63}", owner):
        parse_errors.append(f"line {idx}: owner '{owner}' must match [a-z0-9-] pattern")
        continue
    if not ticket or not re.fullmatch(r"[A-Z]+-[0-9]+", ticket):
        parse_errors.append(f"line {idx}: ticket '{ticket}' must match pattern ABC-123")
        continue
    try:
        expiry = date.fromisoformat(expires_on)
    except ValueError:
        parse_errors.append(f"line {idx}: invalid expires_on date '{expires_on}', expected YYYY-MM-DD")
        continue
    if expiry < today:
        expired_entries.append((idx, rule_id, expires_on))
    if expiry > max_expiry:
        window_violations.append((idx, rule_id, expires_on))
    if rule_id in allowlist_entries:
        parse_errors.append(f"line {idx}: duplicate rule_id '{rule_id}'")
        continue
    allowlist_entries.add(rule_id)

if parse_errors:
    print("Rejected: Terrascan allowlist format errors:")
    for err in parse_errors:
        print(f"  - {err}")
    sys.exit(1)

if expired_entries:
    print("Rejected: Terrascan allowlist has expired entries:")
    for idx, rule_id, expires_on in expired_entries:
        print(f"  - line {idx}: {rule_id} expired on {expires_on}")
    sys.exit(1)

if window_violations:
    print(f"Rejected: Terrascan allowlist expiry exceeds max window ({max_allowlist_days} days):")
    for idx, rule_id, expires_on in window_violations:
        print(f"  - line {idx}: {rule_id} expires on {expires_on}")
    sys.exit(1)

unexpected = sorted(observed - allowlist_entries)
if unexpected:
    print("Rejected: unexpected Terrascan violations:")
    for rule_id in unexpected:
        print(f"  - {rule_id}")
    sys.exit(1)

stale = sorted(allowlist_entries - observed)
if strict_allowlist and stale:
    print("Rejected: stale Terrascan allowlist entries not observed in scan results:")
    for rule_id in stale:
        print(f"  - {rule_id}")
    sys.exit(1)

print("Terrascan allowlist policy passed.")
PY
