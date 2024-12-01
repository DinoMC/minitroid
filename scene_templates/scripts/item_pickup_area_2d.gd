extends Area2D

@export var item_name: String

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player.abilities.has(item_name) || player.tempabilities.has(item_name):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if item_name.contains("sandcanister"):
			body.tempabilities.append(item_name)
		else:
			body.abilities.append(item_name)
		queue_free()
