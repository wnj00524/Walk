## Purpose: Represents a walker's logical horizontal location at any supported distance.
## Why: Integer 256-metre cells keep map identity separate from renderer coordinates,
##      so crossing either side of the origin cannot be confused with a scene position.
## Reads: Signed cell numbers, metre offsets within a cell, and finite vertical height.
## Writes: A normalised logical location only; this file never creates or moves nodes.
## Safe changes: Keep CELL_WIDTH_M and the field units aligned with C01 and the save contract.
## Failure: try_from_world_meters returns a readable error for non-finite input or bad offsets.
class_name WorldPosition
extends RefCounted

const CELL_WIDTH_M: float = 256.0
const MAX_CELL: int = 9223372036854775807
const MIN_CELL: int = -9223372036854775808

var cell_x: int
var cell_z: int
var local_x_m: float
var local_z_m: float
var y_m: float

func _init(
	cell_x_value: int,
	cell_z_value: int,
	local_x_value_m: float,
	local_z_value_m: float,
	y_value_m: float
) -> void:
	cell_x = cell_x_value
	cell_z = cell_z_value
	local_x_m = local_x_value_m
	local_z_m = local_z_value_m
	y_m = y_value_m

static func try_from_world_meters(x_m: float, z_m: float, height_m: float) -> Dictionary:
	## Normalises metres into floor-based cells; negative values remain in [0, 256).
	## Returns {"position": WorldPosition, "error": String}; no position is returned on failure.
	if not is_finite(x_m) or not is_finite(z_m) or not is_finite(height_m):
		return {"position": null, "error": "world coordinates and height must be finite metres"}
	var x_parts := _split_axis(x_m)
	var z_parts := _split_axis(z_m)
	return {
		"position": WorldPosition.new(x_parts["cell"], z_parts["cell"], x_parts["local_m"], z_parts["local_m"], height_m),
		"error": ""
	}

static func from_cells(cell_x_value: int, cell_z_value: int, local_x_value_m: float, local_z_value_m: float, height_m: float) -> Dictionary:
	## Validates an already-cell-based location, including the [0, 256) offset rule.
	if cell_x_value < MIN_CELL or cell_x_value > MAX_CELL or cell_z_value < MIN_CELL or cell_z_value > MAX_CELL:
		return {"position": null, "error": "cell coordinates are outside signed 64-bit range"}
	if not is_finite(local_x_value_m) or not is_finite(local_z_value_m) or not is_finite(height_m):
		return {"position": null, "error": "local offsets and height must be finite metres"}
	if local_x_value_m < 0.0 or local_x_value_m >= CELL_WIDTH_M or local_z_value_m < 0.0 or local_z_value_m >= CELL_WIDTH_M:
		return {"position": null, "error": "local offsets must be in [0, 256) metres"}
	return {"position": WorldPosition.new(cell_x_value, cell_z_value, local_x_value_m, local_z_value_m, height_m), "error": ""}

func to_save_dictionary() -> Dictionary:
	## Uses decimal strings for cells so JSON readers cannot round large integers.
	return {
		"cell_x": str(cell_x),
		"cell_z": str(cell_z),
		"local_x_m": local_x_m,
		"local_z_m": local_z_m,
		"y_m": y_m,
	}

static func _split_axis(axis_m: float) -> Dictionary:
	## floor, rather than truncation toward zero, assigns -0.25 m to cell -1 at 255.75 m.
	var cell := int(floor(axis_m / CELL_WIDTH_M))
	var local_m := axis_m - float(cell) * CELL_WIDTH_M
	if is_equal_approx(local_m, CELL_WIDTH_M):
		cell += 1
		local_m = 0.0
	return {"cell": cell, "local_m": local_m}
