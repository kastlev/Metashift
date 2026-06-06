class_name HealthComponent
extends Node

signal health_changed(current: float, max_health: float)
signal damaged(direction: Vector2)
signal died

@export var data: HealthData

var current_health := 0.0
var iframe_timer := 0.0

func _ready() -> void:
	assert(data != null, name + "/HealthComponent: HealthData requerido")
	current_health = data.max_health

func initialize(override_max: float) -> void:
	# Permite que EnemyData o PlayerData sobreescriban el max sin tocar el Resource.
	# Si no se llama, usa data.max_health del inspector.
	current_health = override_max

func _physics_process(delta: float) -> void:
	if iframe_timer > 0:
		iframe_timer -= delta

func take_damage(damage: float, direction: Vector2 = Vector2.ZERO) -> void:
	if data.has_iframes and iframe_timer > 0:
		return
	if data.has_iframes:
		iframe_timer = data.iframe_duration
	current_health = clamp(current_health - damage, 0.0, data.max_health)
	health_changed.emit(current_health, data.max_health)
	damaged.emit(direction)
	if current_health == 0.0:
		died.emit()

func grant_iframes(duration: float) -> void:
	iframe_timer = maxf(iframe_timer, duration)

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, data.max_health)
	health_changed.emit(current_health, data.max_health)

func is_dead() -> bool:
	return current_health <= 0.0

func emit_health_changed():
	health_changed.emit(current_health, data.max_health)
