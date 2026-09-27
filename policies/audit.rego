# Data Access audit logs on the AI services must include reads and writes.
# ADMIN_READ alone records who changed configuration, not who used a model.
package genai.audit

import rego.v1

ai_services := {"aiplatform.googleapis.com", "modelarmor.googleapis.com"}

configs := [c.change.after | some c in input.resource_changes; c.type == "google_project_iam_audit_config"; c.change.actions != ["delete"]]

log_types(svc) := {t.log_type | some c in configs; c.service == svc; some t in c.audit_log_config}

deny contains msg if {
	count(configs) > 0
	some svc in ai_services
	some needed in {"DATA_READ", "DATA_WRITE"}
	not needed in log_types(svc)
	msg := sprintf("%s audit config lacks %s (LOG-001)", [svc, needed])
}

deny contains msg if {
	some c in configs
	some t in c.audit_log_config
	count(object.get(t, "exempted_members", [])) > 0
	msg := sprintf("%s audit config exempts principals %v from logging (LOG-001)", [c.service, t.exempted_members])
}
