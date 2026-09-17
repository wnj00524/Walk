## Purpose: Maps a canonical world location and channel to a repeatable choice value.
## Why: Content can be loaded in any order without sharing mutable random state.
## Reads: Canonical decimal seed/cell/slot strings and a lowercase ASCII channel.
## Writes: No files or global state; returns a digest-derived integer and unit value.
## Safe changes: Keep the payload fields, separators, SHA-256 byte order, and limits aligned with C02.
## Failure: try_unit_value returns an error and no value when any identifier is non-canonical.
class_name WorldChoices
extends RefCounted

const MAX_SEED: int = 2147483647
const MAX_INT64: int = 9223372036854775807
const MIN_INT64: int = -9223372036854775808
const UINT32_DIVISOR: float = 4294967296.0

static func try_unit_value(
	world_seed: String,
	channel: String,
	cell_x: String,
	cell_z: String,
	slot: String
) -> Dictionary:
	## Returns {"first_u32": int, "unit_value": float, "payload": String, "error": String}.
	## All text is validated before it becomes part of the C02 ASCII payload.
	var seed_error := _validate_unsigned_decimal(world_seed, MAX_SEED, "world seed")
	if not seed_error.is_empty():
		return _failure(seed_error)
	var channel_error := _validate_channel(channel)
	if not channel_error.is_empty():
		return _failure(channel_error)
	var x_error := _validate_signed_decimal(cell_x, "cell_x")
	if not x_error.is_empty():
		return _failure(x_error)
	var z_error := _validate_signed_decimal(cell_z, "cell_z")
	if not z_error.is_empty():
		return _failure(z_error)
	var slot_error := _validate_unsigned_decimal(slot, MAX_INT64, "slot")
	if not slot_error.is_empty():
		return _failure(slot_error)

	var payload := "endless-nature|g1|%s|%s|%s|%s|%s" % [world_seed, channel, cell_x, cell_z, slot]
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(payload.to_ascii_buffer())
	var digest := hashing.finish()
	var first_u32 := (int(digest[0]) << 24) | (int(digest[1]) << 16) | (int(digest[2]) << 8) | int(digest[3])
	return {"first_u32": first_u32, "unit_value": float(first_u32) / UINT32_DIVISOR, "payload": payload, "error": ""}

static func _failure(message: String) -> Dictionary:
	return {"first_u32": null, "unit_value": null, "payload": "", "error": message}

static func _validate_channel(value: String) -> String:
	if value.is_empty():
		return "channel must not be empty"
	for character in value:
		if not ((character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_"):
			return "channel must contain only lowercase ASCII letters, digits, or underscores"
	return ""

static func _validate_unsigned_decimal(value: String, maximum: int, label: String) -> String:
	if not _is_canonical_unsigned(value):
		return "%s must be a canonical non-negative decimal string" % label
	if int(value) > maximum:
		return "%s is outside its supported range" % label
	return ""

static func _validate_signed_decimal(value: String, label: String) -> String:
	if not _is_canonical_signed(value):
		return "%s must be a canonical signed decimal string" % label
	var magnitude := value.trim_prefix("-")
	if magnitude.length() == 19:
		var limit := "9223372036854775807" if not value.begins_with("-") else "9223372036854775808"
		if magnitude > limit:
			return "%s is outside signed 64-bit range" % label
	elif magnitude.length() > 19:
		return "%s is outside signed 64-bit range" % label
	return ""

static func _is_canonical_unsigned(value: String) -> bool:
	if value.is_empty() or (value.length() > 1 and value.begins_with("0")):
		return false
	for character in value:
		if character < "0" or character > "9":
			return false
	return true

static func _is_canonical_signed(value: String) -> bool:
	if value.is_empty():
		return false
	var magnitude := value.trim_prefix("-")
	if magnitude.is_empty() or (magnitude.length() > 1 and magnitude.begins_with("0")):
		return false
	if value.begins_with("-") and magnitude == "0":
		return false
	for character in magnitude:
		if character < "0" or character > "9":
			return false
	return true
