extends UnitBase
class_name JeepHumvee

func _ready() -> void:
	unit_name = "Humvee .50 Cal"
	move_speed = 10.5
	turn_speed = 9.0
	max_health = 180.0
	attack_range = 15.0
	attack_damage = 12.0
	attack_cooldown = 1.0
	super._ready()

func _fire_weapon() -> void:
	if not is_instance_valid(target_unit):
		return
		
	cooldown_timer = attack_cooldown
	# Rajada rápida de 3 tiros calibre .50
	_fire_bullet(0.0)
	get_tree().create_timer(0.12).timeout.connect(func(): if is_instance_valid(self): _fire_bullet(1.0))
	get_tree().create_timer(0.24).timeout.connect(func(): if is_instance_valid(self): _fire_bullet(2.0))

func _fire_bullet(_burst_idx: float) -> void:
	if not is_instance_valid(target_unit):
		return
		
	var spawn_pos: Vector3 = global_position + Vector3(0, 1.8, 0)
	if fire_point:
		spawn_pos = fire_point.global_position
	elif turret:
		spawn_pos = turret.global_position - turret.global_transform.basis.z * 1.2
		
	var target_hit_pos := target_unit.global_position + Vector3(0, 0.6, 0)
	
	var proj := ProjectileScene.instantiate()
	get_parent().add_child(proj)
	proj.setup(spawn_pos, target_hit_pos, attack_damage, target_unit)
	
	if SoundManager.instance:
		SoundManager.instance.play_cannon_shot()
