extends Node

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("F2_action"):
		$CanvasLayer/ColorRect.set_deferred("visible", !$CanvasLayer/ColorRect.visible)

func _input(event: InputEvent) -> void:
	if event is InputEventKey && event.keycode == KEY_F2 && !event.echo && event.pressed:
		$CanvasLayer/ColorRect.set_deferred("visible", !$CanvasLayer/ColorRect.visible)
