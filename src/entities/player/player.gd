class_name Player
extends CharacterBody2D

@export_group("Shoot")
## Escena de la bala del jugador
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25
@export var fire_velocity: float = 1300.0

@export_group("Movement")
@export var speed: float = 450.0
@export var impulse_distance: float = 5000.0
@export var impulse_acceleration: float = 600.0
@export var dash_cooldown: float = 0.5

@onready var animation_player: AnimatedSprite2D = %AnimatedSprite2D
@onready var bullet_spawn: Marker2D = %BulletSpawn
@onready var health: HealthComponent = %HealthComponent
@onready var sfx_shoot = %Shoot
@onready var sfx_hurt = $Hurt
@onready var sfx_dash = $Dash

var current_direction: Vector2 = Vector2.UP
var applying_impulse: bool = false
var last_shot_time: float = 0.0
var last_direction_x: float = 0.0
var last_dash_time: float = -dash_cooldown
var is_shooting: bool = false
var _impulse_distance_current: float
var blink_timer := 0.0

func _ready() -> void:
	_impulse_distance_current = impulse_distance
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)

	if dir != Vector2.ZERO:
		var dir_norm := dir.normalized()
		velocity = dir_norm * speed
		current_direction = dir_norm
		if dir.x != 0:
			last_direction_x = dir.x
		animation_player.flip_h = last_direction_x < 0

		if applying_impulse:
			scale = Vector2(0.8, 0.8)
			velocity += current_direction * impulse_acceleration
			_impulse_distance_current -= impulse_acceleration
			if _impulse_distance_current <= 0:
				applying_impulse = false
				_impulse_distance_current = impulse_distance
		else:
			scale = Vector2.ONE
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 4500.0 * delta)
		applying_impulse = false
		_impulse_distance_current = impulse_distance
		scale = Vector2.ONE

	if Input.is_action_just_pressed("ui_accept") and can_dash() \
			and dir != Vector2.ZERO and velocity.length() > 0:
		applying_impulse = true
		sfx_dash.play()
		last_dash_time = Time.get_ticks_msec() / 1000.0

	if is_shooting and can_shoot():
		shoot()

	if blink_timer > 0.0:
		blink_timer -= delta
		animation_player.visible = int(blink_timer * 10.0) % 2 == 0
	else:
		animation_player.visible = true

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_shooting = event.pressed

func can_shoot() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_shot_time >= fire_rate:
		last_shot_time = now
		return true
	return false

func can_dash() -> bool:
	return (Time.get_ticks_msec() / 1000.0 - last_dash_time) >= dash_cooldown

func shoot() -> void:
	if bullet_scene == null or applying_impulse:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.velocity_vec = (get_global_mouse_position() - global_position).normalized() * fire_velocity
	get_tree().current_scene.add_child(bullet)
	sfx_shoot.play()

func take_damage(amount: int, _dir: Vector2 = Vector2.ZERO) -> void:
	health.take_damage(amount, _dir)

func _on_damaged(_dir: Vector2 = Vector2.ZERO) -> void:
	sfx_hurt.play()
	blink_timer = health.data.iframe_duration

func _on_died() -> void:
	GLOBAL.last_position_player = position
	GLOBAL.frame_sprite_player_index = animation_player.frame
	queue_free()
