# Egress is the exfiltration path. An AI workload VPC must deny it by default,
# and must not re-open it wholesale with a higher-priority allow.
#
# Both rules below are sourced from 0.0.0.0/0. A policy that cannot tell a
# deny-all from an allow-all written against the same range is worse than no
# policy, and there is a named test for exactly that case.
package genai.network

import rego.v1

firewalls := [c.change.after | some c in input.resource_changes; c.type == "google_compute_firewall"; c.change.actions != ["delete"]]

egress_open_world(fw) if {
	fw.direction == "EGRESS"
	some r in fw.destination_ranges
	r == "0.0.0.0/0"
}

default_deny_egress if {
	some fw in firewalls
	egress_open_world(fw)
	count(fw.deny) > 0
}

deny contains "no default-deny EGRESS rule to 0.0.0.0/0 (NET-002)" if {
	count(firewalls) > 0
	not default_deny_egress
}

deny contains msg if {
	some fw in firewalls
	egress_open_world(fw)
	count(fw.allow) > 0
	msg := sprintf("firewall %q allows egress to 0.0.0.0/0; injected instructions can exfiltrate (NET-002)", [fw.name])
}

deny contains msg if {
	some fw in firewalls
	fw.direction == "INGRESS"
	some r in fw.source_ranges
	r == "0.0.0.0/0"
	count(fw.allow) > 0
	msg := sprintf("firewall %q allows ingress from 0.0.0.0/0 (NET-005)", [fw.name])
}
