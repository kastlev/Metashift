extends Control

@onready var rounds = %Rounds

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rounds.frame = GLOBAL.level
