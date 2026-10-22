extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 3.5

@export var rocket_scene: PackedScene
@export var tank_material: Material

@onready var muzzle: Marker3D = $Marker3D


func _ready() -> void:
	_apply_material($Model3D, tank_material)


func _apply_material(node: Node, material: Material) -> void:
	if material == null:
		return

	if node is MeshInstance3D:
		node.material_override = material

	for child in node.get_children():
		_apply_material(child, material)


func shoot() -> void:
	var projectile_container := get_tree().get_first_node_in_group("projectile_container")
	if projectile_container == null:
		push_error("Aucun conteneur de projectiles n'est présent dans la scène.")
		return

	var rocket = rocket_scene.instantiate()
	projectile_container.add_child(rocket)
	rocket.global_transform = muzzle.global_transform
	rocket.set_projectile_material(tank_material)
	# Direction exacte du canon
	rocket.direction = muzzle.global_basis.z.normalized()
	rocket.set_owner_tank(self)
	
func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Inputs
	var move_input := Input.get_axis("ui_down", "ui_up")
	var rotation_input := Input.get_axis("ui_right", "ui_left")
	if Input.is_action_just_pressed("shoot"):
		shoot()

	# Rotation gauche / droite
	rotate_y(rotation_input * ROTATION_SPEED * delta)

	# Direction avant du tank
	var direction := -transform.basis.z

	# Avancer / reculer
	velocity.x = direction.x * move_input * SPEED
	velocity.z = direction.z * move_input * SPEED

	move_and_slide()
	var is_driving: bool = Vector2(velocity.x, velocity.z).length() > 0.1
	var is_turning: bool = absf(rotation_input) > 0.1
	var is_moving: bool = is_driving or is_turning
	$ParticLeft.emitting = is_moving
	$ParticRight.emitting = is_moving
