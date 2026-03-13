#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_BIN="${TF_BIN:-terraform}"
PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${ROOT_DIR}/.terraform.d/plugin-cache}"
INIT_ARGS=(-backend=false -input=false)
TEMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TEMP_DIR}"
}

trap cleanup EXIT

mkdir -p "${PLUGIN_CACHE_DIR}"

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

find "${TEMP_DIR}/modules" -mindepth 1 -maxdepth 1 -type d | sort | while read -r temp_module_dir; do
  module_name="$(basename "${temp_module_dir}")"

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
EOF
  fi

  printf "Validating module: %s\n" "${module_name}"
  "${TF_BIN}" -chdir="${temp_module_dir}" init "${INIT_ARGS[@]}" >/dev/null
  "${TF_BIN}" -chdir="${temp_module_dir}" validate
done
