extends Node2D

var num
var label

func _ready() -> void:
	label = $Label

func update(n):
	num = n
