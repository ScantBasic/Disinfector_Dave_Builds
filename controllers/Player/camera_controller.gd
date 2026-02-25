extends Node3D

var PLAYER: Player

func _ready() -> void:
	await owner.ready
	PLAYER = owner as Player

func _physics_process(delta: float) -> void:
	PLAYER._update_camera(delta)
