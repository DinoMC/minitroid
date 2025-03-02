# This is the main script of the game. It manages the current map and some other stuff.
extends "res://addons/MetroidvaniaSystem/Template/Scripts/MetSysGame.gd"
class_name Game

signal timer_started

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

var timestarted_mainsong = 0
var timestarted_bosssong = 0

func _ready() -> void:
	timestarted_mainsong = Time.get_unix_time_from_system()
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
		
		if GlobalVars.first_launch:
			GlobalVars.first_launch = false
			for ability in GlobalVars.abilities_to_append:
				if !player.abilities.has(ability): player.abilities.append(ability)
		
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
	
	#if !player.abilities.has("win_code"):
	timer_started.emit()
	
	if "blastercode" in player.abilities && !"blaster" in player.abilities:
		item_popup("blaster")
		player.abilities.append("blaster")
		save_game()
	if "walljumpcode" in player.abilities && !"walljump" in player.abilities:
		item_popup("walljump")
		player.abilities.append("walljump")
		save_game()
	if "dashcode" in player.abilities && !"dash" in player.abilities:
		item_popup("dash")
		player.abilities.append("dash")
		save_game()
	if "heatresist_code" in player.abilities && !"heatresist" in player.abilities:
		item_popup("heatresist")
		player.abilities.append("heatresist")
		save_game()
	
	if player.abilities.has("win_code"):
		player.hide()
		player.process_mode = Node.PROCESS_MODE_DISABLED 
		await get_tree().create_timer(2.5).timeout
		var hourglass = MetSys.current_room.get_parent().find_child("Hourglass_AnimatedSprite2D")
		hourglass.play("die")
		$WinSoundPlayer.play()
		await hourglass.animation_finished
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.show()
		
		for i in range(1, 99):
			rewind_timer.start(i*60)
			await get_tree().create_timer(0.01).timeout
		
		rewind_timer.start(5999)
		rewind_timer.paused = true
		$UI/ControlsControl/F2TouchScreenButton.show()
		await get_tree().create_timer(0.01).timeout
		if !player.abilities.has("won"):
			item_popup("won")
			complete_challenge("win_code")
			player.abilities.append("won")
		
		#$UI/RewindTimer_HBoxContainer/RewindTimer.start(5999)
		
	if OS.has_feature("avax"):
		challenge_ids = {
"blaster":"fafdbb78-0cd5-4229-bd9e-c1e769b9a005",
"doorcode":"66dd943f-0bb5-492b-a855-5e16b36b558b",
"dash":"e4e014c5-dd8d-494e-80ad-ec200f64bf8b",
"heatresist":"3e4f2aba-c4f3-42bb-9be1-2b8c42108371",
"sandcanister_done_1":"13a330ce-d968-48a8-b97f-09b8c044c5dc",
"sandcanister_done_2":"27a3e3ad-4d57-48ee-8d5c-fc78b2b553fb",
"walljump":"2f093654-f1d2-4a5c-a7ba-f8b1ac28a385",
"win_code":"86cc7c68-7859-4086-a440-140479193abd"
}

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
	"heatresist_code" : "Heat Code acquired.
You found the code to unlock another ability.",
	"heatresist" : "Heat Suit acquired.
You will now resist high temperatures.",
	"sandcanister_done_1": "You added sand in the hourglass!
Starting next loop, it will last longer.",
	"sandcanister_done_2": "You added sand in the hourglass!
Starting next loop, it will last longer.",
	"won": "Congratulations! 
You are now free from the time loop.
Thanks for playing!
Press F2 for a Retro bonus."

}

var unpausable = false

func item_popup(itemname: String) -> void:
	if itemname in item_descriptions:
		if itemname == "hot_warning" && player.abilities.has("heatresist"): return
		if itemname != "won" : $UI/PopupPanel.size.y = 52
		else: $UI/PopupPanel.size.y = 104
		
		if itemname in ["sandcanister_done_1", "sandcanister_done_2", "blaster", "walljump", "dash", "heatresist"]:
			$PowerUpSoundPlayer.play()
		
		$UI/PopupPanel/RichTextLabel.text = ""
		$UI/PopupPanel.scale.y = 0.0
		$UI/PopupPanel.show()
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		$UI/PopupPanel/RichTextLabel.text = ""
		get_tree().paused = true
		tween.tween_property($UI/PopupPanel, "scale:y", 1.0, 0.5)
		tween.tween_property($UI/PopupPanel/RichTextLabel, "text", "[center]"+item_descriptions[itemname]+"[/center]", 0.01)
		if itemname == "won":
			tween.tween_interval(3.0)
		else:
			tween.tween_interval(1.0)
		tween.tween_property(self, "unpausable", true, 0.01)
		
		complete_challenge(itemname)

func _physics_process(delta: float) -> void:
	if unpausable && (Input.is_action_just_pressed("Jump") || Input.is_action_just_pressed("Shoot")):
		unpausable = false
		var tween = get_tree().create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		$UI/PopupPanel/RichTextLabel.text = ""
		tween.tween_property($UI/PopupPanel, "scale:y", 0.0, 0.5)
		tween.tween_property($UI/PopupPanel, "visible", false, 0.01)
		tween.tween_property(get_tree(), "paused", false,  0.01)

@onready var target2 : AudioStreamPlayer = $MainMusicPlayer_reversed
var time = 0

