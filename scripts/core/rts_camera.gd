extends Node3D
class_name RTSCamera

@export var move_speed: float = 25.0
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 50.0
@export var rotate_speed: float = 2.0
@export var edge_margin: float = 15.0
@export var enable_edge_pan: bool = false

@onready var camera: Camera3D = $Elevation/Camera3D
@onready var elevation: Node3D = $Elevation

var target_zoom: float = 20.0
var zoom_step: float = 3.0

func _ready() -> void:
	if camera:
		target_zoom = camera.position.z

func _process(delta: float) -> void:
	_handle_movement(delta)
	_handle_zoom(delta)
	_handle_rotation(delta)

func _handle_movement(delta: float) -> void:
	var move_dir := Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir += transform.basis.x
		
	if enable_edge_pan:
		var mouse_pos := get_viewport().get_mouse_position()
		var viewport_size := get_viewport().get_visible_rect().size
		if mouse_pos.x <= edge_margin:
			move_dir -= transform.basis.x
		elif mouse_pos.x >= viewport_size.x - edge_margin:
			move_dir += transform.basis.x
		if mouse_pos.y <= edge_margin:
			move_dir -= transform.basis.z
		elif mouse_pos.y >= viewport_size.y - edge_margin:
			move_dir += transform.basis.z

	move_dir.y = 0.0
	move_dir = move_dir.normalized()
	global_position += move_dir * move_speed * delta

func _handle_zoom(delta: float) -> void:
	if camera:
		camera.position.z = lerp(camera.position.z, target_zoom, 10.0 * delta)

func _handle_rotation(delta: float) -> void:
	var rot := 0.0
	if Input.is_key_pressed(KEY_Q):
		rot += rotate_speed * delta
	if Input.is_key_pressed(KEY_E):
		rot -= rotate_speed * delta
	rotate_y(rot)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_step, min_zoom, max_zoom)
