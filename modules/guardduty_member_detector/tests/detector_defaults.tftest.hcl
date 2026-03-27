mock_provider "aws" {}

run "detector_enabled_with_fifteen_minute_publishing" {
  command = plan

  assert {
    condition     = aws_guardduty_detector.this.enable == true
    error_message = "GuardDuty detector should be enabled."
  }

  assert {
    condition     = aws_guardduty_detector.this.finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "GuardDuty detector should publish findings every fifteen minutes."
  }
}
