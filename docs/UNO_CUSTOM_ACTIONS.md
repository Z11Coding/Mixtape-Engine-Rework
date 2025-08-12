# UNO Custom Action Cards

This document explains how to create and use custom action cards in the UNO system.

## Overview

The UNO system now supports custom action cards that can be added to the deck when creating a new game. Custom actions are executed when the card is played and can affect the game state in various ways.

## Creating Custom Action Cards

### Basic Custom Action Card

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

### Multiple Copies

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

## Creating Games with Custom Cards

### Simple Approach

```haxe
var customCards = [/* your custom cards */];
var game = UnoGame.createWithCustomActions(customCards);
```

### Advanced Approach with Custom Colors

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

### Manual Setup

```haxe
var game = new UnoGame();
game.setCustomCards(customCards);
game.setCustomColors(customColors);
// Or add individual cards:
game.addCustomCard(myCustomCard);
```

## Custom Action Function

The action function receives the `UnoGame` instance and can access:

- `game.players` - All players in the game
- `game.turnManager` - Current turn management
- `game.deck` - The deck and discard pile
- `game.currentColor` - Current active color
- `game.drawStack` - Current draw stack for stacking cards

### Common Action Patterns

#### Making Players Draw Cards
```haxe
function(game:UnoGame) {
    var nextPlayer = game.turnManager.getNextPlayer();
    nextPlayer.drawCards(game.deck, 3);
}
```

#### Skipping Players
```haxe
function(game:UnoGame) {
    game.turnManager.skipNextPlayer(); // Skip one player
    // Or skip multiple players:
    for (i in 0...2) game.turnManager.skipNextPlayer();
}
```

#### Changing Turn Direction
```haxe
function(game:UnoGame) {
    game.turnManager.reverseTurn();
}
```

#### Affecting All Players
```haxe
function(game:UnoGame) {
    for (player in game.players) {
        player.drawCards(game.deck, 1);
    }
}
```

#### Swapping Hands
```haxe
function(game:UnoGame) {
    var player1 = game.turnManager.getCurrentPlayer();
    var player2 = game.turnManager.getNextPlayer();
    
    var tempHand = player1.hand.cards.copy();
    player1.hand.cards = player2.hand.cards.copy();
    player2.hand.cards = tempHand;
}
```

## Safety Features

- **Null Action Check**: If no action function is provided, the card will be played without executing any custom logic
- **Game State Validation**: Actions are only executed when the game is in a valid state
- **Error Handling**: Custom actions should handle their own errors gracefully

## Example Custom Cards

### Swap Hands
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

### Draw Until Match
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

## Best Practices

1. **Keep actions balanced** - Don't make cards too powerful
2. **Handle edge cases** - Check for empty decks, single players, etc.
3. **Provide visual feedback** - Use trace() or game events to inform players
4. **Test thoroughly** - Custom actions can affect game flow in unexpected ways
5. **Set appropriate CPU importance** - Higher values make AI players more likely to play the card

## CPU Importance Guidelines

- **1-3**: Low priority, situational cards
- **4-6**: Medium priority, generally useful cards  
- **7-9**: High priority, powerful cards
- **10**: Extremely high priority, game-changing cards

The AI will consider this value when deciding which cards to play from their hand.
