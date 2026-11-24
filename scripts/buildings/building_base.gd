extends StaticBody3D
class_name BuildingBase

signal health_changed(current_hp: float, max_hp: float)
signal building_selected(is_selected: bool)

const ExplosionScene = preload("res://scenes/effects/explosion_effect.tscn")
const GameEconomy = preload("res://scripts/systems/game_economy.gd")
const SupplyTruckScene = preload("res://scenes/units/supply_truck.tscn")

@export_group("Building Stats")
@export var building_name: String = "Building"
@export var team_id: int = 0
@export var cost: int = 500
@export var power_production: int = 0
@export var power_consumption: int = 0
@export var max_health: float = 1000.0
@export var current_health: float = 1000.0

@export_group("References")
@export var selection_ring: Node3D
@export var health_bar_mesh: MeshInstance3D
@export var spawn_point: Node3D

var is_selected: bool = false
var economy_ref: GameEconomy = null

func _ready() -> void:
	current_health = max_health
	add_to_group("buildings")
	set_selected(false)
	_update_health_display()
	
	# Registra consumo e produção de energia no sistema de economia
	economy_ref = get_tree().root.find_child("GameEconomy", true, false)
	if economy_ref:
		economy_ref.register_building_power(power_production, power_consumption)
		
	if building_name == "Centro de Suprimentos":
		call_deferred("_spawn_initial_truck")

func _spawn_initial_truck() -> void:
	spawn_unit(SupplyTruckScene)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected
	emit_signal("building_selected", selected)

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	_update_health_display()
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0.0:
		_on_destruction()

func _update_health_display() -> void:
	if health_bar_mesh:
		var ratio := current_health / max_health
		health_bar_mesh.scale.x = max(0.01, ratio)

func spawn_unit(unit_scene: PackedScene) -> Node:
	if not unit_scene:
		return null
		
	var spawn_pos: Vector3 = global_position + Vector3(0, 0, 5)
	if spawn_point:
		spawn_pos = spawn_point.global_position
		
	var unit := unit_scene.instantiate()
	get_parent().add_child(unit)
	unit.global_position = spawn_pos
	
	# Manda a unidade recém-construída andar um pouco para fora do portão da fábrica
	if unit.has_method("move_to_target"):
		unit.move_to_target(spawn_pos + Vector3(0, 0, 4))
		
	return unit

func _on_destruction() -> void:
	if economy_ref:
		economy_ref.unregister_building_power(power_production, power_consumption)
		
	var explosion := ExplosionScene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	queue_free()
