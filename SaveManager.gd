extends Node

const SAVE_PATH = "user://highscore.cfg"
var config = ConfigFile.new()
var high_score: int = 0

func _ready() -> void:
	load_data()

func load_data() -> void:
	var err = config.load(SAVE_PATH)
	if err == OK:
		high_score = config.get_value("score", "high_score", 0)
	else:
		high_score = 0

func save_data(score: int) -> void:
	if score > high_score:
		high_score = score
		config.set_value("score", "high_score", high_score)
		config.save(SAVE_PATH)

func get_high_score() -> int:
	return high_score
