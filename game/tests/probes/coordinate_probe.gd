## Purpose: Measures logical-coordinate and native-generator behaviour at bounded
##          large distances before a world-origin strategy is chosen.
## Why: A floating-point teleport is not evidence that terrain identity survives
##      recentering, so this probe compares the same samples on both sides.
## Reads: WorldPosition, TerrainService diagnostics, and the native collision body.
## Writes: Probe observations to standard output; no persistent game data.
## Safe changes: Test distances and tolerances may be adjusted when evidence needs
##                to cover a different bounded envelope.
## Failure: Missing scene/service, changed logical samples, or unsafe precision is
##          reported and exits nonzero; unavailable native collision stays explicit.
extends SceneTree

const PROBE_SCENE := "res://tests/probes/coordinate_probe.tscn"
const DISTANCES_M := [0.0, 100_000.0, -100_000.0, 1_000_000.0, -1_000_000.0, 100_000.03125, -100_000.03125, 1_000_000.03125, -1_000_000.03125]
const RECENTER_BOUNDARY_M := 100_000.0
const RECENTER_CROSSINGS_M := [99_999.0, 100_001.0, 99_999.0, 100_001.0, 99_999.0]
const HEIGHT_TOLERANCE_M := 0.0001
const POSITION_TOLERANCE_M := 0.01

var _failures: Array[String] = []
var _observations: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load(PROBE_SCENE) as PackedScene
	if scene == null:
		_failures.append("coordinate probe scene could not be loaded")
		_finish()
		return
	var root := scene.instantiate()
	get_root().add_child(root)
	await process_frame
	var service := root.get_node_or_null("TerrainService") as Node
	var walker := root.get_node_or_null("Walker") as CharacterBody3D
	if service == null or walker == null:
		_failures.append("probe scene is missing TerrainService or Walker")
		_finish()
		return

	print("coordinate_probe distances_m=%s recenter_boundary_m=%s" % [DISTANCES_M, RECENTER_BOUNDARY_M])
	for distance_m: float in DISTANCES_M:
		_record_distance(service, walker, distance_m)

	_record_boundary_crossings(service)
	await _record_recenter_candidate(service, walker)
	print("native_collision_observation=service_ready=%s statistics=%s" % [service.call("is_ground_ready"), service.call("get_statistics")])
	print("observations=%s" % [_observations])
	print("Coordinate probe: failures=%d" % _failures.size())
	for failure: String in _failures:
		push_error(failure)
	_finish()

func _record_distance(service: Node, walker: CharacterBody3D, distance_m: float) -> void:
	var logical := WorldPosition.try_from_world_meters(distance_m, distance_m, 0.0)
	var position := logical["position"] as WorldPosition
	var visual := Vector3(distance_m, 0.0, distance_m)
	var x_precision_error := absf(float(visual.x) - distance_m)
	var z_precision_error := absf(float(visual.z) - distance_m)
	var sample := service.call("sample_probe_height", distance_m, distance_m) as Dictionary
	var observation := {
		"distance_m": distance_m,
		"logical": position.to_save_dictionary(),
		"vector3_precision_error_m": maxf(x_precision_error, z_precision_error),
		"native_sample": sample,
	}
	_observations.append(observation)
	print("distance=%s logical=%s vector3_precision_error_m=%.6f native_sample=%s" % [distance_m, position.to_save_dictionary(), maxf(x_precision_error, z_precision_error), sample])
	if maxf(x_precision_error, z_precision_error) > POSITION_TOLERANCE_M:
		_failures.append("Vector3 precision exceeded tolerance at %s m" % distance_m)
	if sample.get("status") == TerrainService.STATUS_ERROR:
		_failures.append("native sample failed at %s m: %s" % [distance_m, sample.get("error", "unknown error")])

func _record_recenter_candidate(service: Node, walker: CharacterBody3D) -> void:
	var logical_sample := service.call("sample_probe_height", RECENTER_BOUNDARY_M, RECENTER_BOUNDARY_M) as Dictionary
	var before_position := Vector3(RECENTER_BOUNDARY_M, walker.global_position.y, RECENTER_BOUNDARY_M)
	walker.global_position = before_position
	await process_frame
	var before_contact := walker.global_position
	var recentered_visual := Vector3.ZERO
	walker.global_position = Vector3(recentered_visual.x, before_position.y, recentered_visual.z)
	await process_frame
	var after_contact := walker.global_position
	var after_sample := service.call("sample_probe_height", recentered_visual.x, recentered_visual.z) as Dictionary
	var sample_delta := absf(float(logical_sample.get("height_m", NAN)) - float(after_sample.get("height_m", NAN)))
	_observations.append({
		"candidate": "local-origin-recenter-without-native-generator-offset",
		"logical_sample": logical_sample,
		"recentered_visual_sample": after_sample,
		"sample_delta_m": sample_delta,
		"contact_position_before_handoff": before_contact,
		"contact_position_after_handoff": after_contact,
		"collision_ready": bool(service.call("is_ground_ready")),
	})
	print("recenter_candidate=logical=%s visual=%s sample_delta_m=%.6f collision_ready=%s" % [logical_sample, after_sample, sample_delta, service.call("is_ground_ready")])
	if sample_delta <= HEIGHT_TOLERANCE_M:
		_failures.append("recenter candidate unexpectedly preserved a sample without a native generator offset")
	if not bool(service.call("is_ground_ready")):
		print("collision_observation=NOT_RUN native ground was not ready")

func _record_boundary_crossings(service: Node) -> void:
	var previous_sample := NAN
	for distance_m: float in RECENTER_CROSSINGS_M:
		var sample := service.call("sample_probe_height", distance_m, distance_m) as Dictionary
		var logical := WorldPosition.try_from_world_meters(distance_m, distance_m, 0.0)["position"] as WorldPosition
		var sample_height := float(sample.get("height_m", NAN))
		print("boundary_crossing distance=%s logical=%s sample_height_m=%.6f delta_from_previous_m=%.6f" % [distance_m, logical.to_save_dictionary(), sample_height, absf(sample_height - previous_sample) if is_finite(previous_sample) else 0.0])
		_observations.append({
			"boundary_crossing_m": distance_m,
			"logical": logical.to_save_dictionary(),
			"native_sample": sample,
		})
		previous_sample = sample_height

func _finish() -> void:
	quit(0 if _failures.is_empty() else 1)
