extends PlayerState
class_name Sliding

func enter(_previous_state_path: String) -> void:
	player.coyote_time = 0.0
	player.double_jumps = player.max_double_jumps
	player.dashes = player.max_dashes
	player.locked_air_movement_time = 0.0
	player.walljumps = player.max_walljumps
	player.is_sliding = true
	player.velocity += player.wish_dir * player.slide_start_bonus

func update_slide(delta) -> void:
	var speed = player.velocity.length()
	if speed != 0.0:
		var control = max(player.slide_stop_speed, speed)
		var drop = control * player.slide_friction * delta
		#scale velocity to friction
		player.velocity *= max(speed - drop, 0.0) / speed
		player.apply_floor_snap()

func test_end_slide() -> void:
	var horiz_vel = Vector3(player.velocity.x,0,player.velocity.z)
	if player.is_on_wall() || abs(horiz_vel.length()) < player.slide_stop_speed || !player.is_on_floor():
		player.is_sliding = false


func physics_update(delta: float) -> void:
	player.update_inputs()
	update_slide(delta)
	player.update_crouching(delta)
	test_end_slide()
	state_change_rules()

func state_change_rules():
	if Input.is_action_just_pressed("jump") && (player.is_on_floor() || player.coyote_time < 0.2):
		player.is_sliding = false
		player.velocity.x *= 1.15
		player.velocity.z *= 1.15
		finished.emit(JUMPING)
	if !player.is_sliding:
		if !player.is_on_floor():
			finished.emit(FALLING)
		elif player.input_dir != Vector3.ZERO:
			finished.emit(RUNNING)
		else:
			finished.emit(IDLE)
