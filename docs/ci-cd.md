# CI/CD Workflows

This repository uses a focused workflow layout: smaller, purpose-specific workflow files under `.github/workflows/`, backed by shared composite actions in `.github/actions/`.

- `actionlint.yml`
  - Lints workflow YAML and local composite actions.
  - Uses the shared `.github/actions/actionlint` composite action.
- `dependency-review.yml`
  - Reviews supply-chain changes on pull requests and pushes to `main`.
  - Uses GitHub's dependency review action with a `critical` severity failure threshold.
- `ci-terraform.yml`
  - Runs on pull requests and pushes for Terraform/CI paths.
  - Enforces `terraform fmt`, `terraform validate`, `tflint`, `gitleaks`, Checkov, Trivy config, and optional tfsec/Terrascan scans.
  - Keeps tfsec enabled by default because the repo already has allowlist governance around it.
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
  - Uploads plan text artifacts and updates a single sticky PR comment.
  - Does not create saved plan files for later apply.
- `deploy.yml`
  - Runs on pushes to `main` and `workflow_dispatch`.
  - Builds saved plan artifacts (`tfplan`, rendered plan text, plan JSON, checksum).
  - Runs advisory Trivy scans against saved plan JSON before upload.
  - Prefers real target tfvars materialized from `TFVARS_PROD_APP` / `TFVARS_NONPROD_APP` GitHub secrets when those are configured.
  - Applies the exact saved plan only after GitHub Environment approval.
- `destroy.yml`
  - Runs on `workflow_dispatch` only.
  - Requires an exact typed confirmation string before any AWS credentials are used.
  - Prefers real target tfvars materialized from `TFVARS_PROD_APP` / `TFVARS_NONPROD_APP` GitHub secrets when those are configured.
  - Initializes the shared backend, summarizes managed state, and then runs the guarded destroy helper.
  - Uses separate destroy environments so approval rules for destructive actions can be stricter than apply rules.
- `live-validation.yml`
  - Runs nightly for scheduled validation targets and on demand for selected deployment roots.
  - Uses isolated local Terraform state, performs real AWS apply/smoke/destroy cycles, and uploads validation logs.
  - Expects dedicated live-validation tfvars secrets for each enabled target.
  - Keep a target disabled until it has dedicated validation-only DNS and ACM certificates; do not point live validation at the exact hostnames used by a live environment.
  - The repository currently keeps both app roots disabled for live validation because there are no dedicated validation-only DNS names and ACM certificates configured yet.

## Shared Actions

- `.github/actions/setup-terraform`
  - Installs Terraform and enables the shared provider plugin cache used across CI and deploy jobs.
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
  - Default when unset: enabled
- `ENABLE_TERRASCAN`
  - Default when unset: disabled

Backend configuration for saved-plan workflows:

- `TF_BACKEND_BUCKET`
- `TF_BACKEND_REGION`

The deploy and PR-plan workflows default to `TF_BACKEND_BUCKET` plus the target-specific backend key in `ci/terraform-targets.json`. `workflow_dispatch` can still override that with an explicit backend config path when needed. Live validation does not use the shared backend because it validates against isolated local state and destroys in the same job.

## Secrets

Role secrets used by plan/apply workflows:

- `AWS_ROLE_ARN_PROD_APP`
- `AWS_ROLE_ARN_NONPROD_APP`
- `TFVARS_PROD_APP`
- `TFVARS_NONPROD_APP`

Live-validation tfvars secrets:

- `LIVE_VALIDATION_TFVARS_PROD_APP`
- `LIVE_VALIDATION_TFVARS_NONPROD_APP`

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
- Deploy workflow plans are non-speculative saved plan files.
- Apply always consumes the saved plan artifact created earlier in the same workflow.

## Target Catalog

`ci/terraform-targets.json` is the single source of truth for:

- target path
- default tfvars path
- backend key/default backend config path
- AWS role secret mapping
- deploy environment name
- live-validation eligibility and smoke profile

Do not hardcode new Terraform targets directly into workflow YAML.
