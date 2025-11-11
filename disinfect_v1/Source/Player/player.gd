extends CharacterBody3D

# Enumerate all possible player states.
# The player can only be in ONE of these per frame.
enum PlayerState { IDLE, WALKING, SPRINTING, CROUCHING, AIRBORNE, SLIDING }



# --- ASSORTED USAGE VARIABLES ---
# Needed for multiple parts of system
var input_dir = Vector3.ZERO

# --- MICRO STATES ---
var crouching = false
var sliding = false

# --- MOVEMENT TUNING VARIABLES ---
# Speeds for different movement types
@export var walk_speed := 8.0
var sprint_speed := walk_speed * 1.75
var crouch_speed := walk_speed * 0.75

# How fast the player accelerates toward their target speed
@export var ground_accel := 10.0
@export var air_accel := 0.1
@export var friction := 7.0

# Jump and gravity control
@export var gravity := 27.5
@export var jump_force := 10.0
@export var max_bhop_speed := 32.0   # Max speed retention when bunny hopping

# How high we can step up ledges, and some bools for checking whats going on
const MAX_STEP_HEIGHT := 0.5
var snapped_to_stairs_last_frame := false
var last_frame_was_on_floor = -INF

# Crouching stuff
const HEIGHT := 2.0            # default standing height
const CROUCH_TRANSLATE := 0.7
const CROUCHJUMPBONUS := CROUCH_TRANSLATE * 0.9


# --- CAMERA FEEL VARIABLES ---

@export var mouse_sensitivity := 100
@export var cam_bob_intensity := 0.07     # Up/down offset while walking
@export var cam_bob_speed := 10.0         # Frequency of bobbing
@export var cam_smooth := 6.0             # How smoothly camera lerps to target
@export var land_bob_intensity := 2.5     # How far camera dips when landing
@export var land_bob_speed := 12.0        # How fast it returns up after landing

# --- NODE REFERENCES ---
@onready var cam_pivot : Node3D = $Camera_Controller
@onready var cam : Camera3D = $Camera_Controller/Camera
@onready var collisionshape : CollisionShape3D = $Collision
@onready var stair_ahead_check : RayCast3D = $Stair_Ahead_Check
@onready var stair_below_check : RayCast3D = $Stair_Below_Check


# --- INTERNAL STATE VARIABLES ---
var velocity_y := 0.0             # vertical velocity for gravity/jumping
var wish_dir := Vector3.ZERO      # direction based on input and camera facing

var state := PlayerState.IDLE     # current player state
var cam_bob_time := 0.0           # timer for walk bobbing
var target_cam_pos := Vector3.ZERO  # original resting camera position
var land_bob_offset := 10.0        # camera offset when landing
var was_on_floor := false         # used to detect landing
var land_timer := 0.0             # timer for landing bob

# --- SETUP ---
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	target_cam_pos = cam_pivot.position

# --- CAMERA ROTATION VARIABLES ---
var yaw := 0.0
var pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0
@export var look_smoothness := 12.0  # how quickly camera catches up to input

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Update target rotation values instantly based on input
		target_yaw -= event.relative.x * mouse_sensitivity/50000
		cam_pivot.rotation.x -= event.relative.y * mouse_sensitivity/50000
		# Clamp pitch so we can't flip upside down
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		

# --- MAIN UPDATE LOOP ---
func _physics_process(delta):
	handle_input()        # Read movement / sprint / crouch input
	update_state()        # Decide which state we are in
	process_state(delta)  # Execute state-specific movement
	if ! _snap_up_stairs_check(delta):  # Step up small ledges
		move_and_slide()      # Apply velocity to physics system
		_snap_down_to_stairs_check() #step down small ledges
	handle_landing(delta) # Check if we've just landed
	# --- CAMERA ROTATION SMOOTHING ---
	yaw = lerp_angle(yaw, target_yaw, delta * look_smoothness)

	# Apply the smoothed rotation
	rotation.y = yaw
	
	update_camera(delta)  # Apply head bob and camera smoothing




# --- INPUT HANDLING ---
func handle_input():
	# Get directional input as vector (WASD)
	input_dir = Vector3.ZERO
	input_dir.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_dir.z = Input.get_action_strength("Backward") - Input.get_action_strength("Forward")

	# Convert input direction from local space to world space based on facing
	wish_dir = (global_transform.basis * input_dir).normalized()

