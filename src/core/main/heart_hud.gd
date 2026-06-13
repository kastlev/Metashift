extends Control

@export var heart_scene: PackedScene

@onready var container: HBoxContainer = $HBoxContainer

var hearts: Array[Heart] = []

func _ready() -> void:
	# conectar con player
	var player = get_tree().get_first_node_in_group("player") as Player
	
	player.health.health_changed.connect(_on_health_changed)
	player.health.max_health_changed.connect(_on_max_health_changed)
	
	# inicializar
	_build_hearts(player.health.data.max_health)
	_update_hearts(player.health.current_health)
	print(player.health.health_changed.get_connections())
	
func _build_hearts(max_health: int) -> void:
	print("BUILD HEARTS CALLED:", max_health, "ID:", get_instance_id())
	# limpiar anterior
	for c in hearts:
		c.queue_free()
	hearts.clear()

	# crear nuevos
	for i in max_health:
		var heart: Heart = heart_scene.instantiate()
		container.add_child(heart)
		hearts.append(heart)

func _update_hearts(current: int) -> void:
	for i in hearts.size():
		hearts[i].set_full(i < current)

func _on_health_changed(current: float, _max_health: float) -> void:
	print("actualinado hud health")
	_update_hearts(int(current))

func _on_max_health_changed(max_health: int) -> void:
	print("MAX HEALTH SIGNAL:", max_health)
	_build_hearts(max_health)
