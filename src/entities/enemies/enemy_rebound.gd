class_name EnemyFly
extends Enemy

@export_group("Characteristics")
@export var must_explotion: bool = false
@export var rebound_velocity: float = 0.7
@export var impulse_distance: float = 5000.0
@export var impulse_acceleration: float = 220.0

@export_group("Shoot")
@export var num_bullets: int = 5
@export var bullet_speed: float = 200.0
@export var bullet_range: float = 1000.0
@export var fire_velocity: float = 1300.0
@export var bullet_scene: PackedScene

var random_angle := randf_range(0.0, 2.0 * PI)
var random_distance := randi_range(0, 300)
var random_offset := Vector2(cos(random_angle), sin(random_angle)) * random_distance
var last_position_player: Vector2 = Vector2.ZERO
var is_randoming := false
var is_explotion_bullet := false
var _impulse_distance_current: float

func _ready() -> void:
	super._ready()
	_impulse_distance_current = impulse_distance
	current_state = STATE.DASH

func update_behavior(delta: float) -> void:
	match current_state:
		STATE.FOLLOW:
			follow_player(delta)
		STATE.DASH:
			impulse_to_player()
			current_state = STATE.BALL
		STATE.FOLLOW_IA:
			search_for_player(delta)
		STATE.IDLE, STATE.BALL:
			pass

func after_movement(delta: float) -> void:
	if current_state == STATE.BALL:
		rebound_around(delta)
	super.after_movement(delta)

func follow_player(_delta: float) -> void:
	var dist := global_position.distance_to(player.global_position)
	if dist > follow_distance and not is_randoming:
		is_randoming = true
		random_position_to_follow()
		current_state = STATE.FOLLOW_IA
		return
	if _player_alive():
		velocity = (player.global_position - global_position).normalized() * speed
	else:
		current_state = STATE.BALL

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
	if must_explotion:
		explotion()
	if not (collision.get_collider() is CharacterBody2D):
		current_state = STATE.DASH
	velocity = velocity.bounce(collision.get_normal())

func search_for_player(_delta: float) -> void:
	var random_target := player.global_position + random_offset
	velocity = (random_target - global_position).normalized() * speed
	if global_position.distance_to(player.global_position) < follow_distance:
		current_state = STATE.FOLLOW
		is_randoming = false

func random_position_to_follow() -> void:
	random_angle = randf_range(0.0, 2.0 * PI)
	random_distance = randi_range(0, 300)
	random_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	follow_distance = randi_range(190, 220)

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

func _on_detection_target_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		current_state = STATE.DASH
