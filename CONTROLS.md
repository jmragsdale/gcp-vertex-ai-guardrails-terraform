<!-- GENERATED FILE - do not edit by hand.
     Source: controls/controls.yaml   Regenerate: python3 controls/render.py -->

# Control Matrix - Google Cloud Platform (Vertex AI)

29 implemented controls, each backed by a Terraform address that CI verifies exists.

## Framework coverage

| Framework | Version | Controls implemented | Distinct framework IDs mapped |
|---|---|---:|---:|
| OWASP Top 10 for LLM Applications | 2025 | 21 / 29 | 8 |
| NIST AI Risk Management Framework | 1.0 | 29 / 29 | 7 |
| NIST SP 800-53 Rev 5 | Rev 5 | 29 / 29 | 30 |

> **Read this honestly:** these numbers count *technical* controls implemented in Terraform around a generative AI workload. They are not an assessment and not a claim that the workload is safe. Most of the NIST AI RMF (GOVERN, MAP, and the evaluation half of MEASURE) is organisational practice that infrastructure code cannot implement.

## Enforcement split

| Type | Count | Meaning |
|---|---:|---|
| preventive | 14 | blocks the non-compliant configuration from being created |
| detective | 11 | detects and reports the non-compliant configuration |
| foundational | 4 | provides the substrate other controls depend on (logging, keys, scope) |

## Matrix

| ID | Control | Type | Module | OWASP LLM | AI RMF | NIST | Demo-safe | Billable |
|---|---|---|---|---|---|---|---|---|
| `DET-001` | Alert on IAM changes to Vertex AI resources | detective | `detection` | LLM06 | MANAGE 4.1 | AC-2(4), SI-4 | yes | no |
| `DET-002` | Alert on model deployment and undeployment | detective | `detection` | LLM03, LLM04 | MEASURE 2.4 | CM-3, SI-4 | yes | no |
| `DET-003` | Alert on Model Armor template or floor setting changes | detective | `detection` | LLM01 | MANAGE 4.1 | CM-3, SI-4, AU-6 | yes | no |
| `DET-004` | Budget alerts on the AI project, including forecast | detective | `detection` | LLM10 | MANAGE 4.1 | SC-5 | yes | no |
| `ENC-001` | Regional CMEK for Vertex AI with profile-driven rotation and protection level | foundational | `encryption` | LLM02 | MEASURE 2.10 | SC-12, SC-12(1), SC-28 | yes | yes |
| `ENC-002` | Key usable only by Google service agents; administrators hold no decrypt grant | preventive | `encryption` | LLM02 | MEASURE 2.10 | SC-12, AC-5 | yes | no |
| `IAM-001` | Dedicated runtime identity for the AI application | foundational | `identity` | LLM06 | MEASURE 2.7 | AC-2, IA-2 | yes | no |
| `IAM-002` | Predict-only custom role instead of roles/aiplatform.user | preventive | `identity` | LLM06 | MEASURE 2.7 | AC-6, AC-6(1) | yes | no |
| `LOG-001` | Data Access audit logs for Vertex AI and Model Armor | detective | `logging` | LLM10 | MANAGE 4.1 | AU-2, AU-12 | yes | yes |
| `LOG-002` | Retention-locked log bucket for AI audit records | foundational | `logging` | - | MANAGE 4.1 | AU-9, AU-11 | yes | yes |
| `LOG-003` | AI service and Model Armor records routed to the audit bucket | detective | `logging` | - | MEASURE 2.4 | AU-6, AU-12 | yes | yes |
| `MA-001` | Prompt injection and jailbreak detection (template) | detective | `model-armor` | LLM01 | MEASURE 2.7 | SI-10, SI-4 | yes | yes |
| `MA-002` | Sensitive data detection in prompts and responses (template) | detective | `model-armor` | LLM02, LLM07 | MEASURE 2.10 | SI-4, AC-4 | yes | yes |
| `MA-003` | Malicious URL detection (template) | detective | `model-armor` | LLM05 | MEASURE 2.7 | SI-3, SI-4 | yes | yes |
| `MA-004` | Responsible AI content filters (template) | detective | `model-armor` | - | MEASURE 2.6 | SI-4 | yes | yes |
| `MA-005` | Floor setting enforced inline on every Vertex AI call in scope | preventive | `model-armor` | LLM01, LLM02 | MANAGE 1.3 | SI-10, AC-3 | yes | yes |
| `NET-001` | Custom-mode workload VPC with Private Google Access | foundational | `network` | - | MEASURE 2.7 | SC-7 | yes | no |
| `NET-002` | Default-deny egress; the only path out is HTTPS to restricted Google APIs | preventive | `network` | LLM02, LLM06 | MEASURE 2.7 | SC-7(5), AC-4 | yes | no |
| `NET-003` | Google APIs resolve to restricted.googleapis.com | preventive | `network` | LLM02 | MEASURE 2.7 | SC-7, AC-4 | yes | yes |
| `NET-004` | VPC flow logs on the workload subnet | detective | `network` | - | MANAGE 4.1 | AU-12, SI-4 | yes | yes |
| `NET-005` | Explicit, logged default-deny ingress | preventive | `network` | - | MEASURE 2.7 | SC-7 | yes | no |
| `ORG-001` | Model allowlist — only approved Model Garden models and actions | preventive | `org-policy` | LLM03 | GOVERN 6.1 | CM-7, SR-3 | yes | no |
| `ORG-002` | Data residency for AI resources | preventive | `org-policy` | LLM02 | MEASURE 2.10 | SA-9(5), CM-6 | yes | no |
| `ORG-003` | CMEK required for Vertex AI, Cloud Storage and BigQuery | preventive | `org-policy` | LLM02 | MEASURE 2.10 | SC-28, SC-12 | yes | no |
| `ORG-004` | Service account key creation disabled | preventive | `org-policy` | LLM10 | MEASURE 2.7 | IA-5, AC-2 | yes | no |
| `ORG-005` | No automatic Editor grant to default service accounts | preventive | `org-policy` | LLM06 | MEASURE 2.7 | AC-6 | yes | no |
| `ORG-006` | Vertex AI Workbench instances have no public IP | preventive | `org-policy` | - | MEASURE 2.7 | SC-7 | yes | no |
| `ORG-007` | Root access disabled on Vertex AI Workbench | preventive | `org-policy` | - | MEASURE 2.7 | AC-6(10) | yes | no |
| `VSC-001` | VPC Service Controls perimeter around AI data services (dry-run → enforced by profile) | preventive | `vpc-sc` | LLM02, LLM03 | MEASURE 2.7 | SC-7, AC-4, SC-7(10) | no | no |

