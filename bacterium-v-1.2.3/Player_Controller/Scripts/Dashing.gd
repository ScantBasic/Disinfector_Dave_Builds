extends PlayerState
class_name Dashing

var dash_dir := Vector3.ZERO
var remaining_dash_time := 0.0

func enter(_previous_state_path: String) -> void:
	player.dashes -= 1
	player.can_enter_new_dash = false
	remaining_dash_time = player.total_dash_time
	dash_dir = get_dash_direction()

func get_dash_direction() -> Vector3:
	#return what 3d space our input is facing
	if player.input_dir.length() > 0:
		var cam_basis = player.cam.global_transform.basis
		return (cam_basis * player.input_dir).normalized()
	else:
	# Default: camera forward
		var forward : Vector3 = -player.cam.global_transform.basis.z
		return forward.normalized()

func physics_update(delta: float) -> void:
	player.update_inputs()
	update_velocity_dash()
	player.update_crouching(delta)
	end_dash_logic()

func update(_delta: float) -> void:
	remaining_dash_time -= _delta

func update_velocity_dash() -> void:
	player.velocity.x = dash_dir.x * player.dash_velocity
	player.velocity.z = dash_dir.z * player.dash_velocity
	player.velocity.y = dash_dir.y * player.dash_velocity_y

func end_dash_logic() -> void:
	if player.is_on_wall() || remaining_dash_time <= 0.0 || player.is_on_floor():
		player.can_enter_new_dash = false
		player.time_before_can_dash_again = maxf(player.minimum_dash_delay, player.total_dash_time + 0.1)
		if !player.is_on_floor():
			player.velocity.x *= 0.75
			player.velocity.z *= 0.75
		state_change_rules()

func wall_check() -> void:
	if player.locked_air_movement_time <= 0.0 && Input.is_action_pressed("move_forward"):
		if player.can_wallrun and player.is_on_wall() and !player.floor_check.is_colliding():
			if player.left_wall_check.is_colliding() and !player.right_wall_check.is_colliding() and \
			player.last_wallrunned_wall_out_of_time != -1:
				player.side_check_raycast_collided = -1
				player.last_wallrunned_wall_out_of_time = 0
				finished.emit(WALLRUNNING)
			elif !player.left_wall_check.is_colliding() and player.right_wall_check.is_colliding() and \
			player.last_wallrunned_wall_out_of_time != 1:
				player.side_check_raycast_collided = 1
				player.last_wallrunned_wall_out_of_time = 0
				finished.emit(WALLRUNNING)

func state_change_rules():
	if !player.is_on_floor():
		finished.emit(FALLING)
	elif player.input_dir != Vector3.ZERO:
		finished.emit(RUNNING)
	else:
		finished.emit(IDLE)
	wall_check()
	
