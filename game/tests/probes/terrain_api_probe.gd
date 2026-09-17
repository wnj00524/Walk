## Purpose: Probes the pinned Voxel Tools extension without creating a game world.
## Why: Later terrain work must use names and operations proven by this exact binary.
## Reads: Registered native classes and their reflected methods/properties.
## Writes: A concise API result to standard output; it does not save terrain data.
## Safe changes: Add a guarded probe for an API needed by a later terrain task.
## Failure: A missing class, construction error, or failed operation is reported and
##          causes a nonzero process exit rather than being treated as support.
extends SceneTree

const REQUIRED_CLASSES: Array[String] = [
	"VoxelGeneratorGraph",
	"VoxelGeneratorNoise",
	"VoxelViewer",
	"VoxelTerrain",
	"VoxelLodTerrain"
]

var _failures: Array[String] = []
var _operations := 0
var _passed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("Voxel Tools API probe")
	print("godot=%s" % Engine.get_version_info().string)
	for class_name_to_probe: String in REQUIRED_CLASSES:
		_probe_class(class_name_to_probe)
	_probe_related_classes()
	_probe_noise_generator()
	_probe_generator_graph()
	_probe_viewer_and_collision_access()
	print("Probe: operations=%d passed=%d failed=%d" % [_operations, _passed, _failures.size()])
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)

func _probe_class(class_name_to_probe: String) -> void:
	_operations += 1
	if not ClassDB.class_exists(class_name_to_probe):
		_failures.append("class missing: %s" % class_name_to_probe)
		return
	var methods: Array[String] = []
	for method_info: Dictionary in ClassDB.class_get_method_list(class_name_to_probe):
		methods.append(String(method_info.get("name", "")))
	var properties: Array[String] = []
	for property_info: Dictionary in ClassDB.class_get_property_list(class_name_to_probe):
		properties.append(String(property_info.get("name", "")))
	print("class=%s methods=%s properties=%s" % [class_name_to_probe, methods, properties])
	var instance: Object = ClassDB.instantiate(class_name_to_probe)
	if instance == null:
		_failures.append("construction failed: %s" % class_name_to_probe)
		return
	_passed += 1
	if instance is Node:
		(instance as Node).free()

func _probe_generator_graph() -> void:
	_operations += 1
	var graph: Object = ClassDB.instantiate("VoxelGeneratorGraph")
	if graph == null:
		_failures.append("graph construction failed")
		return
	var methods := _method_names("VoxelGeneratorGraph")
	var required := ["compile", "generate_block", "set_sdf_clip_threshold"]
	for method_name: String in required:
		if not methods.has(method_name):
			_failures.append("graph method missing: %s" % method_name)
	if methods.has("compile") and methods.has("generate_block") and methods.has("set_sdf_clip_threshold"):
		graph.call("set_sdf_clip_threshold", 0.0)
		_passed += 1
		print("graph_operations=available set_sdf_clip_threshold(0.0)/compile/generate_block")
	if graph is Node:
		(graph as Node).free()

func _probe_related_classes() -> void:
	var related: Array[String] = []
	for class_name_to_probe: String in ClassDB.get_class_list():
		if class_name_to_probe.begins_with("VoxelGraph") or class_name_to_probe.begins_with("VoxelMesher"):
			related.append(class_name_to_probe)
	print("related_classes=%s" % [related])

func _probe_noise_generator() -> void:
	_operations += 1
	var generator: Object = ClassDB.instantiate("VoxelGeneratorNoise")
	if generator == null:
		_failures.append("noise generator construction failed")
		return
	var noise: Object = ClassDB.instantiate("FastNoiseLite")
	if noise == null:
		_failures.append("FastNoiseLite construction failed")
	else:
		generator.set("noise", noise)
		generator.set("height_start", -32)
		generator.set("height_range", 64)
		_passed += 1
		print("noise_configuration=available noise/height_start/height_range")

func _probe_viewer_and_collision_access() -> void:
	_operations += 1
	var viewer_methods := _method_names("VoxelViewer")
	var terrain_methods := _method_names("VoxelTerrain")
	var lod_methods := _method_names("VoxelLodTerrain")
	var viewer_access := _first_present(viewer_methods, ["set_view_distance", "set_view_distance_margin"])
	var collision_access := _first_present(lod_methods, ["set_generate_collisions", "set_collision_lod_count"])
	var diagnostic_access := _first_present(terrain_methods, ["get_statistics", "get_stats"])
	print("viewer_access=%s collision_access=%s diagnostic_access=%s" % [viewer_access, collision_access, diagnostic_access])
	if viewer_access.is_empty():
		_failures.append("viewer distance operation unavailable")
	if collision_access.is_empty():
		_failures.append("collision configuration operation unavailable")
	if diagnostic_access.is_empty():
		_failures.append("terrain diagnostic operation unavailable")
	var viewer: Object = ClassDB.instantiate("VoxelViewer")
	var lod_terrain: Object = ClassDB.instantiate("VoxelLodTerrain")
	var terrain: Object = ClassDB.instantiate("VoxelTerrain")
	if viewer == null or lod_terrain == null or terrain == null:
		_failures.append("viewer or terrain construction failed")
		return
	viewer.call("set_view_distance", 256)
	viewer.call("set_requires_collisions", true)
	lod_terrain.call("set_generate_collisions", true)
	lod_terrain.call("set_collision_lod_count", 1)
	var statistics: Variant = terrain.call("get_statistics")
	print("configuration_calls=viewer_distance=256 requires_collisions=true collision_lod_count=1 statistics=%s" % [statistics])
	if viewer_access and collision_access and diagnostic_access:
		_passed += 1
	if viewer is Node:
		(viewer as Node).free()
	if lod_terrain is Node:
		(lod_terrain as Node).free()
	if terrain is Node:
		(terrain as Node).free()

func _method_names(class_name_to_probe: String) -> Array[String]:
	var names: Array[String] = []
	for method_info: Dictionary in ClassDB.class_get_method_list(class_name_to_probe):
		names.append(String(method_info.get("name", "")))
	return names

func _first_present(methods: Array[String], candidates: Array[String]) -> String:
	for candidate: String in candidates:
		if methods.has(candidate):
			return candidate
	return ""
