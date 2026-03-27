#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_BIN="${TF_BIN:-terraform}"
PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${ROOT_DIR}/.terraform.d/plugin-cache}"
INIT_ARGS=(-backend=false -input=false -lockfile=readonly)
INIT_TIMEOUT_SECONDS="${ROOT_INIT_TIMEOUT_SECONDS:-180}"
VALIDATE_TIMEOUT_SECONDS="${ROOT_VALIDATE_TIMEOUT_SECONDS:-120}"
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

prefix_output() {
  local root_name=$1
  local output_file=$2

  sed -e '/^$/d' -e "s/^/[root:${root_name}] /" "${output_file}"
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
      if [[ -s "${output_file}" && "${phase}" != "init" ]]; then
        prefix_output "${root_name}" "${output_file}"
      fi
      rm -f "${output_file}"
      return 0
    fi

    if [[ ${attempt} -eq 1 ]] && is_retryable_provider_failure "${output_file}"; then
      printf "[root:%s] Transient provider/network failure during %s; retrying once.\n" "${root_name}" "${phase}"
      attempt=2
      sleep 2
      continue
    fi

    if [[ ${rc} -eq 124 ]]; then
      printf "[root:%s] %s timed out after %ss.\n" "${root_name}" "${phase}" "${timeout_seconds}"
    fi

    prefix_output "${root_name}" "${output_file}" >&2
    rm -f "${output_file}"
    return "${rc}"
  done
}

TARGET_DIRS=("$@")
if [[ ${#TARGET_DIRS[@]} -eq 0 ]]; then
  TARGET_DIRS=("prod-app" "nonprod-app")
fi

for root_name in "${TARGET_DIRS[@]}"; do
  root_dir="${ROOT_DIR}/${root_name}"

  if [[ ! -d "${root_dir}" ]]; then
    printf "Unknown deployment root: %s\n" "${root_name}" >&2
    exit 2
  fi

  printf "[root:%s] Validating deployment root\n" "${root_name}"
  if ! run_root_step "${root_name}" "init" "${INIT_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${root_dir}" init "${INIT_ARGS[@]}"; then
    FAILURES=1
    continue
  fi

  if ! run_root_step "${root_name}" "validate" "${VALIDATE_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${root_dir}" validate -no-color; then
    FAILURES=1
  fi
done

if [[ ${FAILURES} -ne 0 ]]; then
  exit 1
fi
