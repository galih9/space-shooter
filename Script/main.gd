extends Node2D

@onready var player = %Player
@onready var parallax = %Parallax2D
@onready var spawn_manager = $SpawnManager

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

func _process(delta):
	if game_running and not is_paused:
		parallax.scroll_offset.y += 100 * delta
		
	if Input.is_action_just_pressed("ui_cancel"):
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
	
	# Start the enemy wave manager
	if spawn_manager:
		# Connect score signal (only once — guard against double-connect on restart)
		if not spawn_manager.enemy_killed.is_connected(_on_enemy_died):
			spawn_manager.enemy_killed.connect(_on_enemy_died)
		if not spawn_manager.all_waves_finished.is_connected(_on_all_waves_finished):
			spawn_manager.all_waves_finished.connect(_on_all_waves_finished)
		spawn_manager.start()

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
	
	if spawn_manager:
		spawn_manager.stop()

func _on_player_health_changed(hp):
	hp_label.text = "HP: " + str(hp)

func _on_player_died():
	game_over()

func _on_enemy_died(points):
	score += points
	update_score_ui()

func _on_all_waves_finished():
	# Could show a "Wave Clear!" message here
	pass

func update_score_ui():
	score_label.text = "Score: " + str(score)

func _on_start_button_pressed():
	start_game()
	
func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()
