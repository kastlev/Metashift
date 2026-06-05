# HitboxComponent.gd - Area2D en el enemigo que aplica daño al player
class_name HitboxComponent
extends Area2D

@export var target_group: String = &"player"
@export var damage: int = 1

func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent and area.owner.is_in_group(target_group):
		area.take_damage(damage, (area.owner.global_position - owner.global_position).normalized())
