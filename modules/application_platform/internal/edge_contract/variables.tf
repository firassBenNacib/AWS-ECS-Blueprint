variable "routing" {
  type = object({
    frontend_aliases              = list(string)
    backend_path_patterns         = list(string)
    backend_ingress_is_vpc_origin = bool
    route53_zone_id_effective     = string
    route53_zone_name_effective   = string
    route53_zone_managed          = bool
    frontend_runtime_is_s3        = bool
    bucket_name_final             = string
    dr_frontend_bucket_name_final = string
    create_managed_waf_alb        = bool
    create_managed_waf_cloudfront = bool
  })
}

variable "networking" {
  type = object({
    vpc_id                    = string
    interface_endpoints_sg_id = string
    s3_gateway_prefix_list_id = string
    public_edge_subnet_ids    = list(string)
    private_app_subnet_ids    = list(string)
    private_db_subnet_ids     = list(string)
  })
}

variable "frontend" {
  type = object({
    primary_bucket_name    = string
    primary_bucket_domain  = string
    primary_bucket_arn     = string
    dr_bucket_name         = string
    dr_bucket_domain       = string
    dr_bucket_arn          = string
    cloudfront_logs_domain = string
  })
}
