#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_BIN="${TF_BIN:-terraform}"
PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${ROOT_DIR}/.terraform.d/plugin-cache}"
INIT_ARGS=(-backend=false -input=false -lockfile=readonly)
INIT_TIMEOUT_SECONDS="${ROOT_INIT_TIMEOUT_SECONDS:-180}"
TEST_TIMEOUT_SECONDS="${ROOT_TEST_TIMEOUT_SECONDS:-300}"
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
  local root_name=$1
  python3 -c '
import re
import sys

root_name = sys.argv[1]

for raw_line in sys.stdin:
    line = raw_line.rstrip("\n")
    stripped = line.strip()
    if not stripped:
        continue

    file_line = re.fullmatch(r"([^ ]+\.tftest\.hcl)\.\.\. in progress", stripped)
    if file_line:
        print(f"[root-test:{root_name}] Suite: {file_line.group(1)}")
        continue

    run_line = re.fullmatch(r"run \"([^\"]+)\"\.\.\. (pass|fail|skip)", stripped)
    if run_line:
        status = run_line.group(2).upper()
        print(f"[root-test:{root_name}]   {status:<4} {run_line.group(1)}")
        continue

    if (
        stripped.endswith("... tearing down")
        or stripped.endswith(".tftest.hcl... pass")
        or stripped.endswith(".tftest.hcl... fail")
    ):
        continue

    summary = re.fullmatch(r"(Success|Failure)! ([0-9]+ passed, [0-9]+ failed(?:, [0-9]+ skipped)?)\.", stripped)
    if summary:
        print(f"[root-test:{root_name}] Result: {summary.group(2)}")
        continue

    print(f"[root-test:{root_name}] {stripped}")
' "${root_name}"
}

prefix_raw_output() {
  local root_name=$1
  local output_file=$2

  sed -e '/^$/d' -e "s/^/[root-test:${root_name}] /" "${output_file}"
}

run_root_step() {
  local root_name=$1
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
      if [[ -s "${output_file}" && "${phase}" == "test" ]]; then
        format_test_output "${root_name}" < "${output_file}"
      fi
      rm -f "${output_file}"
      return 0
    fi

    if [[ ${attempt} -eq 1 ]] && is_retryable_provider_failure "${output_file}"; then
      printf "[root-test:%s] Transient provider/network failure during %s; retrying once.\n" "${root_name}" "${phase}"
      attempt=2
      sleep 2
      continue
    fi

    if [[ ${rc} -eq 124 ]]; then
      printf "[root-test:%s] %s timed out after %ss.\n" "${root_name}" "${phase}" "${timeout_seconds}"
    fi

    if [[ "${phase}" == "test" ]]; then
      format_test_output "${root_name}" < "${output_file}" >&2
    else
      prefix_raw_output "${root_name}" "${output_file}" >&2
    fi

    rm -f "${output_file}"
    return "${rc}"
  done
}

TARGET_ROOTS=("$@")
if [[ ${#TARGET_ROOTS[@]} -eq 0 ]]; then
  TARGET_ROOTS=("prod-app" "nonprod-app")
fi

for root_name in "${TARGET_ROOTS[@]}"; do
  root_dir="${ROOT_DIR}/${root_name}"

  if [[ ! -d "${root_dir}" ]]; then
    printf "Unknown deployment root: %s\n" "${root_name}" >&2
    exit 2
  fi

  if [[ ! -d "${root_dir}/tests" ]] || ! find "${root_dir}/tests" -maxdepth 1 -type f -name '*.tftest.hcl' -print -quit | grep -q .; then
    printf "[root-test:%s] Skipping; no native Terraform tests found.\n" "${root_name}"
    continue
  fi

  printf "[root-test:%s] Running native Terraform tests\n" "${root_name}"
  if ! run_root_step "${root_name}" "init" "${INIT_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${root_dir}" init "${INIT_ARGS[@]}"; then
    FAILURES=1
    continue
  fi

  if ! run_root_step "${root_name}" "test" "${TEST_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${root_dir}" test -no-color; then
    FAILURES=1
  fi
done

if [[ ${FAILURES} -ne 0 ]]; then
  exit 1
fi
