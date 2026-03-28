data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "external" "existing_public_route53_zone" {
  count = (
    var.environment.route53_zone_id_input == null &&
    var.environment.route53_zone_strategy == "autodiscover"
  ) ? 1 : 0

  program = ["python3", "${path.module}/../../../../.scripts/find_route53_hosted_zone.py"]

  query = {
    domain = var.environment.domain
  }
}

locals {
  discovered_route53_zone_found = (
    length(data.external.existing_public_route53_zone) > 0 &&
    try(data.external.existing_public_route53_zone[0].result.found, "false") == "true"
  )
  discovered_route53_zone_id   = local.discovered_route53_zone_found ? data.external.existing_public_route53_zone[0].result.zone_id : null
  discovered_route53_zone_name = local.discovered_route53_zone_found ? data.external.existing_public_route53_zone[0].result.zone_name : null
  validated_s3_bucket_names = distinct(compact([
    var.guardrails.frontend_bucket_name,
    var.guardrails.s3_access_logs_bucket_name_final,
    var.guardrails.alb_access_logs_bucket_name_final,
    var.guardrails.cloudfront_logs_bucket_name,
    var.guardrails.dr_frontend_bucket_name_final,
    var.guardrails.s3_access_logs_dr_bucket_name_final,
    var.guardrails.alb_access_logs_dr_bucket_name_final,
    var.guardrails.cloudfront_logs_dr_bucket_name_final,
  ]))
}

resource "aws_route53_zone" "environment" {
  count = (
    var.environment.route53_zone_id_input == null &&
    var.environment.route53_zone_strategy == "create"
  ) ? 1 : 0

  name    = var.environment.domain
  comment = "Managed by Terraform for ${var.environment.domain}"
}

locals {
  route53_zone_id_effective = var.environment.route53_zone_id_input != null ? var.environment.route53_zone_id_input : (
    var.environment.route53_zone_strategy == "autodiscover" ? local.discovered_route53_zone_id : (
      var.environment.route53_zone_strategy == "create" ? aws_route53_zone.environment[0].zone_id : null
    )
  )
  route53_zone_name_effective = var.environment.route53_zone_id_input != null ? null : (
    var.environment.route53_zone_strategy == "autodiscover" ? local.discovered_route53_zone_name : (
      var.environment.route53_zone_strategy == "create" ? aws_route53_zone.environment[0].name : null
    )
  )
  route53_zone_managed = length(aws_route53_zone.environment) > 0
}

