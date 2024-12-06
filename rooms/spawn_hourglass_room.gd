extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.get_singleton().timer_started.connect(update_hourglass, CONNECT_DEFERRED)
	update_hourglass()
	
func update_hourglass() -> void:
	var timer = Game.get_singleton().rewind_timer
	if timer.time_left > 240:
		$Hourglass_AnimatedSprite2D.stop()
		$Hourglass_AnimatedSprite2D.animation = "die"
		$Hourglass_AnimatedSprite2D.frame = 5
	elif timer.time_left > 40:
		$Hourglass_AnimatedSprite2D.play("high")
	elif timer.time_left > 20:
		$Hourglass_AnimatedSprite2D.play("mid")
	else:
		$Hourglass_AnimatedSprite2D.play("low")
