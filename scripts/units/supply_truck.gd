extends CharacterBody3D
class_name SupplyTruck

const SupplyDock = preload("res://scripts/buildings/supply_dock.gd")
const GameEconomy = preload("res://scripts/systems/game_economy.gd")
const ExplosionScene = preload("res://scenes/effects/explosion_effect.tscn")

@export var unit_name: String = "Caminhao de Suprimentos"
@export var team_id: int = 0
@export var max_health: float = 160.0
@export var current_health: float = 160.0
@export var move_speed: float = 8.5
@export var turn_speed: float = 9.0
@export var capacity: int = 300

@export var nav_agent: NavigationAgent3D
@export var cargo_crates: Node3D
@export var selection_ring: Node3D

enum TruckState { IDLE, MOVING_TO_DOCK, COLLECTING, MOVING_TO_CENTER, UNLOADING }
var current_state: TruckState = TruckState.IDLE

var target_dock: Node = null
var home_center: Node = null
var current_cargo: int = 0
var wait_timer: float = 0.0
var economy: GameEconomy = null

func _ready() -> void:
	current_health = max_health
	add_to_group("units")
	add_to_group("supply_trucks")
	
	if not nav_agent:
		nav_agent = get_node_or_null("NavigationAgent3D")
	if not selection_ring:
		selection_ring = get_node_or_null("SelectionRing")
	if not cargo_crates:
		cargo_crates = get_node_or_null("Visuals/CargoCrates")
		
	_set_cargo_visible(false)
	set_selected(false)
	
	economy = get_tree().root.find_child("GameEconomy", true, false)
	_start_harvesting_cycle()

func set_selected(selected: bool) -> void:
	if selection_ring:
		selection_ring.visible = selected

func _start_harvesting_cycle() -> void:
	target_dock = _find_nearest_dock()
	if target_dock:
		current_state = TruckState.MOVING_TO_DOCK
		if nav_agent:
			nav_agent.target_position = target_dock.global_position
	else:
		current_state = TruckState.IDLE

func _physics_process(delta: float) -> void:
	if not nav_agent:
		return

	match current_state:
		TruckState.IDLE:
			velocity = Vector3.ZERO
			# Tenta buscar doca periodicamente
			wait_timer += delta
			if wait_timer >= 2.0:
				wait_timer = 0.0
				_start_harvesting_cycle()

		TruckState.MOVING_TO_DOCK:
			if not is_instance_valid(target_dock):
				_start_harvesting_cycle()
				return
				
			var dist := global_position.distance_to(target_dock.global_position)
			if dist <= 4.0:
				velocity = Vector3.ZERO
				current_state = TruckState.COLLECTING
				wait_timer = 2.0 # 2 segundos carregando
			else:
				_perform_movement(delta)

		TruckState.COLLECTING:
			velocity = Vector3.ZERO
			wait_timer -= delta
			if wait_timer <= 0.0:
				if is_instance_valid(target_dock) and target_dock.has_method("harvest"):
					current_cargo = target_dock.harvest(capacity)
				else:
					current_cargo = capacity
				_set_cargo_visible(true)
				
				# Procura o Centro de Suprimentos para descarregar
				home_center = _find_nearest_center()
				if home_center:
					current_state = TruckState.MOVING_TO_CENTER
					nav_agent.target_position = home_center.global_position
				else:
					current_state = TruckState.IDLE

		TruckState.MOVING_TO_CENTER:
			if not is_instance_valid(home_center):
				home_center = _find_nearest_center()
				if not home_center:
					current_state = TruckState.IDLE
					return
					
			var dist := global_position.distance_to(home_center.global_position)
			if dist <= 5.0:
				velocity = Vector3.ZERO
				current_state = TruckState.UNLOADING
				wait_timer = 1.5 # 1.5 segundo descarregando
			else:
				_perform_movement(delta)

		TruckState.UNLOADING:
			velocity = Vector3.ZERO
			wait_timer -= delta
			if wait_timer <= 0.0:
				if economy and current_cargo > 0:
					economy.add_credits(current_cargo)
				current_cargo = 0
				_set_cargo_visible(false)
				# Retorna para buscar mais suprimentos!
				_start_harvesting_cycle()

func _perform_movement(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
		
	var next_pos := nav_agent.get_next_path_position()
	var dir := (next_pos - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	
	if dir.length() > 0.01:
		var target_rot_y := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, turn_speed * delta)
		
	velocity = dir * move_speed
	move_and_slide()

func _set_cargo_visible(has_cargo: bool) -> void:
	if cargo_crates:
		cargo_crates.visible = has_cargo

func _find_nearest_dock() -> Node:
	var docks := get_tree().get_nodes_in_group("supply_docks")
	var closest: Node = null
	var min_dist := 9999.0
	for d in docks:
		if is_instance_valid(d) and d.current_supplies > 0:
			var dist := global_position.distance_to(d.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = d
	return closest

func _find_nearest_center() -> Node:
	var buildings := get_tree().get_nodes_in_group("buildings")
	var closest: Node = null
	var min_dist := 9999.0
	for b in buildings:
		if is_instance_valid(b) and b.team_id == self.team_id and b.building_name == "Centro de Suprimentos":
			var dist := global_position.distance_to(b.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = b
	return closest

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	if current_health <= 0.0:
		var exp := ExplosionScene.instantiate()
		get_parent().add_child(exp)
		exp.global_position = global_position
		queue_free()
