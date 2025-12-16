# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a 3D endless runner game built with Godot 4.2. The game features a character running on a procedurally generated road, avoiding obstacles (rocks) and collecting coins. Based on [this repository](https://github.com/hman278/Godot-Runner-Game) with modifications.

## Development Commands

### Running the Game

**From Godot Editor:**
1. Open Godot and import this project
2. Press F5 to run, or click the Play button
3. The game will launch with `res://Levels/Level.tscn` as the main scene

**From Command Line (macOS):**
```bash
# Run the game directly
/Applications/Godot.app/Contents/MacOS/Godot --path /path/to/3d-endless-runner res://Levels/Level.tscn

# Or open the project in the editor
/Applications/Godot.app/Contents/MacOS/Godot --path /path/to/3d-endless-runner --editor
```

**From Command Line (Linux/Windows with godot in PATH):**
```bash
godot --path . res://Levels/Level.tscn
```

**Game Controls:**
- **A** or **Left Arrow**: Move left
- **D** or **Right Arrow**: Move right
- **Space** or **Up Arrow**: Jump
- **C**: Slide (defined but may not be fully implemented)

**Note:** The game will show a game over screen when the player collides with an obstacle. Use the Restart button to replay.

### Project Structure
- Main scene: `res://Levels/Level.tscn`
- Autoload singletons configured in `project.godot`:
  - `SaveManager`: Manages high score persistence
- Input mappings configured in `project.godot`:
  - `move_left` (A key)
  - `move_right` (D key)
  - `jump` (Space key)
  - `slide` (C key)

## Architecture

### Core Game Systems

**Level Management (Levels/Level.gd)**
- Main game controller that manages all spawning systems
- Three independent spawn timers:
  - `spawn_timer`: Spawns coin collectibles
  - `spawn_obstacle_timer`: Spawns rock obstacles
  - `RoadSpawnTimer`: Spawns road segments
- All spawned objects use the `MovingObject` pattern (move toward player via `global_translate`)
- Three-lane system: lane positions are `[-2, 0, 2]` on the x-axis
- Objects spawn at `startz = -50.0` and move forward via individual scripts
- **Progressive Difficulty System:**
  - Difficulty increases every 10 seconds via `difficulty_timer`
  - Speed multiplier increases by 10% per difficulty level: `1.0 + (difficulty_level * 0.1)`
  - Spawn intervals decrease dynamically:
    - Minimum interval: `max(0.4, 1.0 - (difficulty_level * 0.2))`
    - Maximum interval: `max(3.0, 5.0 - (difficulty_level * 0.5))`
  - All spawned objects (coins, obstacles, roads) receive `speed_multiplier` for synchronized scaling

**Player System (Player/Player.gd)**
- `CharacterBody3D` with lane-based movement (not free movement)
- Lane switching uses `lerp()` for smooth transitions between discrete lanes
- Physics constants:
  - `MOVE_SPEED: 8.0` (lane switching speed)
  - `JUMP_VELOCITY: 8.0`
  - `GRAVITY: 24.0`
  - `DISTANCE_PER_SECOND: 3.75` (calibrated to object movement speed)
- Collision detection via `CollisionArea` that checks for coins group membership
- Death handled via `is_dead` flag set by Level when player collides with rocks
- **Score System:**
  - Tracks `coin_count`, `time_elapsed`, and `distance_traveled`
  - Total score = coins collected + distance traveled (in meters)
  - Distance calculated as `time_elapsed * DISTANCE_PER_SECOND`
  - Score updates in real-time during gameplay
- **Game Over UI:**
  - Full-screen overlay with semi-transparent background
  - Displays: coins collected, distance traveled, total score, and high score
  - Restart button reloads scene via `get_tree().reload_current_scene()`
  - UI uses CanvasLayer for proper 2D rendering over 3D scene

**Moving Objects Pattern (Levels/MovingObject.gd)**
- Base pattern for obstacles (rocks) that move toward player
- All moving objects:
  - Move forward via `global_translate(Vector3(0, 0, 0.25 * speed_multiplier))` in `_process()`
  - `speed_multiplier` defaults to 1.0 and is set by Level based on current difficulty
  - Auto-destroy after 5 seconds via internal Timer
  - Emit `player_entered` signal on collision with player group

**Collectibles (Coins/Coin.gd)**
- Inherit same timer-based destruction pattern as MovingObject
- Self-rotate via `rotate_y(5 * delta)`
- Must be in "coins" group for player collision detection
- Move forward via `global_translate(Vector3(0, 0, 0.25 * speed_multiplier))` and destroy after 5 seconds
- `speed_multiplier` defaults to 1.0 and is set by Level based on current difficulty

**High Score Persistence (SaveManager.gd)**
- Autoload singleton that manages high score persistence across sessions
- Uses Godot's `ConfigFile` API for save data
- Save location: `user://highscore.cfg`
- Key methods:
  - `save_data(score: int)`: Saves score only if it beats current high score
  - `get_high_score() -> int`: Returns the current high score
  - `load_data()`: Loads saved data on game start
- Registered as autoload in `project.godot` under name "SaveManager"

### Spawning Logic

**Coin Spawning**
- Spawns 1-4 lanes of coins per cycle
- Each lane contains 4-10 coins
- Coins within a lane are spaced 2.5 units apart (`startz + i * 2.5`)
- Prevents spawning on the same lane consecutively

**Obstacle Spawning**
- Spawns 1-4 obstacles per cycle
- Random rotation (0-360 degrees) for visual variety
- Uses same lane-avoidance logic as coins
- Connected to Level's `on_player_entered_rock()` to pause game on collision

**Road Spawning**
- Initial spawn at `startz`, then spawns every 1.85 seconds
- First spawn has no wait time, subsequent spawns use 1.85s interval

### Asset Organization

- `assets/coin/`: Coin model and materials
- `assets/snowy_road/`: Road segment assets
- `assets/sounds/`: Audio files
- `assets/stylized_lowpoly_char/`: Player character model
- `assets/stylized_rock/`: Rock obstacle models

### Scene Hierarchy

- `Levels/Level.tscn`: Main game scene with timers and spawn configuration
- `Player/Player.tscn`: Character with collision area, audio player, GUI, and game over panel
  - Contains CanvasLayer with gui Control node for HUD and game over overlay
  - Game over panel has VBoxContainer with score labels and restart button
- `Coins/Coin.tscn`: Collectible coin prefab
- `Levels/Rock/Rock.tscn`: Obstacle prefab (uses MovingObject.gd)
- `Levels/Road/Road.tscn`: Road segment prefab

## Key Implementation Notes

### Player Movement
- Player does NOT use Input.get_action_strength for movement - uses discrete lane switching only
- Input actions use "ui_left"/"ui_right"/"ui_up" (not the custom move_left/move_right defined in project.godot)
- Player is in "players" group for obstacle collision detection

### Game State
- Pause game via `get_tree().paused = true` when player dies
- Game over UI displays on death with score breakdown and restart button
- Score (coins + distance) displayed in real-time via `gui/label` node in Player scene
- High score is automatically saved when player dies and persists across sessions
- Restart reloads the current scene via `get_tree().reload_current_scene()`

### Signal Architecture
- MovingObject (rocks) emit `player_entered` signal
- Level connects to this signal via `rock_inst.player_entered.connect(on_player_entered_rock)`
- Player handles coin collection internally via Area3D collision, not signals
