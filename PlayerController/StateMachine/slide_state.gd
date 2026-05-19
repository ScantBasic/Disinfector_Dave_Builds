extends State
class_name SlideState

var state_name := "Slide"

var play_char : CharacterBody3D

func enter(play_char_ref: CharacterBody3D) -> void:
	play_char = play_char_ref
	

func physics_update(delta : float):
	play_char.update_input()
	update_floor_functions()
	if !play_char.is_sliding:
		start_slide()
	update_slide(delta)
	play_char.update_crouching(delta)
	end_slide()
	
	is_in_water()
	input_management()
	

func update_floor_functions():
	play_char.double_jumps = play_char.max_double_jumps
	if play_char.can_enter_new_dash:
		play_char.dashes = play_char.max_dashes
	play_char.coyote_jump_timer = 0.0

func start_slide() -> void:
	play_char.is_sliding = true
	play_char.velocity += play_char.wish_dir * play_char.slide_start_bonus

func end_slide() -> void:
	var horiz_vel = Vector3(play_char.velocity.x,0,play_char.velocity.z)
	if play_char.is_on_wall() || abs(horiz_vel.length()) < 3.0 || !play_char.is_on_floor():
		play_char.is_sliding = false

func update_slide(delta) -> void:
	var speed = play_char.velocity.length()
	if speed != 0.0:
		var control = max(play_char.slide_stop_speed, speed)
		var drop = control * play_char.slide_friction * delta
		#scale velocity to friction
		play_char.velocity *= max(speed - drop, 0.0) / speed

func input_management():
	if play_char.wish_jump:
		transitioned.emit(self,"JumpState")
		play_char.is_sliding = false
	
	if !play_char.is_sliding:
		if !play_char.is_on_floor():
			transitioned.emit(self, "InairState")
		elif play_char.is_on_floor():
			if play_char.wish_crouch:
				transitioned.emit(self, "CrouchState")
			elif play_char.wish_sprint:
				transitioned.emit(self, "RunState")
			elif play_char.velocity.length() > 0.2:
				transitioned.emit(self,"WalkState")
			else:
				transitioned.emit(self, "IdleState")
		

func is_in_water() -> void:
	if get_tree().get_nodes_in_group("water_area").all(func(area): return !area.overlaps_body(play_char)):
		play_char.in_water =  false
	else: 
		play_char.in_water = true
		play_char.is_sliding = false
		transitioned.emit(self,"WaterState")
