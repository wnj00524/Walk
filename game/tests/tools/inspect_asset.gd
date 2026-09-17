## Purpose: Loads one imported GLB in the labelled review fixture and reports real meshes.
## Why: Godot's importer, rather than a hand-authored scene, must be the final import check.
## Reads: A GLB path supplied after `--`; writes: counts and bounds to standard output.
## Safe changes: Keep this fixture-only and do not add runtime asset-service calls.
## Failure: Missing or non-mesh resources cause a non-zero test result.
extends SceneTree

func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.is_empty():
		push_error("inspect_asset requires a GLB path")
		quit(1)
		return
	var scene_resource := load(arguments[0])
	if not scene_resource is PackedScene:
		push_error("GLB did not import as a PackedScene")
		quit(1)
		return
	var instance := (scene_resource as PackedScene).instantiate()
	var mesh_count := 0
	var bounds := AABB()
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		mesh_count += 1
		bounds = bounds.merge(mesh_node.get_aabb())
	if mesh_count == 0:
		push_error("imported scene contains no mesh instances")
		quit(1)
		return
	print(JSON.stringify({"mesh_instances": mesh_count, "bounds_min": bounds.position, "bounds_size": bounds.size, "blender_dependency": false}))
	quit(0)
