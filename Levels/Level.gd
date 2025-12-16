extends Node

@export var player: CharacterBody3D
@export var spawn_timer: Timer
@export var spawn_env_timer: Timer
@export var spawn_obstacle_timer: Timer


@export var coin: PackedScene

@export var rock:  PackedScene

@export var road: PackedScene

var startz: float = -50.0
var road_spawnx: Array = [-2, 0, 2]
var tree_startx: Array = [10, -10]

var difficulty_level: int = 0
var difficulty_timer: Timer = null
const DIFFICULTY_INTERVAL: float = 10.0



func _ready():
	var x = 0
	var y = 0
	var z = 5
	
	
	
	# Spawn road first (after this, spawn after timeout)
	var road_asset = road.instantiate()
	add_child(road_asset)
	road_asset.global_transform.origin = Vector3(
		0,
		0,
		startz
	)

	# Setup difficulty timer
	difficulty_timer = Timer.new()
	difficulty_timer.wait_time = DIFFICULTY_INTERVAL
	difficulty_timer.autostart = true
	difficulty_timer.timeout.connect(_on_difficulty_timer_timeout)
	add_child(difficulty_timer)



func _on_spawn_timer_timeout():
	randomize()
	#print("spawned a coin!")
	var min_interval = max(0.4, 1.0 - (difficulty_level * 0.2))
	var max_interval = max(3.0, 5.0 - (difficulty_level * 0.5))
	spawn_timer.wait_time = randf_range(min_interval, max_interval) 
	
	var random_line_num = randi() % 3
	var prev_rand_line_n = null
	
	var line_count: int = randi() % 4 + 1
	
	for i in line_count:
		while (prev_rand_line_n != null and prev_rand_line_n == random_line_num):
				random_line_num = randi() % 3
		prev_rand_line_n = random_line_num

		for n in randf_range(4, 10):

			var coin_inst: MeshInstance3D = coin.instantiate()

			add_child(coin_inst)
			coin_inst.speed_multiplier = get_speed_multiplier()

			coin_inst.global_transform.origin = Vector3(
				road_spawnx[random_line_num],
				1.0,
				startz + i * 2.5 # set distance between coins
			)




func _on_spawn_obstacle_timer_timeout():
	randomize()
	#print("spawned an obstacle!")
	var min_interval = max(0.4, 1.0 - (difficulty_level * 0.2))
	var max_interval = max(3.0, 5.0 - (difficulty_level * 0.5))
	spawn_obstacle_timer.wait_time = randf_range(min_interval, max_interval)

	var random_line_num = randi() % 3
	var prev_rand_line_n = null

	# Increase max line count at higher difficulty
	var max_lines = 4 if difficulty_level < 3 else 5
	var line_count: int = randi() % max_lines + 1
	
	for i in line_count:
		while (prev_rand_line_n != null and prev_rand_line_n == random_line_num):
				random_line_num = randi() % 3
		prev_rand_line_n = random_line_num

		var rock_inst = rock.instantiate()
# warning-ignore:return_value_discarded
		rock_inst.player_entered.connect(on_player_entered_rock)

		add_child(rock_inst)
		rock_inst.speed_multiplier = get_speed_multiplier()

		rock_inst.global_transform.origin = Vector3(
			road_spawnx[random_line_num],
			0.0,
			startz
		)
		rock_inst.rotation_degrees.y = randf_range(0, 360)


func _on_road_spawn_timer_timeout():
	var road_asset = road.instantiate()
	add_child(road_asset)
	road_asset.speed_multiplier = get_speed_multiplier()
	road_asset.global_transform.origin = Vector3(
		0,
		0,
		startz
	)
	# After 1st shot, make it 1.85
	($RoadSpawnTimer as Timer).wait_time = 1.85

func on_player_entered_rock():
	player.is_dead = true
	player.show_game_over()
	get_tree().paused = true

func _on_difficulty_timer_timeout() -> void:
	difficulty_level += 1

func get_speed_multiplier() -> float:
	return 1.0 + (difficulty_level * 0.1)

