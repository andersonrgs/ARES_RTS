extends Node3D

const ExplosionScene = preload("res://scenes/effects/explosion_effect.tscn")

@export var speed: float = 35.0
@export var damage: float = 30.0
@export var max_lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var target_unit: Node = null
var target_pos: Vector3 = Vector3.ZERO
var lifetime: float = 0.0

func setup(origin: Vector3, destination: Vector3, damage_amount: float, target: Node = null) -> void:
	global_position = origin
	target_pos = destination
	target_unit = target
	damage = damage_amount
	direction = (destination - origin).normalized()
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		_impact()
		return
		
	var move_dist := speed * delta
	var to_target := (target_pos - global_position)
	
	if to_target.length() <= move_dist:
		global_position = target_pos
		_impact()
	else:
		global_position += direction * move_dist

func _impact() -> void:
	# Spawna efeito de explosão
	var explosion := ExplosionScene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	# Aplica dano ao alvo se ainda válido
	if is_instance_valid(target_unit) and target_unit.has_method("take_damage"):
		target_unit.take_damage(damage)
		
	queue_free()
