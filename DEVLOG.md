# Development Log - gcp-vertex-ai-guardrails-terraform

Working notes: decisions, dead ends, and the reasoning behind the shape of this repo.

## 2026-09-27 - Initial build

**Why a fourth baseline instead of a module in the GCP one.**
`gcp-compliance-baseline-terraform` answers "is this organization aligned to
FedRAMP, NIST and CIS?" This repo answers a narrower question those frameworks
barely address: "what can a generative AI workload reach when its model does
something it should not?" Different threat model, different frameworks (OWASP
LLM, NIST AI RMF), different reviewer. Same `controls.yaml` pattern, because
that pattern is what makes coverage claims falsifiable.

**The design premise: the model is not the boundary.**
Every control was chosen by asking what a fully compromised model could do
through this platform, and how to make that small. That is why egress and
identity carry as much weight as Model Armor. A classifier reduces how often
injection succeeds; the network and the role decide what success is worth.

**Why the allowlist is per action.**
`vertexai.allowedModels` takes `publishers/<p>/models/<m>:<action>`. Allowing
`:predict` and not `:tune` separates "we approved calling this model" from "we
approved training it on our data". The Rego suite warns on `:tune` so it is a
decision rather than a default, and denies bare-publisher entries outright.

**Why a custom role instead of roles/aiplatform.user.**
The predefined role also creates endpoints, deploys models and launches jobs.
An injected instruction that lands in a code path holding those rights has a
much larger blast radius than one that can only call `predict`.

**Why Model Armor is two resources.**
The template only protects callers who remember to call it. The floor setting
applies inline to every Vertex AI call in scope and binds at the organization
in org scope, so it covers projects that do not exist yet. Guardrails that
depend on developer discipline have gaps exactly where discipline lapses.

**Checking schemas instead of writing them from memory.**
Model Armor resources are recent. Before writing them I read the provider's own
documentation for `google_model_armor_template` and `google_model_armor_floorsetting`
and its changelog: template in 6.43, floor setting in 6.45, template permadiff
fixes later in the 7.x line. Hence the `~> 7.0` pin. The allowlist value format
was checked against Google's Model Garden access-control documentation, which
also states that the constraint does not govern Model Registry models; that
limitation is in the ORG-001 note rather than buried.

**Checkov CKV_GCP_43.**
Rotation period comes from `local.p`, which Checkov cannot resolve statically.
Rather than skip and move on, the encryption module validates
`var.rotation_period` against the same 90-day ceiling, so the check the scanner
cannot do is done by Terraform itself. The skip carries that reason inline.

**What is deliberately not here.**
No prompt or response logging (a privacy decision for the application), no
Vertex AI quota overrides (they vary by model and region too much to default
sensibly), and no coverage claim for OWASP LLM08 or LLM09, which no platform
control reaches.
