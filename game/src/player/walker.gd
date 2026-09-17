## Purpose: Gives the prototype a comfortable first-person walking body.
## Why: Keeping movement and look rules together makes the later streamed world able
##      to provide a floor without owning input or camera comfort behaviour.
## Reads: Named walk actions, mouse motion, and the exported metre/second settings.
## Writes: CharacterBody3D position, yaw, camera pitch, and mouse capture state.
## Safe changes: Walking speed, look sensitivity, and pitch limits are the intended
##                comfort controls; keep speed in metres/second and pitch in degrees.
## Failure: Invalid settings are reported and movement is disabled; the cursor can
##          always be released with Escape even if the player is looking around.
class_name Walker
extends CharacterBody3D

@export_range(0.1, 12.0, 0.1, "or_greater") var walking_speed_mps: float = 3.2
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity_deg_per_pixel: float = 0.12
@export_range(-89.0, 0.0, 1.0) var min_pitch_degrees: float = -75.0
@export_range(0.0, 89.0, 1.0) var max_pitch_degrees: float = 75.0

@onready var camera: Camera3D = $Camera3D

var _pitch_degrees := 0.0
var _settings_valid := true

static func validate_settings(
	walking_speed: float,
	look_sensitivity: float,
	min_pitch: float,
	max_pitch: float
) -> String:
	## Returns an explanation instead of guessing when a comfort setting is unsafe.
	if not is_finite(walking_speed) or walking_speed <= 0.0:
		return "walking speed must be a finite positive number of metres per second"
	if not is_finite(look_sensitivity) or look_sensitivity <= 0.0:
		return "mouse sensitivity must be a finite positive number of degrees per pixel"
	if not is_finite(min_pitch) or not is_finite(max_pitch) or min_pitch >= max_pitch:
		return "minimum pitch must be finite and less than maximum pitch"
	if min_pitch < -89.0 or max_pitch > 89.0:
		return "pitch limits must stay between -89 and 89 degrees"
	return ""

static func clamp_pitch(pitch_degrees: float, min_pitch: float, max_pitch: float) -> float:
	## Keeps the camera away from the uncomfortable near-vertical range.
	return clamp(pitch_degrees, min_pitch, max_pitch)

static func horizontal_velocity(input_vector: Vector2, view_basis: Basis, speed_mps: float) -> Vector3:
	## Converts input into a horizontal velocity; delta is applied by the physics body.
	## Normalising prevents diagonal input from being faster than straight input.
	var direction := (view_basis.x * input_vector.x) + (-view_basis.z * input_vector.y)
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	return direction * speed_mps

static func displacement_for_step(input_vector: Vector2, view_basis: Basis, speed_mps: float, delta_seconds: float) -> Vector3:
	## Exposes the time-scaled step used by tests to prove frame-rate independence.
	return horizontal_velocity(input_vector, view_basis, speed_mps) * delta_seconds

func _ready() -> void:
	var settings_error := validate_settings(
		walking_speed_mps,
		mouse_sensitivity_deg_per_pixel,
		min_pitch_degrees,
		max_pitch_degrees
	)
	if not settings_error.is_empty():
		_settings_valid = false
		push_error("Walker disabled: %s" % settings_error)
		return
	_ensure_input_actions()
	_pitch_degrees = camera.rotation_degrees.x
	_set_mouse_captured(true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_set_mouse_captured(false)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_mouse_captured(true)
	if event is InputEventMouseMotion and _mouse_is_captured():
		var motion := event as InputEventMouseMotion
		rotate_y(deg_to_rad(-motion.relative.x * mouse_sensitivity_deg_per_pixel))
		_pitch_degrees = clamp_pitch(
			_pitch_degrees - motion.relative.y * mouse_sensitivity_deg_per_pixel,
			min_pitch_degrees,
			max_pitch_degrees
		)
		camera.rotation_degrees.x = _pitch_degrees

func _physics_process(_delta: float) -> void:
	if not _settings_valid:
		return
	var input_vector := Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_backward")
	velocity = horizontal_velocity(input_vector, global_transform.basis, walking_speed_mps)
	move_and_slide()

func _ensure_input_actions() -> void:
	## Defines actions here because this prototype cannot yet change the shared project settings.
	_add_key_action("walk_forward", KEY_W)
	_add_key_action("walk_backward", KEY_S)
	_add_key_action("walk_left", KEY_A)
	_add_key_action("walk_right", KEY_D)

func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, key_event)

func _set_mouse_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE

func _mouse_is_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
