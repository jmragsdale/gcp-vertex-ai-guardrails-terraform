terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

# ===========================================================================
# Single-project posture
#
# For evaluating this repo without an organization. Org policies bind to the
# project, the Model Armor floor binds to the project, and VPC Service Controls
# are skipped because a perimeter needs an org-level access policy.
#
#   survives  model allowlist, residency, CMEK, key policy, the workload VPC
#             with default-deny egress, Model Armor template and floor, audit
#             logging, guardrail-tampering alerts
#   lost      inheritance (a project-bound constraint protects one project,
#             not the next one someone creates) and the data perimeter
#
# WARNING: enable_audit_logging creates a retention-LOCKED log bucket. Locked
# retention cannot be shortened or deleted, by anyone, until it expires. Leave
# it false in a scratch project.
# ===========================================================================

module "genai_guardrails" {
  source = "../../terraform"

  deployment_scope  = "single_project"
  project_id        = "example-genai-project"
  region            = "us-central1"
  guardrail_profile = "standard"

  enable_org_policies  = true
  enable_identity      = true
  enable_cmek          = true
  enable_network       = true
  enable_model_armor   = true
  enable_detection     = true
  enable_audit_logging = false # see warning above

  alert_email = "security@example.com"
}

output "workload_service_account" {
  description = "Run the application as this identity."
  value       = module.genai_guardrails.workload_service_account
}

output "guardrail_profile" {
  description = "What the selected profile resolved to."
  value       = module.genai_guardrails.guardrail_profile
}
