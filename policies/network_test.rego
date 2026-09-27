package genai.network_test

import rego.v1

import data.genai.network

fw(name, direction, key, ranges, action) := {"type": "google_compute_firewall", "change": {"actions": ["create"], "after": object.union(
	{"name": name, "direction": direction, key: ranges, "allow": [], "deny": []},
	{action: [{"protocol": "all"}]},
)}}

deny_egress := fw("deny-egress", "EGRESS", "destination_ranges", ["0.0.0.0/0"], "deny")

allow_apis := fw("allow-apis", "EGRESS", "destination_ranges", ["199.36.153.4/30"], "allow")

test_baseline_passes if {
	count(network.deny) == 0 with input as {"resource_changes": [deny_egress, allow_apis]}
}

test_missing_default_deny if {
	count(network.deny) == 1 with input as {"resource_changes": [allow_apis]}
}

test_distinguishes_deny_all_from_allow_all_on_same_range if {
	allow_world := fw("allow-world", "EGRESS", "destination_ranges", ["0.0.0.0/0"], "allow")
	count(network.deny) == 0 with input as {"resource_changes": [deny_egress]}
	count(network.deny) == 1 with input as {"resource_changes": [deny_egress, allow_world]}
}

test_open_ingress_denied if {
	open := fw("open", "INGRESS", "source_ranges", ["0.0.0.0/0"], "allow")
	some msg in network.deny with input as {"resource_changes": [deny_egress, open]}
	contains(msg, "ingress")
}

test_no_firewalls_is_not_a_finding if {
	count(network.deny) == 0 with input as {"resource_changes": []}
}
