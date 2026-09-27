output "guardrail_profile" {
  description = "Resolved profile parameters, so a reviewer can see what \"strict\" actually changed."
  value       = local.p
}

output "workload_service_account" {
  description = "Service account the application should run as. It can call models and nothing else."
  value       = try(module.identity[0].service_account_email, null)
}

output "vertex_kms_key" {
  description = "Key to pass as encryption_spec.kms_key_name on Vertex AI resources."
  value       = try(module.encryption[0].vertex_key_id, null)
}

output "model_armor_template" {
  description = "Template for explicit sanitizeUserPrompt / sanitizeModelResponse calls."
  value       = try(module.model_armor[0].template_id, null)
}

output "perimeter_mode" {
  description = "\"dry_run\" observes violations; \"enforced\" blocks them."
  value       = var.enable_vpc_service_controls && local.is_org_scope ? (local.p.vpcsc_dry_run ? "dry_run" : "enforced") : "not_deployed"
}
