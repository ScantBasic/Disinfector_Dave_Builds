extends Control

@onready var PauseMenu: Control = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameplayGlobalScript.is_game_paused:
		PauseMenu.show()
	else:
		PauseMenu.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		GameplayGlobalScript.is_game_paused = ! GameplayGlobalScript.is_game_paused
	
	if GameplayGlobalScript.is_game_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		PauseMenu.show()
		Engine.time_scale = 0.0

	elif !GameplayGlobalScript.is_game_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		PauseMenu.hide()
		Engine.time_scale = 1.0


func _on_resume_pressed() -> void:
	GameplayGlobalScript.is_game_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	PauseMenu.hide()
	Engine.time_scale = 1.0


func _on_exit_pressed() -> void:
	get_tree().quit()
