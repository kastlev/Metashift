class_name Player
extends CharacterBody2D

## signals
signal fired

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

@export_group("Knockback on Hurt")
## Radio en el que se empujan los enemigos cuando el player recibe daño
@export var hurt_push_radius: float = 300.0
## Fuerza del empujón
@export var hurt_push_force: float = 800.0

## ONREADY
@onready var animated_sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var health: HealthComponent = $Components/HealthComponent
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sfx_fire: AudioStreamPlayer2D = $Audio/Fire
@onready var sfx_hurt: AudioStreamPlayer2D = $Audio/Hurt
@onready var sfx_dash: AudioStreamPlayer2D = $Audio/Dash
@onready var particles_hurt = $VFX/ParticlesHurt

## PUBLIC VARS
var is_dashing: bool = false
var is_shooting: bool = false
var input_direction := Vector2.ZERO

### PRIVATE VARS
var _afterimage_counter := 0
var _hitstop_active := false

var _facing_direction_x: float = 0.0

var _dash_direction_started := Vector2.ZERO
var _dash_position_started := Vector2.ZERO
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_buffer_timer := 0.0
var _dash_iframes_timer := 0.0

var _last_valid_dir := Vector2.ZERO
var _last_dir_timer := 0.0

var _fire_cooldown_timer := 0.0

var random = 0.0

var _original_sprite_scale := Vector2.ONE
var _original_sprite_z_index := 10
var can_pulse := true
var tween_move_pulse: Tween
var last_axis := ""
var _original_material: Material

var _freeze_timer := 0.0
const DASH_FREEZE_DURATION := 0.015

var _land_tween: Tween

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_original_sprite_scale = animated_sprite.scale
	_original_sprite_z_index = animated_sprite.z_index
	_original_material = animated_sprite.material

func _physics_process(delta: float) -> void:
		# Freeze solo del player — todo lo demás sigue corriendo
	if _freeze_timer > 0.0:
		_freeze_timer -= delta
		# Durante el freeze mostrar la pose estirada pero no mover
		_update_property_while_dash()
		return
	
	_read_input()
	_tick_timers(delta)
	
	_check_buffer_dash()
	_handle_dash()
	_handle_movement(delta)
	_handle_fire()
	_flip_sprite()
	_update_blink()
	move_and_slide()

func can_move_feel() -> bool:
	return !is_dashing and can_pulse

func get_movement_axis() -> String:
	if abs(input_direction.x) > abs(input_direction.y):
		return "horizontal"
	else:
		return "vertical"

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
	#_dash_cooldown_timer = _tick_timer(_dash_cooldown_timer, delta)
	_dash_timer = _tick_timer(_dash_timer, delta)
	_dash_buffer_timer = _tick_timer(_dash_buffer_timer, delta)
	_last_dir_timer = _tick_timer(_last_dir_timer, delta)
	_dash_iframes_timer = _tick_timer(_dash_iframes_timer, delta)
	
# Guardar ANTES de tickear
	var was_on_cooldown := _dash_cooldown_timer > 0.0
	_dash_cooldown_timer = _tick_timer(_dash_cooldown_timer, delta)
	# Ahora sí: antes estaba en cooldown y ahora llegó a 0
	if was_on_cooldown and _dash_cooldown_timer <= 0.0:
		var tween := create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1.397, 1.397, 1.397, 1.0), 0.05)
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

func _check_buffer_dash() -> void:
	if _dash_buffer_timer <= 0.0:
		return

	var dir := input_direction
	if dir == Vector2.ZERO and _last_dir_timer > 0.0:
		dir = _last_valid_dir

	if _dash_buffer_timer > 0.0 and _can_dash() and dir != Vector2.ZERO:
		_start_dash()
		_dash_buffer_timer = 0.0



func _do_dash_freeze() -> void:
	_freeze_timer = DASH_FREEZE_DURATION


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
	_do_dash_freeze()
	Utils.play_sfx_random(sfx_dash)
	_dash_position_started = global_position
	await get_tree().create_timer(0.2).timeout
	get_tree().call_group("shockwave", "play", _dash_position_started)

func _handle_dash() -> void:
	if !is_dashing:
		return

	animated_sprite.material = null

	if input_direction != Vector2.ZERO:
		var _current_input_influence_to_dash = 0.5
		var new_dir = _dash_direction_started.slerp(input_direction, _current_input_influence_to_dash)
		
		# Solo aplicar si el nuevo dir no se aleja demasiado del original
		if new_dir.dot(_dash_direction_started) > 0.0:
			_dash_direction_started = new_dir

	velocity = _dash_direction_started * dash_speed
	_update_property_while_dash()

	if _dash_timer <= 0.0:
		is_dashing = false
		_dash_iframes_timer = POST_DASH_IFRAMES
		_update_property_end_dash()

