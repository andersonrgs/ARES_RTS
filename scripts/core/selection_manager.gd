extends Control
class_name SelectionManager

const UnitBase = preload("res://scripts/units/unit_base.gd")

@export var camera: Camera3D
@export var ray_length: float = 1000.0
@export var player_team_id: int = 0

var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_end: Vector2 = Vector2.ZERO
var selected_units: Array = []

# Cores da caixa de seleção estilo C&C
@export var box_border_color: Color = Color(0.1, 0.9, 0.2, 0.9)
@export var box_fill_color: Color = Color(0.1, 0.9, 0.2, 0.15)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func _unhandled_input(event: InputEvent) -> void:
	if not camera:
		camera = get_viewport().get_camera_3d()
	if not camera:
		return

	if event is InputEventMouseButton:
		# Botão Esquerdo: Seleção
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start = event.position
				drag_end = event.position
			else:
				if is_dragging:
					is_dragging = false
					drag_end = event.position
					queue_redraw()
					_resolve_selection(Input.is_key_pressed(KEY_SHIFT))
					
		# Botão Direito: Comando de Movimento ou Ataque
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_issue_command_at_mouse(event.position)

	elif event is InputEventMouseMotion and is_dragging:
		drag_end = event.position
		queue_redraw()

func _draw() -> void:
	if is_dragging:
		var rect := _get_drag_rect()
		if rect.size.length() > 5.0:
			draw_rect(rect, box_fill_color, true)
			draw_rect(rect, box_border_color, false, 2.0)

func _get_drag_rect() -> Rect2:
	var top_left := Vector2(min(drag_start.x, drag_end.x), min(drag_start.y, drag_end.y))
	var size := (drag_start - drag_end).abs()
	return Rect2(top_left, size)

func _resolve_selection(keep_previous: bool) -> void:
	var rect := _get_drag_rect()
	
	if not keep_previous:
		_deselect_all()

	# Clique simples (sem arrastar)
	if rect.size.length() < 8.0:
		var unit = _raycast_unit(drag_end)
		if unit and unit.team_id == player_team_id:
			_select_unit(unit)
		return

	# Seleção em área (Box Select) - Apenas unidades aliadas do jogador
	var all_units := get_tree().get_nodes_in_group("units")
	for node in all_units:
		if node is UnitBase and node.team_id == player_team_id:
			var screen_pos := camera.unproject_position(node.global_position)
			if not camera.is_position_behind(node.global_position) and rect.has_point(screen_pos):
				_select_unit(node)

func _select_unit(unit) -> void:
	if not selected_units.has(unit):
		selected_units.append(unit)
		if unit.has_method("set_selected"):
			unit.set_selected(true)

func _deselect_all() -> void:
	for unit in selected_units:
		if is_instance_valid(unit) and unit.has_method("set_selected"):
			unit.set_selected(false)
	selected_units.clear()

func _raycast_unit(screen_pos: Vector2):
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * ray_length
	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	
	if result and result.collider is UnitBase:
		return result.collider
	return null

func _issue_command_at_mouse(screen_pos: Vector2) -> void:
	if selected_units.is_empty():
		return

	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * ray_length
	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	
	if not result:
		return

	# Caso 1: Clicou em um inimigo -> Comando de Ataque focado!
	if result.collider is UnitBase and result.collider.team_id != player_team_id:
		var enemy_target: UnitBase = result.collider
		for unit in selected_units:
			if is_instance_valid(unit) and unit.has_method("attack_target"):
				unit.attack_target(enemy_target)
		return

	# Caso 2: Clicou no chão/terreno -> Comando de Movimento em Formação
	var target_pos: Vector3 = result.position
	var count := selected_units.size()
	var spacing := 3.0
	var cols := int(ceil(sqrt(count)))
	
	for i in range(count):
		var unit = selected_units[i]
		if is_instance_valid(unit) and unit.has_method("move_to_target"):
			var row := i / cols
			var col := i % cols
			var offset := Vector3((col - cols / 2.0) * spacing, 0, (row - cols / 2.0) * spacing)
			unit.move_to_target(target_pos + offset)
