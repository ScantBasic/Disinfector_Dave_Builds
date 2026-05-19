extends State
class_name DashState

var state_name := "Dash"

var play_char : CharacterBody3D

func enter(play_char_ref: CharacterBody3D) -> void:
	play_char = play_char_ref
	

func physics_update(delta : float):
	play_char.update_input()
	if !play_char.is_dashing:
		start_dash()
	update_dash()
	play_char.update_crouching(delta)
	end_dash()
	input_management()
	is_in_water()

func get_dash_direction() -> Vector3:
	#return what 3d space our input is facing
	if play_char.input_dir.length() > 0:
		var cam_basis = play_char.cam.global_transform.basis
		return (cam_basis * play_char.input_dir).normalized()
	else:
	# Default: camera forward
		var forward : Vector3 = -play_char.cam.global_transform.basis.z
		return forward.normalized()

func start_dash() -> void:
	play_char.dash_tmr = play_char.dash_total_time
	play_char.dashes -= 1
	play_char.velocity = get_dash_direction() * play_char.dash_velocity
	play_char.is_dashing = true
	play_char.can_enter_new_dash = false

func update_dash() -> void:
	play_char.velocity = get_dash_direction() * play_char.dash_velocity

func end_dash():
	if play_char.is_on_wall() || play_char.dash_tmr <= 0.0:
		play_char.is_dashing = false
		


func input_management():
	
	if !play_char.is_dashing:
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
		play_char.is_dashing = false
		transitioned.emit(self,"WaterState")
