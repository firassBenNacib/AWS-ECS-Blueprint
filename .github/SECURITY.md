# Security Policy

## Reporting a Vulnerability

Do not report suspected vulnerabilities in public issues or discussions.

Use GitHub private vulnerability reporting for this repository if it is enabled. If it is not enabled, contact the repository maintainers directly before any public disclosure.

When reporting, include:

- affected paths or modules
- impact and attack preconditions
- proof-of-concept or reproduction steps
- any suggested mitigation or containment guidance

## Supported Usage

This repository is intended for production-grade AWS Terraform usage, but secure operation still depends on:

- correct account boundaries
- correct IAM role and KMS policy configuration
- secure handling of secrets and backend configuration
- validation in isolated AWS accounts before promotion

## Response Process

Maintainers may acknowledge, triage, reproduce, remediate, and coordinate disclosure on a best-effort basis.
