class_name Crouching
extends PlayerMovement

func physics_update(delta):
	PLAYER.update_input()
	PLAYER.update_jumping(delta)
	PLAYER.update_velocity_ground(PLAYER.max_velocity_ground * 0.5, delta)
	PLAYER.update_crouching(delta)
	PLAYER.update_velocity()
	PLAYER.cam_bob_time += delta * PLAYER.velocity.length()
	PLAYER.CAMERA_POSITION.position.y = move_toward(PLAYER.CAMERA_POSITION.position.y, PLAYER._headbob(PLAYER.cam_bob_time), delta * 8.0)
	
	if PLAYER.wish_noclip:
		transition.emit("NoClip")
	elif PLAYER.wish_dash && PLAYER.can_enter_new_dash:
		transition.emit("Dashing")
	elif PLAYER.is_on_floor():
		if !PLAYER.is_crouching:
			if round(PLAYER.velocity.length()) == 0.0:
				transition.emit("Idle")
			
			if round(PLAYER.velocity.length()) > 0.0:
				if PLAYER.wish_sprint:
					transition.emit("Sprinting")
				else:
					transition.emit("Walking")
		
	
	elif !PLAYER.is_on_floor():
		transition.emit("Airborne")
