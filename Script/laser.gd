extends Area2D

@export var speed: float = 600.0
@export var damage: int = 1
@export var direction: Vector2 = Vector2.UP
@export var shooter_tag: String = "player" # "player" or "enemy"

func _ready():
	# Connect the area_entered signal to detect collisions
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after 5 seconds to prevent memory leaks if it misses everything
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# Ignore collision with the shooter itself based on groups or logic
	if body.is_in_group(shooter_tag):
		return
		
	if body.has_method("take_damage"):
		# Ensure we don't hit our own team (simple group check)
		# If shooter is player, target enemies.
		if shooter_tag == "player" and body.is_in_group("enemies"):
			body.take_damage(damage)
			queue_free()
		# If shooter is enemy, target player.
		elif shooter_tag == "enemy" and body.is_in_group("player"):
			body.take_damage(damage)
			queue_free()
	
	# Optional: Destroy on walls/borders?
	# For now, let's just let it fly off screen or hit borders if they have collision
	# The borders in Main.tscn are StaticBody2D.
	if body is StaticBody2D:
		queue_free()

func _on_area_entered(area):
	pass # Usually handle body collisions for CharacterBody2D
