package genai.orgpolicy_test

import rego.v1

import data.genai.orgpolicy

pol(constraint, rules) := {
	"type": "google_org_policy_policy",
	"change": {"actions": ["create"], "after": {
		"name": sprintf("organizations/1/policies/%s", [constraint]),
		"spec": [{"rules": rules}],
	}},
}

enforced(c) := pol(c, [{"enforce": "TRUE"}])

models(vals) := pol("vertexai.allowedModels", [{"values": [{"allowed_values": vals}]}])

baseline(model_policy) := {"resource_changes": [
	model_policy,
	enforced("iam.disableServiceAccountKeyCreation"),
	pol("gcp.resourceLocations", [{"values": [{"allowed_values": ["in:us-locations"]}]}]),
]}

good := models(["publishers/google/models/gemini-3.5-flash:predict"])

test_compliant_plan_passes if {
	count(orgpolicy.deny) == 0 with input as baseline(good)
}

test_missing_model_allowlist_denied if {
	plan := {"resource_changes": [enforced("iam.disableServiceAccountKeyCreation")]}
	some msg in orgpolicy.deny with input as plan
	contains(msg, "vertexai.allowedModels")
}

test_deleted_constraint_counts_as_missing if {
	deleted := object.union(good, {"change": {"actions": ["delete"], "after": good.change.after}})
	count(orgpolicy.deny) == 1 with input as baseline(deleted)
}

test_allow_all_denied if {
	plan := baseline(pol("vertexai.allowedModels", [{"allow_all": "TRUE"}]))
	some msg in orgpolicy.deny with input as plan
	contains(msg, "allow_all")
}

test_whole_publisher_denied if {
	plan := baseline(models(["publishers/meta"]))
	some msg in orgpolicy.deny with input as plan
	contains(msg, "whole publisher")
}

test_tune_warns_but_does_not_deny if {
	plan := baseline(models(["publishers/google/models/gemini-3.5-flash:tune"]))
	count(orgpolicy.deny) == 0 with input as plan
	count(orgpolicy.warn) == 1 with input as plan
}
