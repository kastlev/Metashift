extends TextureRect
class_name Heart

@export var full_texture: Texture2D
@export var empty_texture: Texture2D

var is_full := true

func set_full(value: bool) -> void:
	is_full = value
	texture = full_texture if value else empty_texture
