extends CharacterBody2D

signal enemy_died(score_value)

@export var max_hp: int = 3
@onready var current_hp: int = max_hp
@export var score_value: int = 100
@export var move_speed: float = 120.0  # set by spawner via meta

const LASER_SCENE = preload("res://Scenes/laser.tscn")
@onready var shoot_timer: Timer = $Timer
var _following_path: bool = false  # Set to true by spawner when using PathFollow2D

@onready var body_sprite: Sprite2D = $Body

func _ready():
	add_to_group("enemies")
	
	# Apply speed set by EnemySpawner via metadata
	if has_meta("move_speed"):
		move_speed = get_meta("move_speed")
	# Timer is started externally by the spawner (with a stagger delay)
	# so we don't call shoot_timer.start() here anymore

func start_shooting(delay: float = 0.0):
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_instance_valid(self):
		shoot_timer.start()

func _physics_process(_delta):
	# Only apply drift if NOT following a path (PathFollow2D handles movement instead)
	if not _following_path:
		velocity = Vector2(0, move_speed)
		move_and_slide()
	
	# Auto-destroy when off screen (bottom)
	if global_position.y > 800:
		queue_free()

func shoot():
	var laser = LASER_SCENE.instantiate()
	laser.global_position = global_position + Vector2(0, 40)
	get_tree().root.add_child(laser)
	laser.speed = 1000
	laser.direction = Vector2.DOWN
	laser.shooter_tag = "enemy"

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0:
		die()
	else:
		# Flash white on hit
		_flash_hit()

func _flash_hit():
	# Quick color flash to indicate a hit
	body_sprite.modulate = Color(2.0, 0.4, 0.4)  # Bright red-ish
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		body_sprite.modulate = Color(1, 1, 1)

func die():
	enemy_died.emit(score_value)
	queue_free()


func _on_timer_timeout() -> void:
	shoot()
