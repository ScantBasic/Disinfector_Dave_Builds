extends PlayerState
class_name DoubleJumping

func enter(_previous_state_path: String) -> void:
	player.double_jumps -= 1
	if player.wish_dir != Vector3.ZERO:
		player.velocity = player.wish_dir * max(player.max_velocity_ground,Vector2(player.velocity.x,player.velocity.z).length())
	player.velocity.y = player.jump_power
	player.can_wallrun = true

func physics_update(delta: float) -> void:
	player.update_inputs()
	player.velocity.y -= player.gravity * delta
	player.coyote_time += delta
	update_velocity_air(delta)
	player.update_crouching(delta)
	state_change_rules()

func accelerate(max_velocity: float, delta) -> Vector3:
	#current speed compared to wish_dir
	var cur_speed = player.velocity.dot(player.wish_dir)
	#how much we need to accelerate
	var add_speed = clamp(max_velocity - cur_speed, 0.0, player.max_acceleration * delta)
	
	return player.velocity + add_speed * player.wish_dir

func update_velocity_air(delta: float) -> void:
	if player. locked_air_movement_time <= 0.0:
		player.velocity = accelerate(player.max_air_velocity, delta)

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
	if player.velocity.y <= 0:
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("slide") && player.can_enter_new_dash && player.dashes > 0:
		finished.emit(DASHING)
	wall_check()
