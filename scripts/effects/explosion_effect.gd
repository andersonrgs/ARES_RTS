extends Node3D

const SoundManager = preload("res://scripts/systems/sound_manager.gd")

@export var duration: float = 0.6
var elapsed: float = 0.0

@onready var light: OmniLight3D = $OmniLight3D
@onready var mesh_core: MeshInstance3D = $CoreMesh

func _ready() -> void:
	if SoundManager.instance:
		SoundManager.instance.play_explosion()

func _process(delta: float) -> void:
	elapsed += delta
	var progress := elapsed / duration
	
	if progress >= 1.0:
		queue_free()
		return
		
	if mesh_core:
		var scale_factor := sin(progress * PI) * 1.8
		mesh_core.scale = Vector3.ONE * max(0.1, scale_factor)
		
	if light:
		light.light_energy = (1.0 - progress) * 8.0
