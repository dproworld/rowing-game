extends Control

@export var rower_data: Dictionary = {}

func _ready():
	for rower_name in global.data_set:
		var card = preload("res://Scenes/rower_card.tscn").instantiate()
		rower_data = global.data_set[rower_name]
		card.name = rower_name
		card.strength = rower_data["strength"]
		card.endurance = rower_data["endurance"]
		card.tech = rower_data["tech"]
		card.update()
		$CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/ScrollContainer/CardsContainer.add_child(card)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")
