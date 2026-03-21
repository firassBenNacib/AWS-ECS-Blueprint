data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  is_prod                           = local.environment_name == "prod"
  runtime_mode_is_single            = var.app_runtime_mode == "single_backend"
  runtime_mode_is_micro             = var.app_runtime_mode == "gateway_microservices"
  account_security_controls_enabled = var.enable_security_baseline && var.enable_account_security_controls
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Environment = local.environment_name
    },
    var.additional_tags
  )

  enable_environment_suffix = var.enable_environment_suffix
  environment_domain        = trimsuffix(lower(trimspace(var.environment_domain)), ".")
  route53_zone_id_input = (
    var.route53_zone_id != null && trimspace(var.route53_zone_id) != ""
  ) ? trimspace(var.route53_zone_id) : null

  frontend_aliases_final = local.is_prod ? [local.environment_domain, "www.${local.environment_domain}"] : ["${local.environment_name}.${local.environment_domain}", "www.${local.environment_name}.${local.environment_domain}"]
  backend_path_patterns  = ["/api/*", "/auth/*", "/audit/*", "/gateway/*", "/notify/twilio/status"]

  bucket_name_final                    = local.is_prod ? var.bucket_name : "${var.bucket_name}-${local.environment_name}"
  s3_access_logs_bucket_name_final     = trimspace(var.s3_access_logs_bucket_name) != "" ? trimspace(var.s3_access_logs_bucket_name) : (local.enable_environment_suffix ? "${var.project_name}-s3-access-logs-${local.environment_name}" : "${var.project_name}-s3-access-logs")
  alb_access_logs_bucket_name_final    = "${local.s3_access_logs_bucket_name_final}-alb"
  alb_access_logs_dr_bucket_name_final = "${local.alb_access_logs_bucket_name_final}-dr-${var.dr_region}"
  s3_access_logs_dr_bucket_name_final  = "${local.s3_access_logs_bucket_name_final}-dr-${var.dr_region}"
  dr_frontend_bucket_name_final        = trimspace(var.dr_frontend_bucket_name) != "" ? trimspace(var.dr_frontend_bucket_name) : "${local.bucket_name_final}-dr-${var.dr_region}"
  dr_cloudfront_logs_bucket_name_final = trimspace(var.dr_cloudfront_logs_bucket_name) != "" ? trimspace(var.dr_cloudfront_logs_bucket_name) : (trimspace(var.cloudfront_logs_bucket_name) != "" ? "${trimspace(var.cloudfront_logs_bucket_name)}-dr-${var.dr_region}" : "")
  create_primary_s3_kms_key            = var.s3_kms_key_id == null
  create_dr_s3_kms_key                 = var.dr_s3_kms_key_id == null
  s3_primary_kms_key_arn               = var.s3_kms_key_id != null ? var.s3_kms_key_id : aws_kms_key.s3_primary[0].arn
  s3_dr_kms_key_arn                    = var.dr_s3_kms_key_id != null ? var.dr_s3_kms_key_id : aws_kms_key.s3_dr[0].arn
  effective_s3_force_destroy           = var.destroy_mode_enabled ? true : var.s3_force_destroy
  effective_alb_deletion_protection    = var.destroy_mode_enabled ? false : var.alb_deletion_protection
  backend_ecr_repository_name_final    = local.enable_environment_suffix ? "${var.backend_ecr_repository_name}-${local.environment_name}" : var.backend_ecr_repository_name
  default_allowed_image_registries = [
    "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.backend_ecr_repository_name_final}"
  ]
  default_microservice_allowed_image_registry_prefixes = [
    "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/"
  ]
  allowed_image_registries_final = length(var.allowed_image_registries) > 0 ? [
    for registry in var.allowed_image_registries : trimspace(registry)
    if trimspace(registry) != ""
  ] : local.default_allowed_image_registries
  backend_image_repository = (
    var.backend_container_image != null && trimspace(var.backend_container_image) != ""
  ) ? split("@", trimspace(var.backend_container_image))[0] : null
  microservice_allowed_image_registry_prefixes = length(var.allowed_image_registries) > 0 ? [
    for registry in var.allowed_image_registries : trimspace(registry)
    if trimspace(registry) != ""
  ] : local.default_microservice_allowed_image_registry_prefixes
  alb_access_logs_prefix = trim(trimspace(var.alb_access_logs_prefix), "/")
  alb_access_logs_path   = local.alb_access_logs_prefix != "" ? "${local.alb_access_logs_prefix}/" : ""
  securityhub_default_standards_arns = [
    "arn:${data.aws_partition.current.partition}:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0",
    "arn:${data.aws_partition.current.partition}:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/5.0.0"
  ]
  securityhub_standards_arns = length(var.securityhub_standards_arns) > 0 ? var.securityhub_standards_arns : local.securityhub_default_standards_arns

  selected_vpc_id                    = module.network.vpc_id
  selected_interface_endpoints_sg_id = module.network.interface_endpoints_sg_id
  selected_s3_gateway_prefix_list_id = module.network.s3_gateway_prefix_list_id

  selected_public_edge_subnet_ids = sort(module.network.public_edge_subnet_ids)
  selected_private_app_subnet_ids = sort(module.network.private_app_subnet_ids)
  selected_db_subnet_ids          = sort(module.network.private_db_subnet_ids)
  cloudfront_logs_bucket_domain   = "${trimspace(var.cloudfront_logs_bucket_name)}.s3.amazonaws.com"
  dr_frontend_bucket_domain       = aws_s3_bucket.frontend_dr.bucket_regional_domain_name
  vpc_flow_logs_kms_key_arn       = var.vpc_flow_logs_kms_key_id != null ? var.vpc_flow_logs_kms_key_id : null
  ecs_exec_kms_key_arn_final      = var.enable_ecs_exec ? aws_kms_key.ecs_exec[0].arn : null
  backend_env_defaults = {
    DB_HOST = module.rds.address
    DB_PORT = "3306"
    DB_NAME = var.rds_db_name
    DB_USER = var.rds_username
  }
  backend_env_final = merge(local.backend_env_defaults, var.backend_env)
  backend_secret_arns_final = merge(
    var.backend_secret_arns,
    { (var.backend_rds_secret_env_var_name) = module.rds.master_user_secret_arn }
  )
  smtp_host_final = "email-smtp.${var.aws_region}.amazonaws.com"
  microservice_env_placeholders = {
    "__RDS_ENDPOINT__" = module.rds.address
    "__RDS_DB_NAME__"  = var.rds_db_name
    "__SMTP_HOST__"    = local.smtp_host_final
  }
  microservice_secret_placeholders = {
    "__RDS_MASTER_PASSWORD_SECRET_ARN__" = "${module.rds.master_user_secret_arn}:password::"
  }
  service_discovery_namespace_name_final = (
    var.service_discovery_namespace_name != null && trimspace(var.service_discovery_namespace_name) != ""
  ) ? trimsuffix(lower(trimspace(var.service_discovery_namespace_name)), ".") : "${local.environment_name}.${var.project_name}.internal"
  microservices_cluster_name_final  = "${var.project_name}-${local.environment_name}-services"
  microservices_exec_log_group_name = "/aws/ecs/exec/${var.project_name}-${local.environment_name}-services"
  ecs_services_final = local.runtime_mode_is_micro ? {
    for service_name, service in var.ecs_services :
    service_name => {
      image                                        = trimspace(service.image)
      container_port                               = service.container_port
      container_name                               = coalesce(try(service.container_name, null), service_name)
      public                                       = coalesce(try(service.public, null), false)
      desired_count                                = coalesce(try(service.desired_count, null), 1)
      min_count                                    = coalesce(try(service.min_count, null), 1)
      max_count                                    = coalesce(try(service.max_count, null), 2)
      cpu                                          = coalesce(try(service.cpu, null), 512)
      memory                                       = coalesce(try(service.memory, null), 1024)
      alb_request_count_target_value               = try(service.alb_request_count_target_value, null)
      alb_request_count_scale_in_cooldown_seconds  = coalesce(try(service.alb_request_count_scale_in_cooldown_seconds, null), 300)
      alb_request_count_scale_out_cooldown_seconds = coalesce(try(service.alb_request_count_scale_out_cooldown_seconds, null), 60)
      health_check_grace_period_seconds            = coalesce(try(service.health_check_grace_period_seconds, null), 60)
      health_check_path                            = coalesce(try(service.health_check_path, null), "/health")
      container_user                               = try(service.container_user, null)
      readonly_root_fs                             = coalesce(try(service.readonly_root_fs, null), true)
      drop_capabilities                            = coalesce(try(service.drop_capabilities, null), ["ALL"])
      env = {
        for env_key, env_value in coalesce(try(service.env, null), {}) :
        env_key => replace(
          replace(
            replace(env_value, "__RDS_ENDPOINT__", local.microservice_env_placeholders["__RDS_ENDPOINT__"]),
            "__RDS_DB_NAME__",
            local.microservice_env_placeholders["__RDS_DB_NAME__"]
          ),
          "__SMTP_HOST__",
          local.microservice_env_placeholders["__SMTP_HOST__"]
        )
      }
      secret_arns = {
        for secret_key, secret_value in coalesce(try(service.secret_arns, null), {}) :
        secret_key => replace(
          secret_value,
          "__RDS_MASTER_PASSWORD_SECRET_ARN__",
          local.microservice_secret_placeholders["__RDS_MASTER_PASSWORD_SECRET_ARN__"]
        )
      }
      secret_kms_key_arns               = coalesce(try(service.secret_kms_key_arns, null), [])
      task_role_policy_json             = try(service.task_role_policy_json, null)
      log_group_name                    = coalesce(try(service.log_group_name, null), "/aws/ecs/${var.project_name}-${service_name}-${local.environment_name}")
      log_retention_days                = coalesce(try(service.log_retention_days, null), 30)
      log_kms_key_id                    = try(service.log_kms_key_id, null)
      entrypoint                        = coalesce(try(service.entrypoint, null), [])
      command                           = coalesce(try(service.command, null), [])
      mount_points                      = coalesce(try(service.mount_points, null), [])
      task_volumes                      = coalesce(try(service.task_volumes, null), [])
      health_check_command              = coalesce(try(service.health_check_command, null), [])
      health_check_interval_seconds     = coalesce(try(service.health_check_interval_seconds, null), 30)
      health_check_timeout_seconds      = coalesce(try(service.health_check_timeout_seconds, null), 5)
      health_check_retries              = coalesce(try(service.health_check_retries, null), 3)
      health_check_start_period_seconds = coalesce(try(service.health_check_start_period_seconds, null), 15)
      assign_public_ip                  = coalesce(try(service.assign_public_ip, null), false)
      enable_service_discovery          = coalesce(try(service.enable_service_discovery, null), true)
      discovery_name                    = coalesce(try(service.discovery_name, null), service_name)
      extra_egress                      = coalesce(try(service.extra_egress, null), [])
    }
  } : {}
  public_service_keys = local.runtime_mode_is_micro ? sort([
    for service_name, service in local.ecs_services_final : service_name if service.public
  ]) : []
  public_service_key = length(local.public_service_keys) > 0 ? local.public_service_keys[0] : null
  public_service     = local.public_service_key != null ? local.ecs_services_final[local.public_service_key] : null
  microservice_image_repositories = local.runtime_mode_is_micro ? {
    for service_name, service in local.ecs_services_final :
    service_name => split("@", service.image)[0]
  } : {}
  public_service_port               = local.public_service != null ? local.public_service.container_port : null
  public_service_health_check_path  = local.public_service != null ? local.public_service.health_check_path : null
  origin_auth_header_value_resolved = var.enable_origin_auth_header ? nonsensitive(data.aws_ssm_parameter.origin_auth_header_value[0].value) : ""
  origin_auth_previous_header_value_resolved = (
    var.enable_origin_auth_header && length(data.aws_ssm_parameter.origin_auth_previous_header_value) > 0
    ? nonsensitive(data.aws_ssm_parameter.origin_auth_previous_header_value[0].value)
    : ""
  )

  create_managed_waf_alb        = var.enable_managed_waf && var.alb_web_acl_arn == null
  create_managed_waf_cloudfront = var.enable_managed_waf && var.frontend_web_acl_arn == null && var.backend_web_acl_arn == null
}

