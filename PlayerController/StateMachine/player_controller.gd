extends CharacterBody3D

class_name PlayerCharacter

# Input Variables
var input_dir := Vector3.ZERO
var wish_dir := Vector3.ZERO
var wish_jump := false
var wish_crouch := false
var wish_sprint := false
var wish_dash := false
var wish_noclip := false
var last_frame_position: Vector3
var last_frame_velocity: Vector3
var was_on_floor: bool


#reference variables
@onready var cam_holder := $CameraController
@onready var cam := %CameraFirstPerson
@onready var model := $Model_Placeholder
@onready var hitbox := $CollisionBox
@onready var state_machine := $StateMachine
@onready var ceiling_check: RayCast3D = %CeilingCheck
@onready var floor_check: RayCast3D = %FloorCheck
@onready var wallrun_floor_check : RayCast3D = %WallrunFloorCheck
@onready var left_wall_check : RayCast3D = %LeftWallCheck
@onready var right_wall_check : RayCast3D = %RightWallCheck
@onready var water_above_check : RayCast3D = %WaterAboveCheck

# GROUND MOVEMENT VARIABLES
@export_category("Ground Variables")
@export var max_velocity_ground := 8.5
var max_acceleration = 10 * max_velocity_ground
var stop_speed := 1.5
var friction := 6.0

# SLIDING MOVEMENT VARIABLES
var last_velocity := Vector3.ZERO
@export_category("Sliding Variables")
var is_sliding = false
@export var slide_start_bonus := 4.5
var slide_friction := 0.8
var slide_stop_speed := 0.5

# AIR MOVEMENT VARIABLES
@export_category("Air Variables")
@export var max_velocity_air := 1.25
@export var GRAVITY := 15.0
@export var jump_strength := 7.5
var coyote_jump_timer := 0.0
@export var max_jump_time := 0.2
@export var max_double_jumps := 1
var double_jumps := 0

# DASH MOVEMENT VARIABLES
@export_category("Dash Variables")
@export var dash_velocity := 12.0
@export var max_dashes := 1
var dashes := 0
var is_dashing := false
@export var dash_total_time := 0.15
var dash_tmr := 0.0
var can_enter_new_dash := true

# WALLRUN & WALLJUMP VARIABLES
@export_category("Wallrun Variables")
var can_wallrun := true
var side_check_raycast_collided := 0
var last_wallrunned_wall_out_of_time : int = 0 #if -1, left side, if 1, right side
var wall_normal := Vector3.ZERO
var wall_forward_dir := Vector3.ZERO
@export var wallrun_speed := 18.0
@export var wallrun_time := 3.5
@export var max_wallrun_time := 3.5
var wallrun_grav_mult := 0.006
@export var time_bef_can_wallrun_again : float = 0.2
var time_bef_can_wallrun_again_ref := 0.2
@export var walljump_push_force : float = 6.0
@export var walljump_y_velocity : float = 9.0
var walljump_lock_in_air_movement_time := 0.15
var walljump_lock_in_air_movement_time_ref := 0.15

@export_category("Water Variables")
@export var water_speed := 4.5
@export var sink_speed_mult := 0.06
@export var swim_up_speed := 5.0
var in_water : bool = false

#PLAYER CROUCHING & STAIR VARIABLES
const DEFAULT_HEIGHT := 2.0
const CROUCH_TRANSLATE := 0.7
const CROUCH_JUMP_BONUS := CROUCH_TRANSLATE * 0.9
var is_crouching := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()

func _process(delta: float) -> void:
	wallrun_timer(delta)
	dash_timer(delta)

func _physics_process(_delta: float) -> void:
	modify_physics_properties()
	move_and_slide()

func update_input() -> void:
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	wish_dir = (cam_holder.global_transform.basis * input_dir).normalized()
	
	wish_jump = Input.is_action_just_pressed("jump")
	wish_crouch = Input.is_action_pressed("crouch")
	wish_sprint = Input.is_action_pressed("sprint")
	wish_dash = Input.is_action_just_pressed("dash")
	if Input.is_action_just_pressed("Fly") && (!is_sliding || !is_dashing):
		wish_noclip = !wish_noclip

func wallrun_timer(delta : float) -> void:
	if !can_wallrun:
		if time_bef_can_wallrun_again > 0.0: time_bef_can_wallrun_again -= delta
		else:
			#can only reset capacity of wallrunning when not currently wallrunning
			if state_machine.curr_state_name != "Wallrun":
				wallrun_time = max_wallrun_time
				can_wallrun = true

func dash_timer(delta: float) -> void:
	# dash timer needs to constantly decrease, also the logic for re-enabling dashing
	dash_tmr -= delta
	if dash_tmr <= -0.25:
		if is_on_floor() || dashes > 0:
			can_enter_new_dash = true

func modify_physics_properties() -> void:
	last_frame_position = global_position #get play char global position every frame
	last_frame_velocity = velocity #get play char velocity every frame
	was_on_floor = !is_on_floor() #check if play char was on floor every frame

func update_gravity(delta):
	self.velocity.y -= GRAVITY * delta

func update_crouching(delta) -> void:
	#find out if we are actually crouching
	var was_crouching_last_frame = is_crouching
	if wish_crouch:
		is_crouching = true
	elif is_crouching && !self.test_move(self.transform, Vector3(0.0,CROUCH_TRANSLATE,0.0)):
		is_crouching = false
	if is_sliding:
		is_crouching = true
	#something for crouching in the air I think, no clue
	var translate_y_if_possible := 0.0
	if was_crouching_last_frame != is_crouching && !is_on_floor():
		translate_y_if_possible = CROUCH_JUMP_BONUS if is_crouching else -CROUCH_JUMP_BONUS
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.transform, Vector3(0, translate_y_if_possible,0), result)
		self.position.y += result.get_travel().y
		cam_holder.position.y -= result.get_travel().y
	#move the camera for the crouch
	@warning_ignore("incompatible_ternary")
	cam_holder.position.y = lerp(cam_holder.position.y, -CROUCH_TRANSLATE + 1.7 if is_crouching else 1.7, 8 * delta)
	hitbox.shape.height = DEFAULT_HEIGHT - CROUCH_TRANSLATE if is_crouching else DEFAULT_HEIGHT
	hitbox.position.y = hitbox.shape.height / 2.0
	model.mesh.height = hitbox.shape.height
	model.position.y = hitbox.position.y
