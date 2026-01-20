extends Control

@onready var player: CharacterBody3D = $"../.."
@onready var debug_info : MarginContainer = $MarginContainer
@onready var state_label : Label = $"MarginContainer/Panel/HBoxContainer/VBoxContainer/State Label"
@onready var velocity_label : Label = $"MarginContainer/Panel/HBoxContainer/VBoxContainer/Velocity Label"
@onready var position_label : Label = $"MarginContainer/Panel/HBoxContainer/VBoxContainer/Position Label"
@onready var vel_length_label : Label = $"MarginContainer/Panel/HBoxContainer/VBoxContainer/Velocity Length Label"
@onready var framerate_label : Label = $"MarginContainer/Panel/HBoxContainer/VBoxContainer/FrameRate Label"
@onready var health_label : Label = $"MarginContainer/Panel/HBoxContainer/VBoxContainer/Health Label"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameplayGlobalScript.debug:
		debug_info.show()
	else:
		debug_info.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	state_label.text = "State: " + str(player.PlayerState.keys()[player.state])
	velocity_label.text = "Velocity: " + str(snapped(player.velocity.x, 0.01))+ "," + str(snapped(player.velocity.y, 0.01))+ ","  + str(snapped(player.velocity.z, 0.01))
	position_label.text = "Coords: " + str(round(player.global_position.x)) +","+str(round(player.global_position.y)) +","+str(round(player.global_position.z))
	vel_length_label.text = "Velocity Length: " + str(snapped(player.velocity.length(),0.01))
	framerate_label.text = "FPS: " + str(Engine.get_frames_per_second())
	health_label.text = "HP: " + str(player.health_component.cur_hitpoints)