func _update_property_while_dash():
	
	if _land_tween:
		_land_tween.kill()
		_land_tween = null
	
	collision_shape_2d.disabled = true

	_afterimage_counter += 1
	if _afterimage_counter % 2 == 0:
		_spawn_afterimage()

	if random == 0.0:
		random = randf()

	var dir := input_direction if input_direction != Vector2.ZERO else _dash_direction_started
	dir = dir.normalized()

	var horizontal_stretch = Vector2(1.4, 0.7)
	var vertical_stretch = Vector2(0.4, 1.8)
	var dash_scale = horizontal_stretch if abs(dir.x) > abs(dir.y) else vertical_stretch
	
	var scale_plus = Vector2.ZERO
	
	if random <= 0.5:
		#scale_plus = Vector2(2.0, 2.0)
		animated_sprite.z_index = _original_sprite_z_index
	else:
		#scale_plus = Vector2(0, 0)
		animated_sprite.z_index = 9
	
	var base_scale = _original_sprite_scale * dash_scale
	var final_scale = base_scale + scale_plus
	
	animated_sprite.scale = final_scale
	
	var is_diagonal = abs(dir.x) > 0.3 and abs(dir.y) > 0.3
	
	if is_diagonal:
		if dir.y < 0:
			animated_sprite.skew = dir.x * 0.7
		else:
			animated_sprite.skew = dir.x * -0.7
	var white_color = Color(1.439, 1.439, 1.439, 1.0)
	var dark_color = Color(0.859, 0.859, 0.859)
	
	animated_sprite.modulate = dark_color
	
func _update_property_end_dash():
	collision_shape_2d.disabled = false
	_afterimage_counter = 0
	animated_sprite.scale = _original_sprite_scale
	animated_sprite.skew = 0.0
	random = 0.0
	
	if _land_tween:
		_land_tween.kill()

	var dir := _dash_direction_started.normalized()
	var land_squash := Vector2(0.5, 1.8) if abs(dir.x) > abs(dir.y) else Vector2(1.8, 0.5)
	animated_sprite.scale = _original_sprite_scale * land_squash

	_land_tween = create_tween()
	_land_tween.tween_property(animated_sprite, "scale", _original_sprite_scale, 0.62)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)


func _handle_movement(delta):
	if is_dashing:
		return
	animated_sprite.material = _original_material
	if input_direction:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		#if _land_tween:
			#_land_tween.kill()
#
		#var dir := _last_valid_dir.normalized()
		#var land_squash := Vector2(0.5, 1.8) if abs(dir.x) > abs(dir.y) else Vector2(1.8, 0.5)
		#animated_sprite.scale = _original_sprite_scale * land_squash
#
		#_land_tween = create_tween()
		#_land_tween.tween_property(animated_sprite, "scale", _original_sprite_scale, 0.62)\
			#.set_trans(Tween.TRANS_ELASTIC)\
			#.set_ease(Tween.EASE_OUT)

func _handle_fire():
	if !is_shooting:
		return
		
	if _fire_cooldown_timer > 0.0:
		return
		
	pulse()
	_fire()
	GameCameraService.add_trauma(0.3)
	_fire_cooldown_timer = fire_cooldown
	fired.emit()
	
func pulse():
	if not can_pulse:
		return

	can_pulse = false

	var tween = create_tween()

	tween.tween_property(animated_sprite, "scale", Vector2(2.4, 2.4), 0.05)
	tween.tween_property(animated_sprite, "scale", _original_sprite_scale, 0.1)

	tween.finished.connect(func():
		can_pulse = true
	)

func _fire() -> void:
	if bullet_scene == null or is_dashing:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = bullet_spawn.global_position
	bullet.velocity_vec = (get_global_mouse_position() - global_position).normalized() * bullet_speed
	get_tree().current_scene.add_child(bullet)
	Utils.play_sfx_random(sfx_fire)

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
		return

	animated_sprite.modulate = Color.WHITE

	if health.iframe_timer > 0.0:
		animated_sprite.visible = int(health.iframe_timer * 10.0) % 2 == 0
		collision_shape_2d.disabled = true
	else:
		animated_sprite.visible = true
		collision_shape_2d.disabled = false

func _spawn_afterimage() -> void:
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = animated_sprite.sprite_frames
	ghost.animation = animated_sprite.animation
	ghost.frame = animated_sprite.frame
	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.rotation = animated_sprite.rotation
	ghost.skew = animated_sprite.skew
	ghost.global_position = global_position
	ghost.modulate = Color(1, 1, 1, 0.20)
	ghost.z_index = animated_sprite.z_index
	get_tree().current_scene.add_child(ghost)
	var tween := create_tween()
	var time_fading_afterImage = 0.22
	tween.tween_property(ghost, "modulate:a", 0.0, time_fading_afterImage)
	await tween.finished
	ghost.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_shooting = event.pressed
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dash()
	
	if event.is_action_pressed("dash"):
		_dash()

func _dash():
	if _can_dash() and input_direction != Vector2.ZERO:
		_start_dash()
	else:
		_dash_buffer_timer = DASH_BUFFER_WINDOW
### SIGNALS
func _on_damaged(_dir: Vector2 = Vector2.ZERO) -> void:
	Utils.play_sfx_random(sfx_hurt)
	animated_sprite.visible = true
	Utils.push_enemies_from_point(get_tree(), global_position, hurt_push_radius, hurt_push_force)
	if _hitstop_active:
		return

	_hitstop_active = true
	await _do_hitstop()
	_hitstop_active = false
	GameCameraService.add_trauma(0.65)
	particles_hurt.emitting = true
	
#
func _on_died() -> void:
	Engine.time_scale = 1.0
	GLOBAL.last_position_player = position
	GLOBAL.frame_sprite_player_index = animated_sprite.frame
	queue_free()

## Uitlity
func _can_dash() -> bool:
	return _dash_cooldown_timer <= 0.0
	
func _tick_timer(timer: float, delta: float) -> float:
	return maxf(timer - delta, 0.0)
