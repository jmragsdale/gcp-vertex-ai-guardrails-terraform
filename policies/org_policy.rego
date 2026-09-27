# Organization policy coverage for an AI workload.
#
# Runs against a Terraform plan in JSON form:
#   terraform plan -out tfplan && terraform show -json tfplan > plan.json
#   conftest test plan.json --policy policies --all-namespaces
#
# Two failure modes, and the second is worse because it looks like coverage:
#   1. a required constraint is absent from the plan
#   2. the model allowlist is present but written so that it allows everything
package genai.orgpolicy

import rego.v1

required_constraints := {
	"vertexai.allowedModels",
	"iam.disableServiceAccountKeyCreation",
	"gcp.resourceLocations",
}

policies contains change if {
	some change in input.resource_changes
	change.type == "google_org_policy_policy"
	change.change.actions != ["delete"]
}

constraint_of(name) := parts[count(parts) - 1] if {
	parts := split(name, "/policies/")
}

planned contains constraint_of(change.change.after.name) if {
	some change in policies
}

deny contains msg if {
	some constraint in required_constraints
	not constraint in planned
	msg := sprintf("required org policy constraint %q is not in the plan (ORG baseline)", [constraint])
}

# An allowlist that allows everything is not an allowlist.
deny contains msg if {
	some change in policies
	constraint_of(change.change.after.name) == "vertexai.allowedModels"
	some spec in change.change.after.spec
	some rule in spec.rules
	rule.allow_all == "TRUE"
	msg := "vertexai.allowedModels uses allow_all; every Model Garden model is permitted (ORG-001)"
}

# Wildcard-ish entries: a bare publisher permits every model and every action it ships.
deny contains msg if {
	some change in policies
	constraint_of(change.change.after.name) == "vertexai.allowedModels"
	some spec in change.change.after.spec
	some rule in spec.rules
	some values in rule.values
	some v in values.allowed_values
	not contains(v, "/models/")
	msg := sprintf("vertexai.allowedModels allows a whole publisher (%q); name models individually (ORG-001)", [v])
}

# Tuning is a different approval from calling. Flag it so it is a decision, not a default.
warn contains msg if {
	some change in policies
	constraint_of(change.change.after.name) == "vertexai.allowedModels"
	some spec in change.change.after.spec
	some rule in spec.rules
	some values in rule.values
	some v in values.allowed_values
	endswith(v, ":tune")
	msg := sprintf("%q permits fine-tuning; confirm training data governance covers it (ORG-001)", [v])
}
