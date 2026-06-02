class_name EnemyButterfly
extends Enemy

@export_group("Shoot")
## Cantidad de balas en la explosión
@export var num_bullets: int = 8
@export var bullet_speed: float = 300.0
@export var bullet_range: float = 1000.0
## Velocidad de la bala dirigida al jugador	
@export var fire_velocity: float = 300.0
@export var bullet_scene: PackedScene

@export_group("Characteristics")
@export var must_explotion: bool = true

@onready var timer_shoot: Timer = %TimerShoot

var random_angle := randf_range(0.0, 2.0 * PI)
var random_distance := randi_range(0, 300)
var random_offset := Vector2(cos(random_angle), sin(random_angle)) * random_distance
var is_randoming := false
var is_explotion_bullet := false

func _ready() -> void:
	super._ready()
	current_state = STATE.FOLLOW_IA
	timer_shoot.timeout.connect(_on_timer_timeout)
	timer_shoot.wait_time = randf_range(1.0, 3.0)
	timer_shoot.start()

func update_behavior(delta: float) -> void:
	match current_state:
		STATE.FOLLOW:
			follow_player(delta)
		STATE.FOLLOW_IA:
			search_for_player(delta)

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
		current_state = STATE.FOLLOW_IA

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

func fire_to_player() -> void:
	if not is_instance_valid(player) or bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.velocity_vec = (player.global_position - global_position).normalized() * fire_velocity
	get_tree().current_scene.add_child(bullet)

func explotion() -> void:
	if is_explotion_bullet:
		return
	is_explotion_bullet = true
	for i in range(num_bullets):
		var angle := (2.0 * PI / num_bullets) * i
		spawn_bullet(global_position,
			Vector2(cos(angle), sin(angle)).normalized(),
			bullet_speed, bullet_range)

func spawn_bullet(pos: Vector2, dir: Vector2, spd: float, max_dist: float) -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = pos
	bullet.velocity_vec = dir * spd
	bullet.max_distance = max_dist
	add_sibling(bullet)

func on_died() -> void:
	if must_explotion:
		explotion()

func _on_detection_target_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		current_state = STATE.FOLLOW_IA

func _on_timer_timeout() -> void:
	fire_to_player()
	timer_shoot.wait_time = randf_range(1.0, 3.0)
	timer_shoot.start()
