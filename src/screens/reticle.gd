extends Sprite2D


var _reticule_pulse_tween: Tween
var original_scale: Vector2
var player: Player
var spin_speed := 0.0
var t := 0.0
var target_rotation := 0.0
# En Reticule o en un script del HUD
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	player.fired.connect(_pulse)
	original_scale = scale

func _process(_delta: float) -> void:
	global_position = get_viewport().get_mouse_position()

func _physics_process(delta):
	rotation = lerp_angle(rotation, target_rotation, 95.0 * delta)

func _pulse() -> void:
	target_rotation += PI / 2.0
	if _reticule_pulse_tween:
		_reticule_pulse_tween.kill()
	_reticule_pulse_tween = create_tween()
	_reticule_pulse_tween.tween_property(
		self,
		"scale",
		original_scale * 1.18,
		0.06
	).set_trans(Tween.TRANS_BACK)

	_reticule_pulse_tween.tween_property(
		self,
		"scale",
		original_scale,
		0.12
	).set_trans(Tween.TRANS_QUAD)
