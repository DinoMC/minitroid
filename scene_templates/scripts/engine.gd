extends Node


func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.keycode == KEY_F2 && !event.echo && event.pressed:
		$CanvasLayer/ColorRect.set_deferred("visible", !$CanvasLayer/ColorRect.visible)
