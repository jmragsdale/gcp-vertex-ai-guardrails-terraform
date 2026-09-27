# ===========================================================================
# Root composition
#
# Every module is gated twice: on an enable_* flag so nothing metered appears by
# accident, and on deployment_scope so a reader without an organization can
# still plan the whole thing. The order below is the order of the attack path:
# who may call a model, what it may reach, what it may be told, and who notices.
# ===========================================================================

data "google_project" "workload" {
  project_id = var.project_id
}

# CM-7 least functionality. Only the APIs this baseline needs.
resource "google_project_service" "required" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "modelarmor.googleapis.com",
    "orgpolicy.googleapis.com",
    "cloudkms.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy         = false
  disable_dependent_services = false
}

# --------------------------------------------------------------------------- preventive

module "org_policy" {
  source = "./modules/org-policy"
  count  = var.enable_org_policies ? 1 : 0

  parent                 = local.parent
  allowed_models         = var.allowed_models
  allowed_locations      = var.allowed_locations
  cmek_required_services = var.enable_cmek ? var.cmek_required_services : []
}

module "identity" {
  source = "./modules/identity"
  count  = var.enable_identity ? 1 : 0

  project_id = var.project_id
}

module "encryption" {
  source = "./modules/encryption"
  count  = var.enable_cmek ? 1 : 0

  project_id       = var.project_id
  project_number   = data.google_project.workload.number
  region           = var.region
  rotation_period  = local.p.kms_rotation_period
  protection_level = local.p.kms_protection_level

  depends_on = [google_project_service.required]
}

module "network" {
  source = "./modules/network"
  count  = var.enable_network ? 1 : 0

  project_id  = var.project_id
  region      = var.region
  subnet_cidr = var.subnet_cidr

  depends_on = [google_project_service.required]
}

module "vpc_sc" {
  source = "./modules/vpc-sc"
  # A perimeter needs an organization-level access policy. There is no
  # single-project equivalent, and pretending otherwise would be decorative.
  count = var.enable_vpc_service_controls && local.is_org_scope ? 1 : 0

  access_policy_id    = var.access_policy_id
  projects            = length(var.perimeter_projects) > 0 ? var.perimeter_projects : ["projects/${data.google_project.workload.number}"]
  restricted_services = var.restricted_services
  dry_run             = local.p.vpcsc_dry_run
}

# --------------------------------------------------------------------------- runtime guardrails

module "model_armor" {
  source = "./modules/model-armor"
  count  = var.enable_model_armor ? 1 : 0

  project_id              = var.project_id
  region                  = var.region
  floor_parent            = local.parent
  profile                 = var.guardrail_profile
  confidence              = local.p.filter_confidence
  floor_inspect_and_block = local.p.floor_inspect_and_block

  depends_on = [google_project_service.required]
}

# --------------------------------------------------------------------------- evidence and detection

module "logging" {
  source = "./modules/logging"
  count  = var.enable_audit_logging ? 1 : 0

  project_id     = var.project_id
  retention_days = local.p.log_retention_days
  lock_retention = local.p.log_bucket_locked
}

module "detection" {
  source = "./modules/detection"
  count  = var.enable_detection || var.enable_budget ? 1 : 0

  project_id         = var.project_id
  project_number     = data.google_project.workload.number
  alert_email        = var.alert_email
  enable_alerts      = var.enable_detection
  enable_budget      = var.enable_budget
  billing_account_id = var.billing_account_id
  monthly_budget_usd = var.monthly_budget_usd

  depends_on = [google_project_service.required]
}
