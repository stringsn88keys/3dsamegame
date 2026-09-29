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

# Timer: starts on the first clear, stops at game over
var elapsed: float = 0.0
var timer_running: bool = false
var shown_seconds: int = -1
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
var time_label: Label
var game_over_panel: Panel

func _process(delta):
	# Keep timing through clear/gravity animations too
	if timer_running:
		elapsed += delta
		update_time_label()

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
	timer_running = true

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
	timer_running = false
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

		var final_time_label = game_over_panel.get_node_or_null("VBoxContainer/TimeLabel")
		if final_time_label:
			final_time_label.text = "Time: %s" % format_time(elapsed)

func restart_game():
	score = 0
	moves = 0
	elapsed = 0.0
	timer_running = false
	is_processing = false
	hovered_group.clear()
	current_hovered_cube = Vector3i(-1, -1, -1)

	if score_label:
		score_label.text = "Score: 0"
	if moves_label:
		moves_label.text = "Moves: 0"
	update_time_label()
	if preview_label:
		preview_label.visible = false
	if game_over_panel:
		game_over_panel.visible = false

	grid.initialize_grid()
	update_cubes_count()

# Redraws the timer only when the displayed second changes
func update_time_label():
	var seconds = int(elapsed)
	if not time_label or seconds == shown_seconds:
		return
	shown_seconds = seconds
	time_label.text = "Time: %s" % format_time(elapsed)

func format_time(t: float) -> String:
	var total = int(t)
	var h = total / 3600
	var m = (total % 3600) / 60
	var s = total % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%d:%02d" % [m, s]

func update_cubes_count():
	if grid and cubes_label:
		var count = grid.count_remaining_cubes()
		cubes_label.text = "Cubes: %d" % count
