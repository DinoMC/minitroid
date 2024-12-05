extends RigidBody2D

var dying = false


func _on_body_entered(body: Node) -> void:
	spit_die(body)

func spit_die(body) -> void:
	if dying: return
	dying = true
	if body.is_in_group("player"):
		body.try_damage_player()
	$CollisionShape2D.set_deferred("disabled", true)
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	$AnimatedSprite2D.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
