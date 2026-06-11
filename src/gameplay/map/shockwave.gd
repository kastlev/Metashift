extends ColorRect

@onready var camera_2d := get_viewport().get_camera_2d()

func _ready() -> void:
	material.set_shader_parameter("alpha", 0.0)
	material.set_shader_parameter("intensity", 0.0)
	material.set_shader_parameter("size", 0.0)

func play(world_position: Vector2) -> void:
	_set_center(world_position)
	material.set_shader_parameter("size", 0.0)
	material.set_shader_parameter("intensity", 0.07)
	material.set_shader_parameter("chromatic_offset", 0.12)
	material.set_shader_parameter("alpha", 0.7)
	material.set_shader_parameter("ring_color", Color(0.97, 0.97, 0.97, 0.024))

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(
		func(v: float): material.set_shader_parameter("size", v),
		0.0, 0.35, 0.4
	)
	tween.tween_method(
		func(v: float): material.set_shader_parameter("intensity", v),
		0.07, 0.0, 0.3
	)
	tween.tween_method(
		func(v: float): material.set_shader_parameter("chromatic_offset", v),
		0.12, 0.0, 0.3
	)
	tween.tween_method(
		func(v: float): material.set_shader_parameter("alpha", v),
		0.7, 0.0, 0.35
	)

func _set_center(world_pos: Vector2) -> void:
	var viewport_size := get_viewport_rect().size
	var camera_center := camera_2d.get_screen_center_position()
	var screen_pos := (world_pos - camera_center) * camera_2d.zoom + viewport_size / 2.0
	material.set_shader_parameter("center", screen_pos / viewport_size)
