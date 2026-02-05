extends CharacterBody2D

signal enemy_died(score_value)

@export var max_hp: int = 5
@onready var current_hp: int = max_hp
@export var shoot_interval: float = 0.5
@export var score_value: int = 100

const LASER_SCENE = preload("res://Scenes/laser.tscn")
var shoot_timer: Timer

func _ready():
	add_to_group("enemies")
	
	setup_shoot_timer()

func setup_shoot_timer():
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.autostart = true
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	shoot_timer.start()

func _on_shoot_timer_timeout():
	shoot()

func shoot():
	var laser = LASER_SCENE.instantiate()
	laser.global_position = global_position + Vector2(0, 40) # Spawn slightly below
	laser.direction = Vector2.DOWN
	laser.shooter_tag = "enemy"
	laser.speed = 400.0 # Enemy lasers might be slower
	
	get_tree().root.add_child(laser)

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	enemy_died.emit(score_value)
	queue_free()
