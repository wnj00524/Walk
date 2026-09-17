## Purpose: Provides an explicitly opt-in broken check for verifying harness failure handling.
## Why: A test runner is trustworthy only when a known failure produces a failing process.
## Reads: Nothing.
## Writes: Nothing; this fixture always returns a failure message.
## Safe changes: Keep this fixture intentionally broken and isolated from normal suites.
## Failure: Always reports the expected self-test failure.
extends RefCounted

static func always_fails() -> String:
	return "intentional self-test failure"
