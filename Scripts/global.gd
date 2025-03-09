extends Node

# Rower stats in GDScript using nested dictionaries
var data_set = {
	"Patrice": {
		"name": "Patrice",
		"strength": 80,
		"endurance": 75,
		"tech": 0.90
	},
	"Morgan": {
		"name": "Morgan",
		"strength": 75,
		"endurance": 85,
		"tech": 0.78
	},
	"Jordan": {
		"name": "Jordan",
		"strength": 90,
		"endurance": 72,
		"tech": 0.85
	},
	"Casey": {
		"name": "Casey",
		"strength": 65,
		"endurance": 90,
		"tech": 0.92
	},
	"Alex": {
		"name": "Alex",
		"strength": 85,
		"endurance": 68,
		"tech": 0.75
	},
	"Taylor": {
		"name": "Taylor",
		"strength": 70,
		"endurance": 82,
		"tech": 0.88
	},
	"Jamie": {
		"name": "Jamie",
		"strength": 92,
		"endurance": 71,
		"tech": 0.82
	},
	"Riley": {
		"name": "Riley",
		"strength": 67,
		"endurance": 89,
		"tech": 0.76
	},
	"Quinn": {
		"name": "Quinn",
		"strength": 73,
		"endurance": 78,
		"tech": 0.94
	},
	"Avery": {
		"name": "Avery",
		"strength": 88,
		"endurance": 74,
		"tech": 0.79
	},
	"Blake": {
		"name": "Blake",
		"strength": 78,
		"endurance": 86,
		"tech": 0.83
	},
	"Cameron": {
		"name": "Cameron",
		"strength": 82,
		"endurance": 70,
		"tech": 0.91
	},
	"Drew": {
		"name": "Drew",
		"strength": 69,
		"endurance": 92,
		"tech": 0.77
	},
	"Ellis": {
		"name": "Ellis",
		"strength": 91,
		"endurance": 66,
		"tech": 0.84
	},
	"Finley": {
		"name": "Finley",
		"strength": 76,
		"endurance": 84,
		"tech": 0.89
	},
	"Gray": {
		"name": "Gray",
		"strength": 84,
		"endurance": 73,
		"tech": 0.74
	},
	"Harper": {
		"name": "Harper",
		"strength": 72,
		"endurance": 88,
		"tech": 0.86
	},
	"Ivy": {
		"name": "Ivy",
		"strength": 79,
		"endurance": 76,
		"tech": 0.80
	},
	"Jules": {
		"name": "Jules",
		"strength": 86,
		"endurance": 69,
		"tech": 0.93
	},
	"Kennedy": {
		"name": "Kennedy",
		"strength": 74,
		"endurance": 87,
		"tech": 0.81
	},
	"Logan": {
		"name": "Logan",
		"strength": 81,
		"endurance": 79,
		"tech": 0.73
	},
	"Madison": {
		"name": "Madison",
		"strength": 77,
		"endurance": 81,
		"tech": 0.87
	},
	"Nico": {
		"name": "Nico",
		"strength": 83,
		"endurance": 77,
		"tech": 0.95
	},
	"Owen": {
		"name": "Owen",
		"strength": 68,
		"endurance": 93,
		"tech": 0.72
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
