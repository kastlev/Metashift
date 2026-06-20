class_name EnemyButterfly
extends EnemyShooter


@export_group("Characteristics")
@export var must_explotion: bool = true
@export var chase_range: float = 60.0   # si está más cerca que esto -> CHASE
@export var wander_range: float = 80.0  # si está más lejos que esto -> WANDER

@export_group("Shoot")
@export var fire_rate_min: float = 1.0
@export var fire_rate_max: float = 3.0
@onready var detection: DetectionComponent = %DetectionComponent

var _wander_target_offset := EnemyUtils.calc_wander_target_offset()
var _is_wandering := false
var _timer_shoot: Timer


func _ready() -> void:
	super._ready()
	current_state = STATE.WANDER
	detection.target_entered.connect(_on_detection_target_entered)
	_timer_shoot = _create_shoot_timer()
	
func _create_shoot_timer() -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = randf_range(fire_rate_min, fire_rate_max)
	t.timeout.connect(_on_timer_shoot_timeout)
	add_child(t)
	t.start()
	return t


func update_behavior(delta: float) -> void:
	material.set("shader_parameter/velocity",velocity)
	match current_state:
		STATE.CHASE:
			_move_towards_player(delta)
		STATE.WANDER:
			_move_towards_wander_target_offset(delta)

func _move_towards_player(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)

	if dist > wander_range and not _is_wandering:
		_is_wandering = true
		_wander_target_offset = EnemyUtils.calc_wander_target_offset()
		current_state = STATE.WANDER
		return

	velocity = (player.global_position - global_position).normalized() * speed
	
func _flip_sprite() -> void:
	if not is_instance_valid(player):
		return
	var dx := player.global_position.x - global_position.x
	if dx > 4.0:
		animated_sprite.flip_h = false
	elif dx < -4.0:
		animated_sprite.flip_h = true

func _move_towards_wander_target_offset(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var random_target = player.global_position + _wander_target_offset
	velocity = (random_target - global_position).normalized() * speed

	if global_position.distance_to(player.global_position) < chase_range:
		current_state = STATE.CHASE
		_is_wandering = false


func on_died() -> void:
	if must_explotion:
		explotion()


func on_damaged() -> void:
	pass


func _on_detection_target_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		current_state = STATE.CHASE

func _on_timer_shoot_timeout() -> void:
	fire_to_player()
	_timer_shoot.wait_time = randf_range(fire_rate_min, fire_rate_max)
	_timer_shoot.start()
