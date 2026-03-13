# Operations Runbooks

## State Snapshot Before Changes

1. Run `bash .scripts/snapshot_state_and_reports.sh <deployment_root_dir> <backend_hcl_file>`.
2. Confirm state JSON, report archive, and SHA256 manifest were generated.
3. Store snapshot artifacts in your evidence location before any migration or apply.

## ECS Exec Break-Glass

1. Set `enable_ecs_exec = true`.
2. Set `ecs_exec_kms_key_arn` to a valid KMS key ARN.
3. Set `ecs_exec_log_group_name` and `ecs_exec_log_retention_days`.
4. Apply Terraform.
5. Perform audited session access with least privilege IAM.
6. Revert `enable_ecs_exec = false` after the incident or debug window closes.
7. Apply Terraform and confirm ECS Exec is disabled again.

## Private Egress Rollback

1. If `private_app_nat_mode = "disabled"` causes runtime impact, change to `canary`.
2. Apply Terraform and verify image pulls, logs, secret retrieval, and KMS decrypt.
3. If the issue persists, change to `required`.
4. Apply Terraform and confirm service recovery.
5. Review VPC endpoint coverage and any declared per-service outbound exceptions before retrying `canary` or `disabled`.

## Backend Failover Origin Validation

1. Confirm `backend_failover_domain_name` resolves to a healthy DR backend origin.
2. Confirm DR origin TLS certificate and listener path are valid.
3. Inject controlled primary-origin 5xx responses.
4. Verify CloudFront backend origin-group failover to the DR origin.
5. Confirm response and latency remain within expected SLO bounds.
6. Restore the primary origin and verify traffic normalization.

## RDS Restore Drill

1. Create a fresh manual snapshot or select the latest automated recovery point.
2. Restore into isolated subnets and security groups.
3. Run application smoke queries against the restored instance.
4. Verify secrets, monitoring, backup enrollment, and parameter groups on the restored database.
5. Record measured RTO/RPO and manual intervention points.

## ALB Log DR Validation

1. Confirm both `alb_access_logs_bucket_name` and `alb_access_logs_dr_bucket_name` outputs exist after apply.
2. Generate controlled ALB traffic and wait for fresh objects in the primary ALB log bucket.
3. Verify the same objects replicate to the DR ALB log bucket in `dr_region`.
4. Confirm lifecycle, versioning, and public-access-block controls remain enabled on the DR bucket.
