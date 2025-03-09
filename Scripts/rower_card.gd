extends Control

var rname = "blah"
var picture = load("res://Assets/boat.png")
var strength = -1
var endurance = -1
var tech = -1

var name_label
var textrect
var strength_label
var endurance_label
var tech_label

func _ready() -> void:
	name_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Name
	textrect = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/TextureRect
	strength_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Strength
	endurance_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Endurance
	tech_label = $/root/Team/CanvasLayer/MarginContainer/VSplitContainer/Panel2/HSplitContainer/VSplitContainer/MarginContainer/Panel/Tech


func update():
	$MarginContainer/Panel/Name.text = rname
	$MarginContainer/Panel/TextureRect.texture = picture
	#$Panel/Strength.text = str(strength)
	#$Panel/Endurance.text = str(endurance)
	#$Panel/Tech.text = str(tech)

func _on_button_pressed() -> void:
	name_label.text = rname
	textrect.texture = picture
	strength_label.text = "Strength: " + str(strength)
	endurance_label.text = "Endurance: " + str(endurance)
	tech_label.text = "Tech: " + str(tech)
