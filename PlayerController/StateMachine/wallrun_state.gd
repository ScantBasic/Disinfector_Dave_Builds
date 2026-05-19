extends State
class_name WallrunState

var state_name := "Wallrun"

var play_char : CharacterBody3D

func enter(play_char_ref : CharacterBody3D) -> void:
	play_char = play_char_ref
	wallrun_forward_direction_calculus()
	play_char.velocity.y = 0.0


func physics_update(delta : float) -> void:
	applies(delta)
	gravity_with_modifier(delta)
	
	is_in_water()
	input_management()
	
	move(delta)

func gravity_with_modifier(delta) -> void:
	play_char.velocity.y -= play_char.GRAVITY * play_char.wallrun_grav_mult * delta



func wallrun_forward_direction_calculus():
	#get wall normal
	if play_char.side_check_raycast_collided == -1:
		play_char.wall_normal = play_char.left_wall_check.get_collision_normal()
	if play_char.side_check_raycast_collided == 1:
		play_char.wall_normal = play_char.right_wall_check.get_collision_normal()
		
	#calculate the forward direction of the wall the player character will move to
	play_char.wall_forward_dir = (play_char.velocity.normalized() - play_char.wall_normal * \
	play_char.velocity.normalized().dot(play_char.wall_normal)).normalized()

func move(delta : float) -> void:
	
	if Input.is_action_pressed("move_forward"):
			play_char.velocity.x = lerp(play_char.velocity.x, play_char.wall_forward_dir.x * 14.0, 2.3 * delta)
			play_char.velocity.z = lerp(play_char.velocity.z, play_char.wall_forward_dir.z * 14.0, 2.3 * delta)
			
	else:
		play_char.can_wallrun = false
		transitioned.emit(self, "InairState")
		

func applies(delta : float) -> void:
	wallrun_forward_direction_calculus()
	if play_char.wallrun_time > 0.0: play_char.wallrun_time -= delta
	else:
		play_char.can_wallrun = false
		play_char.last_wallrunned_wall_out_of_time = play_char.side_check_raycast_collided #get last wall side where play char wallrunned
		transitioned.emit(self, "InairState")
		
	if (!play_char.is_on_floor() and !play_char.is_on_wall() and \
	!play_char.left_wall_check.is_colliding() and !play_char.right_wall_check.is_colliding()) or \
	play_char.wallrun_floor_check.is_colliding():
		play_char.can_wallrun = false
		transitioned.emit(self, "InairState")

func input_management() -> void:
	if Input.is_action_just_pressed("jump"):
		play_char.can_wallrun = false
		transitioned.emit(self, "JumpState")
	is_in_water()

func is_in_water() -> void:
	if get_tree().get_nodes_in_group("water_area").all(func(area): return !area.overlaps_body(play_char)):
		play_char.in_water =  false
	else: 
		play_char.in_water = true
		play_char.can_wallrun = false
		transitioned.emit(self,"WaterState")
