class_name PlayerMovement
extends State

var PLAYER: Player

func _ready() -> void:
	await owner.ready
	PLAYER = owner as Player

func _process(_delta: float) -> void:
	pass
