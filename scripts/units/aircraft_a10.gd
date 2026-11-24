extends Node3D
class_name AircraftA10

const ProjectileScene = preload("res://scenes/effects/projectile_shell.tscn")
const SoundManager = preload("res://scripts/systems/sound_manager.gd")

@export var fly_speed: float = 48.0
var flight_direction: Vector3 = Vector3.FORWARD
var target_ground_pos: Vector3 = Vector3.ZERO
var total_travel: float = 0.0
var has_dropped_payload: bool = false

func setup_strike(target: Vector3) -> void:
	target_ground_pos = target
	flight_direction = Vector3(0, 0, -1).normalized()
	
	# Inicia 70m atrás do alvo a uma altitude de 15m
	global_position = target - flight_direction * 70.0 + Vector3(0, 15.0, 0)
	look_at(global_position + flight_direction, Vector3.UP)
	
	if SoundManager.instance:
		SoundManager.instance.play_jet_flyby()

func _process(delta: float) -> void:
	var move_dist := fly_speed * delta
	global_position += flight_direction * move_dist
	total_travel += move_dist
	
	# Quando estiver passando por cima do alvo, solta o bombardeio
	var dist_to_target_x_z := Vector2(global_position.x - target_ground_pos.x, global_position.z - target_ground_pos.z).length()
	if dist_to_target_x_z < 8.0 and not has_dropped_payload:
		has_dropped_payload = true
		_drop_bomb_carpet()
		
	# Após percorrer 160m, o caça some do mapa
	if total_travel >= 160.0:
		queue_free()

func _drop_bomb_carpet() -> void:
	for i in range(3):
		var offset := flight_direction * float(i - 1) * 6.0
		var drop_pos := global_position - Vector3(0, 2.0, 0) + offset
		var impact_pos := target_ground_pos + offset
		
		var bomb := ProjectileScene.instantiate()
		get_parent().add_child(bomb)
		bomb.setup(drop_pos, impact_pos, 95.0, null)
