#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "Usage: $0 <write|check> [modules_dir]" >&2
  exit 1
}

require_binary() {
  if ! command -v terraform-docs >/dev/null 2>&1; then
    echo "terraform-docs is required on PATH" >&2
    exit 1
  fi
}

resolve_modules() {
  local modules_dir=$1
  find "${modules_dir}" \
    -path '*/.terraform' -prune -o \
    -type f -name "main.tf" -printf '%h\n' | sort -u
}

write_docs() {
  local module_dir=$1
  terraform-docs --config "${ROOT_DIR}/.tfdocs.yaml" "${module_dir}" >/dev/null
}

check_docs() {
  local module_dir=$1
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  tar --exclude='.terraform' --exclude='.terraform.lock.hcl' -cf - -C "${module_dir}" . | tar -xf - -C "${tmp_dir}"
  terraform-docs --config "${ROOT_DIR}/.tfdocs.yaml" "${tmp_dir}" >/dev/null
  if [[ ! -f "${module_dir}/README.md" ]]; then
    echo "Missing ${module_dir}/README.md" >&2
    rm -rf "${tmp_dir}"
    return 1
  fi
  if ! diff -u "${module_dir}/README.md" "${tmp_dir}/README.md"; then
    echo "terraform-docs drift detected in ${module_dir}" >&2
    rm -rf "${tmp_dir}"
    return 1
  fi
  rm -rf "${tmp_dir}"
}

main() {
  local mode=${1:-}
  local modules_dir=${2:-modules}

  [[ -n "${mode}" ]] || usage
  require_binary

  local module_dir
  local failed=0
  while IFS= read -r module_dir; do
    case "${mode}" in
      write)
        write_docs "${module_dir}"
        ;;
      check)
        if ! check_docs "${module_dir}"; then
          failed=1
        fi
        ;;
      *)
        usage
        ;;
    esac
  done < <(resolve_modules "${modules_dir}")

  if [[ "${failed}" -ne 0 ]]; then
    echo "Rebuild module documentation with: bash .scripts/terraform_docs_gate.sh write" >&2
    exit 1
  fi
}

main "$@"
