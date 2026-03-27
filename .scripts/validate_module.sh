#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_MODULES_SCRIPT="${ROOT_DIR}/.scripts/validate_modules.sh"

if [[ $# -ne 1 || -z "${1}" ]]; then
  printf "Usage: %s <module-name>\n" "$(basename "$0")" >&2
  exit 2
fi

MODULE_NAME="${1}"

if [[ ! -d "${ROOT_DIR}/modules/${MODULE_NAME}" ]]; then
  printf "Unknown module: %s\n" "${MODULE_NAME}" >&2
  exit 2
fi

bash "${VALIDATE_MODULES_SCRIPT}" "${MODULE_NAME}"
