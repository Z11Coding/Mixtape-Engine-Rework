# Pong Game - YutaUtil Games

A complete Pong game implementation for the Mixtape Engine, located in the yutautil games folder.

## Features

### Game Modes
- **Player vs AI**: Single player against computer opponent
- **Two Player**: Local multiplayer (Player 1 vs Player 2)
- **AI vs AI**: Watch two AI opponents compete

### AI Difficulty Levels
- **Easy**: Slower reaction time, less accurate
- **Normal**: Balanced AI performance
- **Hard**: Quick reactions, high accuracy
- **Expert**: Near-perfect AI with predictive capabilities

### Game Features
- Classic Pong physics with realistic ball bouncing
- Ball speed increases with each paddle hit
- Visual ball trail effect
- Score tracking with customizable win conditions
- Pause/resume functionality
- Sound effects for game events
- Smooth paddle controls with velocity-based ball interaction

## Controls

### Player 1 (Left Paddle)
- **W**: Move paddle up
- **S**: Move paddle down

### Player 2 (Right Paddle)
- **Up Arrow**: Move paddle up
- **Down Arrow**: Move paddle down

### Game Controls
- **Enter**: Start new game
- **P**: Pause/Resume game
- **M**: Open menu/options
- **Escape**: Return to main menu

## Usage Examples

### Basic Usage
```haxe
import yutautil.games.pong.PongGameState;

// Launch Pong game directly
FlxG.switchState(new PongGameState());
```

### Using the Example Launcher
```haxe
import yutautil.games.pong.PongExample;

// Simple launch
PongExample.launchCustomPong();
```

### Customizing Game Settings
```haxe
import yutautil.games.pong.PongOptionsSubState;

var options = new PongOptionsSubState();
options.maxScore = 15;
options.gameMode = TWO_PLAYER;
options.aiDifficulty = EXPERT;
// Apply settings...
```

## File Structure

```
yutautil/games/pong/
├── backend/
│   ├── PongBall.hx          # Ball physics and behavior
│   ├── PongPaddle.hx        # Paddle controls and AI
│   ├── PongGame.hx          # Core game logic
│   └── PongSounds.hx        # Sound effect management
├── PongGameState.hx         # Main game state with UI
├── PongOptionsSubState.hx   # Settings and options menu
├── PongExample.hx           # Usage examples
└── README.md               # This file
```

## Backend Classes

### PongBall
Handles ball physics including:
- Position and velocity tracking
- Collision detection
- Bounce calculations with realistic physics
- Speed management and acceleration

### PongPaddle
Manages paddle behavior:
- Player input handling
- AI decision making with multiple difficulty levels
- Collision detection with ball
- Velocity-based ball interaction

### PongGame
Core game logic:
- Game state management (rounds, scoring, win conditions)
- Turn-based gameplay flow
- Event system for UI callbacks
- Game mode switching

### PongSounds
Centralized sound effect management:
- Paddle hit sounds
- Wall bounce effects
- Scoring notifications
- Game start/end audio

## Customization

### Adding Custom Game Modes
Extend the `PongGameMode` enum and modify the game logic in `PongGame.hx`:

```haxe
// Add to PongGameMode enum
enum PongGameMode {
    // ... existing modes
    CUSTOM_MODE;
}

// Handle in game setup
switch (gameMode) {
    case CUSTOM_MODE:
        // Custom game logic
}
```

### Modifying AI Behavior
Adjust AI parameters in `PongPaddle.hx`:

```haxe
// In updateAISettings()
case CUSTOM:
    aiReactionTime = 0.1;
    aiAccuracy = 0.9;
    aiPrediction = 0.8;
```

### Visual Customization
Modify sprites and effects in `PongGameState.hx`:

```haxe
// Custom ball appearance
ballSprite.makeGraphic(size, size, FlxColor.CYAN);

// Custom paddle colors
leftPaddleSprite.makeGraphic(width, height, FlxColor.GREEN);
```

## Integration Notes

- Follows the same pattern as other games in the yutautil folder
- Uses existing engine sound assets for effects
- Compatible with the engine's state management system
- Handles Discord Rich Presence integration
- Memory management with proper cleanup

## Performance

- Optimized for 60 FPS gameplay
- Efficient collision detection
- Minimal memory allocation during gameplay
- Smooth visual effects with proper tweening

## Dependencies

- HaxeFlixel core libraries
- Mixtape Engine backend systems
- Existing engine UI components (PsychUIButton)
- Engine sound and asset management (Paths)
