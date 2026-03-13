# guardduty_member_detector

Account-local GuardDuty detector for workload and single-account deployment roots.

## Documentation

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_guardduty_detector.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| detector_id | GuardDuty detector ID in the member account. |
<!-- END_TF_DOCS -->
