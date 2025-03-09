extends Node2D

@export var num = 0
var label
var on_player = false
var text_label
var s_label
var e_label
var t_label
var boat
var athlete
var data

func _ready() -> void:
	label = $Sprite2D/Label
	text_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Name
	s_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel/MarginContainer/HSplitContainer/VBoxContainer/Ave_Strength
	e_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel/MarginContainer/HSplitContainer/VBoxContainer/Ave_Endurance
	t_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel/MarginContainer/HSplitContainer/VBoxContainer/Ave_Tech
	boat = global.boat
	data = global.data_set
	label.text = str(num)

func _on_button_pressed() -> void:
	athlete = text_label.text
	if(athlete != "Name"):
		for i in range(len(boat)):
			if(athlete == boat[i]):
				print("Athlete already in boat")
				return
		boat[num -1] = athlete
		calc_ave_stat()
	else:
		print("No Name")

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
	s_label.text = "Ave Strength: " + str(round(s/c * 10) / 10.0)
	e_label.text = "Ave Endurance: " + str(round(e/c * 10) / 10.0)
	t_label.text = "Ave Tech: " + str(round(t/c * 100) / 100.0)
	print(s, " ", e, " ", t)
