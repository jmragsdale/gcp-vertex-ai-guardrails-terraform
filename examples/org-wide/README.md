# Organization example (strict profile)

Apply in stages, not all at once. The order avoids the two classic bad
afternoons: an enforced perimeter that breaks CI, and a model allowlist that
blocks the model production is already using.

1. **Audit first.** `enable_audit_logging` and `enable_detection` only. You
   want the evidence trail before you change anything it would record.
2. **Model allowlist in dry run.** Before enforcing ORG-001, list which models
   are actually being called (Data Access logs from step 1 show this) and make
   sure every one of them is either on the list or on purpose off it.
3. **Identity and keys.** `enable_identity`, `enable_cmek`. Move the
   application to the new service account before removing whatever it used.
4. **Network.** `enable_network`. Anything that needed the internet will now
   fail, which is the point; route legitimate egress through a proxy.
5. **Model Armor.** Template first, then the floor setting. Watch the findings
   for a week before trusting the confidence threshold.
6. **Perimeter.** Deploy with the `standard` profile (dry-run), read the
   violation logs until they are quiet, then switch to `strict` to enforce.

Replace every placeholder ID. None of them are real.
