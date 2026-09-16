## Purpose: Owns the minimal application's startup and shutdown behaviour.
## Why: Window-close handling belongs in application glue rather than in future world modules.
## Reads: Godot window notifications; it has no settings, saves, or network inputs.
## Writes: Requests a clean scene-tree shutdown when the user closes the window.
## Safe changes: Startup-only behaviour may be added here when an assigned task requires it.
## Failure: If this script cannot load, Godot reports the error and the main scene cannot start.
extends Control


func _notification(what: int) -> void:
	## Converts the operating system's close request into Godot's orderly shutdown path.
	## This has no return value; other notifications are intentionally ignored.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
