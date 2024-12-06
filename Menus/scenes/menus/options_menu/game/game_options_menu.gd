extends Control


func _on_ResetGameControl_reset_confirmed():
	GameLevelLog.reset_game_data()
	if FileAccess.file_exists("user://save_data.sav"):
		DirAccess.remove_absolute("user://save_data.sav")
	GlobalVars.first_launch = false
