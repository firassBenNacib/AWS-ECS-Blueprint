# Live Validation Bootstrap

Validation-only prerequisites for `prod-app` and `nonprod-app` live here.

## What It Creates

- validation-only ACM certificates
  - frontend certificates in `us-east-1`
  - ALB certificates in the workload region
- origin-auth SSM parameters

## What It Does Not Create

- the application workload itself
- the normal production or non-production deployment roots

Those still come from `prod-app/` and `nonprod-app/`.

## When To Use It

Apply this root before enabling:

- `LIVE_VALIDATION_TFVARS_PROD_APP`
- `LIVE_VALIDATION_TFVARS_NONPROD_APP`

in GitHub Actions.

## Inputs

Start from `terraform.tfvars.example` and provide:

- `project_name`
- `environment_domain`
- `route53_zone_id`
- validation DNS labels for prod and nonprod

## Outputs

Use the resulting certificate ARNs and SSM parameter names to build the live-validation tfvars secrets consumed by the CI workflows.
