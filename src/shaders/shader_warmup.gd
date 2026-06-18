# ShaderWarmup.gd
extends CanvasLayer

## Escena a cargar después del warmup
@export_file("*.tscn") var next_scene: String = "res://src/core/main/world.tscn"


## Cuántos frames esperar antes de continuar
@export var warmup_frames: int = 2

var _warmup_sprites: Array[Sprite2D] = []
var _frames_waited: int = 0
var _ready_to_advance: bool = false


func _ready() -> void:
	var materials := _collect_all_shader_materials()
	for mat in materials:
		var ghost := Sprite2D.new()
		ghost.material = mat.duplicate()
		ghost.texture = PlaceholderTexture2D.new()
		ghost.position = Vector2(-9999, -9999)
		ghost.visible = true
		add_child(ghost)
		_warmup_sprites.append(ghost)
	_ready_to_advance = true


func _process(_delta: float) -> void:
	if not _ready_to_advance:
		return
	_frames_waited += 1
	if _frames_waited >= warmup_frames:
		for ghost in _warmup_sprites:
			ghost.queue_free()
		if next_scene != "":
			get_tree().change_scene_to_file(next_scene)


func _collect_all_shader_materials() -> Array[ShaderMaterial]:
	var result: Array[ShaderMaterial] = []
	var seen: Dictionary = {}
	_scan_directory("res://", result, seen)
	
	print("=== ShaderWarmup: %d shaders encontrados ===" % result.size())
	for mat in result:
		var shader_path := mat.shader.resource_path if mat.shader != null else "shader embebido sin path"
		print("  - %s" % shader_path)
	
	return result

func _scan_directory(path: String, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path := path.path_join(entry)
			if dir.current_is_dir():
				_scan_directory(full_path, result, seen)
			else:
				_try_file(full_path, result, seen)
		entry = dir.get_next()
	dir.list_dir_end()


func _try_file(path: String, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	if path.ends_with(".tres") or path.ends_with(".res"):
		_try_load_material(path, result, seen)
	elif path.ends_with(".tscn"):
		_scan_tscn(path, result, seen)


func _try_load_material(path: String, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	var res := ResourceLoader.load(path)
	if res is ShaderMaterial:
		_register(res, result, seen)


func _scan_tscn(path: String, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	# Lectura rápida de texto — solo carga la escena si hay indicios de shader
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return

	var content := file.get_as_text()
	file.close()

	# Busca indicios de ShaderMaterial embebido o referencia a .gdshader
	var regex := RegEx.new()
	regex.compile("ShaderMaterial|\\.gdshader")
	if regex.search(content) == null:
		return

	# Solo entonces carga la escena completa e inspecciona el árbol
	var packed := ResourceLoader.load(path) as PackedScene
	if packed == null:
		return

	var instance := packed.instantiate()
	_extract_from_node(instance, result, seen)
	instance.free()


func _extract_from_node(node: Node, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	# Material directo del nodo
	if node is CanvasItem:
		var canvas := node as CanvasItem
		_check_material(canvas.material, result, seen)

	# Recorre hijos
	for child in node.get_children():
		_extract_from_node(child, result, seen)


func _check_material(mat: Material, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	if mat is ShaderMaterial:
		_register(mat, result, seen)


func _register(mat: ShaderMaterial, result: Array[ShaderMaterial], seen: Dictionary) -> void:
	var id := mat.get_rid()
	if not seen.has(id):
		seen[id] = true
		result.append(mat)
