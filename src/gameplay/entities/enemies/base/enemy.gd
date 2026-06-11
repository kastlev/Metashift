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
@onready var hurtbox: HurtboxComponent = %HurtboxComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var player: Player = get_tree().get_first_node_in_group("player")
var direction: Vector2 = Vector2.ZERO

var is_dead: bool = false
var death_velocity: Vector2
var death_rotation_speed: float

var timer_flash: Timer
var flash_duration: float = 0.2

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
	animated_sprite.material = animated_sprite.material.duplicate()
	timer_flash = Utils.create_timer(self, flash_duration, _on_timer_flash_timeout)
	_init_flash_shader_property()

func _physics_process(delta: float) -> void:
	if is_dead:
		death_velocity.y += 1300 * delta
		
		global_position += death_velocity * delta
		rotation += death_rotation_speed * delta
		animated_sprite.modulate = Color(1, 1, 1, 0.4)
		return
	
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
	flash()
	on_damaged()

func _on_health_died() -> void:
	call_deferred("_die")
	
func _die() -> void:
	is_dead = true

	death_velocity = velocity
	death_velocity.y = -150

	death_rotation_speed = sign(velocity.x) * randf_range(4.0, 8.0)

	collision_shape.disabled = true

	hurtbox.monitoring = false
	hurtbox.monitorable = false

	set_collision_layer(0)
	set_collision_mask(0)

	on_died()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		queue_free()


func _init_flash_shader_property():
	animated_sprite.material.set_shader_parameter("get_hit", false)
	animated_sprite.material.set_shader_parameter("shake_intensity", 7.143)
	animated_sprite.material.set_shader_parameter("shake_strength", 0.397)
	animated_sprite.material.set_shader_parameter("shake_speed", 30.0)
	animated_sprite.material.set_shader_parameter("flash_color", Color(1.353, 0.142, 0.347))
	animated_sprite.material.set_shader_parameter("flash_strength", 0.818)
	animated_sprite.material.set_shader_parameter("flash_speed", 0.0)
	animated_sprite.material.set_shader_parameter("flash_solid", false)
	
func flash() -> void:
	animated_sprite.material.set_shader_parameter("get_hit", true)
	timer_flash.start()

func _on_timer_flash_timeout() -> void:
	animated_sprite.material.set_shader_parameter("get_hit", false)
