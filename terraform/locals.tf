locals {
  is_org_scope = var.deployment_scope == "organization"
  parent       = local.is_org_scope ? "organizations/${var.org_id}" : "projects/${var.project_id}"

  # -------------------------------------------------------------------------
  # The profile lookup. This map is the single place where "standard" and
  # "strict" differ. Modules read local.p and never branch on
  # var.guardrail_profile, so adding a third profile is a map entry.
  # -------------------------------------------------------------------------
  profile = {
    standard = {
      # Model Armor confidence threshold. MEDIUM_AND_ABOVE blocks likely
      # attacks without drowning a support workload in false positives.
      filter_confidence = "MEDIUM_AND_ABOVE"
      # Filter floor enforced inline on Vertex AI. Standard inspects and
      # blocks; strict does too, and nothing below it is allowed to loosen it.
      floor_inspect_and_block = true

      kms_rotation_period  = "7776000s" # 90 days
      kms_protection_level = "SOFTWARE"

      log_retention_days = 365
      log_bucket_locked  = true

      # A perimeter nobody has modelled against real traffic breaks CI and
      # gets disabled within a week. Standard observes.
      vpcsc_dry_run = true
    }

    strict = {
      filter_confidence       = "LOW_AND_ABOVE"
      floor_inspect_and_block = true

      kms_rotation_period  = "2592000s" # 30 days
      kms_protection_level = "HSM"

      log_retention_days = 2555 # 7 years
      log_bucket_locked  = true

      vpcsc_dry_run = false
    }
  }

  p = local.profile[var.guardrail_profile]
}
