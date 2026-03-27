#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_BIN="${TF_BIN:-terraform}"
PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${ROOT_DIR}/.terraform.d/plugin-cache}"
INIT_ARGS=(-backend=false -input=false)
INIT_TIMEOUT_SECONDS="${MODULE_INIT_TIMEOUT_SECONDS:-180}"
VALIDATE_TIMEOUT_SECONDS="${MODULE_VALIDATE_TIMEOUT_SECONDS:-120}"
TEMP_DIR="$(mktemp -d)"
RUN_PLUGIN_CACHE_DIR="${TEMP_DIR}/plugin-cache"

cleanup() {
  rm -rf "${TEMP_DIR}"
}

trap cleanup EXIT

mkdir -p "${PLUGIN_CACHE_DIR}"
mkdir -p "${RUN_PLUGIN_CACHE_DIR}"

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
  local prefix=$1
  local output_file=$2

  sed -e '/^$/d' -e "s/^/${prefix} /" "${output_file}"
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
      if [[ -s "${output_file}" && "${phase}" != "init" ]]; then
        prefix_output "[module:${module_name}]" "${output_file}"
      fi
      rm -f "${output_file}"
      return 0
    fi

    if [[ ${attempt} -eq 1 ]] && is_retryable_provider_failure "${output_file}"; then
      printf "[module:%s] Transient provider/network failure during %s; retrying once.\n" "${module_name}" "${phase}"
      attempt=2
      sleep 2
      continue
    fi

    if [[ ${rc} -eq 124 ]]; then
      printf "[module:%s] %s timed out after %ss.\n" "${module_name}" "${phase}" "${timeout_seconds}"
    fi
    prefix_output "[module:${module_name}]" "${output_file}" >&2
    rm -f "${output_file}"
    return "${rc}"
  done
}

has_aws_provider_config() {
  local module_dir=$1
  local pattern='^[[:space:]]*provider[[:space:]]+"aws"'

  if command -v rg >/dev/null 2>&1; then
    rg -q "${pattern}" "${module_dir}"
    return
  fi

  grep -R -q -E \
    --include='*.tf' \
    --include='*.tf.json' \
    "${pattern}" \
    "${module_dir}"
}

tar --exclude='.terraform' --exclude='.terraform.lock.hcl' -cf - -C "${ROOT_DIR}" modules | tar -xf - -C "${TEMP_DIR}"

MODULE_FILTER="${1:-}"
FAILURES=0
FOUND_MODULE="false"

mapfile -t MODULE_DIRS < <(find "${TEMP_DIR}/modules" -mindepth 1 -maxdepth 1 -type d | sort)

for temp_module_dir in "${MODULE_DIRS[@]}"; do
  module_name="$(basename "${temp_module_dir}")"

  if [[ -n "${MODULE_FILTER}" && "${module_name}" != "${MODULE_FILTER}" ]]; then
    continue
  fi

  FOUND_MODULE="true"

  rm -rf "${temp_module_dir}/.terraform" "${temp_module_dir}/.terraform.lock.hcl" "${temp_module_dir}/zz_validation_providers.tf"

  if ! has_aws_provider_config "${temp_module_dir}"; then
    cat > "${temp_module_dir}/zz_validation_providers.tf" <<'EOF'
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias                       = "dr"
  region                      = "us-west-2"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias                       = "us_east_1"
  region                      = "us-east-1"
  access_key                  = "mock-access-key"
  secret_key                  = "mock-secret-key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
EOF
  fi

  printf "[module:%s] Validating reusable module\n" "${module_name}"
  if ! run_module_step "${module_name}" "init" "${INIT_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${RUN_PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${temp_module_dir}" init "${INIT_ARGS[@]}"; then
    FAILURES=1
    continue
  fi

  if ! run_module_step "${module_name}" "validate" "${VALIDATE_TIMEOUT_SECONDS}" \
    env TF_PLUGIN_CACHE_DIR="${RUN_PLUGIN_CACHE_DIR}" "${TF_BIN}" -chdir="${temp_module_dir}" validate -no-color; then
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
