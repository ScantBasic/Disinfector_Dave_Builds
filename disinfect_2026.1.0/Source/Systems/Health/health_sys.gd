class_name Health_Sys extends Node

signal health_changed(cur_hp: int, max_hp: int)
signal died()

@export var init_max_hitpoints : float = 1
@export var fix_floating_nums : bool = false
var max_hitpoints : float = 1
var cur_hitpoints : float = 1

func _ready() -> void:
	max_hitpoints = init_max_hitpoints
	cur_hitpoints = init_max_hitpoints

func take_damage(damage_amount: float) -> void:
	#check if alive first
	if cur_hitpoints <= 0:
		return
	
	#makes the damage a flat value for simplicity
	if fix_floating_nums:
		damage_amount = round(damage_amount)
	
	#change our health and say we changed out health
	cur_hitpoints = max(0, cur_hitpoints - damage_amount)
	health_changed.emit(cur_hitpoints, max_hitpoints)
	
	#check if died
	if cur_hitpoints <= 0:
		died.emit()

func heal(amount: float) -> void:
	#adjust if meant to be an int
	if  fix_floating_nums:
		amount = round(amount)
	#change HP with respect to max health
	cur_hitpoints = min(cur_hitpoints + amount, max_hitpoints)
	health_changed.emit(cur_hitpoints, max_hitpoints)

func is_alive() -> bool:
	return cur_hitpoints > 0

func set_max_hitpoints(hitpoints: float) -> void:
	max_hitpoints = round(hitpoints)

func set_cur_hitpoints(value: float) -> void:
	cur_hitpoints = value
	if cur_hitpoints > max_hitpoints:
		cur_hitpoints = max_hitpoints
	
	if fix_floating_nums:
		cur_hitpoints = round(cur_hitpoints)

func get_health_precentage() -> float:
	if max_hitpoints <= 0:
		return 0.0
	
	return cur_hitpoints / max_hitpoints
