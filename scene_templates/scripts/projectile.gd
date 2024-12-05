extends CharacterBody2D


const SPEED = 200.0
var angle = -45
var direction = Vector2.RIGHT
var dying = false

func _ready() -> void:
	rotation_degrees = angle
	direction = Vector2.from_angle(deg_to_rad(angle))
	velocity = direction * SPEED
	
func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision != null:
		die()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("damage"):
		body.damage(1)
		die()

func die() -> void:
	if dying: return
	dying = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D/Area2D/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _on_expire_timer_timeout() -> void:
	if !dying:
		queue_free()
