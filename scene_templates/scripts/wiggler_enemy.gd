extends CharacterBody2D


const SPEED := 75.0

var hp = 2
var dying = false


func _on_hurt_zone_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_hurt_zone = true


func _on_hurt_zone_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_hurt_zone = false

func damage(amount:int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	if dying: return
	dying = true
	$CollisionShape2D.set_deferred("disabled", true)
	$HurtZone_Area2D/CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.hide()
	$CollisionShape2D/AnimatedSprite2D.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
