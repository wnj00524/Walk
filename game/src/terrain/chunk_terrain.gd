## Purpose: Streams small heightmap chunks from logical coordinates and exposes C03.
## Why: A pure-GDScript heightmap keeps noise inputs stable when the visual origin moves.
## Reads: C02 world identity, C03 recipe values, and C01 WorldPosition values.
## Writes: In-memory MeshInstance3D, StaticBody3D, and collision nodes under this service.
## Safe changes: Tune recipe defaults and material appearance; preserve logical sampling and states.
## Failure: Invalid configuration returns ERROR; stale worker results are discarded by epoch.
class_name ChunkTerrain
extends Node3D

const STATUS_READY := "READY"
const STATUS_PENDING := "PENDING"
const STATUS_OUTSIDE := "OUTSIDE_TESTED_SUPPORT"
const STATUS_ERROR := "ERROR"
const DEFAULT_FREQUENCY := 0.006
const DEFAULT_HEIGHT_START := -16.0
const DEFAULT_HEIGHT_RANGE := 64.0
const DEFAULT_VERTICES_PER_SIDE := 32

@export var world_seed: int = 42
@export var chunk_size_m: float = 256.0
@export_range(3, 9, 2) var view_chunks: int = 3
@export_range(8, 128, 1) var vertices_per_side: int = DEFAULT_VERTICES_PER_SIDE

var _configured := false
var _configuration_error := ""
var _epoch := 0
var _frequency := DEFAULT_FREQUENCY
var _height_start_m := DEFAULT_HEIGHT_START
var _height_range_m := DEFAULT_HEIGHT_RANGE
var _noise: FastNoiseLite
var _viewer_position: WorldPosition
var _visual_origin_chunk := Vector2i.ZERO
var _chunks: Dictionary = {}
var _pending_jobs: Dictionary = {}
var _synchronous_generation := false

func configure(world_identity: Dictionary, recipe: Dictionary) -> Dictionary:
	_epoch += 1
	_wait_for_pending_jobs()
	_clear_chunks()
	_pending_jobs.clear()
	_configured = false
	_configuration_error = _validate_identity(world_identity)
	if not _configuration_error.is_empty():
		return {"status": STATUS_ERROR, "error": _configuration_error}
	var seed_value := int(world_identity["world_seed"])
	var error := _validate_recipe(recipe)
	if not error.is_empty():
		_configuration_error = error
		return {"status": STATUS_ERROR, "error": error}
	world_seed = seed_value
	chunk_size_m = float(recipe.get("chunk_size_m", 256.0))
	view_chunks = int(recipe.get("view_chunks", 3))
	vertices_per_side = int(recipe.get("vertices_per_side", DEFAULT_VERTICES_PER_SIDE))
	_frequency = float(recipe.get("frequency", DEFAULT_FREQUENCY))
	_height_start_m = float(recipe.get("height_start_m", DEFAULT_HEIGHT_START))
	_height_range_m = float(recipe.get("height_range_m", DEFAULT_HEIGHT_RANGE))
	_synchronous_generation = bool(recipe.get("synchronous_generation", false))
	_noise = FastNoiseLite.new()
	_noise.seed = world_seed
	_noise.frequency = _frequency
	_configured = true
	_viewer_position = null
	return {"status": STATUS_READY}

func update_viewer(logical_position: WorldPosition) -> void:
	if not _configured:
		return
	if logical_position == null or not is_finite(logical_position.local_x_m) or not is_finite(logical_position.local_z_m):
		_configuration_error = "viewer logical position must contain finite local metres"
		_configured = false
		return
	_viewer_position = logical_position
	var chunk_x := _chunk_for_axis(logical_position.cell_x, logical_position.local_x_m)
	var chunk_z := _chunk_for_axis(logical_position.cell_z, logical_position.local_z_m)
	_visual_origin_chunk = Vector2i(chunk_x, chunk_z)
	var wanted := {}
	var radius := int(view_chunks / 2)
	for z in range(chunk_z - radius, chunk_z + radius + 1):
		for x in range(chunk_x - radius, chunk_x + radius + 1):
			var key := Vector2i(x, z)
			wanted[key] = true
			if not _chunks.has(key) and not _pending_jobs.has(key):
				_start_chunk_job(key)
	for key: Vector2i in _chunks.keys():
		if not wanted.has(key):
			_chunks[key].node.queue_free()
			_chunks.erase(key)
	_reposition_chunks()

