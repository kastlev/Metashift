# EnemyShooter.gd
@abstract
class_name EnemyShooter
extends Enemy

@export_group("Shoot")
## Balas en la explosión
@export var num_bullets: int = 8
@export var bullet_speed: float = 300.0
@export var bullet_range: float = 1000.0
@export var bullet_scene: PackedScene

func fire_to_player() -> void:
	if not is_instance_valid(player):
		return
	EnemyUtils.fire_to_player(global_position, player, bullet_scene, bullet_speed, get_tree().current_scene)


func explotion() -> void:
	EnemyUtils.explotion(global_position, num_bullets, bullet_speed, bullet_range, bullet_scene, self)
