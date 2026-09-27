variable "access_policy_id" {
  description = "Access Context Manager policy number."
  type        = string
}

variable "projects" {
  description = "Perimeter members as \"projects/<number>\"."
  type        = list(string)
}

variable "restricted_services" {
  description = "APIs the perimeter protects."
  type        = list(string)
}

variable "dry_run" {
  description = "true observes and logs violations; false blocks them."
  type        = bool
}

# VSC-001  Service perimeter around AI data. Training data, embeddings, tuned
# models and prompt logs in these services cannot be copied to a project
# outside the perimeter, even by a principal with valid credentials. This is
# the control that turns a stolen token into a failed request.
#
# Dry-run vs enforced is profile-driven. Both shapes are written out in full
# rather than toggled inside one block, so the plan shows exactly which one
# is live.
resource "google_access_context_manager_service_perimeter" "genai" {
  parent         = "accessPolicies/${var.access_policy_id}"
  name           = "accessPolicies/${var.access_policy_id}/servicePerimeters/genai_workloads"
  title          = "genai_workloads"
  perimeter_type = "PERIMETER_TYPE_REGULAR"

  use_explicit_dry_run_spec = var.dry_run

  dynamic "spec" {
    for_each = var.dry_run ? [1] : []
    content {
      resources           = var.projects
      restricted_services = var.restricted_services

      vpc_accessible_services {
        enable_restriction = true
        allowed_services   = ["RESTRICTED-SERVICES"]
      }
    }
  }

  dynamic "status" {
    for_each = var.dry_run ? [] : [1]
    content {
      resources           = var.projects
      restricted_services = var.restricted_services

      vpc_accessible_services {
        enable_restriction = true
        allowed_services   = ["RESTRICTED-SERVICES"]
      }
    }
  }
}
