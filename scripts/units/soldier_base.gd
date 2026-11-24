extends UnitBase
class_name SoldierBase

@export var visuals_body: Node3D
@export var legs_left: Node3D
@export var legs_right: Node3D
@export var rifle_node: Node3D
@export var muzzle_flash: OmniLight3D

var walk_phase: float = 0.0

func _ready() -> void:
	unit_name = "Ranger da Infantaria"
	max_health = 80.0
	move_speed = 5.2
	turn_speed = 12.0
	attack_range = 13.0
	attack_damage = 9.0
	attack_cooldown = 0.65
	super._ready()
	
	if muzzle_flash:
		muzzle_flash.visible = false

func _process(delta: float) -> void:
	super._process(delta)
	_animate_infantry(delta)

func _animate_infantry(delta: float) -> void:
	var is_moving := velocity.length() > 0.2
	
	if is_moving:
		walk_phase += delta * 12.0
		# Movimento pendular das pernas e leve oscilação vertical do tronco
		if legs_left:
			legs_left.rotation.x = sin(walk_phase) * 0.45
		if legs_right:
			legs_right.rotation.x = -sin(walk_phase) * 0.45
		if visuals_body:
			visuals_body.position.y = 0.85 + abs(sin(walk_phase * 2.0)) * 0.05
	else:
		walk_phase = 0.0
		if legs_left:
			legs_left.rotation.x = lerp_angle(legs_left.rotation.x, 0.0, 10.0 * delta)
		if legs_right:
			legs_right.rotation.x = lerp_angle(legs_right.rotation.x, 0.0, 10.0 * delta)
		if visuals_body:
			# Respiração sutil em repouso
			visuals_body.position.y = 0.85 + sin(Time.get_ticks_msec() * 0.003) * 0.02

func _fire_weapon() -> void:
	super._fire_weapon()
	_flash_muzzle()

func _flash_muzzle() -> void:
	if muzzle_flash:
		muzzle_flash.visible = true
		get_tree().create_timer(0.06).timeout.connect(func(): if is_instance_valid(muzzle_flash): muzzle_flash.visible = false)
