variable "project_id" {
  description = "Workload project; also holds the key ring in this layout."
  type        = string
}

variable "project_number" {
  description = "Workload project number, used to name the Google-managed service agents."
  type        = string
}

variable "region" {
  description = "Key ring location. Must match the region Vertex AI resources are created in."
  type        = string
}

variable "rotation_period" {
  description = "Automatic rotation interval, from the guardrail profile."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+s$", var.rotation_period)) && tonumber(trimsuffix(var.rotation_period, "s")) <= 7776000
    error_message = "rotation_period must be a duration in seconds of at most 90 days (7776000s)."
  }
}

variable "protection_level" {
  description = "SOFTWARE or HSM, from the guardrail profile."
  type        = string
}

# ENC-001  Regional key ring for AI data. Vertex AI requires the key to live in
# the same region as the resource it protects.
resource "google_kms_key_ring" "genai" {
  project  = var.project_id
  name     = "genai-${var.region}"
  location = var.region
}

resource "google_kms_crypto_key" "vertex" {
  # checkov:skip=CKV_GCP_43: rotation_period is supplied from local.p (90d standard, 30d strict) and cannot be statically resolved. The 90-day ceiling is enforced by the validation block on var.rotation_period instead.
  name            = "vertex-ai"
  key_ring        = google_kms_key_ring.genai.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = var.rotation_period

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.protection_level
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ENC-002  Only the Vertex AI and Cloud Storage service agents may use the key.
# Humans who administer the key ring hold no encrypt/decrypt grant: an admin
# who can also decrypt is not a separation of duties. The Vertex AI service
# agent is created on first API use; see README for the one-time gcloud step
# if this binding fails on a brand-new project.
resource "google_kms_crypto_key_iam_member" "vertex_agent" {
  crypto_key_id = google_kms_crypto_key.vertex.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "storage_agent" {
  crypto_key_id = google_kms_crypto_key.vertex.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

output "vertex_key_id" {
  description = "Full resource ID of the Vertex AI key."
  value       = google_kms_crypto_key.vertex.id
}
