#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

mapfile -t BACKEND_FILES < <(find "${ROOT_DIR}" -maxdepth 3 -type f \( -name "backend.hcl" -o -name "backend.hcl.example" \) | sort)

if [ ${#BACKEND_FILES[@]} -eq 0 ]; then
  echo "No backend.hcl files found under ${ROOT_DIR}"
  exit 1
fi

declare -A KEY_TO_FILE=()
EXIT_CODE=0

for file in "${BACKEND_FILES[@]}"; do
  if [[ "${file}" == *.example ]]; then
    real_file="${file%.example}"
    if [[ -f "${real_file}" ]]; then
      continue
    fi
  fi

  key_line="$(awk -F '=' '/^[[:space:]]*key[[:space:]]*=/{print $2; exit}' "${file}" | tr -d '"' | xargs || true)"
  if [ -z "${key_line}" ]; then
    echo "[ERROR] Missing backend key in ${file}"
    EXIT_CODE=1
    continue
  fi

  if [[ "${key_line}" == *"terraform.tfstate"* ]]; then
    :
  else
    echo "[ERROR] Backend key should end with terraform.tfstate: ${file} -> ${key_line}"
    EXIT_CODE=1
  fi

  if [[ -n "${KEY_TO_FILE[${key_line}]:-}" ]]; then
    echo "[ERROR] Duplicate backend key detected: ${key_line}"
    echo "        - ${KEY_TO_FILE[${key_line}]}"
    echo "        - ${file}"
    EXIT_CODE=1
  else
    KEY_TO_FILE["${key_line}"]="${file}"
  fi

done

if [ ${EXIT_CODE} -ne 0 ]; then
  exit ${EXIT_CODE}
fi

echo "Backend key strategy check passed (${#BACKEND_FILES[@]} files)."
