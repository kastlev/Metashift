class_name Utils
extends RefCounted

## Crea un timer que espera [duration] segundos y llama [callback].
## [ignore_time_scale] = true para que no se vea afectado por hitstop.
static func delay(source: Node, duration: float, callback: Callable, ignore_time_scale: bool = false) -> void:
	source.get_tree().create_timer(duration, false, false, ignore_time_scale).timeout.connect(callback)

## Igual que delay pero devuelve el SceneTreeTimer por si necesitas cancelarlo.
static func delay_ref(source: Node, duration: float, ignore_time_scale: bool = false) -> SceneTreeTimer:
	return source.get_tree().create_timer(duration, false, false, ignore_time_scale)

## Tween de un solo valor — útil para fade, scale, etc.
## Ejemplo: Utils.tween_prop(sprite, "modulate:a", 0.0, 0.3)
static func tween_prop(source: Node, prop: String, to: Variant, duration: float, trans := Tween.TRANS_LINEAR, ease := Tween.EASE_IN_OUT) -> Tween:
	var tween := source.create_tween()
	tween.set_trans(trans)
	tween.set_ease(ease)
	tween.tween_property(source, prop, to, duration)
	return tween

## Fade out + queue_free de un nodo.
static func fade_and_free(node: Node, duration: float) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(node.queue_free)

## Crea un Timer como hijo de [source]
## [one_shot] = true por defecto — para loops pasar false.
## Devuelve el Timer por si necesitas pausarlo o desconectarlo.
static func make_timer(source: Node, duration: float, callback: Callable, one_shot: bool = true, ignore_time_scale: bool = false) -> Timer:
	var timer := Timer.new()
	timer.wait_time = duration
	timer.one_shot = one_shot
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	timer.ignore_time_scale = ignore_time_scale
	source.add_child(timer)
	timer.timeout.connect(callback)
	if one_shot:
		timer.timeout.connect(timer.queue_free)
	return timer
