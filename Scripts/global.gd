extends Node

# Rower stats in GDScript using nested dictionaries
var data_set = {
	"Patrice": {
		"name": "Patrice",
		"picture": load("res://Assets/PlayerCard/people00.png"),
		"strength": 80,
		"endurance": 75,
		"tech": 0.90
	},
	"Morgan": {
		"name": "Morgan",
		"picture": load("res://Assets/PlayerCard/people01.png"),
		"strength": 75,
		"endurance": 85,
		"tech": 0.78
	},
	"Jordan": {
		"name": "Jordan",
		"picture": load("res://Assets/PlayerCard/people02.png"),
		"strength": 90,
		"endurance": 72,
		"tech": 0.85
	},
	"Casey": {
		"name": "Casey",
		"picture": load("res://Assets/PlayerCard/people03.png"),
		"strength": 65,
		"endurance": 90,
		"tech": 0.92
	},
	"Alex": {
		"name": "Alex",
		"picture": load("res://Assets/PlayerCard/people04.png"),
		"strength": 85,
		"endurance": 68,
		"tech": 0.75
	},
	"Taylor": {
		"name": "Taylor",
		"picture": load("res://Assets/PlayerCard/people05.png"),
		"strength": 70,
		"endurance": 82,
		"tech": 0.88
	},
	"Riley": {
		"name": "Riley",
		"picture": load("res://Assets/PlayerCard/people06.png"),
		"strength": 67,
		"endurance": 89,
		"tech": 0.76
	},
	"Quinn": {
		"name": "Quinn",
		"picture": load("res://Assets/PlayerCard/people07.png"),
		"strength": 73,
		"endurance": 78,
		"tech": 0.94
	},
	"Avery": {
		"name": "Avery",
		"picture": load("res://Assets/PlayerCard/people08.png"),
		"strength": 88,
		"endurance": 74,
		"tech": 0.79
	},
	"Blake": {
		"name": "Blake",
		"picture": load("res://Assets/PlayerCard/people09.png"),
		"strength": 78,
		"endurance": 86,
		"tech": 0.83
	},
	"Cameron": {
		"name": "Cameron",
		"picture": load("res://Assets/PlayerCard/people10.png"),
		"strength": 82,
		"endurance": 70,
		"tech": 0.91
	},
	"Drew": {
		"name": "Drew",
		"picture": load("res://Assets/PlayerCard/people11.png"),
		"strength": 69,
		"endurance": 92,
		"tech": 0.77
	},
	"Ellis": {
		"name": "Ellis",
		"picture": load("res://Assets/PlayerCard/people12.png"),
		"strength": 91,
		"endurance": 66,
		"tech": 0.84
	},
	"Finley": {
		"name": "Finley",
		"picture": load("res://Assets/PlayerCard/people13.png"),
		"strength": 76,
		"endurance": 84,
		"tech": 0.89
	},
	"Gray": {
		"name": "Gray",
		"picture": load("res://Assets/PlayerCard/people14.png"),
		"strength": 84,
		"endurance": 73,
		"tech": 0.74
	},
	"Harper": {
		"name": "Harper",
		"picture": load("res://Assets/PlayerCard/people15.png"),
		"strength": 72,
		"endurance": 88,
		"tech": 0.86
	},
	"Ivy": {
		"name": "Ivy",
		"picture": load("res://Assets/PlayerCard/people16.png"),
		"strength": 79,
		"endurance": 76,
		"tech": 0.80
	},
	"Jules": {
		"name": "Jules",
		"picture": load("res://Assets/PlayerCard/people17.png"),
		"strength": 86,
		"endurance": 69,
		"tech": 0.93
	},
	"Kennedy": {
		"name": "Kennedy",
		"picture": load("res://Assets/PlayerCard/people18.png"),
		"strength": 74,
		"endurance": 87,
		"tech": 0.81
	},
	"Logan": {
		"name": "Logan",
		"picture": load("res://Assets/PlayerCard/people19.png"),
		"strength": 81,
		"endurance": 79,
		"tech": 0.73
	},
	"Madison": {
		"name": "Madison",
		"picture": load("res://Assets/PlayerCard/people20.png"),
		"strength": 77,
		"endurance": 81,
		"tech": 0.87
	},
	"Nico": {
		"name": "Nico",
		"picture": load("res://Assets/PlayerCard/people21.png"),
		"strength": 83,
		"endurance": 77,
		"tech": 0.95
	},
	"Owen": {
		"name": "Owen",
		"picture": load("res://Assets/PlayerCard/people22.png"),
		"strength": 68,
		"endurance": 93,
		"tech": 0.72
	},
	"Jamie": {
		"name": "Jamie",
		"picture": load("res://Assets/PlayerCard/people23.png"),
		"strength": 92,
		"endurance": 71,
		"tech": 0.82
	}
}

# To access individual stats:
# var rower_stats = data_set["Patrice"]  # Gets Patrice's entire data dictionary
# var strength = data_set["Patrice"]["strength"]  # 80
# var endurance = data_set["Patrice"]["endurance"]  # 75
# var tech = data_set["Patrice"]["tech"]  # 0.90

# If you need all names as a separate array:
func get_all_names():
	return data_set.keys()

# If you need to generate the lists from the dictionary:
func generate_separate_lists():
	var names = []
	var strengths = []
	var endurances = []
	var techs = []

	for rower_name in data_set:
		names.append(rower_name)
		strengths.append(data_set[rower_name]["strength"])
		endurances.append(data_set[rower_name]["endurance"])
		techs.append(data_set[rower_name]["tech"])

	return [names, strengths, endurances, techs]

var boat = [null, null, null, null, null, null, null, null]

var trash = 20 # Changed initial value to 20 for testing
