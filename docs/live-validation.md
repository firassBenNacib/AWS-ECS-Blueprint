# Live Validation

Two live validation paths are included in this repository:

- `live-validation.yml`: Terraform apply, smoke test, and destroy using the repository shell helpers
- `terratest-live-validation.yml`: the same isolated flow wrapped by Go-based Terratest

Use them to catch AWS API drift, provider regressions, DNS/certificate mistakes, and end-to-end topology issues that `terraform validate`, scanners, and native module tests cannot prove on their own.

## What Live Validation Does

Each live validation run:

1. materializes a dedicated tfvars payload for the selected root
2. forces `live_validation_mode=true`
3. deploys into an isolated local Terraform state
4. verifies CloudFront, Route53, and ACM wiring for the generated validation aliases
5. runs smoke checks for the target profile
6. destroys the environment in the same run

The live validation environment uses a stable DNS label such as `lv-prod` or `lv-nonprod`, but an isolated Terraform workspace/state for each run.

## Prerequisites

Before enabling scheduled or manual live validation for a root, you need:

- a dedicated validation-only DNS label for that root
- validation-only ACM certificates covering those aliases
- origin-auth SSM parameters if the selected ingress mode uses them
- a complete `LIVE_VALIDATION_TFVARS_<ROOT>` GitHub secret
- optional extra tfvars secrets if you want Terratest to exercise the frontend `ecs` and `public_alb_restricted` variants too
- a target entry marked live-validation-eligible in [`ci/terraform-targets.json`](../ci/terraform-targets.json)

Do not point live validation at the exact public hostnames used by a live production or shared non-production environment.

## Bootstrap Root

Use [`live-validation-bootstrap/`](../live-validation-bootstrap) to provision the validation-only ACM certificates and origin-auth parameters before enabling the GitHub secrets.

That bootstrap root is intentionally separate from the workload roots:

- it prepares prerequisites only
- it does not deploy the application workload

## Secrets And Workflow Inputs

The main secrets are documented in [`docs/ci-cd.md`](./ci-cd.md), but the important split is:

- `TFVARS_PROD_APP` / `TFVARS_NONPROD_APP`: normal plan/apply workflows
- `LIVE_VALIDATION_TFVARS_PROD_APP` / `LIVE_VALIDATION_TFVARS_NONPROD_APP`: isolated live validation workflows
- `LIVE_VALIDATION_TFVARS_FRONTEND_ECS_*` / `LIVE_VALIDATION_TFVARS_PUBLIC_ALB_RESTRICTED_*`: optional Terratest-only scenario coverage for the alternate frontend and backend ingress paths

Keep the live-validation tfvars values separate from the normal root tfvars so validation-only DNS names and certificates never bleed into standard deploys.

## Recommended Operating Mode

- `prod-app`: manual-only until you intentionally maintain validation-only DNS/certificates and accept the temporary cost
- `nonprod-app`: manual first, then scheduled once the validation prerequisites are stable and routinely maintained

Run Terratest in parallel with the shell-based live validation flow when you want one more layer of end-to-end confidence against Terraform/provider/API drift.

## Cost Expectations

Live validation is not free. The main temporary cost drivers are:

- CloudFront distributions
- ALB
- ECS tasks
- NAT egress when enabled
- RDS
- baseline controls enabled by the chosen root profile

For that reason, the repository keeps the production path manual-only and treats non-production scheduling as an intentional operator choice.

## Failure Triage

If a live validation run fails:

1. check the uploaded workflow artifacts first
2. confirm the live-validation tfvars secret still matches the validation DNS/certificate setup
3. verify Route53 aliases and ACM SAN coverage for the validation label
4. rerun manually before changing the normal workload roots

When the failure is only in Terratest but not in `live-validation.yml`, treat it as a signal to inspect the Terratest wrapper or timing assumptions before changing Terraform resources.

The smoke-check helper verifies TLS certificates by default. Only set `LIVE_VALIDATION_INSECURE_TLS=true` when you intentionally need an early bootstrap run to skip certificate verification.
