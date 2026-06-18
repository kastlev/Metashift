class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent

func _ready() -> void:
	if health_component == null:
		health_component = get_parent().get_node_or_null("%HealthComponent")
	assert(health_component != null, name + ": requiere HealthComponent")

func take_damage(amount: float, direction: Vector2 = Vector2.ZERO) -> void:
	health_component.take_damage(amount, direction)
