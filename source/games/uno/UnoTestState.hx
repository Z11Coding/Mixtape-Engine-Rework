package games.uno;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import flixel.math.FlxMath;
import objects.Alphabet;
import games.uno.backend.*;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoCard.UnoCardType;
import games.uno.backend.UnoCPU.UnoDifficulty;
import backend.MusicBeatState;
import states.MainMenuState;
import openfl.Lib;

/**
 * UNO Test State - A complete UNO game implementation using generated temporary assets
 */
class UnoTestState extends MusicBeatState {
    // Game components
    private var unoGame:UnoGame;
    private var gameUI:UnoGameUI;
    private var isGameStarted:Bool = false;
    private var currentPlayerIndex:Int = 0;
    
    // UI Elements
    private var bgSprite:FlxSprite;
    private var gameStatusText:FlxText;
    private var instructionText:FlxText;
    private var topCardSprite:FlxSprite;
    private var playerHandGroup:FlxTypedGroup<FlxSprite>;
    private var playerInfoGroup:FlxTypedGroup<FlxText>;
    
    // Game state
    private var selectedCardIndex:Int = -1;
    private var waitingForColorChoice:Bool = false;
    private var availableColors:Array<UnoColor>;
    private var colorChoiceGroup:FlxTypedGroup<FlxSprite>;
    var instructionFade:FlxTween;

    var normalMus:FlxSound;
    var lastcardMus:FlxSound;

    var randomGenericNames:Array<String> = [
        "Ansley Conner",
        "Giovanni Duncan",
        "Levi Carroll",
        "Rory Winters",
        "Cory Coleman",
        "Jennifer Merritt",
        "Riley Horne",
        "Anika Gillespie",
        "Dorothy Barry",
        "Casen Fields",
        "Abby Reyna",
        "Nola Nixon",
        "Cleo Rivas",
        "Jennifer Merritt",
        "Isabela Farmer",
        "Frankie Holt",
        "Adley Robinson",
        "Devon Corona",
        "Taylor Hanson",
        "Dario Xiong"
    ];
    
    override function create() {
        super.create();

        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();
        
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Testing UNO", "In UNO Test State");
        #end
        
        setupBackground();
        setupUI();
        setupGame();
        add(instructionText); // so that it's over everything
        
        Cursor.show();
        Cursor.cursorMode = Default;

        normalMus = new FlxSound().loadEmbedded(Paths.music('menuMusic/Heart of the Cards'));
        lastcardMus = new FlxSound().loadEmbedded(Paths.music('menuMusic/Heart of the Cards (Last Card Mix)'));
        normalMus.play();
        lastcardMus.play();
        lastcardMus.volume = 0;
        lastcardMus.looped = true;
        normalMus.looped = true;
        FlxG.sound.list.add(normalMus);
        FlxG.sound.list.add(lastcardMus);

        idleTimer = new FlxTimer();
        refreshTimer = new FlxTimer();

        Lib.current.addChild(new games.uno.backend.logs.UnoTurnSummary());
    }
    
    private function setupBackground():Void {
        // Create a simple background with a card table feel
        bgSprite = new FlxSprite();
        bgSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(34, 139, 34)); // Forest Green
        add(bgSprite);
        
