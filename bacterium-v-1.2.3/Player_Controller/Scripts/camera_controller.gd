extends Node3D
class_name CameraController

#Variables
@export_group("Camera Variables")
@export_range(30.0,200.0,0.1) var camera_sensitivity : float = 50.0
@export_range(-360.0, 0.0, 0.01) var max_up_angle_view : float = -90.0 #in degrees
@export_range(0.0, 360.0, 0.01) var max_down_angle_view : float = 90.0 #in degrees
@export_range(5.0, 175.0, 0.01) var fov : float = 90.0
@export var DEFAULT_CAMERA = Camera3D

@onready var FIRST_CAMERA : Camera3D = %FirstPersonCamera
@onready var THIRD_CAMERA : Camera3D = %ThirdPersonCamera
@onready var THIRD_CAM_CONTROLLER : Node3D = %ThirdPersonCameraController
@onready var player : PlayerCharacter = $".."
var in_cutscene : bool = false
var in_subcam_transition : bool = false
var target_camera : String = "null"

#Third Person Variables
@onready var SPRINGPOSITION : Node3D = %SpringArmPosition

#State Variables

var state : String

@export_group("FOV Variables")
var fov_change_tween : Tween
@export_range(0.0, 180.0, 0.01) var min_fov_val : float = 10.0
@export_range(0.0, 180.0, 0.01) var max_fov_val : float = 170.0
@export var cam_fov_per_state : Dictionary[String, Vector2] = {
	#fov value, durations
	"Default" : Vector2(fov, 0.2),
	"Idle" : Vector2(fov, 0.2),
	"Running" : Vector2(fov + 5.0, 0.2),
	"Sliding" : Vector2(fov + 10.0, 0.2),
	"Dashing" : Vector2(fov + 15.0, 0.05),
	"Jumping" : Vector2 (fov + 10.0, 0.2),
	"Falling" : Vector2 (fov + 5.0 , 0.2),
	"DoubleJumping" : Vector2 (fov + 10.0, 0.2),
}

@export_group("Zoom Variables")
var zoom_on : bool = false
var zoom_has_occured : bool = false
@export_range(-180.0, 180.0, 1.0) var zoom_val : float = 40.0
@export_range(0.0, 3.0, 0.01) var zoom_duration : float = 0.05

@export_group("Tilt Variables")
@export var enable_forward_tilt : bool = true
@export var enable_side_tilt : bool = true
@export_range(0.0, 400.0, 0.1) var forward_move_tilt_divider : float = 260.0 #divider to add to the move speed calculated tilt value
@export_range(0.0, 7.0, 0.01) var forward_move_tilt_duration : float = 0.19
@export_range(0.0, 2.0, 0.001) var forward_move_max_tilt_val : float = 2.0
@export_range(0.0, 6.0, 0.1) var side_move_tilt_divider : float = 2.8
@export_range(0.0, 24.0, 0.01) var side_move_tilt_speed : float = 10.0
@export_range(0.0, 12.0, 0.001) var side_move_max_tilt_val : float = 7.0
var tilt_tween : Tween
var last_input_y : float
@export var tilt_props_per_state : Dictionary[String, Vector2] = {
	#lean value (in radians), lerp speed
	"Default" : Vector2(0.0, 7.5),
	"Sliding" : Vector2(-10.0, 7.5),
	"WallRunning" : Vector2(-12.0, 7.5)
}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#update fov for both cameras
	FIRST_CAMERA.fov = fov
	THIRD_CAMERA.fov = fov
	#make the correct camera the active camera
	if FIRST_CAMERA == DEFAULT_CAMERA:
		FIRST_CAMERA.make_current()
	elif THIRD_CAMERA == DEFAULT_CAMERA:
		THIRD_CAMERA.make_current()
	

func _unhandled_input(event: InputEvent) -> void:
	#convert mouse movement to rotational value, apply to camera
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * (camera_sensitivity / 10000))
		#update both camera rotations
		FIRST_CAMERA.rotate_x(-event.relative.y * (camera_sensitivity / 10000))
		THIRD_CAM_CONTROLLER.rotate_x(-event.relative.y * (camera_sensitivity / 10000))
		#lock the camera x rotation in deg_to_rad
		FIRST_CAMERA.rotation.x = clamp(FIRST_CAMERA.rotation.x, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))
		THIRD_CAM_CONTROLLER.rotation.x = clamp(THIRD_CAM_CONTROLLER.rotation.x, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))
	

func zoom() -> void:
	if Input.is_action_just_pressed("cam_zoom") && FIRST_CAMERA.current:
		zoom_on = !zoom_on
		if !zoom_on:
			zoom_has_occured = false
		
		change_fov()
		

