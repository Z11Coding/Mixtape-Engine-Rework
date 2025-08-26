# Archipelago Trap Games System

This system provides Archipelago trap games that can be triggered when the player receives certain trap items. When the player loses these games, they are forced to die in the main game.

## Architecture

### Trap Game Implementation
The trap games extend the existing main game states and modify their behavior:
- **APPongTrapState** extends **PongGameState**
- **APUnoTrapState** extends **UnoTestState**

This approach prevents code duplication and ensures trap games stay updated with main game improvements.

### TrapDeathHandler
Utility class that handles forcing the boyfriend to die by:
- Finding the active PlayState instance
- Calling the boyfriend's kill() method
- Switching to GameOverSubstate with custom return state

### Available Trap Games

#### APPongTrapState
- **Base Class**: Extends PongGameState
- **Win Condition**: Score 5 points before the AI
- **Controls**: W/S keys to control paddle
- **Modifications**: Disables escape, overrides game end behavior, adds warning UI
- **Visual**: Red warning theme overlay on existing Pong visuals

#### APUnoTrapState
- **Base Class**: Extends UnoTestState
- **Win Condition**: Win the UNO round
- **Controls**: Same as main UNO game
- **Modifications**: Disables escape, overrides game end behavior, adds warning UI
- **Visual**: Dark theme overlay on existing UNO visuals

## Usage Examples

### Basic Usage
```haxe
import archipelago.traps.TrapGameManager;

// Launch pong trap
TrapGameManager.launchPongTrap(PlayState.instance);

// Launch UNO trap
TrapGameManager.launchUnoTrap(PlayState.instance);
```

### Integration with Archipelago Items
The trap games are automatically registered in APItem.hx:
```haxe
case "Pong Challenge":
    return new APTrap(name, ConditionHelper.Everywhere(), function() {
        popup('Score 5 points to survive!', "APItem: Pong Challenge", true);
        TrapGameManager.launchPongTrap(states.PlayState.instance);
    }, true, false);

case "UNO Challenge":
    return new APTrap(name, ConditionHelper.Everywhere(), function() {
        popup('Win the round to survive!', "APItem: UNO Challenge", true);
        TrapGameManager.launchUnoTrap(states.PlayState.instance);
    }, true, false);
```

### How Trap Behavior Works

The main game states check if they're being extended by trap versions:

**In PongGameState.hx:**
```haxe
// Handle global controls (unless it's the trap version)
if (Type.getClassName(Type.getClass(this)) != "archipelago.traps.games.APPongTrapState") {
    if (controls.BACK) {
        FlxG.mouse.visible = false;
        MusicBeatState.switchState(new MainMenuState());
    }
}
```

**In APPongTrapState.hx:**
```haxe
override function update(elapsed:Float) {
    // Check for this specific class to disable escape
    if (Type.getClass(this) == APPongTrapState) {
        // Override escape key - don't allow exit until win/lose
        if (FlxG.keys.justPressed.ESCAPE) {
            updateInstructionText("NO ESCAPE! You must win or die!");
            return;
        }
    }
    // ... rest of update logic
}
```

## Death System Integration

The trap games integrate with the existing GameOverSubstate system:
- On loss, TrapDeathHandler.forceDeath() is called with the previous state
- TrapDeathHandler finds boyfriend in PlayState and passes it to GameOverSubstate
- GameOverSubstate loads with the trap's previous state as return target
- Player can retry from the same point they were trapped

## Files Structure

```
source/archipelago/traps/
├── BaseTrapGameState.hx       # Base class for scripted trap games
├── TrapDeathHandler.hx        # Handles forced death mechanics
├── TrapGameManager.hx         # Manager for launching trap games
└── games/
    ├── APPongTrapState.hx     # Pong trap (extends PongGameState)
    └── APUnoTrapState.hx      # UNO trap (extends UnoTestState)
```

## Benefits of This Architecture

1. **No Code Duplication**: Trap games inherit all functionality from main games
2. **Automatic Updates**: When main games are improved, trap games get the benefits
3. **Minimal Modification**: Main games only need small checks to prevent escape in trap mode
4. **Clean Separation**: Trap-specific behavior is contained in the trap classes
5. **Extensible**: Easy to add new trap games by extending existing game states

## Creating New Trap Games

To create a new trap game:

1. **Extend an existing game state:**
```haxe
class APMyGameTrapState extends MyGameState {
    private var previousState:MusicBeatState;

    public function new(?previousState:MusicBeatState = null) {
        this.previousState = previousState;
        super();
    }

    override function create() {
        super.create();
        // Add trap modifications
    }

    override function update(elapsed:Float) {
        // Disable escape for this specific trap class
        if (Type.getClass(this) == APMyGameTrapState) {
            if (FlxG.keys.justPressed.ESCAPE) {
                return; // Trap the player!
            }
        }
        super.update(elapsed);
    }
}
```

2. **Modify the base game state to allow trap behavior:**
```haxe
// In MyGameState.update():
if (Type.getClassName(Type.getClass(this)) != "archipelago.traps.games.APMyGameTrapState") {
    if (controls.BACK) {
        // Normal exit behavior
    }
}
```

3. **Register the trap game:**
```haxe
TrapGameManager.registerTrapGame("mygame", APMyGameTrapState);
```

4. **Add to APItem.hx:**
```haxe
case "My Game Challenge":
    return new APTrap(name, ConditionHelper.Everywhere(), function() {
        TrapGameManager.launchTrapGame("mygame", states.PlayState.instance);
    }, true, false);
```
