extends State
class_name FlyState

var state_name := "Fly"

var play_char : CharacterBody3D

func enter(play_char_ref: CharacterBody3D) -> void:
	play_char = play_char_ref
	

func physics_update(delta : float):
	play_char.update_input()
	process_noclip(delta)
	play_char.update_crouching(delta)
	input_management()


func process_noclip(delta):
	# Some basic movement things if we dont have collision
	play_char.hitbox.disabled = play_char.wish_noclip
	play_char.velocity = Vector3.ZERO
	var noclip_vel = Vector3.ZERO
	noclip_vel = play_char.wish_dir * play_char.max_velocity_ground
	if Input.is_action_pressed("crouch"):
		noclip_vel.y -= play_char.max_velocity_ground
	if Input.is_action_pressed("jump"):
		noclip_vel.y += play_char.max_velocity_ground
	
	if Input.is_action_pressed("sprint"):
		noclip_vel *= 3
	
	play_char.global_position += noclip_vel * delta

func input_management():
	
	if !play_char.wish_noclip:
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
		
