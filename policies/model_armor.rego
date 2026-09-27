# Model Armor must be present, enforcing, and not quietly loosened.
#
# The dangerous misconfiguration is not a missing template (DET-003 and this
# check both catch that); it is a template or floor setting that exists, shows
# up green in every dashboard, and has its prompt-injection filter disabled or
# its floor enforcement switched off.
package genai.modelarmor

import rego.v1

live(type) := [c | some c in input.resource_changes; c.type == type; c.change.actions != ["delete"]]

deny contains "no google_model_armor_template in plan (MA-001..004)" if {
	count(live("google_model_armor_template")) == 0
}

deny contains "no google_model_armor_floorsetting in plan (MA-005)" if {
	count(live("google_model_armor_floorsetting")) == 0
}

filters(change) := change.change.after.filter_config[0]

deny contains msg if {
	some c in array.concat(live("google_model_armor_template"), live("google_model_armor_floorsetting"))
	not pi_enabled(filters(c))
	msg := sprintf("%s: prompt injection / jailbreak filter is not ENABLED (MA-001)", [c.address])
}

pi_enabled(f) if f.pi_and_jailbreak_filter_settings[0].filter_enforcement == "ENABLED"

deny contains msg if {
	some c in array.concat(live("google_model_armor_template"), live("google_model_armor_floorsetting"))
	filters(c).pi_and_jailbreak_filter_settings[0].confidence_level == "HIGH"
	msg := sprintf("%s: prompt injection threshold HIGH only blocks the most obvious attacks (MA-001)", [c.address])
}

deny contains msg if {
	some c in live("google_model_armor_floorsetting")
	not c.change.after.enable_floor_setting_enforcement
	msg := sprintf("%s: floor setting exists but enforcement is off (MA-005)", [c.address])
}

deny contains msg if {
	some c in live("google_model_armor_floorsetting")
	some s in c.change.after.ai_platform_floor_setting
	not s.inspect_and_block
	msg := sprintf("%s: Vertex AI floor inspects only; nothing is blocked (MA-005)", [c.address])
}
