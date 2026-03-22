# Architecture Constraints

## Public Entry Path

- Frontend default: `Route53 -> CloudFront (frontend) -> private S3 (OAC)`.
- Frontend optional: `Route53 -> CloudFront (frontend) -> internal ALB/VPC origin -> ECS frontend` when `frontend_runtime_mode = "ecs"`.
- Backend: `Route53 -> CloudFront (backend) -> internal ALB (VPC origin) -> ECS Fargate (private subnets) -> RDS`.

## Frontend Runtime Note

- `frontend_runtime_mode = "ecs"` changes the frontend traffic path and skips provisioning the frontend content buckets and replication path.
- Log buckets and Terraform state storage can still use S3; the ECS-only behavior applies to frontend content delivery resources.
- [`img/aws-ecs-blueprint-architecture.png`](../img/aws-ecs-blueprint-architecture.png) shows the default `s3` frontend path: `Route53 -> CloudFront (frontend) -> private S3 (OAC)`.
- [`img/aws-ecs-blueprint-architecture-frontend-ecs.png`](../img/aws-ecs-blueprint-architecture-frontend-ecs.png) shows the frontend `ecs` path: `Route53 -> CloudFront (frontend) -> internal ALB/ECS frontend`.
- The backend side stays the same across both diagrams.

## Why CloudFront Is Required For Backend

- The backend ALB is intentionally `internal = true`.
- Public API traffic reaches backend only through CloudFront.
- Removing backend CloudFront would require exposing a public ALB or redesigning the API edge.
- Origin-auth headers and ALB listener rules enforce CloudFront-to-origin request validation.

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

## Security Baseline

- CloudTrail, Config, Security Hub, Access Analyzer.
- Workload accounts keep an account-local GuardDuty detector.
- EventBridge routes high/critical GuardDuty/Security Hub findings to SNS.
- Amazon Inspector is enabled through the account-security baseline module.
- AWS Backup is owned per deployment root through the backup baseline module.

## Deployment Root Ownership Model

- `prod-app` and `nonprod-app` own runtime application resources.
- In single-account mode, exactly one deployment root should own account-level security controls for a given account/region; the checked-in path makes `prod-app` the owner and keeps `nonprod-app` on workload + per-root backup only.

## Microservice Compatibility

- Current ingress supports multi-service expansion without edge redesign.
- Keep shared `CloudFront -> internal ALB` entry path.
- Put a single public gateway ECS service behind the ALB.
- Register internal ECS services in Cloud Map and route privately from the gateway.
- Preserve per-service IAM task roles, secrets, autoscaling, health checks, and alarms.
- Switch back to `single_backend` when only one backend service is needed.
