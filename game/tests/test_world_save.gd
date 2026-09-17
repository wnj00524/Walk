## Purpose: Tests C05 save round-trips, integer-string handling, and safe rejection.
## Why: Persistence must restore identity exactly and never replace corrupt input silently.
## Reads: WorldSave and WorldPosition helpers; writes only disposable user save fixtures.
## Safe changes: Add independent malformed-document cases without deriving expected values.
## Failure: A non-empty result explains the first persistence mismatch.
extends RefCounted

const WorldSaveType = preload("res://src/persistence/world_save.gd")
const SAVE_PATH := "user://t013_world_save.json"
const INVALID_PATH := "user://t013_invalid_save.json"
const UNSUPPORTED_PATH := "user://t013_unsupported_save.json"

static func round_trip_example() -> String:
	_cleanup()
	var identity: Dictionary = WorldSaveType.default_identity()
	var position: WorldPosition = WorldPosition.from_cells(-1, 0, 255.75, 12.0, 18.5).position
	var result: Dictionary = WorldSaveType.save_file(SAVE_PATH, identity, position, {"yaw_rad": 0.25, "pitch_rad": -0.1})
	if result.get("status") != "READY":
		return "example save failed: %s" % result
	var loaded: Dictionary = WorldSaveType.load_file(SAVE_PATH)
	if loaded.get("status") != "READY":
		return "example load failed: %s" % loaded
	var data: Dictionary = loaded.data
	if data.world_seed != "42" or data.position.cell_x != "-1" or not is_equal_approx(float(data.position.local_x_m), 255.75):
		return "example round-trip changed identity or negative cell"
	_cleanup()
	return ""

static func round_trip_large_cell() -> String:
	_cleanup()
	var position: WorldPosition = WorldPosition.from_cells(9223372036854770000, -9223372036854770000, 1.5, 254.5, 2.0).position
	var result: Dictionary = WorldSaveType.save_file(SAVE_PATH, WorldSaveType.default_identity(), position, {"yaw_rad": 1.0, "pitch_rad": 0.5})
	if result.get("status") != "READY":
		return "large-cell save failed: %s" % result
	var loaded: Dictionary = WorldSaveType.load_file(SAVE_PATH)
	if loaded.get("status") != "READY":
		return "large-cell load failed: %s" % loaded
	var data: Dictionary = loaded.data
	if data.position.cell_x != "9223372036854770000" or data.position.cell_z != "-9223372036854770000":
		return "large cell was not preserved as decimal strings"
	_cleanup()
	return ""

static func rejects_unsupported_and_corrupt_without_replacing() -> String:
	_cleanup()
	var corrupt_text := "{not valid json"
	_write_text(INVALID_PATH, corrupt_text)
	var corrupt_result: Dictionary = WorldSaveType.load_file(INVALID_PATH)
	if corrupt_result.get("status") != "ERROR" or _read_text(INVALID_PATH) != corrupt_text:
		return "corrupt save was not rejected and preserved"
	var unsupported_text := JSON.stringify({"schema_version": 99, "generator_version": "g1", "content_version": "c1", "world_seed": "42", "position": {}, "view": {}})
	_write_text(UNSUPPORTED_PATH, unsupported_text)
	var unsupported_result: Dictionary = WorldSaveType.load_file(UNSUPPORTED_PATH)
	if unsupported_result.get("status") != "ERROR" or _read_text(UNSUPPORTED_PATH) != unsupported_text:
		return "unsupported save was not rejected and preserved"
	_cleanup()
	return ""

static func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

static func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	return text

static func _cleanup() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".tmp", SAVE_PATH + ".bak", INVALID_PATH, UNSUPPORTED_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
