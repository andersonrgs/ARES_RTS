extends StaticBody3D
class_name SupplyDock

signal supplies_depleted

@export var max_supplies: int = 15000
@export var current_supplies: int = 15000
@export var crates_visual: Node3D

func _ready() -> void:
	current_supplies = max_supplies
	add_to_group("supply_docks")
	add_to_group("buildings")

func harvest(amount: int) -> int:
	if current_supplies <= 0:
		return 0
	var gathered := mini(amount, current_supplies)
	current_supplies -= gathered
	_update_crates_visual()
	if current_supplies <= 0:
		emit_signal("supplies_depleted")
	return gathered

func _update_crates_visual() -> void:
	if crates_visual:
		var ratio := float(current_supplies) / float(max_supplies)
		crates_visual.scale.y = max(0.2, ratio)
