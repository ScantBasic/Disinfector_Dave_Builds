class_name Sliding
extends PlayerMovement

func physics_update(delta):
	PLAYER.update_timers(delta)
	PLAYER.update_input()
	PLAYER.update_jumping(delta)
	if !PLAYER.is_sliding:
		PLAYER.start_slide()
	PLAYER.update_slide(delta)
	PLAYER.update_crouching(delta)
	PLAYER.update_velocity()
	PLAYER.end_slide()
	PLAYER.CAMERA_POSITION.position.y = move_toward(PLAYER.CAMERA_POSITION.position.y, 1.8 - PLAYER.CROUCH_TRANSLATE if PLAYER.is_crouching else 1.8, delta * 8.0)
	PLAYER.cam_bob_time = 0.0
	
	if PLAYER.is_on_floor():
		if !PLAYER.is_sliding:
			if PLAYER.is_crouching:
				transition.emit("Crouching")
			elif round(PLAYER.velocity.length()) == 0.0:
				transition.emit("Idle")
			elif round(PLAYER.velocity.length()) > 0.0:
				if PLAYER.wish_sprint:
					transition.emit("Sprinting")
				else:
					transition.emit("Walking")
		
	
	elif !PLAYER.is_on_floor():
		transition.emit("Airborne")
		