## Implementation index

Terraform addresses backing each control. CI fails if any of these stop existing.

| ID | Terraform addresses |
|---|---|
| `DET-001` | `detection:google_logging_metric.guardrail`, `detection:google_monitoring_alert_policy.guardrail` |
| `DET-002` | `detection:google_logging_metric.guardrail`, `detection:google_monitoring_alert_policy.guardrail` |
| `DET-003` | `detection:google_logging_metric.guardrail`, `detection:google_monitoring_alert_policy.guardrail` |
| `DET-004` | `detection:google_billing_budget.genai`, `detection:google_monitoring_notification_channel.email` |
| `ENC-001` | `encryption:google_kms_key_ring.genai`, `encryption:google_kms_crypto_key.vertex` |
| `ENC-002` | `encryption:google_kms_crypto_key_iam_member.vertex_agent`, `encryption:google_kms_crypto_key_iam_member.storage_agent` |
| `IAM-001` | `identity:google_service_account.genai_app` |
| `IAM-002` | `identity:google_project_iam_custom_role.model_invoker`, `identity:google_project_iam_member.genai_app_invoker` |
| `LOG-001` | `logging:google_project_iam_audit_config.ai` |
| `LOG-002` | `logging:google_logging_project_bucket_config.ai_audit` |
| `LOG-003` | `logging:google_logging_project_sink.ai_audit` |
| `MA-001` | `model-armor:google_model_armor_template.genai` |
| `MA-002` | `model-armor:google_model_armor_template.genai` |
| `MA-003` | `model-armor:google_model_armor_template.genai` |
| `MA-004` | `model-armor:google_model_armor_template.genai` |
| `MA-005` | `model-armor:google_model_armor_floorsetting.genai` |
| `NET-001` | `network:google_compute_network.genai`, `network:google_compute_subnetwork.genai` |
| `NET-002` | `network:google_compute_firewall.deny_all_egress`, `network:google_compute_firewall.allow_restricted_apis` |
| `NET-003` | `network:google_dns_managed_zone.googleapis`, `network:google_dns_record_set.restricted_a`, `network:google_dns_record_set.googleapis_cname`, `network:google_compute_route.restricted_apis` |
| `NET-004` | `network:google_compute_subnetwork.genai` |
| `NET-005` | `network:google_compute_firewall.deny_all_ingress` |
| `ORG-001` | `org-policy:google_org_policy_policy.allowed_models` |
| `ORG-002` | `org-policy:google_org_policy_policy.resource_locations` |
| `ORG-003` | `org-policy:google_org_policy_policy.restrict_non_cmek` |
| `ORG-004` | `org-policy:google_org_policy_policy.disable_sa_key_creation` |
| `ORG-005` | `org-policy:google_org_policy_policy.no_default_sa_grants` |
| `ORG-006` | `org-policy:google_org_policy_policy.workbench_no_public_ip` |
| `ORG-007` | `org-policy:google_org_policy_policy.workbench_no_root` |
| `VSC-001` | `vpc-sc:google_access_context_manager_service_perimeter.genai` |

