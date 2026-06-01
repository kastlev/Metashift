extends CharacterBody2D

@export_group("Shoot")
@export var num_bullets = 5
@export var fire_rate: float = 2.0
@export var bullet_speed = 200.0
@export var bullet_range = 1000.0
@export var fire_velocity = 1300
@export var bullet_scene: PackedScene

@export_group("Movement")
@export var follow_distance: float = 200.0
@export var speed: float = 70.0

@export_group("Characteristics")
@export var lifes_enemy: int = 2
@export var current_state: STATE = STATE.DASH
@export var must_explotion = false
@export var rebound_velocity = 0.7
@export var impulse_distance: float = 5000.0
@export var impulse_acceleration: float = 220.0

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var timer_damaged_effect: Timer = %TimerDamagedEffect
@onready var timer_shoot: Timer = %TimerShoot
@onready var can_explote = %CanExplote
@onready var player: Player = get_tree().get_first_node_in_group("player")

var random_angle = randf_range(0, 2 * PI)
var random_distance = randi_range(0, 300)
var random_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance

var last_position_player
var last_shot_time: float = 0.0
var can_impulse: bool = true
var applying_impulse: bool = false
var is_randoming = false
var is_explotion_bullet = false

var direction: Vector2 = Vector2.ZERO

enum STATE{
	IDLE, 
	FOLLOW, 
	DASH, 
	BALL, 
	FOLLOW_IA
}

func _process(delta: float) -> void :
	if lifes_enemy <= 0:
		enemy_death()
		return

	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

	match current_state:
		STATE.IDLE:
			idle_behavior(delta)
		STATE.FOLLOW:
			follow_player(delta)
		STATE.DASH:
			impulse_to_player()
			current_state = STATE.BALL
		STATE.BALL:
			rebound_around(delta)
		STATE.FOLLOW_IA:
			search_for_player(delta)
	move_and_slide()

func follow_player(_delta: float) -> void :
	var distance_to_player = position.distance_to(player.position)

	if distance_to_player > follow_distance and is_randoming == false:
		is_randoming = true
		random_position_to_follow()
		current_state = STATE.BALL

	if player and GLOBAL.lifes_player > 0:
		direction = (player.position - position).normalized()
		velocity = direction * speed
	else:
		current_state = STATE.BALL

func damaged() -> void :
	if !lifes_enemy <= 0:
		modulate = Color(31820.271, 0.0, 0.0)
		timer_damaged_effect.start()

func impulse_to_player() -> void :
	last_position_player = player.position
	scale = Vector2(0.8, 0.8)
	direction = (last_position_player - position).normalized()
	velocity = direction * impulse_acceleration
	impulse_distance -= impulse_acceleration

	if impulse_distance <= 0:
		last_position_player = null
		impulse_distance = 5000.0
		scale = Vector2(1, 1)
		velocity = Vector2.ZERO
		current_state = STATE.IDLE

func idle_behavior(delta: float) -> void :
	pass

func rebound_around(delta: float) -> void :
	var collision = move_and_collide(velocity * rebound_velocity * delta)
	if collision:
		if !collision.get_collider() is CharacterBody2D:
			current_state = STATE.DASH

		if scale <= Vector2(1.8, 1.8):
			scale += Vector2(0.1, 0.1)
		if must_explotion:
			explotion()

		var normal = collision.get_normal()
		velocity = velocity.bounce(normal)

func explotion():
	if !is_explotion_bullet:
		is_explotion_bullet = true

		for i in range(num_bullets):
			var angle = (2 * PI / num_bullets) * i
			var dir = Vector2(cos(angle), sin(angle)).normalized()

			spawn_bullet(global_position, dir, bullet_speed, bullet_range)
		if can_explote.is_stopped():
			can_explote.start()

func spawn_bullet(start_position: Vector2, dir: Vector2, speed_bullet: float, max_distance: float):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = start_position
	bullet.velocity = dir * speed_bullet
	bullet.max_distance = max_distance
	add_sibling(bullet)

func enemy_death():
	animated_sprite.play("death")
	collision_shape.set_deferred("disabled", true)
	#$detection.queue_free()
	timer_damaged_effect.stop()
	
	if must_explotion:
		explotion()

func fire_to_player():
	if player:
		var bullet = bullet_scene.instantiate()
		bullet.position = position
		last_position_player = (player.position - position).normalized()
		bullet.velocity = last_position_player * fire_velocity
		get_tree().current_scene.add_child(bullet)

func search_for_player(_delta: float) -> void :
	var random_target = player.position + random_offset
	direction = (random_target - position).normalized()
	velocity = direction * speed
	var distance_to_player = position.distance_to(player.position)

	if distance_to_player < follow_distance:
		current_state = STATE.FOLLOW
		is_randoming = false

func random_position_to_follow():
	random_angle = randf_range(0, 2 * PI)
	random_distance = randf_range(0, 300)
	random_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	follow_distance = randi_range(190, 220)
	
func _on_area_2d_area_entered(area: Area2D) -> void :
	if area.is_in_group("shoot"):
		lifes_enemy -= 1
		damaged()

func _on_area_2d_body_entered(body: Node2D) -> void :
	if body.is_in_group("player") and not GLOBAL.player_is_immune:
		lifes_enemy -= 1
		GLOBAL.lifes_player -= 1
		GLOBAL.player_is_immune = true
		damaged()

func _on_timer_damaged_efect_timeout() -> void :
	modulate = Color(1.0, 1.0, 1.0)


func _on_animated_sprite_2d_animation_finished() -> void :
	if animated_sprite.animation == "death":
		queue_free()

func _on_timer_timeout() -> void :
	fire_to_player()
	timer_shoot.wait_time = randf_range(1, 3)
	
func _on_timer_random_follow_timeout() -> void :
	random_position_to_follow()

func _on_can_explote_timeout() -> void :
	is_explotion_bullet = false
