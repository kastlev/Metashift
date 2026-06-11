extends Node2D

@export var copies := 3
@export var spacing := 5.0

var player: Player
var sprite: AnimatedSprite2D

var ghosts: Array[AnimatedSprite2D] = []

func _ready():
	await owner.ready
	player = owner as Player
	print("owner:", owner)
	print("parent:", get_parent())
	print(player.get_children())
	sprite = player.get_node("%AnimatedSprite2D")

	for i in range(copies):
		var ghost := AnimatedSprite2D.new()

		ghost.sprite_frames = sprite.sprite_frames
		ghost.centered = sprite.centered

		add_child(ghost)
		ghosts.append(ghost)

func _process(_delta):
	if not player.applying_impulse:
		for ghost in ghosts:
			ghost.visible = false
		return

	var dir = -player.current_direction.normalized()

	for i in range(ghosts.size()):
		var ghost := ghosts[i]

		ghost.visible = true
		ghost.animation = sprite.animation
		ghost.frame = sprite.frame
		ghost.flip_h = sprite.flip_h

		ghost.position = dir * 16.0 * (i + 1)

		ghost.modulate = Color(
			1,
			1,
			1,
			0.8 - i * 0.2
		)
