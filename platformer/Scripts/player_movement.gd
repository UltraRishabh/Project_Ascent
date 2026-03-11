extends CharacterBody3D

"""
REMOVE/CHANGE WALL_JUMP
How can the character interact with the world and vice versa:
different wall slide mechanics for each wall? wall slide, 
pickup, drop/throw, doors, chests
enemies, flora, water, collectibles,wind
"""

@onready var pivot = $Pivot
@onready var shape = $Shape
@onready var shape2 = $Shape2
@onready var upper_raycast = $Shape/UpperRayCast
@onready var lower_raycast = $Shape/LowerRayCast
@onready var down_raycast = $DownRayCast

const JOG_SPEED = 10.0
const BOOST_SPEED = 15.0
var MAX_SPEED = JOG_SPEED

const JOG_ACC = 6.5
const JOG_DEC = 8.5
const AIR_ACC = 3.0
var ACCELERATION = JOG_ACC
var DECELERATION = JOG_DEC

const JUMP_VELOCITY = 12.0

const WALL_SLIDE_SPEED = 5.0 # How fast the player slides down a wall
const WALL_JUMP_VELOCITY_XZ = 12.0 # Horizontal force when jumping off a wall
const WALL_JUMP_VELOCITY_Y = 6.5

var up_gravity = Vector3(0.0, -30.0, 0.0)
var down_gravity = Vector3(0.0, -40.0, 0.0)

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
var clamber_jump_multiplier = 1.2
var can_double_jump = false

var is_wall_sliding = false
var can_wall_jump = false

var dive_requested = false
var dive_cooldown_timer = 0.0
var dive_cooldown_time = 0.5

#var is_in_ball_form = false

var on_floor
var current_gravity

func _ready():
	current_gravity = up_gravity if velocity.y > 0 else down_gravity
	on_floor = is_on_floor()
	shape2.disabled = true

func _process(_delta):
	input_dir = Input.get_vector("A", "D", "W", "S")

	if Input.is_action_just_pressed("right_mouse_click") and dive_cooldown_timer==0.0:dive_requested=true

	if Input.is_action_just_pressed("jump"):
		if not on_floor and can_double_jump and not is_wall_sliding:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
		else:
			jump_requested = true
			jump_buffer_timer = jump_buffer_time
	#if Input.is_action_pressed("shift"):
		#is_in_ball_form = true
	#else:
		#is_in_ball_form = false
	#if Input.is_action_just_released("shift"):
		#jump_requested = true

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
			velocity.y += JUMP_VELOCITY * 0.8
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
		can_wall_jump = false # Reset wall jump on floor
	else:
		coyote_timer -= delta

	#--JUMP BUFFER----------------------------------------------------------------------------------
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	else:
		jump_requested = false

	#--GRAVITY--------------------------------------------------------------------------------------
	if not on_floor:
		current_gravity = up_gravity if velocity.y > 0 and Input.is_action_pressed("jump") else down_gravity
		velocity += current_gravity * delta
		ACCELERATION = AIR_ACC
		DECELERATION = AIR_ACC
	elif (!is_wall_sliding and !can_wall_jump) or on_floor:
		ACCELERATION = JOG_ACC
		DECELERATION = JOG_DEC
		
	#--WALL SLIDE LOGIC-----------------------------------------------------------------------------
	var was_wall_sliding = is_wall_sliding
	is_wall_sliding = false # Reset each frame
	if is_on_wall_only() and velocity.y < 0 and lower_raycast.is_colliding():
		is_wall_sliding = true
		
		# Slow down the fall speed to create the slide effect
		if velocity.y < -WALL_SLIDE_SPEED:
			velocity.y = -WALL_SLIDE_SPEED
		
		# If we just started sliding on a new wall, refresh jumps
		if not was_wall_sliding:
			can_wall_jump = true
			can_double_jump = true # Refresh double jump on wall contact

	#--CLAMBER LOGIC--------------------------------------------------------------------------------
	if upper_raycast.is_colliding() and lower_raycast.is_colliding() and not is_clambering:
		is_clambering=true
		can_double_jump=true
		velocity.y=0
	else:
		is_clambering=false
	
	#--JUMPING LOGIC--------------------------------------------------------------------------------
	if jump_requested:
		if is_wall_sliding and can_wall_jump:
			var wall_normal = get_wall_normal()
			velocity = wall_normal * WALL_JUMP_VELOCITY_XZ
			velocity.y = WALL_JUMP_VELOCITY_Y
			can_wall_jump = false
			jump_requested = false
			jump_buffer_timer = 0.0
		elif on_floor or coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			velocity.x *= 0.5
			velocity.z *= 0.5
			can_double_jump = true
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			jump_requested = false

	#--DOUBLE JUMP AND JUMP BUFFER SEPERATION-------------------------------------------------------
	if (down_raycast.get_collision_point() - down_raycast.global_position).length() < 0.25 and not on_floor and velocity.y<0.0:
		can_double_jump=false

	#--BALL FORM LOGIC -----------------------------------------------------------------------------
	#if is_in_ball_form:
		#shape.visible = false
		#shape.disabled = true
		#shape2.visible = true
		#shape2.disabled = false
		#upper_raycast.enabled = false
		#lower_raycast.enabled = false
		#can_double_jump=false
		#ACCELERATION = 1.5
		#DECELERATION = 0.5
		#MAX_SPEED = BOOST_SPEED
	#else:
		#shape.visible = true
		#shape.disabled = false
		#shape2.visible = false
		#shape2.disabled = true
		#upper_raycast.enabled = true
		#lower_raycast.enabled = true
		#ACCELERATION = JOG_ACC
		#DECELERATION = JOG_DEC
		#MAX_SPEED = JOG_SPEED

	#--MOVEMENT-------------------------------------------------------------------------------------
	direction = (pivot.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		target_velocity = direction * MAX_SPEED
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
		
		var target_angle = shape.rotation.y + shape.global_basis.z.signed_angle_to(target_velocity, Vector3.UP)
		shape.rotation.y = lerp_angle(shape.rotation.y, target_angle, ACCELERATION * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)

	if is_clambering:
		velocity = Vector3.ZERO
		velocity.y+=JUMP_VELOCITY*clamber_jump_multiplier
		velocity += -shape.global_transform.basis.z * AIR_ACC
	
	velocity.y = clamp(velocity.y, -50.0, 30.0)
	move_and_slide()

	#--POSITION RESET-------------------------------------------------------------------------------
	if position.y < -10.0:
		get_tree().reload_current_scene()
