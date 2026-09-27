variable "project_id" {
  description = "Workload project."
  type        = string
}

variable "region" {
  description = "Template location."
  type        = string
}

variable "floor_parent" {
  description = "\"organizations/<id>\" or \"projects/<id>\"; where the floor setting binds."
  type        = string
}

variable "profile" {
  description = "Guardrail profile name, used in the template ID."
  type        = string
}

variable "confidence" {
  description = "Detection confidence threshold from the guardrail profile."
  type        = string
}

variable "floor_inspect_and_block" {
  description = "Floor setting blocks (true) or only inspects and logs (false)."
  type        = bool
}

# ===========================================================================
# Model Armor screens prompts going in and responses coming out.
#
# Two layers, deliberately:
#   template       what an application calls explicitly (sanitizeUserPrompt /
#                  sanitizeModelResponse), e.g. before a RAG retrieval step.
#   floor setting  enforced inline on Vertex AI generateContent. Applies even
#                  when an application never calls Model Armor at all, which is
#                  the case that matters: guardrails that depend on every
#                  developer remembering to call them are guardrails with gaps.
#
# Model Armor is a detection layer. Prompt injection is not a solved problem
# and no classifier catches all of it; this reduces volume, it does not close
# the class. The tool-authorization layer is where that gets closed.
# ===========================================================================

resource "google_model_armor_template" "genai" {
  project     = var.project_id
  location    = var.region
  template_id = "genai-${var.profile}"

  filter_config {
    # MA-001  Prompt injection and jailbreak detection.
    pi_and_jailbreak_filter_settings {
      filter_enforcement = "ENABLED"
      confidence_level   = var.confidence
    }

    # MA-002  Sensitive data (Sensitive Data Protection basic infoTypes) in
    # prompts and responses.
    sdp_settings {
      basic_config {
        filter_enforcement = "ENABLED"
      }
    }

    # MA-003  Malicious URLs, in either direction.
    malicious_uri_filter_settings {
      filter_enforcement = "ENABLED"
    }

    # MA-004  Responsible AI content categories.
    rai_settings {
      rai_filters {
        filter_type      = "DANGEROUS"
        confidence_level = var.confidence
      }
      rai_filters {
        filter_type      = "HARASSMENT"
        confidence_level = var.confidence
      }
      rai_filters {
        filter_type      = "HATE_SPEECH"
        confidence_level = var.confidence
      }
      rai_filters {
        filter_type      = "SEXUALLY_EXPLICIT"
        confidence_level = var.confidence
      }
    }
  }

  template_metadata {
    log_template_operations = true
    log_sanitize_operations = true
  }
}

# MA-005  Floor setting: the minimum every Vertex AI call in scope gets,
# whether or not the application asked for it.
resource "google_model_armor_floorsetting" "genai" {
  parent   = var.floor_parent
  location = "global"

  enable_floor_setting_enforcement = true
  integrated_services              = ["AI_PLATFORM"]

  ai_platform_floor_setting {
    inspect_and_block    = var.floor_inspect_and_block
    enable_cloud_logging = true
  }

  filter_config {
    pi_and_jailbreak_filter_settings {
      filter_enforcement = "ENABLED"
      confidence_level   = var.confidence
    }

    malicious_uri_filter_settings {
      filter_enforcement = "ENABLED"
    }

    sdp_settings {
      basic_config {
        filter_enforcement = "ENABLED"
      }
    }
  }
}

output "template_id" {
  description = "Full template resource name."
  value       = google_model_armor_template.genai.id
}
