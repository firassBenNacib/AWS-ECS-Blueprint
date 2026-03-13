#!/usr/bin/env bash
set -euo pipefail

DEPLOYMENT_ROOT_DIR="${1:-}"
BACKEND_CONFIG="${2:-}"
OUT_DIR="${3:-state-backups}"

if [ -z "${DEPLOYMENT_ROOT_DIR}" ]; then
  echo "Usage: $0 <deployment_root_dir> [backend_config_file] [output_dir]"
  exit 1
fi

if [ ! -d "${DEPLOYMENT_ROOT_DIR}" ]; then
  echo "Deployment root directory not found: ${DEPLOYMENT_ROOT_DIR}"
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "Missing terraform command"
  exit 1
fi

DEPLOYMENT_ROOT_NAME="$(basename "${DEPLOYMENT_ROOT_DIR}")"
TS="$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "${OUT_DIR}"

INIT_ARGS=("-reconfigure")
if [ -n "${BACKEND_CONFIG}" ]; then
  if [ ! -f "${BACKEND_CONFIG}" ]; then
    echo "Backend config file not found: ${BACKEND_CONFIG}"
    exit 1
  fi
  INIT_ARGS+=("-backend-config=${BACKEND_CONFIG}")
fi

echo "Initializing backend for ${DEPLOYMENT_ROOT_NAME}..."
terraform -chdir="${DEPLOYMENT_ROOT_DIR}" init "${INIT_ARGS[@]}" >/dev/null

STATE_FILE="${OUT_DIR}/${DEPLOYMENT_ROOT_NAME}-state-${TS}.json"
MANIFEST_FILE="${OUT_DIR}/${DEPLOYMENT_ROOT_NAME}-snapshot-${TS}.sha256"

echo "Pulling remote state into ${STATE_FILE}..."
terraform -chdir="${DEPLOYMENT_ROOT_DIR}" state pull > "${STATE_FILE}"

FILES_TO_HASH=("${STATE_FILE}")

if [ -d "security-reports/${DEPLOYMENT_ROOT_NAME}" ]; then
  REPORT_ARCHIVE="${OUT_DIR}/${DEPLOYMENT_ROOT_NAME}-security-reports-${TS}.tar.gz"
  echo "Archiving security reports into ${REPORT_ARCHIVE}..."
  tar -czf "${REPORT_ARCHIVE}" -C security-reports "${DEPLOYMENT_ROOT_NAME}"
  FILES_TO_HASH+=("${REPORT_ARCHIVE}")
fi

echo "Generating hash manifest ${MANIFEST_FILE}..."
sha256sum "${FILES_TO_HASH[@]}" > "${MANIFEST_FILE}"

echo "Snapshot complete."
echo "- State: ${STATE_FILE}"
if [ -f "${REPORT_ARCHIVE:-}" ]; then
  echo "- Reports: ${REPORT_ARCHIVE}"
fi
echo "- Manifest: ${MANIFEST_FILE}"
