class_name ShakeCamera extends Camera2D

# ── Enums ─────────────────────────────────────────────────────────────────────
## Tipo de shake aplicado al trauma.
## RANDOM = caótico. SINE = rítmico. NOISE = suave y continuo.
enum ShakeType { RANDOM, SINE, NOISE }

# ── Follow ────────────────────────────────────────────────────────────────────
@export_group("Follow")
## Nodo que la cámara seguirá automáticamente. Normalmente el Player.
@export var follow_node: Node2D
## Si true, interpola suavemente hacia el objetivo. Si false, sigue instantáneamente.
@export var follow_smooth: bool = true
## Velocidad de suavizado al seguir el objetivo.
@export var follow_smoothing: float = 6.0
## Radio en px donde el player puede moverse sin que la cámara lo siga.
## 0 = la cámara siempre sigue. Isaac usa ~20-40px.
@export var deadzone_radius: float = 0.0

# ── Lookahead ─────────────────────────────────────────────────────────────────
@export_group("Lookahead")
## Cuánto se adelanta la cámara en la dirección de movimiento.
@export var lookahead_distance: float = 30.0
## Velocidad de transición del lookahead.
@export var lookahead_smoothing: float = 3.0

# ── Zoom ──────────────────────────────────────────────────────────────────────
@export_group("Zoom")
## Zoom objetivo. 1.0 = normal. 0.5 = alejado. 2.0 = acercado.
@export var target_zoom: Vector2 = Vector2.ONE
## Velocidad de transición del zoom.
@export var zoom_smoothing: float = 5.0

# ── Shake ─────────────────────────────────────────────────────────────────────
@export_group("Shake")
## Activa o desactiva completamente el screen shake.
@export var enable_shake: bool = true
## Tipo de shake por defecto.
@export var shake_type: ShakeType = ShakeType.NOISE
## Multiplicador global de intensidad del shake.
@export var shake_multiplier: float = 1.0
## Tiempo que tarda el trauma en volver a 0.
@export var decay: float = 1.5
## Valor mínimo antes de detener completamente el shake.
@export var trauma_threshold: float = 0.01
## Desplazamiento máximo horizontal y vertical en píxeles.
## Con resolución 640x360 usar valores pequeños: Vector2(3, 3).
@export var max_offset: Vector2 = Vector2(8.0, 6.0)
## Rotación máxima del shake en radianes. Usar con moderación.
@export var max_roll: float = 0.05

# ── Estado interno ────────────────────────────────────────────────────────────
var trauma: float = 0.0
var trauma_power: int = 2
var _trauma_dir: Vector2 = Vector2.ZERO  # dirección del shake direccional
var _lookahead_offset: Vector2 = Vector2.ZERO
var _last_follow_pos: Vector2 = Vector2.ZERO
var _noise: FastNoiseLite
var _active_shake_type: ShakeType  # tipo activo en este momento

func _ready() -> void:
	GameCameraService.register(self)
	_noise = FastNoiseLite.new()
	_noise.seed = randi()
	_noise.frequency = 0.05
	_active_shake_type = shake_type
	if follow_node:
		_last_follow_pos = follow_node.global_position

func _process(delta: float) -> void:
	_update_follow(delta)
	_update_zoom(delta)
	_update_shake(delta)

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_J: add_trauma(0.2)
			KEY_K: add_trauma(0.5)
			KEY_L: add_trauma(0.9)

# ── Follow ────────────────────────────────────────────────────────────────────
func _update_follow(delta: float) -> void:
	if not follow_node:
		return

	var move_dir := Vector2.ZERO
	if _last_follow_pos != follow_node.global_position:
		move_dir = (follow_node.global_position - _last_follow_pos).normalized()
	_lookahead_offset = _lookahead_offset.lerp(
		move_dir * lookahead_distance,
		lookahead_smoothing * delta
	)
	_last_follow_pos = follow_node.global_position

	var target := follow_node.global_position + _lookahead_offset
	var dist := global_position.distance_to(target)
	if dist > deadzone_radius:
		if follow_smooth:
			global_position = global_position.lerp(target, follow_smoothing * delta)
		else:
			global_position = target
# ── Zoom ──────────────────────────────────────────────────────────────────────
func _update_zoom(delta: float) -> void:
	zoom = zoom.lerp(target_zoom, zoom_smoothing * delta)

# ── Shake ─────────────────────────────────────────────────────────────────────
func _update_shake(delta: float) -> void:
	if trauma <= trauma_threshold:
		trauma = 0.0
		rotation = 0.0
		offset = Vector2.ZERO
		_trauma_dir = Vector2.ZERO
		return
	trauma = max(trauma - decay * delta, 0.0)
	if enable_shake:
		_apply_shake()

func _apply_shake() -> void:
	var amount := pow(trauma, trauma_power) * shake_multiplier
	var ox: float
	var oy: float

	match _active_shake_type:
		ShakeType.RANDOM:
			ox = randf_range(-1.0, 1.0)
			oy = randf_range(-1.0, 1.0)
		ShakeType.SINE:
			var t := Time.get_ticks_msec() * 0.03
			ox = sin(t)
			oy = sin(t * 2.3)
		ShakeType.NOISE:
			var t := Time.get_ticks_msec() * 0.1
			ox = _noise.get_noise_1d(t)
			oy = _noise.get_noise_1d(t + 100.0)

	# Dirección del impacto sesga el shake si hay trauma direccional
	if _trauma_dir != Vector2.ZERO:
		ox += _trauma_dir.x * 0.5
		oy += _trauma_dir.y * 0.5

	rotation = max_roll * amount * randf_range(-1.0, 1.0)
	offset.x = max_offset.x * amount * ox
	offset.y = max_offset.y * amount * oy

# ── API pública ───────────────────────────────────────────────────────────────

## Agrega trauma a la cámara con el tipo de shake por defecto.
## El valor final se limita automáticamente entre 0.0 y 1.0.
func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)
	_active_shake_type = shake_type
	_trauma_dir = Vector2.ZERO

## Agrega trauma con dirección — el shake es más intenso en esa dirección.
## Útil para impactos con dirección conocida (knockback, explosión direccional).
func add_trauma_directional(amount: float, direction: Vector2) -> void:
	trauma = min(trauma + amount, 1.0)
	_active_shake_type = shake_type
	_trauma_dir = direction.normalized()

## Agrega trauma con tipo de shake específico para este evento.
## Solo sobreescribe el tipo si el nuevo trauma es más intenso que el actual.
func add_trauma_typed(amount: float, type: ShakeType) -> void:
	if amount >= trauma:
		_active_shake_type = type
	trauma = min(trauma + amount, 1.0)
	_trauma_dir = Vector2.ZERO
