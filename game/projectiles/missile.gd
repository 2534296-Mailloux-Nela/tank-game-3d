extends CharacterBody3D

@export var speed := 8.0
@export var max_bounces := 10
@export var lifetime := 8.0
@export var owner_collision_delay := 0.1

var direction: Vector3 = Vector3.ZERO
var bounce_count := 0

var owner_tank: CollisionObject3D
var projectile_material: Material


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func set_owner_tank(tank: CollisionObject3D) -> void:
	owner_tank = tank
	
	# Ignore le tank au lancement
	add_collision_exception_with(tank)
	
	# Le missile peut toucher son propre tank après le délai configuré.
	await get_tree().create_timer(owner_collision_delay).timeout
	
	if is_instance_valid(owner_tank):
		remove_collision_exception_with(owner_tank)


func set_projectile_material(material: Material) -> void:
	projectile_material = material
	_apply_material($Bullet, projectile_material)


func _apply_material(node: Node, material: Material) -> void:
	if material == null:
		return

	if node is MeshInstance3D:
		node.material_override = material

	for child in node.get_children():
		_apply_material(child, material)


func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * speed * delta)

	if collision:
		bounce_count += 1

		if bounce_count >= max_bounces:
			queue_free()
			return

		direction = direction.bounce(
			collision.get_normal()
		).normalized()

	if direction.is_zero_approx():
		return

	var up_axis := Vector3.UP
	if abs(direction.normalized().dot(Vector3.UP)) > 0.999:
		up_axis = Vector3.FORWARD

	look_at(global_position + direction, up_axis)
