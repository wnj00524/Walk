## Purpose: Runs the small offline Godot checks used while the walking experience is built.
## Why: A named suite makes a passing check, a broken check, and an empty selection
##      distinguishable before a larger test framework is justified.
## Reads: Godot's user arguments after `--`, plus the registered test callables.
## Writes: Human-readable counts to standard output and a nonzero process exit on failure.
## Safe changes: Add focused suites and assertions; keep exit-code meanings stable.
## Failure: Unknown or empty suites, failed assertions, and unexpected errors fail the run.
extends SceneTree

const TEST_MAIN_SCENE := "res://scenes/main.tscn"
const SmokeChecks = preload("res://tests/test_smoke.gd")
const FailureChecks = preload("res://tests/test_harness_failure.gd")
const PlayerChecks = preload("res://tests/test_player.gd")
const WorldPositionChecks = preload("res://tests/test_world_position.gd")
const WorldChoiceChecks = preload("res://tests/test_world_choices.gd")
const ChunkTerrainProbe = preload("res://tests/probes/chunk_terrain_probe.gd")
const WorldSaveChecks = preload("res://tests/test_world_save.gd")
const TerrainConsistencyChecks = preload("res://tests/test_terrain_consistency.gd")
const LandformRecipeChecks = preload("res://tests/test_landform_recipe.gd")
const PlacementRulesChecks = preload("res://tests/test_placement_rules.gd")
const VegetationBatchesChecks = preload("res://tests/test_vegetation_batches.gd")
const VisualPresetChecks = preload("res://tests/test_visual_preset.gd")

var _executed := 0
var _passed := 0
var _failed := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var options := _parse_arguments(OS.get_cmdline_user_args())
	if options.get("self_test", "") == "failure":
		_run_suite("failure", [Callable(FailureChecks, "always_fails")])
	else:
		var suite_name: String = options.get("suite", "")
		var suites: Dictionary = {
			"smoke": [Callable(SmokeChecks, "main_scene_exists").bind(TEST_MAIN_SCENE)],
			"player": [
				Callable(PlayerChecks, "settings_are_validated"),
				Callable(PlayerChecks, "pitch_is_bounded"),
				Callable(PlayerChecks, "motion_scales_with_elapsed_time")
			],
			"coordinates": [
				Callable(WorldPositionChecks, "frozen_coordinate_vectors"),
				Callable(WorldPositionChecks, "repeated_boundary_crossings"),
				Callable(WorldPositionChecks, "rejects_non_finite_input"),
				Callable(WorldPositionChecks, "rejects_invalid_offsets")
			],
			"deterministic": [
				Callable(WorldChoiceChecks, "frozen_seed_vectors"),
				Callable(WorldChoiceChecks, "order_independence"),
				Callable(WorldChoiceChecks, "rejects_non_canonical_inputs")
			],
			"chunk_terrain": [
				Callable(ChunkTerrainProbe, "identity_check_one"),
				Callable(ChunkTerrainProbe, "identity_check_two"),
				Callable(ChunkTerrainProbe, "identity_check_three")
			],
			"save": [
				Callable(WorldSaveChecks, "round_trip_example"),
				Callable(WorldSaveChecks, "round_trip_large_cell"),
				Callable(WorldSaveChecks, "rejects_unsupported_and_corrupt_without_replacing")
			],
			"terrain": [
				Callable(TerrainConsistencyChecks, "pinned_surface_samples"),
				Callable(TerrainConsistencyChecks, "shared_boundary_samples"),
				Callable(TerrainConsistencyChecks, "repeat_generation_is_stable"),
				Callable(TerrainConsistencyChecks, "changed_seed_changes_surface")
			],
			"landform": [
				Callable(LandformRecipeChecks, "loads_valid_recipe"),
				Callable(LandformRecipeChecks, "rejects_invalid_parameters"),
				Callable(LandformRecipeChecks, "configures_chunk_terrain"),
				Callable(LandformRecipeChecks, "fixed_seed_shape_is_reproducible")
			],
			"placement": [
				Callable(PlacementRulesChecks, "loads_valid_habitats"),
				Callable(PlacementRulesChecks, "records_are_stable_and_sorted"),
				Callable(PlacementRulesChecks, "reversed_cell_load_order_is_stable"),
				Callable(PlacementRulesChecks, "neighboring_cells_have_disjoint_owners"),
				Callable(PlacementRulesChecks, "rejects_missing_assets"),
				Callable(PlacementRulesChecks, "defers_unready_terrain"),
				Callable(PlacementRulesChecks, "habitat_visual_budget_is_bounded")
			],
			"vegetation": [
				Callable(VegetationBatchesChecks, "creates_and_reuses_batches"),
				Callable(VegetationBatchesChecks, "releases_distant_batches_within_bound"),
				Callable(VegetationBatchesChecks, "rejects_stale_batches"),
				Callable(VegetationBatchesChecks, "rejects_invalid_records_without_fallback"),
				Callable(VegetationBatchesChecks, "renders_approved_runtime_assets")
			],
			"visual_preset": [
				Callable(VisualPresetChecks, "loads_reviewed_preset"),
				Callable(VisualPresetChecks, "rejects_invalid_texture_scale"),
				Callable(VisualPresetChecks, "rejects_invalid_light_intensity"),
				Callable(VisualPresetChecks, "rejects_invalid_fog_density"),
				Callable(VisualPresetChecks, "creates_consistent_material_and_daylight")
			]
		}
		if not suites.has(suite_name):
			_record_failure("Unknown suite: '%s'. Available suites: smoke, player, coordinates, deterministic, chunk_terrain, save, terrain, landform, placement, vegetation." % suite_name)
		else:
			_run_suite(suite_name, suites[suite_name])
	_finish()

func _parse_arguments(arguments: PackedStringArray) -> Dictionary:
	var options := {"suite": "", "self_test": ""}
	var index := 0
	while index < arguments.size():
		if arguments[index] == "--suite" and index + 1 < arguments.size():
			options["suite"] = arguments[index + 1]
			index += 2
		elif arguments[index] == "--self-test" and index + 1 < arguments.size():
			options["self_test"] = arguments[index + 1]
			index += 2
		else:
			index += 1
	return options

func _run_suite(suite_name: String, tests: Array) -> void:
	if tests.is_empty():
		_record_failure("Suite '%s' selected no tests." % suite_name)
		return
	for test: Callable in tests:
		_executed += 1
		if not test.is_valid():
			_failed += 1
			_failures.append("Invalid test callable.")
			continue
		var result: Variant = test.call()
		if result == null:
			_failed += 1
			_failures.append("Test returned no result.")
		elif not (result is String):
			_failed += 1
			_failures.append("Test returned an unsupported result.")
		elif not (result as String).is_empty():
			_failed += 1
			_failures.append("%s: %s" % [test.get_method(), result])
		else:
			_passed += 1

func _record_failure(message: String) -> void:
	_failed += 1
	_failures.append(message)

func _finish() -> void:
	print("Tests: executed=%d passed=%d failed=%d" % [_executed, _passed, _failed])
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failed == 0 and _executed > 0 else 1)
