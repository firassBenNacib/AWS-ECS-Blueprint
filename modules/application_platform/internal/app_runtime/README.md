<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0, < 2.0.0 |
| aws | >= 6.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| ecr_backend | ../../../ecr | n/a |
| ecs_backend | ../../../ecs_backend | n/a |
| ecs_service | ../../../ecs_service | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.microservices_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.microservices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_service_discovery_private_dns_namespace.microservices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.microservices](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| edge | Resolved backend edge outputs consumed by runtime services. | `any` | n/a | yes |
| environment | Normalized environment naming inputs for runtime resources. | <pre>object({<br/>    name          = string<br/>    enable_suffix = bool<br/>  })</pre> | n/a | yes |
| microservices | Resolved gateway-microservices ECS inputs. | `any` | n/a | yes |
| networking | Resolved security-group outputs from the networking wrapper. | `any` | n/a | yes |
| runtime | Resolved shared runtime inputs. | `any` | n/a | yes |
| single_backend | Resolved single-backend ECS inputs. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| backend_ecr_repository_name | n/a |
| backend_ecr_repository_url | n/a |
| backend_ecs_cluster_name | n/a |
| backend_ecs_service_name | n/a |
| backend_ecs_task_definition_arn | n/a |
| ecs_service_names | n/a |
| public_service_name | n/a |
| service_discovery_namespace_name | n/a |
<!-- END_TF_DOCS -->