<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app_data | n/a | <pre>object({<br/>    address                = string<br/>    master_user_secret_arn = string<br/>  })</pre> | n/a | yes |
| backend | n/a | <pre>object({<br/>    backend_env                     = map(string)<br/>    backend_secret_arns             = map(string)<br/>    backend_rds_secret_env_var_name = string<br/>    backend_container_image         = string<br/>    allowed_image_registries_final  = list(string)<br/>    microservice_allowed_registries = list(string)<br/>  })</pre> | n/a | yes |
| ecs_services | n/a | `map(any)` | n/a | yes |
| runtime | n/a | <pre>object({<br/>    runtime_mode_is_micro = bool<br/>    project_name          = string<br/>    environment_name      = string<br/>    aws_region            = string<br/>    rds_db_name           = string<br/>    rds_username          = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| backend_env_final | n/a |
| backend_secret_arns_final | n/a |
| ecs_services_final | n/a |
| microservice_image_repositories | n/a |
| public_service_health_check_path | n/a |
| public_service_key | n/a |
| public_service_keys | n/a |
| public_service_port | n/a |
<!-- END_TF_DOCS -->