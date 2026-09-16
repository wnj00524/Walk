# Txxx - one visible, bounded result

```json
{
  "id": "Txxx",
  "role": "implementer",
  "depends_on": [],
  "read": ["docs/CONTRACTS.md"],
  "write": ["exact/source/file.gd", "exact/test/file.gd"]
}
```

Status lives only in PLAN.md. Replace all example paths/IDs before dispatch.

## Outcome
One sentence the owner can understand.

## Read set
Root instructions, one task, named contracts, and actual changed source. No whole-repository dump.

## Allowed changes
Explicit source/test/config paths, plus one feature walkthrough, CODE_GUIDE, evidence, PLAN row and appended DLOG row. Default five implementation/test/config files and about 300 executable changed lines; split rather than omit tests.

## Steps
Three to five concrete steps with fixed interfaces, units, expected data and error behaviour. No unresolved architecture inside an implementation task.

## Acceptance
Exact available commands, fixtures and expected results; a negative case that must fail; required GPU/Windows/owner evidence identified separately. Missing tests/tooling must be the explicit deliverable or a dependency.

## Non-goals
Name nearby tempting work that must not be done.

## Stop conditions
Name uncertainty/unsupported API/spend/scope conditions. After two focused failed fixes, hand off the actual failure.
