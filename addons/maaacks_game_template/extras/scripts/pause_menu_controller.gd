class_name PauseMenuController
extends Node

## Node for opening a pause menu when detecting a 'ui_cancel' event.

@export var pause_menu_packed : PackedScene
@export var focused_viewport : Viewport
var test

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if not focused_viewport:
			focused_viewport = get_viewport()
		var _initial_focus_control = focused_viewport.gui_get_focus_owner()
		var current_menu = pause_menu_packed.instantiate()
		test = get_tree().current_scene.name
		if get_tree().current_scene.find_child("CanvasLayer") != null:
			get_tree().current_scene.find_child("CanvasLayer").call_deferred("add_child", current_menu)
		else:
			get_tree().current_scene.call_deferred("add_child", current_menu)
		await current_menu.tree_exited
		if _initial_focus_control:
			_initial_focus_control.grab_focus()
