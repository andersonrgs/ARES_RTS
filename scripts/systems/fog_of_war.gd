extends Node3D
class_name FogOfWar

const UnitBase = preload("res://scripts/units/unit_base.gd")
const BuildingBase = preload("res://scripts/buildings/building_base.gd")

@export var map_size: float = 120.0
@export var grid_resolution: int = 128
@export var update_interval: float = 0.08
@export var fog_mesh: MeshInstance3D

var explored_data: PackedByteArray
var visible_data: PackedByteArray
var image: Image
var texture: ImageTexture
var time_since_update: float = 0.0

func _ready() -> void:
	var total_pixels := grid_resolution * grid_resolution
	explored_data = PackedByteArray()
	explored_data.resize(total_pixels)
	explored_data.fill(0)
	
	visible_data = PackedByteArray()
	visible_data.resize(total_pixels)
	visible_data.fill(0)
	
	image = Image.create(grid_resolution, grid_resolution, false, Image.FORMAT_RGBA8)
	_fill_initial_image()
	texture = ImageTexture.create_from_image(image)
	
	if fog_mesh and fog_mesh.material_override is ShaderMaterial:
		fog_mesh.material_override.set_shader_parameter("fog_texture", texture)

func _fill_initial_image() -> void:
	for y in range(grid_resolution):
		for x in range(grid_resolution):
			image.set_pixel(x, y, Color(0, 0, 0, 1))

func _process(delta: float) -> void:
	time_since_update += delta
	if time_since_update >= update_interval:
		time_since_update = 0.0
		_update_fog()

func _update_fog() -> void:
	visible_data.fill(0)
	
	# 1. Revelar visão ao redor de todas as unidades aliadas (Jogador)
	var units := get_tree().get_nodes_in_group("units")
	for node in units:
		if node is UnitBase and node.team_id == 0 and node.current_health > 0:
			_stamp_vision(node.global_position, 18.0)
			
	# 2. Revelar visão ao redor de prédios aliados
	var buildings := get_tree().get_nodes_in_group("buildings")
	for node in buildings:
		if node is BuildingBase and node.team_id == 0 and node.current_health > 0:
			_stamp_vision(node.global_position, 24.0)

	# 3. Atualizar a textura da névoa
	for y in range(grid_resolution):
		for x in range(grid_resolution):
			var idx := y * grid_resolution + x
			var exp_val := float(explored_data[idx]) / 255.0
			var vis_val := float(visible_data[idx]) / 255.0
			image.set_pixel(x, y, Color(exp_val, vis_val, 0.0, 1.0))
			
	texture.update(image)
	
	# 4. Esconder/Mostrar unidades inimigas com base na visibilidade ativa
	for node in units:
		if node is UnitBase and node.team_id != 0:
			var grid_pos := _world_to_grid(node.global_position)
			var is_revealed := false
			if grid_pos.x >= 0 and grid_pos.x < grid_resolution and grid_pos.y >= 0 and grid_pos.y < grid_resolution:
				var idx := grid_pos.y * grid_resolution + grid_pos.x
				is_revealed = (visible_data[idx] > 0)
			node.visible = is_revealed

func _stamp_vision(world_pos: Vector3, radius: float) -> void:
	var center := _world_to_grid(world_pos)
	var grid_radius := int(ceil((radius / map_size) * grid_resolution))
	
	var min_x := clampi(center.x - grid_radius, 0, grid_resolution - 1)
	var max_x := clampi(center.x + grid_radius, 0, grid_resolution - 1)
	var min_y := clampi(center.y - grid_radius, 0, grid_resolution - 1)
	var max_y := clampi(center.y + grid_radius, 0, grid_resolution - 1)
	
	var r_sq := grid_radius * grid_radius
	
	for y in range(min_y, max_y + 1):
		var dy := y - center.y
		for x in range(min_x, max_x + 1):
			var dx := x - center.x
			if (dx * dx + dy * dy) <= r_sq:
				var idx := y * grid_resolution + x
				explored_data[idx] = 255
				visible_data[idx] = 255

func _world_to_grid(world_pos: Vector3) -> Vector2i:
	var half_size := map_size / 2.0
	var norm_x := clampf((world_pos.x + half_size) / map_size, 0.0, 0.999)
	var norm_y := clampf((world_pos.z + half_size) / map_size, 0.0, 0.999)
	return Vector2i(int(norm_x * grid_resolution), int(norm_y * grid_resolution))