data "external" "existing_public_route53_zone" {
  count = local.route53_zone_id_input == null ? 1 : 0

  program = ["python3", "${path.module}/../../.scripts/find_route53_hosted_zone.py"]

  query = {
    domain = local.environment_domain
  }
}

locals {
  discovered_route53_zone_found = (
    length(data.external.existing_public_route53_zone) > 0 &&
    try(data.external.existing_public_route53_zone[0].result.found, "false") == "true"
  )
  discovered_route53_zone_id   = local.discovered_route53_zone_found ? data.external.existing_public_route53_zone[0].result.zone_id : null
  discovered_route53_zone_name = local.discovered_route53_zone_found ? data.external.existing_public_route53_zone[0].result.zone_name : null
}

resource "aws_route53_zone" "environment" {
  count = local.route53_zone_id_input == null && !local.discovered_route53_zone_found ? 1 : 0

  name    = local.environment_domain
  comment = "Managed by Terraform for ${local.environment_domain}"
}

locals {
  route53_zone_id_effective = local.route53_zone_id_input != null ? local.route53_zone_id_input : (
    local.discovered_route53_zone_found ? local.discovered_route53_zone_id : aws_route53_zone.environment[0].zone_id
  )
  route53_zone_name_effective = local.route53_zone_id_input != null ? null : (
    local.discovered_route53_zone_found ? local.discovered_route53_zone_name : aws_route53_zone.environment[0].name
  )
  route53_zone_managed = length(aws_route53_zone.environment) > 0
}

