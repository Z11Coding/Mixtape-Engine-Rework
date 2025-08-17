# UNO Game System

A complete implementation of the UNO card game in Haxe, located in `yutautil/games/uno/`.

## Features

### Core Components

- **UnoCard**: Represents individual UNO cards with colors, types, and values
- **UnoDeck**: Manages the deck of cards with shuffling and dealing
- **UnoHand**: Represents a player's hand with card management (supports infinite capacity when maxHandSize = 0)
- **UnoPlayer**: Base player class with hand management and game actions
- **UnoCPU**: AI player with multiple difficulty levels
- **UnoTurnManager**: Handles turn order and direction changes
- **UnoGame**: Main game controller that manages the complete game flow
- **UnoRules**: Implements special UNO rules and game logic

### Special Rules Supported

- **Card Stacking**: Allow stacking of Draw Two and Wild Draw Four cards
- **Jump In**: Allow players to jump in with exact card matches
- **Force Play**: Option to force players to play if they have a playable card
- **Seven-Zero Rule**: Special effects for 7 and 0 number cards
- **Wild Draw Four Challenge**: Challenge illegal Wild Draw Four plays
- **UNO Penalties**: Penalty for not calling UNO
- **Progressive UNO**: Advanced UNO calling rules

### CPU Difficulty Levels

- **Easy**: Random card selection, sometimes forgets to call UNO
- **Normal**: Basic strategy, prefers action cards
- **Hard**: Strategic play, considers opponent hands
- **Expert**: Advanced AI with card evaluation and optimal play

## Usage

### Basic Game Setup

```haxe
// Create a new game
var game = new UnoGame();

// Add players
var human = new UnoPlayer("p1", "Alice", true);
var cpu = new UnoCPU("cpu1", "Bob", NORMAL);

game.addPlayer(human);
game.addPlayer(cpu);

// Start the game
game.startGame();
```

### Playing Cards

```haxe
// Get playable cards for current player
var playableCards = game.getCurrentPlayerPlayableCards();

if (playableCards.length > 0) {
    // Play the first playable card
    var cardIndex = 0; // Index in player's hand
    var chosenColor = RED; // For wild cards
    
    game.playCard(game.turnManager.getCurrentPlayer(), cardIndex, chosenColor);
}
```

### Event Handling

```haxe
// Set up event listeners
game.onCardPlayed = function(player:UnoPlayer, card:UnoCard) {
    trace('${player.name} played: ${card.toString()}');
};

game.onUnoCall = function(player:UnoPlayer) {
    trace('${player.name} called UNO!');
};

game.onRoundEnd = function(winner:UnoPlayer, points:Int) {
    trace('${winner.name} won and scored $points points!');
};
```

### Custom Rules

```haxe
// Configure custom rules before starting
UnoRules.setCustomRules(
    true,  // Allow stacking
    false, // No jump in
    false, // No force play
    true,  // Seven-zero rule
    true,  // Wild challenge
    500    // Winning score
);
```

## Card Types

### Number Cards (0-9)
- Available in Red, Blue, Green, Yellow
- Card 0 appears once per color
- Cards 1-9 appear twice per color

### Action Cards
- **Skip**: Skip the next player's turn
- **Reverse**: Reverse the direction of play
- **Draw Two**: Next player draws 2 cards and loses their turn

### Wild Cards
- **Wild**: Change the color of play
- **Wild Draw Four**: Change color and next player draws 4 cards

## Game Flow

1. **Setup**: Deal 7 cards to each player
2. **First Card**: Draw a non-action card for the discard pile
3. **Turns**: Players take turns playing matching cards or drawing
4. **UNO Call**: Player must call UNO when down to one card
5. **Round End**: First player to empty their hand wins the round
6. **Scoring**: Winner scores points equal to sum of other players' hands
7. **Game End**: First player to reach target score (default 500) wins

## API Reference

### UnoGame Methods

- `addPlayer(player:UnoPlayer)`: Add a player to the game
- `startGame()`: Start a new game
- `playCard(player, cardIndex, chosenColor)`: Play a card
- `drawCards(player, count)`: Draw cards
- `callUno(player)`: Call UNO
- `challengeWildDrawFour(challenger)`: Challenge a Wild Draw Four
- `getGameStatus()`: Get current game status string

### UnoPlayer Methods

- `drawCards(deck, count)`: Draw cards from deck
- `playCard(cardIndex, deck)`: Play a card
- `getPlayableCards(topCard)`: Get cards that can be played
- `callUno()`: Call UNO
- `hasWon()`: Check if player won the round

### UnoCPU Methods

- `chooseCard(topCard, gameState)`: AI chooses which card to play
- `chooseWildColor()`: AI chooses color for wild cards
- `shouldChallenge(previousPlayer, topCard)`: AI decides whether to challenge

### UnoHand Methods

- `new(maxHandSize)`: Create a new hand (maxHandSize = 0 for infinite capacity)
- `addCard(card)`: Add a card to the hand
- `addCards(cards)`: Add multiple cards to the hand
- `removeCardAt(index)`: Remove a card by index
- `getPlayableCards(topCard)`: Get cards that can be played
- `getSize()`: Get number of cards in hand
- `isEmpty()`: Check if hand is empty
- `isUno()`: Check if hand has exactly one card

## Example Usage

See `UnoExample.hx` for complete examples including:
- Basic game setup
- Event handling
- Game simulation
- Testing individual components

```haxe
// Run a complete simulation
UnoExample.simulateGame();

// Test individual components
UnoExample.testCards();
UnoExample.testPlayers();
```

## Integration

To use the UNO system in your project:

1. Import the main game class: `import yutautil.games.uno.UnoGame;`
2. Create players and add them to the game
3. Set up event handlers for game feedback
4. Start the game and handle player input
5. Use the game's methods to process player actions

The system is designed to be flexible and can be integrated into various UI frameworks or game engines.
