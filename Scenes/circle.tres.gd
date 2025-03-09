extends Node2D

var num
var label
var on_player = false

func _ready() -> void:
	label = $Label

func update(n):
	num = n

func _on_button_pressed() -> void:
	pass
