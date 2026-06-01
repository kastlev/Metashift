extends Area2D

@export var velocity: Vector2 = Vector2.ZERO
@export var max_distance: float = 2000.0

var start_position: Vector2 = Vector2.ZERO

func _ready() -> void :
	start_position = global_position

func _physics_process(delta: float) -> void :
	global_position += velocity * delta

	if global_position.distance_to(start_position) >= max_distance:
		queue_free()

func _on_visible_on_screen_screen_exited() -> void :
	queue_free()

func _on_area_entered(area: Area2D) -> void :
	if area.is_in_group("enemy"):
		queue_free()
