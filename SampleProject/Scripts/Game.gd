# This is the main script of the game. It manages the current map and some other stuff.
extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"
class_name Game

const SaveManager = preload("res://addons/MetroidvaniaSystem/Template/Scripts/SaveManager.gd")
const SAVE_PATH = "user://save_data.sav"

# The game starts in this map. Note that it's scene name only, just like MetSys refers to rooms.
@export var starting_map: String

# Number of collected collectibles. Setting it also updates the counter.
var collectibles: int:
	set(count):
		collectibles = count
		%CollectibleCount.text = "%d/6" % count

# The coordinates of generated rooms. MetSys does not keep this list, so it needs to be done manually.
var generated_rooms: Array[Vector3i]
# The typical array of game events. It's supplementary to the storable objects.
var events: Array[String]
# For Custom Runner integration.
var custom_run: bool

var temporarily_saved_ids: Array[StringName]

@onready var rewind_timer : Timer = $UI/RewindTimer_HBoxContainer/RewindTimer
@onready var fdb_rect : ColorRect = $UI/FadeToBlackColorRect

func _ready() -> void:
	# A trick for static object reference (before static vars were a thing).
	get_script().set_meta(&"singleton", self)
	# Make sure MetSys is in initial state.
	# Does not matter in this project, but normally this ensures that the game works correctly when you exit to menu and start again.
	MetSys.reset_state()
	# Assign player for MetSysGame.
	set_player($Player)
	
	if FileAccess.file_exists(SAVE_PATH):
		# If save data exists, load it using MetSys SaveManager.
		var save_manager := SaveManager.new()
		save_manager.load_from_text(SAVE_PATH)
		# Assign loaded values.
		collectibles = save_manager.get_value("collectible_count")
		generated_rooms.assign(save_manager.get_value("generated_rooms"))
		events.assign(save_manager.get_value("events"))
		player.abilities.assign(save_manager.get_value("abilities"))
		
		if not custom_run:
			var loaded_starting_map: String = save_manager.get_value("current_room")
			if not loaded_starting_map.is_empty(): # Some compatibility problem.
				starting_map = loaded_starting_map
	else:
		# If no data exists, set empty one.
		MetSys.set_save_data()
	
	# Initialize room when it changes.
	room_loaded.connect(init_room, CONNECT_DEFERRED)
	# Load the starting room.
	load_room(starting_map)
	
	# Find the save point and teleport the player to it, to start at the save point.
	var start := map.get_node_or_null(^"SavePoint")
	if start and not custom_run:
		player.position = start.position
	
	# Reset position tracking (feature specific to this project).
	reset_map_starting_coords.call_deferred()
	# Add module for room transitions.
	add_module("RoomTransitions.gd")
	
	var sandcanister_count = 0
	
	for ability in player.abilities:
		if ability.contains("sandcanister"): sandcanister_count += 1
	
	const rewind_timer_maxes = [20, 40, 60, 80, 100]
	$UI/RewindTimer_HBoxContainer/RewindTimer.wait_time = rewind_timer_maxes[sandcanister_count]
	$UI/RewindTimer_HBoxContainer/RewindTimer.start()
	$UI/RewindTimer_HBoxContainer.show()
	
	if "blastercode" in player.abilities && !"blaster" in player.abilities:
		item_popup("blaster")
		player.abilities.append("blaster")
	if "walljumpcode" in player.abilities && !"walljump" in player.abilities:
		item_popup("walljump")
		player.abilities.append("walljump")
	if "dashcode" in player.abilities && !"dash" in player.abilities:
		item_popup("dash")
		player.abilities.append("dash")

# Returns this node from anywhere.
static func get_singleton() -> Game:
	return (Game as Script).get_meta(&"singleton") as Game

# Save game using MetSys SaveManager.
func save_game():
	var save_manager := SaveManager.new()
	save_manager.set_value("collectible_count", collectibles)
	save_manager.set_value("generated_rooms", generated_rooms)
	save_manager.set_value("events", events)
	save_manager.set_value("current_room", MetSys.get_current_room_name())
	save_manager.set_value("abilities", player.abilities)
	save_manager.save_as_text(SAVE_PATH)

func reset_map_starting_coords():
	$UI/MapWindow.reset_starting_coords()

func init_room():
	MetSys.get_current_room_instance().adjust_camera_limits($Player/Camera2D)
	player.on_enter()

func _exit_tree() -> void:
	get_singleton().save_game()


func _on_rewind_timer_timeout() -> void:
	player.trigger_death()

var item_descriptions := {
	"doorcode" : "Door Code acquired.
\"5318008\"",
	"sandcanister_one" : "Sand Canister 1 acquired.
Try bringing it back to the hourglass.",
	"sandcanister_two" : "Sand Canister 2 acquired.
Don't forget to bring it to the hourglass.",
	"blastercode": "Strange Code acquired.
This might be useful later.",
	"blaster" : "Blaster unlocked.
The strange code unlocked your weapon!",
	"hot_warning" : "WARNING!
Reactor room too hot for current suit.",
	"walljumpcode" : "Ascending Code acquired.
You found the code to unlock another ability.",
	"walljump" : "Wall Jump unlocked.
You can now slide down and jump off walls.",
	"dashcode" : "Speed Code acquired.
You found the code to unlock another ability.",
	"dash": "Dash unlocked!
You can now dash, including vertically.",
	"sandcanister_done": "You added sand in the hourglass!
Starting next loop, it will last longer."

}

var unpausable = false

func item_popup(itemname: String) -> void:
	if itemname in item_descriptions:
		#TODO: play tadada sound
		$UI/PopupPanel/RichTextLabel.text = ""
		$UI/PopupPanel.scale.y = 0.0
		$UI/PopupPanel.show()
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		$UI/PopupPanel/RichTextLabel.text = ""
		get_tree().paused = true
		tween.tween_property($UI/PopupPanel, "scale:y", 1.0, 0.5)
		tween.tween_property($UI/PopupPanel/RichTextLabel, "text", "[center]"+item_descriptions[itemname]+"[/center]", 0.01)
		tween.tween_interval(1.0)
		tween.tween_property(self, "unpausable", true, 0.01)

func _physics_process(delta: float) -> void:
	if unpausable && (Input.is_action_just_pressed("Jump") || Input.is_action_just_pressed("Shoot")):
		unpausable = false
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		$UI/PopupPanel/RichTextLabel.text = ""
		get_tree().paused = false
		tween.tween_property($UI/PopupPanel, "scale:y", 0.0, 0.5)
		tween.tween_property($UI/PopupPanel, "visible", false, 0.01)
