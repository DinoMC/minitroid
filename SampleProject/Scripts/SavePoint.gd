# A save point object. Colliding with it saves the game.
extends Area2D

@onready var start_time := Time.get_ticks_msec()

func _ready() -> void:
	body_entered.connect(on_body_entered)

# Player enter save point. Note that in a legit code this should check whether body is really a player.
func on_body_entered(body: Node2D) -> void:
	if Time.get_ticks_msec() - start_time < 1000:
		return # Small hack to prevent saving at the game start.
	if body.is_in_group("player"):
		# Make Game save the data.
		Game.get_singleton().save_game()
		# Starting coords for the delta vector feature.
		Game.get_singleton().reset_map_starting_coords()
		# If carrying sand canisters, save them if at the hourglass.
		if get_parent().get_meta("is_hourglass_room", false):
			while body.tempabilities.size() > 0:
				var newability = body.tempabilities.pop_back()
				body.abilities.append(newability)
				if newability == "sandcanister_one":
					Game.get_singleton().item_popup("sandcanister_done_1")
				elif newability == "sandcanister_two":
					Game.get_singleton().item_popup("sandcanister_done_2")

func _draw() -> void:
	# Draws the circle.
	$CollisionShape2D.shape.draw(get_canvas_item(), Color.BLUE)
