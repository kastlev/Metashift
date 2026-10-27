class_name Utils
extends RefCounted

## Fade out + queue_free de un nodo.
static func fade_and_free(node: Node, duration: float) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(node.queue_free)

## Crea un Timer como hijo de [source]
## [one_shot] = true por defecto — para loops pasar false.
## Devuelve el Timer por si necesitas pausarlo o desconectarlo.
static func create_timer(source: Node, duration: float, callback: Callable, ignore_time_scale: bool = false) -> Timer:
	var timer := Timer.new()
	timer.wait_time = duration
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.ignore_time_scale = ignore_time_scale
	source.add_child(timer)
	timer.timeout.connect(callback)
	return timer

static func play_sfx_random(
	audio: AudioStreamPlayer2D,
	pitch_base := 1.0,
	pitch_variation := 0.05,
	volume_min := -2.0,
	volume_max := 0.0,
	clips: Array[AudioStream] = []
) -> void:
	if clips.size() > 0:
		audio.stream = clips.pick_random()

	audio.pitch_scale = pitch_base + randf_range(-pitch_variation, pitch_variation)
	audio.volume_db = randf_range(volume_min, volume_max)
	audio.play()

static func push_enemies_from_point(scene_tree: SceneTree, origin: Vector2, radius: float, force: float) -> void:
	for node in scene_tree.get_nodes_in_group("enemy"):
		if not is_instance_valid(node):
			continue
		if not (node  is Enemy):
			continue
		var enemy := node as Enemy
		if enemy.is_dead:
			return
		var offset = enemy.global_position - origin
		var dist = offset.length()
		if dist > radius:
			continue

		var direction = offset.normalized() if dist > 0.001 else Vector2.from_angle(randf() * TAU)
		var falloff = 1.0 - (dist / radius)
		print(direction * force * falloff)
		enemy.apply_knockback(direction * force * falloff)
