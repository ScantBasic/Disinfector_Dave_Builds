extends Node
class_name State

#Signal emmitted when a state is finished and needs to transition into another
signal finished(next_state_path: String, data: Dictionary)

#Called for unhandled input events, try to avoid using
func handle_input(_event: InputEvent) -> void:
	pass

# Called on the process loop
func update(_delta: float) -> void:
	pass

# Called in the physics process loop
func physics_update(_delta: float) -> void:
	pass

#used to enter the new state
func enter(_previous_state_path: String) -> void:
	pass

#used to cleanly exit the state
func exit() -> void:
	pass
