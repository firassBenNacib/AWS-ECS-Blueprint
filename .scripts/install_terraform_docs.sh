#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-${ROOT_DIR}/.tmp-bin}"
TERRAFORM_DOCS_VERSION="${TERRAFORM_DOCS_VERSION:-v0.21.0}"
TERRAFORM_DOCS_BIN="${LOCAL_BIN_DIR}/terraform-docs"
LOCK_DIR="${LOCAL_BIN_DIR}/.terraform-docs.lock"
TMP_DIR=""

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "Missing required checksum tool: sha256sum or shasum" >&2
    exit 1
  fi
}

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
CHECKSUMS_PATH="${TMP_DIR}/terraform-docs.sha256sum"
ARCHIVE_NAME="terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz"
CHECKSUM_ASSET_NAME="terraform-docs-${TERRAFORM_DOCS_VERSION}.sha256sum"

curl -sSfL \
  "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/${ARCHIVE_NAME}" \
  -o "${ARCHIVE_PATH}"
curl -sSfL \
  "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/${CHECKSUM_ASSET_NAME}" \
  -o "${CHECKSUMS_PATH}"

EXPECTED_CHECKSUM="$(awk -v archive="${ARCHIVE_NAME}" '$2 == archive { print $1; exit }' "${CHECKSUMS_PATH}")"
ACTUAL_CHECKSUM="$(sha256_file "${ARCHIVE_PATH}")"

if [[ -z "${EXPECTED_CHECKSUM}" ]]; then
  echo "Failed to resolve expected checksum for ${ARCHIVE_NAME}" >&2
  exit 1
fi

if [[ "${ACTUAL_CHECKSUM}" != "${EXPECTED_CHECKSUM}" ]]; then
  echo "Checksum verification failed for ${ARCHIVE_NAME}" >&2
  exit 1
fi

tar -xzf "${ARCHIVE_PATH}" -C "${TMP_DIR}" terraform-docs
install "${TMP_DIR}/terraform-docs" "${TERRAFORM_DOCS_BIN}"
