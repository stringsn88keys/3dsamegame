extends Node3D
class_name CameraController

@export var rotation_speed: float = 0.003
@export var zoom_speed: float = 1.0
@export var min_distance: float = 15.0
@export var max_distance: float = 35.0
@export var initial_distance: float = 25.0

var camera: Camera3D
var is_rotating: bool = false
var last_mouse_pos: Vector2
var current_distance: float

# Lights that follow camera
var main_light: DirectionalLight3D
var fill_light: DirectionalLight3D

# Quaternion-based rotation to avoid gimbal lock
var camera_rotation: Quaternion = Quaternion.IDENTITY

func _ready():
	# Create camera
	camera = Camera3D.new()
	add_child(camera)

	# Create main light (follows camera direction)
	main_light = DirectionalLight3D.new()
	main_light.light_energy = 1.0
	main_light.shadow_enabled = true
	camera.add_child(main_light)
	main_light.rotation_degrees = Vector3(-30, 0, 0)

	# Create fill light (opposite side for softer shadows)
	fill_light = DirectionalLight3D.new()
	fill_light.light_energy = 0.4
	camera.add_child(fill_light)
	fill_light.rotation_degrees = Vector3(150, 180, 0)

	current_distance = initial_distance

	# Set initial camera orientation (looking from angle)
	var initial_rot_y = Quaternion(Vector3.UP, deg_to_rad(45.0))
	var initial_rot_x = Quaternion(Vector3.RIGHT, deg_to_rad(-30.0))
	camera_rotation = initial_rot_y * initial_rot_x

	update_camera_position()

func _input(event):
	# Handle mouse rotation
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = event.pressed
			if is_rotating:
				last_mouse_pos = event.position

		# Handle zoom with mouse wheel
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_distance = max(min_distance, current_distance - zoom_speed)
			update_camera_position()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_distance = min(max_distance, current_distance + zoom_speed)
			update_camera_position()

	elif event is InputEventMouseMotion and is_rotating:
		var delta = event.position - last_mouse_pos
		last_mouse_pos = event.position

		# Trackball rotation using quaternions (no gimbal lock!)
		# Rotate around world Y axis (horizontal mouse movement)
		var rot_y = Quaternion(Vector3.UP, -delta.x * rotation_speed)

		# Rotate around camera's local right axis (vertical mouse movement)
		var camera_right = camera_rotation * Vector3.RIGHT
		var rot_x = Quaternion(camera_right, delta.y * rotation_speed)

		# Apply rotations
		camera_rotation = rot_y * rot_x * camera_rotation
		camera_rotation = camera_rotation.normalized()

		update_camera_position()

func update_camera_position():
	# Position camera at distance from origin using quaternion rotation
	# Start with camera at distance along Z axis (looking back at origin from +Z)
	var base_position = Vector3(0, 0, current_distance)

	# Apply rotation to get camera position
	var rotated_position = camera_rotation * base_position
	camera.position = rotated_position

	# Build camera transform to look at origin
	# Forward direction (camera -Z) should point to origin
	var forward = -rotated_position.normalized()

	# Get the "up" direction from the quaternion's Y axis
	var up = camera_rotation * Vector3.UP

	# Calculate right vector
	var right = up.cross(forward).normalized()

	# Recalculate up to ensure orthogonality
	up = forward.cross(right).normalized()

	# Build basis (Godot uses right, up, -forward for camera basis)
	camera.transform.basis = Basis(right, up, -forward)

func get_camera() -> Camera3D:
	return camera
