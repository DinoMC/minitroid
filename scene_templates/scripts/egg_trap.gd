extends Sprite2D

@export var egg_content : Node2D
var triggered = false

func _on_trap_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && !triggered:
		triggered = true
		$eggsplosionAnimatedSprite2D.play("die")
		egg_content.show()
		egg_content.process_mode = Node.PROCESS_MODE_INHERIT
		self.texture = null
		await get_tree().create_timer(1.0).timeout
		queue_free()
