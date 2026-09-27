variable "project_id" {
  description = "Workload project."
  type        = string
}

variable "project_number" {
  description = "Workload project number, for the budget filter."
  type        = string
}

variable "alert_email" {
  description = "Where alerts go."
  type        = string
}

variable "enable_alerts" {
  description = "Create log-based metrics and alert policies."
  type        = bool
}

variable "enable_budget" {
  description = "Create the billing budget."
  type        = bool
}

variable "billing_account_id" {
  description = "Billing account for the budget."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly spend ceiling."
  type        = number
}

locals {
  # Each metric watches for a change to the guardrails themselves. The most
  # useful thing an attacker with a foothold can do is quietly loosen these.
  metrics = var.enable_alerts ? {
    # DET-001  Someone changed who can use Vertex AI.
    "genai-iam-change" = {
      description = "IAM policy changed on a Vertex AI resource."
      filter      = "protoPayload.serviceName=\"aiplatform.googleapis.com\" AND protoPayload.methodName:\"SetIamPolicy\""
    }
    # DET-002  A model was deployed to or removed from an endpoint.
    "genai-model-deployment" = {
      description = "Model deployed or undeployed on a Vertex AI endpoint."
      filter      = "protoPayload.serviceName=\"aiplatform.googleapis.com\" AND (protoPayload.methodName:\"DeployModel\" OR protoPayload.methodName:\"UndeployModel\")"
    }
    # DET-003  Model Armor templates or floor settings were changed or deleted.
    "genai-guardrail-change" = {
      description = "Model Armor template or floor setting modified."
      filter      = "protoPayload.serviceName=\"modelarmor.googleapis.com\" AND (protoPayload.methodName:\"Update\" OR protoPayload.methodName:\"Delete\")"
    }
  } : {}
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Generative AI security alerts"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_logging_metric" "guardrail" {
  for_each = local.metrics

  project     = var.project_id
  name        = each.key
  description = each.value.description
  filter      = each.value.filter

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "guardrail" {
  for_each = local.metrics

  project               = var.project_id
  display_name          = each.value.description
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email.id]

  conditions {
    display_name = each.value.description

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.guardrail[each.key].name}\" AND resource.type=\"global\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }
}

# DET-004  Unbounded consumption. A leaked credential or a looping agent shows
# up on the bill before it shows up anywhere else. Budgets alert; they do not
# cap spend. Pair with Vertex AI quota limits for a hard ceiling.
resource "google_billing_budget" "genai" {
  count = var.enable_budget ? 1 : 0

  billing_account = var.billing_account_id
  display_name    = "genai-${var.project_id}"

  budget_filter {
    projects = ["projects/${var.project_number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.email.id]
    disable_default_iam_recipients   = false
  }
}
