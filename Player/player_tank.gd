extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 3.5

@export var rocket_scene: PackedScene

@onready var muzzle: Marker3D = $Marker3D
func shoot() -> void:
	var rocket = rocket_scene.instantiate()
	get_tree().current_scene.add_child(rocket)
	rocket.global_transform = muzzle.global_transform
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
	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.1
	$ParticLeft.emitting = is_moving
	$ParticRight.emitting = is_moving
