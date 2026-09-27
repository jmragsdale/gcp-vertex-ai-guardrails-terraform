# Changelog - gcp-vertex-ai-guardrails-terraform

All notable changes to this project are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-09-27

### Added

- `terraform/modules/org-policy/` - `vertexai.allowedModels` per-action model
  allowlist, `gcp.resourceLocations`, `gcp.restrictNonCmekServices`, service
  account key creation disabled, no automatic default-SA grants, Workbench
  with no public IP and no root.
- `terraform/modules/identity/` - dedicated runtime service account with a
  predict-only custom role.
- `terraform/modules/encryption/` - regional key ring and Vertex AI key, usable
  only by the Vertex AI and Cloud Storage service agents.
- `terraform/modules/network/` - custom-mode VPC, default-deny egress and
  ingress, a single egress path to `restricted.googleapis.com`, private DNS,
  flow logs.
- `terraform/modules/vpc-sc/` - service perimeter around AI data services,
  dry-run or enforced by profile.
- `terraform/modules/model-armor/` - template (prompt injection and jailbreak,
  sensitive data, malicious URLs, RAI filters) and an inline Vertex AI floor
  setting.
- `terraform/modules/logging/` - Data Access audit logs for Vertex AI and Model
  Armor, retention-locked log bucket, routing sink.
- `terraform/modules/detection/` - alerts on Vertex AI IAM changes, model
  deployment changes and Model Armor configuration changes; billing budget.
- `guardrail_profile` (`standard` | `strict`) driving filter confidence, key
  rotation and protection level, log retention and perimeter mode.
- `controls/controls.yaml` with 29 controls mapped to OWASP LLM Top 10 (2025),
  NIST AI RMF 1.0 and NIST SP 800-53 Rev 5; `controls/render.py` generates
  `CONTROLS.md` and verifies every claimed Terraform address.
- Four Rego policy suites (org policy, Model Armor, network, audit) with 21
  unit tests.
- CI: `terraform fmt`/`validate`, tflint, Checkov, Trivy, Conftest, gitleaks and
  control-matrix integrity.
- `examples/single-project/` and `examples/org-wide/`.
