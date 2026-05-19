extends State
class_name CrouchState

var state_name := "Walk"

var play_char : CharacterBody3D

func enter(play_char_ref: CharacterBody3D) -> void:
	play_char = play_char_ref
	

func physics_update(delta : float):
	play_char.update_input()
	update_floor_functions()
	update_velocity_ground(play_char.max_velocity_ground * 0.5,delta)
	play_char.update_crouching(delta)
	
	is_in_water()
	input_management()
	

func update_floor_functions():
	play_char.double_jumps = play_char.max_double_jumps
	if play_char.can_enter_new_dash:
		play_char.dashes = play_char.max_dashes
	play_char.coyote_jump_timer = 0.0

func update_velocity_ground(vel:float,delta) -> void:
	#get current speed
	var speed = play_char.velocity.length()
	#find out how much we should stop, what our friction should be
	if speed != 0.0:
		var control = max(play_char.stop_speed, speed)
		var drop = control * play_char.friction * delta
		if play_char.is_crouching:
			drop *= 2.0
		
		#scale velocity to friction
		play_char.velocity *= max(speed - drop, 0.0) / speed
	
	play_char.velocity = accelerate(vel, delta)

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
	elif !play_char.is_on_floor():
		transitioned.emit(self, "InairState")
	
	elif play_char.is_on_floor():
		if play_char.velocity.length() > 0.2:
			transitioned.emit(self, "WalkState")
		else:
			transitioned.emit(self,"IdleState")
	

func is_in_water() -> void:
	if get_tree().get_nodes_in_group("water_area").all(func(area): return !area.overlaps_body(play_char)):
		play_char.in_water =  false
	else: 
		play_char.in_water = true
		transitioned.emit(self,"WaterState")
