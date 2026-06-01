extends CharacterBody2D
class_name Player

@export_group("Shoot")
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.25
@export var fire_velocity = 1300

@export_group("Movement")
@export var speed: float = 450.0
@export var impulse_distance: float = 5000
@export var impulse_acceleration: float = 600.0
@export var dash_cooldown: float = 0.5

@onready var animation_player: AnimatedSprite2D = %AnimatedSprite2D
@onready var screen_size = get_viewport_rect().size
@onready var bullet_spawn = %BulletSpawn
@onready var initial_impulse_distance: float = impulse_distance

@onready var sfx_shoot = %Shoot
@onready var sfx_hurt = $Hurt
@onready var sfx_dash = $Dash

var current_direction: Vector2 = Vector2.UP
var applying_impulse: bool = false

var last_shot_time: float = 0.0
var last_direction_x = 0
var last_dash_time: float = - dash_cooldown

var is_shooting: bool = false
var is_damaged_this_frame: bool = false

func _physics_process(delta: float) -> void :
	is_damaged_this_frame = false

	if GLOBAL.lifes_player <= 0:
		GLOBAL.position_player = position
		GLOBAL.frame_sprite_player_index = animation_player.frame
		queue_free()

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position = position.clamp(Vector2.ZERO, screen_size)
	if direction != Vector2.ZERO:
		var direction_normalized = direction.normalized()
		velocity = direction_normalized * speed
		current_direction = direction_normalized

		if direction.x != 0:
			last_direction_x = direction.x

		animation_player.flip_h = last_direction_x < 0

		if applying_impulse:
			scale.x = 0.8
			scale.y = 0.8
			velocity += current_direction * impulse_acceleration
			impulse_distance -= impulse_acceleration
			if impulse_distance <= 0:
				applying_impulse = false
				impulse_distance = initial_impulse_distance
		else:
			scale.x = 1
			scale.y = 1

	else:
		velocity = velocity.move_toward(Vector2.ZERO, 4500 * delta)
		applying_impulse = false
		impulse_distance = initial_impulse_distance
		scale.x = 1
		scale.y = 1

	if Input.is_action_just_pressed("ui_accept") and can_dash() and direction != Vector2.ZERO and velocity.length() > 0:
		applying_impulse = true
		sfx_dash.play()
		last_dash_time = Time.get_ticks_msec() / 1000.0

	if is_shooting and can_shoot():
		shoot()

	move_and_slide()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_shooting = true
			else:
				is_shooting = false

func can_shoot() -> bool:
	if (Time.get_ticks_msec() / 1000.0 - last_shot_time) >= fire_rate:
		last_shot_time = Time.get_ticks_msec() / 1000.0
		return true
	return false

func can_dash() -> bool:
	return (Time.get_ticks_msec() / 1000.0 - last_dash_time) >= dash_cooldown

func shoot():
	var dir = (get_global_mouse_position() - global_position).normalized()

	if bullet_scene and not applying_impulse:
		var bullet = bullet_scene.instantiate()
		bullet.position = bullet_spawn.global_position
		bullet.velocity = dir * fire_velocity
		get_tree().current_scene.add_child(bullet)
		sfx_shoot.play()
		
func _on_level_hurt_player() -> void :
	sfx_hurt.play()
