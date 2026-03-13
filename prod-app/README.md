# Prod App Deployment Root

This is the primary production deployment root for the public ECS/Fargate app-platform path.

Supported runtime modes:
- `single_backend`: one ECS backend service behind the private ALB
- `gateway_microservices`: `CloudFront -> internal ALB -> gateway ECS service -> internal ECS services`

It also works in single-account mode by leaving the role and account contract inputs unset.

## Usage

```bash
cd prod-app
cp backend.hcl.example backend.hcl
cp terraform.microservices.tfvars.example terraform.tfvars
terraform init -reconfigure -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Use `terraform.tfvars.example` instead when you want the simpler `single_backend` mode.

This deployment root only supports the default Terraform workspace.
