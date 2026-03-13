# Contributing

## Before You Open a Pull Request

- Read the root [README](../README.md) and the relevant document under [`docs/`](../docs).
- Keep changes scoped. Avoid mixing structural refactors with unrelated feature work.
- Do not commit live credentials, `backend.hcl`, generated `*.tfvars`, or state artifacts.

## Repository Layout

- Reusable modules live under [`modules/`](../modules).
- Primary workload deployment roots live at the repository top level:
  - [`prod-app`](../prod-app)
  - [`nonprod-app`](../nonprod-app)
- Helper tooling for the main app-platform path lives under [`.scripts/`](../.scripts).
- Long-form design and runbook material for the main path lives under [`docs/`](../docs).

## Local Checks

Run the same checks maintainers expect in review:

```bash
make fmt-check
make validate
make docs-check
```

Optional local guardrails:

```bash
pre-commit install
pre-commit run --all-files
```

For security-oriented local checks:

```bash
make scan-targets
```

## Terraform Conventions

- Keep modules reusable and provider-agnostic except where aliases are explicitly required.
- Declare provider requirements inside each reusable module.
- Prefer small, focused files grouped by concern over one large entrypoint when editing existing Terraform.
- Keep variable descriptions and outputs accurate. Module documentation is generated from source.
- When you change module inputs, outputs, or resources, regenerate docs with `make docs`.

## Pull Request Expectations

- Explain the operational impact of the change.
- Call out any state migration, import, or rollout ordering concerns.
- Include validation steps and results.
- Update docs when behavior, layout, or operator workflow changes.
- Use the pull request template under [`PULL_REQUEST_TEMPLATE/`](./PULL_REQUEST_TEMPLATE).
