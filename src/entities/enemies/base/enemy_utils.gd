class_name EnemyUtils


## Dispara una bala hacia el jugador
static func fire_to_player(
	origin: Vector2,
	player: Player,
	bullet_scene: PackedScene,
	fire_velocity: float,
	scene_root: Node
) -> void:
	if not is_instance_valid(player) or bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	bullet.global_position = origin
	bullet.velocity_vec = (player.global_position - origin).normalized() * fire_velocity
	scene_root.add_child(bullet)


## Dispara balas en todas las direcciones
static func explotion(
	origin: Vector2,
	num_bullets: int,
	bullet_speed: float,
	bullet_range: float,
	bullet_scene: PackedScene,
	parent: Node
) -> void:
	if bullet_scene == null:
		return
	for i in range(num_bullets):
		var angle := (2.0 * PI / num_bullets) * i
		var bullet := bullet_scene.instantiate()
		bullet.global_position = origin
		bullet.velocity_vec = Vector2(cos(angle), sin(angle)).normalized() * bullet_speed
		bullet.max_distance = bullet_range
		parent.add_sibling(bullet)


## Mueve hacia un punto aleatorio cerca del jugador
static func calc_random_offset() -> Vector2:
	var angle := randf_range(0.0, 2.0 * PI)
	var dist := randf_range(0.0, 300.0)
	return Vector2(cos(angle), sin(angle)) * dist


## Ejecuta el impulso y devuelve si terminó
static func impulse_step(
	current_distance: float,
	impulse_acceleration: float
) -> float:
	return current_distance - impulse_acceleration
