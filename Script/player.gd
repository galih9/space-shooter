extends CharacterBody2D

signal health_changed(current_hp)
signal player_died

@export var speed: float = 400.0
@export var max_hp: int = 10
@onready var current_hp: int = max_hp

# Preload the laser scene
const LASER_SCENE = preload("res://Scenes/laser.tscn")

@onready var damage_sprite: AnimatedSprite2D = $Damage
@onready var body_sprite: Sprite2D = $Body

func _ready():
	add_to_group("player")
	# Damage overlay is hidden at full HP
	damage_sprite.visible = false
	damage_sprite.stop()

func _physics_process(_delta):
	# Movement Logic
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()

	# Shooting Logic
	if Input.is_action_just_pressed("click_left"):
		shoot()

func shoot():
	var laser = LASER_SCENE.instantiate()
	laser.global_position = global_position + Vector2(0, -40)
	laser.direction = Vector2.UP
	laser.shooter_tag = "player"
	get_tree().root.add_child(laser)

func take_damage(amount: int):
	current_hp -= amount
	current_hp = max(current_hp, 0)
	health_changed.emit(current_hp)
	_update_damage_visual()
	if current_hp <= 0:
		die()

func _update_damage_visual():
	var hp_ratio: float = float(current_hp) / float(max_hp)
	
	if current_hp >= max_hp:
		# Full health — no overlay
		damage_sprite.visible = false
		damage_sprite.stop()
	elif hp_ratio > 0.6:
		# > 60% HP (7–9): low damage
		damage_sprite.visible = true
		damage_sprite.play("low_damage")
	elif hp_ratio > 0.3:
		# 31–60% HP (4–6): medium damage
		damage_sprite.visible = true
		damage_sprite.play("med_damage")
	else:
		# ≤ 30% HP (1–3): high damage
		damage_sprite.visible = true
		damage_sprite.play("high_damage")

func die():
	player_died.emit()
	queue_free()
