extends Node3D
class_name Grid3D

# Grid constants
const GRID_SIZE = 12
const CENTER = 5.5
const CUBE_SPACING = 1.1

# Color palette
const COLORS = [
	Color(1.0, 0.2, 0.2),  # Red
	Color(0.2, 0.5, 1.0),  # Blue
	Color(0.3, 1.0, 0.3),  # Green
	Color(1.0, 0.9, 0.2),  # Yellow
	Color(0.9, 0.3, 1.0),  # Purple
]

# Grid data: 3D array of color indices (-1 = empty)
var grid: Array = []
var cube_meshes: Array = []  # 3D array of MeshInstance3D nodes

# Cube mesh resources
var cube_mesh: BoxMesh
var cube_material_base: StandardMaterial3D

signal cubes_cleared(count: int, score: int)
signal gravity_settled()
signal game_over()

func _ready():
	# Create cube mesh
	cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3.ONE * 0.9

	# Create base material
	cube_material_base = StandardMaterial3D.new()
	cube_material_base.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL

	initialize_grid()

func initialize_grid():
	# Initialize 3D arrays
	grid.clear()
	cube_meshes.clear()

	# Clear existing cube nodes
	for child in get_children():
		child.queue_free()

	for x in range(GRID_SIZE):
		grid.append([])
		cube_meshes.append([])
		for y in range(GRID_SIZE):
			grid[x].append([])
			cube_meshes[x].append([])
			for z in range(GRID_SIZE):
				# Random color index
				var color_idx = randi() % COLORS.size()
				grid[x][y].append(color_idx)

				# Create a StaticBody3D for collision detection
				var cube_body = StaticBody3D.new()

				# Create cube mesh instance
				var cube_instance = MeshInstance3D.new()
				cube_instance.mesh = cube_mesh

				# Create material with color
				var material = cube_material_base.duplicate()
				material.albedo_color = COLORS[color_idx]
				cube_instance.material_override = material

				# Add mesh as child of body
				cube_body.add_child(cube_instance)

				# Create collision shape (slightly larger than visual for easier clicking)
				var collision_shape = CollisionShape3D.new()
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3.ONE * 1.0
				collision_shape.shape = box_shape
				cube_body.add_child(collision_shape)

				# Position the cube (centered around origin)
				var pos = grid_to_world(Vector3i(x, y, z))
				cube_body.position = pos

				# Store grid position in metadata for raycasting
				cube_body.set_meta("grid_pos", Vector3i(x, y, z))

				add_child(cube_body)
				cube_meshes[x][y].append(cube_body)

func grid_to_world(grid_pos: Vector3i) -> Vector3:
	# Convert grid coordinates to world position (centered at origin)
	return Vector3(
		(grid_pos.x - CENTER) * CUBE_SPACING,
		(grid_pos.y - CENTER) * CUBE_SPACING,
		(grid_pos.z - CENTER) * CUBE_SPACING
	)

func world_to_grid(world_pos: Vector3) -> Vector3i:
	# Convert world position to grid coordinates
	return Vector3i(
		int(round(world_pos.x / CUBE_SPACING + CENTER)),
		int(round(world_pos.y / CUBE_SPACING + CENTER)),
		int(round(world_pos.z / CUBE_SPACING + CENTER))
	)

func is_valid_pos(pos: Vector3i) -> bool:
	return (pos.x >= 0 and pos.x < GRID_SIZE and
			pos.y >= 0 and pos.y < GRID_SIZE and
			pos.z >= 0 and pos.z < GRID_SIZE)

func get_color_at(pos: Vector3i) -> int:
	if not is_valid_pos(pos):
		return -1
	return grid[pos.x][pos.y][pos.z]

func get_adjacent_positions(pos: Vector3i) -> Array[Vector3i]:
	# Return all 6 face-adjacent positions
	var adjacent: Array[Vector3i] = []
	var offsets = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]

	for offset in offsets:
		var new_pos = pos + offset
		if is_valid_pos(new_pos):
			adjacent.append(new_pos)

	return adjacent

func find_connected_group(start_pos: Vector3i) -> Array[Vector3i]:
	# Flood fill to find all connected cubes of same color
	var color = get_color_at(start_pos)
	if color == -1:  # Empty position
		return []

	var group: Array[Vector3i] = []
	var visited = {}
	var to_check = [start_pos]

	while to_check.size() > 0:
		var pos = to_check.pop_back()
		var key = "%d,%d,%d" % [pos.x, pos.y, pos.z]

		if key in visited:
			continue

		visited[key] = true

		if get_color_at(pos) == color:
			group.append(pos)

			# Add adjacent positions to check
			for adj_pos in get_adjacent_positions(pos):
				var adj_key = "%d,%d,%d" % [adj_pos.x, adj_pos.y, adj_pos.z]
				if adj_key not in visited:
					to_check.append(adj_pos)

	return group

func clear_group(group: Array[Vector3i]) -> void:
	# Remove cubes from grid and scene
	for pos in group:
		grid[pos.x][pos.y][pos.z] = -1

		if cube_meshes[pos.x][pos.y][pos.z]:
			# Animate and remove
			var cube = cube_meshes[pos.x][pos.y][pos.z]
			animate_clear(cube)
			cube_meshes[pos.x][pos.y][pos.z] = null

	# Calculate score: (n-2)² - 5n
	# This penalizes small clears and rewards large ones
	var n = group.size()
	var score = (n - 2) ** 2 - 5 * n
	cubes_cleared.emit(n, score)

	# Wait a bit for animation, then apply gravity
	await get_tree().create_timer(0.3).timeout
	await apply_gravity()

