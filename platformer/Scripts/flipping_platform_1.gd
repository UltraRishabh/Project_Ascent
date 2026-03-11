#flipping_platform_1.gd
extends AnimatableBody3D

## The speed at which the platform rotates towards its target.
@export var rotation_speed: float = 3.0
## The duration in seconds the platform stays flipped before resetting.
@export var flip_duration: float = 3.0
## The duration in seconds to briefly pause physics when a flip is initiated.
@export var physics_pause_duration: float = 0.5

# Using constants makes the code clearer than using "magic numbers" like 90 or -90.
const FLIP_LEFT_ANGLE: float = -90.0
const FLIP_RIGHT_ANGLE: float = 90.0
const NEUTRAL_ANGLE: float = 0.0

# Node references are grouped for clarity.
var player
@onready var red_upper_area: CollisionShape3D = $RedCollider/RedUpperArea/CollisionShape3D
@onready var blue_upper_area: CollisionShape3D = $BlueCollider/BlueUpperArea/CollisionShape3D
@onready var flip_timer: Timer = $FlipTimer

# State variables are prefixed with an underscore to denote they are for internal use.
var _current_target_angle: float = NEUTRAL_ANGLE
var _previous_target_angle: float = NEUTRAL_ANGLE

func _ready() -> void:
	await get_tree().process_frame
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		player = player_nodes[0]

	# Connect the timer's signal in code. This is a robust way to handle signals.
	flip_timer.timeout.connect(_on_flip_timer_timeout)
	# Ensure colliders start in the correct state.
	_update_colliders(NEUTRAL_ANGLE)

func _physics_process(delta: float) -> void:
	# This check efficiently pauses physics only when the target angle actually changes.
	# Using is_equal_approx is safer for comparing floats.
	if not is_equal_approx(_current_target_angle, _previous_target_angle):
		_pause_physics_for(physics_pause_duration)
		_previous_target_angle = _current_target_angle

	# The core rotation logic is lean and runs every frame.
	rotation_degrees.z = lerp(rotation_degrees.z, _current_target_angle, rotation_speed * delta)

# --- Signal Callbacks ---

func _on_blue_upper_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_start_flip(FLIP_LEFT_ANGLE)


func _on_red_upper_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_start_flip(FLIP_RIGHT_ANGLE)

func _on_flip_timer_timeout() -> void:
	# When the timer finishes, reset the platform to its neutral state.
	_current_target_angle = NEUTRAL_ANGLE
	call_deferred("_update_colliders",NEUTRAL_ANGLE)

# --- Helper Functions ---

# This function centralizes the logic for starting a flip.
func _start_flip(target_angle: float) -> void:
	_current_target_angle = target_angle
	call_deferred("_update_colliders",target_angle)
	flip_timer.start(flip_duration)

# Centralized logic for managing all collider states.
func _update_colliders(target_angle: float) -> void:
	if target_angle == NEUTRAL_ANGLE:
		red_upper_area.disabled = false
		blue_upper_area.disabled = false
	else:
		red_upper_area.disabled = true
		blue_upper_area.disabled = true

# This helper function is already well-written.
func _pause_physics_for(seconds: float) -> void:
	set_physics_process(false)
	await get_tree().create_timer(seconds).timeout
	set_physics_process(true)
