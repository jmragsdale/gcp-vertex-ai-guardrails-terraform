package genai.audit_test

import rego.v1

import data.genai.audit

cfg(svc, types) := {"type": "google_project_iam_audit_config", "change": {"actions": ["create"], "after": {
	"service": svc,
	"audit_log_config": [{"log_type": t} | some t in types],
}}}

full := ["ADMIN_READ", "DATA_READ", "DATA_WRITE"]

test_full_config_passes if {
	count(audit.deny) == 0 with input as {"resource_changes": [
		cfg("aiplatform.googleapis.com", full),
		cfg("modelarmor.googleapis.com", full),
	]}
}

test_admin_only_denied if {
	count(audit.deny) == 2 with input as {"resource_changes": [
		cfg("aiplatform.googleapis.com", ["ADMIN_READ"]),
		cfg("modelarmor.googleapis.com", full),
	]}
}

test_exempted_member_denied if {
	exempt := {"type": "google_project_iam_audit_config", "change": {"actions": ["create"], "after": {
		"service": "aiplatform.googleapis.com",
		"audit_log_config": [
			{"log_type": "DATA_READ", "exempted_members": ["user:dev@example.com"]},
			{"log_type": "DATA_WRITE"},
		],
	}}}
	some msg in audit.deny with input as {"resource_changes": [exempt, cfg("modelarmor.googleapis.com", full)]}
	contains(msg, "exempts")
}
