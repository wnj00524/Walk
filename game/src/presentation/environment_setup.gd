## Purpose: Loads the reviewed visual preset and builds the shared daylight objects.
## Why: Terrain and vegetation should use one restrained palette without editor-only setup.
## Reads: res://data/visual_preset.json, containing bounded colour and lighting values.
## Writes: StandardMaterial3D and WorldEnvironment/DirectionalLight3D objects in memory.
## Safe changes: Preset ranges are validated; tune the JSON within those ranges only.
## Failure: Invalid JSON, colours, scales, or lighting values return ERROR or null objects.
class_name EnvironmentSetup
extends RefCounted

const PRESET_PATH := "res://data/visual_preset.json"

static func load_preset(path: String = PRESET_PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "ERROR", "error": "visual preset could not be opened"}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not (parser.data is Dictionary):
		return {"status": "ERROR", "error": "visual preset is not a JSON object"}
	var error := validate_preset(parser.data)
	if not error.is_empty():
		return {"status": "ERROR", "error": error}
	return {"status": "READY", "preset": parser.data}

static func validate_preset(preset: Dictionary) -> String:
	if int(preset.get("schema_version", 0)) != 1:
		return "visual preset schema_version must be 1"
	if String(preset.get("preset_id", "")).is_empty():
		return "visual preset needs a preset_id"
	var terrain: Variant = preset.get("terrain", null)
	var daylight: Variant = preset.get("daylight", null)
	if not (terrain is Dictionary) or not (daylight is Dictionary):
		return "visual preset needs terrain and daylight objects"
	var terrain_error := _validate_color(terrain.get("albedo_color", null), "terrain.albedo_color")
	if not terrain_error.is_empty():
		return terrain_error
	if not _in_range(float(terrain.get("roughness", NAN)), 0.0, 1.0):
		return "terrain.roughness must be between 0 and 1"
	if not _in_range(float(terrain.get("texture_scale", NAN)), 0.1, 64.0):
		return "terrain.texture_scale must be between 0.1 and 64 UV repeats"
	for field in ["background_color", "ambient_color", "light_color", "fog_color"]:
		var color_error := _validate_color(daylight.get(field, null), "daylight.%s" % field)
		if not color_error.is_empty():
			return color_error
	if not _in_range(float(daylight.get("ambient_energy", NAN)), 0.0, 2.0):
		return "daylight.ambient_energy must be between 0 and 2"
	if not _in_range(float(daylight.get("light_intensity", NAN)), 0.1, 4.0):
		return "daylight.light_intensity must be between 0.1 and 4"
	if not (daylight.get("shadow_enabled", null) is bool) or not (daylight.get("fog_enabled", null) is bool):
		return "daylight shadow_enabled and fog_enabled must be booleans"
	if not _in_range(float(daylight.get("fog_density", NAN)), 0.0, 0.1):
		return "daylight.fog_density must be between 0 and 0.1"
	return ""

static func create_terrain_material(preset: Dictionary) -> StandardMaterial3D:
	if not validate_preset(preset).is_empty():
		return null
	var terrain: Dictionary = preset.terrain
	var material := StandardMaterial3D.new()
	material.albedo_color = _color_from_array(terrain.albedo_color)
	material.roughness = float(terrain.roughness)
	material.uv1_scale = Vector3.ONE * float(terrain.texture_scale)
	return material

static func create_environment(preset: Dictionary) -> WorldEnvironment:
	if not validate_preset(preset).is_empty():
		return null
	var daylight: Dictionary = preset.daylight
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = _color_from_array(daylight.background_color)
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = _color_from_array(daylight.ambient_color)
	resource.ambient_light_energy = float(daylight.ambient_energy)
	resource.fog_enabled = bool(daylight.fog_enabled)
	resource.fog_light_color = _color_from_array(daylight.fog_color)
	resource.fog_density = float(daylight.fog_density)
	var environment := WorldEnvironment.new()
	environment.name = "TemperateDaylight"
	environment.environment = resource
	return environment

static func create_sun(preset: Dictionary) -> DirectionalLight3D:
	if not validate_preset(preset).is_empty():
		return null
	var daylight: Dictionary = preset.daylight
	var sun := DirectionalLight3D.new()
	sun.name = "TemperateSun"
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_color = _color_from_array(daylight.light_color)
	sun.light_energy = float(daylight.light_intensity)
	sun.shadow_enabled = bool(daylight.shadow_enabled)
	return sun

static func _validate_color(value: Variant, field: String) -> String:
	if not (value is Array) or value.size() != 4:
		return "%s must contain four colour components" % field
	for component: Variant in value:
		if not _in_range(float(component), 0.0, 1.0):
			return "%s components must be between 0 and 1" % field
	return ""

static func _in_range(value: float, minimum: float, maximum: float) -> bool:
	return is_finite(value) and value >= minimum and value <= maximum

static func _color_from_array(value: Array) -> Color:
	return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
