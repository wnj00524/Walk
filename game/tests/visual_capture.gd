## Purpose: Captures fixed real-renderer views of terrain and approved vegetation.
## Why: Repeatable poses let reviewers compare grounded content without manual camera setup.
## Reads: visual_route.json, the C02 identity, ChunkTerrain, and VegetationBatches.
## Writes: Named PNGs and capture_report.json under the requested artifacts directory.
## Safe changes: Tune route poses with the reviewed JSON; keep the route and report metadata complete.
## Failure: Headless rendering, missing terrain readiness, or save failure exits nonzero.
extends Node3D

const ChunkTerrainType = preload("res://src/terrain/chunk_terrain.gd")
const VegetationBatchesType = preload("res://src/presentation/vegetation_batches.gd")
const ROUTE_PATH := "res://tests/visual_route.json"
var _output_dir := ""
var _terrain: Node
var _vegetation: Node
var _camera: Camera3D
var _route: Dictionary

func _ready() -> void:
	_output_dir = _argument_value("--output-dir", "")
	if _output_dir.is_empty() or DisplayServer.get_name().to_lower() == "headless":
		push_error("NOT RUN: a real display is required for visual capture")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_output_dir)
	_route = _load_route()
	_setup_world()
	call_deferred("_capture_route")

func _setup_world() -> void:
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color(0.48, 0.64, 0.78, 1.0)
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color(0.65, 0.75, 0.82, 1.0)
	environment_resource.ambient_light_energy = 0.8
	environment.environment = environment_resource
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.8, 1.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.current = true
	_terrain = ChunkTerrainType.new()
	add_child(_terrain)
	var identity := {"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": "42"}
	var configured: Dictionary = _terrain.configure(identity, _route.get("recipe", {}))
	if configured.get("status") != "READY":
		push_error("terrain configuration failed: %s" % configured)
		get_tree().quit(1)
		return
	_terrain.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var vegetation := VegetationBatchesType.new()
	add_child(vegetation)
	_vegetation = vegetation
	var vegetation_configured := vegetation.configure_from_files(identity, _terrain)
	if vegetation_configured.get("status") != "READY":
		push_error("vegetation configuration failed: %s" % vegetation_configured)
		get_tree().quit(1)
		return

func _capture_route() -> void:
	for _frame in range(300):
		if _terrain.get_ground_state(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position) == "READY":
			break
		await get_tree().process_frame
	if _terrain.get_ground_state(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position) != "READY":
		push_error("terrain did not become READY within 300 frames")
		get_tree().quit(1)
		return
	_vegetation.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var report := {
		"godot_version": Engine.get_version_info().string,
		"display_server": DisplayServer.get_name(),
		"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"world_seed": _route.get("world_seed", ""),
		"generator_version": _route.get("generator_version", ""),
		"content_version": _route.get("content_version", ""),
		"recipe": _route.get("recipe", {}),
		"vegetation": _vegetation.get_diagnostics(),
		"poses": [],
	}
	for pose: Dictionary in _route.get("poses", []):
		var camera_position := _vector_from_array(pose.position)
		var target := _vector_from_array(pose.target)
		_camera.look_at_from_position(camera_position, target)
		for _frame in range(15):
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var image_path := _output_dir.path_join("%s.png" % pose.name)
		if image.save_png(image_path) != OK:
			push_error("could not save %s" % image_path)
			get_tree().quit(1)
			return
		report.poses.append({"name": pose.name, "position": pose.position, "target": pose.target, "path": image_path})
	var report_file := FileAccess.open(_output_dir.path_join("capture_report.json"), FileAccess.WRITE)
	if report_file == null:
		push_error("could not write capture report")
		get_tree().quit(1)
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()
	print("captured=%d renderer=%s adapter=%s" % [report.poses.size(), report.renderer, report.video_adapter])
	get_tree().quit(0)

func _load_route() -> Dictionary:
	var file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	var parser := JSON.new()
	parser.parse(file.get_as_text())
	file.close()
	return parser.data

func _vector_from_array(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _argument_value(argument: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == argument:
			return args[index + 1]
	return fallback
