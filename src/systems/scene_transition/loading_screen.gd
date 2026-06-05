extends CanvasLayer

signal loading_screen_ready

@export var animation_player: AnimationPlayer

func _ready():
	await animation_player.animation_finished
	loading_screen_ready.emit()

func on_progress_changed(progress: float):
	pass

func on_load_finished():
	animation_player.play_backwards("transition_black")
	await animation_player.animation_finished
	queue_free()
