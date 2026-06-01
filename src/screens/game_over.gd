extends Control

@export var next_level: PackedScene

@onready var sprite_player = %Player
@onready var label = %Label
@onready var button = %Button
@onready var timer_show_text = %TimerShowText

var fading: bool = false
var showing_text = false
var showing_button = false

func _ready() -> void :
	label.visible = false
	button.visible = false
	label.modulate = Color(1, 1, 1, 0)
	button.modulate = Color(1, 1, 1, 0)
	sprite_player.frame = GLOBAL.frame_sprite_player_index
	sprite_player.position = GLOBAL.position_player
	sprite_player.stop()

func _process(delta: float) -> void :
	if fading:
		var modulate = sprite_player.modulate
		modulate.a -= delta * 0.7
		if modulate.a <= 0:
			modulate.a = 0
			fading = false
			button.visible = true
		sprite_player.modulate = modulate
	else:
		if timer_show_text.is_stopped() and not showing_text:
			timer_show_text.start()

		if showing_text:
			label.visible = true
			var label_modulate = label.modulate
			label_modulate.a += delta * 0.5
			if label_modulate.a >= 1:
				label_modulate.a = 1
				showing_text = false
				if timer_show_text.is_stopped() and not showing_button:
					timer_show_text.start()
			label.modulate = label_modulate

		if showing_button:
			button.visible = true
			var button_modulate = button.modulate
			button_modulate.a += delta * 0.5
			if button_modulate.a >= 1:
				button_modulate.a = 1
				showing_button = false
			button.modulate = button_modulate

func _on_timer_show_text_timeout() -> void :
	showing_text = true

func _on_timer_delete_player_timeout() -> void :
	fading = true

func _on_timer_show_button_timeout() -> void :
	showing_button = true

func _on_button_pressed() -> void :
	get_tree().change_scene_to_packed(next_level)
