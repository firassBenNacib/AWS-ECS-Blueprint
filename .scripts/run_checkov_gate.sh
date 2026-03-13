#!/usr/bin/env bash
set -euo pipefail

TFVARS_FILE="${1:-terraform.prod.tfvars}"
WORKDIR="${2:-.}"
ALLOWLIST_DIR="${ALLOWLIST_DIR:-ci/allowlists}"
OUT_DIR="${OUT_DIR:-security-reports/checkov}"
MAX_ALLOWLIST_DAYS="${MAX_ALLOWLIST_DAYS:-90}"
CHECKOV_STRICT_ALLOWLIST="${CHECKOV_STRICT_ALLOWLIST:-}"
CHECKOV_LOG_LEVEL="${CHECKOV_LOG_LEVEL:-ERROR}"
CHECKOV_ALLOWLIST_FILE="${ALLOWLIST_DIR}/checkov_skipped_allowlist.txt"
CHECKOV_SKIP_PATHS="${CHECKOV_SKIP_PATHS:-}"

if [[ -z "${CHECKOV_SKIP_PATHS}" && "${WORKDIR}" == "." ]]; then
  CHECKOV_SKIP_PATHS="nonprod-app,prod-app"
fi

if [[ -z "${CHECKOV_STRICT_ALLOWLIST}" ]]; then
  if [[ "${WORKDIR}" == "." ]]; then
    CHECKOV_STRICT_ALLOWLIST="true"
  else
    CHECKOV_STRICT_ALLOWLIST="false"
  fi
fi

mkdir -p "${OUT_DIR}"

for cmd in checkov python3; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}"
    exit 1
  fi
done

test -f "${TFVARS_FILE}" || {
  echo "Missing tfvars file: ${TFVARS_FILE}"
  exit 1
}

test -f "${CHECKOV_ALLOWLIST_FILE}" || {
  echo "Missing checkov allowlist: ${CHECKOV_ALLOWLIST_FILE}"
  exit 1
}

echo "Running checkov (failed checks must be zero)..."
CHECKOV_ARGS=(-d "${WORKDIR}" --framework terraform -o json)

if [[ -n "${CHECKOV_SKIP_PATHS}" ]]; then
  IFS=',' read -r -a _checkov_skips <<< "${CHECKOV_SKIP_PATHS}"
  for path in "${_checkov_skips[@]}"; do
    trimmed="$(echo "${path}" | xargs)"
    if [[ -n "${trimmed}" ]]; then
      CHECKOV_ARGS+=("--skip-path" "${trimmed}")
    fi
  done
fi

LOG_LEVEL="${CHECKOV_LOG_LEVEL}" checkov "${CHECKOV_ARGS[@]}" > "${OUT_DIR}/checkov.json" || true

python3 - "${OUT_DIR}/checkov.json" "${CHECKOV_ALLOWLIST_FILE}" "${MAX_ALLOWLIST_DAYS}" "${CHECKOV_STRICT_ALLOWLIST}" <<'PY'
import json
import re
import sys
from datetime import date, timedelta
from pathlib import Path

checkov_json = Path(sys.argv[1])
allowlist_file = Path(sys.argv[2])
max_allowlist_days = int(sys.argv[3])
strict_allowlist = sys.argv[4].lower() == "true"


def normalize_resource(resource: str) -> str:
    return re.sub(r"\[\d+\]", "", resource)


def resource_aliases(resource: str) -> set[tuple[str, str]]:
    aliases = set()
    current = resource
    while True:
        aliases.add(current)
        aliases.add(normalize_resource(current))
        if not current.startswith("module."):
            break
        parts = current.split(".", 2)
        if len(parts) < 3:
            break
        current = parts[2]
    return aliases

raw = checkov_json.read_text().strip()
if not raw:
    print("Rejected: checkov output is empty")
    sys.exit(1)

decoder = json.JSONDecoder()
try:
    data, _ = decoder.raw_decode(raw)
