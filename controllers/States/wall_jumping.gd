class_name WallRunning
extends PlayerMovement

func physics_update(delta):
	PLAYER.update_input()
	PLAYER.update_timers(delta)
	PLAYER.gravity_with_multiplier(delta, 0.06)
	PLAYER.update_jumping(delta)
	PLAYER.wall_check()
	PLAYER.update_velocity_wallrun(delta)
	PLAYER.update_crouching(delta)
	PLAYER.update_velocity()
	PLAYER.CAMERA_POSITION.position.y = move_toward(PLAYER.CAMERA_POSITION.position.y, 1.8 - PLAYER.CROUCH_TRANSLATE if PLAYER.is_crouching else 1.8, delta * 8.0)
	PLAYER.cam_bob_time = 0.0
	
	if PLAYER.wish_noclip:
		transition.emit("NoClip")
	elif PLAYER.wish_dash && PLAYER.can_enter_new_dash:
		transition.emit("Dashing")
	elif PLAYER.is_on_floor():
		if PLAYER.is_crouching:
			transition.emit("Crouching")
		elif round(PLAYER.velocity.length()) == 0.0:
			transition.emit("Idle")
		elif round(PLAYER.velocity.length()) > 0.0:
			if PLAYER.wish_sprint:
				transition.emit("Sprinting")
			else:
				transition.emit("Walking")
	elif !PLAYER.is_on_floor() && !PLAYER.is_on_wall():
		transition.emit("Airborne")
