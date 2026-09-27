package genai.modelarmor_test

import rego.v1

import data.genai.modelarmor

filters(enforcement, confidence) := [{"pi_and_jailbreak_filter_settings": [{
	"filter_enforcement": enforcement,
	"confidence_level": confidence,
}]}]

template(f) := {"address": "module.x.google_model_armor_template.genai", "type": "google_model_armor_template",
	"change": {"actions": ["create"], "after": {"filter_config": f}}}

floor(f, enforce, block) := {"address": "module.x.google_model_armor_floorsetting.genai", "type": "google_model_armor_floorsetting",
	"change": {"actions": ["create"], "after": {
		"filter_config": f,
		"enable_floor_setting_enforcement": enforce,
		"ai_platform_floor_setting": [{"inspect_and_block": block}],
	}}}

ok := filters("ENABLED", "MEDIUM_AND_ABOVE")

test_compliant_passes if {
	count(modelarmor.deny) == 0 with input as {"resource_changes": [template(ok), floor(ok, true, true)]}
}

test_missing_both_denied if {
	count(modelarmor.deny) == 2 with input as {"resource_changes": []}
}

test_disabled_pi_filter_denied if {
	bad := filters("DISABLED", "MEDIUM_AND_ABOVE")
	count(modelarmor.deny) == 1 with input as {"resource_changes": [template(bad), floor(ok, true, true)]}
}

test_absent_pi_block_denied if {
	count(modelarmor.deny) == 1 with input as {"resource_changes": [template([{}]), floor(ok, true, true)]}
}

test_high_only_threshold_denied if {
	loose := filters("ENABLED", "HIGH")
	some msg in modelarmor.deny with input as {"resource_changes": [template(ok), floor(loose, true, true)]}
	contains(msg, "HIGH")
}

test_floor_not_enforced_denied if {
	some msg in modelarmor.deny with input as {"resource_changes": [template(ok), floor(ok, false, true)]}
	contains(msg, "enforcement is off")
}

test_inspect_only_denied if {
	some msg in modelarmor.deny with input as {"resource_changes": [template(ok), floor(ok, true, false)]}
	contains(msg, "inspects only")
}
