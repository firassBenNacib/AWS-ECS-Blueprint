#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: init_app_root.sh --root <deployment-root> [--require-backend]

Initializes a deployment root for local plan/apply-style commands.
- Uses backend.hcl when present
- Falls back to TF_BACKEND_BUCKET/TF_BACKEND_REGION when available
- Falls back to -backend=false when no backend config is available
- Reuses a healthy existing initialization when the backend/provider fingerprint still matches
EOF
}

ROOT_DIR=""
REQUIRE_BACKEND="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR="$2"
      shift 2
      ;;
    --require-backend)
      REQUIRE_BACKEND="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${ROOT_DIR}" ]]; then
  printf '--root is required\n' >&2
  usage >&2
  exit 1
fi

ROOT_DIR="$(cd "${ROOT_DIR}" && pwd)"
ROOT_NAME="$(basename "${ROOT_DIR}")"
BACKEND_HCL_PATH="${ROOT_DIR}/backend.hcl"
TF_BIN="${TF_BIN:-terraform}"
INIT_STATE_DIR="${ROOT_DIR}/.terraform"
INIT_FINGERPRINT_PATH="${INIT_STATE_DIR}/.codex-init-fingerprint"
INIT_TIMEOUT_SECONDS="${ROOT_INIT_TIMEOUT_SECONDS:-180}"

init_args=(-input=false)
backend_mode=""
backend_key=""
backend_region=""

if [[ -f "${BACKEND_HCL_PATH}" ]]; then
  backend_mode="backend-hcl"
  init_args+=(-reconfigure "-backend-config=${BACKEND_HCL_PATH}")
elif [[ -n "${TF_BACKEND_BUCKET:-}" ]]; then
  case "${ROOT_NAME}" in
    prod-app)
      backend_key="prod-app/prod/terraform.tfstate"
      ;;
    nonprod-app)
      backend_key="nonprod-app/nonprod/terraform.tfstate"
      ;;
    *)
      printf 'Cannot infer backend key for %s\n' "${ROOT_NAME}" >&2
      exit 1
      ;;
  esac

  backend_mode="backend-env"
  backend_region="${TF_BACKEND_REGION:-${AWS_REGION:-eu-west-1}}"
  init_args+=(
    -reconfigure
    "-backend-config=bucket=${TF_BACKEND_BUCKET}"
    "-backend-config=key=${backend_key}"
    "-backend-config=region=${backend_region}"
    "-backend-config=encrypt=true"
  )
else
  if [[ "${REQUIRE_BACKEND}" == "true" ]]; then
    printf 'Missing backend configuration for %s\n' "${ROOT_NAME}" >&2
    printf 'Provide backend.hcl or TF_BACKEND_BUCKET/TF_BACKEND_REGION before retrying.\n' >&2
    exit 1
  fi

  backend_mode="backend-disabled"
  init_args+=(-backend=false -lockfile=readonly)
fi

hash_file() {
  local path=$1

  if [[ ! -f "${path}" ]]; then
    printf 'missing'
    return 0
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
    return 0
  fi

  python3 - "${path}" <<'PY'
import hashlib
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
print(hashlib.sha256(path.read_bytes()).hexdigest())
PY
}

compute_fingerprint() {
  local lockfile_hash backend_hash
  lockfile_hash="$(hash_file "${ROOT_DIR}/.terraform.lock.hcl")"
  backend_hash="$(hash_file "${BACKEND_HCL_PATH}")"

  printf '%s\n' \
    "root=${ROOT_NAME}" \
    "backend_mode=${backend_mode}" \
    "backend_bucket=${TF_BACKEND_BUCKET:-}" \
    "backend_key=${backend_key}" \
    "backend_region=${backend_region}" \
    "backend_hash=${backend_hash}" \
    "lockfile_hash=${lockfile_hash}" | {
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
      else
        python3 - <<'PY'
import hashlib
import sys

print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())
PY
      fi
    }
}

providers_ready() {
  [[ -f "${INIT_STATE_DIR}/terraform.tfstate" ]] || return 1
  [[ -d "${INIT_STATE_DIR}/providers" ]] || return 1
  [[ -f "${INIT_FINGERPRINT_PATH}" ]] || return 1
  [[ "$(<"${INIT_FINGERPRINT_PATH}")" == "${1}" ]] || return 1

  TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-}" "${TF_BIN}" -chdir="${ROOT_DIR}" providers schema -json >/dev/null 2>&1
}

run_init() {
  if command -v timeout >/dev/null 2>&1; then
    timeout --foreground "${INIT_TIMEOUT_SECONDS}" \
      env TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-}" "${TF_BIN}" -chdir="${ROOT_DIR}" init "${init_args[@]}" >/dev/null
    return $?
  fi

  env TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-}" "${TF_BIN}" -chdir="${ROOT_DIR}" init "${init_args[@]}" >/dev/null
}

fingerprint="$(compute_fingerprint)"

if providers_ready "${fingerprint}"; then
  exit 0
fi

printf 'Initializing Terraform in %s\n' "${ROOT_NAME}" >&2
mkdir -p "${INIT_STATE_DIR}"

if ! run_init; then
  printf 'Terraform initialization failed for %s\n' "${ROOT_NAME}" >&2
  exit 1
fi

printf '%s' "${fingerprint}" > "${INIT_FINGERPRINT_PATH}"
