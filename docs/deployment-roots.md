# Deployment Root Entry Points

Two deployment roots are in scope in this repository:

- `prod-app`: production application runtime deployment root
- `nonprod-app`: non-production application runtime deployment root

Each deployment root includes:
- `backend.hcl.example` with a unique state-key pattern
- `terraform.tfvars.example` for `single_backend` mode
- `terraform.microservices.tfvars.example` for `gateway_microservices` mode
- `terraform.frontend-ecs.tfvars.example` for frontend `ecs` mode
- `terraform.public-alb-restricted.tfvars.example` for backend `public_alb_restricted` mode
- a deployment-root `README.md`

Optional cost-visibility inputs such as `enable_budget_alerts`, `budget_alert_email_addresses`, and the per-service monthly budget limits are supported by both roots, even when they are omitted from the curated example profiles.

The checked-in `nonprod-app/terraform.tfvars` uses a low-cost non-production profile with `private_app_nat_mode = "canary"` so private services still reach external providers through one NAT gateway. The default `nonprod-app/terraform.tfvars.example` remains the ultra-cheap profile. It turns on `enable_cost_optimized_dev_tier`, which disables NAT gateways, disables managed WAF and per-root AWS Backup, keeps RDS single-AZ, clamps ECS service counts to `1/1/1`, and disables account-level security controls for that root.

The public repository path is intentionally platform-only. Multi-account bootstrap roots are not part of the supported surface in this repo.

## Account Strategy

The recommended operating model is:

- `prod-app` in a dedicated production account
- `nonprod-app` in a separate non-production account
- optional shared security and log-archive accounts if your organization already uses them

The repository already supports that split through distinct backend keys, CI target metadata, and per-root `assume_role` inputs.

## Route53 Strategy

Public DNS resolution now uses an explicit strategy instead of an implicit fallback chain:

- `route53_zone_strategy = "explicit"`: require `route53_zone_id`
- `route53_zone_strategy = "autodiscover"`: reuse an existing matching public hosted zone
- `route53_zone_strategy = "create"`: create and manage a public hosted zone for `environment_domain`

For production-style deployments, prefer `route53_zone_id` with `route53_zone_strategy = "explicit"`. The checked-in example tfvars files set `route53_zone_strategy = "create"` when `route53_zone_id = null` so the DNS ownership choice is deliberate.

## Runtime Tokens in Example tfvars

The `*.tfvars.example` files use a small set of `__TOKEN__` placeholders inside the `ecs_services` maps for `gateway_microservices` mode.

These tokens are resolved by `application_platform` during plan and apply when they appear in the expected `ecs_services.env` and `ecs_services.secret_arns` fields. You can keep them as-is when copying the example files into a local `terraform.tfvars`.

Only image digest placeholders such as `REPLACE_ME` still need manual replacement before deployment.

| Token | Where Used | How to Resolve |
|---|---|---|
| `__RDS_ENDPOINT__` | `SPRING_DATASOURCE_URL` env vars inside `ecs_services` | Resolved automatically to the RDS endpoint created or referenced by the root. |
| `__RDS_DB_NAME__` | `SPRING_DATASOURCE_URL` env vars inside `ecs_services` | Resolved automatically from `rds_db_name`. |
| `__RDS_MASTER_PASSWORD_SECRET_ARN__` | `SPRING_DATASOURCE_PASSWORD` secret ARN inside `ecs_services` | Resolved automatically to the managed RDS master-password secret ARN. |
| `__SMTP_HOST__` | `SPRING_MAIL_HOST` env var for `mailer-service` | Resolved automatically to the SES SMTP endpoint for the selected AWS region. |
| `REPLACE_ME` | Container image digest refs inside `ecs_services` | Replace with the full `@sha256:<64-hex>` digest from your ECR repository. |

If you are not using the built-in `ecs_services` placeholder flow, replace the tokens yourself before deployment.
