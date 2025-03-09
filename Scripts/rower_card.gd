extends Control

var rname = "blah"
var picture = load("res://Assets/boat.png")
var strength = -1
var endurance = -1
var tech = -1

func update():
	$MarginContainer/Panel/Name.text = rname
	$MarginContainer/Panel/TextureRect.texture = picture
	#$Panel/Strength.text = str(strength)
	#$Panel/Endurance.text = str(endurance)
	#$Panel/Tech.text = str(tech)
