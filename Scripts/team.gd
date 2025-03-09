extends Control

@export var rower_data: Dictionary = {}

var trash = global.trash
var trash_lab
var name_lab
var data
var s_lab
var e_lab
var t_lab
var s_label
var e_label
var t_label

func _ready():
	trash_lab = $CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer2/HSplitContainer/Trash
	trash_lab.text = "Trash: " + str(trash)
	name_lab = $CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Name
	data = global.data_set
	s_lab = $CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Strength
	e_lab = $CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Endurance
	t_lab = $CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Tech
	s_label = $CanvasLayer/MarginContainer/VSplitContainer/Panel/MarginContainer/HSplitContainer/VBoxContainer/Ave_Strength
	e_label = $CanvasLayer/MarginContainer/VSplitContainer/Panel/MarginContainer/HSplitContainer/VBoxContainer/Ave_Endurance
	t_label = $CanvasLayer/MarginContainer/VSplitContainer/Panel/MarginContainer/HSplitContainer/VBoxContainer/Ave_Tech
	$CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/ScrollContainer/MarginContainer/CardsContainer.layout_mode = 3  # or try 3
	for rower_name in global.data_set:
		var card = preload("res://Scenes/rower_card.tscn").instantiate()
		rower_data = global.data_set[rower_name]
		card.name = rower_name
		card.rname = rower_data["name"]
		card.picture = rower_data["picture"]
		card.strength = rower_data["strength"]
		card.endurance = rower_data["endurance"]
		card.tech = rower_data["tech"]
		card.update()
		$CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/ScrollContainer/MarginContainer/CardsContainer.add_child(card)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")

func _on_s_up_pressed() -> void:
	if(check()):
		trash -= 1
		data[name_lab.text]["strength"] += 1
		update()

func _on_e_up_pressed() -> void:
	if(check()):
		trash -= 1
		data[name_lab.text]["endurance"] += 1
		update()

func _on_t_up_pressed() -> void:
	if(check()):
		trash -= 1
		data[name_lab.text]["tech"] += 0.01
		update()

func check():
	if(trash < 1):
		print("Too little trash")
		return false
	if(name_lab.text == "Name"):
		print("No athlete selected")
		return false
	return true

func update():
	s_lab.text = "Strength: " + str(data[name_lab.text]["strength"])
	e_lab.text = "Endurance: " + str(data[name_lab.text]["endurance"])
	t_lab.text = "Tech: " + str(data[name_lab.text]["tech"])
	trash_lab.text = "Trash: " + str(trash)
	calc_ave_stat()

var boat = global.boat
func calc_ave_stat():
	var s = 0
	var e = 0
	var t = 0
	var c = 8.0
	for i in range(len(boat)):
		if(boat[i] != null):
			s += data[boat[i]]["strength"]
			e += data[boat[i]]["endurance"]
			t += data[boat[i]]["tech"]
	if(c!=0):
		s_label.text = "Ave Strength: " + str(round(s/c * 10) / 10.0)
		e_label.text = "Ave Endurance: " + str(round(e/c * 10) / 10.0)
		t_label.text = "Ave Tech: " + str(round(t/c * 100) / 100.0)
	print(s, " ", e, " ", t)
