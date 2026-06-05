class_name Player
extends CharacterBody2D

@export_group("Shoot")
## Escena de la bala del jugador
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25
@export var bullet_speed: float = 1300.0

@export_group("Movement")
@export var speed: float = 450.0
@export var dash_distance: float = 5000.0
@export var dash_force: float = 600.0
@export var dash_cooldown: float = 0.5

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var bullet_spawn: Marker2D = %BulletSpawn
@onready var health: HealthComponent = %HealthComponent
@onready var sfx_shoot = %Shoot
@onready var sfx_hurt = $Hurt
@onready var sfx_dash = $Dash

var _afterimage_counter := 0


var move_direction: Vector2 = Vector2.UP
var is_dashing: bool = false
var _last_shoot_time: float = 0.0
var _facing_direction_x: float = 0.0
var _last_dash_time: float = -dash_cooldown
var is_shooting: bool = false
var _dash_remaining_distance: float
var _invulnerability_timer := 0.0

func _ready() -> void:
	_dash_remaining_distance = dash_distance 
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)

	if input_direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, 4500.0 * delta)
		is_dashing = false
		_dash_remaining_distance = dash_distance 
		scale = Vector2.ONE
	else:
		move_direction = input_direction.normalized()
		velocity = move_direction * speed

		_flip_sprite(input_direction)

		if is_dashing:
			_process_dash()
		else:
			scale = Vector2.ONE
			animated_sprite.modulate = Color(1.0, 1.0, 1.0)
			_afterimage_counter = 0

	if Input.is_action_just_pressed("ui_accept"):
		_try_dash(input_direction)

	if is_shooting and _can_shoot():
		_shoot()

	_update_blink(delta)

	move_and_slide()

func _process_dash() -> void:
	_afterimage_counter += 1

	if _afterimage_counter % 3 == 0:
		_spawn_afterimage()
	
	animated_sprite.modulate = Color(1.314, 1.314, 1.314)
	scale = Vector2(0.8, 0.8)
	velocity += move_direction * dash_force

	_dash_remaining_distance -= dash_force

	if _dash_remaining_distance > 0:
		return

	is_dashing = false
	_dash_remaining_distance = dash_distance 

func _update_blink(delta: float) -> void:
	if _invulnerability_timer <= 0.0:
		animated_sprite.visible = true
		return

	_invulnerability_timer -= delta
	animated_sprite.visible = int(_invulnerability_timer * 10.0) % 2 == 0

func _try_dash(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return

	if not _can_dash():
		return

	is_dashing = true
	sfx_dash.play()
	_last_dash_time = Time.get_ticks_msec() / 1000.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_shooting = event.pressed

func _can_shoot() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_shoot_time >= fire_rate:
		_last_shoot_time = now
		return true
	return false

func _can_dash() -> bool:
	return (Time.get_ticks_msec() / 1000.0 - _last_dash_time) >= dash_cooldown

func _shoot() -> void:
	if bullet_scene == null or is_dashing:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.velocity_vec = (get_global_mouse_position() - global_position).normalized() * bullet_speed
	get_tree().current_scene.add_child(bullet)
	sfx_shoot.play()

func take_damage(amount: int, _dir: Vector2 = Vector2.ZERO) -> void:
	health.take_damage(amount, _dir)

func _flip_sprite(dir: Vector2) -> void:
	if dir.x == 0:
		return

	_facing_direction_x = dir.x
	animated_sprite.flip_h = _facing_direction_x < 0
	
func _on_damaged(_dir: Vector2 = Vector2.ZERO) -> void:
	sfx_hurt.play()
	_invulnerability_timer = health.data.iframe_duration

func _on_died() -> void:
	GLOBAL.last_position_player = position
	GLOBAL.frame_sprite_player_index = animated_sprite.frame
	queue_free()

func _spawn_afterimage():
	var ghost := AnimatedSprite2D.new()

	ghost.sprite_frames = animated_sprite.sprite_frames
	ghost.animation = animated_sprite.animation
	ghost.frame = animated_sprite.frame

	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.rotation = animated_sprite.rotation

	ghost.global_position = global_position

	ghost.modulate = Color(1, 1, 1, 0.20)

	get_tree().current_scene.add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.15)

	await tween.finished
	ghost.queue_free()
