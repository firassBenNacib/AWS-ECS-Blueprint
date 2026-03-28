# CI/CD Workflows

The repository uses a focused workflow layout: smaller, purpose-specific workflow files under `.github/workflows/`, backed by shared composite actions in `.github/actions/`.

- `actionlint.yml`
  - Lints workflow YAML and local composite actions.
  - Uses the shared `.github/actions/actionlint` composite action.
- `dependency-review.yml`
  - Reviews supply-chain changes on pull requests and pushes to `main`.
  - Uses GitHub's dependency review action with a `critical` severity failure threshold.
- `ci-terraform.yml`
  - Runs on pull requests and pushes for Terraform/CI paths.
  - Enforces `terraform fmt`, root parity checks, hardened `terraform validate`, native `terraform test` for reusable modules and deployment roots, root plan-based tag coverage reports, `tflint`, `gitleaks`, Checkov, Trivy config, and optional tfsec/Terrascan scans.
  - Reuses the same retry/timeout-aware local wrappers for validate and test that the Make targets use.
  - Fails the tag coverage gate only when taggable AWS resources are missing tag values; resource types that do not expose tag fields remain informational in the uploaded report artifacts.
  - Treats Trivy config as the primary config scanner and keeps tfsec as an opt-in compatibility gate for teams that still want the older allowlist path.
  - Keeps Terrascan disabled by default until explicitly enabled.
- `terraform-docs.yml`
  - Verifies `terraform-docs` output drift for reusable modules under `modules/`.
  - Stays separate from the main CI workflow so module documentation drift is easy to spot.
- `allowlist-expiry.yml`
  - Runs on a weekly schedule and on demand.
  - Warns when scanner allowlist entries are close to expiry.
- `pr-plan.yml`
  - Runs speculative plans on same-repo pull requests only.
  - Resolves changed Terraform targets from `ci/terraform-targets.json`.
  - Uploads sanitized plan/result/cost artifacts and updates a single sticky PR comment.
  - Generates Infracost monthly cost estimates from Terraform plan JSON when `INFRACOST_API_KEY` is configured.
  - Uses backend locking with a 5-minute timeout so speculative plan jobs do not bypass S3 lockfile safety.
  - Does not upload raw secret-backed plan text artifacts.
- `deploy.yml`
  - Runs on `workflow_dispatch` only.
  - Builds a deployment plan for review and approval.
  - Uploads only sanitized deployment summaries/result artifacts; it does not upload raw deploy `tfplan` binaries or full plan JSON.
  - The protected apply job regenerates a saved plan after environment approval and applies that in the same job.
  - Prefers real target tfvars materialized from `TFVARS_PROD_APP` / `TFVARS_NONPROD_APP` GitHub secrets when those are configured.
  - Applies only after GitHub Environment approval when `apply_after_plan=true`.
- `drift-detection.yml`
  - Runs weekly and on demand.
  - Reuses the normal root backend and tfvars wiring to detect live-state drift without applying changes.
  - Uses backend locking with a 5-minute timeout so drift checks do not race against concurrent apply jobs.
  - Fails when Terraform returns a detailed-exitcode drift plan and uploads the drift plan artifact for review.
- `destroy.yml`
  - Runs on `workflow_dispatch` only.
  - Requires a confirmation string matching `destroy <target>` after whitespace normalization before any AWS credentials are used.
  - Prefers real target tfvars materialized from `TFVARS_PROD_APP` / `TFVARS_NONPROD_APP` GitHub secrets when those are configured.
  - Initializes the shared backend, summarizes managed state, and then runs the guarded destroy helper.
  - Uses separate destroy environments so approval rules for destructive actions can be stricter than apply rules.
- `live-validation.yml`
  - Runs nightly for scheduled validation targets and on demand for selected deployment roots.
  - Uses isolated local Terraform state, performs real AWS apply/smoke/destroy cycles, and uploads validation logs.
  - Forces `live_validation_mode=true`, so the roots must use an isolated `lv-*` environment name instead of the normal `prod` / `nonprod` override.
  - Uses a stable validation DNS label per root so the isolated Terraform workspace does not force a brand-new public hostname every run.
  - Expects dedicated live-validation tfvars secrets for each enabled target.
  - Verifies CloudFront deployment state, Route53 alias records, and ACM certificate coverage for the generated frontend aliases before the app-profile smoke checks succeed.
  - Keep a target disabled until it has dedicated validation-only DNS and ACM certificates; do not point live validation at the exact hostnames used by a live environment.
  - `prod-app` is intended for manual-only validation once its validation-only DNS/cert/secret prerequisites exist.
  - `nonprod-app` is intended for manual and scheduled validation once its validation-only DNS/cert/secret prerequisites exist.
