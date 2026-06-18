extends Node

@export var enemy_scenes: Array[PackedScene]

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var start_position_player: Marker2D = %StartPositionPlayer
@onready var text_tutorial: Label = %TextTutorial
@onready var reticle: Sprite2D = %Reticle
@onready var rounds = %Rounds
@onready var path_spawn_enemy: PathFollow2D = %PathFollowSpawnEnemy
@onready var timer_level: Timer = %TimerLevel
@onready var timer_spawner_enemy: Timer = %SpawnerEnemy
@onready var background = %Background as Sprite2D

@onready var transition_rect = %Transition
@onready var shader_manager = %ScreenFXLayer


const MAX_ENEMY: int = 40
const WIN_DELAY: float = 45.0

var current_amount_enemy: int = 0
var is_victory_unlocked: bool = false
var is_tutorial_visible: bool = false
var is_waiting_for_input: bool = false
var _blink_tween: Tween

var scroll_direction := Vector2.RIGHT
var scroll_offset := Vector2.ZERO
var target_direction := Vector2.RIGHT
var direction_lerp_speed := 2


func _ready() -> void:
	print("READY START")
	transition_rect.visible = true
	#shader_manager.activate_only("Transition")
	var t := Time.get_ticks_usec()
	player.health.died.connect(_on_player_died)
	player.health.damaged.connect(_on_player_damaged)
	player.position = start_position_player.position
	text_tutorial.visible = false
	text_tutorial.modulate.a = 0.0
	_blink_tween = _start_blink()
	_blink_tween.pause()
	transition_rect.visible = true

	var mat = transition_rect.material
	mat.set_shader_parameter("circle_size", 0.0)
	_play_intro_transition()
	GLOBAL.level = 1
	await get_tree().process_frame
	print("FIRST FRAME:",
		(Time.get_ticks_usec() - t) / 1000.0,
		" ms")

func _play_intro_transition() -> void:
	var mat = transition_rect.material

	var tween := create_tween()

	tween.tween_method(
		func(v):
			mat.set_shader_parameter("circle_size", v),
		0.0,
		1.0,
		1.0
	)

	await tween.finished

	transition_rect.visible = false

func _play_outro_transition() -> void:
	transition_rect.visible = true

	var mat = transition_rect.material

	var tween := create_tween()

	tween.tween_method(
		func(v):
			mat.set_shader_parameter("circle_size", v),
		0.0,
		1.0,
		0.8
	)

	await tween.finished

func _process(delta: float) -> void:
	scroll_direction = scroll_direction.lerp(target_direction, delta * direction_lerp_speed).normalized()
	scroll_offset += scroll_direction * delta * background.material.get_shader_parameter("scroll_speed")

	var mat := background.material as ShaderMaterial
	mat.set_shader_parameter("scroll_offset", scroll_offset)
	
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if not is_tutorial_visible and not is_waiting_for_input:
		is_waiting_for_input = true
		text_tutorial.visible = true
		_blink_tween.play()

	if is_waiting_for_input and Input.is_action_just_pressed("continue"):
		_start_game()

	if is_victory_unlocked and get_tree().get_nodes_in_group("enemy").size() == 0:
		SceneLoader.load_scene("res://src/screens/win.tscn")

func _start_blink() -> Tween:
	var tween := create_tween().set_loops()
	tween.tween_property(text_tutorial, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)  # pausa visible antes de desvanecerse
	tween.tween_property(text_tutorial, "modulate:a", 0.0, 0.5)
	tween.tween_interval(0.3)  # pausa invisible antes de volver
	return tween

func _on_player_damaged(_direction: Vector2) -> void:
	var random_angle := randf_range(0.0, 360.0)
	var angle_rad := deg_to_rad(random_angle)
	target_direction = Vector2(cos(angle_rad), sin(angle_rad))
	
	var mat_flash = shader_manager.activate_for_use("DamageFlash") as ShaderMaterial

	if mat_flash == null:
		return

	mat_flash.set_shader_parameter("intensity", 1.0)

	var tween := create_tween()

	tween.tween_property(
		mat_flash,
		"shader_parameter/intensity",
		0.0,
		0.55
	)

	await tween.finished

	shader_manager.deactivate_after_use("DamageFlash")

func _on_player_died() -> void:
	GLOBAL.previous_scene_path = get_tree().current_scene.scene_file_path
	get_tree().call_deferred("change_scene_to_file", "res://src/screens/game_over.tscn") 

func _on_spawn_enemy_timeout() -> void:
	if current_amount_enemy >= MAX_ENEMY:
		return
	var wait_ranges := [[2.0, 2.5], [1.6, 2.0], [1.0, 1.6], [0.7, 1.0]]
	var idx := clampi(GLOBAL.level - 1, 0, wait_ranges.size() - 1)
	timer_spawner_enemy.wait_time = randf_range(wait_ranges[idx][0], wait_ranges[idx][1])
	var enemy := enemy_scenes[randi() % enemy_scenes.size()].instantiate() as Enemy
	path_spawn_enemy.progress_ratio = randf()
	enemy.position = path_spawn_enemy.position
	add_child(enemy)
	var red_intensity := 1.0 - (idx * 0.25)
	enemy.animated_sprite.material.set_shader_parameter("tint_color", Color(1, red_intensity, red_intensity, 1))
	current_amount_enemy += 1


func _on_timer_level_timeout() -> void:
	GLOBAL.level += 1


func _start_game() -> void:
	_blink_tween.kill()
	text_tutorial.modulate.a = 1.0
	text_tutorial.visible = false
	is_waiting_for_input = false
	is_tutorial_visible = true
	timer_spawner_enemy.start()
	timer_level.start()
	_start_win_timer()
	rounds.visible = true

func _start_win_timer() -> void:
	await get_tree().create_timer(WIN_DELAY).timeout
	is_victory_unlocked = true
