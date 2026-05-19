extends State
class_name WaterState

var state_name := "Water"

var play_char : CharacterBody3D

var water_above : bool = false


func enter(play_char_ref: CharacterBody3D) -> void:
	play_char = play_char_ref
	

func physics_update(delta : float):
	play_char.update_input()
	
	
	check_if_water_above()
	water_physics(delta)
	play_char.update_crouching(delta)
	
	is_in_water()
	input_management()

func water_physics(delta) -> void:
	if play_char.is_on_floor() && !water_above:
		transitioned.emit(self, "WalkState")
	else:
		gravity_with_modifier(delta)
		
		play_char.velocity += play_char.wish_dir * play_char.water_speed * delta
		if Input.is_action_pressed("jump"):
			play_char.velocity.y += play_char.swim_up_speed * delta
		
		if Input.is_action_pressed("crouch"):
			play_char.velocity.y -= play_char.swim_up_speed * delta * 1.5
		
		
		play_char.velocity = play_char.velocity.lerp(Vector3.ZERO, 2 * delta)

func gravity_with_modifier(delta) -> void:
	play_char.velocity.y -= play_char.GRAVITY * play_char.sink_speed_mult * delta

func check_if_water_above():
	if play_char.water_above_check.is_colliding():
		var collider = play_char.water_above_check.get_collider()
		if collider.is_in_group("water_area"):
			water_above = true
		else:
			water_above = false
	
	elif !play_char.water_above_check.is_collidng():
		water_above = false

func input_management():
	
	if !play_char.in_water:
		if play_char.wish_jump:
			transitioned.emit(self,"JumpState")
		elif !play_char.is_on_floor():
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
