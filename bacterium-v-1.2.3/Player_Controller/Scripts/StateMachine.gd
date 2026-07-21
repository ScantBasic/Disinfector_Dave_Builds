extends Node
class_name StateMachine

#the initial state of the state machine. Use first child node if not set.
@export var initial_state: State = null
var cur_state : String = "Idle"
var player : PlayerCharacter

#current state of state machine
@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)).call()

func _ready() -> void:
	# Give all children states a reference to state machine
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to_next_state)
	
	# Wait for owner to finish startup
	await owner.ready
	state.enter("")
	player = owner

func _transition_to_next_state(target_state_path: String, _data: Dictionary = {}) -> void:
	if ! has_node(target_state_path):
		printerr(owner.name + ": Trying to transition into state " + target_state_path + 
		" but it does not exist")
		return
	
	var previous_state_path := state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path)

# Run state functions
func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

func _process(delta: float) -> void:
	state.update(delta)
	cur_state = state.name
	

func _physics_process(delta: float) -> void:
	state.physics_update(delta)
