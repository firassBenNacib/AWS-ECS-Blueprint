#!/usr/bin/env bash
set -euo pipefail

LIVE_VALIDATION_INSECURE_TLS="${LIVE_VALIDATION_INSECURE_TLS:-false}"

usage() {
  echo "Usage: $0 --path PATH --state-file FILE --aws-region REGION --smoke-profile PROFILE" >&2
  exit 1
}

PATH_ARG=""
STATE_FILE=""
AWS_REGION=""
SMOKE_PROFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      PATH_ARG=$2
      shift 2
      ;;
    --state-file)
      STATE_FILE=$2
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

[[ -n "${PATH_ARG}" && -n "${STATE_FILE}" && -n "${AWS_REGION}" && -n "${SMOKE_PROFILE}" ]] || usage

terraform_output_raw() {
  local output_name=$1
  terraform -chdir="${PATH_ARG}" output -state="${STATE_FILE}" -raw "${output_name}" 2>/dev/null || true
}

terraform_output_json() {
  local output_name=$1
  terraform -chdir="${PATH_ARG}" output -state="${STATE_FILE}" -json "${output_name}" 2>/dev/null || true
}

hostname_matches_certificate_name() {
  local hostname cert_name suffix
  hostname="$(tr '[:upper:]' '[:lower:]' <<< "${1%.}")"
  cert_name="$(tr '[:upper:]' '[:lower:]' <<< "${2%.}")"

  if [[ "${hostname}" == "${cert_name}" ]]; then
    return 0
  fi

  if [[ "${cert_name}" != \*.* ]]; then
    return 1
  fi

  suffix="${cert_name#*.}"
  [[ "${hostname}" == *".${suffix}" ]] || return 1
  [[ "${hostname#*.}" == "${suffix}" ]]
}

check_frontend_edge_profile() {
  local distribution_id distribution_status distribution_domain cert_arn zone_id aliases_json
  local -a aliases cert_names

  distribution_id="$(terraform_output_raw frontend_cloudfront_distribution_id)"
  distribution_domain="$(terraform_output_raw frontend_cloudfront_url)"
  cert_arn="$(terraform_output_raw frontend_cert_arn)"
  zone_id="$(terraform_output_raw route53_zone_id_effective)"
  aliases_json="$(terraform_output_json frontend_aliases)"

  if [[ -n "${distribution_id}" ]]; then
    distribution_status="$(aws cloudfront get-distribution \
      --id "${distribution_id}" \
      --query 'Distribution.Status' \
      --output text)"
    if [[ "${distribution_status}" != "Deployed" ]]; then
      echo "CloudFront distribution is not deployed: ${distribution_id} status=${distribution_status}" >&2
      return 1
    fi
    echo "CloudFront deployment check passed: ${distribution_id} status=${distribution_status}"
  fi

  if [[ -n "${aliases_json}" ]]; then
    mapfile -t aliases < <(python3 - <<'PY' "${aliases_json}"
import json, sys
for item in json.loads(sys.argv[1]):
    print(item)
PY
)
  fi

  if [[ -n "${cert_arn}" && ${#aliases[@]} -gt 0 ]]; then
    mapfile -t cert_names < <(aws acm describe-certificate \
      --region us-east-1 \
      --certificate-arn "${cert_arn}" \
      --query 'Certificate.SubjectAlternativeNames' \
      --output text | tr '\t' '\n')

    if ! aws acm describe-certificate \
      --region us-east-1 \
      --certificate-arn "${cert_arn}" \
      --query 'Certificate.Status' \
      --output text | grep -qx 'ISSUED'; then
      echo "ACM certificate is not issued: ${cert_arn}" >&2
      return 1
    fi

    for alias in "${aliases[@]}"; do
      local covered=0
      local cert_name
      for cert_name in "${cert_names[@]}"; do
        if hostname_matches_certificate_name "${alias}" "${cert_name}"; then
          covered=1
          break
        fi
      done
      if [[ "${covered}" -ne 1 ]]; then
        echo "ACM certificate ${cert_arn} does not cover frontend alias ${alias}" >&2
        return 1
      fi
    done
    echo "ACM coverage check passed for ${#aliases[@]} frontend aliases"
  fi

  if [[ -n "${zone_id}" && -n "${distribution_domain}" && ${#aliases[@]} -gt 0 ]]; then
    local alias dns_name
    for alias in "${aliases[@]}"; do
      dns_name="$(aws route53 list-resource-record-sets \
        --hosted-zone-id "${zone_id}" \
        --query "ResourceRecordSets[?Type=='A' && Name=='${alias}.'].AliasTarget.DNSName" \
        --output text)"
      if [[ -z "${dns_name}" ]]; then
        echo "Route53 alias record missing for ${alias} in zone ${zone_id}" >&2
        return 1
      fi
      if [[ "${dns_name%.}" != "${distribution_domain%.}" ]]; then
        echo "Route53 alias record for ${alias} points to ${dns_name}, expected ${distribution_domain}" >&2
        return 1
      fi
    done
    echo "Route53 alias checks passed for ${#aliases[@]} frontend aliases"
  fi
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
  local -a curl_args=(-sS -o /dev/null -w '%{http_code}' --max-time 30)
  if [[ "${LIVE_VALIDATION_INSECURE_TLS}" == "true" ]]; then
    curl_args=(-k "${curl_args[@]}")
  fi
  status="$(curl "${curl_args[@]}" "${url}")"
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

  check_frontend_edge_profile
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
