#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

paths=(
  "${ROOT_DIR}/security-reports"
  "${ROOT_DIR}/state-backups"
  "${ROOT_DIR}/.terraform.d/plugin-cache"
  "${ROOT_DIR}/.tmp-bin"
  "${ROOT_DIR}/.tmpbin"
  "${ROOT_DIR}/checkov.json"
  "${ROOT_DIR}/tflint.txt"
)

for path in "${paths[@]}"; do
  if [[ -d "${path}" ]]; then
    rm -rf "${path}"
  elif [[ -f "${path}" ]]; then
    rm -f "${path}"
  fi
done

find "${ROOT_DIR}" -type d \( -name "__pycache__" -o -name ".terraform" \) -prune -exec sh -c '
  for dir do
    rm -rf "$dir"
  done
' sh {} +

find "${ROOT_DIR}" -depth -type d \( -name ".terraform.d" -o -name "security-reports" -o -name "state-backups" \) -empty -delete

echo "Cleaned local generated artifacts."
