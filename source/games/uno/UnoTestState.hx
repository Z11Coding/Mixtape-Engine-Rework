package games.uno;

import backend.MusicBeatState;
import backend.MusicBeatState;
import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.uno.PongUnoSubstate;
import games.uno.UnoOptionsSubState;
import games.uno.backend.*;
import games.uno.backend.UnoCPU.UnoDifficulty;
import games.uno.backend.UnoCard.UnoCardType;
import games.uno.backend.UnoCard.UnoColor;
import lime.media.openal.AL;
import lime.media.openal.ALEffect;
import objects.Alphabet;
import openfl.Lib;
import states.MainMenuState;

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
    private var unoButton:PsychUIButton;
    private var drawButton:PsychUIButton;
    var blackScreen:FlxSprite;
    var loadingTxt:FlxText;

    // Game state
    private var selectedCardIndex:Int = -1;
    private var waitingForColorChoice:Bool = false;
    private var availableColors:Array<UnoColor>;
    private var colorChoiceGroup:FlxTypedGroup<FlxSprite>;
    var instructionFade:FlxTween;

    // Animation variables
    private var cardAnimations:Map<FlxSprite, FlxTween> = new Map();
    private var selectedCardSprite:FlxSprite;
    private var maxHandWidth:Float = 0;
    private var isFirstCardPlayed:Bool = false;
    private var previousHandCards:Array<UnoCard> = []; // Track previous hand state
    private var isPlayingCard:Bool = false; // Prevent hover effects during card play
    private var previousCardPositions:Map<UnoCard, {x:Float, y:Float}> = new Map(); // Track card positions

    var normalMus:FlxSound;
    var lastcardMus:FlxSound;
    var af:ALEffect;

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

        normalMus = new FlxSound().loadEmbedded(Paths.music('gameMusic/Heart of the Cards'));
        lastcardMus = new FlxSound().loadEmbedded(Paths.music('gameMusic/Heart of the Cards (Last Card Mix)'));
        normalMus.play();
        lastcardMus.play();
        lastcardMus.volume = 0;
        lastcardMus.looped = true;
        normalMus.looped = true;
        FlxG.sound.list.add(normalMus);
        FlxG.sound.list.add(lastcardMus);

        idleTimer = new FlxTimer();
        refreshTimer = new FlxTimer();

        @:privateAccess
        {
            af = AL.createEffect(); // create AudioFilter
            lime.media.openal.AL.effecti( af, lime.media.openal.AL.EFFECT_TYPE, lime.media.openal.AL.EFFECT_PITCH_SHIFTER ); // set filter type
            lime.media.openal.AL.sourcei( lastcardMus._channel.__audioSource.__backend.handle, lime.media.openal.AL.DIRECT_FILTER, af ); // apply filter to source (handle)
        }

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

        // Calculate maximum hand width for compression
        maxHandWidth = FlxG.width - 100; // Leave some margin


        unoButton = new PsychUIButton(0, 0, "UNO!", function() {
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
        });
		unoButton.x = FlxG.width - 120;
		unoButton.y = FlxG.height - unoButton.height - 80;
		unoButton.normalStyle.bgColor = 0xFF520303;
		unoButton.normalStyle.textColor = FlxColor.WHITE;
        unoButton.hoverStyle.bgColor = 0xFFFF0000;
		unoButton.hoverStyle.textColor = FlxColor.WHITE;
        unoButton.clickStyle.bgColor = FlxColor.BLACK;
		unoButton.clickStyle.textColor = FlxColor.WHITE;
        unoButton.resize(80, 50);
		add(unoButton);

        drawButton = new PsychUIButton(0, 0, "Draw", function() {
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
        });
		drawButton.x = FlxG.width - 120;
		drawButton.y = FlxG.height - unoButton.height - 120;
		drawButton.normalStyle.bgColor = FlxColor.BLACK;
		drawButton.normalStyle.textColor = FlxColor.WHITE;
        drawButton.resize(80, 50);
		add(drawButton);

        updateInstructionText("Press ENTER to start a new game, R to restart, O for options, I for debug info, or ESCAPE to return to menu");
    }

    function toggleHideScreen(toggle:Bool) {
        if (toggle && blackScreen != null || !toggle && blackScreen != null) {
            remove(blackScreen);
            remove(loadingTxt);
        }

        if (toggle) {
            blackScreen = new FlxSprite();
            blackScreen.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0));

            loadingTxt = new FlxText(0, 0, 0, "LOADING...", 64);
            loadingTxt.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER);
            loadingTxt.screenCenter();

            add(blackScreen);
            add(loadingTxt);
        }
    }

    function resetUI() {
        if (unoButton != null) {
            remove(unoButton);
            remove(drawButton);
        }
        unoButton = new PsychUIButton(0, 0, "UNO!", function() {
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
        });
		unoButton.x = FlxG.width - 120;
		unoButton.y = FlxG.height - unoButton.height - 80;
		unoButton.normalStyle.bgColor = 0xFF520303;
		unoButton.normalStyle.textColor = FlxColor.WHITE;
        unoButton.hoverStyle.bgColor = 0xFFFF0000;
		unoButton.hoverStyle.textColor = FlxColor.WHITE;
        unoButton.clickStyle.bgColor = FlxColor.BLACK;
		unoButton.clickStyle.textColor = FlxColor.WHITE;
        unoButton.resize(80, 50);
		add(unoButton);

        drawButton = new PsychUIButton(0, 0, "Draw", function() {
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
        });
		drawButton.x = FlxG.width - 120;
		drawButton.y = FlxG.height - unoButton.height - 120;
		drawButton.normalStyle.bgColor = FlxColor.BLACK;
		drawButton.normalStyle.textColor = FlxColor.WHITE;
        drawButton.resize(80, 50);
		add(drawButton);
    }

    private function setupGame():Void {
        try {
            var customColoroftheRainbow:Array<UnoColor> = [];
            for (color in 0...ClientPrefs.data.arrowRGBExtra.length) {
                customColoroftheRainbow.push(UnoColor.CUSTOM(ClientPrefs.data.arrowRGBExtra[color][0], objects.Note.keysShit.get(17).get('letters')[color]));
            }

            // Create custom Pong-UNO cards (10% chance to include them)
            var customCards:Array<UnoCard> = [];
            if (FlxG.random.bool(10)) { // 10% chance
                // Create 4 Pong-UNO cards as wild cards
                for (i in 0...4) {
                    var pongCard = UnoCard.createCustomActionCard(
                        "Pong Battle",
                        UnoColor.WILD,
                        75,
                        8,
                        triggerPongBattle
                    );
                    customCards.push(pongCard);
                }
                trace("Added 4 Pong-UNO cards to deck!");
            }

            // Create UNO game with custom cards
            unoGame = new UnoGame(null, true, customCards.length > 0 ? customCards : null);

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

        //try {
            if (unoGame.players.length > 0) {
                FlxG.camera.visible = false;
                Paths.clearStoredMemory();
                Paths.clearUnusedMemory();
                //toggleHideScreen(true);
                bgSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(34, 139, 34)); // Forest Green
                unoGame.startNewRound();
                selectedCardIndex = -1;
                isFirstCardPlayed = false; // Reset first card animation
                resetCardSelection(); // Clear any card selection
                previousHandCards = []; // Reset hand tracking
                isPlayingCard = false; // Reset animation state
                updateDisplay();
                isGameStarted = true;
                resetUI();
                FlxG.camera.visible = true;
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
                isFirstCardPlayed = false; // Reset first card animation
                resetCardSelection(); // Clear any card selection
                previousHandCards = []; // Reset hand tracking
                isPlayingCard = false; // Reset animation state
                updateDisplay();

                trace("Game started successfully");
            }
        /*} catch (e:Dynamic) {
            trace("Error starting UNO game: " + e);
            updateInstructionText("Error starting game: " + Std.string(e));
            isGameStarted = false;
        }*/
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

            var oneCardLeft:Int = 0;
            for (player in unoGame.players) {
                if (player.hand.cards.length == 1) {
                    oneCardLeft++;
                }
            }
            if (oneCardLeft > 0 && !onLastCard) {
                if (lastcardMus != null && lastcardMus.playing)
                {
                    @:privateAccess
                    {
                        lime.media.openal.AL.effectf( af, lime.media.openal.AL.PITCH, oneCardLeft); // set pitch
                    }
                }
                FlxTween.num(1, 0, 1, {ease: FlxEase.sineInOut}, function(value:Float)
                {
                    normalMus.volume = value;
                });
                FlxTween.num(0, 1, 1, {ease: FlxEase.sineInOut}, function(value:Float)
                {
                    lastcardMus.volume = value;
                });
                onLastCard = true;
            } else if (oneCardLeft == 0 && onLastCard) {
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

                // Add first card appearance animation
                if (!isFirstCardPlayed) {
                    isFirstCardPlayed = true;
                    topCardSprite.alpha = 0;
                    topCardSprite.scale.set(0.1, 0.1);
                    add(topCardSprite);

                    FlxTween.tween(topCardSprite, {alpha: 1}, 0.5, {ease: FlxEase.sineOut});
                    FlxTween.tween(topCardSprite.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.backOut});
                } else {
                    add(topCardSprite);
                }
            }
        } catch (e:Dynamic) {
            trace("Error updating top card display: " + e);
        }
    }

    private function updatePlayerHandDisplay():Void {
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

            var currentCards = humanPlayer.hand.cards.copy();
            var startX = 50;
            var y = FlxG.height - 200;
            var cardCount = currentCards.length;

            // Calculate card spacing with compression
            var cardWidth = 80;
            var idealSpacing = 60;
            var totalIdealWidth = cardCount * idealSpacing;
            var cardSpacing = idealSpacing;

            // Compress cards if they would go off screen
            if (totalIdealWidth > maxHandWidth) {
                cardSpacing = Std.int(maxHandWidth / cardCount);
                // Ensure minimum spacing
                if (cardSpacing < 30) {
                    cardSpacing = 30;
                }
            }

            // Determine if this is initial deal or just an update
            var isInitialDeal = previousHandCards.length == 0;
            var newCardIndices:Array<Int> = [];
            var existingCardMap:Map<UnoCard, Int> = new Map();

            // Map existing cards to their new positions
            if (!isInitialDeal) {
                for (i in 0...currentCards.length) {
                    var card = currentCards[i];
                    var isNewCard = true;
                    for (j in 0...previousHandCards.length) {
                        if (previousHandCards[j] == card) {
                            isNewCard = false;
                            existingCardMap.set(card, i);
                            break;
                        }
                    }
                    if (isNewCard) {
                        newCardIndices.push(i);
                    }
                }
            }

            // Store current sprites for repositioning
            var currentSprites:Array<{sprite:FlxSprite, card:UnoCard}> = [];
            for (i in 0...playerHandGroup.length) {
                var sprite = playerHandGroup.members[i];
                if (sprite != null && i < previousHandCards.length) {
                    currentSprites.push({sprite: sprite, card: previousHandCards[i]});
                }
            }

            // Clear existing animations
            for (sprite in currentSprites) {
                if (cardAnimations.exists(sprite.sprite)) {
                    cardAnimations.get(sprite.sprite).cancel();
                    cardAnimations.remove(sprite.sprite);
                }
            }

            // Clear group but keep sprites for reuse/repositioning
            playerHandGroup.clear();

            // Create new hand display
            for (i in 0...currentCards.length) {
                var card = currentCards[i];
                var targetX = startX + (i * cardSpacing);
                var targetY = y;
                var cardSprite:FlxSprite = null;

                // Check if this card already has a sprite
                var existingSprite:FlxSprite = null;
                for (spriteData in currentSprites) {
                    if (spriteData.card == card) {
                        existingSprite = spriteData.sprite;
                        break;
                    }
                }

                if (existingSprite != null) {
                    // Reuse existing sprite and animate to new position
                    cardSprite = existingSprite;
                    playerHandGroup.add(cardSprite);

                    // Animate to new position if it changed
                    if (Math.abs(cardSprite.x - targetX) > 5 || Math.abs(cardSprite.y - targetY) > 5) {
                        var tween = FlxTween.tween(cardSprite, {x: targetX, y: targetY}, 0.3, {
                            ease: FlxEase.sineOut
                        });
                        cardAnimations.set(cardSprite, tween);
                    }
                } else {
                    // Create new sprite for new card
                    cardSprite = createCardSprite(card, targetX, targetY);
                    playerHandGroup.add(cardSprite);

                    if (isInitialDeal) {
                        // Initial deal - animate from above
                        cardSprite.alpha = 0;
                        cardSprite.y -= 50;

                        var animDelay = i * 0.1; // Stagger animations
                        var fadeIn = FlxTween.tween(cardSprite, {alpha: 1, y: targetY}, 0.3, {
                            ease: FlxEase.sineOut,
                            startDelay: animDelay
                        });
                        cardAnimations.set(cardSprite, fadeIn);
                    } else {
                        // Drawn card - fly from deck to position
                        var deckX = FlxG.width * 0.5 + 50; // Deck position (right of center pile)
                        var deckY = 150;

                        cardSprite.x = deckX;
                        cardSprite.y = deckY;
                        cardSprite.alpha = 0.8;
                        cardSprite.scale.set(1.5, 1.5); // Start larger (deck size)

                        // Animate flying to hand position
                        var flyTween = FlxTween.tween(cardSprite, {
                            x: targetX,
                            y: targetY,
                            alpha: 1
                        }, 0.5, {
                            ease: FlxEase.sineOut
                        });
                        cardAnimations.set(cardSprite, flyTween);

                        // Scale down to hand size
                        FlxTween.tween(cardSprite.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.sineOut});
                    }
                }

                // Store position for next update
                previousCardPositions.set(card, {x: targetX, y: targetY});
            }

            // Destroy any leftover sprites that weren't reused
            for (spriteData in currentSprites) {
                var wasReused = false;
                for (newCard in currentCards) {
                    if (spriteData.card == newCard) {
                        wasReused = true;
                        break;
                    }
                }
                if (!wasReused) {
                    if (cardAnimations.exists(spriteData.sprite)) {
                        cardAnimations.get(spriteData.sprite).cancel();
                        cardAnimations.remove(spriteData.sprite);
                    }
                    spriteData.sprite.destroy();
                }
            }

            // Update previous hand state
            previousHandCards = currentCards.copy();

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
            // Shake animation for invalid card
            if (cardIndex < playerHandGroup.length) {
                var cardSprite = playerHandGroup.members[cardIndex];
                if (cardSprite != null) {
                    animateCardInvalid(cardSprite);
                }
            }
            Cursor.cursorMode = Default;
            return;
        }

        // Immediately stop hover effects and clear selection states
        isPlayingCard = true;
        resetCardSelection();
        Cursor.cursorMode = Default;

        selectedCardIndex = cardIndex;

        if (card.isWildCard()) {
            // Show color choice
            showColorChoice();
        } else {
            // Play the card directly with animation
            var cardSprite = (cardIndex < playerHandGroup.length) ? playerHandGroup.members[cardIndex] : null;
            if (cardSprite != null) {
                // Cancel any existing animations on this sprite
                if (cardAnimations.exists(cardSprite)) {
                    cardAnimations.get(cardSprite).cancel();
                    cardAnimations.remove(cardSprite);
                }

                // Reset sprite to base state before animation
                cardSprite.color = FlxColor.WHITE;
                cardSprite.angle = 0;

                animateCardPlay(cardSprite, function() {
                    // The card play happens after animation completes
                    var success = unoGame.playCard(currentPlayer, cardIndex);
                    if (success) {
                        selectedCardIndex = -1;
                        isPlayingCard = false;
                    } else {
                        updateInstructionText("Failed to play card!", true);
                        isPlayingCard = false;
                    }
                });
            } else {
                // Fallback if no sprite
                var success = unoGame.playCard(currentPlayer, cardIndex);
                if (success) {
                    selectedCardIndex = -1;
                } else {
                    updateInstructionText("Failed to play card!", true);
                }
                isPlayingCard = false;
            }
        }
    }

    /**
     * Animate card selection (hover effect)
     */
    private function animateCardSelection(cardSprite:FlxSprite, select:Bool):Void {
        if (cardSprite == null) return;

        // Cancel existing animation
        if (cardAnimations.exists(cardSprite)) {
            cardAnimations.get(cardSprite).cancel();
            cardAnimations.remove(cardSprite);
        }

        if (select) {
            // Lift and brighten card
            var tween = FlxTween.tween(cardSprite, {y: cardSprite.y - 10}, 0.15, {ease: FlxEase.sineOut});
            cardAnimations.set(cardSprite, tween);
            cardSprite.color = FlxColor.fromRGBFloat(1.2, 1.2, 1.2);
        } else {
            // Return card to normal position
            var originalY = FlxG.height - 200;
            var tween = FlxTween.tween(cardSprite, {y: originalY}, 0.15, {ease: FlxEase.sineOut});
            cardAnimations.set(cardSprite, tween);
            cardSprite.color = FlxColor.WHITE;
        }
    }

    /**
     * Reset card selection
     */
    private function resetCardSelection():Void {
        if (selectedCardSprite != null) {
            // Cancel any existing animation
            if (cardAnimations.exists(selectedCardSprite)) {
                cardAnimations.get(selectedCardSprite).cancel();
                cardAnimations.remove(selectedCardSprite);
            }

            // Reset sprite to normal state
            selectedCardSprite.y = FlxG.height - 200;
            selectedCardSprite.color = FlxColor.WHITE;
            selectedCardSprite.angle = 0;
            selectedCardSprite = null;
        }
    }

    /**
     * Get the color chosen for a wild card (simplified - you might want to show a color picker UI)
     */
    private function getWildCardChosenColor():FlxColor {
        // For now, randomly choose a color - in a real game you'd show a color picker
        var colors = [FlxColor.RED, FlxColor.BLUE, FlxColor.GREEN, FlxColor.YELLOW];
        return colors[FlxG.random.int(0, colors.length - 1)];
    }

    /**
     * Animate card being played
     */
    private function animateCardPlay(cardSprite:FlxSprite, onComplete:Void->Void):Void {
        if (cardSprite == null) {
            isPlayingCard = false;
            onComplete();
            return;
        }

        // Check if this is a wild card by examining its color/type
        var isWildCard = false;
        var cardColor = FlxColor.WHITE; // Default color

        // Try to get the UnoCard data to check if it's wild
        for (i in 0...playerHandGroup.length) {
            var sprite = playerHandGroup.members[i];
            if (sprite == cardSprite && i < unoGame.players[0].hand.cards.length) {
                var card = unoGame.players[0].hand.cards[i];
                isWildCard = card.isWildCard();
                break;
            }
        }

        // Store original values for safety
        var originalColor = cardSprite.color;
        var centerX = FlxG.width * 0.5 - 40;
        var centerY = 150;

        if (isWildCard) {
            // For wild cards, first tween color then animate movement
            var targetColor = getWildCardChosenColor();

            // Color preview animation
            var colorTween = FlxTween.color(cardSprite, 0.3, originalColor, targetColor, {
                ease: FlxEase.sineInOut,
                onComplete: function(_) {
                    cardAnimations.remove(cardSprite);

                    // Now animate movement to center
                    var moveTween = FlxTween.tween(cardSprite, {
                        x: centerX,
                        y: centerY,
                        alpha: 0.8
                    }, 0.25, {
                        ease: FlxEase.sineOut,
                        onComplete: function(_) {
                            cardAnimations.remove(cardSprite);
                            // Reset cursor and playing state immediately
                            Cursor.cursorMode = Default;
                            isPlayingCard = false;
                            onComplete();
                        }
                    });
                    cardAnimations.set(cardSprite, moveTween);

                    // Add slight rotation for style
                    FlxTween.angle(cardSprite, 0, 8, 0.25, {ease: FlxEase.sineOut});
                }
            });
            cardAnimations.set(cardSprite, colorTween);
        } else {
            // Regular card - just animate movement to center
            var tween = FlxTween.tween(cardSprite, {
                x: centerX,
                y: centerY,
                alpha: 0.8
            }, 0.25, {
                ease: FlxEase.sineOut,
                onComplete: function(_) {
                    cardAnimations.remove(cardSprite);
                    // Reset cursor and playing state immediately
                    Cursor.cursorMode = Default;
                    isPlayingCard = false;
                    onComplete();
                }
            });
            cardAnimations.set(cardSprite, tween);

            // Add slight rotation for style
            FlxTween.angle(cardSprite, 0, 8, 0.25, {ease: FlxEase.sineOut});
        }
    }

    /**
     * Animate invalid card selection (shake)
     */
    private function animateCardInvalid(cardSprite:FlxSprite):Void {
        if (cardSprite == null) return;

        // Cancel existing animation
        if (cardAnimations.exists(cardSprite)) {
            cardAnimations.get(cardSprite).cancel();
            cardAnimations.remove(cardSprite);
        }

        var originalX = cardSprite.x;
        var originalColor = cardSprite.color;
        var shakeAmount = 5;

        // Flash red briefly
        cardSprite.color = FlxColor.RED;

        // Shake animation
        var shakeCount = 0;
        var maxShakes = 6;

        function doShake() {
            if (shakeCount >= maxShakes) {
                // Return to original position and color
                cardSprite.x = originalX;
                cardSprite.color = originalColor;
                cardAnimations.remove(cardSprite);
                return;
            }

            var targetX = originalX + (shakeCount % 2 == 0 ? shakeAmount : -shakeAmount);
            var tween = FlxTween.tween(cardSprite, {x: targetX}, 0.05, {
                ease: FlxEase.sineInOut,
                onComplete: function(_) {
                    shakeCount++;
                    doShake();
                }
            });
            cardAnimations.set(cardSprite, tween);
        }

        doShake();

        // Color fade back to normal
        FlxTween.color(cardSprite, 0.4, FlxColor.RED, originalColor);
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
                    // Set playing flag to prevent hover interference
                    isPlayingCard = true;

                    // Animate the wild card being played
                    var cardSprite = (selectedCardIndex >= 0 && selectedCardIndex < playerHandGroup.length) ?
                                    playerHandGroup.members[selectedCardIndex] : null;

                    if (cardSprite != null) {
                        // Cancel any existing animations and reset sprite
                        if (cardAnimations.exists(cardSprite)) {
                            cardAnimations.get(cardSprite).cancel();
                            cardAnimations.remove(cardSprite);
                        }
                        cardSprite.color = FlxColor.WHITE;
                        cardSprite.angle = 0;

                        animateCardPlay(cardSprite, function() {
                            // Play the card after animation
                            var success = unoGame.playCard(humanPlayer, selectedCardIndex, chosenColor);
                            if (success) {
                                selectedCardIndex = -1;
                                waitingForColorChoice = false;
                                colorChoiceGroup.clear();
                                resetCardSelection();
                                updateInstructionText("Color Picked: "+chosenColor, true);
                            } else {
                                updateInstructionText("Failed to play wild card!", true);
                                waitingForColorChoice = false;
                                colorChoiceGroup.clear();
                            }
                            isPlayingCard = false;
                        });
                    } else {
                        // Fallback if no sprite
                        var success = unoGame.playCard(humanPlayer, selectedCardIndex, chosenColor);
                        if (success) {
                            selectedCardIndex = -1;
                            waitingForColorChoice = false;
                            colorChoiceGroup.clear();
                            resetCardSelection();
                            updateInstructionText("Color Picked: "+chosenColor, true);
                        } else {
                            updateInstructionText("Failed to play wild card!", true);
                            waitingForColorChoice = false;
                            colorChoiceGroup.clear();
                        }
                        isPlayingCard = false;
                        Cursor.cursorMode = Default;
                    }
                }
            }
        } catch (e:Dynamic) {
            trace("Error handling color choice: " + e);
            waitingForColorChoice = false;
            colorChoiceGroup.clear();
            isPlayingCard = false;
            Cursor.cursorMode = Default;
        }
    }    private function updateInstructionText(text:String, ?doFade:Bool = false):Void {
        var originalText = instructionText.text;
        if (instructionText != null) {
            instructionText.text = text;
            trace("Instruction: " + text);
            if (instructionFade != null) instructionFade.cancel();
            instructionText.alpha = 1;
            if (doFade) {
                instructionFade = FlxTween.tween(instructionText, {alpha: 0}, 1, {
                    startDelay: 3,
                    ease: FlxEase.quadOut,
                    onComplete: function(_) {
                        instructionText.alpha = 1;
                        instructionText.text = originalText;
                    }
                });
            }
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

        // Handle input (unless it's the trap version)
        if (!(this is archipelago.traps.games.APUnoTrapState)) {
            if (controls.BACK) {
                FlxG.mouse.visible = false;
                MusicBeatState.switchState(new MainMenuState());
            }
        } else {
            // Trap version - no escape allowed
            if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
                updateInstructionText("NO ESCAPE! You must win or die!");
                return;
            }
        }

        if (controls.ACCEPT) {
            if (!isGameStarted) {
                trace("Starting new UNO game...");
                startNewGame();
            }
        }

        // Open UNO options with O key
        if (FlxG.keys.justPressed.O && !isGameStarted) {
            openUnoOptions();
        }

        // Add debug key to restart game
        if (FlxG.keys.justPressed.R) {
            trace("Restarting UNO game...");
            isGameStarted = false;
            if (unoGame != null) {
                unoGame.players = [];
            }
            setupGame();
            updateInstructionText("Press ENTER to start a new game, R to restart, O for options, I for debug info, or ESCAPE to return to menu");
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
        }

        // Handle mouse hover effects for card selection
        if (isGameStarted && unoGame != null && unoGame.turnManager != null && !isPlayingCard) {
            var currentPlayer = unoGame.turnManager.getCurrentPlayer();
            if (currentPlayer != null && currentPlayer.isHuman && !waitingForColorChoice) {
                var foundHover = false;

                for (i in 0...playerHandGroup.length) {
                    var cardSprite = playerHandGroup.members[i];
                    if (cardSprite != null) {
                        if (FlxG.mouse.overlaps(cardSprite)) {
                            // Hover effect
                            if (selectedCardSprite != cardSprite) {
                                resetCardSelection();
                                selectedCardSprite = cardSprite;
                                animateCardSelection(cardSprite, true);
                            }
                            foundHover = true;
                            Cursor.cursorMode = Pointer;
                            break;
                        }
                    }
                }

                if (!foundHover && selectedCardSprite != null) {
                    resetCardSelection();
                    Cursor.cursorMode = Default;
                }
            }
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

    private function openUnoOptions():Void
    {
        var optionsSubState = new UnoOptionsSubState();

        // Set up callbacks for when options change
        optionsSubState.onColorsChanged = function(newColors:Array<UnoColor>) {
            trace('UNO colors updated: ${newColors.length} custom colors');
            // Reinitialize game with new colors if needed
            if (unoGame != null) {
                unoGame.customColors = newColors;
            }
        };

        optionsSubState.onRulesChanged = function() {
            trace('UNO rules updated');
            // Apply new rules to current game if needed
            if (unoGame != null) {
                // The rules are automatically applied since they're static properties
                trace('Rules applied to existing game');
            }
        };

        openSubState(optionsSubState);
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    /**
     * Trigger Pong battle when Pong-UNO card is played
     */
    private function triggerPongBattle(game:UnoGame):Void {
        trace("Pong battle triggered!");

        // Find the current player and the next player
        var currentPlayerIndex = game.turnManager.currentPlayerIndex;
        var nextPlayerIndex = (currentPlayerIndex + 1) % game.players.length;

        var currentPlayer = game.players[currentPlayerIndex];
        var nextPlayer = game.players[nextPlayerIndex];

        var pongSubstate = new PongUnoSubstate(currentPlayer, nextPlayer);

        // Set up callbacks for Pong results - loser draws 4 cards
        pongSubstate.onLeftPlayerWin = (losingPlayer:UnoPlayer) -> {
            trace('${currentPlayer.name} won Pong! ${losingPlayer.name} draws 4 cards.');
            unoGame.drawCards(losingPlayer, 4);
            updateInstructionText('${currentPlayer.name} won Pong! ${losingPlayer.name} drew 4 cards.');
        };

        pongSubstate.onRightPlayerWin = (losingPlayer:UnoPlayer) -> {
            trace('${nextPlayer.name} won Pong! ${losingPlayer.name} draws 4 cards.');
            unoGame.drawCards(losingPlayer, 4);
            updateInstructionText('${nextPlayer.name} won Pong! ${losingPlayer.name} drew 4 cards.');
        };

        openSubState(pongSubstate);
    }

    override function destroy() {
        // Clean up all card animations
        for (cardSprite in cardAnimations.keys()) {
            var tween = cardAnimations.get(cardSprite);
            if (tween != null) {
                tween.cancel();
            }
        }
        cardAnimations.clear();

        // Clean up music and audio effects
        if (normalMus != null) {
            normalMus.stop();
            normalMus.destroy();
        }
        if (lastcardMus != null) {
            lastcardMus.stop();
            lastcardMus.destroy();
        }

        // Clean up timers
        if (idleTimer != null) {
            idleTimer.cancel();
            idleTimer.destroy();
        }
        if (refreshTimer != null) {
            refreshTimer.cancel();
            refreshTimer.destroy();
        }

        super.destroy();
    }
}

/**
 * Helper class for UNO game UI management
 */
class UnoGameUI {
    // This could be expanded for more complex UI management
    // For now, keeping it simple with the state handling the UI directly
}
