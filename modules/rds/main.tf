locals {
  environment_name = (
    var.environment_name_override != null && trimspace(var.environment_name_override) != ""
  ) ? trimspace(var.environment_name_override) : terraform.workspace
  identifier_final                = var.enable_environment_suffix ? "${var.identifier}-${local.environment_name}" : var.identifier
  final_snapshot_identifier_final = coalesce(var.final_snapshot_identifier, "${local.identifier_final}-final")
}

data "aws_iam_policy_document" "enhanced_monitoring_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.monitoring_interval_seconds > 0 ? 1 : 0

  name               = "${local.identifier_final}-enhanced-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring_assume_role.json
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.monitoring_interval_seconds > 0 ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.identifier_final}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${local.identifier_final}-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier                          = local.identifier_final
  engine                              = "mysql"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_type                        = "gp3"
  username                            = var.username
  password                            = var.manage_master_user_password ? null : var.password
  manage_master_user_password         = var.manage_master_user_password
  master_user_secret_kms_key_id       = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null
  db_name                             = var.db_name
  parameter_group_name                = "default.mysql8.0"
  option_group_name                   = "default:mysql-8-0"
  publicly_accessible                 = false
  multi_az                            = var.multi_az
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_id
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.preferred_backup_window
  maintenance_window                  = var.preferred_maintenance_window
  monitoring_interval                 = var.monitoring_interval_seconds
  monitoring_role_arn                 = var.monitoring_interval_seconds > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : local.final_snapshot_identifier_final
  iam_database_authentication_enabled = var.enable_iam_database_auth
  performance_insights_enabled        = var.enable_performance_insights
  performance_insights_kms_key_id     = var.enable_performance_insights ? var.performance_insights_kms_key_id : null
  copy_tags_to_snapshot               = true
  auto_minor_version_upgrade          = true
  db_subnet_group_name                = aws_db_subnet_group.this.name

  vpc_security_group_ids = [var.rds_sg_id]

  tags = {
    Name = local.identifier_final
  }
}
