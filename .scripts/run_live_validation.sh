#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --path PATH --workspace WORKSPACE --tfvars-file FILE --aws-region REGION --smoke-profile PROFILE --log-dir DIR" >&2
  exit 1
}

PATH_ARG=""
WORKSPACE=""
TFVARS_FILE=""
AWS_REGION=""
SMOKE_PROFILE=""
LOG_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      PATH_ARG=$2
      shift 2
      ;;
    --workspace)
      WORKSPACE=$2
      shift 2
      ;;
    --tfvars-file)
      TFVARS_FILE=$2
      shift 2
      ;;
    --aws-region)
      AWS_REGION=$2
      shift 2
      ;;
    --smoke-profile)
      SMOKE_PROFILE=$2
      shift 2
      ;;
    --log-dir)
      LOG_DIR=$2
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "${PATH_ARG}" && -n "${WORKSPACE}" && -n "${TFVARS_FILE}" && -n "${AWS_REGION}" && -n "${SMOKE_PROFILE}" && -n "${LOG_DIR}" ]] || usage

mkdir -p "${LOG_DIR}"

initialized=0
main_status=0
destroy_status=0
tf_data_dir="${LOG_DIR}/tfdata"
state_file="${LOG_DIR}/terraform.tfstate"

cleanup() {
  local exit_code=$?
  set +e

  if [[ "${main_status}" -eq 0 && "${exit_code}" -ne 0 ]]; then
    main_status=${exit_code}
  fi

  if [[ "${initialized}" -eq 1 ]]; then
    TF_DATA_DIR="${tf_data_dir}" terraform -chdir="${PATH_ARG}" init -backend=false -reconfigure > "${LOG_DIR}/destroy-init.log" 2>&1 || true

    if [[ -f "${state_file}" ]]; then
      TF_DATA_DIR="${tf_data_dir}" terraform -chdir="${PATH_ARG}" destroy \
        -auto-approve \
        -input=false \
        -state="${state_file}" \
        -var="live_validation_mode=true" \
        -var-file="${TFVARS_FILE}" > "${LOG_DIR}/destroy.log" 2>&1
      destroy_status=$?
    fi
  fi

  if [[ "${main_status}" -eq 0 && "${destroy_status}" -ne 0 ]]; then
    exit "${destroy_status}"
  fi
  exit "${main_status}"
}

trap cleanup EXIT

TF_DATA_DIR="${tf_data_dir}" terraform -chdir="${PATH_ARG}" init -backend=false -reconfigure > "${LOG_DIR}/init.log" 2>&1
initialized=1

echo "Using isolated local state at ${state_file}" > "${LOG_DIR}/workspace.log"

TF_DATA_DIR="${tf_data_dir}" terraform -chdir="${PATH_ARG}" apply \
  -auto-approve \
  -input=false \
  -state="${state_file}" \
  -var="live_validation_mode=true" \
  -var-file="${TFVARS_FILE}" > "${LOG_DIR}/apply.log" 2>&1
bash .scripts/run_live_validation_checks.sh \
  --path "${PATH_ARG}" \
  --state-file "${state_file}" \
  --aws-region "${AWS_REGION}" \
  --smoke-profile "${SMOKE_PROFILE}" > "${LOG_DIR}/smoke.log" 2>&1

main_status=0
