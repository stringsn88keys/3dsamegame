extends Node3D

@onready var grid = $Grid3D
@onready var camera_controller = $CameraController
@onready var game_manager = GameManager.new()

# UI elements
@onready var score_label = $UI/ScoreLabel
@onready var moves_label = $UI/MovesLabel
@onready var time_label = $UI/TimeLabel
@onready var cubes_label = $UI/CubesLabel
@onready var preview_label = $UI/PreviewLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var restart_button = $UI/GameOverPanel/VBoxContainer/RestartButton

func _ready():
	# Set up game manager
	add_child(game_manager)

	# Connect references
	game_manager.grid = grid
	game_manager.camera_controller = camera_controller
	game_manager.score_label = score_label
	game_manager.moves_label = moves_label
	game_manager.time_label = time_label
	game_manager.cubes_label = cubes_label
	game_manager.preview_label = preview_label
	game_manager.game_over_panel = game_over_panel

	# Connect grid signals (must be done after grid is set)
	grid.cubes_cleared.connect(game_manager._on_cubes_cleared)
	grid.gravity_settled.connect(game_manager._on_gravity_settled)
	grid.game_over.connect(game_manager._on_game_over)

	# Connect restart button
	restart_button.pressed.connect(game_manager.restart_game)

	# Hide game over panel initially
	game_over_panel.visible = false
	preview_label.visible = false

	# Initialize cubes count display
	game_manager.update_cubes_count()
