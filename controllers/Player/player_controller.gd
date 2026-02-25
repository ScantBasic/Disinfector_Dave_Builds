class_name Player
extends CharacterBody3D

# INPUT VARIABLES
var input_dir = Vector3.ZERO
var wish_dir = Vector3.ZERO
var wish_jump := false
var wish_crouch := false
var wish_sprint := false
var wish_dash := false
var wish_noclip := false
var is_crouching := false

# GROUND MOVEMENT VARIABLES
@export_category("Ground Movement")
@export var max_velocity_ground := 8.5
var max_acceleration = 10 * max_velocity_ground
var stop_speed := 1.5
var friction := 6.0

# SLIDING MOVEMENT VARIABLES
var last_velocity := Vector3.ZERO
@export_category("Sliding Movement")
var is_sliding = false               #for the sliding stuff
@export var slide_start_bonus := 4.5      #how much bonus speed you get when you start sliding
var slide_friction := 1.5    # how fast we slow down, smaller means more distance
var slide_stop_speed := 0.5

# AIR MOVEMENT VARIABLES
@export_category("Air Movement")
@export var max_velocity_air := 1.25
@export var GRAVITY := 15.0
@export var jump_strength := 7.5
var coyote_jump_timer := 0.0
@export var max_jump_time := 0.2

# DASH MOVEMENT VARIABLES
@export_category("Dash Movement")
@export var dash_velocity := 12.0
@export var max_dashes := 1
var dashes := 0
var is_dashing := false
@export var dash_total_time := 0.15
var dash_tmr := 0.0
var can_enter_new_dash := true

# WALL MOVEMENT VARIABLES
@export_category("WALL MOVEMENT")
@export var max_wall_jumps := 4
var wall_jumps := 0
@export var wall_speed := 5.5

# CAMERA CONTROLS AND INPUTS
@export_category("Camera")
var TILT_LOWER_LIMIT := deg_to_rad(-90)
var TILT_UPPER_LIMIT := deg_to_rad(90)
@export var CAMERA_CONTROLLER = Camera3D
@onready var HEAD_CONTROLLER = $CameraController/HeadController
@onready var CAMERA_POSITION = $CameraController
@onready var WALLJUMP_RAYCAST = $CameraController/HeadController/Camera3D/RayCast3D


var _mouse_input : bool = false
var _rotation_input : float
var _tilt_input : float
@export var _mouse_sensitivity : float = 100

const cam_bob_intensity := 0.08   # Up/down offset while walking
const cam_bob_speed := 1.0       # Frequency of bobbing
var last_y_velocity : float = 0.0    # last y vel, used in landing and fall damage
var land_bob_speed := 2.0        # How fast it returns up after landing
var cam_bob_time := 0.0           # timer for walk bobbing
var target_cam_pos := Vector3.ZERO  # original resting camera position
var land_bob_offset : float        # camera offset when landing

#PLAYER COLLISION BODY & PLAYER MESH VARIABLES
@export_category("Player Collision/Meshes")
@export var PLAYER_COLLISION = CollisionShape3D
@export var DEFAULT_MESH = MeshInstance3D

#PLAYER CROUCHING & STAIR VARIABLES
const DEFAULT_HEIGHT := 2.0
const CROUCH_TRANSLATE := 0.7
const CROUCH_JUMP_BONUS := CROUCH_TRANSLATE * 0.9




#ACTUAL CODE AND NOT JUST VARIABLES

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * (_mouse_sensitivity /100.0)
		_tilt_input = -event.relative.y * (_mouse_sensitivity /100.0)

func _physics_process(_delta: float) -> void:
	GlobalController.DEBUG.add_property("FPS", Engine.get_frames_per_second(), 1)
	GlobalController.DEBUG.add_property("Move Speed", "%.2f" % Vector2(last_velocity.x,last_velocity.z).length(), 2)