func animate_clear(cube_body: StaticBody3D) -> void:
	# Simple scale-down animation
	var tween = create_tween()
	tween.tween_property(cube_body, "scale", Vector3.ZERO, 0.25)
	tween.tween_callback(cube_body.queue_free)

func apply_gravity() -> void:
	# Apply center-directed gravity
	# Process multiple times until stable
	var max_iterations = 50
	var iteration = 0
	var moved = true

	while moved and iteration < max_iterations:
		moved = false
		iteration += 1

		# Process each axis independently
		for axis in range(3):  # 0=x, 1=y, 2=z
			if apply_gravity_axis(axis):
				moved = true

	# Update all cube positions
	update_cube_positions()

	# Wait for animations to complete (0.4s animation + small buffer)
	await get_tree().create_timer(0.5).timeout

	# Check for game over
	if not has_valid_moves():
		game_over.emit()
	else:
		gravity_settled.emit()

func apply_gravity_axis(axis: int) -> bool:
	# Apply gravity toward center for one axis
	var moved = false

	# For each column perpendicular to this axis
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			# Process from center outward in both directions
			for direction in [-1, 1]:
				moved = process_column(axis, i, j, direction) or moved

	return moved

func process_column(axis: int, i: int, j: int, direction: int) -> bool:
	# Process one column along an axis
	var moved = false
	var start_idx = 6 if direction > 0 else 5  # Start from center
	var end_idx = GRID_SIZE if direction > 0 else -1

	for k in range(start_idx, end_idx, direction):
		var pos = get_pos_from_axis(axis, i, j, k)

		if get_color_at(pos) != -1:
			# Try to move toward center
			var new_k = k
			while true:
				var next_k = new_k - direction
				if next_k < 0 or next_k >= GRID_SIZE:
					break

				var next_pos = get_pos_from_axis(axis, i, j, next_k)
				if get_color_at(next_pos) != -1:
					break  # Blocked by another cube

				# Check if moving toward center
				if not is_moving_toward_center(next_k, k, axis):
					break

				new_k = next_k

			# Move if position changed
			if new_k != k:
				var old_pos = get_pos_from_axis(axis, i, j, k)
				var new_pos = get_pos_from_axis(axis, i, j, new_k)

				grid[new_pos.x][new_pos.y][new_pos.z] = grid[old_pos.x][old_pos.y][old_pos.z]
				grid[old_pos.x][old_pos.y][old_pos.z] = -1

				cube_meshes[new_pos.x][new_pos.y][new_pos.z] = cube_meshes[old_pos.x][old_pos.y][old_pos.z]
				cube_meshes[old_pos.x][old_pos.y][old_pos.z] = null

				# Update metadata with new grid position
				if cube_meshes[new_pos.x][new_pos.y][new_pos.z]:
					cube_meshes[new_pos.x][new_pos.y][new_pos.z].set_meta("grid_pos", new_pos)

				moved = true

	return moved

func get_pos_from_axis(axis: int, i: int, j: int, k: int) -> Vector3i:
	# Convert axis-oriented coordinates to Vector3i
	if axis == 0:  # X axis
		return Vector3i(k, i, j)
	elif axis == 1:  # Y axis
		return Vector3i(i, k, j)
	else:  # Z axis
		return Vector3i(i, j, k)

func is_moving_toward_center(new_idx: int, old_idx: int, axis: int) -> bool:
	# Check if movement is toward center (5.5)
	var center_idx = 5.5
	return abs(new_idx - center_idx) < abs(old_idx - center_idx)

func update_cube_positions() -> void:
	# Animate all cubes to their correct positions
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var cube = cube_meshes[x][y][z]
				if cube:
					var target_pos = grid_to_world(Vector3i(x, y, z))
					var tween = create_tween()
					tween.tween_property(cube, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

func has_valid_moves() -> bool:
	# Check if any groups of 2+ exist
	var checked = {}

	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var pos = Vector3i(x, y, z)
				var key = "%d,%d,%d" % [x, y, z]

				if key in checked:
					continue

				if get_color_at(pos) == -1:
					continue

				var group = find_connected_group(pos)
				if group.size() >= 2:
					return true

				# Mark all in group as checked
				for p in group:
					checked["%d,%d,%d" % [p.x, p.y, p.z]] = true

	return false

func highlight_group(group: Array[Vector3i], enabled: bool) -> void:
	# Highlight or unhighlight a group of cubes
	for pos in group:
		var cube_body = cube_meshes[pos.x][pos.y][pos.z]
		if cube_body:
			# Get the MeshInstance3D child
			var mesh_instance = cube_body.get_child(0) as MeshInstance3D
			if mesh_instance:
				var material = mesh_instance.material_override as StandardMaterial3D
				if enabled:
					material.emission_enabled = true
					material.emission = material.albedo_color * 0.5
				else:
					material.emission_enabled = false

func count_remaining_cubes() -> int:
	# Count all non-empty cubes in the grid
	var count = 0
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				if grid[x][y][z] != -1:
					count += 1
	return count
