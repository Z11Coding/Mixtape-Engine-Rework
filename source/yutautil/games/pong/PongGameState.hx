package yutautil.games.pong;

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
import objects.Alphabet;
import states.MainMenuState;
import yutautil.ExtendedDate;
import yutautil.KonamiTracker;
import yutautil.games.pong.backend.*;
import yutautil.games.pong.backend.PongGame.PongGameMode;
import yutautil.games.pong.backend.PongGame.PongPlayer;
import yutautil.games.pong.backend.PongPaddle.PongAIDifficulty;

/**
 * Pong Game State - A complete Pong game implementation
 */
class PongGameState extends MusicBeatState {
    // Game components
    private var pongGame:PongGame;
    private var isGameStarted:Bool = false;

    // Visual elements
    private var bgSprite:FlxSprite;
    private var fieldSprite:FlxSprite;
    private var gameStatusText:FlxText;
    private var instructionText:FlxText;
    private var leftScoreText:FlxText;
    private var rightScoreText:FlxText;

    // Game objects visual representations
    private var ballSprite:FlxSprite;
    private var leftPaddleSprite:FlxSprite;
    private var rightPaddleSprite:FlxSprite;

    // Ball trail effect
    private var ballTrailGroup:FlxTypedGroup<FlxSprite>;

    // UI elements
    private var pauseButton:PsychUIButton;
    private var menuGroup:FlxTypedGroup<FlxSprite>;
    private var menuTexts:FlxTypedGroup<FlxText>;
    private var selectedMenuItem:Int = 0;
    private var showingMenu:Bool = false;

    // Visual effects
    private var centerLine:FlxSprite;
    private var fieldBorder:FlxSprite;
    private var scoreFlashLeft:FlxSprite;
    private var scoreFlashRight:FlxSprite;

    // Audio
    private var bgMusic:FlxSound;

    // Game settings
    private var currentGameMode:PongGameMode = PLAYER_VS_AI;
    private var currentAIDifficulty:PongAIDifficulty = NORMAL;

    // Rendering offsets
    private var gameFieldOffsetX:Float = 0;
    private var gameFieldOffsetY:Float = 0;

    // Cheat system
    private var konamiTracker:KonamiTracker;
    private var debugTracesEnabled:Bool = false;
    private var rainbowMode:Bool = ExtendedDate.global().isPrideMonth();
    private var godModeUnlocked:Bool = false;
    private var rainbowTimer:Float = 0;
    private var leftPaddleOriginalColor:FlxColor;
    private var rightPaddleOriginalColor:FlxColor;
    private var leftPaddleRainbowTimer:Float = 0;
    private var rightPaddleRainbowTimer:Float = 0;
    private var leftPaddleIsRainbow:Bool = false;
    private var rightPaddleIsRainbow:Bool = false;

    // Default settings (can be set before create())
    private var defaultGameMode:PongGameMode = null;
    private var defaultAIDifficulty:PongAIDifficulty = null;
    private var defaultMaxScore:Int = 10;
    private var defaultBallSpeed:Float = 200;
    private var defaultPaddleSpeed:Float = 350;

    override function create() {
        super.create();

        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Playing Pong", "In Pong Game");
        #end

        setupBackground();
        setupField();
        setupUI();
        setupGame();
        setupCheats();

        // Apply default settings if any were set
        applyDefaultSettings();

        Cursor.show();
        Cursor.cursorMode = Default;

        // Setup background music (optional)
        setupAudio();
    }

