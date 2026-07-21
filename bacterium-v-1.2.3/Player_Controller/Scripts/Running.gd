extends PlayerState
class_name Running

func enter(_previous_state_path: String) -> void:
	player.can_wallrun = true
	player.coyote_time = 0.0
	player.double_jumps = player.max_double_jumps
	player.dashes = player.max_dashes
	player.locked_air_movement_time = 0.0
	player.walljumps = player.max_walljumps

func update(_delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	player.update_inputs()
	update_velocity_ground(player.max_velocity_ground,delta)
	player.velocity.y -= player.gravity * delta
	player.update_crouching(delta)
	state_change_rules()

func update_velocity_ground(vel:float,delta) -> void:
	#get current speed
	var speed = player.velocity.length()
	#find out how much we should stop, what our friction should be
	if speed != 0.0:
		var control = max(player.stop_speed, speed)
		var drop = control * player.friction * delta
		if player.is_crouching:
			drop *= 4.0
		
		#scale velocity to friction
		player.velocity *= max(speed - drop, 0.0) / speed
	
	player.velocity = accelerate(vel, delta)

func accelerate(max_velocity: float, delta) -> Vector3:
	#current speed compared to wish_dir
	var cur_speed = player.velocity.dot(player.wish_dir)
	#how much we need to accelerate
	var add_speed = clamp(max_velocity - cur_speed, 0.0, player.max_acceleration * delta)
	
	return player.velocity + add_speed * player.wish_dir

func state_change_rules():
	if !player.is_on_floor():
		finished.emit(FALLING)
	elif player.wading_detect.has_overlapping_areas():
		finished.emit(WADING)
	elif Input.is_action_just_pressed("jump"):
		finished.emit(JUMPING)
	elif Input.is_action_just_pressed("slide"):
		finished.emit(SLIDING)
	elif player.input_dir == Vector3.ZERO:
		finished.emit(IDLE)
