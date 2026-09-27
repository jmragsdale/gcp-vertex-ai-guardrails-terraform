variable "project_id" {
  description = "Workload project."
  type        = string
}

variable "retention_days" {
  description = "Log bucket retention, from the guardrail profile."
  type        = number
}

variable "lock_retention" {
  description = "Lock retention so nobody, including project owners, can shorten it."
  type        = bool
}

locals {
  ai_services = ["aiplatform.googleapis.com", "modelarmor.googleapis.com"]
}

# LOG-001  Data Access audit logs for the AI services. Admin Activity is always
# on; DATA_READ and DATA_WRITE are not, and they are the records that show who
# invoked which model and who read which dataset. Without them, "what did the
# compromised account do with the model?" has no answer.
resource "google_project_iam_audit_config" "ai" {
  for_each = toset(local.ai_services)

  project = var.project_id
  service = each.key

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# LOG-002  Retention-locked bucket for AI audit records.
resource "google_logging_project_bucket_config" "ai_audit" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "genai-audit"
  retention_days = var.retention_days
  locked         = var.lock_retention
  description    = "Audit records for AI services. Retention locked; see guardrail_profile."
}

# LOG-003  Route every AI-service audit record, plus Model Armor findings,
# into that bucket.
resource "google_logging_project_sink" "ai_audit" {
  project                = var.project_id
  name                   = "genai-audit"
  destination            = "logging.googleapis.com/${google_logging_project_bucket_config.ai_audit.id}"
  unique_writer_identity = true
  filter                 = "protoPayload.serviceName=(\"aiplatform.googleapis.com\" OR \"modelarmor.googleapis.com\") OR resource.type=\"modelarmor.googleapis.com/SanitizeOperation\""
}
