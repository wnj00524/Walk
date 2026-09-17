## Purpose: Checks the small, deterministic movement rules without needing a rendered window.
## Why: Input devices and physics timing are difficult to inspect directly, so these tests
##      lock down the comfort boundaries and the unit-based movement contract.
## Reads: Static validation, pitch, velocity, and displacement helpers from Walker.
## Writes: Nothing; each function returns an empty string on success or a failure explanation.
## Safe changes: Add independent cases when comfort defaults change; never derive expectations
##                from the implementation under test.
## Failure: A non-empty return is reported by the named Godot test suite and fails the process.
extends RefCounted

static func settings_are_validated() -> String:
	if not Walker.validate_settings(3.2, 0.12, -75.0, 75.0).is_empty():
		return "default walker settings should be accepted"
	if Walker.validate_settings(0.0, 0.12, -75.0, 75.0).is_empty():
		return "zero walking speed should be rejected"
	if Walker.validate_settings(3.2, -0.1, -75.0, 75.0).is_empty():
		return "negative mouse sensitivity should be rejected"
	if Walker.validate_settings(3.2, 0.12, 80.0, 75.0).is_empty():
		return "reversed pitch limits should be rejected"
	return ""

static func pitch_is_bounded() -> String:
	if not is_equal_approx(Walker.clamp_pitch(-100.0, -75.0, 75.0), -75.0):
		return "look down exceeded the configured pitch limit"
	if not is_equal_approx(Walker.clamp_pitch(100.0, -75.0, 75.0), 75.0):
		return "look up exceeded the configured pitch limit"
	return ""

static func motion_scales_with_elapsed_time() -> String:
	var input := Vector2(0.0, 1.0)
	var basis := Basis.IDENTITY
	var one_second_at_60 := Vector3.ZERO
	for _step in range(60):
		one_second_at_60 += Walker.displacement_for_step(input, basis, 3.2, 1.0 / 60.0)
	var one_second_at_120 := Vector3.ZERO
	for _step in range(120):
		one_second_at_120 += Walker.displacement_for_step(input, basis, 3.2, 1.0 / 120.0)
	if not one_second_at_60.is_equal_approx(one_second_at_120):
		return "one second of walking changed with the physics step size"
	if not is_equal_approx(one_second_at_60.length(), 3.2):
		return "walking distance did not use metres per second"
	return ""