# --- STATE MACHINE LOGIC ---
func update_state():
	# If not on the ground, always airborne.
	if not is_on_floor():
		state = PlayerState.AIRBORNE
		return

	# On the ground: choose a state based on inputs
	if crouching:
		state = PlayerState.CROUCHING
	elif Input.is_action_pressed("Sprint") and wish_dir.length() > 0:
		if Input.is_action_just_pressed("Crouch"):
			state = PlayerState.SLIDING
		else:
			state = PlayerState.SPRINTING
	elif wish_dir.length() > 0:
		state = PlayerState.WALKING
	else:
		state = PlayerState.IDLE

# --- STATE MACHINE EXECUTION ---
func process_state(delta):
	match state:
		PlayerState.IDLE:
			process_ground_movement(delta, walk_speed)
			apply_friction(delta)
			handle_jump(delta)
			handle_crouch(delta)

		PlayerState.WALKING:
			process_ground_movement(delta, walk_speed)
			handle_jump(delta)
			handle_crouch(delta)

		PlayerState.SPRINTING:
			process_ground_movement(delta, sprint_speed)
			handle_jump(delta)
			handle_crouch(delta)

		PlayerState.CROUCHING:
			process_ground_movement(delta, crouch_speed)
			handle_jump(delta)
			handle_crouch(delta)

		PlayerState.AIRBORNE:
			process_air_movement(delta)
			handle_crouch(delta)

# --- GROUND MOVEMENT ---
func process_ground_movement(delta, target_speed):
	# Only affect horizontal movement; vertical handled separately
	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	var target_vel = wish_dir * target_speed

	# Smoothly move current horizontal velocity toward target
	horiz_vel = horiz_vel.lerp(target_vel, ground_accel * delta)

	# Update velocity components
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z
	velocity.y = velocity_y

# --- AIR MOVEMENT (bunny-hop and air control) ---
func process_air_movement(delta):
	# Apply gravity
	velocity_y -= gravity * delta

	# Separate horizontal velocity
	var horiz_vel = Vector3(velocity.x, 0, velocity.z)
	var horiz_speed = horiz_vel.length()

	if wish_dir.length() == 0:
		# No input, just keep momentum and gravity
		velocity.x = horiz_vel.x
		velocity.z = horiz_vel.z
		velocity.y = velocity_y
		return

	# --- SOURCE-STYLE AIR CONTROL / STRAFING ---
	# Determine how aligned we are with current velocity
	var wish_speed = max_bhop_speed
	var dot = horiz_vel.dot(wish_dir.normalized())
	var k = 24.0  # Strength of air control (higher = tighter strafing)

	var accel_dir = wish_dir.normalized()

	# Apply acceleration perpendicular to velocity for smoother control
	if horiz_speed > 0:
		var vel_dir = horiz_vel.normalized()
		var perpendicular = (accel_dir - vel_dir * vel_dir.dot(accel_dir)).normalized()
		horiz_vel += perpendicular * air_accel * k * delta

	# Limit final speed to max
	if horiz_vel.length() > wish_speed:
		horiz_vel = horiz_vel.normalized() * wish_speed

	# Update velocity
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.z
	velocity.y = velocity_y

# --- FRICTION WHEN STOPPED ---
func apply_friction(delta):
	if wish_dir.length() == 0:
		var horiz_vel = Vector3(velocity.x, 0, velocity.z)
		var drop = horiz_vel.length() * friction * delta
		var new_speed = max(horiz_vel.length() - drop, 0)
		horiz_vel = horiz_vel.normalized() * new_speed if new_speed > 0 else Vector3.ZERO
		velocity.x = horiz_vel.x
		velocity.z = horiz_vel.z

# --- JUMPING / SPEED RETENTION ---
func handle_jump(delta):
	var coyote_tmr : float
	if is_on_floor():
		last_frame_was_on_floor = Engine.get_physics_frames()
		
		coyote_tmr = 0
	else:
		coyote_tmr += delta
	
	
	if coyote_tmr <= 0.2 and Input.is_action_just_pressed("Jump"):
		velocity_y = jump_force

		# Bunny-hop momentum carry:
		# If player has high horizontal speed, preserve some when jumping.
		var horiz_speed = Vector3(velocity.x, 0, velocity.z).length()
		if horiz_speed > walk_speed:
			var velocity_scale = clamp(horiz_speed / sprint_speed, 1.0, 1.3)
			velocity.x *= velocity_scale
			velocity.z *= velocity_scale

