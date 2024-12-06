extends RigidBody2D


func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
