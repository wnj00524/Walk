## Purpose: Validates and loads the one authored heightmap recipe used by terrain.
## Why: A named recipe keeps landscape shape, density, and metre units reproducible.
## Reads: JSON recipe dictionaries from res:// or test-provided dictionaries.
## Writes: Validated dictionaries for ChunkTerrain; it never creates terrain nodes.
## Safe changes: Tune the single recipe's frequency and vertical range within the
##                documented limits; keep chunk size aligned with WorldPosition.
## Failure: Returns a readable error string instead of silently using bad defaults.
class_name LandformRecipe
extends RefCounted

const RECIPE_PATH := "res://data/landform_recipe.json"
const SCHEMA_VERSION := 1
const CHUNK_SIZE_M := 256.0
const MIN_FREQUENCY := 0.0005
const MAX_FREQUENCY := 0.02
const MIN_HEIGHT_RANGE_M := 1.0
const MAX_HEIGHT_RANGE_M := 200.0

static func load_default() -> Dictionary:
	var file := FileAccess.open(RECIPE_PATH, FileAccess.READ)
	if file == null:
		return {"recipe": {}, "error": "could not open %s" % RECIPE_PATH}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not (parser.data is Dictionary):
		return {"recipe": {}, "error": "landform recipe is not valid JSON"}
	var recipe: Dictionary = parser.data
	var validation_error := validate(recipe)
	return {"recipe": recipe, "error": validation_error}

static func validate(recipe: Dictionary) -> String:
	if int(recipe.get("schema_version", -1)) != SCHEMA_VERSION:
		return "schema_version must be %d" % SCHEMA_VERSION
	if String(recipe.get("recipe_id", "")).is_empty():
		return "recipe_id must not be empty"
	var chunk_size := float(recipe.get("chunk_size_m", NAN))
	if not is_finite(chunk_size) or not is_equal_approx(chunk_size, CHUNK_SIZE_M):
		return "chunk_size_m must be 256 finite metres"
	var view_chunks := int(recipe.get("view_chunks", 0))
	if view_chunks < 3 or view_chunks % 2 == 0:
		return "view_chunks must be an odd ring size of at least 3"
	var vertices := int(recipe.get("vertices_per_side", 0))
	if vertices < 2 or vertices > 128:
		return "vertices_per_side must be in [2, 128]"
	var frequency := float(recipe.get("frequency", NAN))
	if not is_finite(frequency) or frequency < MIN_FREQUENCY or frequency > MAX_FREQUENCY:
		return "frequency must be finite and in [%.4f, %.2f] cycles per metre" % [MIN_FREQUENCY, MAX_FREQUENCY]
	var height_start := float(recipe.get("height_start_m", NAN))
	if not is_finite(height_start):
		return "height_start_m must be finite metres"
	var height_range := float(recipe.get("height_range_m", NAN))
	if not is_finite(height_range) or height_range < MIN_HEIGHT_RANGE_M or height_range > MAX_HEIGHT_RANGE_M:
		return "height_range_m must be finite and in [%.1f, %.1f] metres" % [MIN_HEIGHT_RANGE_M, MAX_HEIGHT_RANGE_M]
	return ""

static func to_chunk_configuration(recipe: Dictionary) -> Dictionary:
	var error := validate(recipe)
	if not error.is_empty():
		return {"configuration": {}, "error": error}
	return {"configuration": recipe.duplicate(true), "error": ""}
