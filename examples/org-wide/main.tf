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
# Organization posture, strict profile
#
# Guardrails bind at the organization and are inherited by every project,
# including the ones created next quarter by a team that has never read this
# repo. That inheritance is most of the value.
#
# Apply in stages. See README.md in this directory for the order.
# ===========================================================================

module "genai_guardrails" {
  source = "../../terraform"

  deployment_scope  = "organization"
  org_id            = "123456789012"
  project_id        = "example-genai-project"
  region            = "us-central1"
  guardrail_profile = "strict"

  allowed_models = [
    "publishers/google/models/gemini-3.5-flash:predict",
    "publishers/google/models/text-embedding-005:predict",
  ]

  enable_org_policies         = true
  enable_identity             = true
  enable_cmek                 = true
  enable_network              = true
  enable_vpc_service_controls = true
  enable_model_armor          = true
  enable_audit_logging        = true
  enable_detection            = true
  enable_budget               = true

  access_policy_id   = "000000000000"
  billing_account_id = "000000-000000-000000"
  monthly_budget_usd = 2000
  alert_email        = "security@example.com"
}

output "perimeter_mode" {
  description = "dry_run or enforced."
  value       = module.genai_guardrails.perimeter_mode
}
