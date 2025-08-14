# UNO Implementation and Debug Features

This document describes the UNO game implementation and debug features added to the Mixtape Engine Rework.

## UNO Game Features

### Enhanced CPU Support
- **Custom Color Support**: CPUs now intelligently handle custom colors in addition to standard UNO colors
- **Custom Action Card Intelligence**: CPUs evaluate custom action cards based on their `cpuImportance` rating
- **Improved Strategy**: CPUs consider custom colors when making wild card color choices
- **Difficulty Scaling**: All difficulty levels (Easy, Normal, Hard, Expert) work with custom elements

### Custom Colors and Cards
- **Custom Colors**: Support for any FlxColor with optional names (e.g., Purple, Orange, Pink, Cyan)
- **Custom Action Cards**: Create cards with custom names, point values, CPU importance, and action functions
- **Flexible Game Setup**: Mix custom colors/cards with standard UNO rules

### UNO Test State
- **Complete Game Implementation**: Full UNO game with 1 human player vs 3 CPU players
- **Interactive UI**: Click-to-play cards, color selection for wild cards, mouse/keyboard controls
- **Generated Assets**: Uses programmatically generated card graphics (no external assets required)
- **Custom Game Examples**: Includes example custom colors and action cards:
  - **Skip All**: Wild card that skips all other players
  - **Draw One**: Color-specific cards that make the next player draw one card

#### UNO Test Controls
- **ENTER**: Start new game
- **Mouse Click**: Select and play cards
- **D Key**: Draw a card
- **U Key**: Call UNO
- **ESCAPE**: Return to main menu

## Custom Action Cards

The UNO system supports custom action cards that can be added to the deck when creating a new game. Custom actions are executed when the card is played and can affect the game state in various ways.

### Creating Custom Action Cards

#### Basic Custom Action Card

```haxe
var customCard = UnoCard.createCustomActionCard(
    "Card Name",           // Display name
    UnoColor.RED,          // Card color (can be any UnoColor including WILD)
    25,                    // Point value for scoring (optional, default: 50)
    7,                     // CPU importance 1-10 (optional, default: 5)
    function(game:UnoGame) { // Action function (optional)
        // Your custom logic here
        trace("Custom action executed!");
    }
);
```

#### Multiple Copies

```haxe
var customCards = UnoCard.createCustomActionCards(
    "Skip All",           // Card name
    UnoColor.YELLOW,      // Color
    2,                    // Number of copies
    35,                   // Point value
    9,                    // CPU importance
    function(game:UnoGame) {
        // Skip all other players
        for (i in 0...(game.players.length - 1)) {
            game.turnManager.skipNextPlayer();
        }
    }
);
```

### Creating Games with Custom Cards

#### Simple Approach

```haxe
var customCards = [/* your custom cards */];
var game = UnoGame.createWithCustomActions(customCards);
```

#### Advanced Approach with Custom Colors

```haxe
var customColors = UnoCard.createCustomColors([
    FlxColor.PURPLE,
    FlxColor.ORANGE
], ["Purple", "Orange"]);

var customCards = [/* your custom cards */];

var game = UnoGame.createCustomGame({
    customColors: customColors,
    customCards: customCards,
    includeBaseColors: true  // Include standard Red, Blue, Green, Yellow
});
```

#### Manual Setup

```haxe
var game = new UnoGame();
game.setCustomCards(customCards);
game.setCustomColors(customColors);
// Or add individual cards:
game.addCustomCard(myCustomCard);
```

### Custom Action Function

The action function receives the `UnoGame` instance and can access:

- `game.players` - All players in the game
- `game.turnManager` - Current turn management
- `game.deck` - The deck and discard pile
- `game.currentColor` - Current active color
- `game.drawStack` - Current draw stack for stacking cards

#### Common Action Patterns

##### Making Players Draw Cards
```haxe
function(game:UnoGame) {
    var nextPlayer = game.turnManager.getNextPlayer();
    nextPlayer.drawCards(game.deck, 3);
}
```

##### Skipping Players
```haxe
function(game:UnoGame) {
    game.turnManager.skipNextPlayer(); // Skip one player
    // Or skip multiple players:
    for (i in 0...2) game.turnManager.skipNextPlayer();
}
```

##### Changing Turn Direction
```haxe
function(game:UnoGame) {
    game.turnManager.reverseTurn();
}
```

##### Affecting All Players
```haxe
function(game:UnoGame) {
    for (player in game.players) {
        player.drawCards(game.deck, 1);
    }
}
```

