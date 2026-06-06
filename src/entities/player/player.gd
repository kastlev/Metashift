class_name Player
extends CharacterBody2D

## CONSTANTS
const DASH_BUFFER_WINDOW := 0.18
const DIR_LENIENCY_WINDOW := 0.08
const POST_DASH_IFRAMES := 0.12

## EXPORTS
@export_group("Shoot")
@export var bullet_scene: PackedScene
@export var fire_cooldown: float = 0.25
@export var bullet_speed: float = 1300.0

@export_group("Movement")
@export var speed: float = 600.0
@export var acceleration: float = 4000
@export var friction: float = 5000

@export_group("Dash")
@export var dash_speed := 1200.0
@export var dash_acceleration: float = 100.0
@export var dash_friction: float = 1050.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 0.5

## ONREADY
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var bullet_spawn: Marker2D = %BulletSpawn
@onready var health: HealthComponent = %HealthComponent
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sfx_shoot: AudioStreamPlayer2D = %Shoot
@onready var sfx_hurt: AudioStreamPlayer2D = $Hurt
@onready var sfx_dash: AudioStreamPlayer2D = $Dash

## PUBLIC VARS
var is_dashing: bool = false
var is_shooting: bool = false
var input_direction := Vector2.ZERO

### PRIVATE VARS
var _afterimage_counter := 0
var _hitstop_active := false

var _facing_direction_x: float = 0.0

var _dash_direction_started := Vector2.ZERO
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_buffer_timer := 0.0
var _dash_iframes_timer := 0.0

var _last_valid_dir := Vector2.ZERO
var _last_dir_timer := 0.0

var _fire_cooldown_timer := 0.0

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	_read_input()
	_tick_timers(delta)
	
	_check_buffer_dash()
	_handle_dash()
	_handle_movement(delta)
	_handle_fire()
	_flip_sprite()
	_update_blink()
	
	move_and_slide()

### PUBLIC FUNC
func is_invulnerable() -> bool:
	return is_dashing or _dash_iframes_timer > 0.0 or health.iframe_timer > 0.0

func _read_input() -> void:
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction != Vector2.ZERO:
		_last_valid_dir = input_direction
		_last_dir_timer = DIR_LENIENCY_WINDOW

func _tick_timers(delta: float) -> void:
	_fire_cooldown_timer = _tick_timer(_fire_cooldown_timer, delta)
	_dash_cooldown_timer = _tick_timer(_dash_cooldown_timer, delta)
	_dash_timer = _tick_timer(_dash_timer, delta)
	_dash_buffer_timer = _tick_timer(_dash_buffer_timer, delta)
	_last_dir_timer = _tick_timer(_last_dir_timer, delta)
	_dash_iframes_timer = _tick_timer(_dash_iframes_timer, delta)

func _check_buffer_dash() -> void:
	if _dash_buffer_timer <= 0.0:
		return

	var dir := input_direction
	if dir == Vector2.ZERO and _last_dir_timer > 0.0:
		dir = _last_valid_dir

	if _dash_buffer_timer > 0.0 and _can_dash() and dir != Vector2.ZERO:
		_start_dash()
		_dash_buffer_timer = 0.0

func _start_dash() -> void:
	if is_dashing:
		return

	if !_can_dash():
		return

	var dir := input_direction
	if dir == Vector2.ZERO and _last_dir_timer > 0.0:
		dir = _last_valid_dir
	if dir == Vector2.ZERO:
		return

	_dash_direction_started = dir
	is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown

func _handle_dash():
	if !is_dashing:
		return

	if input_direction != Vector2.ZERO:
		_dash_direction_started = _dash_direction_started.slerp(input_direction, 0.7)

	velocity = _dash_direction_started * dash_speed
	
	collision_shape_2d.disabled = true
	
	_afterimage_counter += 1
	if _afterimage_counter % 3 == 0:
		_spawn_afterimage()

	scale = Vector2(0.5, 0.5)

	if _dash_timer <= 0.0:
		is_dashing = false
		_dash_iframes_timer = POST_DASH_IFRAMES
		
func _handle_movement(delta):
	if is_dashing:
		return

	if input_direction:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	scale = Vector2.ONE
	collision_shape_2d.disabled = false
	_afterimage_counter = 0

func _handle_fire():
	if !is_shooting:
		return
		
	if _fire_cooldown_timer > 0.0:
		return
	_fire()
	_fire_cooldown_timer = fire_cooldown

func _fire() -> void:
	if bullet_scene == null or is_dashing:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.velocity_vec = (get_global_mouse_position() - global_position).normalized() * bullet_speed
	get_tree().current_scene.add_child(bullet)
	sfx_shoot.play()

func _flip_sprite() -> void:
	if input_direction.x == 0:
		return
	_facing_direction_x = input_direction.x
	animated_sprite.flip_h = _facing_direction_x < 0

func _do_hitstop() -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.025, false, false, true).timeout
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.04, false, false, true).timeout
	Engine.time_scale = 1.0

## VISUAL
func _update_blink() -> void:
	if is_dashing:
		animated_sprite.visible = true
		animated_sprite.modulate = Color(0.822, 0.861, 0.99, 0.502)
		return

	animated_sprite.modulate = Color.WHITE

	if health.iframe_timer > 0.0:
		animated_sprite.visible = int(health.iframe_timer * 10.0) % 2 == 0
	else:
		animated_sprite.visible = true

func _spawn_afterimage() -> void:
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
	tween.tween_property(ghost, "modulate:a", 0.0, 0.10)
	await tween.finished
	ghost.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_shooting = event.pressed
	
	if event.is_action_pressed("ui_accept"):
		if _can_dash() and input_direction != Vector2.ZERO:
			_start_dash()
		else:
			_dash_buffer_timer = DASH_BUFFER_WINDOW

### SIGNALS
func _on_damaged(_dir: Vector2 = Vector2.ZERO) -> void:
	sfx_hurt.play()
	animated_sprite.visible = true

	if _hitstop_active:
		return

	_hitstop_active = true
	await _do_hitstop()
	_hitstop_active = false
	GameCameraService.add_trauma(0.65)
#
func _on_died() -> void:
	GLOBAL.last_position_player = position
	GLOBAL.frame_sprite_player_index = animated_sprite.frame
	queue_free()

## Uitlity
func _can_dash() -> bool:
	return _dash_cooldown_timer <= 0.0
	
func _tick_timer(timer: float, delta: float) -> float:
	return maxf(timer - delta, 0.0)
