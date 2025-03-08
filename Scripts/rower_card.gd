extends Node2D

func _ready():
	$Name.text = global.test_name
	$Strength.text = str(global.test_strength)
