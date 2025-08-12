package yutautil.games.uno;

import flixel.util.FlxColor;
import yutautil.games.uno.UnoRules.UnoGameState;
import yutautil.games.uno.UnoTurnManager.TurnDirection;
import yutautil.games.uno.UnoCard.UnoColor;
import yutautil.games.uno.UnoCard.UnoCardType;
import yutautil.games.uno.UnoCPU.UnoDifficulty;

/**
 * Example usage and testing of the UNO game system
 */
class UnoExample {
    public static function createSampleGame():UnoGame {
        var game = new UnoGame();
        
        // Add human players
        var player1 = new UnoPlayer("p1", "Alice", true);
        var player2 = new UnoPlayer("p2", "Bob", true);
        
        // Add CPU players with different difficulties
        var cpu1 = new UnoCPU("cpu1", "Easy Bot", UnoDifficulty.EASY);
        var cpu2 = new UnoCPU("cpu2", "Hard Bot", UnoDifficulty.HARD);
        
        game.addPlayer(player1);
        game.addPlayer(player2);
        game.addPlayer(cpu1);
        game.addPlayer(cpu2);
        
        // Set up event handlers
        setupGameEvents(game);
        
        return game;
    }
    
    public static function createCustomColorGame():UnoGame {
        // Create custom colors using FlxColor
        var customColors = UnoCard.createCustomColors([
            FlxColor.PURPLE,   // Purple replaces Red
            FlxColor.ORANGE,   // Orange replaces Yellow  
            FlxColor.CYAN,     // Cyan replaces Blue
            FlxColor.PINK      // Pink replaces Green
        ], ["Purple", "Orange", "Cyan", "Pink"]);
        
        // Create game with custom colors
        var game = new UnoGame(customColors);
        
        // Add players
        var player1 = new UnoPlayer("p1", "Alice", true);
        var cpu1 = new UnoCPU("cpu1", "Rainbow Bot", UnoDifficulty.NORMAL);
        
        game.addPlayer(player1);
        game.addPlayer(cpu1);
        
        // Set up event handlers
        setupGameEvents(game);
        
        return game;
    }
    
    public static function setupGameEvents(game:UnoGame):Void {
        game.onGameStart = function() {
            trace("UNO Game Started!");
        };
        
        game.onRoundStart = function(roundNum:Int) {
            trace('Round $roundNum started!');
            trace('Starting top card: ${game.deck.getTopCard().toString()}');
        };
        
        game.onCardPlayed = function(player:UnoPlayer, card:UnoCard) {
            trace('${player.name} played: ${card.toString()}');
        };
        
        game.onPlayerDraw = function(player:UnoPlayer, count:Int) {
            trace('${player.name} drew $count card(s)');
        };
        
        game.onUnoCall = function(player:UnoPlayer) {
            trace('${player.name} called UNO!');
        };
        
        game.onUnoPenalty = function(player:UnoPlayer) {
            trace('${player.name} was penalized for not calling UNO!');
        };
        
        game.onDirectionChange = function(direction:TurnDirection) {
            var dirStr = direction == CLOCKWISE ? "clockwise" : "counter-clockwise";
            trace('Direction changed to $dirStr');
        };
        
        game.onPlayerSkipped = function(player:UnoPlayer) {
            trace('${player.name} was skipped!');
        };
        
        game.onWildColorChosen = function(color:UnoColor) {
            trace('Wild card color changed to $color');
        };
        
        game.onChallenge = function(challenger:UnoPlayer, challenged:UnoPlayer, successful:Bool) {
            var result = successful ? "successful" : "failed";
            trace('${challenger.name} challenged ${challenged.name} - Challenge $result!');
        };
        
        game.onRoundEnd = function(winner:UnoPlayer, points:Int) {
            trace('${winner.name} won the round and scored $points points!');
            trace('Current scores:');
            for (player in game.players) {
                trace('  ${player.name}: ${player.score}');
            }
        };
        
        game.onGameEnd = function(winner:UnoPlayer) {
            trace('${winner.name} won the game with ${winner.score} points!');
        };
    }
    
