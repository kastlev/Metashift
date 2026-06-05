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

@onready var player: Player = get_tree().get_first_node_in_group("player")
var direction: Vector2 = Vector2.ZERO

enum STATE {
	IDLE,        # sin hacer nada, esperando
	CHASE,       # siguiendo al jugador directamente
	WANDER,      # moviéndose a posición aleatoria cerca del jugador
	CHARGING,    # preparando/ejecutando el impulso hacia el jugador
	BOUNCING,    # en el aire rebotando tras el impulso
}
@export var current_state: STATE = STATE.IDLE

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	_flip_sprite()
	update_behavior(delta)
	if not _use_manual_movement():
		move_and_slide()

func _use_manual_movement() -> bool:
	return false

func _flip_sprite() -> void:
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true


@abstract
func update_behavior(_delta: float) -> void

@abstract
func on_died() -> void

@abstract
func on_damaged() -> void

func _on_health_damaged(_dir: Vector2) -> void:
	flash.flash()
	on_damaged()

func _on_health_died() -> void:
	animated_sprite.play("death")
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	on_died()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()
