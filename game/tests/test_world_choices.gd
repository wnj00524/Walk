## Purpose: Compares WorldChoices with the independent C02 seed vectors.
## Why: Expected hashes must remain fixed even if the implementation changes.
## Reads: res://../fixtures/seed_vectors.json and shuffled/reversed copies in memory.
## Writes: Nothing; each check returns an explanation or an empty string on success.
## Safe changes: Add independent invalid-input cases; never derive expected values from WorldChoices.
## Failure: A non-empty return identifies the first deterministic-choice contract mismatch.
extends RefCounted

static func frozen_seed_vectors() -> String:
	var file := FileAccess.open("res://../fixtures/seed_vectors.json", FileAccess.READ)
	if file == null:
		return "could not open frozen seed vectors"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("vectors"):
		return "seed fixture is not a vector document"
	for vector: Variant in (parsed as Dictionary)["vectors"]:
		var example := vector as Dictionary
		var result := _lookup(example)
		if not (result["error"] as String).is_empty():
			return "fixture value was rejected: %s (%s)" % [example["payload"], result["error"]]
		if result["first_u32"] != int(example["first_u32"]):
			return "first_u32 mismatch for %s" % example["payload"]
		if not is_equal_approx(float(result["unit_value"]), float(example["unit_value"])):
			return "unit value mismatch for %s" % example["payload"]
		if result["payload"] != example["payload"]:
			return "payload mismatch for %s" % example["payload"]
	return ""

static func order_independence() -> String:
	var examples := [
		["42", "tree", "0", "0", "0"],
		["42", "rock", "0", "0", "0"],
		["2147483647", "ground_cover", "3906", "-3907", "7"],
	]
	var expected: Array[float] = []
	for example: Array in examples:
		expected.append(float(WorldChoices.try_unit_value(example[0], example[1], example[2], example[3], example[4])["unit_value"]))
	for index in [2, 0, 1]:
		var example: Array = examples[index]
		var actual := float(WorldChoices.try_unit_value(example[0], example[1], example[2], example[3], example[4])["unit_value"])
		if actual != expected[index]:
			return "choice changed with input order"
	return ""

static func rejects_non_canonical_inputs() -> String:
	var invalid_cases := [
		["", "tree", "0", "0", "0"], ["01", "tree", "0", "0", "0"], ["42", "Tree", "0", "0", "0"],
		["42", "tree", "+1", "0", "0"], ["42", "tree", "-0", "0", "0"], ["42", "tree", "0", "00", "0"],
		["42", "tree", "0", "0", "-1"], ["2147483648", "tree", "0", "0", "0"],
	]
	for example: Array in invalid_cases:
		var result := WorldChoices.try_unit_value(example[0], example[1], example[2], example[3], example[4])
		if (result["error"] as String).is_empty() or result["unit_value"] != null:
			return "invalid identifier was accepted: %s" % str(example)
	return ""

static func _lookup(example: Dictionary) -> Dictionary:
	return WorldChoices.try_unit_value(str(example["seed"]), str(example["channel"]), str(example["cell_x"]), str(example["cell_z"]), str(int(example["slot"])))
