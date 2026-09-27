# ---------------------------------------------------------------------------
# Scope and identity
#
# Nothing here hardcodes a real organization, project or billing account.
# Every identifier is a variable with an obviously fake default.
# ---------------------------------------------------------------------------

variable "deployment_scope" {
  description = "\"organization\" binds guardrails at the org and enables VPC-SC; \"single_project\" demonstrates them on one project."
  type        = string
  default     = "single_project"

  validation {
    condition     = contains(["organization", "single_project"], var.deployment_scope)
    error_message = "deployment_scope must be \"organization\" or \"single_project\"."
  }
}

variable "org_id" {
  description = "Numeric organization ID. Only used when deployment_scope is \"organization\"."
  type        = string
  default     = "123456789012"

  validation {
    condition     = can(regex("^[0-9]{6,20}$", var.org_id))
    error_message = "org_id must be the numeric organization ID, not the domain name."
  }
}

variable "project_id" {
  description = "Project that runs the generative AI workload (Vertex AI, Model Armor, the app's service account)."
  type        = string
  default     = "example-genai-project"
}

variable "region" {
  description = "Region for Vertex AI, KMS, Model Armor templates and the workload subnet."
  type        = string
  default     = "us-central1"
}

variable "guardrail_profile" {
  description = "\"standard\" or \"strict\". Drives filter sensitivity, key rotation, log retention and whether the perimeter enforces. See locals.tf."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "strict"], var.guardrail_profile)
    error_message = "guardrail_profile must be \"standard\" or \"strict\"."
  }
}

# ---------------------------------------------------------------------------
# Feature gates. Free, preventive controls default on. Anything metered or
# anything that can break traffic defaults off.
# ---------------------------------------------------------------------------

variable "enable_org_policies" {
  description = "Preventive org policy constraints (ORG-*). Free."
  type        = bool
  default     = true
}

variable "enable_identity" {
  description = "Dedicated workload service account with a predict-only custom role (IAM-*)."
  type        = bool
  default     = true
}

variable "enable_cmek" {
  description = "Cloud KMS key ring and Vertex AI key (ENC-*). Metered."
  type        = bool
  default     = false
}

variable "enable_network" {
  description = "Workload VPC with default-deny and restricted.googleapis.com routing (NET-*)."
  type        = bool
  default     = false
}

variable "enable_vpc_service_controls" {
  description = "Service perimeter around AI data services (VSC-*). Organization scope only."
  type        = bool
  default     = false
}

variable "enable_model_armor" {
  description = "Model Armor template and floor setting (MA-*). Metered per request."
  type        = bool
  default     = false
}

variable "enable_audit_logging" {
  description = "Data Access audit logs for AI services plus a retention-locked log bucket (LOG-*). Metered by volume."
  type        = bool
  default     = false
}

variable "enable_detection" {
  description = "Log-based metrics and alert policies for guardrail tampering (DET-001..003)."
  type        = bool
  default     = false
}

variable "enable_budget" {
  description = "Billing budget with alert thresholds on the AI project (DET-004). Requires billing_account_id."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Control parameters
# ---------------------------------------------------------------------------

variable "allowed_models" {
  description = <<-EOT
    Values for constraints/vertexai.allowedModels, as
    publishers/<publisher>/models/<model>:<action>, where action is predict,
    deploy or tune. Anything not listed is blocked. Allowing :predict without
    :tune is deliberate: calling an approved model is not the same approval as
    fine-tuning it on your data. Replace with your approved model list.
  EOT
  type        = list(string)
  default = [
    "publishers/google/models/gemini-3.5-flash:predict",
    "publishers/google/models/text-embedding-005:predict",
  ]
}

variable "allowed_locations" {
  description = "Values for constraints/gcp.resourceLocations (ORG-002)."
  type        = list(string)
  default     = ["in:us-locations"]
}

variable "cmek_required_services" {
  description = "Services that must use CMEK (constraints/gcp.restrictNonCmekServices deny list)."
  type        = list(string)
  default     = ["aiplatform.googleapis.com", "storage.googleapis.com", "bigquery.googleapis.com"]
}

variable "access_policy_id" {
  description = "Access Context Manager policy number. Required for VPC-SC."
  type        = string
  default     = "000000000000"
}

variable "perimeter_projects" {
  description = "Project numbers inside the AI perimeter, as \"projects/<number>\"."
  type        = list(string)
  default     = []
}

variable "restricted_services" {
  description = "APIs the perimeter protects. Data in these services cannot leave it."
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "notebooks.googleapis.com",
    "modelarmor.googleapis.com",
  ]
}

variable "subnet_cidr" {
  description = "Primary range for the workload subnet."
  type        = string
  default     = "10.40.0.0/24"
}

variable "alert_email" {
  description = "Notification channel for detection alerts and budget thresholds."
  type        = string
  default     = "security@example.com"
}

variable "billing_account_id" {
  description = "Billing account for the budget (DET-004), e.g. 000000-000000-000000."
  type        = string
  default     = "000000-000000-000000"
}

variable "monthly_budget_usd" {
  description = "Monthly spend ceiling for the AI project. Alerts at 50/90/100 percent and on forecast."
  type        = number
  default     = 500
}
