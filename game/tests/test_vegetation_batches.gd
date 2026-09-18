## Purpose: Proves bounded vegetation batch lifecycle and stale-result safety.
## Why: Scene objects must be created, reused, and released by logical cell.
## Reads: Fixed C04 records and the renderer's public batch/diagnostic methods.
## Writes: Labelled temporary Node3D test batches only; no runtime assets or files.
## Safe changes: Add independent cells/epochs; preserve the resident cap assertion.
## Failure: A non-empty result identifies a lifecycle, bound, or stale-epoch defect.
extends RefCounted

const VegetationBatchesType = preload("res://src/presentation/vegetation_batches.gd")
const ChunkTerrainType = preload("res://src/terrain/chunk_terrain.gd")
const LandformRecipeType = preload("res://src/world/landform_recipe.gd")

static func creates_and_reuses_batches() -> String:
	var holder := Node3D.new()
	var renderer := VegetationBatchesType.new()
	holder.add_child(renderer)
	var configured := renderer.configure(_identity(), Node3D.new(), _habitats(), {})
	if configured.status != "READY":
		holder.free()
		return "configure failed: %s" % configured
	var cell := Vector2i(2, -3)
	var records: Array = [_record(cell, 12.0, 18.0)]
	var first := renderer.apply_batch(cell, records, int(configured.epoch))
	var second := renderer.apply_batch(cell, records, int(configured.epoch))
	var diagnostics := renderer.get_diagnostics()
	var batch := renderer.get_child(0) as Node3D
	var expected_origin := Vector3(512.0, 0.0, -768.0)
	holder.free()
	if first.status != "READY" or second.status != "READY":
		return "batch create/reuse failed: %s / %s" % [first, second]
	if batch == null or batch.position != expected_origin:
		return "batch world origin was %s, expected %s" % [batch.position if batch != null else "<missing>", expected_origin]
	return "batch count was not one after reuse" if diagnostics.resident_batch_count != 1 else ""

static func releases_distant_batches_within_bound() -> String:
	var holder := Node3D.new()
	var renderer := VegetationBatchesType.new()
	holder.add_child(renderer)
	var configured := renderer.configure(_identity(), Node3D.new(), _habitats(), {})
	var epoch: int = configured.epoch
	for index in range(12):
		renderer.apply_batch(Vector2i(index, 0), [_record(Vector2i(index, 0), 10.0, 10.0)], epoch)
	var diagnostics := renderer.get_diagnostics()
	holder.free()
	return "resident batches exceeded cap" if diagnostics.resident_batch_count > 9 else ""

static func rejects_stale_batches() -> String:
	var holder := Node3D.new()
	var renderer := VegetationBatchesType.new()
	holder.add_child(renderer)
	var configured := renderer.configure(_identity(), Node3D.new(), _habitats(), {})
	var stale := renderer.apply_batch(Vector2i.ZERO, [_record(Vector2i.ZERO, 1.0, 1.0)], int(configured.epoch) - 1)
	holder.free()
	return "stale batch was applied" if stale.status != "STALE" else ""

static func rejects_invalid_records_without_fallback() -> String:
	var holder := Node3D.new()
	var renderer := VegetationBatchesType.new()
	holder.add_child(renderer)
	var configured := renderer.configure(_identity(), Node3D.new(), _habitats(), {})
	var invalid := _record(Vector2i.ZERO, 256.0, 1.0)
	var result := renderer.apply_batch(Vector2i.ZERO, [invalid], int(configured.epoch))
	var diagnostics := renderer.get_diagnostics()
	holder.free()
	return "invalid record created an instance" if result.status != "READY" or diagnostics.rendered_instance_count != 0 else ""

static func renders_approved_runtime_assets() -> String:
	var holder := Node3D.new()
	var terrain := ChunkTerrainType.new()
	holder.add_child(terrain)
	var recipe: Dictionary = LandformRecipeType.load_default().recipe
	recipe["synchronous_generation"] = true
	terrain.configure(_identity(), recipe)
	terrain.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var renderer := VegetationBatchesType.new()
	holder.add_child(renderer)
	var configured := renderer.configure_from_files(_identity(), terrain)
	if configured.status != "READY":
		holder.free()
		return "runtime vegetation configuration failed: %s" % configured
	renderer.update_viewer(WorldPosition.from_cells(0, 0, 128.0, 128.0, 0.0).position)
	var diagnostics := renderer.get_diagnostics()
	terrain.shutdown()
	holder.free()
	return "approved catalogue rendered no instances: %s" % diagnostics if diagnostics.rendered_instance_count < 1 else ""

static func _record(cell: Vector2i, x_m: float, z_m: float) -> Dictionary:
	return {"stable_id": "%d:%d:test:0" % [cell.x, cell.y], "asset_id": "missing_asset", "cell_x": cell.x, "cell_z": cell.y, "local_x_m": x_m, "local_z_m": z_m, "y_m": 4.0, "yaw_rad": 0.0, "scale": 1.0, "habitat_id": "test"}

static func _identity() -> Dictionary:
	return {"schema_version": 1, "generator_version": "g1", "content_version": "c1", "world_seed": "42"}

static func _habitats() -> Array:
	return [{"habitat_id": "test", "channel": "placement_test", "density_per_cell": 1, "cluster_count": 1, "min_slope": 0.0, "max_slope": 1.0, "scale_min": 1.0, "scale_max": 1.0, "asset_ids": ["missing_asset"]}]