resource "null_resource" "guardrails" {
  triggers = {
    environment = local.environment_name
  }

  lifecycle {
    precondition {
      condition = (
        length(var.availability_zones) > 0 &&
        length(var.public_app_subnet_cidrs) == length(var.availability_zones) &&
        length(var.private_app_subnet_cidrs) == length(var.availability_zones) &&
        length(var.private_db_subnet_cidrs) == length(var.availability_zones)
      )
      error_message = "Set availability_zones and provide matching public_app_subnet_cidrs/private_app_subnet_cidrs/private_db_subnet_cidrs lengths."
    }

    precondition {
      condition     = !var.enable_origin_auth_header || trimspace(var.origin_auth_header_ssm_parameter_name) != ""
      error_message = "enable_origin_auth_header=true requires origin_auth_header_ssm_parameter_name to be set."
    }

    precondition {
      condition     = local.effective_alb_deletion_protection || var.destroy_mode_enabled
      error_message = "alb_deletion_protection must be true unless destroy_mode_enabled=true."
    }

    precondition {
      condition     = !var.enable_origin_auth_header || lower(trimspace(var.origin_auth_header_name)) != lower(trimspace(var.origin_auth_previous_header_name))
      error_message = "origin_auth_header_name and origin_auth_previous_header_name must be different to support safe two-header rotation."
    }

    precondition {
      condition     = !var.enable_origin_auth_header || trimspace(var.origin_auth_previous_header_ssm_parameter_name) == "" || trimspace(var.origin_auth_header_ssm_parameter_name) != trimspace(var.origin_auth_previous_header_ssm_parameter_name)
      error_message = "origin_auth_previous_header_ssm_parameter_name must differ from origin_auth_header_ssm_parameter_name when both are set."
    }

    precondition {
      condition     = var.enable_cloudfront_access_logs
      error_message = "enable_cloudfront_access_logs must be true in this production-only configuration."
    }

    precondition {
      condition     = trimspace(var.cloudfront_logs_bucket_name) != ""
      error_message = "cloudfront_logs_bucket_name must be set because CloudFront access logs are always enabled."
    }

    precondition {
      condition     = !local.effective_s3_force_destroy || var.destroy_mode_enabled
      error_message = "s3_force_destroy must be false unless destroy_mode_enabled=true."
    }

    precondition {
      condition     = var.s3_versioning_enabled
      error_message = "s3_versioning_enabled must be true because cross-region replication is enforced for production posture."
    }

    precondition {
      condition     = var.enable_managed_waf || (var.alb_web_acl_arn != null && (var.frontend_web_acl_arn != null || var.backend_web_acl_arn != null))
      error_message = "When enable_managed_waf=false, you must provide alb_web_acl_arn and one CloudFront web ACL ARN."
    }

    precondition {
      condition     = var.aws_region != var.dr_region
      error_message = "dr_region must differ from aws_region to ensure cross-region S3 replication."
    }

    precondition {
      condition     = length(var.interface_endpoint_services) > 0
      error_message = "interface_endpoint_services must contain at least one service."
    }

    precondition {
      condition     = !local.account_security_controls_enabled || length(local.securityhub_standards_arns) > 0
      error_message = "Account-level security controls require at least one Security Hub standard ARN."
    }

    precondition {
      condition     = local.selected_interface_endpoints_sg_id != null
      error_message = "An interface endpoint security group must exist."
    }

    precondition {
      condition     = local.selected_s3_gateway_prefix_list_id != null
      error_message = "An S3 gateway endpoint prefix list must exist."
    }

    precondition {
      condition     = local.runtime_mode_is_micro ? length(local.ecs_services_final) > 0 : true
      error_message = "app_runtime_mode=gateway_microservices requires ecs_services to contain at least one service."
    }

    precondition {
      condition     = local.runtime_mode_is_micro ? length(local.public_service_keys) == 1 : true
      error_message = "app_runtime_mode=gateway_microservices requires exactly one ecs_services entry with public=true."
    }

    precondition {
      condition = local.runtime_mode_is_micro ? alltrue([
        for service in values(local.ecs_services_final) :
        can(regex("^.+@sha256:[A-Fa-f0-9]{64}$", service.image))
      ]) : true
      error_message = "All ecs_services images must be digest-pinned in gateway_microservices mode."
    }

    precondition {
      condition = local.runtime_mode_is_micro ? alltrue([
        for repo in values(local.microservice_image_repositories) :
        anytrue([
          for prefix in local.microservice_allowed_image_registry_prefixes :
          startswith(repo, prefix)
        ])
      ]) : true
      error_message = "All ecs_services images must use an approved registry prefix."
    }

    precondition {
      condition = local.runtime_mode_is_micro ? alltrue([
        for service in values(local.ecs_services_final) :
        service.min_count <= service.desired_count && service.desired_count <= service.max_count
      ]) : true
      error_message = "Each ecs_services entry must satisfy min_count <= desired_count <= max_count."
    }

    precondition {
      condition     = local.runtime_mode_is_single ? var.create_backend_ecr_repository || length(local.allowed_image_registries_final) > 0 : true
      error_message = "When create_backend_ecr_repository=false in single_backend mode, allowed_image_registries must contain at least one approved registry prefix."
    }

    precondition {
      condition = local.runtime_mode_is_single ? anytrue([
        for prefix in local.allowed_image_registries_final :
        local.backend_image_repository == trimspace(prefix)
      ]) : true
      error_message = "backend_container_image must use one of the approved registry prefixes in single_backend mode."
    }

    precondition {
      condition     = local.runtime_mode_is_single ? (var.backend_min_count <= var.backend_desired_count && var.backend_desired_count <= var.backend_max_count) : true
      error_message = "backend_min_count must be <= backend_desired_count and backend_desired_count must be <= backend_max_count in single_backend mode."
    }

    precondition {
      condition     = !var.enable_ecs_exec || trimspace(var.ecs_exec_log_group_name) != ""
      error_message = "enable_ecs_exec=true requires ecs_exec_log_group_name to be set."
    }

    precondition {
      condition     = !var.enable_cloudtrail_data_events || length(var.cloudtrail_data_event_resources) > 0
      error_message = "enable_cloudtrail_data_events=true requires at least one cloudtrail_data_event_resources ARN."
    }



  }
}

data "aws_ssm_parameter" "origin_auth_header_value" {
  count = var.enable_origin_auth_header ? 1 : 0

  name            = var.origin_auth_header_ssm_parameter_name
  with_decryption = true
}

data "aws_ssm_parameter" "origin_auth_previous_header_value" {
  count = var.enable_origin_auth_header && trimspace(var.origin_auth_previous_header_ssm_parameter_name) != "" ? 1 : 0

  name            = var.origin_auth_previous_header_ssm_parameter_name
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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
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
  count = local.create_primary_s3_kms_key ? 1 : 0

  description             = "KMS CMK for primary-region S3 encryption and replication source objects"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_key_policy.json
}

resource "aws_kms_alias" "s3_primary" {
  count = local.create_primary_s3_kms_key ? 1 : 0

  name          = "alias/${var.project_name}-s3-primary-${local.environment_name}"
  target_key_id = aws_kms_key.s3_primary[0].key_id
}

resource "aws_kms_key" "s3_dr" {
  provider = aws.dr
  count    = local.create_dr_s3_kms_key ? 1 : 0

  description             = "KMS CMK for DR-region S3 replica encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_key_policy.json
}

resource "aws_kms_alias" "s3_dr" {
  provider = aws.dr
  count    = local.create_dr_s3_kms_key ? 1 : 0

  name          = "alias/${var.project_name}-s3-dr-${local.environment_name}"
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
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
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
  count = var.enable_ecs_exec ? 1 : 0

  description             = "KMS CMK for ECS Exec session and audit-log encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.ecs_exec_kms_key_policy.json
}

resource "aws_kms_alias" "ecs_exec" {
  count = var.enable_ecs_exec ? 1 : 0

  name          = "alias/${var.project_name}-ecs-exec-${local.environment_name}"
  target_key_id = aws_kms_key.ecs_exec[0].key_id
}

