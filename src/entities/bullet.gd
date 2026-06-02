class_name Bullet
extends Area2D

## Grupo objetivo que puede recibir daño
@export var target_group: String = &"player"
## Velocidad y dirección combinadas
@export var velocity_vec: Vector2 = Vector2.ZERO
@export var max_distance: float = 2000.0
@export var damage: int = 1

@onready var visible_on_screen = $VisibleOnScreen

var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	visible_on_screen.screen_exited.connect(queue_free)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += velocity_vec * delta
	if global_position.distance_to(start_position) >= max_distance:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent and area.owner.is_in_group(target_group):
		area.take_damage(damage)
		queue_free()
