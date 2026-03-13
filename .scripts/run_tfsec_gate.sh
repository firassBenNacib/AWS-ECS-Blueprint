#!/usr/bin/env bash
set -euo pipefail

TFVARS_FILE="${1:-terraform.prod.tfvars}"
WORKDIR="${2:-.}"
ALLOWLIST_DIR="${ALLOWLIST_DIR:-ci/allowlists}"
OUT_DIR="${OUT_DIR:-security-reports/tfsec}"
MAX_ALLOWLIST_DAYS="${MAX_ALLOWLIST_DAYS:-90}"
TFSEC_STRICT_ALLOWLIST="${TFSEC_STRICT_ALLOWLIST:-}"
TFSEC_ALLOWLIST_FILE="${ALLOWLIST_DIR}/tfsec_ignored_high_allowlist.txt"
TFSEC_EXCLUDE_PATHS="${TFSEC_EXCLUDE_PATHS:-}"

if [[ -z "${TFSEC_EXCLUDE_PATHS}" && "${WORKDIR}" == "." ]]; then
  TFSEC_EXCLUDE_PATHS="nonprod-app,prod-app"
fi

if [[ -z "${TFSEC_STRICT_ALLOWLIST}" ]]; then
  if [[ "${WORKDIR}" == "." ]]; then
    TFSEC_STRICT_ALLOWLIST="true"
  else
    TFSEC_STRICT_ALLOWLIST="false"
  fi
fi

mkdir -p "${OUT_DIR}"

for cmd in tfsec python3; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}"
    exit 1
  fi
done

test -f "${TFVARS_FILE}" || {
  echo "Missing tfvars file: ${TFVARS_FILE}"
  exit 1
}

test -f "${TFSEC_ALLOWLIST_FILE}" || {
  echo "Missing tfsec allowlist: ${TFSEC_ALLOWLIST_FILE}"
  exit 1
}

echo "Running tfsec (unsuppressed findings must be zero)..."
TFSEC_ARGS=(
  "${WORKDIR}"
  "--tfvars-file" "${TFVARS_FILE}"
  "--no-color"
  "--format" "json"
  "--out" "${OUT_DIR}/tfsec.unsuppressed.json"
)

if [[ -n "${TFSEC_EXCLUDE_PATHS}" ]]; then
  IFS=',' read -r -a _tfsec_excludes <<< "${TFSEC_EXCLUDE_PATHS}"
  for path in "${_tfsec_excludes[@]}"; do
    trimmed="$(echo "${path}" | xargs)"
    if [[ -n "${trimmed}" ]]; then
      TFSEC_ARGS+=("--exclude-path" "${trimmed}")
    fi
  done
fi

tfsec "${TFSEC_ARGS[@]}"

echo "Running tfsec (include ignored for allowlist enforcement)..."
TFSEC_IGNORED_ARGS=(
  "${WORKDIR}"
  "--tfvars-file" "${TFVARS_FILE}"
  "--include-ignored"
  "--no-color"
  "--format" "json"
  "--out" "${OUT_DIR}/tfsec.include_ignored.json"
)

if [[ -n "${TFSEC_EXCLUDE_PATHS}" ]]; then
  IFS=',' read -r -a _tfsec_excludes <<< "${TFSEC_EXCLUDE_PATHS}"
  for path in "${_tfsec_excludes[@]}"; do
    trimmed="$(echo "${path}" | xargs)"
    if [[ -n "${trimmed}" ]]; then
      TFSEC_IGNORED_ARGS+=("--exclude-path" "${trimmed}")
    fi
  done
fi

tfsec "${TFSEC_IGNORED_ARGS[@]}" || true

python3 - "${OUT_DIR}/tfsec.include_ignored.json" "${TFSEC_ALLOWLIST_FILE}" "${MAX_ALLOWLIST_DAYS}" "${TFSEC_STRICT_ALLOWLIST}" <<'PY'
import json
import re
import sys
from datetime import date, timedelta
from pathlib import Path

tfsec_json = Path(sys.argv[1])
allowlist_file = Path(sys.argv[2])
max_allowlist_days = int(sys.argv[3])
strict_allowlist = sys.argv[4].lower() == "true"

