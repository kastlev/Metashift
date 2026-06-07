class_name EnemyFly
extends EnemyShooter

@export_group("Characteristics")
## A partir de este nivel dispara al jugador
@export var shoot_from_level: int = 3

@onready var detection: DetectionComponent = %DetectionComponent

var _timer_shoot: Timer

func _ready() -> void:
	super._ready()
	current_state = STATE.CHARGING  # <- lanza hacia el player al spawnear
	if GLOBAL.level >= shoot_from_level:
		_timer_shoot = _create_shoot_timer()

func _create_shoot_timer() -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = randf_range(2.0, 4.0)
	t.timeout.connect(_on_timer_shoot_timeout)
	add_child(t)
	t.start()
	return t

func update_behavior(delta: float) -> void:
	match current_state:
		STATE.CHARGING:
			_charge_towards_player()
			current_state = STATE.BOUNCING
		STATE.BOUNCING:
			_rebound_around(delta)
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)

		print(
			"collider:",
			c.get_collider().name,
			" normal:",
			c.get_normal()
		)

func _charge_towards_player() -> void:
	# Se llama UNA vez al entrar en CHARGING, setea velocidad y ya no recalcula
	if not is_instance_valid(player):
		return
	velocity = (player.global_position - global_position).normalized() \
		* speed


func _rebound_around(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if not collision:
		return

	var collider := collision.get_collider()
	velocity = velocity.bounce(collision.get_normal())

	if collider.is_in_group("wall"):
		if scale <= Vector2(2.2, 2.2):
			scale += Vector2(0.1, 0.1)
		if scale >= Vector2(1.1, 1.1):
			GameCameraService.add_trauma(0.7)
		current_state = STATE.CHARGING
		

func _use_manual_movement() -> bool:
	return current_state == STATE.BOUNCING


func on_died() -> void:
	pass


func on_damaged() -> void:
	pass

func _on_timer_shoot_timeout() -> void:
	fire_to_player()
	_timer_shoot.wait_time = randf_range(2.0, 4.0)
	_timer_shoot.start()
