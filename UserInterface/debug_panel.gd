extends PanelContainer

var property
@onready var property_container = $MarginContainer/VBoxContainer

func _ready() -> void:
	GlobalController.DEBUG = self
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		visible = !visible
	

func add_property(title: String, value, order):
	var target
	target = property_container.find_child(title,true,false)
	if !target:
		target = Label.new()
		property_container.add_child(target)
		target.name = title
		target.text = target.name + ": " + str(value)
		property_container.move_child(target,order)
	elif visible:
		target.text = target.name + ": " + str(value)
		property_container.move_child(target,order)
