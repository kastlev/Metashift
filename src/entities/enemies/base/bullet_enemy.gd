extends Area2D

@export var velocity: Vector2 = Vector2.ZERO
@export var max_distance: float = 2000.0

var start_position: Vector2 = Vector2.ZERO
var damage_bullet = 1

func _ready() -> void :
	start_position = global_position

func _physics_process(delta: float) -> void :
	global_position += velocity * delta

	if global_position.distance_to(start_position) >= max_distance:
		queue_free()

func _on_visible_on_screen_screen_exited() -> void :
	queue_free()

func _on_body_entered(body: Node2D) -> void :
	if body.is_in_group("player") and not body.is_damaged_this_frame:
		body.is_damaged_this_frame = true
		GLOBAL.player_is_immune = true
		GLOBAL.lifes_player -= damage_bullet
		queue_free()
