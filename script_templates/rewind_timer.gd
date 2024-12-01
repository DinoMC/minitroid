extends HBoxContainer


func _physics_process(delta: float) -> void:
	var time_left = $RewindTimer.time_left
	var seconds = fmod(time_left, 60.0)
	var minutes = time_left / 60
	$Minutes.text = "%02d" % minutes
	$Seconds.text = "%02d" % seconds
