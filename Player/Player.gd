extends CharacterBody3D

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var animation_player: AnimationPlayer = $Character/AnimationPlayer
@onready var gui: Control = $CanvasLayer/gui
@onready var game_over_panel: Panel = $CanvasLayer/gui/game_over_panel

const MOVE_SPEED: float = 8.0
const JUMP_VELOCITY: float = 8.0  # Jump strength
const GRAVITY: float = 24.0  # Gravity strength
const LANES: Array = [-2, 0, 2]  # Lane positions on x-axis
const DISTANCE_PER_SECOND: float = 3.75  # Calibrated to object movement speed

var target_lane: int = 1
var is_dead: bool = false

var coin_count: int = 0
var time_elapsed: float = 0.0
var distance_traveled: int = 0

func _ready() -> void:
	gui.get_node("label").text = "Coins: "
	$CanvasLayer/gui/game_over_panel/VBoxContainer/restart_button.pressed.connect(_on_restart_pressed)

func _physics_process(delta: float) -> void:
	if not is_dead:
		time_elapsed += delta
		distance_traveled = int(time_elapsed * DISTANCE_PER_SECOND)
		update_hud()

	var direction: Vector3 = Vector3.ZERO

	# Handle lane switching
	if Input.is_action_just_pressed("ui_left") and target_lane > 0:
		target_lane -= 1
	if Input.is_action_just_pressed("ui_right") and target_lane < LANES.size() - 1:
		target_lane += 1
	
	# Move towards the target lane
	var target_x: float = LANES[target_lane]
	var current_x: float = global_transform.origin.x
	global_transform.origin.x = lerp(current_x, target_x, MOVE_SPEED * delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0  # Reset vertical velocity when on the floor

	# Jumping logic
	if is_on_floor() and Input.is_action_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY  # Apply jump velocity

	# Apply the velocity and move the character
	move_and_slide()

	# Play animations based on movement
	if not is_on_floor():
		animation_player.play("Jump")
	else:
		animation_player.play("Run")

func _on_collision_area_entered(area):
	var parent = area.get_parent()
	if parent.is_in_group("coins"):
		audio_player.play()
		coin_count += 1
		parent.queue_free()

func get_total_score() -> int:
	return coin_count + distance_traveled

func update_hud() -> void:
	gui.get_node("label").text = "Score: " + str(get_total_score())

func show_game_over() -> void:
	var total_score = get_total_score()
	SaveManager.save_data(total_score)

	# Populate game over UI
	game_over_panel.get_node("VBoxContainer/score_container/coins_label").text = "Coins: " + str(coin_count)
	game_over_panel.get_node("VBoxContainer/score_container/distance_label").text = "Distance: " + str(distance_traveled) + " m"
	game_over_panel.get_node("VBoxContainer/score_container/total_score_label").text = "Total Score: " + str(total_score)
	game_over_panel.get_node("VBoxContainer/score_container/high_score_label").text = "High Score: " + str(SaveManager.get_high_score())

	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