func change_fov() -> void:
	#for state related fov change requests
	#if zoom is occuring, pass the rest of the function
	
	#manage the fov changes relative to a specific state
	state = player.state_machine.cur_state
	
	
	
	FIRST_CAMERA.fov = clamp(FIRST_CAMERA.fov, min_fov_val, max_fov_val)
	
	if !zoom_on || !zoom_has_occured:
		fov_change_tween = get_tree().create_tween()
		if cam_fov_per_state.has(state):
			fov_change_tween.tween_property(FIRST_CAMERA, "fov", cam_fov_per_state[state][0], cam_fov_per_state[state][1])
			fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
		else:
			#default value used for case like this one, when you need to force a fov change for a state that doesn't have his own setted fov
			fov_change_tween.tween_property(FIRST_CAMERA, "fov", cam_fov_per_state["Default"][0], cam_fov_per_state["Default"][1])
			fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
				
	#doesn't set zoom boolean to false right now, because we want the zoom to occur whatever the current state of play char is
	if zoom_on and !zoom_has_occured:
		zoom_has_occured = true
		fov_change_tween.tween_property(FIRST_CAMERA, "fov", FIRST_CAMERA.fov - zoom_val, zoom_duration)
		if !fov_change_tween.is_connected("finished", Callable(fov_change_tween, "kill")):
			fov_change_tween.finished.connect(Callable(fov_change_tween, "kill"))
	

func reset_tween():
	if tilt_tween and tilt_tween.is_running():
		tilt_tween.kill()
	tilt_tween = create_tween()

func tilt(delta : float) -> void:
	if state != "Sliding":
		if enable_forward_tilt:
			##forward (forward and backward movement) tilt
			#in most first person games, forward and backward tilt is not continious, but only applied at start of the movement
			#using a lerp will be counter productive, so in that case, we use a tween, to apply a one time camera rotation
			
			#use if sign() in the case of analogic sticks used
			var has_started_moving_forward = sign(player.input_dir.y) == 1 and sign(last_input_y) != 1
			var has_started_moving_backward = sign(player.input_dir.y) == -1 and sign(last_input_y) != -1
			
			#forward or backward input
			if has_started_moving_forward or has_started_moving_backward:
				reset_tween()
				var cam_x_rot_pre_tween : float = rotation.x
				var tilt_offset : float = clamp((-player.input_dir.y * player.move_speed) / forward_move_tilt_divider, -forward_move_max_tilt_val, forward_move_max_tilt_val)
				var tilt_target : float = clamp(cam_x_rot_pre_tween - tilt_offset, deg_to_rad(max_up_angle_view), deg_to_rad(max_down_angle_view))
				
				tilt_tween.tween_property(self, "rotation:x", tilt_target, forward_move_tilt_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tilt_tween.tween_property(self, "rotation:x", cam_x_rot_pre_tween, forward_move_tilt_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				
				tilt_tween.finished.connect(Callable(tilt_tween, "kill"))
		
			last_input_y = player.input_dir.y
			
		if enable_side_tilt:
			##side (left and right movement) tilt
			#in most first person games, lateral/side tilt is continious, so we use a lerp
			rotation_degrees.z = lerp(rotation_degrees.z,
			clamp((-player.input_dir.x * player.max_velocity_ground) / side_move_tilt_divider, -side_move_max_tilt_val, side_move_max_tilt_val), 
			side_move_tilt_speed * delta)
			
	#tilt for specific states, for example when wallrunning
	if state in tilt_props_per_state.keys():
		if state == "WallRunning" and player.side_check_raycast_collided != 0: #specific case for wallrun
			rotation_degrees.z = lerp(rotation_degrees.z, tilt_props_per_state[state][0] * -player.side_check_raycast_collided, tilt_props_per_state[state][1] * delta)
		else:
			rotation_degrees.z = lerp(rotation_degrees.z, tilt_props_per_state[state][0], tilt_props_per_state[state][1] * delta)
	else:
		#default camera rotation if no specific lean needs to be applied
		rotation_degrees.z = lerp(rotation_degrees.z, tilt_props_per_state["Default"][0], tilt_props_per_state["Default"][1] * delta)
	

func update_subcamera_position() -> void:
	if !in_cutscene && !in_subcam_transition:
		THIRD_CAMERA.position = SPRINGPOSITION.position


func subcamera_transition(delta: float, target: String) -> void:
	match target:
		"subcamera":
			THIRD_CAMERA.make_current()
			THIRD_CAMERA.position = lerp(THIRD_CAMERA.position, SPRINGPOSITION.position, 12 * delta)
			if THIRD_CAMERA.position == SPRINGPOSITION.position:
				in_subcam_transition = false
				target_camera = "null"
	
		"camera":
			THIRD_CAMERA.position = lerp(THIRD_CAMERA.position, Vector3(0.0,0.0,0.0), 12 * delta)
			if snapped(THIRD_CAMERA.position.z,0.1) == 0.0:
				THIRD_CAMERA.position.z = 0.0
				in_subcam_transition = false
				target_camera = "null"
				FIRST_CAMERA.make_current()
	

func _process(delta: float) -> void:
	state = player.state_machine.cur_state
	tilt(delta)
	
	change_fov()
	zoom()
	
	
	#update the third person camera position if in third person camera
	if THIRD_CAMERA.current:
		update_subcamera_position()
	
	#set up correct camera to transition to
	if Input.is_action_just_pressed("toggle_camera"):
		in_subcam_transition = true
		if THIRD_CAMERA.current:
			target_camera = "camera"
		elif FIRST_CAMERA.current:
			target_camera = "subcamera"
	
	#switch cameras
	if in_subcam_transition:
		subcamera_transition(delta, target_camera)
	
