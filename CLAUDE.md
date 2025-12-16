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

**Note:** The game will pause when the player collides with an obstacle. Close the window to exit.

### Project Structure
- Main scene: `res://Levels/Level.tscn`
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

**Player System (Player/Player.gd)**
- `CharacterBody3D` with lane-based movement (not free movement)
- Lane switching uses `lerp()` for smooth transitions between discrete lanes
- Physics constants:
  - `MOVE_SPEED: 8.0` (lane switching speed)
  - `JUMP_VELOCITY: 8.0`
  - `GRAVITY: 24.0`
- Collision detection via `CollisionArea` that checks for coins group membership
- Death handled via `is_dead` flag set by Level when player collides with rocks

**Moving Objects Pattern (Levels/MovingObject.gd)**
- Base pattern for obstacles (rocks) that move toward player
- All moving objects:
  - Move forward via `global_translate(Vector3(0, 0, 0.25))` in `_process()`
  - Auto-destroy after 5 seconds via internal Timer
  - Emit `player_entered` signal on collision with player group

**Collectibles (Coins/Coin.gd)**
- Inherit same timer-based destruction pattern as MovingObject
- Self-rotate via `rotate_y(5 * delta)`
- Must be in "coins" group for player collision detection
- Move forward and destroy after 5 seconds

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
- `Player/Player.tscn`: Character with collision area, audio player, and GUI
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
- No restart/game over UI implemented - game simply pauses
- Coin count displayed via `gui/label` node in Player scene

### Signal Architecture
- MovingObject (rocks) emit `player_entered` signal
- Level connects to this signal via `rock_inst.player_entered.connect(on_player_entered_rock)`
- Player handles coin collection internally via Area3D collision, not signals
