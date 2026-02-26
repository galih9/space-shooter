extends Node

## Orchestrates multiple enemy waves using EnemySpawner children.
## Each wave fires sequentially. After all waves complete, loops back.

signal all_waves_finished
signal enemy_killed(points)

@export var waves_config: Array[Dictionary] = []

var _current_wave_index: int = -1
var _current_spawner: Node = null
var _fallback_timer: Timer = null
var _game_running: bool = false
var _spawner_nodes: Array = []

func _ready():
	_collect_spawners()
	if waves_config.is_empty():
		_build_default_waves()

func _collect_spawners():
	_spawner_nodes.clear()
	for child in get_children():
		if child is Path2D:
			for subchild in child.get_children():
				if subchild.has_method("start_wave"):
					_spawner_nodes.append(subchild)
					# Forward score signal to main
					subchild.enemy_scored.connect(_on_enemy_scored)

func _build_default_waves():
	for spawner in _spawner_nodes:
		waves_config.append({
			"spawner_node": spawner,
			"fallback_timeout": 25.0
		})

func start():
	_game_running = true
	_current_wave_index = -1
	_advance_wave()

func _advance_wave():
	if not _game_running:
		return

	_current_wave_index += 1

	if _current_wave_index >= waves_config.size():
		all_waves_finished.emit()
		_current_wave_index = -1
		await get_tree().create_timer(3.0).timeout
		_advance_wave()
		return

	var config: Dictionary = waves_config[_current_wave_index]

	# Resolve spawner
	if config.has("spawner_node"):
		_current_spawner = config["spawner_node"]
	elif config.has("spawner"):
		_current_spawner = get_node(config["spawner"])
	else:
		push_error("SpawnManager: wave config has no spawner reference.")
		_advance_wave()
		return

	# Apply overrides
	if config.has("enemy_count"):
		_current_spawner.enemy_count = config["enemy_count"]
	if config.has("spawn_interval"):
		_current_spawner.spawn_interval = config["spawn_interval"]
	if config.has("move_speed"):
		_current_spawner.path_travel_speed = config["move_speed"]

	# One-shot connection for wave completion
	if _current_spawner.wave_finished.is_connected(_on_wave_finished):
		_current_spawner.wave_finished.disconnect(_on_wave_finished)
	_current_spawner.wave_finished.connect(_on_wave_finished, CONNECT_ONE_SHOT)

	var timeout: float = config.get("fallback_timeout", 25.0)
	_start_fallback_timer(timeout)
	_current_spawner.start_wave()

func _start_fallback_timer(timeout: float):
	if _fallback_timer and is_instance_valid(_fallback_timer):
		_fallback_timer.stop()
		_fallback_timer.queue_free()

	_fallback_timer = Timer.new()
	_fallback_timer.wait_time = timeout
	_fallback_timer.one_shot = true
	_fallback_timer.timeout.connect(_on_fallback_timeout)
	add_child(_fallback_timer)
	_fallback_timer.start()

func _on_wave_finished():
	if _fallback_timer and is_instance_valid(_fallback_timer):
		_fallback_timer.stop()
	await get_tree().create_timer(2.0).timeout
	_advance_wave()

func _on_fallback_timeout():
	if _current_spawner and _current_spawner.wave_finished.is_connected(_on_wave_finished):
		_current_spawner.wave_finished.disconnect(_on_wave_finished)
	_advance_wave()

func _on_enemy_scored(points: int):
	enemy_killed.emit(points)

func stop():
	_game_running = false
	if _fallback_timer and is_instance_valid(_fallback_timer):
		_fallback_timer.stop()
