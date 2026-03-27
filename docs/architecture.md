# Architecture Constraints

The repository is designed as a production-ready blueprint for supported workload classes, not as a universal blueprint for every workload shape or protocol.

## Public Entry Path

- Frontend default: `Route53 -> CloudFront (frontend) -> private S3 (OAC)`.
- Frontend optional: `Route53 -> CloudFront (frontend) -> internal ALB/VPC origin -> ECS frontend` when `frontend_runtime_mode = "ecs"`.
- Backend default: `Route53 -> CloudFront (frontend ordered path behaviors) -> internal ALB (VPC origin) -> ECS Fargate (private subnets) -> RDS`.
- Backend alternate: `Route53 -> CloudFront (frontend ordered path behaviors) -> public ALB restricted to CloudFront origin-facing infrastructure -> ECS Fargate (private subnets) -> RDS` when `backend_ingress_mode = "public_alb_restricted"`.

## Frontend Runtime Note

- `frontend_runtime_mode = "ecs"` changes the frontend traffic path and skips provisioning the frontend content buckets and replication path.
- Log buckets and Terraform state storage can still use S3; the ECS-only behavior applies to frontend content delivery resources.
- [`img/aws-ecs-blueprint-architecture.png`](../img/aws-ecs-blueprint-architecture.png) shows the default `s3` frontend path: `Route53 -> CloudFront (frontend) -> private S3 (OAC)`.
- [`img/aws-ecs-blueprint-architecture-frontend-ecs.png`](../img/aws-ecs-blueprint-architecture-frontend-ecs.png) shows the frontend `ecs` path: `Route53 -> CloudFront (frontend) -> internal ALB/ECS frontend`.
- [`img/aws-ecs-blueprint-architecture-public-alb-restricted.png`](../img/aws-ecs-blueprint-architecture-public-alb-restricted.png) shows the alternate backend ingress path: `Route53 -> CloudFront (frontend ordered backend paths) -> public restricted ALB -> ECS backend`.
- The backend side stays the same across the first two frontend-runtime diagrams.

## Backend Ingress Modes

- `vpc_origin_alb` is the default. The backend ALB is intentionally `internal = true`, and backend/API traffic reaches it only through CloudFront VPC origins.
- `public_alb_restricted` is the alternate mode. The ALB becomes internet-facing in public edge subnets, but ALB ingress is still restricted to CloudFront origin-facing infrastructure and origin-auth headers remain enabled.
- The checked-in roots use a frontend distribution with ordered backend path behaviors. A dedicated backend CloudFront module exists for custom consumers, but it is not the default root topology.

## Domain And Front-Door Strategy

- Default root topology: one frontend CloudFront distribution is the primary public front door.
- In that default topology, ordered cache behaviors forward backend/API paths to the backend origin while frontend paths continue to use the configured frontend origin.
- This is the recommended pattern when you want one hostname strategy and one edge entry point for both web and API traffic.
- The reusable `modules/cloudfront_backend` module exists for consumers that want a separate API subdomain and a dedicated backend distribution lifecycle. This module is intentionally **not instantiated** by the checked-in deployment roots (`prod-app`, `nonprod-app`); it is provided as an opt-in building block for custom consumers.
- Treat those as two supported edge patterns:
  - single-domain path routing through the frontend distribution
  - separate API hostname through a dedicated backend distribution

## Support Boundaries

- Supported default workload class: HTTP/HTTPS private-origin ECS web workloads.
- Supported alternate workload class: workloads that still fit CloudFront + ALB, but need `public_alb_restricted` instead of a private CloudFront VPC origin.
- CloudFront VPC-origin capabilities should be checked against your workload requirements, especially for WebSockets, gRPC, and other advanced origin features.
- `public_alb_restricted` broadens compatibility, but some workloads may still need a different ingress design. In those cases, extend or adapt the blueprint rather than assuming the default ingress modes cover every pattern.
- When AWS creates `CloudFront-VPCOrigins-Service-SG`, treat it as service-managed and do not edit it manually.

## Runtime Scope

- Single runtime model: ECS Fargate only.
- No EC2/ASG backend runtime path in this repository.
- Runtime modes:
  - `single_backend`: one ECS backend service behind the ALB
  - `gateway_microservices`: one public ECS gateway service behind the ALB plus private internal ECS services registered in Cloud Map

## Egress Model

- Private app subnets are endpoint-first (`ecr.api`, `ecr.dkr`, `logs`, `sts`, `secretsmanager`, `kms`, plus S3 gateway endpoint).
- Microservice services can declare narrowly-scoped outbound internet exceptions when external SMTP or HTTPS integrations are required.
- NAT mode rollout is staged: `required -> canary -> disabled`.
- `enable_cost_optimized_dev_tier = true` forces the effective private-app NAT mode to `disabled` so a dev stack can run endpoint-first with zero NAT gateways.

## Cost Drivers

- Main recurring cost drivers are CloudFront + WAF, NAT egress, Multi-AZ RDS, log buckets, replication, and account security baseline services.
- Enabling frontend `ecs`, DR replication, and account-level security controls materially increases the monthly baseline compared with a minimal single-backend deployment.
- The cheapest supported dev footprint is `enable_cost_optimized_dev_tier = true`, which disables NAT, disables managed WAF and per-root AWS Backup, disables account-level security controls in that root, makes the workload RDS instance single-AZ, and clamps ECS service counts to `1/1/1`.
- Because that cheap-dev profile removes NAT, private-subnet services that depend on external SMTP or HTTPS integrations still need either NAT re-enabled or a separate dev-only public-placement pattern.
- Production still requires managed WAF or explicit ALB/CloudFront web ACL ARNs. Non-production roots may disable WAF explicitly when you accept the lower protection level.

## Security Baseline

- CloudTrail, Config, Security Hub, Access Analyzer.
- Workload accounts keep an account-local GuardDuty detector.
- EventBridge routes high/critical GuardDuty/Security Hub findings to SNS.
- EventBridge can also route ECS Exec `ExecuteCommand` API calls to the same security notifications path when `enable_ecs_exec_audit_alerts = true`.
- Amazon Inspector is enabled through the account-security baseline module.
- AWS Backup is owned per deployment root through the backup baseline module, but the cost-optimized dev tier forces it off for that root.
- The workload RDS master-user secret can be rotated automatically through an AWS-hosted Secrets Manager rotation Lambda in private app subnets.

## Deployment Root Ownership Model

- `prod-app` and `nonprod-app` own runtime application resources.
- In single-account mode, exactly one deployment root should own account-level security controls for a given account/region; the checked-in path makes `prod-app` the owner, while the checked-in `nonprod-app` root uses a low-cost single-NAT profile and stays workload-only with per-root AWS Backup disabled.

## Microservice Compatibility

- Current ingress supports multi-service expansion without edge redesign.
- Keep shared `CloudFront -> internal ALB` entry path.
- Put a single public gateway ECS service behind the ALB.
- Register internal ECS services in Cloud Map and route privately from the gateway.
- Preserve per-service IAM task roles, secrets, autoscaling, health checks, and alarms.
- Switch back to `single_backend` when only one backend service is needed.
