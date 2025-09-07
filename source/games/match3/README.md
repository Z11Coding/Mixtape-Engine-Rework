# Match 3 Game

A comprehensive Match 3 puzzle game implementation for the Mixtape Engine, featuring multiple game modes, objectives, and power-ups.

## Features

### Game Modes
- **Classic**: Standard Match 3 with objectives
- **Timed**: Race against the clock
- **Limited Moves**: Solve puzzles with restricted moves
- **VS CPU**: Player vs AI opponent
- **Obstacles**: Clear obstacles by matching nearby pieces

### Power-ups and Special Pieces
- **Horizontal Stripe**: Created by matching 4 pieces horizontally, clears entire row
- **Vertical Stripe**: Created by matching 4 pieces vertically, clears entire column
- **Bomb**: Created by matching 5+ pieces, clears 3x3 area
- **Color Bomb**: Created by matching 5 pieces, clears all pieces of a color
- **Rainbow**: Special piece that can match with any color

### Piece Types
- **Basic Pieces**: Standard colored pieces (Red, Blue, Green, Yellow, Purple, Orange)
- **Character Icons**: Uses character icons from the base game or mods
- **Obstacles**: Blocks that need to be cleared by matching adjacent pieces
- **Power-ups**: Special pieces with unique abilities

### Objectives System
Multiple objective types supported:
- Score targets
- Clear specific colors
- Remove obstacles
- Collect certain piece types
- Create special pieces
- Survive turns (VS mode)
- Cascade matches

## Architecture

### Backend Classes

#### `Match3Piece`
Represents individual pieces on the board with properties for:
- Type (Basic, Icon, Obstacle, Power-up)
- Color
- Position
- Special abilities

#### `Match3Board`
Manages the game grid including:
- Piece placement and movement
- Match detection (horizontal and vertical)
- Gravity simulation
- Power-up activation
- Cascade handling

#### `Match3Game`
Main game controller that handles:
- Game state management
- Turn-based logic
- Score tracking
- Objective progress
- Animation coordination

#### `Match3Objective`
Defines and tracks various game objectives:
- Progress tracking
- Completion detection
- Contribution calculation

#### `Match3CPU`
AI opponent for VS mode with:
- Multiple difficulty levels
- Move evaluation
- Strategic thinking
- Cascade prediction

### UI Components

#### `Match3TestState`
Main game state providing:
- Visual grid display
- Interactive piece selection
- Objective tracking
- Score display
- Game mode selection

## Usage

To access the Match 3 game, add it to your main menu or call:

```haxe
FlxG.switchState(new games.match3.Match3TestState());
```

### Creating Custom Objectives

```haxe
var objectives = [
    new Match3Objective(SCORE(1000), 1000, "Score 1,000 points"),
    new Match3Objective(CLEAR_COLOR(FlxColor.RED, 20), 20, "Clear 20 red pieces"),
    new Match3Objective(CLEAR_OBSTACLES(5), 5, "Clear 5 obstacles")
];

match3Game.initialize(objectives);
```

### Using Character Icons

The game can use character icons from your game or mods:

```haxe
var iconList = ["bf", "dad", "gf", "pico"]; // Character names
match3Game.initialize(objectives, iconList);
```

## Game Flow

1. **Initialization**: Set up board, objectives, and game mode
2. **Player Input**: Click and drag or click-to-select pieces
3. **Move Validation**: Check if swap creates valid matches
4. **Match Processing**: Remove matched pieces, award points
5. **Power-up Creation**: Generate special pieces for large matches
6. **Gravity**: Make pieces fall to fill empty spaces
7. **Cascade Detection**: Check for new matches after falling
8. **Objective Updates**: Progress tracking and completion checking
9. **Turn Management**: Switch players in VS mode
10. **Game Over**: Check win/lose conditions

## Customization

### Adding New Piece Types
Extend the `Match3PieceType` enum and update match logic in `Match3Piece.canMatchWith()`.

### Creating New Power-ups
Add to the `SpecialType` enum and implement activation logic in `Match3Board.activatePowerUp()`.

### New Game Modes
Extend the `GameMode` enum and add mode-specific logic in `Match3Game`.

### Custom Objectives
Extend the `ObjectiveType` enum and implement checking logic in `Match3Objective.checkContribution()`.

## Integration

The Match 3 game follows the same pattern as other games in the Mixtape Engine:
- Backend classes handle game logic
- State classes provide UI and user interaction
- Modular design allows easy integration and customization

The game integrates with the existing asset system and can use character icons, fonts, and other resources from the base game or loaded mods.