resource "null_resource" "guardrails" {
  triggers = {
    environment = var.environment.name
  }

  lifecycle {
    precondition {
      condition = (
        length(var.guardrails.availability_zones) > 0 &&
        length(var.guardrails.public_app_subnet_cidrs) == length(var.guardrails.availability_zones) &&
        length(var.guardrails.private_app_subnet_cidrs) == length(var.guardrails.availability_zones) &&
        length(var.guardrails.private_db_subnet_cidrs) == length(var.guardrails.availability_zones)
      )
      error_message = "Set availability_zones and provide matching public_app_subnet_cidrs/private_app_subnet_cidrs/private_db_subnet_cidrs lengths."
    }

    precondition {
      condition     = !var.origin_auth.enabled || trimspace(var.origin_auth.header_ssm_parameter_name) != ""
      error_message = "enable_origin_auth_header=true requires origin_auth_header_ssm_parameter_name to be set."
    }

    precondition {
      condition     = !var.environment.live_validation_mode || startswith(var.environment.name, "lv-")
      error_message = "live_validation_mode=true requires the effective environment name to start with lv- so validation traffic cannot reuse live hostnames."
    }

    precondition {
      condition     = !(var.environment.name == "prod" && var.guardrails.cost_optimized_dev_tier_enabled)
      error_message = "enable_cost_optimized_dev_tier must remain false for the prod environment."
    }

    precondition {
      condition     = !var.environment.live_validation_mode || var.environment.live_validation_label != null
      error_message = "live_validation_mode=true requires live_validation_dns_label to be set so validation can use stable preissued certificate names."
    }

    precondition {
      condition = (
        var.environment.route53_zone_id_input != null ||
        contains(["autodiscover", "create"], var.environment.route53_zone_strategy)
      )
      error_message = "Set route53_zone_id explicitly, or intentionally choose route53_zone_strategy=autodiscover or route53_zone_strategy=create."
    }

    precondition {
      condition     = var.environment.route53_zone_strategy != "autodiscover" || local.discovered_route53_zone_found
      error_message = "route53_zone_strategy=autodiscover did not find a matching public hosted zone. Set route53_zone_id explicitly or use route53_zone_strategy=create."
    }

    precondition {
      condition     = var.guardrails.effective_alb_deletion_protection || var.guardrails.destroy_mode_enabled
      error_message = "alb_deletion_protection must be true unless destroy_mode_enabled=true."
    }

    precondition {
      condition     = !var.origin_auth.enabled || lower(trimspace(var.guardrails.origin_auth_header_name)) != lower(trimspace(var.guardrails.origin_auth_previous_header_name))
      error_message = "origin_auth_header_name and origin_auth_previous_header_name must be different to support safe two-header rotation."
    }

    precondition {
      condition     = !var.origin_auth.enabled || trimspace(var.origin_auth.previous_ssm_parameter_name) == "" || trimspace(var.origin_auth.header_ssm_parameter_name) != trimspace(var.origin_auth.previous_ssm_parameter_name)
      error_message = "origin_auth_previous_header_ssm_parameter_name must differ from origin_auth_header_ssm_parameter_name when both are set."
    }

    precondition {
      condition     = var.guardrails.enable_cloudfront_access_logs
      error_message = "enable_cloudfront_access_logs must be true in this production-only configuration."
    }

    precondition {
      condition     = trimspace(var.guardrails.cloudfront_logs_bucket_name) != ""
      error_message = "cloudfront_logs_bucket_name must be set because CloudFront access logs are always enabled."
    }

    precondition {
      condition = alltrue([
        for bucket_name in local.validated_s3_bucket_names :
        length(bucket_name) >= 3 &&
        length(bucket_name) <= 63 &&
        can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", bucket_name)) &&
        !can(regex("\\.\\.", bucket_name)) &&
        !startswith(bucket_name, "xn--") &&
        !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", bucket_name))
      ])
      error_message = "Resolved S3 bucket names must be 3-63 chars, lowercase, use only letters/numbers/dots/hyphens, avoid consecutive dots, and must not be formatted like IPv4 addresses."
    }

    precondition {
      condition     = !var.guardrails.effective_s3_force_destroy || var.guardrails.destroy_mode_enabled
      error_message = "s3_force_destroy must be false unless destroy_mode_enabled=true."
    }

    precondition {
      condition     = var.guardrails.s3_versioning_enabled
      error_message = "s3_versioning_enabled must be true because cross-region replication is enforced for production posture."
    }

    precondition {
      condition = (
        var.environment.name != "prod" ||
        var.guardrails.enable_managed_waf ||
        var.guardrails.cost_optimized_dev_tier_enabled ||
        (var.guardrails.alb_web_acl_arn != null && (var.guardrails.frontend_web_acl_arn != null || var.guardrails.backend_web_acl_arn != null))
      )
      error_message = "Production requires managed WAF or explicit ALB/CloudFront web ACL ARNs. Non-production roots may disable WAF explicitly."
    }

    precondition {
      condition     = var.kms.aws_region != var.kms.dr_region
      error_message = "dr_region must differ from aws_region to ensure cross-region S3 replication."
    }

    precondition {
      condition     = length(var.guardrails.interface_endpoint_services) > 0
      error_message = "interface_endpoint_services must contain at least one service."
    }

    precondition {
      condition     = !var.guardrails.account_security_controls_enabled || length(var.guardrails.securityhub_standards_arns) > 0
      error_message = "Account-level security controls require at least one Security Hub standard ARN."
    }

    precondition {
      condition     = var.guardrails.selected_interface_endpoints_sg_id != null
      error_message = "An interface endpoint security group must exist."
    }

    precondition {
      condition     = var.guardrails.selected_s3_gateway_prefix_list_id != null
      error_message = "An S3 gateway endpoint prefix list must exist."
    }

    precondition {
      condition     = var.guardrails.runtime_mode_is_micro ? length(var.guardrails.ecs_services_final) > 0 : true
      error_message = "app_runtime_mode=gateway_microservices requires ecs_services to contain at least one service."
    }

    precondition {
      condition     = var.guardrails.runtime_mode_is_micro ? length(var.guardrails.public_service_keys) == 1 : true
      error_message = "app_runtime_mode=gateway_microservices requires exactly one ecs_services entry with public=true."
    }

    precondition {
      condition = var.guardrails.runtime_mode_is_micro ? alltrue([
        for service in values(var.guardrails.ecs_services_final) :
        can(regex("^.+@sha256:[A-Fa-f0-9]{64}$", service.image))
      ]) : true
      error_message = "All ecs_services images must be digest-pinned in gateway_microservices mode."
    }

    precondition {
      condition = var.guardrails.runtime_mode_is_micro ? alltrue([
        for repo in values(var.guardrails.microservice_image_repositories) :
        anytrue([
          for prefix in var.guardrails.microservice_allowed_image_registry_prefixes :
          startswith(repo, prefix)
        ])
      ]) : true
      error_message = "All ecs_services images must use an approved registry prefix."
    }

    precondition {
      condition = var.guardrails.runtime_mode_is_micro ? alltrue([
        for service in values(var.guardrails.ecs_services_final) :
        service.min_count <= service.desired_count && service.desired_count <= service.max_count
      ]) : true
      error_message = "Each ecs_services entry must satisfy min_count <= desired_count <= max_count."
    }

    precondition {
      condition     = var.guardrails.runtime_mode_is_single ? var.guardrails.create_backend_ecr_repository || length(var.guardrails.allowed_image_registries_final) > 0 : true
      error_message = "When create_backend_ecr_repository=false in single_backend mode, allowed_image_registries must contain at least one approved registry prefix."
    }

    precondition {
      condition = var.guardrails.runtime_mode_is_single ? anytrue([
        for prefix in var.guardrails.allowed_image_registries_final :
        var.guardrails.backend_image_repository == trimspace(prefix)
      ]) : true
      error_message = "backend_container_image must use one of the approved registry prefixes in single_backend mode."
    }

    precondition {
      condition     = var.guardrails.runtime_mode_is_single ? (var.guardrails.backend_min_count <= var.guardrails.backend_desired_count && var.guardrails.backend_desired_count <= var.guardrails.backend_max_count) : true
      error_message = "backend_min_count must be <= backend_desired_count and backend_desired_count must be <= backend_max_count in single_backend mode."
    }

    precondition {
      condition     = !var.kms.enable_ecs_exec || trimspace(var.guardrails.ecs_exec_log_group_name) != ""
      error_message = "enable_ecs_exec=true requires ecs_exec_log_group_name to be set."
    }

    precondition {
      condition     = !var.guardrails.enable_cloudtrail_data_events || length(var.guardrails.cloudtrail_data_event_resources) > 0
      error_message = "enable_cloudtrail_data_events=true requires at least one cloudtrail_data_event_resources ARN."
    }
  }
}

