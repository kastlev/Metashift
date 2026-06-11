extends Control

@onready var sprite_player: AnimatedSprite2D = %Player
@onready var game_over_label: Label = %GameOverLabel
@onready var retry_button: Button = %RetryButton

func _ready() -> void:
	game_over_label.visible = false
	retry_button.visible = false

	game_over_label.modulate.a = 0.0
	retry_button.modulate.a = 0.0

	sprite_player.frame = GLOBAL.frame_sprite_player_index
	sprite_player.position = GLOBAL.last_position_player
	sprite_player.stop()

	retry_button.pressed.connect(_on_button_pressed)
	sequence()

func sequence() -> void:
	await get_tree().create_timer(0.8).timeout
	
	var tween := create_tween()
	tween.tween_property(sprite_player, "modulate:a", 0.0, 1.5)
	
	await tween.finished

	game_over_label.visible = true
	tween = create_tween()
	tween.tween_property(game_over_label, "modulate:a", 1.0, 1.0)
	
	await tween.finished
	
	await get_tree().create_timer(0.5).timeout
	
	retry_button.visible = true
	tween = create_tween()
	tween.tween_property(retry_button, "modulate:a", 1.0, 1.0)

func _on_button_pressed() -> void:
	var start = Time.get_ticks_usec()
	print(
	get_tree().get_nodes_in_group("enemy").size()
	)
	get_tree().change_scene_to_file(GLOBAL.previous_scene_path)
	print("change scene:", Time.get_ticks_usec() - start)
