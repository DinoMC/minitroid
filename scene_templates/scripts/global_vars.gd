extends Node

var playerid = ""
var externalPlayerId = ""
var accountConnected := false
var first_launch = true

var abilities_to_append = []

func _ready() -> void:
	get_tree().connect("node_added", _on_node_added)
	process_mode = PROCESS_MODE_ALWAYS
	
func _on_node_added(window) -> void:
	if window is AcceptDialog || window is ConfirmationDialog || window is PopupMenu:
		window.visibility_changed.connect(func():
			RenderingServer.viewport_set_global_canvas_transform(window.get_viewport_rid(), window.global_canvas_transform * window.get_screen_transform().get_scale().x);
			RenderingServer.viewport_set_size(window.get_viewport_rid(), window.size.x * window.get_screen_transform().get_scale().x, window.size.y * window.get_screen_transform().get_scale().y);
			pass
		)
