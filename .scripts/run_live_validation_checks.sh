#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --path PATH --aws-region REGION --smoke-profile PROFILE" >&2
  exit 1
}

PATH_ARG=""
AWS_REGION=""
SMOKE_PROFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      PATH_ARG=$2
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
    *)
      usage
      ;;
  esac
done

[[ -n "${PATH_ARG}" && -n "${AWS_REGION}" && -n "${SMOKE_PROFILE}" ]] || usage

terraform_output_raw() {
  local output_name=$1
  terraform -chdir="${PATH_ARG}" output -raw "${output_name}" 2>/dev/null || true
}

check_http_endpoint() {
  local name=$1
  local raw_value
  raw_value="$(terraform_output_raw "${name}")"
  if [[ -z "${raw_value}" ]]; then
    return 0
  fi

  local url="${raw_value}"
  if [[ ! "${url}" =~ ^https?:// ]]; then
    url="https://${url}"
  fi

  local status
  status="$(curl -ksS -o /dev/null -w '%{http_code}' --max-time 30 "${url}")"
  case "${status}" in
    2*|3*|401|403|404)
      echo "HTTP check passed for ${name}: ${url} -> ${status}"
      ;;
    *)
      echo "HTTP check failed for ${name}: ${url} -> ${status}" >&2
      return 1
      ;;
  esac
}

check_app_profile() {
  local ecs_cluster ecs_service desired running rds_instance_id rds_status

  ecs_cluster="$(terraform_output_raw backend_ecs_cluster_name)"
  ecs_service="$(terraform_output_raw backend_ecs_service_name)"
  if [[ -n "${ecs_cluster}" && -n "${ecs_service}" ]]; then
    desired="$(aws ecs describe-services \
      --cluster "${ecs_cluster}" \
      --services "${ecs_service}" \
      --region "${AWS_REGION}" \
      --query 'services[0].desiredCount' \
      --output text)"
    running="$(aws ecs describe-services \
      --cluster "${ecs_cluster}" \
      --services "${ecs_service}" \
      --region "${AWS_REGION}" \
      --query 'services[0].runningCount' \
      --output text)"
    if [[ "${desired}" == "None" || "${running}" == "None" || "${desired}" -lt 1 || "${running}" -lt 1 ]]; then
      echo "ECS service is not healthy: cluster=${ecs_cluster} service=${ecs_service} desired=${desired} running=${running}" >&2
      return 1
    fi
    echo "ECS check passed: cluster=${ecs_cluster} service=${ecs_service} desired=${desired} running=${running}"
  fi

  rds_instance_id="$(terraform_output_raw rds_instance_id)"
  if [[ -n "${rds_instance_id}" ]]; then
    rds_status="$(aws rds describe-db-instances \
      --db-instance-identifier "${rds_instance_id}" \
      --region "${AWS_REGION}" \
      --query 'DBInstances[0].DBInstanceStatus' \
      --output text)"
    if [[ "${rds_status}" != "available" ]]; then
      echo "RDS instance is not available: ${rds_instance_id} status=${rds_status}" >&2
      return 1
    fi
    echo "RDS check passed: ${rds_instance_id} status=${rds_status}"
  fi

  check_http_endpoint backend_cloudfront_url
  check_http_endpoint frontend_cloudfront_url
  check_http_endpoint backend_alb_dns_name
}

check_security_profile() {
  local cloudtrail_arn cloudtrail_name trail_status detector_id detector_status log_bucket_name

  cloudtrail_arn="$(terraform_output_raw cloudtrail_arn)"
  if [[ -n "${cloudtrail_arn}" ]]; then
    cloudtrail_name="${cloudtrail_arn##*/}"
    trail_status="$(aws cloudtrail get-trail-status \
      --name "${cloudtrail_name}" \
      --region "${AWS_REGION}" \
      --query 'IsLogging' \
      --output text)"
    if [[ "${trail_status}" != "True" ]]; then
      echo "CloudTrail is not logging: ${cloudtrail_name}" >&2
      return 1
    fi
    echo "CloudTrail check passed: ${cloudtrail_name}"
  fi

  detector_id="$(terraform_output_raw guardduty_detector_id)"
  if [[ -n "${detector_id}" ]]; then
    detector_status="$(aws guardduty get-detector \
      --detector-id "${detector_id}" \
      --region "${AWS_REGION}" \
      --query 'Status' \
      --output text)"
    if [[ "${detector_status}" != "ENABLED" ]]; then
      echo "GuardDuty detector is not enabled: ${detector_id}" >&2
      return 1
    fi
    echo "GuardDuty check passed: ${detector_id}"
  fi

  log_bucket_name="$(terraform_output_raw log_bucket_name)"
  if [[ -n "${log_bucket_name}" ]]; then
    aws s3api head-bucket --bucket "${log_bucket_name}" --region "${AWS_REGION}" >/dev/null
    echo "S3 log bucket check passed: ${log_bucket_name}"
  fi
}

case "${SMOKE_PROFILE}" in
  app)
    check_app_profile
    ;;
  security)
    check_security_profile
    ;;
  none)
    echo "No smoke checks registered for profile=${SMOKE_PROFILE}"
    ;;
  *)
    echo "Unknown smoke profile: ${SMOKE_PROFILE}" >&2
    exit 1
    ;;
esac
