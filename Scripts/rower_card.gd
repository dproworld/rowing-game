extends Control

var rname = "null"
var strength = -1
var endurance = -1
var tech = -1

func update():
	$Name.text = rname
	$Strength.text = str(strength)
	$Endurance.text = str(endurance)
	$Tech.text = str(tech)