data "aws_ssm_parameter" "origin_auth_header_value" {
  count = var.origin_auth.enabled ? 1 : 0

  name            = var.origin_auth.header_ssm_parameter_name
  with_decryption = true
}

data "aws_ssm_parameter" "origin_auth_previous_header_value" {
  count = var.origin_auth.enabled && trimspace(var.origin_auth.previous_ssm_parameter_name) != "" ? 1 : 0

  name            = var.origin_auth.previous_ssm_parameter_name
  with_decryption = true
}

data "aws_iam_policy_document" "s3_kms_key_policy" {
  #checkov:skip=CKV_AWS_109: KMS key policies require root-level administration statement on resource * for account ownership.
  #checkov:skip=CKV_AWS_111: KMS key policies require root-level administration statement on resource * for account ownership.
  #checkov:skip=CKV_AWS_356: In KMS key policies, the Resource must be "*" and cannot be narrowed to key ARN.
  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudFrontLogDeliveryUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudFrontReadUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"]
    }
  }
}

resource "aws_kms_key" "s3_primary" {
  count = var.kms.create_primary_s3_kms_key ? 1 : 0

  description             = "KMS CMK for primary-region S3 encryption and replication source objects"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_key_policy.json
}

resource "aws_kms_alias" "s3_primary" {
  count = var.kms.create_primary_s3_kms_key ? 1 : 0

  name          = "alias/${var.kms.project_name}-s3-primary-${var.environment.name}"
  target_key_id = aws_kms_key.s3_primary[0].key_id
}

resource "aws_kms_key" "s3_dr" {
  provider = aws.dr
  count    = var.kms.create_dr_s3_kms_key ? 1 : 0

  description             = "KMS CMK for DR-region S3 replica encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_key_policy.json
}

resource "aws_kms_alias" "s3_dr" {
  provider = aws.dr
  count    = var.kms.create_dr_s3_kms_key ? 1 : 0

  name          = "alias/${var.kms.project_name}-s3-dr-${var.environment.name}"
  target_key_id = aws_kms_key.s3_dr[0].key_id
}

data "aws_iam_policy_document" "ecs_exec_kms_key_policy" {
  #checkov:skip=CKV_AWS_109: KMS key policies require root-level administration statement on resource * for account ownership.
  #checkov:skip=CKV_AWS_111: KMS key policies require root-level administration statement on resource * for account ownership.
  #checkov:skip=CKV_AWS_356: In KMS key policies, the Resource must be "*" and cannot be narrowed to key ARN.
  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogsUseOfTheKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${var.kms.aws_region}.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "ecs_exec" {
  count = var.kms.enable_ecs_exec ? 1 : 0

  description             = "KMS CMK for ECS Exec session and audit-log encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.ecs_exec_kms_key_policy.json
}

resource "aws_kms_alias" "ecs_exec" {
  count = var.kms.enable_ecs_exec ? 1 : 0

  name          = "alias/${var.kms.project_name}-ecs-exec-${var.environment.name}"
  target_key_id = aws_kms_key.ecs_exec[0].key_id
}
