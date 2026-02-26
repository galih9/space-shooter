extends Node2D

## Spawns enemies one by one, each following the parent Path2D via PathFollow2D.
## Attach this as a child of a Path2D node.

signal wave_finished
signal enemy_scored(points)

@export var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")
@export var enemy_count: int = 5
@export var spawn_interval: float = 0.8   # seconds between each enemy spawn
@export var path_travel_speed: float = 150.0  # pixels/sec along the path
@export var shoot_stagger: float = 0.1    # extra delay between each enemy's first shot

# Internal
var _enemies_spawned: int = 0
var _enemies_alive: int = 0
var _path: Path2D
var _spawn_timer: Timer
var _active: bool = false

func _ready():
	_path = get_parent()
	assert(_path is Path2D, "EnemySpawner must be a child of a Path2D node.")

## Called by SpawnManager to begin this wave.
func start_wave():
	_enemies_spawned = 0
	_enemies_alive = 0
	_active = true

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_spawn_next_enemy)
	add_child(_spawn_timer)
	_spawn_timer.start()

func _spawn_next_enemy():
	if _enemies_spawned >= enemy_count:
		_spawn_timer.stop()
		_spawn_timer.queue_free()
		return

	# Create a PathFollow2D that will slide along the path
	var follower: PathFollow2D = PathFollow2D.new()
	follower.progress = 0.0
	follower.loop = false
	follower.rotates = false  # Keep enemy sprite upright
	_path.add_child(follower)

	# Instantiate the enemy and place it under the follower
	var enemy = enemy_scene.instantiate()
	enemy._following_path = true   # Disable self-drift
	follower.add_child(enemy)
	enemy.position = Vector2.ZERO  # Local to follower

	# Connect signals
	_enemies_alive += 1
	enemy.enemy_died.connect(_on_enemy_died)

	# Animate the follower along the path each frame
	var path_length: float = _path.curve.get_baked_length()
	_animate_follower(follower, path_length)

	# Start shooting with a stagger based on spawn order
	enemy.start_shooting(_enemies_spawned * shoot_stagger)

	_enemies_spawned += 1

func _animate_follower(follower: PathFollow2D, path_length: float):
	# We drive movement in a lightweight coroutine using idle frames
	# so it works independently for each enemy.
	_run_follower(follower, path_length)

func _run_follower(follower: PathFollow2D, path_length: float):
	while is_instance_valid(follower):
		var delta: float = get_process_delta_time()
		follower.progress += path_travel_speed * delta

		# Reached end of path — free the follower (which frees the child enemy)
		if follower.progress >= path_length:
			if is_instance_valid(follower):
				# The enemy finished the path without being killed — just remove it silently.
				# Disconnect enemy_died so _enemies_alive doesn't undercount.
				var enemy = _get_enemy_child(follower)
				if is_instance_valid(enemy) and enemy.enemy_died.is_connected(_on_enemy_died):
					enemy.enemy_died.disconnect(_on_enemy_died)
					_enemies_alive -= 1
					# Check wave completion since this enemy left silently
					_check_wave_done()
				follower.queue_free()
			return

		await get_tree().process_frame

func _get_enemy_child(follower: PathFollow2D) -> Node:
	for child in follower.get_children():
		if child is CharacterBody2D:
			return child
	return null

func _on_enemy_died(score_value: int):
	_enemies_alive -= 1
	enemy_scored.emit(score_value)
	_check_wave_done()

func _check_wave_done():
	if _active and _enemies_spawned >= enemy_count and _enemies_alive <= 0:
		_active = false
		wave_finished.emit()
