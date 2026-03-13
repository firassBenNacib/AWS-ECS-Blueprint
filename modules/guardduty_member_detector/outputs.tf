output "detector_id" {
  description = "GuardDuty detector ID in the member account."
  value       = aws_guardduty_detector.this.id
}
