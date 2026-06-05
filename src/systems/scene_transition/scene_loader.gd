extends Node

signal progress_changed(pogress)
signal load_finished

var loading_screen: PackedScene = preload("res://src/systems/scene_transition/loading_screen.tscn")
var loaded_resource: PackedScene
var scene_path: String
var progress: Array = []
var use_sub_threads: bool = true

func _ready():
	set_process(false)
	
func load_scene(_scene_path: String):
	scene_path = _scene_path
	var new_load_screen = loading_screen.instantiate()
	add_child(new_load_screen)
	
	progress_changed.connect(new_load_screen.on_progress_changed)
	load_finished.connect(new_load_screen.on_load_finished)
	
	await new_load_screen.loading_screen_ready
	
	start_load()

func start_load():
	var state = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)
	
func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	progress_changed.emit(progress[0])
	
	match load_status:
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(loaded_resource)
			load_finished.emit()
			set_process(false)
	
	
