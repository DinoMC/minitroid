extends Area2D

@export var damage_amount := 5
@export var heat := false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if heat && body.abilities.has("heatresist"):
			$CollisionShape2D.set_deferred("disabled", true)
		else:
			body.current_hurtzone_damage = damage_amount
			body.in_hurt_zone = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_hurt_zone = false
		body.current_hurtzone_damage = body.default_damage
