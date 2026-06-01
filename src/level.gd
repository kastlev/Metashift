extends Node

signal hurt_player

@export var enemy_scenes: Array[PackedScene]

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var start_position_player: Marker2D = %StartPositionPlayer

@onready var lifes: Label = %Lifes
@onready var text_tutorial: Label = %TextTutorial
@onready var reticle = %Reticle

@onready var path_spawn_enemy: PathFollow2D = %PathSpawnEnemy
@onready var lighted_cender: PointLight2D = %LightedCender

@onready var timer_level: Timer = %TimerLevel
@onready var blink_timer: Timer = %BlinkTimer
@onready var timer_win: Timer = %TimerWin
@onready var timer_immune: Timer = %TimerImmune
@onready var timer_spawner_enemy: Timer = %SpawnerEnemy
@onready var level_finished = %LevelFinished

var can_win: bool = false
var amount_enemy: int = 0
var max_enemy: int = 50
var game_started: bool = false
var is_showing_tutorial: bool = false
var player_is_visible: bool = true
var player_: CharacterBody2D

func _ready() -> void :
	timer_win.wait_time = 50
	GLOBAL.lifes_player = 7
	lifes.text = str(GLOBAL.lifes_player)
	text_tutorial.visible = false
	lighted_cender.energy = 0
	player.position = start_position_player.position
	GLOBAL.player_is_immune = false

func _process(_delta: float) -> void :
	reticle.global_position = get_viewport().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	print("nivel: ", GLOBAL.level)
	
	if can_win:
			var enemies = get_tree().get_nodes_in_group("enemy")
			if enemies.size() == 0:
				get_tree().change_scene_to_file("res://src/screens/win.tscn")

	lifes.text = str(GLOBAL.lifes_player)

	if GLOBAL.lifes_player <= 0:
		get_tree().change_scene_to_file("res://src/screens/game_over.tscn")

	if GLOBAL.player_is_immune and player:
		if blink_timer.is_stopped():
			blink_timer.start()
	else:
		blink_timer.stop()

	if GLOBAL.player_is_immune and timer_immune.is_stopped() and GLOBAL.lifes_player != 0:
		timer_immune.start()
		player.visible = false
		hurt_player.emit()

	if lighted_cender.energy < 1.7:
		lighted_cender.energy += 0.015
	else:
		if is_showing_tutorial == false:
			text_tutorial.visible = true
			is_showing_tutorial = true

	if Input.is_action_just_pressed("continue") and is_showing_tutorial:
		level_finished.start()
		text_tutorial.visible = false
		game_started = true
		timer_spawner_enemy.start()
		timer_level.start()
		timer_win.start()

func _on_spawn_enemy_timeout() -> void :
	if GLOBAL.level == 1:
		timer_spawner_enemy.wait_time = randf_range(2, 2.5)
	elif GLOBAL.level == 2:
		timer_spawner_enemy.wait_time = randf_range(1.6, 2)
	elif GLOBAL.level == 3:
		timer_spawner_enemy.wait_time = randf_range(1, 1.6)
	elif GLOBAL.level == 4:
		timer_spawner_enemy.wait_time = randf_range(0.7, 1)

	if amount_enemy < max_enemy:
		var random_enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = random_enemy_scene.instantiate()

		path_spawn_enemy.progress_ratio = randf()
		enemy.position = path_spawn_enemy.position

		add_child(enemy)
		amount_enemy += 1

func _on_timer_immune_timeout() -> void :
	GLOBAL.player_is_immune = false
	if player:
		player.visible = true

func _on_blink_timer_timeout() -> void :
	if GLOBAL.player_is_immune and GLOBAL.lifes_player != 0:
		player_is_visible = !player_is_visible
		player.visible = player_is_visible

func _on_timer_win_timeout() -> void :
	can_win = true

func _on_timer_stop_mobs_timeout() -> void :
	timer_spawner_enemy.stop()

func _on_timer_level_timeout() -> void :
	GLOBAL.level += 1
