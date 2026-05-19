extends State
class_name JumpState

var state_name : String = "Jump"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	
	if !play_char.can_wallrun:
		walljump()
	else:
		jump()


func physics_update(delta : float):
	play_char.update_input()
	applies(delta)
	play_char.update_gravity(delta)
	play_char.update_crouching(delta)
	move(delta)
	is_in_water()
	input_management()
	

func walljump() -> void:
	play_char.can_wallrun = false
	var wall_normal = play_char.wall_normal
	
	var horizontal_velocity := Vector3(play_char.velocity.x,0.0,play_char.velocity.z)
	
	#remove the speed directed toward the wall
	var into_wall_velocity := horizontal_velocity.dot(wall_normal)
	if into_wall_velocity < 0.0: horizontal_velocity -= wall_normal * into_wall_velocity
	
	#add an impulse to exit the wall
	horizontal_velocity += wall_normal * play_char.walljump_push_force
	
	#applies the calculated wall jump speed
	play_char.velocity.x = horizontal_velocity.x
	play_char.velocity.z = horizontal_velocity.z
	play_char.velocity.y = play_char.walljump_y_velocity
	
	play_char.walljump_lock_in_air_movement_time = play_char.walljump_lock_in_air_movement_time_ref


func jump():
	if play_char.coyote_jump_timer < play_char.max_jump_time:
		play_char.velocity.y = play_char.jump_strength
		play_char.wish_jump = false
	elif play_char.double_jumps > 0 && !play_char.is_on_wall():
		#if not inputing a direction, maintain velocity, cleaner movement
		if play_char.wish_dir != Vector3.ZERO:
			play_char.velocity = play_char.wish_dir * (play_char.max_velocity_ground + 4 if play_char.wish_sprint else play_char.max_velocity_ground)
		play_char.velocity.y = play_char.jump_strength
		play_char.wish_jump = false
		play_char.double_jumps -= 1


func input_management():
	if play_char.wish_noclip:
		transitioned.emit(self, "FlyState")
	elif play_char.wish_dash && play_char.can_enter_new_dash:
		transitioned.emit(self,"DashState")
	elif !play_char.is_on_floor():
		transitioned.emit(self, "InairState")
	elif play_char.is_on_floor():
		if round(play_char.velocity.length()) == 0.0:
			transitioned.emit(self, "IdleState")
		else:
			transitioned.emit(self, "WalkState")

func move(delta):
	if play_char.walljump_lock_in_air_movement_time <= 0.0:
		play_char.velocity.x = lerp(play_char.velocity.x, play_char.wish_dir.x * 0.5, 5.0 * delta)
		play_char.velocity.z = lerp(play_char.velocity.z, play_char.wish_dir.z * 0.5, 5.0 * delta)

func applies(delta):
	if play_char.walljump_lock_in_air_movement_time > 0.0: play_char.walljump_lock_in_air_movement_time -= delta
	if play_char.velocity.y < 0.0: transitioned.emit(self, "InairState")

func is_in_water() -> void:
	if get_tree().get_nodes_in_group("water_area").all(func(area): return !area.overlaps_body(play_char)):
		play_char.in_water =  false
	else: 
		play_char.in_water = true
		transitioned.emit(self,"WaterState")
