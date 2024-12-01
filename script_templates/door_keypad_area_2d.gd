extends StaticBody2D

func _ready() -> void:
	if MetSys.register_storable_object(self):
		return

func _on_door_keypad_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.abilities.has("doorcode"):
			open_door()
			
func open_door() -> void:
	$DoorKeypadArea2D/CollisionShape2D.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D.z_index = 2
	MetSys.store_object(self)
