Review <TASK_ID> in a fresh pass. Read AGENTS.md, the card, the changed source, the actual diff and docs/evidence/<TASK_ID>.md. Do not accept the implementation agent's summary as proof.

Check scope, interfaces, independent assertions, negative cases, actual commands/test counts, source comments and plain-English walkthrough. Re-run available checks. Distinguish unavailable hardware/live service checks from success. Check that no credentials, unsupported fallbacks, weakened tests, unapproved spend or duplicated terrain logic were introduced.

For a probe, distinguish a completed investigation from backend acceptance. For visual/audio/release gates, require the owner's explicit decision on the actual build/evidence.

Return concrete findings with files and required fixes. Only when every required acceptance item is supported, promote the PLAN row to DONE and record the review. Otherwise use BLOCKED or leave REVIEW with named corrections according to coordinator ownership. Do not repair a broad set of unrelated code while reviewing.
