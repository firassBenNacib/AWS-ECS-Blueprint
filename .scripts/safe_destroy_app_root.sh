#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: safe_destroy_app_root.sh --root <deployment-root> [--tfvars <file>] [--cleanup-secrets]

Safely destroys an app deployment root by:
1. disabling ALB and RDS deletion protection via AWS APIs,
2. removing S3 replication config and emptying versioned buckets (including governance-locked objects),
3. running terraform destroy with destroy-mode overrides,
4. optionally deleting app secrets referenced by the deployment environment.
EOF
}

ROOT_DIR=""
TFVARS_FILE="terraform.tfvars"
CLEANUP_SECRETS="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR="$2"
      shift 2
      ;;
    --tfvars)
      TFVARS_FILE="$2"
      shift 2
      ;;
    --cleanup-secrets)
      CLEANUP_SECRETS="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${ROOT_DIR}" ]]; then
  echo "--root is required" >&2
  usage >&2
  exit 1
fi

ROOT_DIR="$(cd "${ROOT_DIR}" && pwd)"
if [[ "${TFVARS_FILE}" = /* ]]; then
  TFVARS_PATH="${TFVARS_FILE}"
else
  TFVARS_PATH="${ROOT_DIR}/${TFVARS_FILE}"
fi

if [[ ! -f "${TFVARS_PATH}" ]]; then
  echo "tfvars file not found: ${TFVARS_PATH}" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required" >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required" >&2
  exit 1
fi

read_tfvar() {
  local key="$1"
  python3 - "$TFVARS_PATH" "$key" <<'PY'
import re
import sys

path, key = sys.argv[1], sys.argv[2]
pattern = re.compile(rf'^\s*{re.escape(key)}\s*=\s*(.+?)\s*$')
with open(path, 'r', encoding='utf-8') as handle:
    for raw_line in handle:
        line = raw_line.split('#', 1)[0].rstrip()
        match = pattern.match(line)
        if not match:
            continue
        value = match.group(1).strip()
        if value == "null":
            print("")
            raise SystemExit(0)
        if value.startswith('"') and value.endswith('"'):
            print(value[1:-1])
            raise SystemExit(0)
        print(value)
        raise SystemExit(0)
print("")
PY
}

AWS_REGION="$(read_tfvar aws_region)"
if [[ -z "${AWS_REGION}" ]]; then
  echo "Could not determine aws_region from ${TFVARS_PATH}" >&2
  exit 1
fi

ENVIRONMENT_PREFIX=""
case "$(basename "${ROOT_DIR}")" in
  prod-app) ENVIRONMENT_PREFIX="prod/" ;;
  nonprod-app) ENVIRONMENT_PREFIX="nonprod/" ;;
esac

OVERRIDE_FILE="$(mktemp)"
cleanup_override() {
  rm -f "${OVERRIDE_FILE}"
}
trap cleanup_override EXIT

cat > "${OVERRIDE_FILE}" <<'EOF'
destroy_mode_enabled = true
security_baseline_enable_object_lock = false
rds_deletion_protection = false
rds_skip_final_snapshot_on_destroy = true
EOF

state_value() {
  local address="$1"
  local key="$2"
  terraform -chdir="${ROOT_DIR}" state show -no-color "${address}" | sed -n "s/^    ${key} *= *\"\\(.*\\)\"/\\1/p" | head -n 1
}

state_list_matching() {
  local pattern="$1"
  terraform -chdir="${ROOT_DIR}" state list | grep -E "${pattern}" || true
}

disable_alb_deletion_protection() {
  local alb_address
  alb_address="$(state_list_matching 'aws_lb\.this$' | head -n 1)"
  [[ -z "${alb_address}" ]] && return 0

  local alb_arn region
  alb_arn="$(state_value "${alb_address}" arn)"
  region="$(state_value "${alb_address}" region)"
  [[ -z "${alb_arn}" || -z "${region}" ]] && return 0

  echo "Disabling ALB deletion protection for ${alb_arn}"
  aws elbv2 modify-load-balancer-attributes \
    --region "${region}" \
    --load-balancer-arn "${alb_arn}" \
    --attributes Key=deletion_protection.enabled,Value=false >/dev/null
}

disable_rds_deletion_protection() {
  local rds_address
  rds_address="$(state_list_matching 'aws_db_instance\.this$' | head -n 1)"
  [[ -z "${rds_address}" ]] && return 0

  local identifier region
  identifier="$(state_value "${rds_address}" identifier)"
  region="$(state_value "${rds_address}" region)"
  [[ -z "${identifier}" || -z "${region}" ]] && return 0

  echo "Disabling RDS deletion protection for ${identifier}"
  aws rds modify-db-instance \
    --region "${region}" \
    --db-instance-identifier "${identifier}" \
    --no-deletion-protection \
    --apply-immediately >/dev/null
  aws rds wait db-instance-available \
    --region "${region}" \
    --db-instance-identifier "${identifier}"
}

empty_bucket_versions() {
  local bucket="$1"
  local region="$2"
  local object_lock_enabled="$3"

  echo "Removing replication config from ${bucket}"
  aws s3api delete-bucket-replication --bucket "${bucket}" --region "${region}" >/dev/null 2>&1 || true

  python3 - "${bucket}" "${region}" "${object_lock_enabled}" <<'PY'
import json
import subprocess
import sys

bucket, region, object_lock_enabled = sys.argv[1], sys.argv[2], sys.argv[3] == "true"

def run_json(command):
    output = subprocess.check_output(command, text=True)
    return json.loads(output) if output.strip() else {}

key_marker = None
version_marker = None

while True:
    command = [
        "aws", "s3api", "list-object-versions",
        "--bucket", bucket,
        "--region", region,
        "--output", "json",
    ]
    if key_marker:
        command.extend(["--key-marker", key_marker])
    if version_marker:
        command.extend(["--version-id-marker", version_marker])

    data = run_json(command)
    items = []
    for group in ("Versions", "DeleteMarkers"):
        for item in data.get(group, []):
            items.append((item["Key"], item["VersionId"]))

    for key, version_id in items:
        delete_cmd = [
            "aws", "s3api", "delete-object",
            "--bucket", bucket,
            "--region", region,
            "--key", key,
            "--version-id", version_id,
        ]
        if object_lock_enabled:
            delete_cmd.append("--bypass-governance-retention")
        subprocess.check_call(delete_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    if not data.get("IsTruncated", False):
        break

    key_marker = data.get("NextKeyMarker")
    version_marker = data.get("NextVersionIdMarker")
PY
}

empty_managed_buckets() {
  mapfile -t bucket_addresses < <(state_list_matching 'aws_s3_bucket\.')
  [[ ${#bucket_addresses[@]} -eq 0 ]] && return 0

  for address in "${bucket_addresses[@]}"; do
    local bucket region object_lock_enabled
    bucket="$(state_value "${address}" bucket)"
    region="$(state_value "${address}" region)"
    object_lock_enabled="$(terraform -chdir="${ROOT_DIR}" state show -no-color "${address}" | sed -n 's/^    object_lock_enabled *= *\(.*\)$/\1/p' | head -n 1)"
    [[ -z "${bucket}" || -z "${region}" ]] && continue
    [[ "${object_lock_enabled}" == "true" ]] || object_lock_enabled="false"
    echo "Emptying bucket ${bucket} in ${region}"
    empty_bucket_versions "${bucket}" "${region}" "${object_lock_enabled}"
  done
}

cleanup_secrets() {
  [[ "${CLEANUP_SECRETS}" == "true" ]] || return 0

  if [[ -n "${ENVIRONMENT_PREFIX}" ]]; then
    mapfile -t secret_names < <(aws secretsmanager list-secrets \
      --region "${AWS_REGION}" \
      --query "SecretList[?starts_with(Name, \`${ENVIRONMENT_PREFIX}\`)].Name" \
      --output text | tr '\t' '\n' | sed '/^$/d')

    for secret_name in "${secret_names[@]}"; do
      echo "Deleting secret ${secret_name}"
      aws secretsmanager delete-secret \
        --region "${AWS_REGION}" \
        --secret-id "${secret_name}" \
        --force-delete-without-recovery >/dev/null
    done
  fi

  local rds_address secret_arn
  rds_address="$(state_list_matching 'aws_db_instance\.this$' | head -n 1)"
  if [[ -n "${rds_address}" ]]; then
    secret_arn="$(terraform -chdir="${ROOT_DIR}" state show -no-color "${rds_address}" | sed -n 's/^            secret_arn *= *"\(.*\)"/\1/p' | head -n 1)"
    if [[ -n "${secret_arn}" ]]; then
      echo "Deleting RDS master secret ${secret_arn}"
      aws secretsmanager delete-secret \
        --region "${AWS_REGION}" \
        --secret-id "${secret_arn}" \
        --force-delete-without-recovery >/dev/null 2>&1 || true
    fi
  fi
}

disable_alb_deletion_protection
disable_rds_deletion_protection
empty_managed_buckets

terraform -chdir="${ROOT_DIR}" destroy \
  -auto-approve \
  -var-file="${TFVARS_PATH}" \
  -var-file="${OVERRIDE_FILE}"

cleanup_secrets

echo "Safe destroy completed for ${ROOT_DIR}"
