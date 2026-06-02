class_name EnemyBee
extends Enemy

@export_group("Characteristics")
@export var must_explotion: bool = false
@export var rebound_velocity: float = 1.0
@export var impulse_distance: float = 5000.0
@export var impulse_acceleration: float = 120.0

@export_group("Shoot")
@export var num_bullets: int = 8
@export var bullet_speed: float = 300.0
@export var bullet_range: float = 1000.0
@export var bullet_scene: PackedScene

var _impulse_distance_current: float
var last_position_player: Vector2 = Vector2.ZERO
var is_explotion_bullet := false

func _ready() -> void:
	super._ready()
	_impulse_distance_current = impulse_distance
	current_state = STATE.DASH

func update_behavior(_delta: float) -> void:
	match current_state:
		STATE.DASH:
			impulse_to_player()
			current_state = STATE.BALL
		STATE.IDLE, STATE.BALL, STATE.FOLLOW, STATE.FOLLOW_IA:
			pass

func after_movement(delta: float) -> void:
	if current_state == STATE.BALL:
		rebound_around(delta)
	super.after_movement(delta)

func impulse_to_player() -> void:
	if not is_instance_valid(player):
		return
	last_position_player = player.global_position
	scale = Vector2(0.8, 0.8)
	velocity = (last_position_player - global_position).normalized() * impulse_acceleration
	_impulse_distance_current -= impulse_acceleration
	if _impulse_distance_current <= 0.0:
		_impulse_distance_current = impulse_distance
		scale = Vector2.ONE
		velocity = Vector2.ZERO
		current_state = STATE.IDLE

func rebound_around(delta: float) -> void:
	var collision := move_and_collide(velocity * rebound_velocity * delta)
	if not collision:
		return
	if scale <= Vector2(1.8, 1.8):
		scale += Vector2(0.1, 0.1)
	if not (collision.get_collider() is CharacterBody2D):
		current_state = STATE.DASH
	velocity = velocity.bounce(collision.get_normal())

func explotion() -> void:
	if is_explotion_bullet or bullet_scene == null:
		return
	is_explotion_bullet = true
	for i in range(num_bullets):
		var angle := (2.0 * PI / num_bullets) * i
		var bullet := bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.velocity_vec = Vector2(cos(angle), sin(angle)).normalized() * bullet_speed
		bullet.max_distance = bullet_range
		add_sibling(bullet)

func on_died() -> void:
	if must_explotion:
		explotion()