##### Swapping Hands
```haxe
function(game:UnoGame) {
    var player1 = game.turnManager.getCurrentPlayer();
    var player2 = game.turnManager.getNextPlayer();
    
    var tempHand = player1.hand.cards.copy();
    player1.hand.cards = player2.hand.cards.copy();
    player2.hand.cards = tempHand;
}
```

### Example Custom Cards

#### Swap Hands
```haxe
var swapHands = UnoCard.createCustomActionCard(
    "Swap Hands",
    UnoColor.WILD,
    30,
    8,
    function(game:UnoGame) {
        var current = game.turnManager.getCurrentPlayer();
        var next = game.turnManager.getNextPlayer();
        
        var temp = current.hand.cards.copy();
        current.hand.cards = next.hand.cards.copy();
        next.hand.cards = temp;
    }
);
```

#### Draw Until Match
```haxe
var drawUntilMatch = UnoCard.createCustomActionCard(
    "Draw Until Match",
    UnoColor.RED,
    25,
    6,
    function(game:UnoGame) {
        var nextPlayer = game.turnManager.getNextPlayer();
        var cardsDrawn = 0;
        var maxDraws = 5;
        
        while (cardsDrawn < maxDraws) {
            var card = game.deck.drawCard();
            nextPlayer.hand.addCard(card);
            cardsDrawn++;
            
            if (card.color == game.currentColor) break;
        }
    }
);
```

### CPU Importance Guidelines

- **1-3**: Low priority, situational cards
- **4-6**: Medium priority, generally useful cards  
- **7-9**: High priority, powerful cards
- **10**: Extremely high priority, game-changing cards

The AI will consider this value when deciding which cards to play from their hand.

### Safety Features

- **Null Action Check**: If no action function is provided, the card will be played without executing any custom logic
- **Game State Validation**: Actions are only executed when the game is in a valid state
- **Error Handling**: Custom actions should handle their own errors gracefully

## Debug State Menu

### Comprehensive State Browser
- **Auto-Discovery**: Automatically finds all states using the StatePick system
- **Categorized Display**: States grouped by type (Core, Editors, Games, Utility, etc.)
- **Search Functionality**: Real-time filtering with text search
- **State Information**: Shows class names, descriptions, and categories

### Features
- **Live Search**: Type to filter states in real-time
- **Category Organization**: States organized into logical groups
- **Error Handling**: Safe state switching with error messages for failures
- **State Descriptions**: Helpful descriptions for each discoverable state

#### Debug Menu Controls
- **Arrow Keys**: Navigate state list
- **Page Up/Down**: Fast navigation (10 items at a time)
- **ENTER**: Switch to selected state
- **BACKSPACE**: Clear search text
- **R Key**: Reload state list
- **Type Letters/Numbers**: Search for states
- **ESCAPE**: Return to main menu

### Access Points
- **Main Menu**: Press F3 or the debug_2 control
- **Master Editor Menu**: Select "Debug State Menu" option

## File Structure

```
source/
├── yutautil/games/uno/
│   ├── UnoCPU.hx              # Enhanced CPU with custom color/card support
│   ├── UnoGame.hx             # Updated to pass available colors to CPU
│   ├── UnoCard.hx             # Custom color and action card utilities
│   └── ... (other UNO files)
├── states/
│   ├── UnoTestState.hx        # Complete UNO game implementation
│   ├── DebugStateMenu.hx      # Debug state browser
│   └── MainMenuState.hx       # Updated with debug access
└── states/editors/
    └── MasterEditorMenu.hx    # Updated with UNO and debug access
```

## Best Practices

1. **Keep actions balanced** - Don't make cards too powerful
2. **Handle edge cases** - Check for empty decks, single players, etc.
3. **Provide visual feedback** - Use trace() or game events to inform players
4. **Test thoroughly** - Custom actions can affect game flow in unexpected ways
5. **Set appropriate CPU importance** - Higher values make AI players more likely to play the card

## Notes

- **No External Assets Required**: All UNO graphics are generated programmatically
- **Extensible Design**: Easy to add new custom colors and action cards
- **Debug-Friendly**: Debug menu helps developers access any state quickly
- **Safe State Switching**: Error handling prevents crashes from invalid states
- **Performance Optimized**: Efficient state discovery and management

The implementation provides a complete, playable UNO game with advanced customization options and comprehensive debugging tools for engine development.
