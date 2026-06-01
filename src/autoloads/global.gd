extends Node

var frame_sprite_player_index
var position_player: Vector2
var lifes_player: int = 2
var player_is_immune = false
var level: float

func _ready() -> void :
	level = 1