# --- CROUCH TOGGLE ---
func handle_crouch(delta) -> void:
	var was_crouched_last_frame = crouching
	
	
	if Input.is_action_pressed("Crouch"):
		crouching = true
	elif crouching && ! self.test_move(self.transform, Vector3(0,CROUCH_TRANSLATE,0)):
		crouching = false
	else:
		if Input.is_action_just_pressed("Crouch"):
			crouching = crouching
	
	if sliding:
		crouching = true
	
	var translate_y_if_possible := 0.0
	if was_crouched_last_frame != crouching and not is_on_floor():
		translate_y_if_possible = CROUCHJUMPBONUS if crouching else -CROUCHJUMPBONUS
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.transform,Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
		cam_pivot.position.y -= result.get_travel().y
	
	@warning_ignore("incompatible_ternary")
	cam_pivot.position.y = move_toward(cam_pivot.position.y, -CROUCH_TRANSLATE + 1.8 if crouching else 1.8, 7.5 * delta)
	collisionshape.shape.height = HEIGHT - CROUCH_TRANSLATE if crouching else HEIGHT
	collisionshape.position.y = collisionshape.shape.height /2
	$PlaceHolder_Mesh.mesh.height = collisionshape.shape.height
	$PlaceHolder_Mesh.position.y = collisionshape.position.y

# --- STEP-UP LOGIC ---
# Lets the player walk up small ledges (like stairs) instead of hitting an invisible wall.

# Code found at https://www.youtube.com/watch?v=Tb-R3l0SQdc, this guy is cool.

# Check if possible to go up
func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func _snap_down_to_stairs_check() -> void:
	var did_snap := false
	# Since it is called after move_and_slide, _last_frame_was_on_floor should still be current frame number.
	# After move_and_slide off top of stairs, on floor should then be false. Update raycast incase it's not already.
	stair_below_check.force_raycast_update()
	var floor_below : bool = stair_below_check.is_colliding() and not is_surface_too_steep(stair_below_check.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() == last_frame_was_on_floor
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		if self.test_move(self.global_transform, Vector3(0,-MAX_STEP_HEIGHT,0), body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	snapped_to_stairs_last_frame = did_snap

func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not snapped_to_stairs_last_frame: return false
	# Don't snap stairs if trying to jump, also no need to check for stairs ahead if not moving
	if self.velocity.y > 0 or (self.velocity * Vector3(1,0,1)).length() == 0: return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	# Run a body_test_motion slightly above the pos we expect to move to, towards the floor.
	#  We give some clearance above to ensure there's ample room for the player.
	#  If it hits a step <= MAX_STEP_HEIGHT, we can teleport the player on top of the step
	#  along with their intended motion forward.
	var down_check_result = KinematicCollision3D.new()
	if (self.test_move(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		# Note I put the step_height <= 0.01 in just because I noticed it prevented some physics glitchiness
		# 0.02 was found with trial and error. Too much and sometimes get stuck on a stair. Too little and can jitter if running into a ceiling.
		# The normal character controller (both jolt & default) seems to be able to handled steps up of 0.1 anyway
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - self.global_position).y > MAX_STEP_HEIGHT: return false
		stair_ahead_check.global_position = down_check_result.get_position() + Vector3(0,MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		stair_ahead_check.force_raycast_update()
		if stair_ahead_check.is_colliding() and not is_surface_too_steep(stair_ahead_check.get_collision_normal()):
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			snapped_to_stairs_last_frame = true
			return true
	return false


# --- LANDING DETECTION ---
# Detect when the player hits the ground to trigger a short camera "thud"
func handle_landing(delta):
	if was_on_floor == false and is_on_floor():
		# Player has just landed this frame
		land_bob_offset = -land_bob_intensity
		land_timer = 0.0

	# Remember ground state for next frame
	was_on_floor = is_on_floor()

	# Gradually move camera offset back to zero
	if land_bob_offset < 0:
		land_timer += delta * land_bob_speed
		land_bob_offset = lerp(land_bob_offset, 0.0, land_timer)

# --- CAMERA EFFECTS ---
func update_camera(delta):
	# Calculate horizontal speed for bobbing
	var horiz_speed = Vector3(velocity.x, 0, velocity.z).length()

	# Update bobbing phase
	if is_on_floor() and horiz_speed > 0.1:
		cam_bob_time += delta * cam_bob_speed * clamp(horiz_speed / sprint_speed, 0.5, 1.2)
	else:
		 # fade out bob smoothly in air
		cam_bob_time = lerp(cam_bob_time, 0.0, delta * 2.0)
		cam_bob_intensity = lerp(cam_bob_intensity, 0.0, delta * 6.0)

	# Calculate offset from sine wave for walking bob
	var bob_offset = Vector3(0, sin(cam_bob_time * 2.0) * cam_bob_intensity, 0)

	# Combine walk bob and landing offset
	var desired_pos = target_cam_pos + bob_offset + Vector3(0, land_bob_offset, 0)

	# Smoothly interpolate camera to new position if we have movement input
	cam_pivot.position = cam_pivot.position.lerp(desired_pos, delta * cam_smooth)