    private function setupBackground():Void {
        // Create dark background
        bgSprite = new FlxSprite();
        bgSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(10, 10, 15));
        add(bgSprite);
    }

    private function setupField():Void {
        // Calculate field dimensions (leave margins for UI)
        var fieldMargin = 50;
        var fieldX = fieldMargin;
        var fieldY = fieldMargin + 60; // Extra space for score
        var fieldWidth = FlxG.width - (fieldMargin * 2);
        var fieldHeight = FlxG.height - (fieldMargin * 2) - 120; // Space for UI

        // Create field background
        fieldSprite = new FlxSprite(fieldX, fieldY);
        fieldSprite.makeGraphic(Std.int(fieldWidth), Std.int(fieldHeight), FlxColor.fromRGB(20, 20, 30));
        add(fieldSprite);

        // Create field border
        fieldBorder = new FlxSprite(fieldX - 2, fieldY - 2);
        fieldBorder.makeGraphic(Std.int(fieldWidth + 4), Std.int(fieldHeight + 4), FlxColor.WHITE);
        fieldBorder.stamp(fieldSprite, 2, 2);
        add(fieldBorder);

        // Create center line
        centerLine = new FlxSprite(fieldX + fieldWidth / 2 - 1, fieldY);
        centerLine.makeGraphic(2, Std.int(fieldHeight), FlxColor.fromRGBFloat(1, 1, 1, 0.5));
        add(centerLine);

        // Create dotted center line effect
        for (i in 0...Std.int(fieldHeight / 20)) {
            if (i % 2 == 0) {
                var dot = new FlxSprite(fieldX + fieldWidth / 2 - 2, fieldY + i * 20);
                dot.makeGraphic(4, 10, FlxColor.WHITE);
                add(dot);
            }
        }

        // Initialize game with field dimensions
        pongGame = new PongGame(fieldWidth, fieldHeight, 10);

        // Store field offset for rendering
        gameFieldOffsetX = fieldX;
        gameFieldOffsetY = fieldY;
    }

    private function setupUI():Void {
        // Game status text
        gameStatusText = new FlxText(10, 10, FlxG.width - 20, "", 16);
        gameStatusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        add(gameStatusText);

        // Score display
        leftScoreText = new FlxText(FlxG.width * 0.25, 30, 200, "0", 48);
        leftScoreText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER);
        add(leftScoreText);

        rightScoreText = new FlxText(FlxG.width * 0.75 - 200, 30, 200, "0", 48);
        rightScoreText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER);
        add(rightScoreText);

        // Score flash effects
        scoreFlashLeft = new FlxSprite();
        scoreFlashLeft.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 1, 0, 0));
        add(scoreFlashLeft);

        scoreFlashRight = new FlxSprite();
        scoreFlashRight.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 1, 0));
        add(scoreFlashRight);

        // Instruction text
        instructionText = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 14);
        instructionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, CENTER);
        add(instructionText);

        // Pause button
        pauseButton = new PsychUIButton(FlxG.width - 120, 10, "Pause", function() {
            if (isGameStarted && pongGame.isGameActive) {
                var isPaused = pongGame.togglePause();
                pauseButton.text.text = isPaused ? "Resume" : "Pause";
                updateInstructionText(isPaused ? "Game Paused - Click Resume or press P" : "Game Resumed");
            }
        });
        pauseButton.resize(100, 30);
        add(pauseButton);

        // Ball trail group
        ballTrailGroup = new FlxTypedGroup<FlxSprite>();
        add(ballTrailGroup);

        // Create game object sprites
        createGameSprites();

        // Setup menu
        setupMenu();

        updateInstructionText("Press ENTER to start, M for menu, or ESCAPE to return to main menu");
    }

    private function createGameSprites():Void {
        if (pongGame == null) return;

        // Ball sprite
        ballSprite = new FlxSprite();
        ballSprite.makeGraphic(Std.int(pongGame.ball.width), Std.int(pongGame.ball.height), FlxColor.WHITE);
        add(ballSprite);

        // Paddle sprites
        leftPaddleOriginalColor = FlxColor.fromRGB(100, 200, 255);
        rightPaddleOriginalColor = FlxColor.fromRGB(255, 100, 100);

        leftPaddleSprite = new FlxSprite();
        leftPaddleSprite.makeGraphic(Std.int(pongGame.leftPaddle.width), Std.int(pongGame.leftPaddle.height), leftPaddleOriginalColor);
        add(leftPaddleSprite);

        rightPaddleSprite = new FlxSprite();
        rightPaddleSprite.makeGraphic(Std.int(pongGame.rightPaddle.width), Std.int(pongGame.rightPaddle.height), rightPaddleOriginalColor);
        add(rightPaddleSprite);
    }

    private function setupMenu():Void {
        menuGroup = new FlxTypedGroup<FlxSprite>();
        menuTexts = new FlxTypedGroup<FlxText>();

        // Menu background
        var menuBg = new FlxSprite();
        menuBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.8));
        menuGroup.add(menuBg);

        // Menu options
        var menuOptions = [
            "Resume Game",
            "New Game - Player vs AI",
            "New Game - Two Player",
            "New Game - AI vs AI",
            "AI Difficulty: " + getDifficultyName(currentAIDifficulty),
            "Return to Main Menu"
        ];

        for (i in 0...menuOptions.length) {
            var optionText = new FlxText(0, 200 + i * 60, FlxG.width, menuOptions[i], 24);
            optionText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
            menuTexts.add(optionText);
        }

        add(menuGroup);
        add(menuTexts);

        menuGroup.visible = false;
        menuTexts.visible = false;
    }

    private function setupGame():Void {
        if (pongGame == null) return;

        setupGameEvents();
        if (debugTracesEnabled) {
            trace("Pong game initialized successfully");
        }
    }

    private function setupCheats():Void {
        konamiTracker = new KonamiTracker();

        // Debug traces cheat - spell "DEBUG"
        konamiTracker.addCheatFromString("DEBUG", function(cheat) {
            debugTracesEnabled = !debugTracesEnabled;
            var status = debugTracesEnabled ? "ENABLED" : "DISABLED";
            updateInstructionText('Debug traces ' + status + '!');
            if (debugTracesEnabled) {
                trace("Debug traces enabled in Pong!");
            }
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        // Rainbow mode cheat - spell "LGBT"
        konamiTracker.addCheatFromString("LGBT", function(cheat) {
            rainbowMode = !rainbowMode;
            var status = rainbowMode ? "ENABLED" : "DISABLED";
            updateInstructionText('Rainbow mode ' + status + '! 🌈');
            if (debugTracesEnabled) {
                trace("Rainbow mode " + status.toLowerCase() + "!");
            }
            if (!rainbowMode) {
                // Reset ball and paddles to original colors
                if (ballSprite != null) {
                    ballSprite.color = FlxColor.WHITE;
                }
                resetPaddleColors();
            }
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        // God mode unlock cheat - spell "GODISREAL"
        konamiTracker.addCheatFromString("GODISREAL", function(cheat) {
            if (!godModeUnlocked) {
                godModeUnlocked = true;
                updateInstructionText('GOD MODE UNLOCKED! The ultimate AI difficulty is now available!');
                if (debugTracesEnabled) {
                    trace("GOD MODE has been unlocked!");
                }
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);

                // Visual effect - flash the screen briefly
                var godFlash = new FlxSprite();
                godFlash.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(1, 1, 0, 0.5));
                add(godFlash);
                FlxTween.tween(godFlash, {alpha: 0}, 1.0, {
                    onComplete: function(_) {
                        remove(godFlash);
                        godFlash.destroy();
                    }
                });
            } else {
                updateInstructionText('GOD MODE already unlocked!');
                if (debugTracesEnabled) {
                    trace("GOD MODE was already unlocked");
                }
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
            }
        });

        add(konamiTracker);
    }

    private function setupGameEvents():Void {
        if (pongGame == null) return;

        pongGame.onGameStart = () -> {
            isGameStarted = true;
            updateInstructionText("Use W/S or Arrow Keys to control paddles. Press P to pause");
            PongSounds.playGameStart();
        };

        pongGame.onScore = (player, leftScore, rightScore) -> {
            leftScoreText.text = Std.string(leftScore);
            rightScoreText.text = Std.string(rightScore);

            // Flash screen effect
            if (player == LEFT) {
                FlxTween.tween(scoreFlashLeft, {alpha: 0.3}, 0.1, {
                    onComplete: function(_) {
                        FlxTween.tween(scoreFlashLeft, {alpha: 0}, 0.3);
                    }
                });
            } else {
                FlxTween.tween(scoreFlashRight, {alpha: 0.3}, 0.1, {
                    onComplete: function(_) {
                        FlxTween.tween(scoreFlashRight, {alpha: 0}, 0.3);
                    }
                });
            }

            PongSounds.playScore();
        };

        pongGame.onGameEnd = (winner) -> {
            isGameStarted = false;
            var winnerName = winner == LEFT ? "Left Player" : "Right Player";
            updateInstructionText('$winnerName Wins! Press ENTER to play again or M for menu');
            PongSounds.playGameEnd();
        };

        pongGame.onPaddleHit = (paddle) -> {
            PongSounds.playPaddleHit();

            // Visual feedback on paddle hit
            var paddleSprite = paddle == pongGame.leftPaddle ? leftPaddleSprite : rightPaddleSprite;
            var isLeftPaddle = paddle == pongGame.leftPaddle;

            if (rainbowMode) {
                // Start rainbow cycle for the paddle that was hit
                if (isLeftPaddle) {
                    leftPaddleIsRainbow = true;
                    leftPaddleRainbowTimer = 0;
                } else {
                    rightPaddleIsRainbow = true;
                    rightPaddleRainbowTimer = 0;
                }
                if (debugTracesEnabled) {
                    trace("Paddle hit - starting rainbow effect for " + (isLeftPaddle ? "left" : "right") + " paddle");
                }
            } else {
                // Normal color flash
                var originalColor = isLeftPaddle ? leftPaddleOriginalColor : rightPaddleOriginalColor;
                FlxTween.color(paddleSprite, 0.1, FlxColor.WHITE, originalColor);
            }
        };

        pongGame.onBallBounce = () -> {
            PongSounds.playWallBounce();
        };
    }

    private function setupAudio():Void {
        // Optional background music - using existing menu music
        // bgMusic = FlxG.sound.load(Paths.music('menuMusic/Heart of the Cards'));
        // bgMusic.looped = true;
        // bgMusic.volume = 0.3;
        // bgMusic.play();
    }

    private function startNewGame(mode:PongGameMode = null):Void {
        if (pongGame == null) return;

        if (mode != null) {
            currentGameMode = mode;
        }

        // Check if GOD difficulty is selected but not unlocked
        if (currentAIDifficulty == GOD && !godModeUnlocked) {
            currentAIDifficulty = NORMAL; // Fallback to normal difficulty
            updateInstructionText("GOD difficulty is locked! Use cheat 'GODISREAL' to unlock it. Set to Normal for now.");
        }

        pongGame.resetGame();
        pongGame.startGame(currentGameMode);

        // Update AI difficulty
        if (currentGameMode == PLAYER_VS_AI || currentGameMode == AI_VS_AI) {
            pongGame.setAIDifficulty(pongGame.rightPaddle, currentAIDifficulty);
            if (currentGameMode == AI_VS_AI) {
                pongGame.setAIDifficulty(pongGame.leftPaddle, currentAIDifficulty);
            }
        }

        updateDisplay();
    }

    private function updateDisplay():Void {
        if (pongGame == null) return;

        // Update status text
        gameStatusText.text = pongGame.getGameStatus();

        // Update score display
        leftScoreText.text = Std.string(pongGame.leftScore);
        rightScoreText.text = Std.string(pongGame.rightScore);

        // Update game object positions
        if (ballSprite != null) {
            ballSprite.x = gameFieldOffsetX + pongGame.ball.position.x - pongGame.ball.radius;
            ballSprite.y = gameFieldOffsetY + pongGame.ball.position.y - pongGame.ball.radius;
        }

        if (leftPaddleSprite != null) {
            leftPaddleSprite.x = gameFieldOffsetX + pongGame.leftPaddle.x;
            leftPaddleSprite.y = gameFieldOffsetY + pongGame.leftPaddle.y;
        }

        if (rightPaddleSprite != null) {
            rightPaddleSprite.x = gameFieldOffsetX + pongGame.rightPaddle.x;
            rightPaddleSprite.y = gameFieldOffsetY + pongGame.rightPaddle.y;
        }

        // Update ball trail
        updateBallTrail();
    }

    private function updateBallTrail():Void {
        if (pongGame == null || !pongGame.isRoundActive) return;

        // Clear old trail sprites
        ballTrailGroup.clear();

        // Create trail sprites from ball trail data
        for (i in 0...pongGame.ballTrail.length) {
            var trailPoint = pongGame.ballTrail[i];
            var alpha = 1.0 - (trailPoint.time / 0.5); // Fade over 0.5 seconds

            if (alpha > 0) {
                var trailSprite = new FlxSprite();
                var size = Std.int(pongGame.ball.radius * alpha);
                trailSprite.makeGraphic(size, size, FlxColor.fromRGBFloat(1, 1, 1, alpha * 0.5));
                trailSprite.x = gameFieldOffsetX + trailPoint.x - size / 2;
                trailSprite.y = gameFieldOffsetY + trailPoint.y - size / 2;
                ballTrailGroup.add(trailSprite);
            }
        }
    }

    private function updateInstructionText(text:String):Void {
        if (instructionText != null) {
            instructionText.text = text;
        }
    }

    private function toggleMenu():Void {
        showingMenu = !showingMenu;
        menuGroup.visible = showingMenu;
        menuTexts.visible = showingMenu;

        if (showingMenu) {
            selectedMenuItem = 0;
            updateMenuSelection();
            if (isGameStarted && pongGame.isGameActive) {
                pongGame.togglePause(); // Pause when menu opens
                pauseButton.text.text = "Resume";
            }
        } else {
            if (isGameStarted && pongGame.isGameActive && !pongGame.isRoundActive) {
                pongGame.togglePause(); // Resume when menu closes
                pauseButton.text.text = "Pause";
            }
        }
    }

    private function updateMenuSelection():Void {
        if (!showingMenu) return;

        for (i in 0...menuTexts.length) {
            var text = menuTexts.members[i];
            if (text != null) {
                text.color = i == selectedMenuItem ? FlxColor.YELLOW : FlxColor.WHITE;
            }
        }

        // Update AI difficulty text
        if (menuTexts.members[4] != null) {
            menuTexts.members[4].text = "AI Difficulty: " + getDifficultyName(currentAIDifficulty);
        }
    }

    private function handleMenuSelection():Void {
        if (!showingMenu) return;

        switch (selectedMenuItem) {
            case 0: // Resume Game
                toggleMenu();

            case 1: // New Game - Player vs AI
                currentGameMode = PLAYER_VS_AI;
                startNewGame(currentGameMode);
                toggleMenu();

            case 2: // New Game - Two Player
                currentGameMode = TWO_PLAYER;
                startNewGame(currentGameMode);
                toggleMenu();

            case 3: // New Game - AI vs AI
                currentGameMode = AI_VS_AI;
                startNewGame(currentGameMode);
                toggleMenu();

            case 4: // AI Difficulty
                cycleAIDifficulty();
                updateMenuSelection();

            case 5: // Return to Main Menu
                FlxG.mouse.visible = false;
                MusicBeatState.switchState(new MainMenuState());
        }
    }

    private function cycleAIDifficulty():Void {
        currentAIDifficulty = switch (currentAIDifficulty) {
            case EASY: NORMAL;
            case NORMAL: HARD;
            case HARD: EXPERT;
            case EXPERT: YES;
            case YES:
                if (godModeUnlocked) {
                    GOD;
                } else {
                    EASY; // Skip GOD if not unlocked, go back to EASY
                }
            case GOD: EASY;
        };
    }

    private function getDifficultyName(difficulty:PongAIDifficulty):String {
        return switch (difficulty) {
            case EASY: "Easy";
            case NORMAL: "Normal";
            case HARD: "Hard";
            case EXPERT: "Expert";
            case YES: "Yes";
            case GOD:
                if (godModeUnlocked) {
                    "GOD MODE";
                } else {
                    "??? (LOCKED)";
                }
        };
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // Handle menu navigation
        if (showingMenu) {
            if (controls.UI_UP_P) {
                selectedMenuItem = selectedMenuItem > 0 ? selectedMenuItem - 1 : menuTexts.length - 1;
                updateMenuSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }

            if (controls.UI_DOWN_P) {
                selectedMenuItem = selectedMenuItem < menuTexts.length - 1 ? selectedMenuItem + 1 : 0;
                updateMenuSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }

            if (controls.ACCEPT) {
                handleMenuSelection();
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
            }

            if (controls.BACK || FlxG.keys.justPressed.M) {
                toggleMenu();
                FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
            }

            return; // Don't process game input while menu is open
        }

        // Handle global controls (unless it's the trap version)
        if (!(this is archipelago.traps.games.APPongTrapState)) {
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
            if (!isGameStarted || !pongGame.isGameActive) {
                startNewGame();
            }
        }

        if (FlxG.keys.justPressed.M) {
            toggleMenu();
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        }

        if (FlxG.keys.justPressed.P && isGameStarted && pongGame.isGameActive) {
            var isPaused = pongGame.togglePause();
            pauseButton.text.text = isPaused ? "Resume" : "Pause";
            updateInstructionText(isPaused ? "Game Paused - Press P to resume" : "Game Resumed");
        }

        // Update game
        if (pongGame != null) {
            pongGame.update(elapsed);
            updateDisplay();
        }

        // Update rainbow effects
        if (rainbowMode) {
            updateRainbowEffects(elapsed);
        }
    }

    /**
     * Set default game mode (call before create())
     */
    public function setDefaultGameMode(mode:PongGameMode):Void {
        defaultGameMode = mode;
    }

    /**
     * Set default settings (call before create())
     */
    public function setDefaultSettings(
        mode:PongGameMode,
        difficulty:PongAIDifficulty,
        maxScore:Int,
        ballSpeed:Float,
        paddleSpeed:Float
    ):Void {
        defaultGameMode = mode;
        defaultAIDifficulty = difficulty;
        defaultMaxScore = maxScore;
        defaultBallSpeed = ballSpeed;
        defaultPaddleSpeed = paddleSpeed;
    }

    /**
     * Unlock GOD mode (can be called externally)
     */
    public function unlockGodMode():Void {
        if (!godModeUnlocked) {
            godModeUnlocked = true;
            if (debugTracesEnabled) {
                trace("GOD MODE unlocked externally");
            }
        }
    }

    /**
     * Check if GOD mode is unlocked
     */
    public function isGodModeUnlocked():Bool {
        return godModeUnlocked;
    }

    /**
     * Apply default settings if they were set
     */
    private function applyDefaultSettings():Void {
        if (defaultGameMode != null) {
            currentGameMode = defaultGameMode;
        }
        if (defaultAIDifficulty != null) {
            currentAIDifficulty = defaultAIDifficulty;
        }
        if (pongGame != null) {
            pongGame.maxScore = defaultMaxScore;
            pongGame.ball.speed = defaultBallSpeed;
            pongGame.leftPaddle.speed = defaultPaddleSpeed;
            pongGame.rightPaddle.speed = defaultPaddleSpeed;
        }
    }

    /**
     * Update rainbow effects when rainbow mode is active
     */
    private function updateRainbowEffects(elapsed:Float):Void {
        if (!rainbowMode) return;

        rainbowTimer += elapsed;

        // Make ball rainbow
        if (ballSprite != null) {
            var ballHue = (rainbowTimer * 120) % 360; // Rotate hue over time
            ballSprite.color = FlxColor.fromHSB(ballHue, 1.0, 1.0);
        }

        // Handle paddle rainbow cycles
        if (leftPaddleIsRainbow) {
            leftPaddleRainbowTimer += elapsed;
            var duration = 2.0; // Rainbow cycle duration

            if (leftPaddleRainbowTimer < duration) {
                var progress = leftPaddleRainbowTimer / duration;
                var hue = progress * 360;
                leftPaddleSprite.color = FlxColor.fromHSB(hue, 0.8, 1.0);
            } else {
                // Rainbow cycle complete, return to original color
                leftPaddleIsRainbow = false;
                leftPaddleSprite.color = leftPaddleOriginalColor;
                if (debugTracesEnabled) {
                    trace("Left paddle rainbow cycle complete");
                }
            }
        }

        if (rightPaddleIsRainbow) {
            rightPaddleRainbowTimer += elapsed;
            var duration = 2.0; // Rainbow cycle duration

            if (rightPaddleRainbowTimer < duration) {
                var progress = rightPaddleRainbowTimer / duration;
                var hue = progress * 360;
                rightPaddleSprite.color = FlxColor.fromHSB(hue, 0.8, 1.0);
            } else {
                // Rainbow cycle complete, return to original color
                rightPaddleIsRainbow = false;
                rightPaddleSprite.color = rightPaddleOriginalColor;
                if (debugTracesEnabled) {
                    trace("Right paddle rainbow cycle complete");
                }
            }
        }
    }

    /**
     * Reset paddle colors to their original values
     */
    private function resetPaddleColors():Void {
        leftPaddleIsRainbow = false;
        rightPaddleIsRainbow = false;
        leftPaddleRainbowTimer = 0;
        rightPaddleRainbowTimer = 0;

        if (leftPaddleSprite != null) {
            leftPaddleSprite.color = leftPaddleOriginalColor;
        }
        if (rightPaddleSprite != null) {
            rightPaddleSprite.color = rightPaddleOriginalColor;
        }
    }
}