    /**
     * Simulate a simple game with automatic play
     */
    public static function simulateGame(?maxTurns:Int):Void {
        var game = createSampleGame();
        game.startGame();
        
        trace("=== UNO Game Simulation ===");
        trace(game.getGameStatus());
        
        // Simulate some turns (in a real game, this would be user input)
        var maxTurns = maxTurns ?? 100;
        var turnCount = 0;
        
        while (game.isRoundActive && turnCount < maxTurns) {
            // Delay for a moment, so that the game sim can be seen.
            Sys.sleep(2);
            turnCount++;
            var currentPlayer = game.turnManager.getCurrentPlayer();
            
            trace('\n--- Turn $turnCount: ${currentPlayer.name} ---');
            trace('Hand: ${currentPlayer.hand.toString()}');
            trace('Top card: ${game.deck.getTopCard().toString()} (Color: ${game.currentColor})');
            
            var playableCards = game.getCurrentPlayerPlayableCards();
            
            if (playableCards.length > 0) {
                // Find the index of the first playable card
                var cardToPlay = playableCards[0];
                var cardIndex = currentPlayer.hand.cards.indexOf(cardToPlay);
                
                // For wild cards, choose a color
                var chosenColor:UnoColor = null;
                if (cardToPlay.isWildCard()) {
                    if (Std.isOfType(currentPlayer, UnoCPU)) {
                        chosenColor = cast(currentPlayer, UnoCPU).chooseWildColor();
                    } else {
                        // For human players, just choose red for simplicity
                        chosenColor = UnoColor.RED;
                    }
                }
                
                // Check UNO condition before playing
                if (currentPlayer.hand.getSize() == 2) {
                    game.callUno(currentPlayer);
                }
                
                // Try to play the card
                var success = game.playCard(currentPlayer, cardIndex, chosenColor);
                if (!success) {
                    // Card couldn't be played (probably due to draw stack), must draw instead
                    trace('${currentPlayer.name} cannot play card due to draw stack, drawing...');
                    game.drawCards(currentPlayer, 1);
                }
            } else {
                // Must draw cards
                trace('${currentPlayer.name} has no playable cards, drawing...');
                game.drawCards(currentPlayer, 1);
            }
            
            // Check for UNO penalties
            game.checkUnoPenalties();
        }
        
        if (turnCount >= maxTurns) {
            trace("Game simulation ended due to turn limit");
            game.forceEndGame();
        }
        
        trace("\n=== Final Game Stats ===");
        var stats = game.getGameStats();
        trace('Total rounds played: ${stats.roundNumber}');
        trace('Total cards played: ${stats.totalCardsPlayed}');
        
        trace("\nFinal scores:");
        for (playerStat in cast(stats.playerStats, Array<Dynamic>)) {
            trace('  ${playerStat.name}: ${playerStat.score} points');
        }
    }
    
    /**
     * Test custom color functionality
     */
    public static function testCustomColors():Void {
        trace("=== Custom Color System Test ===");
        
        // Create custom colors
        var customColors = UnoCard.createCustomColors([
            FlxColor.PURPLE,
            FlxColor.ORANGE,
            FlxColor.CYAN
        ], ["Purple", "Orange", "Cyan"]);
        
        trace("Created " + customColors.length + " custom colors");
        
        // Test custom color cards
        for (color in customColors) {
            var card = new UnoCard(color, UnoCardType.NUMBER, 5);
            trace("Card: " + card.toString() + " | FlxColor: 0x" + StringTools.hex(card.getFlxColor(), 8));
        }
        
        // Test color matching
        var purpleCard = new UnoCard(customColors[0], UnoCardType.NUMBER, 3);
        var orangeCard = new UnoCard(customColors[1], UnoCardType.NUMBER, 5);
        var anotherPurple = new UnoCard(customColors[0], UnoCardType.DRAW_TWO);
        
        trace("Purple 3 can play on Orange 5: " + purpleCard.canPlayOn(orangeCard));
        trace("Purple Draw Two can play on Purple 3: " + anotherPurple.canPlayOn(purpleCard));
        
        // Test deck with custom colors
        var deck = new UnoDeck();
        deck.initializeDeckWithColors(customColors);
        trace("Custom deck has " + deck.getRemainingCards() + " cards");
        
        var drawnCard = deck.drawCard();
        trace("Drew: " + drawnCard.toString());
        
        trace("=== Custom Color Test Complete ===\n");
    }
    
