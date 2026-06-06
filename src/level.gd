extends Node


@export var enemy_scenes: Array[PackedScene]

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var start_position_player: Marker2D = %StartPositionPlayer
@onready var lifes: Label = %Lifes
@onready var text_tutorial: Label = %TextTutorial
@onready var reticle: Sprite2D = %Reticle
@onready var path_spawn_enemy: PathFollow2D = %PathSpawnEnemy
@onready var lighted_cender: PointLight2D = %LightedCender
@onready var timer_level: Timer = %TimerLevel
@onready var timer_spawner_enemy: Timer = %SpawnerEnemy

@onready var transition_rect = %TransitionRect


const MAX_ENEMY: int = 50
const WIN_DELAY: float = 50.0
const LIGHT_TARGET: float = 1.7
const LIGHT_SPEED: float = 0.015

var amount_enemy: int = 0
var can_win: bool = false
var tutorial_done: bool = false
var waiting_for_input: bool = false
var _blink_tween: Tween


func _ready() -> void:
	player.health.damaged.connect(_on_health_player_change)
	player.health.died.connect(_on_player_died)
	_on_health_player_change()
	player.position = start_position_player.position
	text_tutorial.visible = false
	text_tutorial.modulate.a = 0.0
	lighted_cender.energy = 0
	_blink_tween = _start_blink()
	_blink_tween.pause()
	_play_intro_transition()
	
func _play_intro_transition() -> void:
	var mat = transition_rect.material

	mat.set_shader_parameter("circle_size", 0.0)

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

func _process(_delta: float) -> void:
	reticle.global_position = get_viewport().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if lighted_cender.energy < LIGHT_TARGET:
		lighted_cender.energy = minf(lighted_cender.energy + LIGHT_SPEED, LIGHT_TARGET)
	elif not tutorial_done and not waiting_for_input:
		waiting_for_input = true
		text_tutorial.visible = true
		_blink_tween.play()

	if waiting_for_input and Input.is_action_just_pressed("continue"):
		_start_game()

	if can_win and get_tree().get_nodes_in_group("enemy").size() == 0:
		SceneLoader.load_scene("res://src/screens/win.tscn")


func _start_blink() -> Tween:
	var tween := create_tween().set_loops()
	tween.tween_property(text_tutorial, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)  # pausa visible antes de desvanecerse
	tween.tween_property(text_tutorial, "modulate:a", 0.0, 0.5)
	tween.tween_interval(0.3)  # pausa invisible antes de volver
	return tween


func _on_health_player_change(_dir: Vector2 = Vector2.ZERO) -> void:
	lifes.text = str(player.health.current_health)


func _on_player_died() -> void:
	GLOBAL.previous_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://src/screens/game_over.tscn")

func _on_spawn_enemy_timeout() -> void:
	if amount_enemy >= MAX_ENEMY:
		return
	var wait_ranges := [[2.0, 2.5], [1.6, 2.0], [1.0, 1.6], [0.7, 1.0]]
	var idx := clampi(GLOBAL.level - 1, 0, wait_ranges.size() - 1)
	timer_spawner_enemy.wait_time = randf_range(wait_ranges[idx][0], wait_ranges[idx][1])
	var enemy := enemy_scenes[randi() % enemy_scenes.size()].instantiate()
	path_spawn_enemy.progress_ratio = randf()
	enemy.position = path_spawn_enemy.position
	add_child(enemy)
	amount_enemy += 1


func _on_timer_level_timeout() -> void:
	GLOBAL.level += 1


func _start_game() -> void:
	_blink_tween.kill()
	text_tutorial.modulate.a = 1.0
	text_tutorial.visible = false
	waiting_for_input = false
	tutorial_done = true
	timer_spawner_enemy.start()
	timer_level.start()
	_start_win_timer()


func _start_win_timer() -> void:
	await get_tree().create_timer(WIN_DELAY).timeout
	can_win = true