## Reverse index (framework control -> repo control)

### OWASP Top 10 for LLM Applications

| Framework control | Implemented by |
|---|---|
| LLM01 | `DET-003`, `MA-001`, `MA-005` |
| LLM02 | `ENC-001`, `ENC-002`, `MA-002`, `MA-005`, `NET-002`, `NET-003`, `ORG-002`, `ORG-003`, `VSC-001` |
| LLM03 | `DET-002`, `ORG-001`, `VSC-001` |
| LLM04 | `DET-002` |
| LLM05 | `MA-003` |
| LLM06 | `DET-001`, `IAM-001`, `IAM-002`, `NET-002`, `ORG-005` |
| LLM07 | `MA-002` |
| LLM10 | `DET-004`, `LOG-001`, `ORG-004` |

### NIST AI Risk Management Framework

| Framework control | Implemented by |
|---|---|
| GOVERN 6.1 | `ORG-001` |
| MANAGE 1.3 | `MA-005` |
| MANAGE 4.1 | `DET-001`, `DET-003`, `DET-004`, `LOG-001`, `LOG-002`, `NET-004` |
| MEASURE 2.4 | `DET-002`, `LOG-003` |
| MEASURE 2.6 | `MA-004` |
| MEASURE 2.7 | `IAM-001`, `IAM-002`, `MA-001`, `MA-003`, `NET-001`, `NET-002`, `NET-003`, `NET-005`, `ORG-004`, `ORG-005`, `ORG-006`, `ORG-007`, `VSC-001` |
| MEASURE 2.10 | `ENC-001`, `ENC-002`, `MA-002`, `ORG-002`, `ORG-003` |

### NIST SP 800-53 Rev 5

| Framework control | Implemented by |
|---|---|
| AC-2 | `IAM-001`, `ORG-004` |
| AC-2(4) | `DET-001` |
| AC-3 | `MA-005` |
| AC-4 | `MA-002`, `NET-002`, `NET-003`, `VSC-001` |
| AC-5 | `ENC-002` |
| AC-6 | `IAM-002`, `ORG-005` |
| AC-6(1) | `IAM-002` |
| AC-6(10) | `ORG-007` |
| AU-2 | `LOG-001` |
| AU-6 | `DET-003`, `LOG-003` |
| AU-9 | `LOG-002` |
| AU-11 | `LOG-002` |
| AU-12 | `LOG-001`, `LOG-003`, `NET-004` |
| CM-3 | `DET-002`, `DET-003` |
| CM-6 | `ORG-002` |
| CM-7 | `ORG-001` |
| IA-2 | `IAM-001` |
| IA-5 | `ORG-004` |
| SA-9(5) | `ORG-002` |
| SC-5 | `DET-004` |
| SC-7 | `NET-001`, `NET-003`, `NET-005`, `ORG-006`, `VSC-001` |
| SC-7(5) | `NET-002` |
| SC-7(10) | `VSC-001` |
| SC-12 | `ENC-001`, `ENC-002`, `ORG-003` |
| SC-12(1) | `ENC-001` |
| SC-28 | `ENC-001`, `ORG-003` |
| SI-3 | `MA-003` |
| SI-4 | `DET-001`, `DET-002`, `DET-003`, `MA-001`, `MA-002`, `MA-003`, `MA-004`, `NET-004` |
| SI-10 | `MA-001`, `MA-005` |
| SR-3 | `ORG-001` |