func get_ground_state(logical_position: WorldPosition) -> String:
	if not _configured:
		return STATUS_ERROR
	var key := _key_for_position(logical_position)
	if not _is_in_support(key):
		return STATUS_OUTSIDE
	if _chunks.has(key) and bool(_chunks[key].get("collision_ready", false)):
		return STATUS_READY
	return STATUS_PENDING

func query_surface(logical_position: WorldPosition) -> Dictionary:
	var state := get_ground_state(logical_position)
	if state != STATUS_READY:
		return {"status": state}
	var x_m := _logical_axis_m(logical_position.cell_x, logical_position.local_x_m)
	var z_m := _logical_axis_m(logical_position.cell_z, logical_position.local_z_m)
	var height := _sample_height(x_m, z_m)
	var dx := _sample_height(x_m + 0.5, z_m) - _sample_height(x_m - 0.5, z_m)
	var dz := _sample_height(x_m, z_m + 0.5) - _sample_height(x_m, z_m - 0.5)
	return {"status": STATUS_READY, "height_m": height, "normal": Vector3(-dx, 1.0, -dz).normalized()}

func get_diagnostics() -> Dictionary:
	var viewer: Variant = null
	if _viewer_position != null:
		viewer = _viewer_position.to_save_dictionary()
	return {
		"epoch": _epoch,
		"last_logical_viewer_position": viewer,
		"loaded_chunk_count": _chunks.size(),
		"pending_job_count": _pending_jobs.size(),
		"configuration_error": _configuration_error,
	}

func shutdown() -> void:
	_epoch += 1
	_wait_for_pending_jobs()
	_pending_jobs.clear()
	_clear_chunks()
	_configured = false
	_configuration_error = ""
	_viewer_position = null

func _start_chunk_job(key: Vector2i) -> void:
	var job_epoch := _epoch
	if _synchronous_generation:
		_apply_chunk_result(key, job_epoch, _generate_chunk_data(key, job_epoch))
		return
	var task_id := WorkerThreadPool.add_task(_generate_chunk_job.bind(key, job_epoch), false, "chunk terrain")
	_pending_jobs[key] = {"task_id": task_id, "epoch": job_epoch}

func _generate_chunk_job(key: Vector2i, job_epoch: int) -> void:
	var result := _generate_chunk_data(key, job_epoch)
	call_deferred("_apply_chunk_result", key, job_epoch, result)

func _generate_chunk_data(key: Vector2i, job_epoch: int) -> PackedFloat32Array:
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.frequency = _frequency
	var samples := PackedFloat32Array()
	var count := vertices_per_side * vertices_per_side
	samples.resize(count)
	for z in range(vertices_per_side):
		for x in range(vertices_per_side):
			var local_x := float(x) / float(vertices_per_side - 1) * chunk_size_m
			var local_z := float(z) / float(vertices_per_side - 1) * chunk_size_m
			var logical_x := float(key.x) * chunk_size_m + local_x
			var logical_z := float(key.y) * chunk_size_m + local_z
			samples[z * vertices_per_side + x] = _height_from_noise(noise.get_noise_2d(logical_x, logical_z))
	return samples

func _wait_for_pending_jobs() -> void:
	for entry: Dictionary in _pending_jobs.values():
		WorkerThreadPool.wait_for_task_completion(int(entry.task_id))

func _apply_chunk_result(key: Vector2i, result_epoch: int, heights: PackedFloat32Array) -> void:
	if result_epoch != _epoch or not _configured:
		return
	_pending_jobs.erase(key)
	if _chunks.has(key):
		return
	var node := _build_chunk_node(key, heights)
	add_child(node)
	_chunks[key] = {"node": node, "collision_ready": true}
	_reposition_chunks()