func stop_music_animated() -> void:
	var target: AudioStreamPlayer = $MainMusicPlayer
	target2 = $MainMusicPlayer_reversed
	if $BossMusicPlayer.playing:
		target = $BossMusicPlayer
		target2 = $BossMusicPlayer_reversed
	var tween = get_tree().create_tween()
	tween.tween_property(target, "pitch_scale", 0.01, 1.0)
	if target == $MainMusicPlayer:
		if OS.has_feature("web"):
			tween.tween_property(self, "time", 82.29 - fmod(Time.get_unix_time_from_system() - timestarted_mainsong, 82.29), 0.01)
		else:
			tween.tween_property(self, "time", 82.29 - target.get_playback_position(), 0.01)
	elif target == $BossMusicPlayer:
		if OS.has_feature("web"):
			tween.tween_property(self, "time", 82.29 - fmod(Time.get_unix_time_from_system() - timestarted_bosssong, 96.05), 0.01)
		else:
			tween.tween_property(self, "time", 96.05 - target.get_playback_position(), 0.01)
	tween.tween_callback(target.stop)

func start_music_reversed() -> void:
	target2.pitch_scale = 0.01
	target2.play(time)
	var tween = get_tree().create_tween()
	tween.tween_property(target2, "pitch_scale", 1.0, 1.0)
		
func play_alien_damaged_sound() -> void:
	$AlienDamageSound_Player.play()

func switch_to_boss_music() -> void:
	$BossMusicPlayer.volume_db = -20
	var tween = get_tree().create_tween()
	tween.tween_property($MainMusicPlayer, "volume_db", -20, 0.5)
	tween.tween_callback($MainMusicPlayer.stop)
	timestarted_bosssong = Time.get_unix_time_from_system()
	tween.tween_callback($BossMusicPlayer.play)
	tween.tween_property($BossMusicPlayer, "volume_db", -7, 0.5)

var challenge_ids = {
	"blaster":"15dc5baf-a2e4-4b37-bd00-84b5efbaa511",
	"doorcode":"aefa10a9-c4e1-46d7-a93b-a7552c18230d",
	"dash":"bb2a972b-9fa4-47a9-be69-509a8488af65",
	"heatresist":"41f46e9e-101d-4f9d-bd16-05f688da0f03",
	"sandcanister_done_1":"df7d81c4-bcb6-4416-9385-26c73943dd9c",
	"sandcanister_done_2":"55b1b922-d75f-406f-a762-ad4ae175838f",
	"walljump":"f2c759e1-bb6d-41c4-a6df-bacdc9923552",
	"win_code":"282c9be1-ccff-4d27-97f4-37e8d53c74fd"
}

func complete_challenge(itemname: String) -> void:
	if !itemname in challenge_ids: return
	#$Background/Score2.text = "Current objective: Die"
	if $HTTPRequest.request_completed.is_connected(_on_challenge_complete):
		$HTTPRequest.request_completed.disconnect(_on_challenge_complete)
	$HTTPRequest.request_completed.connect(_on_challenge_complete.bind(itemname))
	if OS.has_feature("avax"):
		$HTTPRequest.request("https://api.whalepass.gg/players/"+GlobalVars.playerid+"/progress/challenge", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "Content-Type: application/json", "X-Battlepass-Id: 33d3615d-c7d3-4d16-adce-2d53e5cfb00d"], 2, JSON.stringify({"gameId" : "8709dd77-9dab-443b-9264-6757ca96f440", "challengeId" : challenge_ids[itemname]}) )
	else:
		$HTTPRequest.request("https://api.whalepass.gg/players/"+GlobalVars.playerid+"/progress/challenge", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "Content-Type: application/json", "X-Battlepass-Id: e0da1a47-65b9-4b8f-a6f3-b6cf3ac4a9b7"], 2, JSON.stringify({"gameId" : "51bea481-def4-415b-9d72-205fc0785a76", "challengeId" : challenge_ids[itemname]}) )		

func _on_challenge_complete(result, code, headers, body, itemname: String) -> void:
	if code==200:
		_add_achievement(itemname)

@onready var icon_paths = {
	"blaster":preload("res://art/icons/Blaster.png"),
	"doorcode":preload("res://art/icons/Code.png"),
	"dash":preload("res://art/icons/Dash.png"),
	"heatresist":preload("res://art/icons/Heat Suit.png"),
	"sandcanister_done_1":preload("res://art/icons/Sand1.png"),
	"sandcanister_done_2":preload("res://art/icons/Sand2.png"),
	"walljump":preload("res://art/icons/WallJump.png"),
	"win_code":preload("res://art/icons/Free.png")
}
var reward_names = {
	"blaster":"Blaster",
	"doorcode":"Door Code",
	"dash":"Dash Boots",
	"heatresist":"Heat Suit",
	"sandcanister_done_1":"Sand Canister 1",
	"sandcanister_done_2":"Sand Canister 2",
	"walljump":"Climbing Gloves",
	"win_code":"Curse Immunity"
}
func _add_achievement(itemname: String) -> void:
	var achievementPopupScene = preload("res://achievement_popup.tscn")
	var instance = achievementPopupScene.instantiate()
	var icon = icon_paths[itemname]
	instance.icon = icon
	instance.text = "[center]NEW REWARD[/center]

[center]"+reward_names[itemname]+"[/center]"
	var achievement_box_node = $UI
	achievement_box_node.add_child(instance)
	instance.position.y += instance.size.y
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(instance, "position:y", instance.position.y - instance.size.y, 0.75)
	tween.play()
	await get_tree().create_timer(6).timeout
	instance.queue_free()
