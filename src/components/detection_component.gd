class_name DetectionComponent
extends Area2D

signal target_entered(body: Node2D)
signal target_exited(body: Node2D)

## Solo emite señal para bodies de este grupo. Vacío = todos.
@export var filter_group: String = "player"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if filter_group.is_empty() or body.is_in_group(filter_group):
		target_entered.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if filter_group.is_empty() or body.is_in_group(filter_group):
		target_exited.emit(body)
