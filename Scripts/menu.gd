extends Control


func _on_team_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/team.tscn")

func _on_practice_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/practice.tscn")

func _on_race_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/race.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
