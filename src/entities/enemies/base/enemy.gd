@abstract
class_name Enemy
extends CharacterBody2D


@export_group("Movement")
## Velocidad base de movimiento
@export var speed: float = 150.0
## Daño al tocar al jugador
@export var touch_damage: int = 1

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var health: HealthComponent = %HealthComponent
@onready var flash: FlashComponent = %FlashComponent
@onready var hurtbox: HurtboxComponent = %HurtboxComponent

var player: Player
var direction: Vector2 = Vector2.ZERO

enum STATE { IDLE, FOLLOW, DASH, BALL, FOLLOW_IA }
@export var current_state: STATE = STATE.IDLE


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	animated_sprite.animation_finished.connect(_on_animation_finished)
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player
	_flip_sprite()
	update_behavior(delta)
	move_and_slide()
	_apply_touch_damage()


func _flip_sprite() -> void:
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true


@abstract
func update_behavior(_delta: float) -> void


func _apply_touch_damage() -> void:
	if touch_damage <= 0:
		return
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var body := col.get_collider() as Node2D
		if body and body.is_in_group("player"):
			var hurtbox_player := body.get_node_or_null("%HurtboxComponent") as HurtboxComponent
			if hurtbox_player:
				hurtbox_player.take_damage(
					touch_damage,
					(body.global_position - global_position).normalized()
				)
			break


func _player_alive() -> bool:
	return is_instance_valid(player) and not player.health.is_dead()


func _on_health_damaged(_dir: Vector2) -> void:
	flash.flash()


func _on_health_died() -> void:
	animated_sprite.play("death")
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	on_died()


func on_died() -> void:
	pass


func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()