    /**
     * Test basic card functionality
     */
    public static function testCards():Void {
        trace("=== Card System Test ===");
        
        // Test card creation
        var redSeven = new UnoCard(UnoColor.RED, UnoCardType.NUMBER, 7);
        var blueSkip = new UnoCard(UnoColor.BLUE, UnoCardType.SKIP);
        var wildCard = new UnoCard(WILD, WILD);
        
        trace('Red 7: ${redSeven.toString()}');
        trace('Blue Skip: ${blueSkip.toString()}');
        trace('Wild: ${wildCard.toString()}');
        
        // Test card compatibility
        trace('\nCard compatibility tests:');
        trace('Red 7 can play on Blue 7: ${redSeven.canPlayOn(new UnoCard(UnoColor.BLUE, UnoCardType.NUMBER, 7))}');
        trace('Red 7 can play on Red Skip: ${redSeven.canPlayOn(new UnoCard(UnoColor.RED, UnoCardType.SKIP))}');
        trace('Wild can play on Red 7: ${wildCard.canPlayOn(redSeven)}');
        
        // Test deck
        trace('\n=== Deck Test ===');
        var deck = new UnoDeck();
        trace('Initial deck size: ${deck.getRemainingCards()}');
        
        var drawnCards = deck.drawCards(5);
        trace('Drew 5 cards:');
        for (card in drawnCards) {
            trace('  ${card.toString()}');
        }
        
        trace('Deck size after drawing: ${deck.getRemainingCards()}');
    }
    
    /**
     * Test player and hand functionality
     */
    public static function testPlayers():Void {
        trace("=== Player System Test ===");
        
        var player = new UnoPlayer("test", "Test Player");
        var deck = new UnoDeck();
        
        // Draw starting hand
        player.drawCards(deck, 7);
        trace('Player hand: ${player.hand.toString()}');
        
        var topCard = deck.drawCard();
        deck.discard(topCard);
        trace('Top card: ${topCard.toString()}');
        
        var playableCards = player.getPlayableCards(topCard);
        trace('Playable cards: ${playableCards.length}');
        for (card in playableCards) {
            trace('  ${card.toString()}');
        }
        
        // Test CPU player
        trace('\n=== CPU Player Test ===');
        var cpu = new UnoCPU("cpu", "CPU Player", NORMAL);
        cpu.drawCards(deck, 7);
        
        trace('CPU hand: ${cpu.hand.toString()}');
        
        // Create a mock game state for CPU decision making
        var gameState = new UnoGameState();
        gameState.players = [player, cpu];
        gameState.currentPlayer = cpu;
        gameState.direction = TurnDirection.CLOCKWISE;
        gameState.topCard = topCard;
        gameState.currentColor = topCard.color;
        
        var cpuChoice = cpu.chooseCard(topCard, gameState);
        if (cpuChoice >= 0) {
            trace('CPU chose to play: ${cpu.hand.cards[cpuChoice].toString()}');
        } else {
            trace('CPU has no playable cards');
        }
    }
    
    /**
     * Run all tests
     */
    public static function runTests():Void {
        testCustomColors();
        trace("\n" + StringTools.repeat("=", 50) + "\n");
        testCards();
        trace("\n" + StringTools.repeat("=", 50) + "\n");
        testPlayers();
        trace("\n" + StringTools.repeat("=", 50) + "\n");
        simulateGame();
    }
}

// String extension for repeat function
class StringTools {
    public static function repeat(s:String, times:Int):String {
        var result = "";
        for (i in 0...times) {
            result += s;
        }
        return result;
    }
}
