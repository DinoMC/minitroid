extends AnimatedSprite2D


func spit() -> void:
	var spit = preload("res://scene_templates/vomit_body_2d.tscn").instantiate()
	add_child(spit)
