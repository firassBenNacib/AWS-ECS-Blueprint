#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-${ROOT_DIR}/.tmp-bin}"
TERRAFORM_DOCS_VERSION="${TERRAFORM_DOCS_VERSION:-v0.21.0}"
TERRAFORM_DOCS_BIN="${LOCAL_BIN_DIR}/terraform-docs"
LOCK_DIR="${LOCAL_BIN_DIR}/.terraform-docs.lock"
TMP_DIR=""

cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
  rm -rf "${LOCK_DIR}"
}

if command -v terraform-docs >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "${LOCAL_BIN_DIR}"
trap cleanup EXIT

while ! mkdir "${LOCK_DIR}" 2>/dev/null; do
  sleep 1
done

if command -v terraform-docs >/dev/null 2>&1; then
  exit 0
fi

TMP_DIR="$(mktemp -d)"
ARCHIVE_PATH="${TMP_DIR}/terraform-docs.tar.gz"

curl -sSfL \
  "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz" \
  -o "${ARCHIVE_PATH}"
tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}" terraform-docs
install "${TMP_DIR}/terraform-docs" "${TERRAFORM_DOCS_BIN}"
