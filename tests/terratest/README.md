# Terratest

The Go-based end-to-end validation layer for the blueprint lives in this directory.

## Purpose

The Terratest path is intentionally narrow:

- it reuses `.scripts/run_live_validation.sh`
- it does not invent a second deployment workflow
- it adds one more compatibility check against Terraform, provider, and AWS API drift

## Current Test

- `live_validation_test.go`
  - Runs the same isolated apply, smoke, and destroy path used by `live-validation.yml`
  - Skips automatically unless the required environment variables are present

## Required Environment Variables

- `E2E_TERRAFORM_ROOT`
- `E2E_TFVARS_FILE`
- `E2E_AWS_REGION`
- `E2E_SMOKE_PROFILE`

Optional:

- `E2E_REPO_ROOT`
- `E2E_LOG_DIR`
- `E2E_TERRATEST_RETRIES`
- `E2E_FRONTEND_ECS_TFVARS_FILE`
- `E2E_FRONTEND_ECS_SMOKE_PROFILE`
- `E2E_PUBLIC_ALB_RESTRICTED_TFVARS_FILE`
- `E2E_PUBLIC_ALB_RESTRICTED_SMOKE_PROFILE`

When the optional extra tfvars variables are present, the Terratest path also runs:

- a frontend `ecs` live-validation scenario
- a backend `public_alb_restricted` live-validation scenario

## Typical Local Command

```bash
go test ./... -run TestLiveValidationE2E -count=1 -timeout 30m -v
```

Without the required `E2E_*` variables, the test should skip rather than fail.
