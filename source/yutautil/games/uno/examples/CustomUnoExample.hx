package yutautil.games.uno.examples;

import yutautil.games.uno.UnoGame;
import yutautil.games.uno.UnoCard;
import yutautil.games.uno.UnoCard.UnoColor;
import yutautil.games.uno.UnoPlayer;
import flixel.util.FlxColor;

/**
 * Example showing how to create and use custom action cards in UNO
 */
class CustomUnoExample {
    
    /**
     * Create a UNO game with custom action cards
     */
    public static function createCustomUnoGame():UnoGame {
        // Create some custom action cards
        var customCards = [];
        
        // Example 1: "Swap Hands" card - players swap their entire hands
        var swapHandsCard = UnoCard.createCustomActionCard(
            "Swap Hands", 
            UnoColor.WILD, 
            30, // Point value
            8,  // CPU importance (higher = more likely to play)
            function(game:UnoGame) {
                var currentPlayer = game.turnManager.getCurrentPlayer();
                var nextPlayer = game.turnManager.getNextPlayer();
                
                // Swap the hands
                var tempHand = currentPlayer.hand.cards.copy();
                currentPlayer.hand.cards = nextPlayer.hand.cards.copy();
                nextPlayer.hand.cards = tempHand;
                
                trace('${currentPlayer.name} and ${nextPlayer.name} swapped hands!');
            }
        );
        customCards.push(swapHandsCard);
        
        // Example 2: "Draw Until Match" card - next player draws until they get a matching color
        var drawUntilMatchCard = UnoCard.createCustomActionCard(
            "Draw Until Match",
            UnoColor.RED,
            25,
            6,
            function(game:UnoGame) {
                var nextPlayer = game.turnManager.getNextPlayer();
                var cardsDrawn = 0;
                var maxDraws = 5; // Prevent infinite loops
                
                while (cardsDrawn < maxDraws) {
                    var drawnCard = game.deck.drawCard();
                    nextPlayer.hand.addCard(drawnCard);
                    cardsDrawn++;
                    
                    if (drawnCard.color == game.currentColor) {
                        break;
                    }
                }
                
                trace('${nextPlayer.name} drew $cardsDrawn cards until matching ${game.currentColor}!');
            }
        );
        customCards.push(drawUntilMatchCard);
        
        // Example 3: "Color Chaos" card - everyone draws a card and current color changes randomly
        var colorChaosCard = UnoCard.createCustomActionCard(
            "Color Chaos",
            UnoColor.WILD,
            40,
            7,
            function(game:UnoGame) {
                // Everyone draws a card
                for (player in game.players) {
                    player.drawCards(game.deck, 1);
                }
                
                // Change to a random color
                var standardColors = [UnoColor.RED, UnoColor.BLUE, UnoColor.GREEN, UnoColor.YELLOW];
                var randomColor = standardColors[Math.floor(Math.random() * standardColors.length)];
                game.currentColor = randomColor;
                
                trace('Color Chaos! Everyone draws a card and color changes to $randomColor!');
            }
        );
        customCards.push(colorChaosCard);
        
        // Example 4: "Skip All" card - skips all other players, current player goes again
        var skipAllCard = UnoCard.createCustomActionCard(
            "Skip All",
            UnoColor.YELLOW,
            35,
            9,
            function(game:UnoGame) {
                var currentPlayer = game.turnManager.getCurrentPlayer();
                
                // Skip to the current player's next turn
                for (i in 0...(game.players.length - 1)) {
                    game.turnManager.skipNextPlayer();
                }
                
                trace('${currentPlayer.name} plays Skip All - everyone else is skipped!');
            }
        );
        customCards.push(skipAllCard);
        
        // Create the game with these custom cards
        return UnoGame.createWithCustomActions(customCards);
    }
    
    /**
     * Create a UNO game with custom colors and actions
     */
    public static function createAdvancedCustomGame():UnoGame {
        // Create custom colors
        var customColors = UnoCard.createCustomColors([
            FlxColor.PURPLE,
            FlxColor.ORANGE,
            FlxColor.PINK
        ], ["Purple", "Orange", "Pink"]);
        
        // Create custom action cards that work with custom colors
        var customCards = [];
        
        // Purple-specific action: "Purple Power" - draw 3, discard 1
        var purplePowerCard = UnoCard.createCustomActionCard(
            "Purple Power",
            customColors[0], // Purple
            20,
            5,
            function(game:UnoGame) {
                var currentPlayer = game.turnManager.getCurrentPlayer();
                currentPlayer.drawCards(game.deck, 3);
                
                // For demo purposes, just discard the first card
                if (currentPlayer.hand.cards.length > 0) {
                    var discardedCard = currentPlayer.hand.cards.shift();
                    game.deck.discard(discardedCard);
                }
                
                trace('${currentPlayer.name} uses Purple Power: draws 3, discards 1!');
            }
        );
        customCards.push(purplePowerCard);
        
        // Orange-specific action: "Orange Overdrive" - play again if you have another orange card
        var orangeOverdriveCard = UnoCard.createCustomActionCard(
            "Orange Overdrive",
            customColors[1], // Orange
            15,
            6,
            function(game:UnoGame) {
                var currentPlayer = game.turnManager.getCurrentPlayer();
                var hasOrangeCard = false;
                
                for (card in currentPlayer.hand.cards) {
                    if (UnoCard.colorsMatch(card.color, customColors[1])) {
                        hasOrangeCard = true;
                        break;
                    }
                }
                
                if (hasOrangeCard) {
                    // Don't advance turn - player goes again
                    trace('${currentPlayer.name} has another orange card - goes again!');
                } else {
                    trace('${currentPlayer.name} uses Orange Overdrive but has no more orange cards.');
                }
            }
        );
        customCards.push(orangeOverdriveCard);
        
        return UnoGame.createCustomGame({
            customColors: customColors,
            customCards: customCards,
            includeBaseColors: true
        });
    }
    
    /**
     * Example of how to use the custom UNO game
     */
    public static function playExample():Void {
        var game = createCustomUnoGame();
        
        // Add some players
        game.addPlayer(new UnoPlayer("Player 1", true));
        game.addPlayer(new UnoPlayer("Player 2", false));
        game.addPlayer(new UnoPlayer("Player 3", false));
        
        // Set up event handlers
        game.onCardPlayed = function(player:UnoPlayer, card:UnoCard) {
            trace('${player.name} played: ${card.toString()}');
        };
        
        game.onGameStart = function() {
            trace("Custom UNO game started!");
        };
        
        game.onRoundEnd = function(winner:UnoPlayer, points:Int) {
            trace('${winner.name} won the round with $points points!');
        };
        
        // Start the game
        game.startGame();
        
        trace("Game Status:");
        trace(game.getGameStatus());
    }
}
