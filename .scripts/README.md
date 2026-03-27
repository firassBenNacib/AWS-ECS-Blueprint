# Script Helpers

This directory contains the repository's local operator and CI helper scripts.

## Main Entry Points

- `validate_modules.sh`
  - Validates reusable Terraform modules from an isolated temporary copy.
  - Injects mock AWS providers for modules that intentionally do not define their own provider configuration.
- `test_modules.sh`
  - Runs native `terraform test` suites across top-level reusable modules.
  - Formats test output for local readability.
- `test_roots.sh`
  - Runs native `terraform test` suites for the `prod-app` and `nonprod-app` deployment roots.
  - Exercises root-to-composition wiring and root-specific contract behavior.
- `security_scan_prod.sh`
  - Runs the local policy and scanner path used by `make scan-root` and `make scan-roots`.
  - Applies timeout and one-retry guardrails around the tfsec and Checkov gate scripts.
- `safe_destroy_app_root.sh`
  - Performs the guarded destroy flow for a deployment root.
- `init_app_root.sh`
  - Initializes a deployment root with backend-aware logic for local `plan`-style commands.
- `check_root_parity.py`
  - Verifies that `prod-app` and `nonprod-app` keep the same `module "app"` input surface.
  - Powers the root-parity check in CI and `make check-root-parity`.
- `report_terraform_tag_gaps.py`
  - Audits Terraform plan or state JSON for taggable AWS resources that currently receive no tags.
  - Keeps unsupported AWS resource types informational by default and can fail only on real missing tag values in strict mode.
  - Powers the `make tag-plan-root` and `make tag-state-root` targets.

## Plan And PR Utilities

- `terraform_target_matrix.py`
  - Resolves the canonical target matrix used by CI workflows.
- `render_terraform_pr_summary.py`
  - Builds the Terraform PR summary comment body.
- `extract_terraform_plan_counts.py`
  - Extracts add/change/destroy totals from plan output.
- `extract_infracost_summary.py`
  - Extracts compact monthly cost deltas from Infracost JSON output.

## Live Validation

- `run_live_validation.sh`
  - Applies, smoke-tests, and destroys an isolated validation environment.
- `run_live_validation_checks.sh`
  - Shared smoke-check logic used by the live validation path.
  - Verifies TLS by default; use `LIVE_VALIDATION_INSECURE_TLS=true` only when you intentionally need an insecure bootstrap smoke check.

## Documentation

- `terraform_docs_gate.sh`
  - Regenerates or verifies `terraform-docs` output for modules.
- `install_terraform_docs.sh`
  - Installs the pinned local `terraform-docs` binary for repo use.

## Notes

- These scripts are intended to be called from the `Makefile` and CI workflows, not memorized ad hoc.
- When changing script behavior, update the relevant workflow or Make target at the same time so local and CI paths stay aligned.
