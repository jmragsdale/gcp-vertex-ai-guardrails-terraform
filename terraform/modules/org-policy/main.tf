# ===========================================================================
# Preventive guardrails for generative AI.
#
# Org policy is evaluated by the Google API before a resource exists, so these
# are the only controls here that cannot be bypassed by an application that
# forgets to call something. They are also free.
# ===========================================================================

# ORG-001  Model supply chain. Only allowlisted Model Garden models can be used.
# The difference between "we approved Gemini" and "a notebook somewhere is
# calling an unreviewed open model with production data" is this constraint.
resource "google_org_policy_policy" "allowed_models" {
  name   = "${var.parent}/policies/vertexai.allowedModels"
  parent = var.parent

  spec {
    rules {
      values {
        allowed_values = var.allowed_models
      }
    }
  }
}

# ORG-002  Data residency. Prompts, embeddings, tuning data and endpoints stay
# in approved locations. Note this governs where resources are created; the
# data-processing location of a global model endpoint is a separate question,
# answered by choosing regional endpoints in the application.
resource "google_org_policy_policy" "resource_locations" {
  name   = "${var.parent}/policies/gcp.resourceLocations"
  parent = var.parent

  spec {
    rules {
      values {
        allowed_values = var.allowed_locations
      }
    }
  }
}

# ORG-003  Vertex AI resources (datasets, tuned models, endpoints, pipelines)
# must be created with a customer-managed key.
resource "google_org_policy_policy" "restrict_non_cmek" {
  count = length(var.cmek_required_services) > 0 ? 1 : 0

  name   = "${var.parent}/policies/gcp.restrictNonCmekServices"
  parent = var.parent

  spec {
    rules {
      values {
        denied_values = var.cmek_required_services
      }
    }
  }
}

# ORG-004  No long-lived service account keys. A leaked key for an account that
# can call a model is a free, unattributed inference budget for whoever has it.
resource "google_org_policy_policy" "disable_sa_key_creation" {
  name   = "${var.parent}/policies/iam.disableServiceAccountKeyCreation"
  parent = var.parent

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# ORG-005  Default service accounts get no automatic Editor grant. Workbench
# and pipeline jobs that fall back to the default compute SA would otherwise
# run with project-wide write.
resource "google_org_policy_policy" "no_default_sa_grants" {
  name   = "${var.parent}/policies/iam.automaticIamGrantsForDefaultServiceAccounts"
  parent = var.parent

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# ORG-006  Vertex AI Workbench instances get no public IP.
resource "google_org_policy_policy" "workbench_no_public_ip" {
  name   = "${var.parent}/policies/ainotebooks.restrictPublicIp"
  parent = var.parent

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# ORG-007  No root on Workbench instances. Data scientists get notebooks, not a
# host from which to rewrite the credential helper.
resource "google_org_policy_policy" "workbench_no_root" {
  name   = "${var.parent}/policies/ainotebooks.disableRootAccess"
  parent = var.parent

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}
