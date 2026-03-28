locals {
  backend_env_defaults = {
    DB_HOST = var.app_data.address
    DB_PORT = "3306"
    DB_NAME = var.runtime.rds_db_name
    DB_USER = var.runtime.rds_username
  }

  backend_env_final = merge(local.backend_env_defaults, var.backend.backend_env)
  backend_secret_arns_final = merge(
    var.backend.backend_secret_arns,
    { (var.backend.backend_rds_secret_env_var_name) = var.app_data.master_user_secret_arn }
  )

  microservice_env_placeholders = {
    "__RDS_ENDPOINT__" = var.app_data.address
    "__RDS_DB_NAME__"  = var.runtime.rds_db_name
    "__SMTP_HOST__"    = var.runtime.smtp_host
  }
  microservice_secret_placeholders = {
    "__RDS_MASTER_PASSWORD_SECRET_ARN__" = "${var.app_data.master_user_secret_arn}:password::"
  }
}