resource "aws_s3_bucket" "s3_access_logs" { #tfsec:ignore:aws-s3-enable-bucket-logging Dedicated access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  #checkov:skip=CKV_AWS_18: Dedicated access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  bucket        = local.s3_access_logs_bucket_name_final
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "s3_access_logs_eventbridge" {
  bucket = aws_s3_bucket.s3_access_logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.s3_primary_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id

  rule {
    id     = "s3-access-log-retention"
    status = "Enabled"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket" "s3_access_logs_dr" { #tfsec:ignore:aws-s3-enable-bucket-logging Dedicated DR access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  provider = aws.dr
  #checkov:skip=CKV_AWS_18: Dedicated DR access-log sink bucket intentionally does not log to itself to avoid recursive loops.
  bucket        = local.s3_access_logs_dr_bucket_name_final
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "s3_access_logs_dr_eventbridge" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.s3_dr_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id

  rule {
    id     = "s3-access-log-retention-dr"
    status = "Enabled"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "s3_access_logs_dr_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_access_logs_dr.arn,
      "${aws_s3_bucket.s3_access_logs_dr.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowS3ServerAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.s3_access_logs_dr.arn}/s3-access/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = compact([
        aws_s3_bucket.frontend_dr.arn,
        aws_s3_bucket.cloudfront_logs_dr.arn,
        aws_s3_bucket.alb_access_logs_dr.arn
      ])
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access_logs_dr_bucket" {
  provider = aws.dr
  bucket   = aws_s3_bucket.s3_access_logs_dr.id
  policy   = data.aws_iam_policy_document.s3_access_logs_dr_bucket_policy.json
}

data "aws_iam_policy_document" "s3_access_logs_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_access_logs_replication" {
  name               = local.enable_environment_suffix ? "s3-access-logs-repl-${local.environment_name}" : "s3-access-logs-repl"
  assume_role_policy = data.aws_iam_policy_document.s3_access_logs_replication_assume_role.json
}

data "aws_iam_policy_document" "s3_access_logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.s3_access_logs.arn]
  }

  statement {
    sid = "SourceObjectReadForReplication"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = ["${aws_s3_bucket.s3_access_logs.arn}/*"]
  }

  #tfsec:ignore:aws-iam-no-policy-wildcards S3 replication requires object ARN wildcards to cover all keys in the destination bucket.
  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.s3_access_logs_dr.arn}/*"]
  }

  statement {
    sid = "AllowKmsOnSourceAndDestinationKeys"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]
    resources = [
      local.s3_primary_kms_key_arn,
      local.s3_dr_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "s3_access_logs_replication" {
  name   = local.enable_environment_suffix ? "s3-access-logs-repl-${local.environment_name}" : "s3-access-logs-repl"
  role   = aws_iam_role.s3_access_logs_replication.id
  policy = data.aws_iam_policy_document.s3_access_logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "s3_access_logs" {
  bucket = aws_s3_bucket.s3_access_logs.id
  role   = aws_iam_role.s3_access_logs_replication.arn

  rule {
    id     = "s3-access-logs-to-dr"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.s3_access_logs_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = local.s3_dr_kms_key_arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.s3_access_logs,
    aws_s3_bucket_versioning.s3_access_logs_dr,
    aws_iam_role_policy.s3_access_logs_replication
  ]
}

resource "aws_s3_bucket" "alb_access_logs" {
  #checkov:skip=CKV_AWS_145: ALB access logs only support SSE-S3 on the destination bucket.
  bucket        = local.alb_access_logs_bucket_name_final
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "alb_access_logs_eventbridge" {
  bucket = aws_s3_bucket.alb_access_logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" { #tfsec:ignore:aws-s3-encryption-customer-key ALB access logs only support SSE-S3 on the destination bucket.
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    id     = "alb-access-log-retention"
    status = "Enabled"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "alb_access_logs_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.alb_access_logs.arn,
      "${aws_s3_bucket.alb_access_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowALBAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.alb_access_logs.arn}/${local.alb_access_logs_path}AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = data.aws_iam_policy_document.alb_access_logs_bucket_policy.json
}

resource "aws_s3_bucket_logging" "alb_access_logs" {
  count = var.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.alb_access_logs.id
  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "s3-access/alb-logs/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_bucket]
}

resource "aws_s3_bucket" "alb_access_logs_dr" { #tfsec:ignore:aws-s3-enable-bucket-logging Dedicated DR ALB access-log sink bucket logs to the DR access-log bucket below.
  provider = aws.dr
  #checkov:skip=CKV_AWS_145: ALB access logs only support SSE-S3 on the destination bucket.
  #checkov:skip=CKV_AWS_18: Dedicated DR ALB access-log sink bucket logs to the DR access-log bucket below.
  bucket        = local.alb_access_logs_dr_bucket_name_final
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "alb_access_logs_dr_eventbridge" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs_dr" { #tfsec:ignore:aws-s3-encryption-customer-key ALB access log replicas remain SSE-S3 encrypted because the source service only supports SSE-S3.
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id

  rule {
    id     = "alb-access-log-retention-dr"
    status = "Enabled"

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "alb_access_logs_dr_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.alb_access_logs_dr.arn,
      "${aws_s3_bucket.alb_access_logs_dr.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.alb_access_logs_dr.id
  policy   = data.aws_iam_policy_document.alb_access_logs_dr_bucket_policy.json
}

resource "aws_s3_bucket_logging" "alb_access_logs_dr" {
  provider = aws.dr
  count    = var.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.alb_access_logs_dr.id
  target_bucket = aws_s3_bucket.s3_access_logs_dr.id
  target_prefix = "s3-access/alb-logs-dr/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_dr_bucket]
}

data "aws_iam_policy_document" "alb_access_logs_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "alb_access_logs_replication" {
  name               = local.enable_environment_suffix ? "s3-alb-logs-repl-${local.environment_name}" : "s3-alb-logs-repl"
  assume_role_policy = data.aws_iam_policy_document.alb_access_logs_replication_assume_role.json
}

data "aws_iam_policy_document" "alb_access_logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.alb_access_logs.arn]
  }

  statement {
    sid = "SourceObjectReadForReplication"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = ["${aws_s3_bucket.alb_access_logs.arn}/*"]
  }

  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.alb_access_logs_dr.arn}/*"]
  }
}

resource "aws_iam_role_policy" "alb_access_logs_replication" {
  name   = local.enable_environment_suffix ? "s3-alb-logs-repl-${local.environment_name}" : "s3-alb-logs-repl"
  role   = aws_iam_role.alb_access_logs_replication.id
  policy = data.aws_iam_policy_document.alb_access_logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  role   = aws_iam_role.alb_access_logs_replication.arn

  rule {
    id     = "alb-access-logs-to-dr"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.alb_access_logs_dr.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.alb_access_logs,
    aws_s3_bucket_versioning.alb_access_logs_dr,
    aws_iam_role_policy.alb_access_logs_replication
  ]
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = var.cloudfront_logs_bucket_name
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "cloudfront_logs_eventbridge" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  #checkov:skip=CKV2_AWS_65: CloudFront standard log delivery requires ACL-compatible ownership mode.
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.s3_primary_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  count = var.enable_cloudfront_logs_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "cloudfront-log-retention"
    status = "Enabled"

    expiration {
      days = var.cloudfront_logs_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.cloudfront_logs_abort_incomplete_multipart_upload_days
    }
  }
}

resource "aws_s3_bucket_logging" "cloudfront_logs" {
  count = var.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.cloudfront_logs.id
  target_bucket = aws_s3_bucket.s3_access_logs.id
  target_prefix = "s3-access/cloudfront-logs/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_bucket]
}

module "network" {
  source = "../network"

  vpc_name                        = var.vpc_name
  vpc_cidr                        = var.vpc_cidr
  availability_zones              = var.availability_zones
  public_app_subnet_cidrs         = var.public_app_subnet_cidrs
  private_app_subnet_cidrs        = var.private_app_subnet_cidrs
  private_db_subnet_cidrs         = var.private_db_subnet_cidrs
  flow_logs_retention_days        = var.vpc_flow_logs_retention_days
  flow_logs_kms_key_id            = local.vpc_flow_logs_kms_key_arn
  lockdown_default_security_group = var.lockdown_default_security_group
  interface_endpoint_services     = var.interface_endpoint_services
  private_app_nat_mode            = var.private_app_nat_mode
}

module "ecr_backend" {
  count  = local.runtime_mode_is_single && var.create_backend_ecr_repository ? 1 : 0
  source = "../ecr"

  repository_name        = local.backend_ecr_repository_name_final
  max_image_count        = var.backend_ecr_lifecycle_max_images
  encryption_kms_key_arn = var.backend_ecr_kms_key_arn
}

module "guardduty_member_detector" {
  count  = local.account_security_controls_enabled ? 1 : 0
  source = "../guardduty_member_detector"
}

#checkov:skip=CKV2_AWS_10: CloudTrail to CloudWatch integration is configured in module.security_baseline but may report false positives in graph checks.
#checkov:skip=CKV2_AWS_45: AWS Config recorder status is enabled in module.security_baseline; this graph check can report false positives with split recorder/status resources.
module "security_baseline" {
  count  = local.account_security_controls_enabled ? 1 : 0
  source = "../security_baseline"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix                         = local.enable_environment_suffix ? "${var.project_name}-${local.environment_name}" : var.project_name
  log_bucket_name                     = local.enable_environment_suffix ? lower("${var.project_name}-security-baseline-${data.aws_caller_identity.current.account_id}-${local.environment_name}") : lower("${var.project_name}-security-baseline-${data.aws_caller_identity.current.account_id}")
  securityhub_standards               = local.securityhub_standards_arns
  cloudtrail_retention_days           = var.security_baseline_log_retention_days
  access_logs_bucket_name             = local.s3_access_logs_bucket_name_final
  access_logs_bucket_name_dr          = local.s3_access_logs_dr_bucket_name_final
  enable_aws_config                   = var.enable_aws_config
  security_findings_sns_topic_arn     = var.security_findings_sns_topic_arn
  security_findings_sns_subscriptions = var.security_findings_sns_subscriptions
  enable_cloudtrail_data_events       = var.enable_cloudtrail_data_events
  cloudtrail_data_event_resources     = var.cloudtrail_data_event_resources
  enable_inspector                    = var.enable_inspector
  enable_log_bucket_object_lock       = !var.destroy_mode_enabled && var.security_baseline_enable_object_lock
  log_bucket_force_destroy            = local.effective_s3_force_destroy
}

module "backup_baseline" {
  source = "../backup_baseline"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix                      = local.enable_environment_suffix ? "${var.project_name}-${local.environment_name}" : var.project_name
  enable_aws_backup                = var.enable_aws_backup
  enable_backup_selection          = true
  backup_vault_name                = var.aws_backup_vault_name
  backup_schedule_expression       = var.aws_backup_schedule_expression
  backup_retention_days            = var.aws_backup_retention_days
  backup_start_window_minutes      = var.aws_backup_start_window_minutes
  backup_completion_window_minutes = var.aws_backup_completion_window_minutes
  backup_cross_region_copy_enabled = var.aws_backup_cross_region_copy_enabled
  backup_copy_retention_days       = var.aws_backup_copy_retention_days
  backup_resource_arns = [
    module.rds.instance_arn,
    module.s3.bucket_arn
  ]
}

module "security_groups" {
  count  = local.runtime_mode_is_single ? 1 : 0
  source = "../security_groups"

  vpc_id                    = local.selected_vpc_id
  app_port                  = var.backend_container_port
  alb_listener_port         = var.alb_listener_port
  http_origin_listener_port = var.backend_origin_protocol_policy == "http-only" ? 80 : null
  alb_ingress_cidr_blocks   = var.private_app_subnet_cidrs
  egress_endpoint_sg_id     = local.selected_interface_endpoints_sg_id
  egress_s3_prefix_list_id  = local.selected_s3_gateway_prefix_list_id
  enable_environment_suffix = local.enable_environment_suffix
  environment_name_override = local.environment_name
}

resource "aws_security_group" "microservices_alb" {
  count = local.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-alb-sg-${local.environment_name}"
  description = "Allow CloudFront VPC-origin traffic to the public ECS service ALB."
  vpc_id      = local.selected_vpc_id
}

resource "aws_security_group" "microservices_gateway" {
  count = local.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-gateway-sg-${local.environment_name}"
  description = "Allow ALB traffic to the public gateway ECS service."
  vpc_id      = local.selected_vpc_id

  ingress {
    description     = "Public service traffic from the internal ALB"
    from_port       = local.public_service_port
    to_port         = local.public_service_port
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_alb[0].id]
  }

  egress {
    description = "Allow DNS over UDP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow DNS over TCP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description     = "HTTPS to VPC interface endpoints (ECR, CloudWatch, Secrets Manager, KMS)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.selected_interface_endpoints_sg_id]
  }

  egress {
    description     = "HTTPS to Amazon S3 via the gateway endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [local.selected_s3_gateway_prefix_list_id]
  }

  egress {
    description     = "Internal service-to-service traffic within the private subnet tier"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal[0].id]
  }
}

resource "aws_security_group_rule" "microservices_alb_to_gateway" {
  count = local.runtime_mode_is_micro ? 1 : 0

  type                     = "egress"
  from_port                = local.public_service_port
  to_port                  = local.public_service_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.microservices_alb[0].id
  source_security_group_id = aws_security_group.microservices_gateway[0].id
  description              = "Forward ALB traffic to the public ECS service only."
}

resource "aws_security_group" "microservices_internal" {
  count = local.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-internal-sg-${local.environment_name}"
  description = "Allow east-west traffic between private ECS services."
  vpc_id      = local.selected_vpc_id

  ingress {
    description = "Allow internal service-to-service traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow DNS over UDP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow DNS over TCP to the VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description     = "HTTPS to VPC interface endpoints (ECR, CloudWatch, Secrets Manager, KMS)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [local.selected_interface_endpoints_sg_id]
  }

  egress {
    description     = "HTTPS to Amazon S3 via the gateway endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [local.selected_s3_gateway_prefix_list_id]
  }

  egress {
    description = "MySQL to RDS within the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "microservices_extra_egress" {
  for_each = local.runtime_mode_is_micro ? {
    for service_name, service in local.ecs_services_final :
    service_name => service if length(service.extra_egress) > 0
  } : {}

  name        = "microservices-extra-egress-${each.key}-${local.environment_name}"
  description = "Additional egress exceptions for ${each.key}."
  vpc_id      = local.selected_vpc_id

  dynamic "egress" {
    for_each = each.value.extra_egress
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_security_group" "microservices_rds" {
  count = local.runtime_mode_is_micro ? 1 : 0

  name        = "microservices-rds-sg-${local.environment_name}"
  description = "Allow MySQL access from private ECS services."
  vpc_id      = local.selected_vpc_id

  ingress {
    description     = "MySQL from private ECS services"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal[0].id]
  }

  egress {
    description = "Restrict outbound traffic to the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_cloudwatch_log_group" "microservices_exec" {
  count = local.runtime_mode_is_micro && var.enable_ecs_exec ? 1 : 0

  name              = local.microservices_exec_log_group_name
  retention_in_days = var.ecs_exec_log_retention_days
  kms_key_id        = local.ecs_exec_kms_key_arn_final
}

resource "aws_ecs_cluster" "microservices" {
  count = local.runtime_mode_is_micro ? 1 : 0

  name = local.microservices_cluster_name_final

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  dynamic "configuration" {
    for_each = var.enable_ecs_exec ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = local.ecs_exec_kms_key_arn_final
        logging    = "OVERRIDE"

        log_configuration {
          cloud_watch_encryption_enabled = true
          cloud_watch_log_group_name     = aws_cloudwatch_log_group.microservices_exec[0].name
        }
      }
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "microservices" {
  count = local.runtime_mode_is_micro ? 1 : 0

  name = local.service_discovery_namespace_name_final
  vpc  = local.selected_vpc_id
}

resource "aws_service_discovery_service" "microservices" {
  for_each = local.runtime_mode_is_micro ? {
    for service_name, service in local.ecs_services_final :
    service_name => service if service.enable_service_discovery
  } : {}

  name = each.value.discovery_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.microservices[0].id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  lifecycle {
    ignore_changes = [
      health_check_custom_config
    ]
  }
}

module "alb" {
  source = "../alb"

  vpc_id                            = local.selected_vpc_id
  alb_subnet_ids                    = local.selected_private_app_subnet_ids
  alb_security_group_id             = local.runtime_mode_is_single ? module.security_groups[0].backend_alb_sg_id : aws_security_group.microservices_alb[0].id
  app_port                          = local.runtime_mode_is_single ? var.backend_container_port : local.public_service_port
  alb_listener_port                 = var.alb_listener_port
  enable_origin_http_listener       = var.backend_origin_protocol_policy == "http-only"
  origin_http_listener_port         = 80
  certificate_arn                   = var.alb_certificate_arn
  ssl_policy                        = var.alb_ssl_policy
  health_check_path                 = local.runtime_mode_is_single ? var.backend_healthcheck_path : local.public_service_health_check_path
  health_check_matcher              = var.alb_health_check_matcher
  health_check_interval_seconds     = var.alb_health_check_interval_seconds
  health_check_timeout_seconds      = var.alb_health_check_timeout_seconds
  health_check_healthy_threshold    = var.alb_health_check_healthy_threshold
  health_check_unhealthy_threshold  = var.alb_health_check_unhealthy_threshold
  target_type                       = "ip"
  alb_name                          = var.alb_name
  target_group_name                 = var.alb_target_group_name
  enable_environment_suffix         = local.enable_environment_suffix
  environment_name_override         = local.environment_name
  enable_deletion_protection        = local.effective_alb_deletion_protection
  idle_timeout                      = var.alb_idle_timeout
  access_logs_bucket                = aws_s3_bucket.alb_access_logs.id
  access_logs_prefix                = local.alb_access_logs_prefix
  enable_origin_auth_header         = var.enable_origin_auth_header
  origin_auth_header_name           = var.origin_auth_header_name
  origin_auth_header_value          = local.origin_auth_header_value_resolved
  origin_auth_previous_header_name  = var.origin_auth_previous_header_name
  origin_auth_previous_header_value = local.origin_auth_previous_header_value_resolved
}

resource "aws_cloudfront_vpc_origin" "backend_primary" {
  depends_on = [module.network]

  vpc_origin_endpoint_config {
    arn                    = module.alb.alb_arn
    http_port              = 80
    https_port             = var.alb_listener_port
    name                   = local.enable_environment_suffix ? "backend-origin-${local.environment_name}" : "backend-origin"
    origin_protocol_policy = "https-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

resource "aws_cloudfront_vpc_origin" "backend_primary_http" {
  count      = var.backend_origin_protocol_policy == "http-only" ? 1 : 0
  depends_on = [module.network, module.alb]

  vpc_origin_endpoint_config {
    arn                    = module.alb.alb_arn
    http_port              = 80
    https_port             = var.alb_listener_port
    name                   = local.enable_environment_suffix ? "backend-origin-http-${local.environment_name}" : "backend-origin-http"
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

data "aws_security_group" "cloudfront_vpc_origin" {
  count      = local.runtime_mode_is_micro ? 1 : 0
  depends_on = [aws_cloudfront_vpc_origin.backend_primary, aws_cloudfront_vpc_origin.backend_primary_http]

  filter {
    name   = "group-name"
    values = ["CloudFront-VPCOrigins-Service-SG"]
  }

  filter {
    name   = "vpc-id"
    values = [local.selected_vpc_id]
  }
}

resource "aws_security_group_rule" "microservices_cloudfront_to_alb_https" {
  count = local.runtime_mode_is_micro ? 1 : 0

  type                     = "ingress"
  from_port                = var.alb_listener_port
  to_port                  = var.alb_listener_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.microservices_alb[0].id
  source_security_group_id = data.aws_security_group.cloudfront_vpc_origin[0].id
  description              = "Allow CloudFront VPC origin traffic to the ALB HTTPS listener."
}

resource "aws_security_group_rule" "microservices_cloudfront_to_alb_http" {
  count = local.runtime_mode_is_micro && var.backend_origin_protocol_policy == "http-only" ? 1 : 0

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.microservices_alb[0].id
  source_security_group_id = data.aws_security_group.cloudfront_vpc_origin[0].id
  description              = "Allow CloudFront VPC origin traffic to the ALB HTTP listener."
}

resource "aws_wafv2_web_acl" "alb" {
  count = local.create_managed_waf_alb ? 1 : 0

  name  = local.enable_environment_suffix ? "backend-alb-waf-${local.environment_name}" : "backend-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.enable_environment_suffix ? "backend-alb-waf-${local.environment_name}" : "backend-alb-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.enable_environment_suffix ? "alb-known-bad-inputs-${local.environment_name}" : "alb-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.enable_environment_suffix ? "alb-common-rules-${local.environment_name}" : "alb-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit_requests_per_5_mins
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.enable_environment_suffix ? "alb-rate-limit-${local.environment_name}" : "alb-rate-limit"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_cloudwatch_log_group" "waf_alb" {
  count = local.create_managed_waf_alb ? 1 : 0

  name              = local.enable_environment_suffix ? "aws-waf-logs-backend-alb-${local.environment_name}" : "aws-waf-logs-backend-alb"
  retention_in_days = var.waf_log_retention_days
  kms_key_id        = null
}

resource "aws_wafv2_web_acl_logging_configuration" "alb" {
  count = local.create_managed_waf_alb ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf_alb[0].arn]
  resource_arn            = aws_wafv2_web_acl.alb[0].arn
}

resource "aws_wafv2_web_acl_association" "alb_managed" {
  count = local.create_managed_waf_alb ? 1 : 0

  resource_arn = module.alb.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb[0].arn
}

resource "aws_wafv2_web_acl_association" "alb_custom" {
  count = var.alb_web_acl_arn != null ? 1 : 0

  resource_arn = module.alb.alb_arn
  web_acl_arn  = var.alb_web_acl_arn
}

resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1
  count    = local.create_managed_waf_cloudfront ? 1 : 0

  name  = local.enable_environment_suffix ? "cloudfront-waf-${local.environment_name}" : "cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.enable_environment_suffix ? "cloudfront-waf-${local.environment_name}" : "cloudfront-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.enable_environment_suffix ? "cf-known-bad-inputs-${local.environment_name}" : "cf-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.enable_environment_suffix ? "cf-common-rules-${local.environment_name}" : "cf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit_requests_per_5_mins
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = local.enable_environment_suffix ? "cf-rate-limit-${local.environment_name}" : "cf-rate-limit"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_cloudwatch_log_group" "waf_cloudfront" {
  provider = aws.us_east_1
  count    = local.create_managed_waf_cloudfront ? 1 : 0

  name              = local.enable_environment_suffix ? "aws-waf-logs-cloudfront-${local.environment_name}" : "aws-waf-logs-cloudfront"
  retention_in_days = var.waf_log_retention_days
  kms_key_id        = null
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  provider = aws.us_east_1
  count    = local.create_managed_waf_cloudfront ? 1 : 0

  log_destination_configs = [aws_cloudwatch_log_group.waf_cloudfront[0].arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront[0].arn
}

module "s3" {
  source = "../s3"

  bucket_name                                      = local.bucket_name_final
  force_destroy                                    = local.effective_s3_force_destroy
  versioning_enabled                               = var.s3_versioning_enabled
  enable_kms_encryption                            = true
  kms_key_id                                       = local.s3_primary_kms_key_arn
  enable_access_logging                            = var.enable_s3_access_logging
  access_logging_target_bucket_name                = var.enable_s3_access_logging ? aws_s3_bucket.s3_access_logs.id : null
  access_logging_target_prefix                     = "s3-access/frontend/"
  access_logging_prerequisite_ids                  = var.enable_s3_access_logging ? [aws_s3_bucket_policy.s3_access_logs_bucket.id] : []
  enable_replication                               = true
  replication_role_arn                             = aws_iam_role.frontend_replication.arn
  replication_destination_bucket_arn               = aws_s3_bucket.frontend_dr.arn
  replication_replica_kms_key_id                   = local.s3_dr_kms_key_arn
  replication_prerequisite_ids                     = [aws_s3_bucket_versioning.frontend_dr.id, aws_iam_role_policy.frontend_replication.id]
  enable_lifecycle                                 = var.enable_s3_lifecycle
  lifecycle_expiration_days                        = var.s3_lifecycle_expiration_days
  lifecycle_noncurrent_expiration_days             = var.s3_lifecycle_noncurrent_expiration_days
  lifecycle_abort_incomplete_multipart_upload_days = var.s3_lifecycle_abort_incomplete_multipart_upload_days
}

data "aws_iam_policy_document" "s3_access_logs_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.s3_access_logs.arn,
      "${aws_s3_bucket.s3_access_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowS3ServerAccessLogsDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.s3_access_logs.arn}/s3-access/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = compact([
        module.s3.bucket_arn,
        aws_s3_bucket.alb_access_logs.arn,
        aws_s3_bucket.cloudfront_logs.arn
      ])
    }
  }
}

resource "aws_s3_bucket_policy" "s3_access_logs_bucket" {
  bucket = aws_s3_bucket.s3_access_logs.id
  policy = data.aws_iam_policy_document.s3_access_logs_bucket_policy.json
}

resource "aws_s3_bucket" "frontend_dr" {
  provider = aws.dr
  #checkov:skip=CKV_AWS_144: Destination bucket in the frontend CRR topology; Checkov can miss the module-owned source replication association.
  bucket        = local.dr_frontend_bucket_name_final
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "frontend_dr_eventbridge" {
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "frontend_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.s3_dr_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "frontend_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend_dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.frontend_dr.id

  rule {
    id     = "frontend-dr-lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "frontend_dr" {
  provider = aws.dr
  count    = var.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.frontend_dr.id
  target_bucket = aws_s3_bucket.s3_access_logs_dr.id
  target_prefix = "s3-access/frontend-dr/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_dr_bucket]
}

resource "aws_s3_bucket" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket        = local.dr_cloudfront_logs_bucket_name_final
  force_destroy = local.effective_s3_force_destroy
}

resource "aws_s3_bucket_notification" "cloudfront_logs_dr_eventbridge" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = local.s3_dr_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs_dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.cloudfront_logs_dr.id

  rule {
    id     = "cloudfront-logs-dr-lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "cloudfront_logs_dr" {
  provider = aws.dr
  count    = var.enable_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.cloudfront_logs_dr.id
  target_bucket = aws_s3_bucket.s3_access_logs_dr.id
  target_prefix = "s3-access/cloudfront-logs-dr/"

  depends_on = [aws_s3_bucket_policy.s3_access_logs_dr_bucket]
}

module "cloudfront_frontend" {
  source = "../cloudfront_frontend"

  frontend_bucket_domain     = module.s3.bucket_domain_name
  secondary_bucket_domain    = local.dr_frontend_bucket_domain
  frontend_aliases           = local.frontend_aliases_final
  frontend_cert_arn          = var.acm_cert_frontend
  cache_policy_id            = var.frontend_cache_policy_id
  price_class                = var.frontend_price_class
  response_headers_policy_id = var.frontend_response_headers_policy_id
  viewer_protocol_policy     = var.frontend_viewer_protocol_policy
  geo_restriction_type       = var.frontend_geo_restriction_type
  geo_locations              = var.frontend_geo_locations
  access_logs_bucket         = local.cloudfront_logs_bucket_domain
  access_logs_prefix         = "${var.cloudfront_logs_prefix}edge/"
  enable_environment_suffix  = local.enable_environment_suffix
  environment_domain         = local.environment_domain
  environment_name_override  = local.environment_name
  web_acl_id                 = coalesce(var.frontend_web_acl_arn, var.backend_web_acl_arn, try(aws_wafv2_web_acl.cloudfront[0].arn, null))
  enable_spa_routing         = var.frontend_runtime_mode == "s3"
  backend_origin_enabled     = true
  backend_origin_domain_name = module.alb.alb_dns_name
  backend_origin_vpc_origin_id = (
    var.backend_origin_protocol_policy == "http-only"
    ? aws_cloudfront_vpc_origin.backend_primary_http[0].id
    : aws_cloudfront_vpc_origin.backend_primary.id
  )
  backend_origin_https_port                 = var.alb_listener_port
  backend_origin_protocol_policy            = var.backend_origin_protocol_policy
  backend_viewer_protocol_policy            = var.backend_viewer_protocol_policy
  backend_cache_policy_id                   = var.backend_cache_policy_id
  backend_origin_request_policy_id          = var.backend_origin_request_policy_id
  backend_response_headers_policy_id        = var.backend_response_headers_policy_id
  backend_allowed_methods                   = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  backend_path_patterns                     = local.backend_path_patterns
  backend_origin_auth_enabled               = var.enable_origin_auth_header
  backend_origin_auth_header_name           = var.origin_auth_header_name
  backend_origin_auth_header_value          = local.origin_auth_header_value_resolved
  backend_origin_auth_previous_header_name  = var.origin_auth_previous_header_name
  backend_origin_auth_previous_header_value = local.origin_auth_previous_header_value_resolved

  frontend_runtime_mode    = var.frontend_runtime_mode
  frontend_alb_domain_name = module.alb.alb_dns_name
  frontend_vpc_origin_id   = var.backend_origin_protocol_policy == "http-only" ? aws_cloudfront_vpc_origin.backend_primary_http[0].id : aws_cloudfront_vpc_origin.backend_primary.id
  frontend_alb_https_port  = var.alb_listener_port
}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      module.s3.bucket_arn,
      "${module.s3.bucket_arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.s3.bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront_frontend.frontend_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = module.s3.bucket_name
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}

data "aws_iam_policy_document" "frontend_dr_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.frontend_dr.arn,
      "${aws_s3_bucket.frontend_dr.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowCloudFrontReadObjects"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend_dr.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront_frontend.frontend_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_dr_policy" {
  provider = aws.dr

  bucket = aws_s3_bucket.frontend_dr.id
  policy = data.aws_iam_policy_document.frontend_dr_bucket_policy.json
}

data "aws_iam_policy_document" "frontend_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "frontend_replication" {
  name               = local.enable_environment_suffix ? "s3-frontend-replication-${local.environment_name}" : "s3-frontend-replication"
  assume_role_policy = data.aws_iam_policy_document.frontend_replication_assume_role.json
}

data "aws_iam_policy_document" "frontend_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.s3.bucket_arn]
  }

  #tfsec:ignore:aws-iam-no-policy-wildcards S3 replication requires object ARN wildcards to cover all keys in the source bucket.
  statement {
    sid = "SourceObjectReadForReplication"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = ["${module.s3.bucket_arn}/*"]
  }

  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.frontend_dr.arn}/*"]
  }

  statement {
    sid = "AllowKmsOnSourceAndDestinationKeys"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]
    resources = [
      local.s3_primary_kms_key_arn,
      local.s3_dr_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "frontend_replication" {
  name   = local.enable_environment_suffix ? "s3-frontend-replication-${local.environment_name}" : "s3-frontend-replication"
  role   = aws_iam_role.frontend_replication.id
  policy = data.aws_iam_policy_document.frontend_replication.json
}

data "aws_iam_policy_document" "cloudfront_logs_replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudfront_logs_replication" {
  name = local.enable_environment_suffix ? "s3-cf-logs-repl-${local.environment_name}" : "s3-cf-logs-repl"

  assume_role_policy = data.aws_iam_policy_document.cloudfront_logs_replication_assume_role.json
}

data "aws_iam_policy_document" "cloudfront_logs_replication" {
  statement {
    sid = "SourceBucketConfig"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.cloudfront_logs.arn]
  }

  statement {
    sid = "SourceObjectReadForReplication"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = ["${aws_s3_bucket.cloudfront_logs.arn}/*"]
  }

  statement {
    sid = "DestinationWriteForReplication"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.cloudfront_logs_dr.arn}/*"]
  }

  statement {
    sid = "AllowKmsOnSourceAndDestinationKeys"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]
    resources = [
      local.s3_primary_kms_key_arn,
      local.s3_dr_kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "cloudfront_logs_replication" {
  name   = local.enable_environment_suffix ? "s3-cf-logs-repl-${local.environment_name}" : "s3-cf-logs-repl"
  role   = aws_iam_role.cloudfront_logs_replication.id
  policy = data.aws_iam_policy_document.cloudfront_logs_replication.json
}

resource "aws_s3_bucket_replication_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  role   = aws_iam_role.cloudfront_logs_replication.arn

  rule {
    id     = "cloudfront-logs-to-dr"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.cloudfront_logs_dr.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = local.s3_dr_kms_key_arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.cloudfront_logs,
    aws_s3_bucket_versioning.cloudfront_logs_dr,
    aws_iam_role_policy.cloudfront_logs_replication
  ]
}

module "rds" {
  source = "../rds"

  identifier                      = var.rds_identifier
  db_name                         = var.rds_db_name
  username                        = var.rds_username
  password                        = null
  manage_master_user_password     = true
  master_user_secret_kms_key_id   = var.rds_master_user_secret_kms_key_id
  instance_class                  = var.rds_instance_class
  allocated_storage               = var.rds_allocated_storage
  max_allocated_storage           = var.rds_max_allocated_storage
  backup_retention_period         = var.rds_backup_retention_period
  preferred_backup_window         = var.rds_preferred_backup_window
  preferred_maintenance_window    = var.rds_preferred_maintenance_window
  final_snapshot_identifier       = var.rds_final_snapshot_identifier
  deletion_protection             = var.destroy_mode_enabled ? false : var.rds_deletion_protection
  skip_final_snapshot             = var.destroy_mode_enabled ? true : var.rds_skip_final_snapshot_on_destroy
  enable_performance_insights     = var.rds_enable_performance_insights
  performance_insights_kms_key_id = null
  kms_key_id                      = null
  enable_iam_database_auth        = var.enable_rds_iam_auth
  monitoring_interval_seconds     = var.rds_monitoring_interval_seconds
  enabled_cloudwatch_logs_exports = var.rds_enabled_cloudwatch_logs_exports
  rds_sg_id = (
    local.runtime_mode_is_single
    ? module.security_groups[0].rds_sg_id
    : aws_security_group.microservices_rds[0].id
  )
  db_subnet_ids             = local.selected_db_subnet_ids
  enable_environment_suffix = local.enable_environment_suffix
  environment_name_override = local.environment_name
}

module "ecs_backend" {
  count  = local.runtime_mode_is_single ? 1 : 0
  source = "../ecs_backend"

  private_subnet_ids        = local.selected_private_app_subnet_ids
  service_security_group_id = module.security_groups[0].backend_service_sg_id
  target_group_arn          = module.alb.target_group_arn

  cluster_name                                 = var.backend_cluster_name
  service_name                                 = var.backend_service_name
  task_family                                  = var.backend_task_family
  execution_role_name                          = var.backend_execution_role_name
  task_role_name                               = var.backend_task_role_name
  container_name                               = var.backend_container_name
  container_image                              = var.backend_container_image
  container_port                               = var.backend_container_port
  container_user                               = var.backend_container_user
  readonly_root_fs                             = var.backend_readonly_root_filesystem
  drop_capabilities                            = var.backend_drop_linux_capabilities
  task_cpu                                     = var.backend_task_cpu
  task_memory                                  = var.backend_task_memory
  desired_count                                = var.backend_desired_count
  min_count                                    = var.backend_min_count
  max_count                                    = var.backend_max_count
  cpu_target_value                             = var.backend_cpu_target_value
  memory_target_value                          = var.backend_memory_target_value
  alb_request_count_target_value               = var.backend_alb_request_count_target_value
  alb_request_count_scale_in_cooldown_seconds  = var.backend_alb_request_count_scale_in_cooldown_seconds
  alb_request_count_scale_out_cooldown_seconds = var.backend_alb_request_count_scale_out_cooldown_seconds
  health_check_grace_period_seconds            = var.backend_healthcheck_grace_period_seconds
  enable_execute_command                       = var.enable_ecs_exec
  exec_kms_key_arn                             = local.ecs_exec_kms_key_arn_final
  exec_log_group_name                          = var.ecs_exec_log_group_name
  exec_log_retention_days                      = var.ecs_exec_log_retention_days
  alb_arn_suffix                               = module.alb.alb_arn_suffix
  target_group_arn_suffix                      = module.alb.target_group_arn_suffix
  deploy_alarm_5xx_threshold                   = var.backend_deploy_alarm_5xx_threshold
  deploy_alarm_unhealthy_hosts_threshold       = var.backend_deploy_alarm_unhealthy_hosts_threshold
  deploy_alarm_eval_periods                    = var.backend_deploy_alarm_eval_periods

  scale_in_cooldown_seconds  = var.backend_scale_in_cooldown_seconds
  scale_out_cooldown_seconds = var.backend_scale_out_cooldown_seconds

  environment           = local.backend_env_final
  secret_arns           = local.backend_secret_arns_final
  secret_kms_key_arns   = var.backend_secret_kms_key_arns
  task_role_policy_json = var.backend_task_role_policy_json

  log_group_name            = var.backend_log_group_name
  log_retention_days        = var.backend_log_retention_days
  log_kms_key_id            = var.backend_log_kms_key_id
  enable_environment_suffix = local.enable_environment_suffix
  environment_name_override = local.environment_name
}

module "ecs_service" {
  for_each = local.runtime_mode_is_micro ? local.ecs_services_final : {}
  source   = "../ecs_service"

  cluster_arn  = aws_ecs_cluster.microservices[0].arn
  cluster_name = aws_ecs_cluster.microservices[0].name

  private_subnet_ids = local.selected_private_app_subnet_ids
  service_security_group_ids = concat(
    each.key == local.public_service_key ? [
      aws_security_group.microservices_gateway[0].id,
      aws_security_group.microservices_internal[0].id
      ] : [
      aws_security_group.microservices_internal[0].id
    ],
    contains(keys(aws_security_group.microservices_extra_egress), each.key) ? [
      aws_security_group.microservices_extra_egress[each.key].id
    ] : []
  )

  service_name        = "${var.project_name}-${each.key}-${local.environment_name}"
  task_family         = "${var.project_name}-${each.key}-${local.environment_name}"
  execution_role_name = "${var.project_name}-${each.key}-${local.environment_name}-exec"
  task_role_name      = "${var.project_name}-${each.key}-${local.environment_name}-task"

  container_name    = each.value.container_name
  container_image   = each.value.image
  container_port    = each.value.container_port
  container_user    = each.value.container_user
  readonly_root_fs  = each.value.readonly_root_fs
  drop_capabilities = each.value.drop_capabilities

  task_cpu                               = each.value.cpu
  task_memory                            = each.value.memory
  desired_count                          = each.value.desired_count
  min_count                              = each.value.min_count
  max_count                              = each.value.max_count
  health_check_grace_period_seconds      = each.value.health_check_grace_period_seconds
  enable_execute_command                 = var.enable_ecs_exec
  exec_kms_key_arn                       = local.ecs_exec_kms_key_arn_final
  exec_log_group_name                    = null
  scale_in_cooldown_seconds              = var.backend_scale_in_cooldown_seconds
  scale_out_cooldown_seconds             = var.backend_scale_out_cooldown_seconds
  alb_arn_suffix                         = each.key == local.public_service_key ? module.alb.alb_arn_suffix : null
  target_group_arn_suffix                = each.key == local.public_service_key ? module.alb.target_group_arn_suffix : null
  enable_deploy_alarms                   = each.key == local.public_service_key
  deploy_alarm_5xx_threshold             = var.backend_deploy_alarm_5xx_threshold
  deploy_alarm_unhealthy_hosts_threshold = var.backend_deploy_alarm_unhealthy_hosts_threshold
  deploy_alarm_eval_periods              = var.backend_deploy_alarm_eval_periods

  environment           = each.value.env
  secret_arns           = each.value.secret_arns
  secret_kms_key_arns   = each.value.secret_kms_key_arns
  log_group_name        = each.value.log_group_name
  log_retention_days    = each.value.log_retention_days
  log_kms_key_id        = each.value.log_kms_key_id
  task_role_policy_json = each.value.task_role_policy_json

  enable_load_balancer           = each.key == local.public_service_key
  load_balancer_target_group_arn = each.key == local.public_service_key ? module.alb.target_group_arn : null
  service_discovery_registry_arn = try(aws_service_discovery_service.microservices[each.key].arn, null)

  entrypoint                        = each.value.entrypoint
  command                           = each.value.command
  mount_points                      = each.value.mount_points
  task_volumes                      = each.value.task_volumes
  health_check_command              = each.value.health_check_command
  health_check_interval_seconds     = each.value.health_check_interval_seconds
  health_check_timeout_seconds      = each.value.health_check_timeout_seconds
  health_check_retries              = each.value.health_check_retries
  health_check_start_period_seconds = each.value.health_check_start_period_seconds
  assign_public_ip                  = each.value.assign_public_ip
}

resource "aws_route53_record" "frontend_root" {
  allow_overwrite = true
  zone_id         = local.route53_zone_id_effective
  name            = local.frontend_aliases_final[0]
  type            = "A"

  alias {
    name                   = module.cloudfront_frontend.frontend_url
    zone_id                = module.cloudfront_frontend.frontend_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend_www" {
  allow_overwrite = true
  zone_id         = local.route53_zone_id_effective
  name            = local.frontend_aliases_final[1]
  type            = "A"

  alias {
    name                   = module.cloudfront_frontend.frontend_url
    zone_id                = module.cloudfront_frontend.frontend_hosted_zone_id
    evaluate_target_health = false
  }
}
