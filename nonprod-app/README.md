# Non-Prod App Deployment Root

Primary non-production deployment root for the public ECS/Fargate app-platform path.

Supported runtime modes:
- `single_backend`: one ECS backend service behind the private ALB
- `gateway_microservices`: `CloudFront -> internal ALB -> gateway ECS service -> internal ECS services`

It also works in single-account mode by leaving the optional role and account inputs unset.

## Usage

```bash
cd nonprod-app
cp backend.hcl.example backend.hcl
cp terraform.microservices.tfvars.example terraform.tfvars
terraform init -reconfigure -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Use `terraform.tfvars.example` instead when you want the simpler `single_backend` mode.

Only the default Terraform workspace is supported in this deployment root.
