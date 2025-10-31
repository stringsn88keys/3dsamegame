extends Node3D
class_name GameManager

@onready var grid: Grid3D
@onready var camera_controller: CameraController
@onready var ui: Control

# Game state
var score: int = 0
var moves: int = 0
var is_processing: bool = false
var hovered_group: Array[Vector3i] = []
var current_hovered_cube: Vector3i = Vector3i(-1, -1, -1)

# Click detection
var mouse_down_pos: Vector2 = Vector2.ZERO
var was_dragging: bool = false
const DRAG_THRESHOLD: float = 5.0  # pixels

# UI references (will be set from Main scene)
var score_label: Label
var moves_label: Label
var cubes_label: Label
var preview_label: Label
var game_over_panel: Panel

func _process(_delta):
	if is_processing or not camera_controller:
		return

	# Don't process hover when dragging
	if was_dragging:
		clear_hover()
		return

	# Raycast from mouse to find hovered cube
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = camera_controller.get_camera()

	if not camera:
		return

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		# Get grid position from collider metadata
		var collider = result.collider
		if collider and collider.has_meta("grid_pos"):
			var grid_pos = collider.get_meta("grid_pos")
			if grid.get_color_at(grid_pos) != -1:
				update_hover(grid_pos)
			else:
				clear_hover()
		else:
			clear_hover()
	else:
		clear_hover()

func _input(event):
	if is_processing:
		return

	# Handle mouse button events
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Mouse down - record position
			mouse_down_pos = event.position
			was_dragging = false
		else:
			# Mouse up - check if it was a click (not a drag)
			if not was_dragging and hovered_group.size() >= 2:
				clear_current_group()
			# Reset drag state on mouse up
			was_dragging = false

	# Track if mouse moved significantly (dragging)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if mouse_down_pos.distance_to(event.position) > DRAG_THRESHOLD:
			was_dragging = true

func update_hover(grid_pos: Vector3i):
	# Check if we're hovering over a new cube
	if grid_pos == current_hovered_cube:
		return

	# Clear previous highlight
	if hovered_group.size() > 0:
		grid.highlight_group(hovered_group, false)

	current_hovered_cube = grid_pos
	hovered_group = grid.find_connected_group(grid_pos)

	# Only highlight if group is 2 or more
	if hovered_group.size() >= 2:
		grid.highlight_group(hovered_group, true)

		# Update preview label with new scoring formula: (n-2)² - 5n
		var n = hovered_group.size()
		var potential_score = (n - 2) ** 2 - 5 * n
		if preview_label:
			var sign = "+" if potential_score >= 0 else ""
			preview_label.text = "Cubes: %d | Points: %s%d" % [n, sign, potential_score]
			preview_label.visible = true
	else:
		hovered_group.clear()
		if preview_label:
			preview_label.visible = false

func clear_hover():
	if hovered_group.size() > 0:
		grid.highlight_group(hovered_group, false)
		hovered_group.clear()

	current_hovered_cube = Vector3i(-1, -1, -1)

	if preview_label:
		preview_label.visible = false

func clear_current_group():
	if hovered_group.size() < 2:
		return

	is_processing = true
	moves += 1

	if moves_label:
		moves_label.text = "Moves: %d" % moves

	# Clear the group
	grid.clear_group(hovered_group)
	hovered_group.clear()
	current_hovered_cube = Vector3i(-1, -1, -1)

	if preview_label:
		preview_label.visible = false

func _on_cubes_cleared(count: int, points: int):
	score += points

	if score_label:
		score_label.text = "Score: %d" % score

	print("Cleared %d cubes for %d points. Total score: %d" % [count, points, score])

func _on_gravity_settled():
	is_processing = false
	update_cubes_count()

func _on_game_over():
	is_processing = true
	print("Game Over! Final score: %d in %d moves" % [score, moves])

	if game_over_panel:
		game_over_panel.visible = true

		# Update game over text
		var final_score_label = game_over_panel.get_node_or_null("VBoxContainer/ScoreLabel")
		if final_score_label:
			final_score_label.text = "Final Score: %d" % score

		var final_moves_label = game_over_panel.get_node_or_null("VBoxContainer/MovesLabel")
		if final_moves_label:
			final_moves_label.text = "Moves: %d" % moves

func restart_game():
	score = 0
	moves = 0
	is_processing = false
	hovered_group.clear()
	current_hovered_cube = Vector3i(-1, -1, -1)

	if score_label:
		score_label.text = "Score: 0"
	if moves_label:
		moves_label.text = "Moves: 0"
	if preview_label:
		preview_label.visible = false
	if game_over_panel:
		game_over_panel.visible = false

	grid.initialize_grid()
	update_cubes_count()

func update_cubes_count():
	if grid and cubes_label:
		var count = grid.count_remaining_cubes()
		cubes_label.text = "Cubes: %d" % count