func _build_chunk_node(key: Vector2i, heights: PackedFloat32Array) -> Node3D:
	var root := Node3D.new()
	root.name = "Chunk_%d_%d" % [key.x, key.y]
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_mesh(heights)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.38, 0.24, 1.0)
	material.roughness = 0.95
	mesh_instance.material_override = material
	root.add_child(mesh_instance)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = vertices_per_side
	shape.map_depth = vertices_per_side
	shape.set_map_data(heights)
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)
	return root

func _build_mesh(heights: PackedFloat32Array) -> ArrayMesh:
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for z in range(vertices_per_side):
		for x in range(vertices_per_side):
			var index := z * vertices_per_side + x
			var px := float(x) / float(vertices_per_side - 1) * chunk_size_m
			var pz := float(z) / float(vertices_per_side - 1) * chunk_size_m
			positions.append(Vector3(px, heights[index], pz))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / float(vertices_per_side - 1), float(z) / float(vertices_per_side - 1)))
	for z in range(vertices_per_side - 1):
		for x in range(vertices_per_side - 1):
			var top_left := z * vertices_per_side + x
			var top_right := top_left + 1
			var bottom_left := top_left + vertices_per_side
			var bottom_right := bottom_left + 1
			indices.append_array([top_left, top_right, bottom_left, top_right, bottom_right, bottom_left])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _reposition_chunks() -> void:
	for key: Vector2i in _chunks.keys():
		var node: Node3D = _chunks[key].node
		node.position = Vector3(float(key.x - _visual_origin_chunk.x) * chunk_size_m, 0.0, float(key.y - _visual_origin_chunk.y) * chunk_size_m)

func _clear_chunks() -> void:
	for entry: Dictionary in _chunks.values():
		(entry.node as Node3D).queue_free()
	_chunks.clear()

func _validate_identity(identity: Dictionary) -> String:
	for field in ["schema_version", "generator_version", "content_version", "world_seed"]:
		if not identity.has(field):
			return "world identity is missing %s" % field
	if int(identity.schema_version) != 1 or String(identity.generator_version) != "g1" or String(identity.content_version) != "c1":
		return "world identity version is unsupported"
	var seed_text := String(identity.world_seed)
	if not seed_text.is_valid_int() or int(seed_text) < 0 or int(seed_text) > 2147483647:
		return "world_seed must be a canonical unsigned 32-bit seed"
	return ""

func _validate_recipe(recipe: Dictionary) -> String:
	var size := float(recipe.get("chunk_size_m", 256.0))
	var ring := int(recipe.get("view_chunks", 3))
	var density := int(recipe.get("vertices_per_side", DEFAULT_VERTICES_PER_SIDE))
	if not is_finite(size) or size <= 0.0 or not is_equal_approx(size, 256.0):
		return "chunk_size_m must be 256 finite metres"
	if ring < 3 or ring % 2 == 0:
		return "view_chunks must be an odd ring size of at least 3"
	if density < 2:
		return "vertices_per_side must be at least 2"
	return ""

func _chunk_for_axis(cell: int, local_m: float) -> int:
	return cell + int(floor(local_m / chunk_size_m))

func _key_for_position(position: WorldPosition) -> Vector2i:
	return Vector2i(_chunk_for_axis(position.cell_x, position.local_x_m), _chunk_for_axis(position.cell_z, position.local_z_m))

func _is_in_support(key: Vector2i) -> bool:
	if _viewer_position == null:
		return false
	var viewer_key := Vector2i(_chunk_for_axis(_viewer_position.cell_x, _viewer_position.local_x_m), _chunk_for_axis(_viewer_position.cell_z, _viewer_position.local_z_m))
	var radius := int(view_chunks / 2)
	return abs(key.x - viewer_key.x) <= radius and abs(key.y - viewer_key.y) <= radius

func _logical_axis_m(cell: int, local_m: float) -> float:
	return float(cell) * WorldPosition.CELL_WIDTH_M + local_m

func _sample_height(x_m: float, z_m: float) -> float:
	return _height_from_noise(_noise.get_noise_2d(x_m, z_m))

func _height_from_noise(noise_value: float) -> float:
	return _height_start_m + (noise_value + 1.0) * 0.5 * _height_range_m
