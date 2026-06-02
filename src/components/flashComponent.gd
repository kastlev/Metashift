class_name FlashComponent
extends Node

@export var sprite: CanvasItem
@export var flash_color: Color = Color(31820.271, 0.0, 0.0) 
@export var duration: float = 0.1

var _original_modulate: Color

func _ready() -> void:
	assert(sprite != null, "FlashComponent requiere un sprite")
	_original_modulate = sprite.modulate

func flash() -> void:
	sprite.modulate = flash_color

	await get_tree().create_timer(duration).timeout

	if is_instance_valid(sprite):
		sprite.modulate = _original_modulate
