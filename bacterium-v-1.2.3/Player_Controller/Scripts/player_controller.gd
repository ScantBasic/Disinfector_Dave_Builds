extends CharacterBody3D
class_name PlayerCharacter

# Input Variables
var input_dir := Vector3.ZERO
var wish_dir := Vector3.ZERO
var wish_crouch := false

# Crouching Varaibles
const DEFAULT_HEIGHT := 2.0
const CROUCH_TRANSLATE := 0.7
const CROUCH_JUMP_BONUS := CROUCH_TRANSLATE * 0.9
var is_crouching := false

# Raycast Variables
var side_check_raycast_collided := 0
var last_wallrunned_wall_out_of_time : int = 0 #if -1, left side, if 1, right side


# Reference Variables
@onready var cam_holder := $CameraController
@onready var cam := %FirstPersonCamera
@onready var model := $Placeholder_Bean
@onready var hitbox := $Collision_Box
@onready var state_machine := $StateMachine
@onready var left_wall_check : RayCast3D = %LeftWallCheck
@onready var right_wall_check : RayCast3D = %RightWallCheck
@onready var floor_check : RayCast3D = %FloorCheck
@onready var wading_detect : Area3D = $Wading_Detection
@onready var swimming_detect : Area3D = $Swimming_Detection

# Ground Movement Variables
@export_category("Ground Movement Variables")
@export var max_velocity_ground : float = 9.5
@export var max_acceleration = 110
@export var friction : float = 6.0
var stop_speed := 1.5
@export var wading_speed_mult := 0.5

# Sliding Variables
@export_category("Sliding Movement Variables")
var is_sliding := false
@export var slide_start_bonus := 5.0
@export var slide_friction := 0.8
@export var slide_stop_speed := 3.5

# Airborne Movement Variables
@export_category("Airborne Movement Variables")
@export var gravity := 15.0
@export var jump_power := 7.5
var coyote_time := 0.0
@export var max_air_velocity := 1.25
var locked_air_movement_time := 0.0
var double_jumps := 1
@export var max_double_jumps := 1

# Wall Movement Variables
@export_category("Wall Movement Variables")
var wall_normal := Vector3.ZERO
var can_wallrun := true
@export var wallrun_speed := 14.0
var wallrun_time := 0.0
@export var max_wallrun_time := 1.5
@export var walljump_power := 6.5
@export var walljump_height_power := 8.5
var wallrun_grav_mult := 0.05
var wall_forward_dir = Vector3.ZERO
@export var max_walljumps := 3
var walljumps := 3

# Dashing Movement Variables
@export_category("Dashing Movement Variables")
@export var max_dashes := 1
var dashes := 1
@export var total_dash_time := 0.25
var can_enter_new_dash := true
@export var dash_velocity := 14.0
@export var dash_velocity_y := 9.0
var time_before_can_dash_again := 0.25
@export var minimum_dash_delay := 0.1 # the least amount of time before you can enter a new dash

# Swimming Movement Variables
@export_category("Swimming Movement Variables")
@export var sinking_gravity_mult := 0.15
@export var swim_up_speed := 12.0
@export var swimming_speed := 6.0

# Used to set input direction and wish_direction before physics
func update_inputs() -> void:
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	wish_dir = (cam_holder.global_transform.basis * input_dir).normalized()
	wish_crouch = Input.is_action_pressed("crouch")

# Fancy crouching code I found from a tutorial
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

func _physics_process(_delta: float) -> void:
	move_and_slide()
	

func _process(delta: float) -> void:
	dash_timer_update(delta)
	airlock_timer_update(delta)
	print(state_machine.cur_state)
	#print(Vector2(self.velocity.x,self.velocity.z).length())

func dash_timer_update(delta: float) -> void:
	if time_before_can_dash_again >= 0.0:
		time_before_can_dash_again -= delta
	
	if time_before_can_dash_again <= 0.0:
		if self.is_on_floor() || dashes > 0:
			can_enter_new_dash = true

func airlock_timer_update(delta:float) -> void:
	if locked_air_movement_time >= 0.0:
		locked_air_movement_time -= delta
