# EnemyBeeNew.gd
class_name EnemyBeeNew
extends Enemy


@export_group("Movement")
## Intervalo en segundos para actualizar la dirección hacia el jugador
@export var direction_update_interval: float = 1.5  # original: 1.5

@export_group("Shoot")
@export var num_bullets: int = 6
@export var bullet_speed: float = 250.0
@export var bullet_range: float = 1000.0
@export var bullet_scene: PackedScene

@onready var detection: DetectionComponent = %DetectionComponent

var _direction_timer: float = 0.0

func _ready() -> void:
	super._ready()
	detection.target_entered.connect(_on_detection_target_entered)

func update_behavior(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_direction_timer -= delta
	if _direction_timer <= 0.0:
		_direction_timer = direction_update_interval
		direction = (player.global_position - global_position).normalized()

	velocity = direction * speed

func on_died() -> void:
	EnemyUtils.explotion(global_position, num_bullets, bullet_speed, bullet_range, bullet_scene, self)

func _on_detection_target_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		direction = (player.global_position - global_position).normalized()
		_direction_timer = direction_update_interval

func on_damaged() -> void:
	pass
