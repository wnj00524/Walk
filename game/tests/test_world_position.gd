## Purpose: Locks down C01's cell boundaries and invalid-input behavior.
## Why: The frozen vectors independently define expected negative and positive locations.
## Reads: res://../fixtures/coordinate_vectors.json through Godot's test-only file path.
## Writes: Nothing; each check returns an explanation or an empty string on success.
## Safe changes: Add independent vectors and failure cases; do not derive expected values from WorldPosition.
## Failure: A non-empty return identifies the first coordinate contract mismatch.
extends RefCounted

static func frozen_coordinate_vectors() -> String:
	var file := FileAccess.open("res://../fixtures/coordinate_vectors.json", FileAccess.READ)
	if file == null:
		return "could not open frozen coordinate vectors"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("vectors"):
		return "coordinate fixture is not a vector document"
	for vector: Variant in (parsed as Dictionary)["vectors"]:
		var example := vector as Dictionary
		var result := WorldPosition.try_from_world_meters(float(example["world_axis_m"]), 0.0, 0.0)
		if not (result["error"] as String).is_empty():
			return "fixture value was rejected: %s" % example["world_axis_m"]
		var position := result["position"] as WorldPosition
		if str(position.cell_x) != str(example["expected_cell"]):
			return "cell mismatch for %s m: got %s" % [example["world_axis_m"], position.cell_x]
		if not is_equal_approx(position.local_x_m, float(example["expected_local_m"])):
			return "local mismatch for %s m: got %s" % [example["world_axis_m"], position.local_x_m]
	return ""

static func repeated_boundary_crossings() -> String:
	var result := WorldPosition.try_from_world_meters(256.0, -256.0, 4.0)
	if not (result["error"] as String).is_empty():
		return result["error"]
	var position := result["position"] as WorldPosition
	if position.cell_x != 1 or position.local_x_m != 0.0 or position.cell_z != -1 or position.local_z_m != 0.0:
		return "exact boundary did not enter the adjacent signed cells"
	for crossing: int in range(-3, 4):
		var negative := WorldPosition.try_from_world_meters(float(crossing) * 256.0 - 0.125, 0.0, 0.0)
		var negative_position := negative["position"] as WorldPosition
		if negative_position.local_x_m < 0.0 or negative_position.local_x_m >= WorldPosition.CELL_WIDTH_M:
			return "negative crossing escaped the local offset range"
	return ""

static func rejects_non_finite_input() -> String:
	for invalid: float in [INF, -INF, NAN]:
		var result := WorldPosition.try_from_world_meters(invalid, 0.0, 0.0)
		if (result["error"] as String).is_empty() or result["position"] != null:
			return "non-finite horizontal input was accepted"
		result = WorldPosition.try_from_world_meters(0.0, 0.0, invalid)
		if (result["error"] as String).is_empty() or result["position"] != null:
			return "non-finite height was accepted"
	return ""

static func rejects_invalid_offsets() -> String:
	for offset: float in [-0.001, WorldPosition.CELL_WIDTH_M, INF, NAN]:
		var result := WorldPosition.from_cells(0, 0, offset, 0.0, 0.0)
		if (result["error"] as String).is_empty() or result["position"] != null:
			return "invalid local offset was accepted: %s" % offset
	return ""
