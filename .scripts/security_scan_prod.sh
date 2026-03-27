#!/usr/bin/env bash
set -euo pipefail

TFVARS_FILE="${1:-terraform.prod.tfvars}"
WORKDIR="${2:-.}"
ALLOWLIST_DIR="${ALLOWLIST_DIR:-ci/allowlists}"
OUT_DIR="${OUT_DIR:-security-reports/checks}"
MAX_ALLOWLIST_DAYS="${MAX_ALLOWLIST_DAYS:-90}"
TFSEC_MIN_SEVERITY="${TFSEC_MIN_SEVERITY:-HIGH}"
TFSEC_STRICT_ALLOWLIST="${TFSEC_STRICT_ALLOWLIST:-}"
CHECKOV_STRICT_ALLOWLIST="${CHECKOV_STRICT_ALLOWLIST:-}"
CHECKOV_LOG_LEVEL="${CHECKOV_LOG_LEVEL:-ERROR}"
TFSEC_EXCLUDE_PATHS="${TFSEC_EXCLUDE_PATHS:-}"
CHECKOV_SKIP_PATHS="${CHECKOV_SKIP_PATHS:-}"
TFSEC_TIMEOUT_SECONDS="${TFSEC_TIMEOUT_SECONDS:-300}"
CHECKOV_TIMEOUT_SECONDS="${CHECKOV_TIMEOUT_SECONDS:-420}"
SCAN_RETRYABLE_PATTERN="${SCAN_RETRYABLE_PATTERN:-context deadline exceeded|TLS handshake timeout|Client\\.Timeout exceeded|connection reset by peer|unexpected EOF|ReadTimeout|Temporary failure in name resolution|timed out}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

export ALLOWLIST_DIR
export OUT_DIR
export MAX_ALLOWLIST_DAYS
export TFSEC_MIN_SEVERITY
export TFSEC_STRICT_ALLOWLIST
export CHECKOV_STRICT_ALLOWLIST
export CHECKOV_LOG_LEVEL
export TFSEC_EXCLUDE_PATHS
export CHECKOV_SKIP_PATHS
export TFSEC_TIMEOUT_SECONDS
export CHECKOV_TIMEOUT_SECONDS

run_with_timeout() {
  local timeout_seconds=$1
  local output_file=$2
  local rc
  shift 2

  if command -v timeout >/dev/null 2>&1; then
    timeout --foreground "${timeout_seconds}" "$@" >"${output_file}" 2>&1
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
      return 0
    fi
    return "${rc}"
  fi

  "$@" >"${output_file}" 2>&1
  rc=$?
  if [[ ${rc} -eq 0 ]]; then
    return 0
  fi
  return "${rc}"
}

is_retryable_scan_failure() {
  local output_file=$1

  if command -v rg >/dev/null 2>&1; then
    rg -q "${SCAN_RETRYABLE_PATTERN}" "${output_file}"
    return
  fi

  grep -Eq "${SCAN_RETRYABLE_PATTERN}" "${output_file}"
}

run_scan_step() {
  local root_label=$1
  local step_name=$2
  local timeout_seconds=$3
  shift 3

  local attempt=1
  local output_file
  local rc
  output_file="$(mktemp)"

  while true; do
    run_with_timeout "${timeout_seconds}" "${output_file}" "$@"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
      cat "${output_file}"
      rm -f "${output_file}"
      return 0
    fi

    if [[ ${attempt} -eq 1 ]] && is_retryable_scan_failure "${output_file}"; then
      printf "[root:%s][scan] Transient failure during %s; retrying once.\n" "${root_label}" "${step_name}" >&2
      attempt=2
      sleep 2
      continue
    fi

    if [[ ${rc} -eq 124 ]]; then
      printf "[root:%s][scan] %s timed out after %ss.\n" "${root_label}" "${step_name}" "${timeout_seconds}" >&2
    fi

    cat "${output_file}" >&2
    rm -f "${output_file}"
    return "${rc}"
  done
}

printf "[root:%s][scan] Starting tfsec gate.\n" "${WORKDIR}" >&2
run_scan_step "${WORKDIR}" "tfsec" "${TFSEC_TIMEOUT_SECONDS}" \
  bash "${SCRIPT_DIR}/run_tfsec_gate.sh" "${TFVARS_FILE}" "${WORKDIR}"
printf "[root:%s][scan] Starting checkov gate.\n" "${WORKDIR}" >&2
run_scan_step "${WORKDIR}" "checkov" "${CHECKOV_TIMEOUT_SECONDS}" \
  bash "${SCRIPT_DIR}/run_checkov_gate.sh" "${TFVARS_FILE}" "${WORKDIR}"
