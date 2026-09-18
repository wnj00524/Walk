## Purpose: Loads one imported GLB in the labelled review fixture and reports real meshes.
## Why: Godot's importer, rather than a hand-authored scene, must be the final import check.
## Reads: A GLB path supplied after `--`; writes: counts and bounds to standard output.
## Safe changes: Keep this fixture-only and do not add runtime asset-service calls.
## Failure: Missing or non-mesh resources cause a non-zero test result.
extends Node3D

var _root: Node

func _ready() -> void:
	_root = get_tree().root
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("inspect_asset requires a GLB path")
		get_tree().quit(1)
		return
	var scene_resource := load(arguments[0])
	if not scene_resource is PackedScene:
		push_error("GLB did not import as a PackedScene")
		get_tree().quit(1)
		return
	var instance := (scene_resource as PackedScene).instantiate()
	_root.call_deferred("add_child", instance)
	var camera := Camera3D.new()
	_root.call_deferred("add_child", camera)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -25.0, 0.0)
	light.light_energy = 1.2
	_root.call_deferred("add_child", light)
	var mesh_count := 0
	var material_count := 0
	var textured_material_count := 0
	var albedo_paths: Array[String] = []
	var albedo_samples: Array[String] = []
	var bounds := AABB()
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		mesh_count += 1
		for surface_index in range(mesh_node.mesh.get_surface_count()):
			var material := mesh_node.get_active_material(surface_index)
			if material != null:
				material_count += 1
			if material is BaseMaterial3D and (material as BaseMaterial3D).albedo_texture != null:
				textured_material_count += 1
				var albedo := (material as BaseMaterial3D).albedo_texture
				albedo_paths.append(albedo.resource_path)
				var albedo_image := albedo.get_image()
				albedo_samples.append(str(albedo_image.get_pixel(0, 0)) if albedo_image != null and not albedo_image.is_empty() else "<empty>")
		bounds = bounds.merge(mesh_node.get_aabb())
	if mesh_count == 0:
		push_error("imported scene contains no mesh instances")
		get_tree().quit(1)
		return
	print(JSON.stringify({"mesh_instances": mesh_count, "material_count": material_count, "textured_material_count": textured_material_count, "albedo_paths": albedo_paths, "albedo_samples": albedo_samples, "bounds_min": bounds.position, "bounds_size": bounds.size, "blender_dependency": false}))
	var output_dir := _argument_value("--output-dir", "artifacts/T019_" + arguments[0].get_file().get_basename())
	if not output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path(output_dir)
		if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
			push_error("could not create capture directory: " + output_dir)
			get_tree().quit(1)
			return
		var center := bounds.position + bounds.size * 0.5
		for view: Dictionary in [{"name": "close", "distance": 2.5}, {"name": "mid", "distance": 6.0}, {"name": "far", "distance": 14.0}]:
			camera.look_at_from_position(center + Vector3(0.0, bounds.size.y * 0.35, float(view["distance"])), center)
			for _frame in range(10):
				await get_tree().process_frame
			_root.get_viewport().get_texture().get_image().save_png(output_dir.path_join("%s.png" % view["name"]))
	get_tree().quit(0)

func _argument_value(argument: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == argument:
			return args[index + 1]
	return fallback
