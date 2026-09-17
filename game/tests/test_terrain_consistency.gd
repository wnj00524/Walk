## Purpose: Guards accepted terrain samples, shared edges, repeat generation, and seed identity.
## Why: A future terrain change must not move an existing place or introduce boundary seams.
## Reads: Independently pinned terrain_samples.json and the public ChunkTerrain surface API.
## Writes: Temporary in-memory ChunkTerrain nodes only; no world or save data.
## Safe changes: Add independently reviewed coordinates/tolerances; never generate expectations at runtime.
## Failure: A non-empty result names the changed sample, edge, or identity invariant.
extends RefCounted

const ChunkTerrainType = preload("res://src/terrain/chunk_terrain.gd")
const FIXTURE_PATH := "res://tests/fixtures/terrain_samples.json"

static func pinned_surface_samples() -> String:
	var fixture: Dictionary = _load_fixture()
	var terrain := _new_terrain(42)
	terrain.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var tolerance := float(fixture.tolerance_m)
	for row: Dictionary in fixture.samples:
		var position: WorldPosition = WorldPosition.from_cells(int(row.cell_x), int(row.cell_z), float(row.local_x_m), float(row.local_z_m), 0.0).position
		var sample: Dictionary = terrain.query_surface(position)
		if sample.get("status") != "READY":
			_free_terrain(terrain)
			return "%s was not READY: %s" % [row.name, sample]
		var delta: float = abs(float(sample.height_m) - float(row.height_m))
		if delta > tolerance:
			_free_terrain(terrain)
			return "%s changed by %.6f m" % [row.name, delta]
	_free_terrain(terrain)
	return ""

static func shared_boundary_samples() -> String:
	var terrain := _new_terrain(42)
	terrain.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var west: Dictionary = terrain.query_surface(WorldPosition.from_cells(0, 0, 255.999, 64.0, 0.0).position)
	var east: Dictionary = terrain.query_surface(WorldPosition.from_cells(1, 0, 0.0, 64.0, 0.0).position)
	if west.get("status") != "READY" or east.get("status") != "READY":
		_free_terrain(terrain)
		return "shared boundary was not READY from both logical paths"
	var delta: float = abs(float(west.height_m) - float(east.height_m))
	_free_terrain(terrain)
	return "shared boundary changed by %.6f m" % delta if delta > 0.01 else ""

static func repeat_generation_is_stable() -> String:
	var first := _new_terrain(42)
	first.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var first_sample: Dictionary = first.query_surface(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	_free_terrain(first)
	var second := _new_terrain(42)
	second.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var second_sample: Dictionary = second.query_surface(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var delta: float = abs(float(first_sample.height_m) - float(second_sample.height_m))
	_free_terrain(second)
	return "repeat generation changed by %.6f m" % delta if delta > 0.0001 else ""

static func changed_seed_changes_surface() -> String:
	var terrain := _new_terrain(43)
	terrain.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var sample: Dictionary = terrain.query_surface(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var expected: float = float(_load_fixture().samples[0].height_m)
	var delta: float = abs(float(sample.height_m) - expected)
	_free_terrain(terrain)
	return "changed seed did not change the pinned surface" if delta <= 0.01 else ""

static func _new_terrain(seed_value: int) -> Node:
	var terrain := ChunkTerrainType.new()
	var holder := Node3D.new()
	holder.add_child(terrain)
	terrain.set_meta("test_holder", holder)
	var result: Dictionary = terrain.configure({"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": str(seed_value)}, {"synchronous_generation": true})
	if result.get("status") != "READY":
		return terrain
	return terrain

static func _free_terrain(terrain: Node) -> void:
	var holder: Node = terrain.get_meta("test_holder")
	terrain.shutdown()
	holder.free()

static func _load_fixture() -> Dictionary:
	var file := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
	var parser := JSON.new()
	parser.parse(file.get_as_text())
	file.close()
	return parser.data
