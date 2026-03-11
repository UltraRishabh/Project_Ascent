extends Node3D
"""
Reminder: Make universal logic for mouse and controller both
"""

@onready var springarm = $SpringArm3D
const min_spring_length = 6.5
const max_spring_length = 11.0

@export var camera_motion = Vector2.ZERO
@export var horizontal_sensitivity = 1.5
@export var horizontal_inversion = true
@export var  vertical_sensitivity = 1.5
@export var vertical_inversion = true

func _input(event):
	if event.is_action_pressed("mouse_left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	
	if Input.is_action_pressed("control"):
		if Input.is_action_just_pressed("scroll_up"):
			springarm.spring_length -= 0.2
		elif Input.is_action_just_pressed("scroll_down"):
			springarm.spring_length += 0.5
	springarm.spring_length = clamp(springarm.spring_length,min_spring_length,max_spring_length)

func _unhandled_input(event):
	if (event is InputEventMouseMotion) and (Input.MOUSE_MODE_CAPTURED == Input.get_mouse_mode()):
		camera_motion = event.relative

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	rotation_degrees.y += camera_motion.x * horizontal_sensitivity * (1-2*int(horizontal_inversion)) * delta
	rotation_degrees.x += camera_motion.y * vertical_sensitivity * (1-2*int(vertical_inversion)) * delta
	rotation_degrees.x = clamp(rotation_degrees.x,-35.,20.0)

	camera_motion = Vector2.ZERO
