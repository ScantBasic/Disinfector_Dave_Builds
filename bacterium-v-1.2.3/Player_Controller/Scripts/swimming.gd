extends PlayerState
class_name Swimming

func physics_update(delta: float) -> void:
	player.update_inputs()
	water_physics(delta)
	player.velocity.y -= player.gravity * delta * player.sinking_gravity_mult
	player.update_crouching(delta)
	state_change_rules()

func water_physics(delta) -> void:
	player.velocity += player.wish_dir * player.swimming_speed * delta
	
	if Input.is_action_pressed("jump"):
		player.velocity.y += player.swim_up_speed * delta
	elif Input.is_action_pressed("crouch"):
		player.velocity.y -= player.swim_up_speed * 1.5 * delta
	
	player.velocity = player.velocity.lerp(Vector3.ZERO, 2 * delta)

func state_change_rules():
	if player.wading_detect.has_overlapping_areas() && !player.swimming_detect.has_overlapping_areas():
		finished.emit(WADING)
	if !player.wading_detect.has_overlapping_areas() && !player.swimming_detect.has_overlapping_areas():
		if !player.is_on_floor():
			finished.emit(FALLING)
		elif Input.is_action_just_pressed("slide") && player.can_enter_new_dash && player.dashes > 0:
			finished.emit(DASHING)
		elif player.is_on_floor():
			if player.input_dir == Vector3.ZERO:
				finished.emit(IDLE)
			else:
				finished.emit(RUNNING)