## Caveats and limitations

- **`DET-002`** - A swapped model behind a stable endpoint is how a poisoned or unreviewed model reaches production without anyone changing application code.
- **`DET-003`** - Guardrail tampering. Loosening a confidence threshold is quieter than deleting a template and has much the same effect.
- **`DET-004`** - Budgets notify; they do not stop spend. A hard ceiling needs Vertex AI quota limits or a budget-triggered function that disables billing, and the second option has consequences worth thinking through first.
- **`ENC-002`** - The Vertex AI service agent exists only after the API is first used. On a brand-new project this binding can fail until it does; the README has the one-line gcloud command that creates it.
- **`IAM-002`** - aiplatform.endpoints.predict covers generateContent on publisher models. Applications that also embed documents, use context caching or call Vertex AI Search will need additional permissions; add them one at a time and say why in the role description.
- **`LOG-001`** - Records who called which model and when. Audit logs do not contain prompt or response bodies; capturing those is an application decision with its own privacy cost.
- **`LOG-002`** - Locked retention cannot be shortened or removed, including by project owners and including by terraform destroy. That is the point, and it is also why the examples say so twice.
- **`MA-001`** - A classifier. It reduces the volume of successful injections and catches none of the ones it has not learned to see. Treat it as a tripwire, and enforce tool authority in application code regardless.
- **`MA-002`** - Basic Sensitive Data Protection infoTypes only. Organisation-specific identifiers need an advanced_config with your own inspect template.
- **`MA-005`** - Binds at the organization in organization scope, so it applies to projects that do not exist yet. Unlike the template, it does not depend on application code calling it.
- **`NET-002`** - This is what makes an injected "send the data to this URL" instruction fail at the network even when every application-layer control has been talked past. Agents that legitimately browse the web need a separate, proxied egress path, not a hole in this rule.
- **`ORG-001`** - Governs Model Garden models only, not models registered in Vertex AI Model Registry, per Google's documentation. A self-uploaded model is outside this control and needs its own review gate.
- **`ORG-002`** - Constrains where resources are created. Where a request to a global model endpoint is processed is a separate choice made in application code by calling a regional endpoint.
- **`ORG-003`** - Only created when enable_cmek is true, because requiring CMEK without a key to use would block every Vertex AI resource.
- **`ORG-005`** - Affects projects created after the policy is set. Existing default service accounts keep any Editor grant they already have.
- **`VSC-001`** - Organization scope only. In the standard profile the perimeter is dry-run: it logs violations and blocks nothing. That is the correct first state and it is not protection. Promote to strict after the violation log is quiet.

## Framework notes

- The OWASP LLM Top 10 describes application risks, most of which live in code this repo cannot see: prompt construction, tool design, output handling. A control here maps to an OWASP category when it reduces the likelihood or blast radius of that risk at the platform layer. None of them closes an OWASP category on its own.
- NIST AI RMF subcategories are mapped only where infrastructure produces the evidence the subcategory asks for (security evaluated, behaviour monitored in production, privacy risk addressed, third-party risk governed). GOVERN, MAP and most of MEASURE are organisational practice and do not appear, by design rather than by omission.
- Every mapping in this matrix is authored by one practitioner and reviewed by nobody with authority. It is a defensible starting point for a control narrative, not an assessment.
- Nothing here has been applied against a real Google Cloud organization or project. The matrix proves that claimed controls resolve to real Terraform addresses. It does not prove they work.
