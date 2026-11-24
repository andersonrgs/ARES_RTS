extends CharacterBody3D
class_name UnitBase

signal health_changed(current_hp: float, max_hp: float)
signal unit_selected(is_selected: bool)

const ProjectileScene = preload("res://scenes/effects/projectile_shell.tscn")
const ExplosionScene = preload("res://scenes/effects/explosion_effect.tscn")
const SoundManager = preload("res://scripts/systems/sound_manager.gd")

@export_group("Faction & Stats")
@export var unit_name: String = "Crusader Tank"
@export var team_id: int = 0  # 0 = Aliado/Jogador, 1 = Inimigo
@export var max_health: float = 250.0
@export var current_health: float = 250.0
@export var move_speed: float = 7.0
@export var turn_speed: float = 8.0
@export var attack_range: float = 16.0
@export var attack_damage: float = 35.0
@export var attack_cooldown: float = 1.8
@export var turret_turn_speed: float = 5.0

@export_group("References")
@export var selection_ring: Node3D
@export var nav_agent: NavigationAgent3D
@export var turret: Node3D
@export var barrel: Node3D
@export var fire_point: Node3D
@export var health_bar_mesh: MeshInstance3D

enum UnitState { IDLE, MOVING, ATTACKING }
var current_state: UnitState = UnitState.IDLE

var is_selected: bool = false
var target_unit: UnitBase = null
var cooldown_timer: float = 0.0
var manual_attack_order: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("units")
	
	if not nav_agent:
		nav_agent = get_node_or_null("NavigationAgent3D")
	if not selection_ring:
		selection_ring = get_node_or_null("SelectionRing")
	if not turret:
		turret = get_node_or_null("Visuals/Turret")
	if not fire_point:
		fire_point = get_node_or_null("Visuals/Turret/FirePoint")
		
	set_selected(false)
	_update_health_display()

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected
	if selected and team_id == 0 and SoundManager.instance:
		SoundManager.instance.play_radio_ack()
	emit_signal("unit_selected", selected)

func move_to_target(target_point: Vector3) -> void:
	target_unit = null
	manual_attack_order = false
	current_state = UnitState.MOVING
	if nav_agent:
		nav_agent.target_position = target_point

func attack_target(enemy: UnitBase) -> void:
	if not is_instance_valid(enemy) or enemy == self:
		return
	target_unit = enemy
	manual_attack_order = true
	current_state = UnitState.ATTACKING

func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	_handle_target_acquisition()
	_handle_turret_aim(delta)

func _physics_process(delta: float) -> void:
	if not nav_agent:
		return
		
	match current_state:
		UnitState.IDLE:
			velocity = Vector3.ZERO
			
		UnitState.MOVING:
			if nav_agent.is_navigation_finished():
				current_state = UnitState.IDLE
				velocity = Vector3.ZERO
				return
			_perform_movement(delta)
			
		UnitState.ATTACKING:
			if not is_instance_valid(target_unit):
				target_unit = null
				current_state = UnitState.IDLE
				velocity = Vector3.ZERO
				return
				
			var dist := global_position.distance_to(target_unit.global_position)
			if dist > attack_range:
				# Se estiver fora do alcance, anda até aproximar
				nav_agent.target_position = target_unit.global_position
				_perform_movement(delta)
			else:
				# Dentro do alcance: para e atira
				velocity = Vector3.ZERO

func _perform_movement(delta: float) -> void:
	var next_path_pos := nav_agent.get_next_path_position()
	var move_direction := (next_path_pos - global_position)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	if move_direction.length() > 0.01:
		var target_rotation_y := atan2(-move_direction.x, -move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation_y, turn_speed * delta)
		
	velocity = move_direction * move_speed
	move_and_slide()

func _handle_target_acquisition() -> void:
	# Se já temos um alvo válido e vivo, mantenha
	if is_instance_valid(target_unit) and target_unit.current_health > 0:
		var dist := global_position.distance_to(target_unit.global_position)
		if manual_attack_order or dist <= attack_range * 1.3:
			return

	# Busca automática de inimigos mais próximos no raio de visão
	target_unit = null
	var closest_dist := attack_range
	var all_units := get_tree().get_nodes_in_group("units")
	
	for node in all_units:
		if node is UnitBase and node != self and is_instance_valid(node):
			if node.team_id != self.team_id and node.current_health > 0:
				var d := global_position.distance_to(node.global_position)
				if d <= closest_dist:
					closest_dist = d
					target_unit = node

func _handle_turret_aim(delta: float) -> void:
	if not turret:
		return
		
	if is_instance_valid(target_unit):
		var target_pos := target_unit.global_position
		var local_target := turret.global_transform.affine_inverse() * target_pos
		var target_angle := atan2(-local_target.x, -local_target.z)
		
		turret.rotation.y = lerp_angle(turret.rotation.y, turret.rotation.y + target_angle, turret_turn_speed * delta)
		
		# Checa se o canhão está alinhado com o alvo e pronto para atirar
		var dist := global_position.distance_to(target_pos)
		if dist <= attack_range and abs(target_angle) < 0.25 and cooldown_timer <= 0.0:
			_fire_weapon()
	else:
		# Volta o canhão suavemente para a frente
		turret.rotation.y = lerp_angle(turret.rotation.y, 0.0, turret_turn_speed * 0.5 * delta)

func _fire_weapon() -> void:
	if not is_instance_valid(target_unit):
		return
		
	cooldown_timer = attack_cooldown
	
	# Determina a posição de saída do tiro
	var spawn_pos: Vector3 = global_position + Vector3(0, 1.2, 0)
	if fire_point:
		spawn_pos = fire_point.global_position
	elif turret:
		spawn_pos = turret.global_position - turret.global_transform.basis.z * 1.5
		
	var target_hit_pos := target_unit.global_position + Vector3(0, 0.8, 0)
	
	# Instancia o projétil balístico
	var proj := ProjectileScene.instantiate()
	get_parent().add_child(proj)
	proj.setup(spawn_pos, target_hit_pos, attack_damage, target_unit)
	
	if SoundManager.instance:
		SoundManager.instance.play_cannon_shot()

func take_damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	_update_health_display()
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0.0:
		_on_death()

func _update_health_display() -> void:
	if health_bar_mesh:
		var ratio := current_health / max_health
		health_bar_mesh.scale.x = max(0.01, ratio)

func _on_death() -> void:
	var explosion := ExplosionScene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	queue_free()
