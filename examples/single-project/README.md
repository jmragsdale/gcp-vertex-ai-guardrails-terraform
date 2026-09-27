# Single-project example

Plans the guardrails against one project, no organization required.

```bash
terraform init && terraform plan
```

What this posture can and cannot demonstrate is spelled out at the top of
`main.tf`. The short version: it demonstrates the controls; the organization
posture enforces them, including on projects that do not exist yet.

`enable_audit_logging` is off on purpose. It creates a retention-locked log
bucket, and locked retention outlives `terraform destroy`.
