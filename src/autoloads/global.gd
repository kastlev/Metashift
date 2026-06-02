extends Node


var previous_scene_path: String
var frame_sprite_player_index: int
var last_position_player: Vector2

var score: int
var level: int

func _ready() -> void :
	level = 1
