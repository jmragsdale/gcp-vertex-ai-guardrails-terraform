variable "project_id" {
  description = "Workload project."
  type        = string
}

# IAM-001  One identity per workload. The application runs as this account, so
# every model call in the audit log is attributable to it and nothing else.
resource "google_service_account" "genai_app" {
  project      = var.project_id
  account_id   = "genai-app"
  display_name = "Generative AI application"
  description  = "Runtime identity for the AI application. Predict-only. No keys (ORG-004)."
}

# IAM-002  Predict-only custom role. roles/aiplatform.user would also let the
# application create endpoints, deploy models and launch training jobs; an
# injected instruction that reaches a code path holding those rights has a
# much larger blast radius than one that can only ask a model a question.
resource "google_project_iam_custom_role" "model_invoker" {
  project     = var.project_id
  role_id     = "genaiModelInvoker"
  title       = "Generative AI model invoker"
  description = "Call Vertex AI models. Cannot create, deploy, tune or delete anything."
  permissions = ["aiplatform.endpoints.predict"]
}

resource "google_project_iam_member" "genai_app_invoker" {
  project = var.project_id
  role    = google_project_iam_custom_role.model_invoker.id
  member  = "serviceAccount:${google_service_account.genai_app.email}"
}

output "service_account_email" {
  description = "Runtime identity for the AI application."
  value       = google_service_account.genai_app.email
}
