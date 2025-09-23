# Stealth Maze Game

A stealth-based maze game where players must navigate randomly generated mazes while avoiding enemies with vision cones.

## Game Features

### Core Mechanics
- **Stealth Movement**: Move carefully to avoid enemy detection
- **Vision Cones**: Both player and enemies have directional vision
- **Collectible System**: Red squares create a "tail" that follows the player
- **Hiding System**: Use closets to hide from enemies (with different capacity rules)
- **Multi-Floor Progression**: Navigate through multiple maze floors

### Game Objects
- **Cyan Square**: The player character
- **Purple Squares**: AI enemies with patrol patterns and vision cones
- **Red Squares**: Objective collectibles that must be gathered
- **Golden Squares**: Bonus collectibles for extra points
- **Brown Squares**: Closets for hiding (1-person and 2-person variants)
- **Green Squares**: Exit tiles (activated after collecting red objective)

### Difficulty Levels
- **Easy**: Smaller mazes, fewer enemies, longer detection times
- **Medium**: Balanced gameplay with moderate challenge
- **Hard**: Large mazes, more enemies, quick detection and aggressive AI

## File Structure

```
/stealthmaze/
├── StealthMazeGameState.hx        # Main game state
├── StealthMazeMinigameState.hx    # Demo/preview state with simulated gameplay
├── APStealthMazeTrapState.hx      # Archipelago trap integration
├── StealthMazeLauncher.hx         # Utility launcher class
├── StealthMazeIndex.hx            # Index/access utility
├── /backend/
│   ├── MazeData.hx                # Core data structures and enums
│   ├── MazeGenerator.hx           # Procedural maze generation
│   └── MazePathfinder.hx          # A* pathfinding for AI
└── /objects/
    ├── MazePlayer.hx              # Player character with stealth mechanics
    ├── MazeEnemy.hx               # AI enemies with state machine
    └── MazeObjects.hx             # Collectibles, closets, and exits
```

## Usage

### Launch Minigame Demo
```haxe
StealthMazeLauncher.launchMinigame();
```

### Launch Full Game
```haxe
// Default difficulty (Medium)
StealthMazeLauncher.launch();

// Specific difficulty
StealthMazeLauncher.launchWithDifficulty(HARD);

// Quick launch methods
StealthMazeLauncher.launchEasy();
StealthMazeLauncher.launchMedium();
StealthMazeLauncher.launchHard();
```

### Archipelago Integration
```haxe
// Launch as AP trap with custom settings
StealthMazeLauncher.launchAPTrap(MEDIUM, 300.0); // 5 minutes

// Predefined AP trap configurations
StealthMazeLauncher.launchAPTrapEasy();  // 3 minutes, easy difficulty
StealthMazeLauncher.launchAPTrapHard();  // 10 minutes, hard difficulty
```

## Controls

- **WASD / Arrow Keys**: Move player
- **Shift**: Sprint (generates more noise, detected easier)
- **E / Space**: Interact with closets (hide/exit)
- **Escape**: Pause game (not available in AP trap mode)

## Stealth Mechanics

### Player Stealth
- Moving generates noise that enemies can hear
- Sprinting generates more noise and extends detection range
- Vision cone shows where player can see
- Tail segments follow behind player after collecting objectives

### Enemy AI States
1. **Patrol**: Normal movement along set paths
2. **Investigate**: Moving to check a suspicious location
3. **Chase**: Actively pursuing the player
4. **Search**: Looking for player after losing sight

### Hiding System
- **1-Person Closets**: Hide completely (including tail segments)
- **2-Person Closets**: Hide player but tail remains visible
- Interact with closets using E or Space key
- Cannot hide if closet is already occupied

## Archipelago Integration

The `APStealthMazeTrapState` extends the main game with:
- Timer-based trap duration
- Integration with `TrapDeathHandler.forceDeath()`
- No pause functionality (traps cannot be paused)
- Automatic return to main menu on completion/failure

## Technical Implementation

### Architecture
- Built on Mixtape-Engine-Rework framework
- Extends `MusicBeatState` for consistency
- Uses FlxSprite-based entity system
- Implements FlxTween for smooth animations

### AI System
- State machine pattern for enemy behavior
- A* pathfinding for intelligent navigation
- Line-of-sight checking for vision detection
- Sound-based detection system

### Maze Generation
- Recursive backtracking algorithm
- Room-based generation with corridors
- Dynamic entity placement based on difficulty
- Multi-floor progression system
