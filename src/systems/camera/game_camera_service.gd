extends Node

var camera: ShakeCamera

func register(cam: ShakeCamera) -> void:
	camera = cam

func unregister(cam: ShakeCamera) -> void:
	if camera == cam:
		camera = null

func add_trauma(amount: float) -> void:
	if camera:
		camera.add_trauma(amount)

func add_trauma_directional(amount: float, dir: Vector2) -> void:
	if camera:
		camera.add_trauma_directional(amount, dir)

func add_trauma_typed(amount: float, type) -> void:
	if camera:
		camera.add_trauma_typed(amount, type)
