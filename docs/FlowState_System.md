# FlowState System Documentation

The FlowState system provides a comprehensive framework for creating smooth state transitions with built-in animation support in your Haxe/HaxeFlixel game. Instead of extending `MusicBeatState` directly, you should extend `BaseFlowState` for most game states.

## Core Components

### 1. FlowState
The main state manager that handles transitions between `BaseFlowState` instances. It acts as an intermediary state that manages smooth animations and transitions.

**Key Features:**
- Manages transition animations between states
- Handles both FlowSprites and regular FlxSprites
- Provides callbacks for transition completion
- Can transition to regular FlxStates when exiting the FlowState system

### 2. BaseFlowState
The replacement for extending `MusicBeatState` normally. This is what you should extend when creating states for this game.

**Key Features:**
- Automatic enter/exit animation management
- Support for both FlowSprites and regular FlxSprites
- Built-in sprite management with arrays
- Customizable create() method for state setup

### 3. FlowSprite
Enhanced sprite class with built-in enter/exit animations and tweens.

**Key Features:**
- Built-in animation and tween support
- Method chaining for easy setup
- Helper methods for common animations (fade, slide, scale)
- Automatic animation cleanup on destroy

### 4. FlowAnimation
Flexible animation system that can handle tweens, sprite animations, delays, and custom functions.

**Key Features:**
- Support for FlxTween-based animations
- Sprite animation support with frame/completion waiting
- Delay animations
- Custom function animations
- Static helper methods for common animations

### 5. FlowSpriteManager
Utility class for managing animations on regular FlxSprites.

**Key Features:**
- Add enter/exit animations to any FlxSprite
- Helper methods for common animations
- Automatic cleanup
- Combined animation support

## Usage Examples

### Basic State Creation

```haxe
class MyGameState extends BaseFlowState {
    private var background:FlowSprite;
    private var titleText:FlxText;
    private var button:FlowSprite;

    override public function create():Void {
        super.create();

        // Create background with animations
        background = new FlowSprite(0, 0);
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
        background.fadeIn(1.0).fadeOut(0.8);
        addFlowSprite(background);

        // Create regular text with custom animations
        titleText = new FlxText(0, 100, FlxG.width, "My Game", 32);
        titleText.alignment = CENTER;
        FlowSpriteManager.addEnterAnimation(titleText, FlowSpriteManager.createFadeIn(0.6));
        FlowSpriteManager.addExitAnimation(titleText, FlowSpriteManager.createSlideOut("top", 200));
        addSprite(titleText);

        // Create button with chained animations
        button = new FlowSprite(100, 300);
        button.makeGraphic(200, 50, FlxColor.GREEN);
        button.scaleIn(0.5).slideOutTo("bottom", 300, 0.4);
        addFlowSprite(button);
    }
}
```

### Creating and Using FlowState

```haxe
// Create initial state
var myState = new MyGameState();
var flowState = new FlowState(myState);

// Switch to this state
MusicBeatState.switchState(flowState);

// Later, transition to another state
var nextState = new AnotherGameState();
FlowState.instance.transitionTo(nextState, function() {
    trace("Transition completed!");
});

// Exit FlowState system and go to regular state
FlowState.instance.transitionToFlxState(new MainMenuState());
```

### Advanced FlowSprite Usage

```haxe
var sprite = new FlowSprite(100, 100);
sprite.loadGraphic("assets/images/mysprite.png");

// Chain multiple enter animations
sprite.fadeIn(0.5)
      .scaleIn(0.6)
      .addEnterAnimation(FlowAnimation.createDelay(0.2))
      .addEnterAnimation(FlowAnimation.createCustom(function(spr:FlxSprite, callback:Void->Void) {
          // Custom bounce animation
          FlxTween.tween(spr, {y: spr.y - 20}, 0.3, {
              type: PINGPONG,
              onComplete: function(t) callback()
          });
      }));

// Chain exit animations
sprite.fadeOut(0.4)
      .slideOutTo("right", 300, 0.5);

addFlowSprite(sprite);
```

### Regular FlxSprite with Animations

```haxe
var regularSprite = new FlxSprite(200, 200);
regularSprite.loadGraphic("assets/images/regular.png");

// Add animations using FlowSpriteManager
FlowSpriteManager.addEnterAnimation(regularSprite, FlowSpriteManager.createCombined([
    FlowSpriteManager.createFadeIn(0.5),
    FlowSpriteManager.createScaleIn(0.5)
]));

FlowSpriteManager.addExitAnimation(regularSprite, FlowSpriteManager.createSlideOut("left", 400, 0.6));

addSprite(regularSprite);
```

### Custom FlowAnimation Examples

```haxe
// Create a complex custom animation
var customAnim = FlowAnimation.createCustom(function(sprite:FlxSprite, callback:Void->Void) {
    // First tween
    FlxTween.tween(sprite, {alpha: 0.5}, 0.3, {
        onComplete: function(t) {
            // Second tween
            FlxTween.tween(sprite.scale, {x: 1.2, y: 1.2}, 0.2, {
                type: PINGPONG,
                onComplete: function(t2) callback()
            });
        }
    });
});

sprite.addEnterAnimation(customAnim);

// Static helper animations
sprite.addEnterAnimation(FlowAnimation.fadeIn(0.8, FlxEase.elasticOut));
sprite.addExitAnimation(FlowAnimation.scale(1, 1, 0, 0, 0.4, FlxEase.backIn));
```

## Best Practices

1. **Always call super.create()** in your BaseFlowState create() method
2. **Use FlowSprites** for sprites that need complex animations
3. **Use regular FlxSprites with FlowSpriteManager** for simpler sprites or when working with existing code
4. **Chain animations** using method chaining for cleaner code
5. **Use callbacks** for transition completion when you need to trigger events
6. **Clean up properly** - the system handles most cleanup automatically, but be aware of external references

## Animation Timing

The system ensures all animations complete before transitioning states. Enter animations play when a state becomes active, and exit animations play when transitioning away from a state.

- Enter animations: `fadeIn()`, `scaleIn()`, `slideInFrom()`
- Exit animations: `fadeOut()`, `scaleOut()`, `slideOutTo()`
- Custom timing: Use `FlowAnimation.createDelay()` for precise timing

## Transition Flow

1. **Exit Current State**: All sprites play their exit animations
2. **Cleanup**: Current state is removed and destroyed
3. **Enter New State**: New state is added and enter animations play
4. **Completion**: Transition callbacks are executed

This creates smooth, visually appealing transitions between different game states while maintaining clean code organization.
