extends State

class_name InairState

var state_name : String = "Inair"

var play_char : CharacterBody3D

func enter(play_char_ref: CharacterBody3D) -> void:
	play_char = play_char_ref
	

func physics_update(delta : float):
	play_char.update_input()
	play_char.coyote_jump_timer += delta
	if play_char.walljump_lock_in_air_movement_time > 0.0: play_char.walljump_lock_in_air_movement_time -= delta
	play_char.update_gravity(delta)
	update_velocity_air(delta)
	play_char.update_crouching(delta)
	
	is_in_water()
	input_management()
	
	wall_check()
	

func update_velocity_air(delta) -> void:
	if play_char.walljump_lock_in_air_movement_time <= 0.0:
		play_char.velocity = accelerate(play_char.max_velocity_air, delta)

func accelerate(max_velocity: float, delta) -> Vector3:
	#current speed compared to wish_dir
	var cur_speed = play_char.velocity.dot(play_char.wish_dir)
	#how much we need to accelerate
	var add_speed = clamp(max_velocity - cur_speed, 0.0, play_char.max_acceleration * delta)
	
	return play_char.velocity + add_speed * play_char.wish_dir


func input_management():
	if play_char.wish_noclip:
		transitioned.emit(self, "FlyState")
	elif play_char.wish_jump:
		transitioned.emit(self,"JumpState")
	elif play_char.wish_dash && play_char.can_enter_new_dash:
		transitioned.emit(self,"DashState")
	elif play_char.is_on_floor():
		if play_char.wish_crouch:
			transitioned.emit(self, "CrouchState")
		elif play_char.velocity.length() > 0.2:
			transitioned.emit(self, "WalkState")
		else:
			transitioned.emit(self,"IdleState")

func wall_check() -> void:
	if play_char.walljump_lock_in_air_movement_time <= 0.0 && Input.is_action_pressed("move_forward"):
		if play_char.can_wallrun and (play_char.is_on_wall()) and !play_char.wallrun_floor_check.is_colliding():
			if play_char.left_wall_check.is_colliding() and !play_char.right_wall_check.is_colliding() and \
			play_char.last_wallrunned_wall_out_of_time != -1:
				play_char.side_check_raycast_collided = -1
				play_char.last_wallrunned_wall_out_of_time = 0
				transitioned.emit(self, "WallrunState")
			elif !play_char.left_wall_check.is_colliding() and play_char.right_wall_check.is_colliding() and \
			play_char.last_wallrunned_wall_out_of_time != 1:
				play_char.side_check_raycast_collided = 1
				play_char.last_wallrunned_wall_out_of_time = 0
				transitioned.emit(self, "WallrunState")
			else:
				return
			

func is_in_water() -> void:
	if get_tree().get_nodes_in_group("water_area").all(func(area): return !area.overlaps_body(play_char)):
		play_char.in_water =  false
	else: 
		play_char.in_water = true
		transitioned.emit(self,"WaterState")