        // Add some table texture
        var tableOverlay = new FlxSprite();
        tableOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.1));
        add(tableOverlay);
    }
    
    private function setupUI():Void {
        // Game status text
        gameStatusText = new FlxText(10, 50, FlxG.width - 20, "", 16);
        gameStatusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        add(gameStatusText);
        
        // Instruction text
        instructionText = new FlxText(10, FlxG.height - 60, FlxG.width - 20, "", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, CENTER);
        
        // Player hand group
        playerHandGroup = new FlxTypedGroup<FlxSprite>();
        add(playerHandGroup);
        
        // Player info group
        playerInfoGroup = new FlxTypedGroup<FlxText>();
        add(playerInfoGroup);
        
        // Color choice group (initially hidden)
        colorChoiceGroup = new FlxTypedGroup<FlxSprite>();
        add(colorChoiceGroup);
        
        updateInstructionText("Press ENTER to start a new game, R to restart, I for debug info, or ESCAPE to return to menu");
    }
    
    private function setupGame():Void {
        try {
            var customColoroftheRainbow:Array<UnoColor> = [];
            for (color in 0...ClientPrefs.data.arrowRGBExtra.length) {
                customColoroftheRainbow.push(UnoColor.CUSTOM(ClientPrefs.data.arrowRGBExtra[color][0], objects.Note.keysShit.get(17).get('letters')[color]));
            }
            // Create UNO game with standard colors first (simpler initialization)
            unoGame = new UnoGame(); //customColoroftheRainbow
            
            setupGameEvents();
            
            trace("UNO game initialized successfully");
        } catch (e:Dynamic) {
            trace("Error initializing UNO game: " + e);
            updateInstructionText("Error initializing game: " + Std.string(e));
        }
    }
    
    private function setupGameEvents():Void {
        if (unoGame == null) {
            trace("Cannot setup events: unoGame is null");
            return;
        }
        
        unoGame.onGameStart = () -> {
            trace("UNO Game Started!");
            isGameStarted = true;
            updateDisplay();
            updateInstructionText("Click on a card to play it, or press D to draw");
        };
        
        unoGame.onCardPlayed = (player, card) -> {
            if (card != null) {
                var playerName = player != null ? Std.string(player.name) : "Unknown";
                trace('$playerName played: ${card.toString()}');
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
                updateDisplay();
            }
        };
        
        unoGame.onPlayerDraw = (player, count) -> {
            if (player != null) {
                trace('${Std.string(player.name)} drew $count card(s)');
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
                updateDisplay();
            }
        };
        
        unoGame.onRoundEnd = (winner, points) -> {
            if (winner != null) {
                updateInstructionText('${Std.string(winner.name)} wins the round with $points points! Press ENTER for next round');
            }
            isGameStarted = false;
        };
        
        unoGame.onGameEnd = (winner) -> {
            if (winner != null) {
                updateInstructionText('${Std.string(winner.name)} wins the game! Press ENTER to start new game');
            }
            isGameStarted = false;
        };
        
        unoGame.onWildColorChosen = (color) -> {
            waitingForColorChoice = false;
            updateDisplay();
        };

        unoGame.afterCardPlayed = (player, card) -> {
            if (card != null) {
                MemoryUtilBase.compact();
                MemoryUtilBase.collect(true);
                updateDisplay();
                if (!refreshTimer.active) {
                    refreshTimer.start(1, function(tmr:FlxTimer) {
                        updateDisplay();
                        if (refreshTimer != null) refreshTimer.reset();
                    });
                }
            }
        };
        
        trace("UNO game events setup complete");
    }
    
    private function startNewGame():Void {
        if (unoGame == null) {
            trace("Cannot start game: unoGame is null");
            updateInstructionText("Error: Game not initialized!");
            return;
        }
        
        try {
            if (unoGame.players.length > 0) {
                unoGame.startNewRound();
                selectedCardIndex = -1;
                updateDisplay();
                isGameStarted = true;
                
                trace("Game reset successfully");
            } else {
                // Clear existing players
                unoGame.players = [];
                
                // Add human player
                var humanPlayer = new UnoPlayer("human", "You", true);
                unoGame.addPlayer(humanPlayer);
                
                // Add CPU players with proper difficulty distribution
                var difficulties = [UnoDifficulty.EXPERT, UnoDifficulty.EXPERT, UnoDifficulty.EXPERT];
                for (i in 1...4) { // Add 3 CPU players
                    var difficulty = difficulties[(i - 1) % difficulties.length];
                    var diffName = switch (difficulty) {
                        case EASY: "Easy";
                        case NORMAL: "Normal"; 
                        case HARD: "Hard";
                        case EXPERT: "Expert";
                    }
                    var cpu = new UnoCPU('cpu$i', randomGenericNames[FlxG.random.int(0, randomGenericNames.length)], difficulty);
                    unoGame.addPlayer(cpu);
                }
                
                trace('Starting UNO game with ${unoGame.players.length} players...');
                
                // Start the game
                unoGame.startGame();
                selectedCardIndex = -1;
                updateDisplay();
                
                trace("Game started successfully");
            }
        } catch (e:Dynamic) {
            trace("Error starting UNO game: " + e);
            updateInstructionText("Error starting game: " + Std.string(e));
            isGameStarted = false;
        }
    }
    
    var onLastCard:Bool = false;
    private function updateDisplay():Void {
        if (!isGameStarted || unoGame == null) {
            //trace("Cannot update display: game not started or unoGame is null");
            return;
        }

        Paths.clearUnusedMemory();
        
        try {
            // Update game status
            if (gameStatusText != null) {
                gameStatusText.text = getGameStatusSafe();
            }
            
            // Update top card display
            updateTopCardDisplay();
            
            // Update player hand display
            updatePlayerHandDisplay();

            // Update player info display
            updatePlayerInfoDisplay();

            var oneCardLeft = false;
            for (player in unoGame.players) {
                if (player.hand.cards.length == 1) {
                    oneCardLeft = true;
                    break;
                }
            }
            if (oneCardLeft && !onLastCard) {
                FlxTween.num(1, 0, 1, {ease: FlxEase.sineInOut}, function(value:Float)
                {
                    normalMus.volume = value;
                });
                FlxTween.num(0, 1, 1, {ease: FlxEase.sineInOut}, function(value:Float)
                {
                    lastcardMus.volume = value;
                });
                onLastCard = true;
            } else if (!oneCardLeft && onLastCard) {
                FlxTween.num(0, 1, 1, {ease: FlxEase.sineInOut}, function(value:Float)
                {
                    normalMus.volume = value;
                });
                FlxTween.num(1, 0, 1, {ease: FlxEase.sineInOut}, function(value:Float)
                {
                    lastcardMus.volume = value;
                });
                onLastCard = false;
            }
        } catch (e:Dynamic) {
            trace("Error updating display: " + e);
        }
    }
    
    private function updateTopCardDisplay():Void {
        if (topCardSprite != null) {
            remove(topCardSprite);
            topCardSprite = null;
        }
        
        if (!isGameStarted || unoGame == null || unoGame.deck == null) {
            trace("Cannot update top card: missing dependencies");
            return;
        }
        
        try {
            var topCard = unoGame.deck.getTopCard();
            if (topCard != null) {
                topCardSprite = createCardSprite(topCard, FlxG.width * 0.5 - 40, 150);
                topCardSprite.setGraphicSize(Std.int(topCardSprite.width * 1.5));
                add(topCardSprite);
            }
        } catch (e:Dynamic) {
            trace("Error updating top card display: " + e);
        }
    }
    
    private function updatePlayerHandDisplay():Void {
        for (card in playerHandGroup.members) {
            card.destroy();
        }
        playerHandGroup.clear();
        
        if (!isGameStarted || unoGame == null || unoGame.players == null || unoGame.players.length == 0) {
            trace("Cannot update hand display: missing player data");
            return;
        }
        
        try {
            var humanPlayer = unoGame.players[0]; // First player is human
            if (humanPlayer == null || humanPlayer.hand == null || humanPlayer.hand.cards == null) {
                trace("Cannot update hand display: human player or hand is null");
                return;
            }
            
            var startX = 50;
            var y = FlxG.height - 200;
            var cardOff = 0;
            var cardOffMult = 60;
            
            for (card in humanPlayer.hand.cards) {
                var cardSprite = createCardSprite(card, startX + (cardOff * cardOffMult), y);
                cardOff++;
                playerHandGroup.add(cardSprite);
            }
        } catch (e:Dynamic) {
            trace("Error updating player hand display: " + e);
        }
    }
    
    private function updatePlayerInfoDisplay():Void {
        playerInfoGroup.clear();
        
        if (!isGameStarted || unoGame == null || unoGame.players == null) {
            trace("Cannot update player info: missing game data");
            return;
        }
        
        try {
            for (i in 0...unoGame.players.length) {
                var player = unoGame.players[i];
                if (player == null) continue;
                
                var text = new FlxText(10, 280 + (i * 20), FlxG.width - 20, player.getStatus(), 14);
                text.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
                
                // Highlight current player
                if (unoGame.turnManager != null && unoGame.turnManager.getCurrentPlayer() == player) {
                    text.color = FlxColor.YELLOW;
                }
                
                playerInfoGroup.add(text);
            }
        } catch (e:Dynamic) {
            trace("Error updating player info display: " + e);
        }
    }
    
    private function createCardSprite(card:UnoCard, x:Float, y:Float):FlxSprite {
        if (card == null) {
            trace("Warning: createCardSprite called with null card");
            var errorSprite = new FlxSprite(x, y);
            errorSprite.makeGraphic(80, 110, FlxColor.RED, true);
            return errorSprite;
        }
        
        var cardSprite = new FlxSprite(x, y);

        
        try {
            // Create a simple card representation
            cardSprite.makeGraphic(80, 110, FlxColor.WHITE, true);
            
            // Add colored border
            var borderSprite = new FlxSprite();
            borderSprite.makeGraphic(76, 106, card.getFlxColor(), true);
            cardSprite.stamp(borderSprite, 2, 2);
            
            // Add card text (simplified)
            var cardText = new FlxText(0, 0, 80, getCardDisplayText(card), 12);
            cardText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.BLACK, CENTER);
            cardText.y = 49; // Center vertically
            cardSprite.stamp(cardText, 0, 0);
        } catch (e:Dynamic) {
            trace("Error creating card sprite: " + e);
            // Fallback to simple colored rectangle
            cardSprite.makeGraphic(80, 110, FlxColor.GRAY, true);
        }
        
        return cardSprite;
    }
    
    private function getCardDisplayText(card:UnoCard):String {
        if (card == null) return "?";
        
        return switch(card.type) {
            case NUMBER: Std.string(card.value);
            case SKIP: "SKIP";
            case REVERSE: "REV";
            case DRAW_TWO: "+2";
            case WILD: "WILD";
            case WILD_DRAW_FOUR: "W+4";
            case CUSTOM(name, _, _, _): name != null ? name.substr(0, 6) : "CUSTOM";
        }
    }
    
    private function processCPUTurn():Void {
        if (!isGameStarted || unoGame == null || unoGame.turnManager == null) {
            trace("Cannot process CPU turn: missing game components");
            return;
        }
        
        try {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer == null || currentPlayer.isHuman) {
                //trace("Current player is null or human, skipping CPU turn");
                updatePlayerInfoDisplay();
                return;
            }
            
            if (Std.isOfType(currentPlayer, UnoCPU)) {
                var cpuPlayer = cast(currentPlayer, UnoCPU);
                
                // Get top card safely
                var topCard = unoGame.deck != null ? unoGame.deck.getTopCard() : null;
                if (topCard == null) {
                    trace("Cannot process CPU turn: top card is null");
                    return;
                }
                
                var playableCards = cpuPlayer.getPlayableCards(topCard);
                
                if (playableCards.length > 0) {
                    var cardIndex = cpuPlayer.chooseCard(topCard, unoGame.gameState);
                    if (cardIndex >= 0 && cardIndex < cpuPlayer.hand.cards.length) {
                        var card = cpuPlayer.hand.cards[cardIndex];
                        var chosenColor:UnoColor = null;
                        
                        if (card.isWildCard()) {
                            chosenColor = cpuPlayer.chooseWildColor();
                        }
                        
                        var success = unoGame.playCard(cpuPlayer, cardIndex, chosenColor);
                        if (!success) {
                            // If card couldn't be played, draw instead
                            unoGame.drawCards(cpuPlayer, 1);
                        }
                    } else {
                        unoGame.drawCards(cpuPlayer, 1);
                    }
                } else {
                    unoGame.drawCards(cpuPlayer, 1);
                }
            }
        } catch (e:Dynamic) {
            trace("Error processing CPU turn: " + e);
        }
    }
    
    private function handleCardClick(cardIndex:Int):Void {
        if (!isGameStarted || unoGame == null || unoGame.turnManager == null) {
            trace("Cannot handle card click: game not ready");
            Cursor.cursorMode = Default;
            return;
        }

        var currentPlayer = unoGame.turnManager.getCurrentPlayer();
        if (currentPlayer == null || !currentPlayer.isHuman) {
            trace("Not human player turn");
            Cursor.cursorMode = Default;
            return;
        }
        
        if (cardIndex < 0 || cardIndex >= currentPlayer.hand.cards.length) {
            trace("Invalid card index: " + cardIndex);
            Cursor.cursorMode = Default;
            return;
        }
        
        var card = currentPlayer.hand.cards[cardIndex];
        if (card == null) {
            trace("Selected card is null");
            Cursor.cursorMode = Default;
            return;
        }
        
        var topCard = unoGame.deck != null ? unoGame.deck.getTopCard() : null;
        if (topCard == null) {
            trace("Top card is null");
            Cursor.cursorMode = Default;
            return;
        }
        
        if (!card.canPlayOn(topCard)) {
            FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
            updateInstructionText("Cannot play that card!", true);
            Cursor.cursorMode = Default;
            return;
        }
        
        selectedCardIndex = cardIndex;
        
        if (card.isWildCard()) {
            // Show color choice
            showColorChoice();
        } else {
            // Play the card directly
            var success = unoGame.playCard(currentPlayer, cardIndex);
            if (success) {
                selectedCardIndex = -1;
            } else {
                updateInstructionText("Failed to play card!", true);
            }
        }
        Cursor.cursorMode = Default;
        
        /*try {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer == null || !currentPlayer.isHuman) {
                trace("Not human player turn");
                Cursor.cursorMode = Default;
                return;
            }
            
            if (cardIndex < 0 || cardIndex >= currentPlayer.hand.cards.length) {
                trace("Invalid card index: " + cardIndex);
                Cursor.cursorMode = Default;
                return;
            }
            
            var card = currentPlayer.hand.cards[cardIndex];
            if (card == null) {
                trace("Selected card is null");
                Cursor.cursorMode = Default;
                return;
            }
            
            var topCard = unoGame.deck != null ? unoGame.deck.getTopCard() : null;
            if (topCard == null) {
                trace("Top card is null");
                Cursor.cursorMode = Default;
                return;
            }
            
            if (!card.canPlayOn(topCard)) {
                FlxG.sound.play(Paths.sound('cancelMenu'), 0.5);
                updateInstructionText("Cannot play that card!");
                Cursor.cursorMode = Default;
                return;
            }
            
            selectedCardIndex = cardIndex;
            
            if (card.isWildCard()) {
                // Show color choice
                showColorChoice();
            } else {
                // Play the card directly
                var success = unoGame.playCard(currentPlayer, cardIndex);
                if (success) {
                    selectedCardIndex = -1;
                } else {
                    updateInstructionText("Failed to play card!");
                }
            }
            Cursor.cursorMode = Default;
        } catch (e:Dynamic) {
            trace("Error handling card click: " + e);
            updateInstructionText("Error playing card: " + Std.string(e));
        }*/
    }
    
    private function showColorChoice():Void {
        if (unoGame == null || unoGame.turnManager == null) {
            trace("Cannot show color choice: missing game components");
            return;
        }

        waitingForColorChoice = true;
        colorChoiceGroup.clear();
        
        // Get available colors (standard colors only for simplicity)
        availableColors = (unoGame.customColors != null && unoGame.customColors.length > 0 ? unoGame.customColors : UnoCard.getStandardColors());
        
        // Remove WILD from choosable colors
        availableColors = availableColors.filter(function(color) return color != WILD);
        
        // Create color choice buttons
        var startX = FlxG.width * 0.5 - (availableColors.length * 30);
        var y = 300;
        
        for (i in 0...availableColors.length) {
            var colorButton = new FlxSprite(startX + (i * 60), y);
            var buttonColor = switch(availableColors[i]) {
                case RED: FlxColor.RED;
                case BLUE: FlxColor.BLUE;
                case GREEN: FlxColor.GREEN;
                case YELLOW: FlxColor.YELLOW;
                case CUSTOM(color, _): color;
                case _: FlxColor.WHITE;
            };
            colorButton.makeGraphic(50, 50, buttonColor);
            
            // Add a border
            var border = new FlxSprite();
            border.makeGraphic(46, 46, FlxColor.WHITE);
            colorButton.stamp(border, 2, 2);
            
            // Add color text
            var colorName = switch(availableColors[i]) {
                case RED: "RED";
                case BLUE: "BLUE";
                case GREEN: "GREEN";
                case YELLOW: "YELLOW";
                case CUSTOM(_, name): name != null ? name.substr(0, 6) : "CUSTOM";
                case _: "?";
            };
            
            var colorText = new FlxText(0, 0, 50, colorName, 8);
            colorText.setFormat(Paths.font("vcr.ttf"), 8, FlxColor.BLACK, CENTER);
            colorText.y = 21; // Center vertically
            colorButton.stamp(colorText, 0, 0);
            
            colorChoiceGroup.add(colorButton);
        }
        
        updateInstructionText("Choose a color by clicking on it");
        
        /*try {
            waitingForColorChoice = true;
            colorChoiceGroup.clear();
            
            // Get available colors (standard colors only for simplicity)
            availableColors = unoGame.customColors;
            
            // Remove WILD from choosable colors
            availableColors = availableColors.filter(function(color) return color != WILD);
            
            // Create color choice buttons
            var startX = FlxG.width * 0.5 - (availableColors.length * 30);
            var y = 500;
            
            for (i in 0...availableColors.length) {
                var colorButton = new FlxSprite(startX + (i * 60), y);
                var buttonColor = switch(availableColors[i]) {
                    case RED: FlxColor.RED;
                    case BLUE: FlxColor.BLUE;
                    case GREEN: FlxColor.GREEN;
                    case YELLOW: FlxColor.YELLOW;
                    case CUSTOM(color, _): color;
                    case _: FlxColor.WHITE;
                };
                colorButton.makeGraphic(50, 50, buttonColor);
                
                // Add a border
                var border = new FlxSprite();
                border.makeGraphic(46, 46, FlxColor.WHITE);
                colorButton.stamp(border, 2, 2);
                
                // Add color text
                var colorName = switch(availableColors[i]) {
                    case RED: "RED";
                    case BLUE: "BLUE";
                    case GREEN: "GREEN";
                    case YELLOW: "YELLOW";
                    case CUSTOM(_, name): name != null ? name.substr(0, 6) : "CUSTOM";
                    case _: "?";
                };
                
                var colorText = new FlxText(0, 0, 50, colorName, 8);
                colorText.setFormat(Paths.font("vcr.ttf"), 8, FlxColor.BLACK, CENTER);
                colorText.y = 21; // Center vertically
                colorButton.stamp(colorText, 0, 0);
                
                colorChoiceGroup.add(colorButton);
            }
            
            updateInstructionText("Choose a color by clicking on it");
        } catch (e:Dynamic) {
            trace("Error showing color choice: " + new DetailedException(e));
            waitingForColorChoice = false;
        }*/
    }
    
    private function handleColorChoice(colorIndex:Int):Void {
        if (!waitingForColorChoice || availableColors == null || colorIndex >= availableColors.length) {
            trace("Invalid color choice: " + colorIndex);
            Cursor.cursorMode = Default;
            return;
        }
        
        try {
            var chosenColor = availableColors[colorIndex];
            if (unoGame != null && unoGame.turnManager != null) {
                var humanPlayer = unoGame.turnManager.getCurrentPlayer();
                if (humanPlayer != null && humanPlayer.isHuman) {
                    var success = unoGame.playCard(humanPlayer, selectedCardIndex, chosenColor);
                    if (success) {
                        selectedCardIndex = -1;
                        waitingForColorChoice = false;
                        colorChoiceGroup.clear();
                    } else {
                        updateInstructionText("Failed to play wild card!", true);
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("Error handling color choice: " + e);
            waitingForColorChoice = false;
            colorChoiceGroup.clear();
        }
        Cursor.cursorMode = Default;
    }
    
    private function updateInstructionText(text:String, ?doFade:Bool = false):Void {
        if (instructionText != null) {
            instructionText.text = text;
            trace("Instruction: " + text);
            instructionFade.cancel();
            instructionText.alpha = 1;
            if (doFade) instructionFade = FlxTween.tween(instructionText, {alpha: 0}, 1, {startDelay: 3, ease: FlxEase.quadOut});
        }
    }
    
    /**
     * Get game status safely with null checks
     */
    private function getGameStatusSafe():String {
        if (unoGame == null) {
            return "Game not initialized";
        }
        
        try {
            return unoGame.getGameStatus();
        } catch (e:Dynamic) {
            return "Error getting game status: " + Std.string(e);
        }
    }
    
    var idleTimer:FlxTimer;
    var refreshTimer:FlxTimer;
    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle CPU turns
        if (unoGame != null && unoGame.turnManager != null && unoGame.turnManager.getCurrentPlayer() != null) {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (!currentPlayer.isHuman) {
                //Sys.sleep(cast (currentPlayer, UnoCPU).thinkingTime);
                if (!idleTimer.active) {
                    idleTimer.start(cast (currentPlayer, UnoCPU).thinkingTime, function(tmr:FlxTimer) {
                        processCPUTurn();
                        if (idleTimer != null) idleTimer.cancel();
                    });
                }
            }
        }
        
        // Handle input
        if (controls.BACK) {
            FlxG.mouse.visible = false;
            MusicBeatState.switchState(new MainMenuState());
        }
        
        if (controls.ACCEPT) {
            if (!isGameStarted) {
                trace("Starting new UNO game...");
                startNewGame();
            }
        }
        
        // Add debug key to restart game
        if (FlxG.keys.justPressed.R) {
            trace("Restarting UNO game...");
            isGameStarted = false;
            if (unoGame != null) {
                unoGame.players = [];
            }
            setupGame();
            updateInstructionText("Press ENTER to start a new game, R to restart, I for debug info, or ESCAPE to return to menu");
        }
        
        // Debug info with I key
        if (FlxG.keys.justPressed.I && isGameStarted && unoGame != null) {
            trace("=== UNO Game Debug Info ===");
            trace("Game Active: " + unoGame.isGameActive);
            trace("Round Active: " + unoGame.isRoundActive);
            trace("Players Count: " + (unoGame.players != null ? unoGame.players.length : 0));
            if (unoGame.turnManager != null) {
                var current = unoGame.turnManager.getCurrentPlayer();
                var playerName = current != null ? Std.string(current.name) : "null";
                trace("Current Player: " + playerName);
            }
            if (unoGame.deck != null) {
                trace("Top Card: " + (unoGame.deck.getTopCard() != null ? unoGame.deck.getTopCard().toString() : "null"));
            }
            trace("========================");
        }
        
        // Draw card with D key
        if (FlxG.keys.justPressed.D && isGameStarted && unoGame != null && unoGame.turnManager != null) {
            try {
                var currentPlayer = unoGame.turnManager.getCurrentPlayer();
                if (currentPlayer != null && currentPlayer.isHuman) {
                    trace("Human player drawing card");
                    unoGame.drawCards(currentPlayer, 1);
                } else {
                    trace("Cannot draw: not human player turn or player is null");
                }
            } catch (e:Dynamic) {
                trace("Error drawing card: " + e);
            }
        }
        
        // Handle mouse clicks
        if (FlxG.mouse.justPressed && isGameStarted) {
            if (waitingForColorChoice) {
                // Check color choice clicks
                for (i in 0...colorChoiceGroup.length) {
                    var colorButton = colorChoiceGroup.members[i];
                    if (colorButton != null && FlxG.mouse.overlaps(colorButton)) {
                        Cursor.cursorMode = Pointer;
                        handleColorChoice(i);
                        break;
                    }
                }
            } else if (unoGame != null && unoGame.turnManager != null) {
                var currentPlayer = unoGame.turnManager.getCurrentPlayer();
                if (currentPlayer != null && currentPlayer.isHuman) {
                    // Check card clicks
                    for (i in 0...playerHandGroup.length) {
                        var cardSprite = playerHandGroup.members[i];
                        if (cardSprite != null && FlxG.mouse.overlaps(cardSprite)) {
                            Cursor.cursorMode = Pointer;
                            handleCardClick(i);
                            break;
                        }
                    }
                }
            }
            /*try {
                if (waitingForColorChoice) {
                    // Check color choice clicks
                    for (i in 0...colorChoiceGroup.length) {
                        var colorButton = colorChoiceGroup.members[i];
                        if (colorButton != null && FlxG.mouse.overlaps(colorButton)) {
                            Cursor.cursorMode = Pointer;
                            handleColorChoice(i);
                            break;
                        }
                    }
                } else if (unoGame != null && unoGame.turnManager != null) {
                    var currentPlayer = unoGame.turnManager.getCurrentPlayer();
                    if (currentPlayer != null && currentPlayer.isHuman) {
                        // Check card clicks
                        for (i in 0...playerHandGroup.length) {
                            var cardSprite = playerHandGroup.members[i];
                            if (cardSprite != null && FlxG.mouse.overlaps(cardSprite)) {
                                Cursor.cursorMode = Pointer;
                                handleCardClick(i);
                                break;
                            }
                        }
                    }
                }
            } catch (e:Dynamic) {
                trace("Error handling mouse click: " + e);
            }*/
        }
        
        // UNO call with U key
        if (FlxG.keys.justPressed.U && isGameStarted && unoGame != null && unoGame.turnManager != null) {
            try {
                var currentPlayer = unoGame.turnManager.getCurrentPlayer();
                if (currentPlayer != null && currentPlayer.isHuman) {
                    if (unoGame.callUno(currentPlayer)) {
                        updateInstructionText("UNO called!", true);
                        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
                    }
                }
            } catch (e:Dynamic) {
                trace("Error calling UNO: " + e);
            }
        }
    }
}

/**
 * Helper class for UNO game UI management
 */
class UnoGameUI {
    // This could be expanded for more complex UI management
    // For now, keeping it simple with the state handling the UI directly
}
