#player_movement.gd
extends CharacterBody3D

"""
How can the character interact with the world and vice versa:
wall slide, pickup, drop/throw, doors, chests
enemies, flora, water, collectibles,wind
"""

@onready var pivot = $Pivot
@onready var shape = $Shape
@onready var upper_raycast = $Shape/UpperRayCast
@onready var lower_raycast = $Shape/LowerRayCast
@onready var down_raycast = $DownRayCast

const JOG_SPEED = 11.0
const BOOST_SPEED = 15.0
var MAX_SPEED = JOG_SPEED

const JOG_ACC = 6.0
const JOG_DEC = 7.5
const AIR_ACC = 3.5
var ACCELERATION = JOG_ACC
var DECELERATION = JOG_DEC

const JUMP_VELOCITY = 9.0
const DOUBLE_JUMP_VELOCITY = 8.0 # Height of the second jump
const JUMP_HOLD_FORCE = 4.0 #(4 or 3.5)
var up_gravity = Vector3(0.0, -20.0, 0.0) # Weaker gravity when moving up
var down_gravity = Vector3(0.0, -40.0, 0.0) # Stronger gravity when falling

var direction = Vector3.ZERO
var input_dir = Vector2.ZERO
var target_velocity = Vector3.ZERO

var jump_buffer_time = 0.12
var jump_buffer_timer = 0.0

var coyote_time = 0.12
var coyote_timer = 0.0

var speed_boost = false
var speed_boost_timer = 0.0
var speed_boost_time = 2.0

var jump_requested = false
var is_clambering = false
var can_double_jump = false # Tracks if the double jump is available

var dive_requested = false
var dive_cooldown_timer = 0.0
var dive_cooldown_time = 0.6

var on_floor
var current_gravity

func _ready():
	current_gravity = up_gravity if velocity.y > 0 else down_gravity
	on_floor = is_on_floor()

func _process(_delta):
	input_dir = Input.get_vector("A", "D", "W", "S")

	if Input.is_action_just_pressed("left_mouse_click") and dive_cooldown_timer==0.0:dive_requested=true

	if Input.is_action_pressed("jump") and not on_floor and velocity.y > 0 and can_double_jump:
		velocity.y += JUMP_HOLD_FORCE * _delta

	if Input.is_action_just_pressed("jump"):
		if not on_floor and can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false 
		else:
			jump_requested = true
			jump_buffer_timer = jump_buffer_time

func _physics_process(delta):
	on_floor = is_on_floor()

	#--SPEED BOOST LOGIC----------------------------------------------------------------------------
	if speed_boost and speed_boost_timer<speed_boost_time:
		speed_boost_timer+=delta
		MAX_SPEED=BOOST_SPEED
		ACCELERATION=AIR_ACC
		DECELERATION=AIR_ACC
	else:
		speed_boost_timer=0.0
		speed_boost=false
		MAX_SPEED=JOG_SPEED
		ACCELERATION=JOG_ACC
		DECELERATION=JOG_DEC

	#--DIVING LOGIC---------------------------------------------------------------------------------
	if dive_requested and Vector2(velocity.x,velocity.z).length()>1.5 and dive_cooldown_timer<=0.0:
		if on_floor:
			velocity.y += 6.0
			velocity += shape.global_basis.z * 8.0
		else:
			velocity += shape.global_basis.z * 8.0
		dive_cooldown_timer=dive_cooldown_time
	dive_requested = false

	if dive_cooldown_timer>0.0:
		dive_cooldown_timer-=delta
	else:
		dive_cooldown_timer=0.0

	#--COYOTE TIMER---------------------------------------------------------------------------------
	if on_floor:
		coyote_timer = coyote_time
		can_double_jump = false 
	else:
		coyote_timer -= delta

	#--JUMP BUFFER----------------------------------------------------------------------------------
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	else:
		jump_requested = false

	#--GRAVITY--------------------------------------------------------------------------------------
	if not on_floor:
		current_gravity = up_gravity if velocity.y > 0 else down_gravity
		velocity += current_gravity * delta
		ACCELERATION = AIR_ACC
		DECELERATION = AIR_ACC
	else:
		ACCELERATION = JOG_ACC
		DECELERATION = JOG_DEC

	#--CLAMBER LOGIC--------------------------------------------------------------------------------
	if upper_raycast.is_colliding() and lower_raycast.is_colliding() and !is_clambering:
		is_clambering=true
		can_double_jump=true
		velocity.y=0
	else:is_clambering=false

	#--JUMPING LOGIC--------------------------------------------------------------------------------
	if jump_requested and (on_floor or coyote_timer > 0.0):
		velocity.y = JUMP_VELOCITY
		velocity.x *=0.5
		velocity.z*=0.5
		can_double_jump = true
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		jump_requested = false

	#--DOUBLE JUMP AND JUMP BUFFER SEPERATION-------------------------------------------------------
	if (down_raycast.get_collision_point() - down_raycast.global_position).length() < 0.25 and !on_floor and velocity.y<0.0:
		can_double_jump=false

	#--MOVEMENT-------------------------------------------------------------------------------------
	direction = (pivot.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		target_velocity = direction * MAX_SPEED
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
		
		# Rotate the character model to face the direction of movement
		var target_angle = shape.rotation.y + shape.global_basis.z.signed_angle_to(target_velocity, Vector3.UP)
		shape.rotation.y = lerp_angle(shape.rotation.y, target_angle, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)

	if is_clambering:
		velocity = Vector3.ZERO
		velocity.y+=JUMP_VELOCITY
		velocity += -shape.global_transform.basis.z * AIR_ACC
	
	velocity.y = clamp(velocity.y, -50.0, 30.0)
	move_and_slide()

	#--POSITION RESET-------------------------------------------------------------------------------
	if position.y < -10.0:
		get_tree().reload_current_scene()