data = json.loads(tfsec_json.read_text())
results = data.get("results", [])

ignored = [r for r in results if r.get("status") == 2]
ignored_high_locations = {}
for finding in ignored:
    if finding.get("severity") != "HIGH":
        continue
    rule_id = finding.get("long_id")
    if not rule_id:
        continue
    loc = finding.get("location", {})
    filename = loc.get("filename", "")
    start_line = loc.get("start_line", 0)
    ignored_high_locations.setdefault(rule_id, set()).add(f"{filename}:{start_line}")

ignored_high = sorted(ignored_high_locations.keys())
ignored_critical = sorted({r.get("long_id") for r in ignored if r.get("severity") == "CRITICAL"})

allowlist_expected_counts = {}
expired_entries = []
window_violations = []
parse_errors = []
today = date.today()
max_expiry = today + timedelta(days=max_allowlist_days)

for idx, raw in enumerate(allowlist_file.read_text().splitlines(), start=1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue

    parts = [part.strip() for part in line.split("|")]
    if len(parts) != 6:
        parse_errors.append(f"line {idx}: expected 6 pipe-delimited fields, got {len(parts)}")
        continue

    rule_id, expected_count_raw, justification, owner, ticket, expires_on = parts
    if not rule_id:
        parse_errors.append(f"line {idx}: rule_id is empty")
        continue
    if not expected_count_raw.isdigit() or int(expected_count_raw) <= 0:
        parse_errors.append(f"line {idx}: expected_count '{expected_count_raw}' must be a positive integer")
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

    if rule_id in allowlist_expected_counts:
        parse_errors.append(f"line {idx}: duplicate rule_id '{rule_id}'")
        continue

    allowlist_expected_counts[rule_id] = int(expected_count_raw)

if parse_errors:
    print("Rejected: tfsec allowlist format errors:")
    for err in parse_errors:
        print(f"  - {err}")
    sys.exit(1)

if expired_entries:
    print("Rejected: tfsec allowlist has expired entries:")
    for idx, rule_id, expires_on in expired_entries:
        print(f"  - line {idx}: {rule_id} expired on {expires_on}")
    sys.exit(1)

if window_violations:
    print(f"Rejected: tfsec allowlist expiry exceeds max window ({max_allowlist_days} days):")
    for idx, rule_id, expires_on in window_violations:
        print(f"  - line {idx}: {rule_id} expires on {expires_on}")
    sys.exit(1)

if ignored_critical:
    print("Rejected: ignored CRITICAL tfsec findings are not allowed:")
    for item in ignored_critical:
        print(f"  - {item}")
    sys.exit(1)

allowlist_rules = set(allowlist_expected_counts.keys())
unexpected_high = sorted(set(ignored_high) - allowlist_rules)
if unexpected_high:
    print("Rejected: unexpected ignored HIGH tfsec findings:")
    for item in unexpected_high:
        print(f"  - {item}")
    print("Allowed ignored HIGH tfsec rule IDs:")
    for item in sorted(allowlist_rules):
        print(f"  - {item}")
    sys.exit(1)

stale_allowlist = sorted(allowlist_rules - set(ignored_high))
if strict_allowlist and stale_allowlist:
    print("Rejected: stale tfsec allowlist entries not observed in ignored HIGH results:")
    for item in stale_allowlist:
        print(f"  - {item}")
    sys.exit(1)

count_mismatch = []
for rule_id in sorted(allowlist_rules):
    expected_count = allowlist_expected_counts[rule_id]
    observed_count = len(ignored_high_locations.get(rule_id, set()))
    if observed_count != expected_count:
        count_mismatch.append((rule_id, expected_count, observed_count))

if strict_allowlist and count_mismatch:
    print("Rejected: ignored HIGH tfsec occurrence count mismatch:")
    for rule_id, expected_count, observed_count in count_mismatch:
        print(f"  - {rule_id}: expected {expected_count}, observed {observed_count}")
    sys.exit(1)

print("tfsec ignored HIGH/CRITICAL policy passed.")
PY
