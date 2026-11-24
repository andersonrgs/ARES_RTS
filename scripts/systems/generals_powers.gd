extends Node
class_name GeneralsPowers

signal powers_cooldown_updated(scan_cd: float, strike_cd: float)

const A10Scene = preload("res://scenes/units/aircraft_a10.tscn")
const SoundManager = preload("res://scripts/systems/sound_manager.gd")
const FogOfWar = preload("res://scripts/systems/fog_of_war.gd")

@export var max_scan_cd: float = 25.0
@export var max_strike_cd: float = 35.0

var scan_timer: float = 0.0
var strike_timer: float = 0.0

enum PowerTargetMode { NONE, SCAN, AIRSTRIKE }
var current_mode: PowerTargetMode = PowerTargetMode.NONE

var camera: Camera3D
var fog_ref: FogOfWar

func _ready() -> void:
	fog_ref = get_tree().root.find_child("FogOfWar", true, false)

func _process(delta: float) -> void:
	if scan_timer > 0.0:
		scan_timer = max(0.0, scan_timer - delta)
	if strike_timer > 0.0:
		strike_timer = max(0.0, strike_timer - delta)
		
	emit_signal("powers_cooldown_updated", scan_timer, strike_timer)

func trigger_satellite_scan_targeting() -> void:
	if scan_timer <= 0.0:
		current_mode = PowerTargetMode.SCAN

func trigger_airstrike_targeting() -> void:
	if strike_timer <= 0.0:
		current_mode = PowerTargetMode.AIRSTRIKE

func _unhandled_input(event: InputEvent) -> void:
	if current_mode == PowerTargetMode.NONE:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var target_pos := _get_ground_mouse_pos(event.position)
			if target_pos != Vector3.ZERO:
				_execute_power(target_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			current_mode = PowerTargetMode.NONE
			
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		current_mode = PowerTargetMode.NONE

func _execute_power(target_pos: Vector3) -> void:
	match current_mode:
		PowerTargetMode.SCAN:
			scan_timer = max_scan_cd
			if not fog_ref:
				fog_ref = get_tree().root.find_child("FogOfWar", true, false)
			if fog_ref and fog_ref.has_method("_stamp_vision"):
				# Revela permanentemente essa área e arredores
				fog_ref._stamp_vision(target_pos, 32.0)
			if SoundManager.instance:
				SoundManager.instance.play_radio_ack()
				
		PowerTargetMode.AIRSTRIKE:
			strike_timer = max_strike_cd
			var jet := A10Scene.instantiate()
			get_parent().add_child(jet)
			jet.setup_strike(target_pos)
			
	current_mode = PowerTargetMode.NONE

func _get_ground_mouse_pos(screen_pos: Vector2) -> Vector3:
	if not camera:
		camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO
		
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 1000.0
	var space := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space.intersect_ray(query)
	
	if result:
		return result.position
	return Vector3.ZERO
