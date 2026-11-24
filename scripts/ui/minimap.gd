extends Control
class_name Minimap

const UnitBase = preload("res://scripts/units/unit_base.gd")
const BuildingBase = preload("res://scripts/buildings/building_base.gd")

@export var map_size: float = 120.0
@export var camera: Camera3D
@export var rts_camera_rig: Node3D

var is_dragging: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(130, 110)

func _process(_delta: float) -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if is_dragging:
				_navigate_to_minimap_pos(event.position)
	elif event is InputEventMouseMotion and is_dragging:
		_navigate_to_minimap_pos(event.position)

func _navigate_to_minimap_pos(mouse_pos: Vector2) -> void:
	if not rts_camera_rig:
		rts_camera_rig = get_tree().root.find_child("RTSCamera", true, false)
	if not rts_camera_rig:
		return
		
	var norm_x := clampf(mouse_pos.x / size.x, 0.0, 1.0)
	var norm_y := clampf(mouse_pos.y / size.y, 0.0, 1.0)
	
	var world_x := (norm_x - 0.5) * map_size
	var world_z := (norm_y - 0.5) * map_size
	
	rts_camera_rig.global_position.x = world_x
	rts_camera_rig.global_position.z = world_z + 10.0 # Compensar inclinação da câmera

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	
	# Fundo do Radar com borda tática
	draw_rect(rect, Color(0.03, 0.06, 0.04, 0.95))
	draw_rect(rect, Color(0.1, 0.7, 0.3, 0.8), false, 1.5)
	
	# Linhas de grade do radar
	var mid_x := size.x / 2.0
	var mid_y := size.y / 2.0
	draw_line(Vector2(mid_x, 0), Vector2(mid_x, size.y), Color(0.1, 0.5, 0.2, 0.3), 1.0)
	draw_line(Vector2(0, mid_y), Vector2(size.x, mid_y), Color(0.1, 0.5, 0.2, 0.3), 1.0)
	
	# Desenhar Prédios
	var buildings := get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		if b is BuildingBase and is_instance_valid(b):
			var m_pos := _world_to_minimap(b.global_position)
			var color := Color(0.2, 0.85, 1.0) if b.team_id == 0 else Color(1.0, 0.2, 0.2)
			draw_rect(Rect2(m_pos - Vector2(3, 3), Vector2(6, 6)), color)
			
	# Desenhar Unidades
	var units := get_tree().get_nodes_in_group("units")
	for u in units:
		if u is UnitBase and is_instance_valid(u):
			# Se for inimigo, só desenha se estiver revelado pelo Fog of War
			if u.team_id != 0 and not u.visible:
				continue
				
			var m_pos := _world_to_minimap(u.global_position)
			var color := Color(0.15, 0.95, 0.2) if u.team_id == 0 else Color(1.0, 0.2, 0.2)
			draw_circle(m_pos, 2.5, color)
			
	# Desenhar Retângulo de Visão da Câmera
	if not rts_camera_rig:
		rts_camera_rig = get_tree().root.find_child("RTSCamera", true, false)
	if rts_camera_rig:
		var cam_pos := _world_to_minimap(rts_camera_rig.global_position - Vector3(0, 0, 10))
		var box_w := (35.0 / map_size) * size.x
		var box_h := (25.0 / map_size) * size.y
		var cam_rect := Rect2(cam_pos - Vector2(box_w / 2.0, box_h / 2.0), Vector2(box_w, box_h))
		draw_rect(cam_rect, Color(1, 1, 1, 0.8), false, 1.0)

func _world_to_minimap(world_pos: Vector3) -> Vector2:
	var norm_x := (world_pos.x / map_size) + 0.5
	var norm_y := (world_pos.z / map_size) + 0.5
	return Vector2(norm_x * size.x, norm_y * size.y)
