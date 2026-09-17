## Purpose: Reads and writes the versioned C05 world identity, position, and view.
## Why: A small explicit envelope lets restart resume the same world without re-seeding.
## Reads: C02 identity, C01 WorldPosition values, and finite yaw/pitch in radians.
## Writes: A JSON save plus temporary/backup files in the caller-selected path.
## Safe changes: Extend the schema only through a migration task; keep cell integers as strings.
## Failure: Invalid input or corrupt/unsupported files returns ERROR without replacing the source.
class_name WorldSave
extends RefCounted

const SCHEMA_VERSION := 1
const GENERATOR_VERSION := "g1"
const CONTENT_VERSION := "c1"
const MAX_SEED := 2147483647
const MIN_CELL := -9223372036854775808
const MAX_CELL := 9223372036854775807

static func default_identity() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"generator_version": GENERATOR_VERSION,
		"content_version": CONTENT_VERSION,
		"world_seed": "42",
	}

static func save_file(path: String, identity: Dictionary, position: WorldPosition, view: Dictionary) -> Dictionary:
	var document_result := _make_document(identity, position, view)
	if document_result.get("status") != "READY":
		return document_result
	var target := _global_path(path)
	var temporary := target + ".tmp"
	var backup := target + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _error("could not open temporary save: %s" % FileAccess.get_open_error())
	file.store_string(JSON.stringify(document_result.document, "\t"))
	file.flush()
	file.close()
	var had_original := FileAccess.file_exists(target)
	if had_original:
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		var copy_error := DirAccess.copy_absolute(target, backup)
		if copy_error != OK:
			DirAccess.remove_absolute(temporary)
			return _error("could not preserve the existing save: %s" % copy_error)
		var remove_error := DirAccess.remove_absolute(target)
		if remove_error != OK:
			DirAccess.remove_absolute(temporary)
			return _error("could not replace the existing save: %s" % remove_error)
	var rename_error := DirAccess.rename_absolute(temporary, target)
	if rename_error != OK:
		if had_original:
			DirAccess.copy_absolute(backup, target)
		DirAccess.remove_absolute(temporary)
		return _error("could not install the new save: %s" % rename_error)
	return {"status": "READY", "path": path}

static func load_file(path: String) -> Dictionary:
	var target := _global_path(path)
	if not FileAccess.file_exists(target):
		return {"status": "MISSING", "path": path}
	var file := FileAccess.open(target, FileAccess.READ)
	if file == null:
		return _error("could not open save: %s" % FileAccess.get_open_error())
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return _error("save is not valid JSON: %s" % parser.get_error_message())
	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		return _error("save is not valid JSON object text")
	var validation := _validate_document(parsed as Dictionary)
	if validation.get("status") != "READY":
		return validation
	return {"status": "READY", "data": parsed}

static func _make_document(identity: Dictionary, position: WorldPosition, view: Dictionary) -> Dictionary:
	var identity_error := _validate_identity(identity)
	if not identity_error.is_empty():
		return _error(identity_error)
	if position == null:
		return _error("position is required")
	var position_result := WorldPosition.from_cells(position.cell_x, position.cell_z, position.local_x_m, position.local_z_m, position.y_m)
	if not String(position_result.get("error", "")).is_empty():
		return _error(String(position_result.error))
	if not view.has("yaw_rad") or not view.has("pitch_rad"):
		return _error("view must contain yaw_rad and pitch_rad")
	var yaw := float(view.yaw_rad)
	var pitch := float(view.pitch_rad)
	if not is_finite(yaw) or not is_finite(pitch):
		return _error("view angles must be finite radians")
	return {
		"status": "READY",
		"document": {
			"schema_version": SCHEMA_VERSION,
			"generator_version": GENERATOR_VERSION,
			"content_version": CONTENT_VERSION,
			"world_seed": String(identity.world_seed),
			"position": position.to_save_dictionary(),
			"view": {"yaw_rad": yaw, "pitch_rad": pitch},
		}
	}

static func _validate_document(document: Dictionary) -> Dictionary:
	for field in ["schema_version", "generator_version", "content_version", "world_seed", "position", "view"]:
		if not document.has(field):
			return _error("save is missing %s" % field)
	if int(document.schema_version) != SCHEMA_VERSION or String(document.generator_version) != GENERATOR_VERSION or String(document.content_version) != CONTENT_VERSION:
		return _error("save version is unsupported")
	var identity := {
		"schema_version": document.schema_version,
		"generator_version": document.generator_version,
		"content_version": document.content_version,
		"world_seed": document.world_seed,
	}
	var identity_error := _validate_identity(identity)
	if not identity_error.is_empty():
		return _error(identity_error)
	var position: Variant = document.position
	if not (position is Dictionary):
		return _error("position must be an object")
	for field in ["cell_x", "cell_z", "local_x_m", "local_z_m", "y_m"]:
		if not position.has(field):
			return _error("position is missing %s" % field)
	var cell_error := _validate_cell_string(String(position.cell_x))
	if not cell_error.is_empty():
		return _error(cell_error)
	cell_error = _validate_cell_string(String(position.cell_z))
	if not cell_error.is_empty():
		return _error(cell_error)
	var position_result := WorldPosition.from_cells(int(position.cell_x), int(position.cell_z), float(position.local_x_m), float(position.local_z_m), float(position.y_m))
	if not String(position_result.get("error", "")).is_empty():
		return _error(String(position_result.error))
	var view: Variant = document.view
	if not (view is Dictionary) or not view.has("yaw_rad") or not view.has("pitch_rad"):
		return _error("view must contain yaw_rad and pitch_rad")
	if not is_finite(float(view.yaw_rad)) or not is_finite(float(view.pitch_rad)):
		return _error("view angles must be finite radians")
	return {"status": "READY"}

static func _validate_identity(identity: Dictionary) -> String:
	for field in ["schema_version", "generator_version", "content_version", "world_seed"]:
		if not identity.has(field):
			return "identity is missing %s" % field
	if int(identity.schema_version) != SCHEMA_VERSION or String(identity.generator_version) != GENERATOR_VERSION or String(identity.content_version) != CONTENT_VERSION:
		return "identity version is unsupported"
	var seed := String(identity.world_seed)
	if not _is_canonical_unsigned(seed) or int(seed) > MAX_SEED:
		return "world_seed must be a canonical unsigned decimal seed"
	return ""

static func _validate_cell_string(value: String) -> String:
	var cell_pattern := RegEx.new()
	cell_pattern.compile("^-?(0|[1-9][0-9]*)$")
	if cell_pattern.search(value) == null:
		return "cell coordinates must be decimal strings"
	if not value.is_valid_int():
		return "cell coordinate is not an integer"
	var parsed := int(value)
	if parsed < MIN_CELL or parsed > MAX_CELL:
		return "cell coordinate is outside signed 64-bit range"
	return ""

static func _is_canonical_unsigned(value: String) -> bool:
	var seed_pattern := RegEx.new()
	seed_pattern.compile("^(0|[1-9][0-9]*)$")
	return seed_pattern.search(value) != null

static func _global_path(path: String) -> String:
	return ProjectSettings.globalize_path(path)

static func _error(message: String) -> Dictionary:
	return {"status": "ERROR", "error": message}
