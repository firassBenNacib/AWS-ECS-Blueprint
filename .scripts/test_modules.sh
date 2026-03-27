#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_BIN="${TF_BIN:-terraform}"
PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${ROOT_DIR}/.terraform.d/plugin-cache}"
INIT_ARGS=(-backend=false -input=false -lockfile=readonly)
INIT_TIMEOUT_SECONDS="${MODULE_INIT_TIMEOUT_SECONDS:-180}"
TEST_TIMEOUT_SECONDS="${MODULE_TEST_TIMEOUT_SECONDS:-300}"
MODULE_FILTER="${1:-}"
FOUND_MODULE="false"
FAILURES=0

mkdir -p "${PLUGIN_CACHE_DIR}"

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

is_retryable_provider_failure() {
  local output_file=$1
  local pattern='Failed to query available provider packages|registry\.terraform\.io|context deadline exceeded|TLS handshake timeout|Client\.Timeout exceeded|connection reset by peer|unexpected EOF|error downloading|request cancelled|timeout while waiting for plugin'

  if command -v rg >/dev/null 2>&1; then
    rg -q "${pattern}" "${output_file}"
    return
  fi

  grep -Eq "${pattern}" "${output_file}"
}

format_test_output() {
  local module_name=$1
  python3 -c '
import re
import sys

module_name = sys.argv[1]

for raw_line in sys.stdin:
    line = raw_line.rstrip("\n")
    stripped = line.strip()
    if not stripped:
        continue

    file_line = re.fullmatch(r"([^ ]+\.tftest\.hcl)\.\.\. in progress", stripped)
    if file_line:
        print(f"[module-test:{module_name}] Suite: {file_line.group(1)}")
        continue

    run_line = re.fullmatch(r"run \"([^\"]+)\"\.\.\. (pass|fail|skip)", stripped)
    if run_line:
        status = run_line.group(2).upper()
        print(f"[module-test:{module_name}]   {status:<4} {run_line.group(1)}")
        continue

    if (
        stripped.endswith("... tearing down")
        or stripped.endswith(".tftest.hcl... pass")
        or stripped.endswith(".tftest.hcl... fail")
    ):
        continue

    summary = re.fullmatch(r"(Success|Failure)! ([0-9]+ passed, [0-9]+ failed(?:, [0-9]+ skipped)?)\.", stripped)
    if summary:
        print(f"[module-test:{module_name}] Result: {summary.group(2)}")
        continue

    print(f"[module-test:{module_name}] {stripped}")
' "${module_name}"
}

prefix_raw_output() {
  local module_name=$1
  local output_file=$2

  sed -e '/^$/d' -e "s/^/[module-test:${module_name}] /" "${output_file}"
}

run_module_step() {
  local module_name=$1
  local phase=$2
  local timeout_seconds=$3
  shift 3

  local output_file
  local attempt=1
  local rc
  output_file="$(mktemp)"

  while true; do
    run_with_timeout "${timeout_seconds}" "${output_file}" "$@"
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
      if [[ -s "${output_file}" ]]; then
        if [[ "${phase}" == "test" ]]; then
          format_test_output "${module_name}" < "${output_file}"
        fi
      fi
      rm -f "${output_file}"
      return 0
    fi

    if [[ ${attempt} -eq 1 ]] && is_retryable_provider_failure "${output_file}"; then
      printf "[module-test:%s] Transient provider/network failure during %s; retrying once.\n" "${module_name}" "${phase}"
      attempt=2
      sleep 2
      continue
    fi

    if [[ ${rc} -eq 124 ]]; then
      printf "[module-test:%s] %s timed out after %ss.\n" "${module_name}" "${phase}" "${timeout_seconds}"
    fi

    if [[ "${phase}" == "test" ]]; then
      format_test_output "${module_name}" < "${output_file}" >&2
    else
      prefix_raw_output "${module_name}" "${output_file}" >&2
    fi

    rm -f "${output_file}"
    return "${rc}"
  done
}

mapfile -t MODULE_DIRS < <(find "${ROOT_DIR}/modules" -mindepth 1 -maxdepth 1 -type d | sort)

for module_dir in "${MODULE_DIRS[@]}"; do
  module_name="$(basename "${module_dir}")"

  if [[ -n "${MODULE_FILTER}" && "${module_name}" != "${MODULE_FILTER}" ]]; then
    continue
  fi

  FOUND_MODULE="true"

  if [[ ! -d "${module_dir}/tests" ]] || ! find "${module_dir}/tests" -maxdepth 1 -type f -name '*.tftest.hcl' -print -quit | grep -q .; then
    printf "[module-test:%s] Skipping; no native Terraform tests found.\n" "${module_name}"
    continue
  fi

  printf "[module-test:%s] Running native Terraform tests\n" "${module_name}"
  if ! run_module_step "${module_name}" "init" "${INIT_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${module_dir}" init "${INIT_ARGS[@]}"; then
    FAILURES=1
    continue
  fi

  if ! run_module_step "${module_name}" "test" "${TEST_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${module_dir}" test -no-color; then
    FAILURES=1
  fi
done

if [[ -n "${MODULE_FILTER}" && "${FOUND_MODULE}" != "true" ]]; then
  printf "Reusable module not found: %s\n" "${MODULE_FILTER}" >&2
  exit 1
fi

if [[ ${FAILURES} -ne 0 ]]; then
  exit 1
fi
