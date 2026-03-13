# Scanner Exception Catalog

This catalog classifies current ignored/skipped controls into governance categories.

## Required Structural Exceptions

- `CKV_AWS_109`, `CKV_AWS_111`, `CKV_AWS_356` on KMS key policies:
  - KMS key policies require account-root administration and `Resource = "*"` patterns.

## Module Graph / Scanner-Limit Exceptions

- `CKV2_AWS_32` (CloudFront response headers policy attached in module behavior)
- `CKV2_AWS_47` (CloudFront WAF/Log4j controls attached in the top-level app composition)
- `CKV2_AWS_5` (Security groups attached through module outputs/composition)
- `CKV2_AWS_3` on `module.guardduty_member_detector.aws_guardduty_detector.this`
  - the member-account detector is intentionally account-local
  - the detector is not organization-managed in this platform-only repository and is intentionally scoped to the workload account

## Intentional Design Tradeoff Exceptions

- `CKV_AWS_378` (private VPC-internal HTTP target group behind CloudFront/ALB TLS termination)
- `CKV2_AWS_65` (CloudFront standard logs require ACL-compatible ownership mode)
- `CKV_AWS_18` on dedicated log sink buckets (self-logging recursion avoidance)

## Governance Rules

1. Every exception must exist in allowlists with owner, ticket, and expiry.
2. Expiry window must remain bounded (`MAX_ALLOWLIST_DAYS`).
3. Design tradeoff exceptions must be re-reviewed at each architecture milestone.