func _update_camera(delta) -> void:
	HEAD_CONTROLLER.rotate_x(_tilt_input * delta)
	HEAD_CONTROLLER.rotation.x = clamp(HEAD_CONTROLLER.rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	
	if is_sliding:
		CAMERA_POSITION.rotate_y(_rotation_input * delta)
		CAMERA_POSITION.rotation.y = clamp(CAMERA_POSITION.rotation.y,deg_to_rad(-135), deg_to_rad(135))
	else:
		self.rotate_y(_rotation_input * delta)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
	
	if !is_sliding:
		rotate_y(CAMERA_POSITION.rotation.y)
		CAMERA_POSITION.rotation.y = 0.0
	
	CAMERA_CONTROLLER.rotation.z = lerp(CAMERA_CONTROLLER.rotation.z, 0.0, 2.4 * delta)

func _headbob(time) -> float:
	var pos = Vector3.ZERO
	var mult = 1.0
	if wish_sprint:
		mult = 1.25
	
	if is_crouching:
		pos.y = 1.8 - CROUCH_TRANSLATE + sin(time * cam_bob_speed)  * mult * cam_bob_intensity + land_bob_offset
	else:
		pos.y = 1.8 + sin(time * cam_bob_speed ) * mult * cam_bob_intensity + land_bob_offset
	return pos.y

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func update_input() -> void:
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	wish_dir = (self.global_transform.basis * input_dir).normalized()
	wish_jump = Input.is_action_just_pressed("jump")
	wish_crouch = Input.is_action_pressed("crouch")
	wish_sprint = Input.is_action_pressed("sprint")
	wish_dash = Input.is_action_just_pressed("dash")
	if Input.is_action_just_pressed("noclip") && (!is_sliding || !is_dashing):
		wish_noclip = !wish_noclip

func update_timers(delta) -> void:
	dash_tmr -= delta
	if dash_tmr <= -0.25:
		if is_on_floor() || dashes > 0:
			can_enter_new_dash = true
			if is_on_floor():
				dashes = max_dashes

func accelerate(max_velocity: float, delta) -> Vector3:
	#current speed compared to wish_dir
	var cur_speed = self.velocity.dot(wish_dir)
	#how much we need to accelerate
	var add_speed = clamp(max_velocity - cur_speed, 0.0, max_acceleration * delta)
	
	return self.velocity + add_speed * wish_dir

func update_velocity_air(delta) -> void:
	self.velocity = accelerate(max_velocity_air, delta)

func update_velocity_ground(vel:float,delta) -> void:
	var speed = self.velocity.length()
	if speed != 0.0:
		var control = max(stop_speed, speed)
		var drop = control * friction * delta
		if is_crouching:
			drop *= 2.0
		
		#scale velocity to friction
		self.velocity *= max(speed - drop, 0.0) / speed
	
	self.velocity = accelerate(vel, delta)

func update_velocity() -> void:
	move_and_slide()
	last_velocity = self.velocity


func update_gravity(delta) -> void:
	self.velocity.y -= GRAVITY * delta

func update_jumping(delta) -> void:
	
	if wish_jump:
		if coyote_jump_timer < max_jump_time:
			self.velocity.y = jump_strength
			wish_jump = false
			if is_sliding:
				self.velocity.x *= 1.05
				self.velocity.z *= 1.05
	
	
	if is_on_floor():
		wall_jumps = max_wall_jumps
		if can_enter_new_dash:
			dashes = max_dashes
		coyote_jump_timer = 0.0
	else:
		coyote_jump_timer += delta

func update_crouching(delta) -> void:
	var was_crouching_last_frame = is_crouching
	
	if wish_crouch:
		is_crouching = true
	
	elif is_crouching && !self.test_move(self.transform, Vector3(0.0,CROUCH_TRANSLATE,0.0)):
		is_crouching = false
	
	if is_sliding:
		is_crouching = true
	
	var translate_y_if_possible := 0.0
	if was_crouching_last_frame != is_crouching && !is_on_floor():
		translate_y_if_possible = CROUCH_JUMP_BONUS if is_crouching else -CROUCH_JUMP_BONUS
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.transform, Vector3(0, translate_y_if_possible,0), result)
		self.position.y += result.get_travel().y
		CAMERA_POSITION.position.y -= result.get_travel().y
	
	@warning_ignore("incompatible_ternary")
	CAMERA_POSITION.position.y = lerp(CAMERA_POSITION.position.y, -CROUCH_TRANSLATE + 1.7 if is_crouching else 1.7, 8 * delta)
	PLAYER_COLLISION.shape.height = DEFAULT_HEIGHT - CROUCH_TRANSLATE if is_crouching else DEFAULT_HEIGHT
	PLAYER_COLLISION.position.y = PLAYER_COLLISION.shape.height / 2.0
	DEFAULT_MESH.mesh.height = PLAYER_COLLISION.shape.height
	DEFAULT_MESH.position.y = PLAYER_COLLISION.position.y

