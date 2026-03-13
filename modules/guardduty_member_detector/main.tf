resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3: This detector is intentionally account-local for the platform-only workload repository.
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
