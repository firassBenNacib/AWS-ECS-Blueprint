locals {
  selected_public_edge_subnet_ids = sort(var.networking.public_edge_subnet_ids)
  selected_private_app_subnet_ids = sort(var.networking.private_app_subnet_ids)
  selected_db_subnet_ids          = sort(var.networking.private_db_subnet_ids)
  selected_alb_subnet_ids         = var.routing.backend_ingress_is_vpc_origin ? local.selected_private_app_subnet_ids : local.selected_public_edge_subnet_ids

  frontend_primary_bucket_arn_expected = var.routing.frontend_runtime_is_s3 ? "arn:aws:s3:::${var.routing.bucket_name_final}" : null
  frontend_dr_bucket_arn_expected      = var.routing.frontend_runtime_is_s3 ? "arn:aws:s3:::${var.routing.dr_frontend_bucket_name_final}" : null
}
