data "aws_caller_identity" "current" {}

locals {
  targets = {
    prod-app = {
      root_id                     = "prod-app"
      dns_label                   = lower(trimspace(var.prod_validation_dns_label))
      frontend_domain             = "${lower(trimspace(var.prod_validation_dns_label))}.${trimsuffix(lower(trimspace(var.environment_domain)), ".")}"
      alb_certificate_domain      = "api-${lower(trimspace(var.prod_validation_dns_label))}.${trimsuffix(lower(trimspace(var.environment_domain)), ".")}"
      origin_auth_parameter_name  = "/${var.project_name}/live-validation/prod-app/origin-auth/current"
      bucket_name                 = trimspace(var.prod_bucket_name) != "" ? trimspace(var.prod_bucket_name) : "${var.project_name}-lv-prod-frontend"
      cloudfront_logs_bucket_name = trimspace(var.prod_cloudfront_logs_bucket_name) != "" ? trimspace(var.prod_cloudfront_logs_bucket_name) : "${var.project_name}-lv-prod-cf-logs-${data.aws_caller_identity.current.account_id}"
      vpc_cidr                    = "10.30.0.0/16"
      public_app_subnet_cidrs     = ["10.30.1.0/24", "10.30.2.0/24"]
      private_app_subnet_cidrs    = ["10.30.21.0/24", "10.30.22.0/24"]
      private_db_subnet_cidrs     = ["10.30.11.0/24", "10.30.12.0/24"]
      availability_zones          = ["eu-west-1a", "eu-west-1b"]
      root_variable_name          = "prod_app_role_arn"
    }
    nonprod-app = {
      root_id                     = "nonprod-app"
      dns_label                   = lower(trimspace(var.nonprod_validation_dns_label))
      frontend_domain             = "${lower(trimspace(var.nonprod_validation_dns_label))}.${trimsuffix(lower(trimspace(var.environment_domain)), ".")}"
      alb_certificate_domain      = "api-${lower(trimspace(var.nonprod_validation_dns_label))}.${trimsuffix(lower(trimspace(var.environment_domain)), ".")}"
      origin_auth_parameter_name  = "/${var.project_name}/live-validation/nonprod-app/origin-auth/current"
      bucket_name                 = trimspace(var.nonprod_bucket_name) != "" ? trimspace(var.nonprod_bucket_name) : "${var.project_name}-lv-nonprod-frontend"
      cloudfront_logs_bucket_name = trimspace(var.nonprod_cloudfront_logs_bucket_name) != "" ? trimspace(var.nonprod_cloudfront_logs_bucket_name) : "${var.project_name}-lv-nonprod-cf-logs-${data.aws_caller_identity.current.account_id}"
      vpc_cidr                    = "10.40.0.0/16"
      public_app_subnet_cidrs     = ["10.40.1.0/24", "10.40.2.0/24"]
      private_app_subnet_cidrs    = ["10.40.21.0/24", "10.40.22.0/24"]
      private_db_subnet_cidrs     = ["10.40.11.0/24", "10.40.12.0/24"]
      availability_zones          = ["eu-west-1a", "eu-west-1b"]
      root_variable_name          = "nonprod_app_role_arn"
    }
  }

  frontend_cert_dns_records = merge([
    for target_id, target in local.targets : {
      for dvo in aws_acm_certificate.frontend[target_id].domain_validation_options :
      "${target_id}/${dvo.domain_name}" => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
  ]...)

  alb_cert_dns_records = merge([
    for target_id, target in local.targets : {
      for dvo in aws_acm_certificate.alb[target_id].domain_validation_options :
      "${target_id}/${dvo.domain_name}" => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
  ]...)
}

resource "random_password" "origin_auth_current" {
  for_each = local.targets

  length  = 40
  special = false
}

resource "aws_ssm_parameter" "origin_auth_current" {
  for_each = local.targets

  name   = each.value.origin_auth_parameter_name
  type   = "SecureString"
  tier   = "Standard"
  key_id = "alias/aws/ssm"
  value  = random_password.origin_auth_current[each.key].result
}

resource "aws_acm_certificate" "frontend" {
  for_each = local.targets
  provider = aws.us_east_1

  domain_name       = each.value.frontend_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "frontend_cert_validation" {
  for_each = local.frontend_cert_dns_records

  allow_overwrite = true
  zone_id         = var.route53_zone_id
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "frontend" {
  for_each = local.targets
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.frontend[each.key].arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.frontend[each.key].domain_validation_options :
    aws_route53_record.frontend_cert_validation["${each.key}/${dvo.domain_name}"].fqdn
  ]
}

resource "aws_acm_certificate" "alb" {
  for_each = local.targets

  domain_name       = each.value.alb_certificate_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_cert_validation" {
  for_each = local.alb_cert_dns_records

  allow_overwrite = true
  zone_id         = var.route53_zone_id
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "alb" {
  for_each = local.targets

  certificate_arn = aws_acm_certificate.alb[each.key].arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.alb[each.key].domain_validation_options :
    aws_route53_record.alb_cert_validation["${each.key}/${dvo.domain_name}"].fqdn
  ]
}
