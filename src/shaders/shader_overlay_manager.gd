class_name ShaderOverlayManager
extends CanvasLayer

var overlays: Dictionary = {}
var materials: Dictionary = {}

func _ready() -> void:
	print("Shaders registrados en ShaderOverlayManager: ")
	for child in get_children():
		if child is CanvasItem:
			overlays[child.name] = child
			materials[child.name] = child.material
	for child in get_children():
		if child is CanvasItem:
			print(child.name, " -> ", child.material)

# -------------------------------------------------------------------
# VISIBILITY
# -------------------------------------------------------------------

## Hace visible el overlay sin tocar su material.
## Útil cuando el shader ya está asignado y solo quieres mostrarlo.
func show_overlay(overlay_name: String) -> void:
	var overlay := _get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.visible = true


## Oculta el overlay sin tocar su material.
func hide_overlay(overlay_name: String) -> void:
	var overlay := _get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.visible = false


## Oculta todos los overlays y muestra únicamente el indicado.
func show_only(overlay_name: String) -> void:
	if _get_overlay(overlay_name) == null:
		return
	hide_all()
	show_overlay(overlay_name)


## Oculta todos los overlays y muestra los indicados en la lista.
func show_many(overlay_names: Array[String]) -> void:
	hide_all()
	for overlay_name in overlay_names:
		show_overlay(overlay_name)


## Hace visibles todos los overlays registrados.
func show_all() -> void:
	for overlay in overlays.values():
		overlay.visible = true


## Oculta todos los overlays registrados.
func hide_all() -> void:
	for overlay in overlays.values():
		overlay.visible = false


# -------------------------------------------------------------------
# SHADERS
# -------------------------------------------------------------------

## Restaura el material original del overlay (lo reactiva si estaba en null).
## No cambia la visibilidad.
func enable_shader(overlay_name: String) -> void:
	var overlay := _get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.material = materials[overlay_name]


## Desconecta el material del overlay (overlay_name.material = null).
## El nodo sigue visible pero sin efecto de shader.
func disable_shader(overlay_name: String) -> void:
	var overlay := _get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.material = null


## Reactiva el material en todos los overlays registrados.
func enable_all_shaders() -> void:
	for overlay_name in overlays.keys():
		enable_shader(overlay_name)


## Desconecta el material de todos los overlays registrados.
func disable_all_shaders() -> void:
	for overlay_name in overlays.keys():
		disable_shader(overlay_name)


# -------------------------------------------------------------------
# OVERLAYS (VISIBILITY + SHADER)
# -------------------------------------------------------------------

## Activa el overlay: lo hace visible y le asigna su material original.
## Equivale a show + enable_shader en una sola llamada.
func activate_overlay(overlay_name: String) -> void:
	var overlay := _get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.visible = true
	overlay.material = materials[overlay_name]


## Desactiva el overlay: lo oculta y pone su material a null.
## Equivale a hide + disable_shader en una sola llamada.
func deactivate_overlay(overlay_name: String) -> void:
	var overlay := _get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.visible = false
	overlay.material = null


## Desactiva todos los overlays y activa únicamente el indicado.
func activate_only(overlay_name: String) -> void:
	if _get_overlay(overlay_name) == null:
		return
	deactivate_all()
	activate_overlay(overlay_name)


## Desactiva todos los overlays y activa los indicados en la lista.
func activate_many(overlay_names: Array[String]) -> void:
	deactivate_all()
	for overlay_name in overlay_names:
		activate_overlay(overlay_name)


## Activa todos los overlays registrados (visibles + material asignado).
func activate_all() -> void:
	for overlay_name in overlays.keys():
		activate_overlay(overlay_name)


## Desactiva todos los overlays registrados (ocultos + material null).
func deactivate_all() -> void:
	for overlay_name in overlays.keys():
		deactivate_overlay(overlay_name)


# -------------------------------------------------------------------
# ACCESO AVANZADO
# -------------------------------------------------------------------

## Activa el overlay y devuelve su ShaderMaterial listo para modificar parámetros.
## Llama a [method deactivate_after_use] cuando termines para limpiar el estado.
## Devuelve null si el overlay no existe o su material no es un ShaderMaterial.
func activate_for_use(overlay_name: String) -> ShaderMaterial:
	var overlay := get_overlay(overlay_name)
	if overlay == null:
		return null
	var mat := get_shader_material(overlay_name)
	if mat == null:
		return null
	overlay.visible = true
	overlay.material = mat
	return mat


## Oculta el overlay y desconecta su material.
## Usar siempre después de [method activate_for_use] una vez terminado el efecto.
func deactivate_after_use(overlay_name: String) -> void:
	var overlay := get_overlay(overlay_name)
	if overlay == null:
		return
	overlay.visible = false
	overlay.material = null


## Devuelve el nodo CanvasItem del overlay, o null si no existe.
func get_overlay(overlay_name: String) -> CanvasItem:
	return _get_overlay(overlay_name)


## Devuelve el material original guardado en [method _ready], o null si no existe.
## Usa este material para leer parámetros sin riesgo de obtener null
## si el shader fue temporalmente desconectado.
func get_material(overlay_name: String) -> Material:
	if not materials.has(overlay_name):
		push_error(
			"ShaderOverlayManager: material '%s' not found."
			% overlay_name
		)
		return null
	return materials[overlay_name]


## Devuelve el material del overlay casteado a ShaderMaterial.
## Falla con push_error si el material no es un ShaderMaterial.
func get_shader_material(overlay_name: String) -> ShaderMaterial:
	var material := get_material(overlay_name)
	if material == null:
		return null
	if not material is ShaderMaterial:
		push_error(
			"ShaderOverlayManager: material of overlay '%s' is not a ShaderMaterial. Found: %s"
			% [overlay_name, material.get_class()]
		)
		return null
	return material as ShaderMaterial

# -------------------------------------------------------------------
# INTERNAL
# -------------------------------------------------------------------

func _get_overlay(overlay_name: String) -> CanvasItem:
	if not overlays.has(overlay_name):
		push_error(
			"ShaderOverlayManager: overlay '%s' not found.\nAvailable overlays: %s"
			% [overlay_name, overlays.keys()]
		)
		return null
	return overlays[overlay_name]
