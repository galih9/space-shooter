extends CharacterBody2D

signal health_changed(current_hp)
signal player_died

@export var speed: float = 400.0
@export var max_hp: int = 10
@onready var current_hp: int = max_hp

# Preload the laser scene
const LASER_SCENE = preload("res://Scenes/laser.tscn")

func _ready():
	add_to_group("player")

func _physics_process(_delta):
	# Movement Logic
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()

	# Shooting Logic
	if Input.is_action_just_pressed("click_left"): # Requires mapping 'click_left' or detecting mouse index
		shoot()
	# Fallback if custom action isn't mapped:
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_action_pressed("ui_accept"): # naive check
		pass # Input.is_mouse_button_pressed is a check, not "just pressed".
		# Better to handle "just pressed" in _input for mouse if action not defined
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()

func shoot():
	var laser = LASER_SCENE.instantiate()
	# Setup laser
	laser.global_position = global_position + Vector2(0, -40) # Spawn slightly ahead/above
	laser.direction = Vector2.UP
	laser.shooter_tag = "player"
	laser.speed = 800.0
	
	# Add to main scene (root) so it doesn't move with player
	get_tree().root.add_child(laser)

func take_damage(amount: int):
	current_hp -= amount
	health_changed.emit(current_hp)
	if current_hp <= 0:
		die()

func die():
	player_died.emit()
	queue_free()