func start_slide() -> void:
	is_sliding = true
	self.velocity += wish_dir * slide_start_bonus

func end_slide() -> void:
	var horiz_vel = Vector3(self.velocity.x,0,self.velocity.z)
	if is_on_wall() || abs(horiz_vel.length()) < 3.0 || !is_on_floor():
		is_sliding = false

func update_slide(delta) -> void:
	var speed = self.velocity.length()
	if speed != 0.0:
		var control = max(slide_stop_speed, speed)
		var drop = control * slide_friction * delta
		#scale velocity to friction
		self.velocity *= max(speed - drop, 0.0) / speed
	

func get_dash_direction() -> Vector3:
	if input_dir.length() > 0:
		var cam_basis = HEAD_CONTROLLER.global_transform.basis
		return (cam_basis * input_dir).normalized()
	else:
	# Default: camera forward
		var forward := -self.global_transform.basis.z
		return forward.normalized()

func start_dash() -> void:
	dash_tmr = dash_total_time
	dashes -= 1
	self.velocity = get_dash_direction() * dash_velocity
	is_dashing = true
	can_enter_new_dash = false

func update_dash() -> void:
	self.velocity = get_dash_direction() * dash_velocity

func end_dash():
	if is_on_wall() || dash_tmr <= 0.0:
		is_dashing = false
		

# --- NOCLIP MOVEMENT ---
func process_noclip(delta):
	PLAYER_COLLISION.disabled = wish_noclip
	self.velocity = Vector3.ZERO
	var noclip_vel = Vector3.ZERO
	noclip_vel = wish_dir * max_velocity_ground
	if Input.is_action_pressed("crouch"):
		noclip_vel.y -= max_velocity_ground
	if Input.is_action_pressed("jump"):
		noclip_vel.y += max_velocity_ground
	
	if Input.is_action_pressed("sprint"):
		noclip_vel *= 3
	
	self.global_position += noclip_vel * delta

func handle_wall_movement(delta) -> void:
		# Separate horizontal velocity
	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	#not on ground so fall
	#reducer if falling to make it feel better
	if self.velocity.y <= 0.0:
		self.velocity.y *= 0.8
	
	#jump (or drop) from the wall
	if Input.is_action_just_pressed("jump"):
		if wall_jumps > 0:
			horiz_vel += get_wall_normal() * wall_speed
			self.velocity.y = jump_strength
			wall_jumps -= 1
	elif Input.is_action_pressed("crouch"):
		horiz_vel += get_wall_normal() * wall_speed
		self.velocity.y = -1.5
	
	#wall movement math
	var collision = get_slide_collision(0)
	var normal = collision.get_normal()
	get_tree().create_timer(0.5)
	var wallrun_dir = -normal * wall_speed * 5
	var player_view_dir = -CAMERA_CONTROLLER.global_transform.basis.z
	var dot = wallrun_dir.dot(player_view_dir)
	if dot <0:
		wallrun_dir = -wallrun_dir
	wallrun_dir += normal * 0.01
	wish_dir = wallrun_dir
	
	var target_roll := 0.0
	if WALLJUMP_RAYCAST.is_colliding():
		var wall_collision_point = WALLJUMP_RAYCAST.get_collision_point()
		var wall_collision_normal = WALLJUMP_RAYCAST.get_collision_normal()
		
		var distance = WALLJUMP_RAYCAST.global_position.distance_to(wall_collision_point)
		var t =  clamp(distance / 6, 0.0, 1.0)
		
		var right_dir = global_transform.basis.x
		var side = right_dir.dot(-wall_collision_normal)
		
		var roll_amount = deg_to_rad(35 * (1.0-t))
		target_roll = roll_amount * sign(side)
		CAMERA_CONTROLLER.rotation.z = lerp(CAMERA_CONTROLLER.rotation.z, target_roll, 6.0 * delta)
	
	
	
	# Update velocity
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z
