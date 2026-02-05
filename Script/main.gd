extends Node2D

@onready var player = %Player
@onready var parallax = %Parallax2D

# UI Nodes
@onready var ui_canvas = $UI
@onready var start_screen = $UI/StartScreen
@onready var start_button = $UI/StartScreen/StartButton
@onready var h_box_container = $UI/StartScreen/HBoxContainer
@onready var hud = $UI/HUD
@onready var pause_screen = $UI/PauseScreen
@onready var game_over_screen = $UI/GameOverScreen
@onready var restart_button = $UI/GameOverScreen/RestartButton
@onready var score_label = $UI/HUD/ScoreLabel
@onready var hp_label = $UI/HUD/HPLabel

var score: int = 0
var game_running: bool = false
var is_paused: bool = false

func _ready():
	# Allow Main script and UI to process even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect UI Buttons
	start_button.pressed.connect(_on_start_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	# Initial State
	game_running = false
	get_tree().paused = true
	start_screen.visible = true
	hud.visible = false
	pause_screen.visible = false
	game_over_screen.visible = false
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.enemy_died.connect(_on_enemy_died)

func _process(delta):
	if game_running and not is_paused:
		# Scroll the parallax background
		# "scroll goes vertical to make illusion of plane is moving" -> Plane moves UP contextually, so background moves DOWN.
		# `scroll_offset` += Vector2(0, speed * delta)
		parallax.scroll_offset.y += 100 * delta
		
	if Input.is_action_just_pressed("ui_cancel"): # Escape key usually
		toggle_pause()

func start_game():
	game_running = true
	is_paused = false
	get_tree().paused = false
	
	score = 0
	update_score_ui()
	
	start_screen.visible = false
	game_over_screen.visible = false
	hud.visible = true
	
	# Reset player if needed (reload scene often easier for full reset, but here we just start)
	# If this is restart, we might reload.

func toggle_pause():
	if not game_running: return
	
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_screen.visible = is_paused

func game_over():
	game_running = false
	get_tree().paused = true
	game_over_screen.visible = true
	hud.visible = false

func _on_player_health_changed(hp):
	hp_label.text = "HP: " + str(hp)

func _on_player_died():
	game_over()

func _on_enemy_died(points):
	score += points
	update_score_ui()

func update_score_ui():
	score_label.text = "Score: " + str(score)

# Button Signals (Connect these in Scene editor or via code if nodes have unique names)
func _on_start_button_pressed():
	start_game()
	
func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()