except json.JSONDecodeError as exc:
    print(f"Rejected: checkov output is not parseable JSON: {exc}")
    sys.exit(1)

results = data.get("results", {})

failed_checks = results.get("failed_checks", [])
skipped_checks = results.get("skipped_checks", [])
observed_failed = set()
for item in failed_checks:
    check_id = item.get("check_id")
    resource = item.get("resource")
    if check_id and resource:
        observed_failed.add((check_id, resource))

observed_skipped = set()
for item in skipped_checks:
    check_id = item.get("check_id")
    resource = item.get("resource")
    if check_id and resource:
        observed_skipped.add((check_id, resource))

allowlist_entries = set()
allowlist_match_entries = set()
allowlist_lookup = {}
expired_entries = []
window_violations = []
parse_errors = []
today = date.today()
max_expiry = today + timedelta(days=max_allowlist_days)

for idx, raw_line in enumerate(allowlist_file.read_text().splitlines(), start=1):
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue

    parts = [part.strip() for part in line.split("|")]
    if len(parts) != 6:
        parse_errors.append(f"line {idx}: expected 6 pipe-delimited fields, got {len(parts)}")
        continue

    check_id, resource, justification, owner, ticket, expires_on = parts
    if not check_id:
        parse_errors.append(f"line {idx}: check_id is empty")
        continue
    if not resource:
        parse_errors.append(f"line {idx}: resource is empty")
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
        expired_entries.append((idx, check_id, resource, expires_on))
    if expiry > max_expiry:
        window_violations.append((idx, check_id, resource, expires_on))

    key = (check_id, resource)
    if key in allowlist_entries:
        parse_errors.append(f"line {idx}: duplicate allowlist entry '{check_id}|{resource}'")
        continue
    allowlist_entries.add(key)
    for match_key in {key, (check_id, normalize_resource(resource))}:
        allowlist_match_entries.add(match_key)
        allowlist_lookup.setdefault(match_key, set()).add(key)

if parse_errors:
    print("Rejected: checkov allowlist format errors:")
    for err in parse_errors:
        print(f"  - {err}")
    sys.exit(1)

if expired_entries:
    print("Rejected: checkov allowlist has expired entries:")
    for idx, check_id, resource, expires_on in expired_entries:
        print(f"  - line {idx}: {check_id}|{resource} expired on {expires_on}")
    sys.exit(1)

if window_violations:
    print(f"Rejected: checkov allowlist expiry exceeds max window ({max_allowlist_days} days):")
    for idx, check_id, resource, expires_on in window_violations:
        print(f"  - line {idx}: {check_id}|{resource} expires on {expires_on}")
    sys.exit(1)

unexpected_failed = sorted(
    (check_id, resource)
    for check_id, resource in observed_failed
    if not any((check_id, alias) in allowlist_match_entries for alias in resource_aliases(resource))
)
if unexpected_failed:
    print("Rejected: unexpected failed checkov checks:")
    for check_id, resource in unexpected_failed:
        print(f"  - {check_id}|{resource}")
    sys.exit(1)

unexpected_skipped = sorted(
    (check_id, resource)
    for check_id, resource in observed_skipped
    if not any((check_id, alias) in allowlist_match_entries for alias in resource_aliases(resource))
)
if unexpected_skipped:
    print("Rejected: unexpected skipped checkov checks:")
    for check_id, resource in unexpected_skipped:
        print(f"  - {check_id}|{resource}")
    sys.exit(1)

observed = observed_failed | observed_skipped
observed_allowlist_matches = set()
for check_id, resource in observed:
    for alias in resource_aliases(resource):
        observed_allowlist_matches.update(allowlist_lookup.get((check_id, alias), set()))

stale = sorted(allowlist_entries - observed_allowlist_matches)
if strict_allowlist and stale:
    print("Rejected: stale checkov allowlist entries not observed in failed/skipped checks:")
    for check_id, resource in stale:
        print(f"  - {check_id}|{resource}")
    sys.exit(1)

print("checkov allowlist policy passed.")
PY
