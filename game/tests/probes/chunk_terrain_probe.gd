## Purpose: Exercises ChunkTerrain streaming and logical identity across recenterings.
## Why: The backend gate needs a reproducible headless proof independent of the main scene.
## Reads: ChunkTerrain's C03 methods and WorldPosition's C01 constructors.
## Writes: Temporary terrain nodes in memory and probe results to standard output.
## Safe changes: Add independent assertions; keep the three recentering checkpoints intact.
## Failure: Any timeout, wrong state, or height discontinuity exits with code 1.
extends SceneTree

const ChunkTerrainType = preload("res://src/terrain/chunk_terrain.gd")
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var terrain := ChunkTerrainType.new()
	root.add_child(terrain)
	var identity := {"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": "42"}
	var result := terrain.configure(identity, {})
	_assert(result.get("status") == "READY", "configure failed: %s" % result)
	var position_result := WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0)
	var sample_position: WorldPosition = position_result.position
	var current_position: WorldPosition = sample_position
	terrain.update_viewer(current_position)
	if not await _wait_until_ready(terrain, sample_position):
		_failures.append("initial chunk did not become READY within 300 frames")
	var initial_sample: Dictionary = terrain.query_surface(sample_position)
	var previous_height: float = float(initial_sample.get("height_m", 0.0))
	for recentering in range(3):
		current_position = WorldPosition.from_cells(1 if recentering % 2 == 0 else 0, 0, 0.0, 128.0, 0.0).position
		terrain.update_viewer(current_position)
		if not await _wait_until_ready(terrain, sample_position):
			_failures.append("recentring %d did not become READY within 300 frames" % (recentering + 1))
			break
		var sample: Dictionary = terrain.query_surface(sample_position)
		_assert(sample.get("status") == "READY", "recentring %d query was not READY" % (recentering + 1))
		var height: float = float(sample.get("height_m", 0.0))
		var delta: float = abs(height - previous_height)
		print("recentring=%d height_delta=%.6f" % [recentering + 1, delta])
		_assert(delta <= 0.01, "recentring %d changed height by %.6f m" % [recentering + 1, delta])
		previous_height = height
	var outside: WorldPosition = WorldPosition.from_cells(10, 0, 0.0, 0.0, 0.0).position
	_assert(terrain.get_ground_state(outside) == "OUTSIDE_TESTED_SUPPORT", "outside support state was not returned")
	terrain.shutdown()
	print("Chunk terrain probe: failures=%d" % _failures.size())
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)

func _wait_until_ready(terrain: Node, position: WorldPosition) -> bool:
	for _frame in range(300):
		if terrain.get_ground_state(position) == "READY":
			return true
		await process_frame
	return false

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

static func registered_identity_check(recentering_count: int) -> String:
	var holder := Node3D.new()
	var terrain := ChunkTerrainType.new()
	holder.add_child(terrain)
	var identity := {"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": "42"}
	var configured := terrain.configure(identity, {"synchronous_generation": true})
	if configured.get("status") != "READY":
		return "configure failed: %s" % configured
	var sample_position: WorldPosition = WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position
	var previous_height := 0.0
	for index in range(recentering_count + 1):
		var viewer_cell := 0 if index % 2 == 0 else 1
		terrain.update_viewer(WorldPosition.from_cells(viewer_cell, 0, 0.0, 128.0, 0.0).position)
		var sample: Dictionary = terrain.query_surface(sample_position)
		if sample.get("status") != "READY":
			return "sample was not READY after recentering %d: %s" % [index, sample]
		var height := float(sample.height_m)
		if index > 0 and abs(height - previous_height) > 0.01:
			return "height changed by %.6f m at recentering %d" % [abs(height - previous_height), index]
		previous_height = height
	terrain.shutdown()
	holder.free()
	return ""

static func identity_check_one() -> String:
	return registered_identity_check(1)

static func identity_check_two() -> String:
	return registered_identity_check(2)

static func identity_check_three() -> String:
	return registered_identity_check(3)
