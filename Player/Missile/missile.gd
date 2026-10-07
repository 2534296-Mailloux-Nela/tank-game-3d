extends CharacterBody3D

@export var speed := 8.0
@export var max_bounces := 10
@export var lifetime := 8.0

var direction: Vector3 = Vector3.ZERO
var bounce_count := 0

var owner_tank: CollisionObject3D


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func set_owner_tank(tank: CollisionObject3D) -> void:
	owner_tank = tank
	
	# Ignore le tank au lancement
	add_collision_exception_with(tank)
	
	# Après 0.2 seconde, le missile peut toucher son propre tank
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(owner_tank):
		remove_collision_exception_with(owner_tank)


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

	look_at(global_position + direction, Vector3.UP)
