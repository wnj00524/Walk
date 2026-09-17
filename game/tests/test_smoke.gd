## Purpose: Holds the smoke-suite assertion for the current minimal project shell.
## Why: The first suite must prove that the runner executes a real assertion against the game.
## Reads: The main scene path supplied by the runner.
## Writes: Nothing; returning a message marks the assertion as failed.
## Safe changes: Add independent foundation checks as the project grows.
## Failure: Returns a plain-language message when the expected project resource is absent.
extends RefCounted

static func main_scene_exists(scene_path: String) -> String:
	if not ResourceLoader.exists(scene_path):
		return "Expected scene does not exist: %s" % scene_path
	return ""
