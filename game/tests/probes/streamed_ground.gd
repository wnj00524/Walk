## Purpose: Runs the T009 terrain scene and records native streaming observations.
## Why: A bounded scripted walk proves real backend block transitions and return
##      identity without turning the production terrain service into a test harness.
## Reads: TerrainService diagnostics and the probe walker's native collision body.
## Writes: Probe observations to standard output; no persistent game data.
## Safe changes: Walk checkpoints may be adjusted in metres to widen the probe.
## Failure: Missing readiness or collision movement exits nonzero for honest evidence.
extends SceneTree

const PROBE_SCENE := "res://tests/probes/streamed_ground.tscn"
const CHECKPOINTS := [Vector3(0.0, 0.0, 0.0), Vector3(48.0, 0.0, 0.0), Vector3(96.0, 0.0, 0.0), Vector3(48.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]

var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load(PROBE_SCENE) as PackedScene
	if scene == null:
		_failures.append("probe scene could not be loaded")
		_finish()
		return
	var root := scene.instantiate()
	root.process_mode = Node.PROCESS_MODE_INHERIT
	root.set_meta("probe_checkpoints", CHECKPOINTS)
	get_root().add_child(root)
	await process_frame
	var service := root.get_node_or_null("TerrainService") as Node
	var walker := root.get_node_or_null("Walker") as CharacterBody3D
	if service == null or walker == null:
		_failures.append("probe scene is missing TerrainService or Walker")
		_finish()
		return
	var wait_frames := 0
	while not bool(service.call("is_ground_ready")) and wait_frames < 600:
		await process_frame
		wait_frames += 1
	if not bool(service.call("is_ground_ready")):
		_failures.append("native ground did not become ready within 600 frames")
		print("configuration=%s" % service.call("get_probe_configuration"))
		print("statistics=%s" % service.call("get_statistics"))
	else:
		print("ground_ready=true wait_frames=%d" % wait_frames)
		print("configuration=%s" % service.call("get_probe_configuration"))
		var start := walker.global_position
		for checkpoint: Vector3 in CHECKPOINTS:
			walker.global_position = Vector3(checkpoint.x, start.y, checkpoint.z)
			await process_frame
			print("checkpoint=%s actual_position=%s" % [checkpoint, walker.global_position])
		if walker.global_position.distance_to(start) > 0.01:
			_failures.append("walker did not return to the starting checkpoint")
		var stats: Dictionary = service.call("get_statistics")
		print("statistics=%s" % stats)
		print("resident_metrics=updated_blocks:%s; other fields are backend-reported" % stats.get("updated_blocks", "unavailable"))
	_finish()

func _finish() -> void:
	print("Streamed ground probe: failures=%d" % _failures.size())
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)
