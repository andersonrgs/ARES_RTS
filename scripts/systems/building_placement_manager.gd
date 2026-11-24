extends Node3D
class_name BuildingPlacementManager

signal placement_started
signal placement_finished

const GhostScene = preload("res://scenes/buildings/placement_ghost.tscn")
const GameEconomy = preload("res://scripts/systems/game_economy.gd")
const SelectionManager = preload("res://scripts/core/selection_manager.gd")
const SoundManager = preload("res://scripts/systems/sound_manager.gd")

@export var camera: Camera3D
@export var economy: GameEconomy
@export var selection_manager: SelectionManager

var active_ghost: Node3D = null
var current_building_scene: PackedScene = null
var current_cost: int = 0
var is_valid_location: bool = true

func _ready() -> void:
	if not economy:
		economy = get_tree().root.find_child("GameEconomy", true, false)
	if not selection_manager:
		selection_manager = get_tree().root.find_child("SelectionManager", true, false)

func start_placement(building_scene: PackedScene, cost: int, size: Vector3 = Vector3(5, 3, 5)) -> void:
	cancel_placement()
	
	current_building_scene = building_scene
	current_cost = cost
	
	active_ghost = GhostScene.instantiate()
	add_child(active_ghost)
	
	var mesh_inst: MeshInstance3D = active_ghost.get_node_or_null("MeshInstance3D")
	var col_shape: CollisionShape3D = active_ghost.get_node_or_null("Area3D/CollisionShape3D")
	if mesh_inst and mesh_inst.mesh is BoxMesh:
		mesh_inst.mesh.size = size
		mesh_inst.position.y = size.y / 2.0
	if col_shape and col_shape.shape is BoxShape3D:
		col_shape.shape.size = size
		col_shape.position.y = size.y / 2.0
		
	if selection_manager:
		selection_manager.set_process_unhandled_input(false)
		
	emit_signal("placement_started")

func cancel_placement() -> void:
	if active_ghost:
		active_ghost.queue_free()
		active_ghost = null
	current_building_scene = null
	
	if selection_manager:
		selection_manager.set_process_unhandled_input(true)
		
	emit_signal("placement_finished")

func _process(_delta: float) -> void:
	if not active_ghost:
		return
		
	if not camera:
		camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	
	if result:
		# Posiciona o ghost onde o mouse apontar
		active_ghost.global_position = Vector3(round(result.position.x), 0, round(result.position.z))
		
		# Validação de sobreposição com obstáculos/outros prédios
		var area: Area3D = active_ghost.get_node_or_null("Area3D")
		is_valid_location = true
		
		if economy and not economy.has_credits(current_cost):
			is_valid_location = false
		elif area:
			var overlapping := area.get_overlapping_bodies()
			for body in overlapping:
				# Se colidir com algo que não seja o chão puro (ex: rochas, prédios, tanques)
				if body.name != "Ground":
					is_valid_location = false
					break
					
		_update_ghost_visual(is_valid_location)

func _update_ghost_visual(valid: bool) -> void:
	if not active_ghost:
		return
	var mesh_inst: MeshInstance3D = active_ghost.get_node_or_null("MeshInstance3D")
	if mesh_inst and mesh_inst.mesh and mesh_inst.mesh.material is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh_inst.mesh.material
		if valid:
			mat.albedo_color = Color(0.2, 0.9, 0.3, 0.5) # Verde válido
		else:
			mat.albedo_color = Color(0.9, 0.2, 0.2, 0.5) # Vermelho inválido

func _unhandled_input(event: InputEvent) -> void:
	if not active_ghost:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_valid_location and current_building_scene:
				_confirm_placement()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()
			
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_placement()

func _confirm_placement() -> void:
	if economy and not economy.spend_credits(current_cost):
		return
		
	var new_building = current_building_scene.instantiate()
	get_parent().add_child(new_building)
	new_building.global_position = active_ghost.global_position
	
	if SoundManager.instance:
		SoundManager.instance.play_construction_complete()
	
	cancel_placement()
