# Deployment Root Entry Points

This repository keeps two deployment roots in scope:

- `prod-app`: production application runtime deployment root
- `nonprod-app`: non-production application runtime deployment root

Each deployment root includes:
- `backend.hcl.example` with a unique state-key pattern
- `terraform.tfvars.example` for `single_backend` mode
- `terraform.microservices.tfvars.example` for `gateway_microservices` mode
- a deployment-root `README.md`

The public repository path is intentionally platform-only. Multi-account bootstrap roots are not part of the supported surface in this repo.
