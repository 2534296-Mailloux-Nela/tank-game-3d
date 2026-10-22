extends Node3D

signal map_generated(start_position: Vector3, goal_position: Vector3)

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.UP,
]

@export_category("Labyrinthe")
@export_range(2, 20, 1) var grid_width := 6
@export_range(2, 20, 1) var grid_height := 6
@export_range(1.5, 8.0, 0.1) var cell_size := 3.0
@export_range(0.0, 0.8, 0.05) var extra_opening_chance := 0.2
@export var generation_seed := 0

@export_category("Murs")
@export var wall_scene: PackedScene
@export_range(0.1, 1.0, 0.05) var wall_thickness := 0.25
@export_range(0.5, 4.0, 0.1) var wall_height := 1.0

@export_category("Points")
@export var player_path: NodePath
@export var goal_path: NodePath

@onready var generated_walls: Node3D = $GeneratedWalls
@onready var ground_mesh: MeshInstance3D = $StaticBody3D/MeshInstance3D
@onready var camera: Camera3D = $Camera3D

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	generate_map()


func generate_map() -> void:
	if wall_scene == null:
		push_error("La scène de mur du générateur de carte n'est pas configurée.")
		return

	_clear_generated_walls()
	_prepare_random_number_generator()

	var vertical_walls := _create_bool_grid(grid_width + 1, grid_height)
	var horizontal_walls := _create_bool_grid(grid_height + 1, grid_width)
	_carve_maze(vertical_walls, horizontal_walls)
	_add_extra_openings(vertical_walls, horizontal_walls)
	_resize_ground_and_camera()
	_build_walls(vertical_walls, horizontal_walls)
	_place_points()


func _prepare_random_number_generator() -> void:
	if generation_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = generation_seed


func _create_bool_grid(column_count: int, row_count: int) -> Array:
	var grid: Array = []
	for column_index in range(column_count):
		var column: Array[bool] = []
		column.resize(row_count)
		column.fill(true)
		grid.append(column)
	return grid


func _carve_maze(vertical_walls: Array, horizontal_walls: Array) -> void:
	var visited := _create_bool_grid(grid_width, grid_height)
	for column in visited:
		column.fill(false)

	var stack: Array[Vector2i] = [Vector2i.ZERO]
	visited[0][0] = true

	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var available_directions: Array[Vector2i] = []

		for direction in DIRECTIONS:
			var neighbour: Vector2i = current + direction
			if _is_inside_grid(neighbour) and not visited[neighbour.x][neighbour.y]:
				available_directions.append(direction)

		if available_directions.is_empty():
			stack.pop_back()
			continue

		var direction: Vector2i = available_directions[_rng.randi_range(0, available_directions.size() - 1)]
		_remove_wall_between(current, direction, vertical_walls, horizontal_walls)
		var neighbour: Vector2i = current + direction
		visited[neighbour.x][neighbour.y] = true
		stack.append(neighbour)


func _is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < grid_height


func _remove_wall_between(
	cell: Vector2i,
	direction: Vector2i,
	vertical_walls: Array,
	horizontal_walls: Array
) -> void:
	if direction == Vector2i.RIGHT:
		vertical_walls[cell.x + 1][cell.y] = false
	elif direction == Vector2i.LEFT:
		vertical_walls[cell.x][cell.y] = false
	elif direction == Vector2i.DOWN:
		horizontal_walls[cell.y + 1][cell.x] = false
	else:
		horizontal_walls[cell.y][cell.x] = false


func _add_extra_openings(vertical_walls: Array, horizontal_walls: Array) -> void:
	for x in range(1, grid_width):
		for y in range(grid_height):
			if vertical_walls[x][y] and _rng.randf() < extra_opening_chance:
				vertical_walls[x][y] = false

	for y in range(1, grid_height):
		for x in range(grid_width):
			if horizontal_walls[y][x] and _rng.randf() < extra_opening_chance:
				horizontal_walls[y][x] = false


func _build_walls(vertical_walls: Array, horizontal_walls: Array) -> void:
	var map_width := grid_width * cell_size
	var map_depth := grid_height * cell_size

	for y in range(grid_height + 1):
		var x := 0
		while x < grid_width:
			if not horizontal_walls[y][x]:
				x += 1
				continue

			var run_start := x
			while x < grid_width and horizontal_walls[y][x]:
				x += 1

			var run_length := (x - run_start) * cell_size
			var center_x := -map_width * 0.5 + run_start * cell_size + run_length * 0.5
			var center_z := -map_depth * 0.5 + y * cell_size
			_add_wall(Vector3(center_x, wall_height * 0.5, center_z), run_length, true)

	for x in range(grid_width + 1):
		var y := 0
		while y < grid_height:
			if not vertical_walls[x][y]:
				y += 1
				continue

			var run_start := y
			while y < grid_height and vertical_walls[x][y]:
				y += 1

			var run_length := (y - run_start) * cell_size
			var center_x := -map_width * 0.5 + x * cell_size
			var center_z := -map_depth * 0.5 + run_start * cell_size + run_length * 0.5
			_add_wall(Vector3(center_x, wall_height * 0.5, center_z), run_length, false)


func _resize_ground_and_camera() -> void:
	var map_width := grid_width * cell_size
	var map_depth := grid_height * cell_size
	var margin := cell_size
	var plane := ground_mesh.mesh as PlaneMesh
	if plane != null:
		plane.size = Vector2(map_width + margin, map_depth + margin)

	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_aspect := 1.0
	if viewport_size.y > 0.0:
		viewport_aspect = viewport_size.x / viewport_size.y
	camera.size = maxf(map_depth + margin, (map_width + margin) / viewport_aspect)


func _add_wall(wall_position: Vector3, length: float, is_horizontal: bool) -> void:
	var wall := wall_scene.instantiate() as Node3D
	generated_walls.add_child(wall)
	wall.position = wall_position
	wall.scale = Vector3(wall_thickness, wall_height, length + wall_thickness)
	if is_horizontal:
		wall.rotation.y = PI * 0.5


func _place_points() -> void:
	var start_position := _cell_to_position(Vector2i.ZERO)
	var goal_position := _cell_to_position(Vector2i(grid_width - 1, grid_height - 1))

	var player := get_node_or_null(player_path) as Node3D
	if player != null:
		player.position = start_position

	var goal := get_node_or_null(goal_path) as Node3D
	if goal != null:
		goal.position = goal_position + Vector3.UP * 0.03

	map_generated.emit(start_position, goal_position)


func _cell_to_position(cell: Vector2i) -> Vector3:
	return Vector3(
		-grid_width * cell_size * 0.5 + (cell.x + 0.5) * cell_size,
		0.0,
		-grid_height * cell_size * 0.5 + (cell.y + 0.5) * cell_size
	)


func _clear_generated_walls() -> void:
	for wall in generated_walls.get_children():
		generated_walls.remove_child(wall)
		wall.queue_free()