- `terratest-live-validation.yml`
  - Runs weekly for scheduled validation targets and on demand for selected deployment roots.
  - Uses Go-based [Terratest](https://terratest.gruntwork.io/) to execute the same isolated apply/smoke/destroy path that `live-validation.yml` runs through `.scripts/run_live_validation.sh`.
  - Supports the default app profile and optional extra scenario tfvars for `frontend_runtime_mode = "ecs"` and `backend_ingress_mode = "public_alb_restricted"` when those secrets are configured.
  - Uploads the Terratest log bundle for the target root and is intended as an extra end-to-end compatibility check against Terraform/provider/AWS API drift.

See [`docs/live-validation.md`](./live-validation.md) for the operator checklist, cost expectations, bootstrap flow, and troubleshooting path.

## Shared Actions

- `.github/actions/setup-terraform`
  - Installs the pinned Terraform CLI version and enables the shared provider plugin cache used across CI and deploy jobs.
- `.github/actions/configure-aws-credentials`
  - Resolves the target-specific AWS role secret and assumes it with GitHub OIDC.
- `.github/actions/actionlint`
  - Installs and runs `actionlint` with repository-local configuration.

## Repo Variables

Scanner toggles:

- `ENABLE_CHECKOV`
  - Default when unset: enabled
- `ENABLE_TRIVY`
  - Default when unset: enabled
- `ENABLE_TRIVY_PLAN`
  - Default when unset: enabled
- `ENABLE_TFSEC`
  - Default when unset: disabled
  - Set it to `true` when you want the legacy tfsec compatibility gate in addition to Trivy
- `ENABLE_TERRASCAN`
  - Default when unset: disabled

Backend configuration for saved-plan workflows:

- `TF_BACKEND_BUCKET`
- `TF_BACKEND_REGION`

The deploy and PR-plan workflows default to `TF_BACKEND_BUCKET` plus the target-specific backend key in `ci/terraform-targets.json`. Deploy `workflow_dispatch` can still override that with an explicit backend config path when needed. Live validation does not use the shared backend because it validates against isolated local state and destroys in the same job.

## Secrets

Required repo secrets for the standard plan/apply/destroy workflows:

- `AWS_ROLE_ARN_PROD_APP`
- `AWS_ROLE_ARN_NONPROD_APP`
- `TFVARS_PROD_APP`
- `TFVARS_NONPROD_APP`

Optional repo secrets:

- `INFRACOST_API_KEY` for pull-request cost estimates only

The checked-in [`infracost.yml`](../infracost.yml) is for local `infracost breakdown` usage only. The pull-request workflow intentionally uses speculative plan JSON plus repo-secret tfvars so the PR cost comment matches the actual target inputs more closely.

Live-validation tfvars secrets:

- `LIVE_VALIDATION_TFVARS_PROD_APP`
- `LIVE_VALIDATION_TFVARS_NONPROD_APP`
- `LIVE_VALIDATION_TFVARS_FRONTEND_ECS_PROD_APP`
- `LIVE_VALIDATION_TFVARS_FRONTEND_ECS_NONPROD_APP`
- `LIVE_VALIDATION_TFVARS_PUBLIC_ALB_RESTRICTED_PROD_APP`
- `LIVE_VALIDATION_TFVARS_PUBLIC_ALB_RESTRICTED_NONPROD_APP`

Live validation also needs validation-only DNS names and matching ACM certificates baked into those tfvars values. Those tfvars now set a stable `live_validation_dns_label` such as `lv-prod` or `lv-nonprod`, while the Terraform workspace remains unique per run for safe state isolation.

Environment-scoped secrets and variables are optional with the current workflow layout. The checked-in workflows read the repo-level values above by default, while GitHub environments still provide approval gates and a place to move secrets later if you want stricter separation.

## Validation Bootstrap

- `live-validation-bootstrap/`
  - Dedicated helper root for provisioning validation-only ACM certificates and origin-auth SSM parameters.
  - Intended to be applied before enabling `LIVE_VALIDATION_TFVARS_*` secrets in GitHub.
  - Emits the exact certificate ARNs and parameter names needed to build those secrets.
  - Does not create the workload itself; the workload still comes from the normal `prod-app` / `nonprod-app` roots during `live-validation.yml`.

## GitHub Environments

Protected apply jobs use these environment names:

- `prod-app`
- `nonprod-app`

Protected destroy jobs should use these environment names:

- `prod-app-destroy`
- `nonprod-app-destroy`

Configure required reviewers on all of those environments to gate applies and destroys.

## Saved Plans vs PR Plans

- Pull request plans are speculative and are used only for review feedback.
- Deploy workflow plans are non-speculative but their uploaded artifacts are sanitized summaries, not raw full-plan artifacts.
- Apply regenerates a saved plan in the protected job after environment approval and applies it there.

## Target Catalog

`ci/terraform-targets.json` is the single source of truth for:

- target path
- default tfvars path
- backend key/default backend config path
- AWS role secret mapping
- deploy environment name
- live-validation eligibility and smoke profile

That catalog structure is already suitable for a multi-account operating model where `prod-app` and `nonprod-app` assume different roles into different AWS accounts.

Do not hardcode new Terraform targets directly into workflow YAML.
