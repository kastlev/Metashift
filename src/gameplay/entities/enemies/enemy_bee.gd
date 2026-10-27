class_name EnemyBee
extends EnemyShooter


@export_group("Movement")
## Intervalo en segundos para actualizar la dirección hacia el jugador
@export var direction_update_interval: float = 1.5
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
	pass
	#EnemyUtils.explotion(global_position, num_bullets, bullet_speed, bullet_range, bullet_scene, self)

func _on_detection_target_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		direction = (player.global_position - global_position).normalized()
		_direction_timer = direction_update_interval

func on_damaged() -> void:
	pass
