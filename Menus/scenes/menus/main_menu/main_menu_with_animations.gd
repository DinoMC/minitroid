extends MainMenu
var tempplayerid = ""


var animation_state_machine : AnimationNodeStateMachinePlayback

func play_game():
	GameLog.game_started()
	super.play_game()

func intro_done():
	animation_state_machine.travel("OpenMainMenu")

func _is_in_intro():
	return animation_state_machine.get_current_node() == "Intro"

func _event_is_mouse_button_released(event : InputEvent):
	return event is InputEventMouseButton and not event.is_pressed()

func _event_skips_intro(event : InputEvent):
	return event.is_action_released("ui_accept") or \
		event.is_action_released("ui_select") or \
		event.is_action_released("ui_cancel") or \
		_event_is_mouse_button_released(event)

func _open_sub_menu(menu):
	super._open_sub_menu(menu)
	animation_state_machine.travel("OpenSubMenu")

func _close_sub_menu():
	super._close_sub_menu()
	animation_state_machine.travel("OpenMainMenu")

func _input(event):
	if _is_in_intro() and _event_skips_intro(event):
		intro_done()
		return
	super._input(event)

func _ready():
	super._ready()
	animation_state_machine = $MenuAnimationTree.get("parameters/playback")

	if OS.has_feature("playdeck"):
		JavaScriptBridge.eval("
			const parent = window.parent.window;
			parent.postMessage({ playdeck: { method: 'loading' } }, '*');
			setTimeout(() => {
				parent.postMessage({ playdeck: { method: 'loading', value: 100 } }, '*');
			}, 100);")

	if GlobalVars.first_launch:
		var uuid = preload("res://addons/uuidv5/v5.gd")
	
		if not FileAccess.file_exists("user://savegame.save"):
			tempplayerid = uuid.v5(str(Time.get_unix_time_from_system()), str(randi()))
			$HTTPRequest.request_completed.connect(_on_request_completed)
			if OS.has_feature("avax"):
				$HTTPRequest.request("https://api.whalepass.gg/enrollments", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "Content-Type: application/json"], 2, JSON.stringify({"gameId" : "8709dd77-9dab-443b-9264-6757ca96f440", "playerId" : tempplayerid}) )
			else:
				$HTTPRequest.request("https://api.whalepass.gg/enrollments", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "Content-Type: application/json"], 2, JSON.stringify({"gameId" : "51bea481-def4-415b-9d72-205fc0785a76", "playerId" : tempplayerid}) )
		else:
			var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
			while save_file.get_position() < save_file.get_length():
				var json_string = save_file.get_line()
				var json = JSON.new()
				var parse_result = json.parse(json_string)
				if not parse_result == OK:
					print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
					continue
				var node_data = json.get_data()
				tempplayerid = node_data["externalPlayerId"]
				GlobalVars.playerid = node_data["id"]
				GlobalVars.externalPlayerId = node_data["externalPlayerId"]
				GlobalVars.accountConnected = node_data["accountConnected"]
				if node_data["accountConnected"] == true:
					%ConnectButton.text = "Display
Account"
				$HTTPRequest.request_completed.connect(_on_request_completed)
				if OS.has_feature("avax"):
					$HTTPRequest.request("https://api.whalepass.gg/enrollments", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "Content-Type: application/json"], 2, JSON.stringify({"gameId" : "8709dd77-9dab-443b-9264-6757ca96f440", "playerId" : tempplayerid}) )
				else:
					$HTTPRequest.request("https://api.whalepass.gg/enrollments", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "Content-Type: application/json"], 2, JSON.stringify({"gameId" : "51bea481-def4-415b-9d72-205fc0785a76", "playerId" : tempplayerid}) )
	else:
		enable_buttons()


func _on_request_completed(result, code, headers, body) -> void:
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
		var json_string = JSON.stringify(json)
		save_file.store_line(json_string)
		GlobalVars.playerid = json["id"]
		GlobalVars.externalPlayerId = json["externalPlayerId"]
		GlobalVars.accountConnected = json["accountConnected"]
		if json["accountConnected"] == true:
			%ConnectButton.text = "Display
Account"
		check_inventory()

func _on_connect_button_pressed() -> void:
	$HTTPRequest2.request_completed.connect(_on_redirect_completed)
	if OS.has_feature("avax"):
		$HTTPRequest2.request("https://api.whalepass.gg/players/"+GlobalVars.playerid+"/redirect?gameId=8709dd77-9dab-443b-9264-6757ca96f440", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "X-Battlepass-Id: 33d3615d-c7d3-4d16-adce-2d53e5cfb00d"], 0 )
	else:
		$HTTPRequest2.request("https://api.whalepass.gg/players/"+GlobalVars.playerid+"/redirect?gameId=51bea481-def4-415b-9d72-205fc0785a76", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "X-Battlepass-Id: e0da1a47-65b9-4b8f-a6f3-b6cf3ac4a9b7"], 0 )
	
func _on_redirect_completed(result, code, headers, body) -> void:
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		OS.shell_open(json['redirectionLink'])

func check_inventory() -> void:
	$HTTPRequest3.request_completed.connect(_on_inventory_check_completed)
	if OS.has_feature("avax"):
		$HTTPRequest3.request("https://api.whalepass.gg/players/"+GlobalVars.playerid+"/inventory?gameId=8709dd77-9dab-443b-9264-6757ca96f440", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "X-Battlepass-Id: 33d3615d-c7d3-4d16-adce-2d53e5cfb00d"], 0 )
	else:
		$HTTPRequest3.request("https://api.whalepass.gg/players/"+GlobalVars.playerid+"/inventory?gameId=51bea481-def4-415b-9d72-205fc0785a76", ["X-API-KEY: 23163dc17d9143f86412f936605d1224", "X-Battlepass-Id: e0da1a47-65b9-4b8f-a6f3-b6cf3ac4a9b7"], 0 )
	
func _on_inventory_check_completed(result, code, headers, body) -> void:
	#TODO : check best bracelet in list and set Strength
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var items = json['items']
		for item in items:
			if item["name"] == "First World Conquered":
				GlobalVars.abilities_to_append.append("win_code")
				GlobalVars.abilities_to_append.append("won")
			if item["name"] == "Climbing Gloves":
				GlobalVars.abilities_to_append.append("walljumpcode")
				GlobalVars.abilities_to_append.append("walljump")
			if item["name"] == "Second Sand Canister":
				GlobalVars.abilities_to_append.append("sandcanister_two")
			if item["name"] == "First Sand Canister":
				GlobalVars.abilities_to_append.append("sandcanister_one")
			if item["name"] == "Heat Resist Suit":
				GlobalVars.abilities_to_append.append("heatresistcode")
				GlobalVars.abilities_to_append.append("heatresist")
			if item["name"] == "Blaster":
				GlobalVars.abilities_to_append.append("blastercode")
				GlobalVars.abilities_to_append.append("blaster")
			if item["name"] == "Door Code":
				GlobalVars.abilities_to_append.append("doorcode")
			if item["name"] == "Dash Boots":
				GlobalVars.abilities_to_append.append("dashcode")
				GlobalVars.abilities_to_append.append("dash")

		enable_buttons()

func enable_buttons() -> void:
	if GlobalVars.accountConnected == true:
		%ConnectButton.text = "Display
Account"
	%ConnectButton.disabled = false
	%PlayButton.disabled = false


func _on_fullscreen_button_pressed() -> void:
	AppSettings.set_fullscreen_enabled(!AppSettings.is_fullscreen(get_window()), get_window())
