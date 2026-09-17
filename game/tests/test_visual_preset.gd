## Purpose: Proves the visual preset rejects unsafe values and creates shared objects.
## Why: Material scale and daylight controls must fail clearly before visual review.
## Reads: visual_preset.json and in-memory invalid variants.
## Writes: Temporary StandardMaterial3D, WorldEnvironment, and DirectionalLight3D objects.
## Safe changes: Add independent invalid cases when the preset schema gains a field.
## Failure: Returns a message when validation accepts a bad value or omits an object.
extends RefCounted

const EnvironmentSetupType = preload("res://src/presentation/environment_setup.gd")

static func loads_reviewed_preset() -> String:
	var result := EnvironmentSetupType.load_preset()
	return "reviewed preset did not load: %s" % result if result.get("status") != "READY" else ""

static func rejects_invalid_texture_scale() -> String:
	var preset := _preset()
	preset.terrain.texture_scale = 0.0
	return "zero texture scale was accepted" if EnvironmentSetupType.validate_preset(preset).is_empty() else ""

static func rejects_invalid_light_intensity() -> String:
	var preset := _preset()
	preset.daylight.light_intensity = 4.1
	return "excessive light intensity was accepted" if EnvironmentSetupType.validate_preset(preset).is_empty() else ""

static func rejects_invalid_fog_density() -> String:
	var preset := _preset()
	preset.daylight.fog_density = -0.1
	return "negative fog density was accepted" if EnvironmentSetupType.validate_preset(preset).is_empty() else ""

static func creates_consistent_material_and_daylight() -> String:
	var preset := _preset()
	var material := EnvironmentSetupType.create_terrain_material(preset)
	var environment := EnvironmentSetupType.create_environment(preset)
	var sun := EnvironmentSetupType.create_sun(preset)
	if material == null or environment == null or sun == null:
		return "valid preset did not create all visual objects"
	if not is_equal_approx(material.uv1_scale.x, 6.0) or not is_equal_approx(sun.light_energy, 0.78):
		return "preset controls did not reach the created objects"
	environment.environment = null
	environment.free()
	sun.free()
	return ""

static func _preset() -> Dictionary:
	var result := EnvironmentSetupType.load_preset()
	return result.preset.duplicate(true)
