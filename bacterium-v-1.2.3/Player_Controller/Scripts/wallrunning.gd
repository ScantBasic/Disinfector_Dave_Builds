extends PlayerState
class_name WallRunning

func enter(_previous_state_path: String) -> void:
	wallrun_forward_direction_calculus()
	player.velocity.y = 0.0
	player.wallrun_time = player.max_wallrun_time


func physics_update(delta: float) -> void:
	player.update_inputs()
	wallrun_forward_direction_calculus()
	end_wallrun_checks(delta)
	player.velocity.y -= player.gravity * delta * player.wallrun_grav_mult
	wallrun_movement_physics(delta)
	player.update_crouching(delta)
	
	state_change_rules()


func wallrun_forward_direction_calculus():
	#get wall normal
	if player.side_check_raycast_collided == -1:
		player.wall_normal = player.left_wall_check.get_collision_normal()
	if player.side_check_raycast_collided == 1:
		player.wall_normal = player.right_wall_check.get_collision_normal()
		
	#calculate the forward direction of the wall the player character will move to
	player.wall_forward_dir = (player.velocity.normalized() - player.wall_normal * \
	player.velocity.normalized().dot(player.wall_normal)).normalized()

func wallrun_movement_physics(delta: float) -> void:
	if Input.is_action_pressed("move_forward"):
		player.velocity.x = lerp(player.velocity.x, player.wall_forward_dir.x * player.wallrun_speed, 2.3 * delta)
		player.velocity.z = lerp(player.velocity.z, player.wall_forward_dir.z * player.wallrun_speed, 2.3 * delta)
		
	else:
		player.can_wallrun = false
		finished.emit(FALLING)

func end_wallrun_checks(delta : float) -> void:
	if player.wallrun_time > 0.0:
		player.wallrun_time -= delta
	else:
		player.can_wallrun = false
		player.last_wallrunned_wall_out_of_time = player.side_check_raycast_collided
		finished.emit(FALLING)
	if (!player.is_on_floor() && !player.is_on_wall() && !player.left_wall_check.is_colliding() \
	&& !player.right_wall_check.is_colliding() || player.floor_check.is_colliding()):
		player.can_wallrun = false
		finished.emit(FALLING)

func state_change_rules():
	if player.wallrun_time <= 0.0 || !player.can_wallrun:
		player.can_wallrun = false
		finished.emit(FALLING)
	if Input.is_action_just_pressed("jump") && player.walljumps > 0:
				player.can_wallrun = false
				finished.emit(WALLJUMPING)
