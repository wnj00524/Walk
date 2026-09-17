## Purpose: Owns the native streamed terrain used by the T009 probe.
## Why: Keeping Voxel Tools calls here prevents the player and presentation layers
##      from depending on backend-specific nodes or guessed surface heights.
## Reads: A world seed and bounded probe settings exported by the scene.
## Writes: Native VoxelTerrain/VoxelViewer nodes and diagnostic state in memory only.
## Safe changes: Noise height/range and view distance are probe settings in metres;
##                keep collision enabled and do not add a second terrain generator.
## Failure: Invalid settings leave the service not ready and report a readable error.
class_name TerrainService
extends Node3D

signal ground_ready

const STATUS_READY := "READY"
const STATUS_PENDING := "PENDING"
const STATUS_ERROR := "ERROR"

@export var world_seed: int = 42
@export_range(32.0, 512.0, 16.0, "or_greater") var view_distance_m: float = 96.0
@export var height_start_m: float = -16.0
@export var height_range_m: float = 64.0
@export_range(1, 8, 1) var collision_lod_count: int = 1

var _terrain: VoxelLodTerrain
var _viewer: VoxelViewer
var _statistics: Dictionary = {}
var _configuration_error := ""
var _ground_is_ready := false
var _last_ready_position := Vector3.ZERO

func _ready() -> void:
	_configuration_error = _configure_native_terrain()
	if not _configuration_error.is_empty():
		push_error("TerrainService disabled: %s" % _configuration_error)
		return
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _terrain == null:
		return
	var walker := get_parent().get_node_or_null("Walker") as Node3D
	if walker != null:
		_viewer.global_position = walker.global_position
	_statistics = _terrain.get_statistics()
	if not _ground_is_ready and int(_statistics.get("updated_blocks", 0)) > 0:
		_ground_is_ready = true
		_last_ready_position = _viewer.global_position
		ground_ready.emit()

func is_ground_ready() -> bool:
	## True only after the native backend has meshed at least one block.
	return _ground_is_ready and _configuration_error.is_empty()

func query_ground(_world_position: Vector3) -> Dictionary:
	## Reports readiness without inventing a height before collision data exists.
	if not _configuration_error.is_empty():
		return {"status": STATUS_ERROR, "error": _configuration_error}
	if not is_ground_ready():
		return {"status": STATUS_PENDING}
	return {"status": STATUS_READY, "statistics": _statistics.duplicate(true)}

func get_statistics() -> Dictionary:
	## Returns the last native diagnostic snapshot; fields are backend-owned.
	return _statistics.duplicate(true)

func get_probe_configuration() -> Dictionary:
	return {
		"world_seed": world_seed,
		"view_distance_m": view_distance_m,
		"height_start_m": height_start_m,
		"height_range_m": height_range_m,
		"collision_lod_count": collision_lod_count,
		"collision_enabled": _terrain != null and _terrain.get_generate_collisions(),
		"native_class": "VoxelLodTerrain + VoxelGeneratorNoise + VoxelMesherTransvoxel + VoxelViewer",
	}

func _configure_native_terrain() -> String:
	if not is_finite(view_distance_m) or view_distance_m <= 0.0:
		return "view distance must be a finite positive number of metres"
	if not is_finite(height_start_m) or not is_finite(height_range_m) or height_range_m <= 0.0:
		return "height start and range must be finite, with a positive range in metres"
	if collision_lod_count < 1:
		return "collision LOD count must be at least one"

	_terrain = VoxelLodTerrain.new()
	_terrain.name = "StreamedVoxelTerrain"
	_terrain.set_view_distance(view_distance_m)
	_terrain.set_lod_count(4)
	_terrain.set_generate_collisions(true)
	_terrain.set_collision_layer(1)
	_terrain.set_collision_mask(1)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.38, 0.24, 1.0)
	material.roughness = 0.95
	_terrain.set_material(material)
	var generator := VoxelGeneratorNoise.new()
	var noise := FastNoiseLite.new()
	noise.seed = world_seed
	noise.frequency = 0.006
	generator.set_noise(noise)
	generator.set_height_start(height_start_m)
	generator.set_height_range(height_range_m)
	_terrain.set_generator(generator)
	var mesher := VoxelMesherTransvoxel.new()
	_terrain.set_mesher(mesher)
	add_child(_terrain)

	_viewer = get_parent().get_node_or_null("Walker/Camera3D/TerrainViewer") as VoxelViewer
	if _viewer == null:
		_viewer = VoxelViewer.new()
		_viewer.name = "TerrainViewer"
		var camera := get_parent().get_node_or_null("Walker/Camera3D") as Camera3D
		if camera == null:
			return "probe scene must provide a Walker/Camera3D path for the native viewer"
		camera.add_child(_viewer)
	_viewer.set_view_distance(view_distance_m)
	_viewer.set_requires_visuals(true)
	_viewer.set_requires_collisions(true)
	return ""
