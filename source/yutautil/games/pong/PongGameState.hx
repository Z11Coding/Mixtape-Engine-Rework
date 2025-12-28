package yutautil.games.pong;

import backend.MusicBeatState;
import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
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
import yutautil.games.pong.objects.BossSpecialBall;
import yutautil.games.pong.objects.BossStarObstacle;

/**
 * Pong Game State - A complete Pong game implementation
 */
class PongGameState extends MusicBeatState {
    // private var oldFramerate:Int = -1;
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

    // Debug display
    private var ballDebugText:FlxText;
    private var ballDebugEnabled:Bool = false;

    // Game objects visual representations
    private var ballSprite:FlxSprite;
    private var leftPaddleSprite:FlxSprite;
    private var rightPaddleSprite:FlxSprite;

    // Ball rotation and momentum visual effects
    private var ballRotationTween:FlxTween;

    // Ball trail effect
    private var ballTrailGroup:FlxTypedGroup<FlxSprite>;
    private var trailSpritePool:Array<FlxSprite> = [];
    private var lastTrailUpdate:Float = 0;

    // Dash trail effects
    private var leftPaddleTrailGroup:FlxTypedGroup<FlxSprite>;
    private var rightPaddleTrailGroup:FlxTypedGroup<FlxSprite>;

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

    // Boost visual effect tracking
    private var leftPaddleIsBoosting:Bool = false;
    private var rightPaddleIsBoosting:Bool = false;

    // Dash mechanic
    private var dashEnabled:Bool = false;
    private var leftPaddleDashCooldown:Float = 0;
    private var rightPaddleDashCooldown:Float = 0;
    private var leftPaddleDashBar:FlxSprite;
    private var rightPaddleDashBar:FlxSprite;
    private var leftPaddleDashBarBg:FlxSprite;
    private var rightPaddleDashBarBg:FlxSprite;

    // Boost mechanic visual bars
    private var leftPaddleBoostBar:FlxSprite;
    private var rightPaddleBoostBar:FlxSprite;
    private var leftPaddleBoostBarBg:FlxSprite;
    private var rightPaddleBoostBarBg:FlxSprite;
    private var leftBoostBarFadeTimer:Float = 0;
    private var rightBoostBarFadeTimer:Float = 0;

    // Default settings (can be set before create())
    private var defaultGameMode:PongGameMode = null;
    private var defaultAIDifficulty:PongAIDifficulty = null;
    private var defaultMaxScore:Int = 10;
    private var defaultBallSpeed:Float = 200;
    private var defaultPaddleSpeed:Float = 350;

    // Instruction text fading
    private var instructionFadeTimer:FlxTimer;
    private var defaultInstructionText:String = "";
    private var temporaryInstructionShown:Bool = false;

    // Boss Mode System
    private var bossMode:Bool = false;
    private var bossPhase:Int = 0; // Current difficulty phase (0=EASY, 1=NORMAL, 2=HARD, 3=EXPERT, 4=YES, 5=GOD)
    private var bossLives:Int = 3;
    private var bossTimer:Float = 0; // For final phase timer
    private var bossMaxTime:Float = 300; // 5 minutes
    private var bossStarObstacles:FlxTypedGroup<BossStarObstacle>;
    private var bossSpecialBalls:Array<BossSpecialBall>; // Logical balls (not FlxSprites)
    private var bossSpecialBallSprites:FlxTypedGroup<FlxSprite>; // Visual sprites for special balls
    private var bossSpecialBallTypes:Array<String> = [];
    private var bossOriginalBgColor:FlxColor;
    private var bossLivesText:FlxText;
    private var bossTimerText:FlxText;
    private var bossPhaseText:FlxText;
    private var bossPlayerDashCooldown:Float = 0;
    private var bossGodDashCooldown:Float = 8.0; // God starts with 8 second cooldown
    private var bossGreenBallExists:Bool = false;
    private var bossGoldenBallHits:Int = 0;
    private var cheatsDisabled:Bool = false;

    // Boss mode special states
    private var bossDashBallCollected:Bool = false;
    private var bossGoldenBallCollected:Bool = false;
    private var bossFakeBallsEnabled:Bool = false;
    private var bossPlayerFrozen:Bool = false;
    private var bossPlayerFreezeTimer:Float = 0;

    override function create() {
        // Force FPS to 60 if lower
        this.newFrameRate();

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
        pongGame.debugTracesEnabled = debugTracesEnabled;

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

        // Ball debug text (speed, momentum, max speed display)
        ballDebugText = new FlxText(10, 120, 300, "", 12);
        ballDebugText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.CYAN, LEFT);
        ballDebugText.visible = ballDebugEnabled;
        add(ballDebugText);

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

        // Dash trail groups
        leftPaddleTrailGroup = new FlxTypedGroup<FlxSprite>();
        add(leftPaddleTrailGroup);
        rightPaddleTrailGroup = new FlxTypedGroup<FlxSprite>();
        add(rightPaddleTrailGroup);

        // Create game object sprites
        createGameSprites();

        // Setup menu
        setupMenu();

        // Setup boss mode UI elements
        setupBossModeUI();

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

        // Create dash bars
        createDashBars();
    }

    private function setupMenu():Void {
        menuGroup = new FlxTypedGroup<FlxSprite>();
        menuTexts = new FlxTypedGroup<FlxText>();

        // Menu background
        var menuBg = new FlxSprite();
        menuBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.8));
        menuGroup.add(menuBg);

        // Menu options - skip Two Player mode if boss mode is active
        var menuOptions = [
            "Resume Game",
            "New Game - Player vs AI"
        ];

        if (!bossMode) {
            menuOptions.push("New Game - Two Player");
        }

        menuOptions.push("New Game - AI vs AI");
        menuOptions.push("AI Difficulty: " + getDifficultyName(currentAIDifficulty));
        menuOptions.push("Return to Main Menu");

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

    private function setupBossModeUI():Void {
        // Boss mode star obstacles
        bossStarObstacles = new FlxTypedGroup<BossStarObstacle>();
        add(bossStarObstacles);

        // Boss mode special balls (logical objects, not FlxSprites)
        bossSpecialBalls = [];

        // Boss mode special ball sprites for rendering
        bossSpecialBallSprites = new FlxTypedGroup<FlxSprite>();
        add(bossSpecialBallSprites);

        // Boss mode UI text
        bossLivesText = new FlxText(10, 90, 200, "", 16);
        bossLivesText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, LEFT);
        bossLivesText.visible = false;
        add(bossLivesText);

        bossTimerText = new FlxText(FlxG.width - 150, 90, 140, "", 16);
        bossTimerText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, RIGHT);
        bossTimerText.visible = false;
        add(bossTimerText);

        bossPhaseText = new FlxText(FlxG.width / 2 - 100, 90, 200, "", 16);
        bossPhaseText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        bossPhaseText.visible = false;
        add(bossPhaseText);

        // Store original background color
        bossOriginalBgColor = FlxColor.fromRGB(10, 10, 15);
    }

    public override function destroy()        // Restore old framerate if it was changed
    {
        Framerate();
        super.destroy();
    }

    	function Framerate()
	{
		if(backend.ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = backend.ClientPrefs.data.framerate;
			FlxG.drawFramerate = backend.ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = backend.ClientPrefs.data.framerate;
			FlxG.updateFramerate = backend.ClientPrefs.data.framerate;
		}
	}

    function newFrameRate()
        {

            var requiredFrames = 60;

            if (backend.ClientPrefs.data.framerate < requiredFrames)
            {
                if (requiredFrames > FlxG.drawFramerate)
                 {
                    FlxG.updateFramerate = requiredFrames;
                    FlxG.drawFramerate = requiredFrames;
                 }
                 else
                 {
                     FlxG.drawFramerate = requiredFrames;
                     FlxG.updateFramerate = requiredFrames;
                 }
            }
            else
            {
                Framerate();
            }
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
        // UNLIMITED cheat - spell "UNLIMITED"
        konamiTracker.addCheatFromString("UNLIMITED", function(cheat) {
            if (pongGame != null && pongGame.ball != null) {
                pongGame.ball.maxSpeed = pongGame.ball.maxSpeed.getInfinity();
                updateInstructionText('Ball speed set to UNLIMITED!', true, 3.0);
                if (debugTracesEnabled) trace("UNLIMITED cheat activated: Ball maxSpeed set to infinity");
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);
            }
        });

        // Debug traces cheat - spell "DEBUG"
        konamiTracker.addCheatFromString("DEBUG", function(cheat) {
            debugTracesEnabled = !debugTracesEnabled;
            if (pongGame != null) {
                pongGame.debugTracesEnabled = debugTracesEnabled;
            }
            var status = debugTracesEnabled ? "ENABLED" : "DISABLED";
            updateInstructionText('Debug traces ' + status + '!', true, 2.0);
            if (debugTracesEnabled) {
                trace("Debug traces enabled in Pong!");
            }
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        // Rainbow mode cheat - spell "LGBT"
        konamiTracker.addCheatFromString("LGBT", function(cheat) {
            rainbowMode = !rainbowMode;
            var status = rainbowMode ? "ENABLED" : "DISABLED";
            updateInstructionText('Rainbow mode ' + status + '! 🌈', true, 2.0);
            if (debugTracesEnabled) {
                trace("Rainbow mode " + status.toLowerCase() + "!");
            }
            if (!rainbowMode) {
                // Reset ball and paddles to original colors
                if (ballSprite != null) {
                    ballSprite.color = FlxColor.WHITE;
                }
                // Reset ball color in PongGame for trail
                if (pongGame != null) {
                    pongGame.currentBallColor = null;
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

        // Dash mechanic cheat - spell "DASH"
        konamiTracker.addCheatFromString("DASH", function(cheat) {
            dashEnabled = !dashEnabled;
            if (pongGame != null) {
                // If global dash is enabled, enable for both paddles
                if (dashEnabled) {
                    pongGame.leftPaddle.dashEnabled = true;
                    pongGame.rightPaddle.dashEnabled = true;
                } else {
                    // If global dash is disabled, disable for both paddles (unless boss mode overrides)
                    if (!bossMode) {
                        pongGame.leftPaddle.dashEnabled = false;
                        pongGame.rightPaddle.dashEnabled = false;
                    }
                }
            }
            var status = dashEnabled ? "ENABLED" : "DISABLED";
            var dashMessage = 'Dash mechanic ' + status + '!';
            if (dashEnabled) {
                if (pongGame != null && pongGame.gameMode == PLAYER_VS_AI) {
                    var dashKey = getKeyName(FlxG.save.data.pongLeftDashKey != null ? FlxG.save.data.pongLeftDashKey : FlxKey.A);
                    dashMessage += ' Use $dashKey to dash!';
                } else {
                    dashMessage += ' Use A (left) / Shift (right) to dash!';
                }
            }
            updateInstructionText(dashMessage, true, 3.0);
            if (debugTracesEnabled) {
                trace("Dash mechanic " + status.toLowerCase() + "!");
            }
            updateDashBarsVisibility();
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        // Boost mechanic cheat - spell "BOOST"
        konamiTracker.addCheatFromString("BOOST", function(cheat) {
            if (pongGame != null) {
                // Toggle boost for both paddles
                var newBoostState = !pongGame.leftPaddle.boostEnabled;
                pongGame.leftPaddle.boostEnabled = newBoostState;
                pongGame.rightPaddle.boostEnabled = newBoostState;

                var status = newBoostState ? "ENABLED" : "DISABLED";
                var boostMessage = 'Boost mechanic ' + status + '!';
                if (newBoostState) {
                    if (pongGame.gameMode == PLAYER_VS_AI) {
                        var boostKey = getKeyName(FlxG.save.data.pongLeftDashKey != null ? FlxG.save.data.pongLeftDashKey : FlxKey.A);
                        boostMessage += ' Use $boostKey to boost and add momentum to the ball!';
                    } else {
                        boostMessage += ' Use A (left) / Shift (right) to boost and add momentum to the ball!';
                    }
                }
                updateInstructionText(boostMessage, true, 4.0);
                if (debugTracesEnabled) {
                    trace("Boost mechanic " + status.toLowerCase() + "!");
                }
            }
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        // Anti-clip cheat - spell "ANTICLIP"
        konamiTracker.addCheatFromString("ANTIPHASE", function(cheat) {
            if (pongGame != null && pongGame.ball != null) {
                pongGame.ball.antiClipEnabled = !pongGame.ball.antiClipEnabled;
                var status = pongGame.ball.antiClipEnabled ? "ENABLED" : "DISABLED";
                updateInstructionText('Anti-clip system ' + status + '! Ball can no longer phase through paddles at high speeds!', true, 3.0);
                if (debugTracesEnabled) {
                    trace("Anti-clip system " + status.toLowerCase() + "!");
                }
                FlxG.sound.play(Paths.sound('confirmMenu'), 0.8);
            }
        });

        // Boss Mode cheat - spell "IAMTHEBOSS"
        konamiTracker.addCheatFromString("IAMTHEBOSS", function(cheat) {
            if (!bossMode) {
                startBossMode();
                updateInstructionText('BOSS MODE ACTIVATED! Prepare for the ultimate challenge!', true, 4.0);
                if (debugTracesEnabled) {
                    trace("Boss Mode activated!");
                }
                if (showingMenu) toggleMenu();
                setupMenu();
                FlxG.sound.play(Paths.sound('confirmMenu'), 1.0);
            } else {
                updateInstructionText('Boss Mode is already active!', true, 2.0);
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
            }
        });

        // Ball debug info cheat - spell "SPEEDOMETER"
        konamiTracker.addCheatFromString("SPEEDOMETER", function(cheat) {
            ballDebugEnabled = !ballDebugEnabled;
            if (ballDebugText != null) {
                ballDebugText.visible = ballDebugEnabled;
            }
            var status = ballDebugEnabled ? "ENABLED" : "DISABLED";
            updateInstructionText('Ball speed debug display ' + status + '!', true, 2.0);
            if (debugTracesEnabled) {
                trace("Ball debug display " + status.toLowerCase() + "!");
            }
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        add(konamiTracker);
    }

    private function setupGameEvents():Void {
        if (pongGame == null) return;

        pongGame.onGameStart = () -> {
            isGameStarted = true;
            updateInstructionText(getDefaultControlsText());
            PongSounds.playGameStart();
        };

        pongGame.onScore = (player, leftScore, rightScore) -> {
            leftScoreText.text = Std.string(leftScore);
            rightScoreText.text = Std.string(rightScore);

            // Flash screen effect
            if (player == PongPlayer.LEFT) {
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

            // Handle boss mode round end immediately after each score
            if (bossMode) {
                handleBossRoundEnd(player);
            }
        };

        pongGame.onGameEnd = (winner) -> {
            isGameStarted = false;
            var winnerName = winner == PongPlayer.LEFT ? "Left Player" : "Right Player";
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

        pongGame.onBallUpdate = (ballX, ballY) -> {
            handleBallSpecialInteractions(ballX, ballY);
        };
    }

    private function setupAudio():Void {
        FlxG.sound.music.stop();
        bgMusic = FlxG.sound.load(Paths.music('gameMusic/PONG beyond the stars${(FlxG.random.bool(18) ? ' (Classics Mix)' : '')}'));
        bgMusic.looped = true;
        bgMusic.volume = 0.3;
        bgMusic.play();
        FlxG.sound.list.add(bgMusic);
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

        // Update status text - show boss mode info instead of regular status
        if (bossMode) {
            var phaseName = switch (bossPhase) {
                case 0: "Easy";
                case 1: "Normal";
                case 2: "Hard";
                case 3: "Expert";
                case 4: "Yes";
                case 5: "GOD";
                default: "BEYOND GOD";
            };
            gameStatusText.text = 'BOSS MODE - Phase: $phaseName | Lives: $bossLives';
        } else {
            gameStatusText.text = pongGame.getGameStatus();
        }

        // Update score display
        leftScoreText.text = Std.string(pongGame.leftScore);
        rightScoreText.text = Std.string(pongGame.rightScore);

        // Update game object positions
        if (ballSprite != null) {
            ballSprite.x = gameFieldOffsetX + pongGame.ball.position.x - pongGame.ball.radius;
            ballSprite.y = gameFieldOffsetY + pongGame.ball.position.y - pongGame.ball.radius;

            // Update ball rotation based on momentum and velocity
            updateBallRotation();
        }

        if (leftPaddleSprite != null) {
            leftPaddleSprite.x = gameFieldOffsetX + pongGame.leftPaddle.x;
            leftPaddleSprite.y = gameFieldOffsetY + pongGame.leftPaddle.y;
        }

        if (rightPaddleSprite != null) {
            rightPaddleSprite.x = gameFieldOffsetX + pongGame.rightPaddle.x;
            rightPaddleSprite.y = gameFieldOffsetY + pongGame.rightPaddle.y;
        }

        // Update special balls positions
        if (bossSpecialBalls != null && bossSpecialBallSprites != null) {
            for (i in 0...bossSpecialBalls.length) {
                var specialBall = bossSpecialBalls[i];
                var ballSprite = bossSpecialBallSprites.members[i];

                if (specialBall != null && ballSprite != null && specialBall.isAlive()) {
                    ballSprite.x = gameFieldOffsetX + specialBall.position.x - specialBall.radius;
                    ballSprite.y = gameFieldOffsetY + specialBall.position.y - specialBall.radius;
                    ballSprite.visible = true;
                } else if (ballSprite != null) {
                    ballSprite.visible = false;
                }
            }
        }

        // Update ball trail
        updateBallTrail();

        // Update ball debug text if enabled
        updateBallDebugText();
    }

    /**
     * Update ball rotation based on momentum and velocity
     */
    private function updateBallRotation():Void {
        if (pongGame == null || pongGame.ball == null || ballSprite == null) return;

        var ball = pongGame.ball;
        var momentum = ball.momentum;

        // If momentum is more than 0, cancel any tween back to 0 and do normal spinning
        if (momentum > 0) {
            // Cancel any existing tween back to 0
            if (ballRotationTween != null) {
                ballRotationTween.cancel();
                ballRotationTween = null;
            }

            // Determine rotation direction based on velocity direction
            var rotationDirection = ball.velocity.x > 0 ? 1 : -1; // Positive velocity = clockwise

            // Calculate rotation speed based purely on momentum (not velocity magnitude)
            var rotationSpeed = momentum * 2.0; // Adjust multiplier for desired rotation speed

            // Apply continuous rotation directly to angle
            ballSprite.angle += rotationSpeed * rotationDirection * FlxG.elapsed * 60; // Normalize for framerate
        }
        // If momentum is 0 or less, start tween back to 0 if not already running and not already at 0
        else if (ballRotationTween == null && Math.abs(ballSprite.angle) > 1) {
            ballRotationTween = FlxTween.tween(ballSprite, {angle: 0}, 0.5, {
                ease: FlxEase.quadOut,
                onComplete: function(_) {
                    ballRotationTween = null;
                    ballSprite.angle = 0;
                }
            });
        }
        // If already close to 0 and no tween running, just snap to 0
        else if (ballRotationTween == null && Math.abs(ballSprite.angle) <= 1) {
            ballSprite.angle = 0;
        }
    }    private function updateBallTrail():Void {
        if (pongGame == null || !pongGame.isRoundActive) return;

        // Only update trail every 2-3 frames to reduce lag
        var currentTime = haxe.Timer.stamp();
        if (currentTime - lastTrailUpdate < 0.033) return; // ~30fps for trails
        lastTrailUpdate = currentTime;

        // Return used sprites to pool
        for (sprite in ballTrailGroup.members) {
            if (sprite != null) {
                var flxSprite:FlxSprite = cast sprite;
                flxSprite.visible = false;
                trailSpritePool.push(flxSprite);
            }
        }
        ballTrailGroup.clear();

        // Limit trail length for performance
        var maxTrailPoints = 15; // Reduced from potentially unlimited
        var startIndex = Std.int(Math.max(0, pongGame.ballTrail.length - maxTrailPoints));

        // Create trail sprites from ball trail data
        for (i in startIndex...pongGame.ballTrail.length) {
            var trailPoint = pongGame.ballTrail[i];
            var alpha = 1.0 - (trailPoint.time / 0.5); // Fade over 0.5 seconds

            if (alpha > 0.1) { // Skip very faint trails
                var trailSprite:FlxSprite;

                // Reuse sprite from pool or create new one
                if (trailSpritePool.length > 0) {
                    trailSprite = trailSpritePool.pop();
                    trailSprite.visible = true;
                } else {
                    trailSprite = new FlxSprite();
                }

                var size = Std.int(pongGame.ball.radius * alpha);

                // Use the stored color if available (rainbow mode), otherwise use white
                var trailColor:FlxColor;
                if (trailPoint.color != null) {
                    trailColor = FlxColor.fromRGBFloat(
                        FlxColor.fromInt(trailPoint.color).redFloat,
                        FlxColor.fromInt(trailPoint.color).greenFloat,
                        FlxColor.fromInt(trailPoint.color).blueFloat,
                        alpha * 0.5
                    );
                } else {
                    trailColor = FlxColor.fromRGBFloat(1, 1, 1, alpha * 0.5);
                }

                trailSprite.makeGraphic(size, size, trailColor);
                trailSprite.x = gameFieldOffsetX + trailPoint.x - size / 2;
                trailSprite.y = gameFieldOffsetY + trailPoint.y - size / 2;
                ballTrailGroup.add(trailSprite);
            }
        }
    }

    /**
     * Update ball debug text display with current speed, momentum, and max speed
     */
    private function updateBallDebugText():Void {
        if (!ballDebugEnabled || ballDebugText == null || pongGame == null || pongGame.ball == null) return;

        var ball = pongGame.ball;

        // Calculate current speed from velocity
        var currentSpeed = Math.sqrt(ball.velocity.x * ball.velocity.x + ball.velocity.y * ball.velocity.y);

        // Get effective speed (including momentum)
        var effectiveSpeed = ball.getEffectiveSpeed();

        // Get momentum and max speed
        var momentum = ball.getMomentum();
        var maxSpeed = ball.maxSpeed;

        // Format the debug text
        var debugInfo = "BALL DEBUG INFO:\n";
        debugInfo += 'Base Speed: ${Math.round(currentSpeed * 10) / 10}\n';
        debugInfo += 'Effective Speed: ${Math.round(effectiveSpeed * 10) / 10}\n';
        debugInfo += 'Momentum: ${Math.round(momentum * 10) / 10}\n';
        debugInfo += 'Max Speed: ${Math.round(maxSpeed * 10) / 10}\n';
        debugInfo += 'Speed Boost: ${Math.round((effectiveSpeed - currentSpeed) * 10) / 10}\n';
        debugInfo += 'Over Limit: ${currentSpeed > maxSpeed ? "YES" : "NO"}\n';
        debugInfo += 'Velocity: (${Math.round(ball.velocity.x * 10) / 10}, ${Math.round(ball.velocity.y * 10) / 10})';

        ballDebugText.text = debugInfo;
    }

    /**
     * Update dash trails for paddles
     */
    private function updateDashTrails():Void {
        if (pongGame == null) return;

        // Update left paddle trail if it has dash enabled
        if (pongGame.leftPaddle != null && pongGame.leftPaddle.dashEnabled) {
            updatePaddleTrail(pongGame.leftPaddle, leftPaddleTrailGroup, leftPaddleOriginalColor);
        }

        // Update right paddle trail if it has dash enabled
        if (pongGame.rightPaddle != null && pongGame.rightPaddle.dashEnabled) {
            updatePaddleTrail(pongGame.rightPaddle, rightPaddleTrailGroup, rightPaddleOriginalColor);
        }
    }

    /**
     * Update trail for a specific paddle
     */
    private function updatePaddleTrail(paddle:PongPaddle, trailGroup:FlxTypedGroup<FlxSprite>, paddleColor:FlxColor):Void {
        if (paddle == null || trailGroup == null) return;

        // Clear old trail sprites
        trailGroup.clear();

        // Create trail sprites from paddle trail data
        for (i in 0...paddle.dashTrail.length) {
            var trailPoint = paddle.dashTrail[i];

            if (trailPoint.alpha > 0) {
                var trailSprite = new FlxSprite();
                trailSprite.makeGraphic(Std.int(paddle.width), Std.int(paddle.height),
                    FlxColor.fromRGBFloat(paddleColor.redFloat, paddleColor.greenFloat, paddleColor.blueFloat, trailPoint.alpha * 0.6));
                trailSprite.x = gameFieldOffsetX + trailPoint.x;
                trailSprite.y = gameFieldOffsetY + trailPoint.y;
                trailGroup.add(trailSprite);
            }
        }
    }

    private function updateInstructionText(text:String, isTemporary:Bool = false, fadeTime:Float = 3.0):Void {
        if (instructionText != null) {
            instructionText.text = text;

            // Cancel any existing fade timer
            if (instructionFadeTimer != null) {
                instructionFadeTimer.cancel();
            }

            if (isTemporary) {
                temporaryInstructionShown = true;
                // Set up fade timer to return to default text
                instructionFadeTimer = new FlxTimer().start(fadeTime, function(timer) {
                    if (isGameStarted && pongGame != null && pongGame.isRoundActive && !pongGame.isPaused) {
                        // Return to default controls text if playing and not paused
                        instructionText.text = getDefaultControlsText();
                        temporaryInstructionShown = false;
                    }
                });
            } else {
                // This is the new default text
                defaultInstructionText = text;
                temporaryInstructionShown = false;
            }
        }
    }

    private function getDefaultControlsText():String {
        if (pongGame == null) return "Press ENTER to start, M for menu, or ESCAPE to return to main menu";

        if (pongGame.gameMode == PLAYER_VS_AI) {
            // Show custom controls for single player
            var upKey = getKeyName(FlxG.save.data.pongLeftUpKey != null ? FlxG.save.data.pongLeftUpKey : FlxKey.W);
            var downKey = getKeyName(FlxG.save.data.pongLeftDownKey != null ? FlxG.save.data.pongLeftDownKey : FlxKey.S);

            var controlText = 'Use $upKey/$downKey to control paddle. Press P to pause, C for controls';

            if (dashEnabled) {
                var dashKey = getKeyName(FlxG.save.data.pongLeftDashKey != null ? FlxG.save.data.pongLeftDashKey : FlxKey.A);
                controlText += ', $dashKey to dash';
            }

            if (pongGame.leftPaddle.boostEnabled) {
                var boostKey = getKeyName(FlxG.save.data.pongLeftDashKey != null ? FlxG.save.data.pongLeftDashKey : FlxKey.A);
                controlText += ', $boostKey to boost';
            }

            return controlText;
        } else {
            // Show standard controls for multiplayer
            var controlText = "Use W/S (left) or Arrow Keys (right) to control paddles. Press P to pause";

            if (dashEnabled) {
                controlText += ", A/Shift to dash";
            }

            if (pongGame.leftPaddle.boostEnabled || pongGame.rightPaddle.boostEnabled) {
                controlText += ", A/Shift to boost";
            }

            return controlText;
        }
    }

    private function getKeyName(key:Int):String {
        return switch (key) {
            case FlxKey.W: "W";
            case FlxKey.A: "A";
            case FlxKey.S: "S";
            case FlxKey.D: "D";
            case FlxKey.UP: "UP";
            case FlxKey.DOWN: "DOWN";
            case FlxKey.LEFT: "LEFT";
            case FlxKey.RIGHT: "RIGHT";
            case FlxKey.SPACE: "SPACE";
            case FlxKey.SHIFT: "SHIFT";
            case FlxKey.CONTROL: "CTRL";
            case FlxKey.ALT: "ALT";
            case FlxKey.TAB: "TAB";
            case FlxKey.ENTER: "ENTER";
            default: Std.string(key);
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

        // Update AI difficulty text (position depends on boss mode)
        var aiDifficultyIndex = bossMode ? 3 : 4; // Index 3 in boss mode, 4 in normal mode
        if (menuTexts.members[aiDifficultyIndex] != null) {
            menuTexts.members[aiDifficultyIndex].text = "AI Difficulty: " + getDifficultyName(currentAIDifficulty);
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

            case 2: // New Game - Two Player OR AI vs AI (depending on boss mode)
                if (bossMode) {
                    // Boss mode: skip Two Player, go directly to AI vs AI
                    currentGameMode = AI_VS_AI;
                } else {
                    // Normal mode: Two Player
                    currentGameMode = TWO_PLAYER;
                }
                startNewGame(currentGameMode);
                toggleMenu();

            case 3: // AI vs AI (normal mode) OR AI Difficulty (boss mode)
                if (bossMode) {
                    // Boss mode: AI Difficulty
                    cycleAIDifficulty();
                    updateMenuSelection();
                } else {
                    // Normal mode: AI vs AI
                    currentGameMode = AI_VS_AI;
                    startNewGame(currentGameMode);
                    toggleMenu();
                }

            case 4: // AI Difficulty (normal mode) OR Return to Main Menu (boss mode)
                if (bossMode) {
                    // Boss mode: Return to Main Menu
                    FlxG.mouse.visible = false;
                    MusicBeatState.switchState(new MainMenuState());
                } else {
                    // Normal mode: AI Difficulty
                    cycleAIDifficulty();
                    updateMenuSelection();
                }

            case 5: // Return to Main Menu (normal mode only)
                if (!bossMode) {
                    FlxG.mouse.visible = false;
                    MusicBeatState.switchState(new MainMenuState());
                }
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

        // Auto-switch from TWO_PLAYER to PLAYER_VS_AI when boss mode is active
        if (bossMode && pongGame != null && pongGame.gameMode == TWO_PLAYER) pongGame.gameMode = PLAYER_VS_AI;

        // Ensure right paddle is AI-controlled and has correct difficulty for boss mode
        if (bossMode && pongGame != null && pongGame.rightPaddle != null) {
            pongGame.rightPaddle.isPlayer = false;
            var bossAIDifficulty = switch (bossPhase) {
                case 0: EASY;
                case 1: NORMAL;
                case 2: HARD;
                case 3: EXPERT;
                case 4: YES;
                case 5: GOD;
                default: GOD;
            };
            if (pongGame.rightPaddle.aiDifficulty != bossAIDifficulty) {
                pongGame.setAIDifficulty(pongGame.rightPaddle, bossAIDifficulty);
            }
        }

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

        if (FlxG.keys.justPressed.C && pongGame != null && pongGame.gameMode == PLAYER_VS_AI) {
            openControlsSubstate();
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        }

        if (FlxG.keys.justPressed.P && isGameStarted && pongGame.isGameActive) {
            var isPaused = pongGame.togglePause();
            pauseButton.text.text = isPaused ? "Resume" : "Pause";
            updateInstructionText(isPaused ? "Game Paused - Press P to resume" : "Game Resumed", true, 2.0);
        }

        // Update game
        if (pongGame != null) {
            pongGame.update(elapsed);
            updateDisplay();

            // Update special balls for boss mode
            if (bossMode) {
                updateBossSpecialBalls();
            }

            // Check for game end
            if (pongGame.winner != null) {
                // Boss mode is handled in onScore callback, not here
                if (!bossMode) {
                    switch (pongGame.winner) {
                        case PongPlayer.LEFT:
                            updateInstructionText('Left paddle wins!', true);
                        case PongPlayer.RIGHT:
                            updateInstructionText('Right paddle wins!', true);
                    }
                }
            }
        }

        // Update boss mode if active
        updateBossMode(elapsed);

        // Update rainbow effects
        if (rainbowMode) {
            updateRainbowEffects(elapsed);
        } else {
            // Ensure ball color is reset when not in rainbow mode
            if (pongGame != null) {
                pongGame.currentBallColor = null;
            }
        }

        // Update dash mechanics
        var anyPaddleHasDash = pongGame != null &&
                              ((pongGame.leftPaddle != null && pongGame.leftPaddle.dashEnabled) ||
                               (pongGame.rightPaddle != null && pongGame.rightPaddle.dashEnabled));

        if (anyPaddleHasDash) {
            updateDashBars();
            updateDashTrails();
        }

        // Update paddle visual effects (dash and boost)
        var anyPaddleHasEffects = pongGame != null &&
                                 ((pongGame.leftPaddle != null && (pongGame.leftPaddle.dashEnabled || pongGame.leftPaddle.boostEnabled)) ||
                                  (pongGame.rightPaddle != null && (pongGame.rightPaddle.dashEnabled || pongGame.rightPaddle.boostEnabled)));

        if (anyPaddleHasEffects) {
            updatePaddleDashEffects(); // This now handles both dash and boost effects
        }

        // Update boost mechanics visual bars
        updateBoostBarsVisibility();
        updateBoostBars();
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
            var ballColor = FlxColor.fromHSB(ballHue, 1.0, 1.0);
            ballSprite.color = ballColor;

            // Pass current ball color to PongGame for trail
            if (pongGame != null) {
                pongGame.currentBallColor = ballColor;
            }
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
                // Rainbow cycle complete, tween back to original color
                leftPaddleIsRainbow = false;
                FlxTween.color(leftPaddleSprite, 0.3, leftPaddleSprite.color, leftPaddleOriginalColor);
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
                // Rainbow cycle complete, tween back to original color
                rightPaddleIsRainbow = false;
                FlxTween.color(rightPaddleSprite, 0.3, rightPaddleSprite.color, rightPaddleOriginalColor);
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
            // Tween back to original color instead of snapping
            FlxTween.color(leftPaddleSprite, 0.3, leftPaddleSprite.color, leftPaddleOriginalColor);
        }
        if (rightPaddleSprite != null) {
            // Tween back to original color instead of snapping
            FlxTween.color(rightPaddleSprite, 0.3, rightPaddleSprite.color, rightPaddleOriginalColor);
        }
    }

    /**
     * Create dash and boost cooldown bars
     */
    private function createDashBars():Void {
        // Vertical bars that match paddle orientation
        var barWidth = 6;
        var barHeight = 60;

        // Left paddle dash bar (positioned in center of paddle)
        leftPaddleDashBarBg = new FlxSprite();
        leftPaddleDashBarBg.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(40, 40, 40));
        add(leftPaddleDashBarBg);

        leftPaddleDashBar = new FlxSprite();
        leftPaddleDashBar.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(50, 200, 50)); // Green
        add(leftPaddleDashBar);

        // Right paddle dash bar (positioned in center of paddle)
        rightPaddleDashBarBg = new FlxSprite();
        rightPaddleDashBarBg.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(40, 40, 40));
        add(rightPaddleDashBarBg);

        rightPaddleDashBar = new FlxSprite();
        rightPaddleDashBar.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(50, 200, 50)); // Green
        add(rightPaddleDashBar);

        // Left paddle boost bar (positioned above paddle)
        leftPaddleBoostBarBg = new FlxSprite();
        leftPaddleBoostBarBg.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(40, 40, 40));
        add(leftPaddleBoostBarBg);

        leftPaddleBoostBar = new FlxSprite();
        leftPaddleBoostBar.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(255, 150, 50)); // Orange
        add(leftPaddleBoostBar);

        // Right paddle boost bar (positioned above paddle)
        rightPaddleBoostBarBg = new FlxSprite();
        rightPaddleBoostBarBg.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(40, 40, 40));
        add(rightPaddleBoostBarBg);

        rightPaddleBoostBar = new FlxSprite();
        rightPaddleBoostBar.makeGraphic(barWidth, barHeight, FlxColor.fromRGB(255, 150, 50)); // Orange
        add(rightPaddleBoostBar);

        updateDashBarsVisibility();
        updateBoostBarsVisibility();
    }

    /**
     * Update dash bar visibility based on individual paddle dash enabled state
     */
    private function updateDashBarsVisibility():Void {
        // Check individual paddle dash states
        var leftPaddleHasDash = pongGame != null && pongGame.leftPaddle != null && pongGame.leftPaddle.dashEnabled;
        var rightPaddleHasDash = pongGame != null && pongGame.rightPaddle != null && pongGame.rightPaddle.dashEnabled;

        // Update visibility based on individual paddle states
        if (leftPaddleDashBar != null) leftPaddleDashBar.visible = leftPaddleHasDash;
        if (leftPaddleDashBarBg != null) leftPaddleDashBarBg.visible = leftPaddleHasDash;
        if (rightPaddleDashBar != null) rightPaddleDashBar.visible = rightPaddleHasDash;
        if (rightPaddleDashBarBg != null) rightPaddleDashBarBg.visible = rightPaddleHasDash;
    }

    /**
     * Update boost bar visibility with fade-out when cooldown is 0
     */
    private function updateBoostBarsVisibility():Void {
        // Check individual paddle boost states
        var leftPaddleHasBoost = pongGame != null && pongGame.leftPaddle != null && pongGame.leftPaddle.boostEnabled;
        var rightPaddleHasBoost = pongGame != null && pongGame.rightPaddle != null && pongGame.rightPaddle.boostEnabled;

        // Hide all boost bars when boost is disabled for both paddles
        if (!leftPaddleHasBoost && !rightPaddleHasBoost) {
            if (leftPaddleBoostBar != null) leftPaddleBoostBar.visible = false;
            if (leftPaddleBoostBarBg != null) leftPaddleBoostBarBg.visible = false;
            if (rightPaddleBoostBar != null) rightPaddleBoostBar.visible = false;
            if (rightPaddleBoostBarBg != null) rightPaddleBoostBarBg.visible = false;
            return;
        }

        // Left paddle boost bar visibility with fade
        if (leftPaddleHasBoost && pongGame.leftPaddle.getBoostCooldownProgress() > 0) {
            // Show bars when cooldown is active
            if (leftPaddleBoostBar != null) {
                leftPaddleBoostBar.visible = true;
                leftPaddleBoostBar.alpha = 1.0;
            }
            if (leftPaddleBoostBarBg != null) {
                leftPaddleBoostBarBg.visible = true;
                leftPaddleBoostBarBg.alpha = 1.0;
            }
            leftBoostBarFadeTimer = 1.0; // Reset fade timer
        } else if (leftBoostBarFadeTimer > 0) {
            // Fade out bars when cooldown is 0
            var fadeAlpha = leftBoostBarFadeTimer;
            if (leftPaddleBoostBar != null) {
                leftPaddleBoostBar.visible = true;
                leftPaddleBoostBar.alpha = fadeAlpha;
            }
            if (leftPaddleBoostBarBg != null) {
                leftPaddleBoostBarBg.visible = true;
                leftPaddleBoostBarBg.alpha = fadeAlpha;
            }
        } else {
            // Hide bars completely
            if (leftPaddleBoostBar != null) leftPaddleBoostBar.visible = false;
            if (leftPaddleBoostBarBg != null) leftPaddleBoostBarBg.visible = false;
        }

        // Right paddle boost bar visibility with fade
        if (rightPaddleHasBoost && pongGame.rightPaddle.getBoostCooldownProgress() > 0) {
            // Show bars when cooldown is active
            if (rightPaddleBoostBar != null) {
                rightPaddleBoostBar.visible = true;
                rightPaddleBoostBar.alpha = 1.0;
            }
            if (rightPaddleBoostBarBg != null) {
                rightPaddleBoostBarBg.visible = true;
                rightPaddleBoostBarBg.alpha = 1.0;
            }
            rightBoostBarFadeTimer = 1.0; // Reset fade timer
        } else if (rightBoostBarFadeTimer > 0) {
            // Fade out bars when cooldown is 0
            var fadeAlpha = rightBoostBarFadeTimer;
            if (rightPaddleBoostBar != null) {
                rightPaddleBoostBar.visible = true;
                rightPaddleBoostBar.alpha = fadeAlpha;
            }
            if (rightPaddleBoostBarBg != null) {
                rightPaddleBoostBarBg.visible = true;
                rightPaddleBoostBarBg.alpha = fadeAlpha;
            }
        } else {
            // Hide bars completely
            if (rightPaddleBoostBar != null) rightPaddleBoostBar.visible = false;
            if (rightPaddleBoostBarBg != null) rightPaddleBoostBarBg.visible = false;
        }
    }

    /**
     * Update dash bars positions and progress
     */
    private function updateDashBars():Void {
        if (pongGame == null) return;

        // Check if any paddle has dash enabled
        var anyPaddleHasDash = (pongGame.leftPaddle != null && pongGame.leftPaddle.dashEnabled) ||
                              (pongGame.rightPaddle != null && pongGame.rightPaddle.dashEnabled);

        if (!anyPaddleHasDash) return;

        // Update left paddle dash bar (centered on paddle)
        if (leftPaddleDashBar != null && leftPaddleSprite != null) {
            leftPaddleDashBarBg.x = leftPaddleSprite.x + (leftPaddleSprite.width - leftPaddleDashBarBg.width) / 2;
            leftPaddleDashBarBg.y = leftPaddleSprite.y + (leftPaddleSprite.height - leftPaddleDashBarBg.height) / 2;

            leftPaddleDashBar.x = leftPaddleDashBarBg.x;
            leftPaddleDashBar.y = leftPaddleDashBarBg.y;

            var leftProgress = 1.0 - pongGame.leftPaddle.getDashCooldownProgress();
            // Scale from bottom up
            leftPaddleDashBar.scale.y = leftProgress;
            leftPaddleDashBar.y = leftPaddleDashBarBg.y + leftPaddleDashBarBg.height * (1.0 - leftProgress);
        }

        // Update right paddle dash bar (centered on paddle)
        if (rightPaddleDashBar != null && rightPaddleSprite != null) {
            rightPaddleDashBarBg.x = rightPaddleSprite.x + (rightPaddleSprite.width - rightPaddleDashBarBg.width) / 2;
            rightPaddleDashBarBg.y = rightPaddleSprite.y + (rightPaddleSprite.height - rightPaddleDashBarBg.height) / 2;

            rightPaddleDashBar.x = rightPaddleDashBarBg.x;
            rightPaddleDashBar.y = rightPaddleDashBarBg.y;

            var rightProgress = 1.0 - pongGame.rightPaddle.getDashCooldownProgress();
            // Scale from bottom up
            rightPaddleDashBar.scale.y = rightProgress;
            rightPaddleDashBar.y = rightPaddleDashBarBg.y + rightPaddleDashBarBg.height * (1.0 - rightProgress);
        }
    }

    /**
     * Update boost bars positions and progress
     */
    private function updateBoostBars():Void {
        if (pongGame == null) return;

        // Update fade timers
        if (leftBoostBarFadeTimer > 0) {
            leftBoostBarFadeTimer -= FlxG.elapsed;
        }
        if (rightBoostBarFadeTimer > 0) {
            rightBoostBarFadeTimer -= FlxG.elapsed;
        }

        // Update left paddle boost bar (positioned above paddle)
        if (leftPaddleBoostBar != null && leftPaddleSprite != null && leftPaddleBoostBar.visible) {
            leftPaddleBoostBarBg.x = leftPaddleSprite.x + (leftPaddleSprite.width - leftPaddleBoostBarBg.width) / 2;
            leftPaddleBoostBarBg.y = leftPaddleSprite.y - leftPaddleBoostBarBg.height - 10; // Above paddle

            leftPaddleBoostBar.x = leftPaddleBoostBarBg.x;
            leftPaddleBoostBar.y = leftPaddleBoostBarBg.y;

            var leftProgress = pongGame.leftPaddle.getBoostCooldownProgress();
            // Scale from bottom up
            leftPaddleBoostBar.scale.y = leftProgress;
            leftPaddleBoostBar.y = leftPaddleBoostBarBg.y + leftPaddleBoostBarBg.height * (1.0 - leftProgress);
        }

        // Update right paddle boost bar (positioned above paddle)
        if (rightPaddleBoostBar != null && rightPaddleSprite != null && rightPaddleBoostBar.visible) {
            rightPaddleBoostBarBg.x = rightPaddleSprite.x + (rightPaddleSprite.width - rightPaddleBoostBarBg.width) / 2;
            rightPaddleBoostBarBg.y = rightPaddleSprite.y - rightPaddleBoostBarBg.height - 10; // Above paddle

            rightPaddleBoostBar.x = rightPaddleBoostBarBg.x;
            rightPaddleBoostBar.y = rightPaddleBoostBarBg.y;

            var rightProgress = pongGame.rightPaddle.getBoostCooldownProgress();
            // Scale from bottom up
            rightPaddleBoostBar.scale.y = rightProgress;
            rightPaddleBoostBar.y = rightPaddleBoostBarBg.y + rightPaddleBoostBarBg.height * (1.0 - rightProgress);
        }
    }

    /**
     * Handle paddle dash and boost visual effects
     */
    private function updatePaddleDashEffects():Void {
        if (pongGame == null) return;

        // LEFT PADDLE EFFECTS
        var leftPaddleCurrentlyBoosting = pongGame.leftPaddle.isBoostActive();
        var leftPaddleCurrentlyDashing = pongGame.leftPaddle.isDashing;

        // Handle boost effect (takes priority over dash)
        if (leftPaddleCurrentlyBoosting && !leftPaddleIsBoosting && leftPaddleSprite != null) {
            // Start boost effect - flash white and fade back over boost duration
            leftPaddleIsBoosting = true;
            FlxTween.color(leftPaddleSprite, 0.1, leftPaddleSprite.color, FlxColor.WHITE, {
                onComplete: function(_) {
                    // Fade back to original color over the boost duration
                    var boostDuration = pongGame.leftPaddle.boostActiveTime;
                    FlxTween.color(leftPaddleSprite, boostDuration * 0.8, FlxColor.WHITE, leftPaddleOriginalColor, {
                        onComplete: function(_) {
                            leftPaddleIsBoosting = false;
                        }
                    });
                }
            });
        }
        // Handle dash effect (only if not boosting)
        else if (!leftPaddleCurrentlyBoosting && leftPaddleCurrentlyDashing && leftPaddleSprite != null) {
            if (leftPaddleSprite.color != FlxColor.WHITE) {
                FlxTween.color(leftPaddleSprite, 0.1, leftPaddleSprite.color, FlxColor.WHITE);
            }
        }
        // Reset to original color when neither dashing nor boosting
        else if (!leftPaddleCurrentlyDashing && !leftPaddleCurrentlyBoosting && !leftPaddleIsRainbow && !leftPaddleIsBoosting && leftPaddleSprite != null) {
            if (leftPaddleSprite.color == FlxColor.WHITE) {
                FlxTween.color(leftPaddleSprite, 0.3, FlxColor.WHITE, leftPaddleOriginalColor);
            }
        }

        // RIGHT PADDLE EFFECTS
        var rightPaddleCurrentlyBoosting = pongGame.rightPaddle.isBoostActive();
        var rightPaddleCurrentlyDashing = pongGame.rightPaddle.isDashing;

        // Handle boost effect (takes priority over dash)
        if (rightPaddleCurrentlyBoosting && !rightPaddleIsBoosting && rightPaddleSprite != null) {
            // Start boost effect - flash white and fade back over boost duration
            rightPaddleIsBoosting = true;
            FlxTween.color(rightPaddleSprite, 0.1, rightPaddleSprite.color, FlxColor.WHITE, {
                onComplete: function(_) {
                    // Fade back to original color over the boost duration
                    var boostDuration = pongGame.rightPaddle.boostActiveTime;
                    FlxTween.color(rightPaddleSprite, boostDuration * 0.8, FlxColor.WHITE, rightPaddleOriginalColor, {
                        onComplete: function(_) {
                            rightPaddleIsBoosting = false;
                        }
                    });
                }
            });
        }
        // Handle dash effect (only if not boosting)
        else if (!rightPaddleCurrentlyBoosting && rightPaddleCurrentlyDashing && rightPaddleSprite != null) {
            if (rightPaddleSprite.color != FlxColor.WHITE) {
                FlxTween.color(rightPaddleSprite, 0.1, rightPaddleSprite.color, FlxColor.WHITE);
            }
        }
        // Reset to original color when neither dashing nor boosting
        else if (!rightPaddleCurrentlyDashing && !rightPaddleCurrentlyBoosting && !rightPaddleIsRainbow && !rightPaddleIsBoosting && rightPaddleSprite != null) {
            if (rightPaddleSprite.color == FlxColor.WHITE) {
                FlxTween.color(rightPaddleSprite, 0.3, FlxColor.WHITE, rightPaddleOriginalColor);
            }
        }
    }

    /**
     * Open controls mapping substate
     */
    private function openControlsSubstate():Void {
        openSubState(new PongControlsSubstate(pongGame.leftPaddle.dashEnabled));
    }

    // ================================
    // BOSS MODE SYSTEM
    // ================================

    /**
     * Start boss mode - disable cheats and initialize
     */
    private function startBossMode():Void {
        bossMode = true;
        cheatsDisabled = true;

        // Disable all active cheats before starting boss mode
        disableAllCheats();

        bossPhase = 0; // Start with EASY
        bossLives = 3;
        bossTimer = 0;
        bossPlayerDashCooldown = 0;
        bossGodDashCooldown = 8.0;
        bossGreenBallExists = false;
        bossGoldenBallHits = 0;

        // Change background to slightly red
        bgSprite.color = FlxColor.fromRGB(25, 10, 10);

        // Show boss UI
        bossLivesText.visible = true;
        bossPhaseText.visible = true;
        updateBossUI();

        // Start first phase
        startBossPhase();
    }

    /**
     * Disable all active cheats when entering boss mode
     */
    private function disableAllCheats():Void {
        var cheatsToDisable = [];

        // Check and disable debug traces
        if (debugTracesEnabled) {
            debugTracesEnabled = false;
            cheatsToDisable.push("Debug traces");
        }

        // Check and disable rainbow mode (but preserve if it's Pride Month)
        var wasPrideMonth = ExtendedDate.global().isPrideMonth();
        if (rainbowMode && !wasPrideMonth) {
            rainbowMode = false;
            cheatsToDisable.push("Rainbow mode");

            // Reset paddle colors to original
            if (leftPaddleSprite != null && rightPaddleSprite != null) {
                leftPaddleSprite.color = leftPaddleOriginalColor;
                rightPaddleSprite.color = rightPaddleOriginalColor;
                leftPaddleIsRainbow = false;
                rightPaddleIsRainbow = false;
            }
        }

        // Check and disable dash mechanics
        if (dashEnabled) {
            dashEnabled = false;
            cheatsToDisable.push("Dash mechanics");

            // Reset dash properties
            if (pongGame != null) {
                if (pongGame.leftPaddle != null) {
                    pongGame.leftPaddle.dashEnabled = false;
                    pongGame.leftPaddle.dashCooldown = 0;
                    pongGame.leftPaddle.isDashing = false;
                }
                if (pongGame.rightPaddle != null) {
                    pongGame.rightPaddle.dashEnabled = false;
                    pongGame.rightPaddle.dashCooldown = 0;
                    pongGame.rightPaddle.isDashing = false;
                }
            }

            // Hide dash bars
            if (leftPaddleDashBar != null) leftPaddleDashBar.visible = false;
            if (leftPaddleDashBarBg != null) leftPaddleDashBarBg.visible = false;
            if (rightPaddleDashBar != null) rightPaddleDashBar.visible = false;
            if (rightPaddleDashBarBg != null) rightPaddleDashBarBg.visible = false;
        }

        // Check and disable boost mechanics
        if (pongGame != null && (pongGame.leftPaddle.boostEnabled || pongGame.rightPaddle.boostEnabled)) {
            pongGame.leftPaddle.boostEnabled = false;
            pongGame.rightPaddle.boostEnabled = false;
            pongGame.ball.resetMomentum(); // Reset any existing momentum
            cheatsToDisable.push("Boost mechanics");
        }

        // Reset ball properties (unlimited speed, anti-clip)
        if (pongGame != null && pongGame.ball != null) {
            // Reset unlimited speed
            if (pongGame.ball.maxSpeed == Math.POSITIVE_INFINITY) {
                pongGame.ball.maxSpeed = 600; // Reset to default
                cheatsToDisable.push("Unlimited ball speed");
            }

            // Disable anti-clip
            if (pongGame.ball.antiClipEnabled) {
                pongGame.ball.antiClipEnabled = false;
                cheatsToDisable.push("Anti-clip protection");
            }
        }

        // Show notification of disabled cheats
        if (cheatsToDisable.length > 0) {
            var message = "Boss mode activated! Disabled cheats: " + cheatsToDisable.join(", ");
            updateInstructionText(message, true, 4.0);
        } else {
            updateInstructionText("Boss mode activated! No active cheats to disable.", true, 3.0);
        }
    }

    /**
     * Start a new boss phase with appropriate difficulty
     */
    private function startBossPhase():Void {
        if (pongGame == null) return;

        var difficulty = switch (bossPhase) {
            case 0: EASY;
            case 1: NORMAL;
            case 2: HARD;
            case 3: EXPERT;
            case 4: YES;
            case 5: GOD;
            default: GOD;
        };

        // Set right paddle to boss difficulty only
        // Left paddle keeps its original difficulty based on game mode
        pongGame.setAIDifficulty(pongGame.rightPaddle, difficulty);

        // Ensure right paddle is AI-controlled for boss mode
        pongGame.rightPaddle.isPlayer = false;

        // Set max score to very high value so game never ends due to score in boss mode
        pongGame.maxScore = 9999;

        // Set up YES difficulty mechanics
        if (difficulty == YES) {
            pongGame.rightPaddle.bossModeDashLimit = 5;
            pongGame.rightPaddle.bossModeDashUsed = 0;

            // Enable dashing for YES AI
            pongGame.rightPaddle.dashEnabled = true;

            // Enable boost for player in YES phase
            pongGame.leftPaddle.boostEnabled = true;
            pongGame.rightPaddle.boostEnabled = true;
            pongGame.ball.resetMomentum(); // Reset momentum

            updateDashBarsVisibility(); // Show dash bars for AI
        } else if (difficulty == GOD) {
            // GOD phase gets both dash and boost
            pongGame.rightPaddle.dashEnabled = true;
            pongGame.leftPaddle.boostEnabled = true;
            pongGame.rightPaddle.boostEnabled = true;
            pongGame.ball.resetMomentum(); // Reset momentum

            updateDashBarsVisibility(); // Show dash bars
        } else {
            pongGame.rightPaddle.bossModeDashLimit = 0; // No limit for other difficulties
            pongGame.rightPaddle.bossModeDashUsed = 0;

            // Disable dashing and boost for other difficulties in boss mode
            pongGame.rightPaddle.dashEnabled = false;
            pongGame.leftPaddle.boostEnabled = false;
            pongGame.rightPaddle.boostEnabled = false;
            pongGame.ball.resetMomentum(); // Reset momentum
            updateDashBarsVisibility(); // Hide dash bars
        }

        // Special setup for GOD phase
        if (bossPhase >= 5) {
            bossTimerText.visible = true;
            bossTimer = 0;
            createStarObstacles();
        }

        updateBossUI();

        // Use current game mode, but change TWO_PLAYER to PLAYER_VS_AI for boss mode
        var modeForBoss = currentGameMode == TWO_PLAYER ? PLAYER_VS_AI : currentGameMode;
        startNewGame(modeForBoss);
    }

    /**
     * Update boss mode UI text
     */
    private function updateBossUI():Void {
        bossLivesText.text = 'Lives: $bossLives';

        var phaseName = switch (bossPhase) {
            case 0: "Easy";
            case 1: "Normal";
            case 2: "Hard";
            case 3: "Expert";
            case 4: "Yes";
            case 5: "GOD";
            default: "BEYOND GOD";
        };

        // Add dash counter for YES difficulty
        if (bossPhase == 4 && pongGame != null && pongGame.rightPaddle != null) {
            var dashesLeft = pongGame.rightPaddle.bossModeDashLimit - pongGame.rightPaddle.bossModeDashUsed;
            if (dashesLeft > 0) {
                phaseName += ' (Dashes: $dashesLeft)';
            } else {
                phaseName += ' (DASHES EXHAUSTED)';
            }
        }

        bossPhaseText.text = 'Boss Phase: $phaseName';

        if (bossPhase >= 5) {
            var timeLeft = Math.max(0, bossMaxTime - bossTimer);
            var minutes = Math.floor(timeLeft / 60);
            var seconds = Math.floor(timeLeft % 60);
            bossTimerText.text = 'Time: ${minutes}:${seconds < 10 ? "0" : ""}${seconds}';
        }
    }

    /**
     * Create sparkling star obstacles for GOD phase
     */
    private function createStarObstacles():Void {
        if (bossStarObstacles == null) return;

        // Clear existing stars
        bossStarObstacles.clear();

        // Create 8-12 stars around the field
        var numStars = FlxG.random.int(8, 12);
        for (i in 0...numStars) {
            var star = new BossStarObstacle();

            // Position around the field edges
            if (FlxG.random.bool()) {
                // Top or bottom
                star.x = FlxG.random.float(gameFieldOffsetX + 50, gameFieldOffsetX + pongGame.fieldWidth - 50);
                star.y = FlxG.random.bool() ? gameFieldOffsetY + 20 : gameFieldOffsetY + pongGame.fieldHeight - 30;
            } else {
                // Left or right sides
                star.x = FlxG.random.bool() ? gameFieldOffsetX + 50 : gameFieldOffsetX + pongGame.fieldWidth - 60;
                star.y = FlxG.random.float(gameFieldOffsetY + 50, gameFieldOffsetY + pongGame.fieldHeight - 50);
            }

            bossStarObstacles.add(star);
        }
    }

    /**
     * Create special balls (freeze, frantic, dash, golden)
     */
    private function createSpecialBall(type:String):Void {
        if (bossSpecialBalls == null || bossSpecialBallSprites == null || pongGame == null) return;

        var ball = new BossSpecialBall(pongGame.fieldWidth, pongGame.fieldHeight, type);

        // Position the ball randomly in the field
        ball.position.x = FlxG.random.float(100, pongGame.fieldWidth - 100);
        ball.position.y = FlxG.random.float(100, pongGame.fieldHeight - 100);

        bossSpecialBalls.push(ball);
        bossSpecialBallTypes.push(type);

        // Create visual sprite for the special ball
        var sprite = new FlxSprite(ball.position.x, ball.position.y);
        sprite.makeGraphic(16, 16, ball.getColor());
        bossSpecialBallSprites.add(sprite);

        if (type == "dash") {
            bossGreenBallExists = true;
        }
    }

    private function updateBossSpecialBalls():Void {
        if (bossSpecialBalls == null || bossSpecialBallSprites == null || pongGame == null) return;

        // Check for special balls that should be removed (reached scoring edges)
        var ballsToRemove:Array<Int> = [];
        for (i in 0...bossSpecialBalls.length) {
            var ball = bossSpecialBalls[i];
            if (ball != null && ball.isAlive()) {
                // Remove special balls that reach the left or right edge (scoring areas)
                if (ball.position.x <= 0 || ball.position.x >= pongGame.fieldWidth) {
                    ballsToRemove.push(i);
                }
            }
        }

        // Remove special balls and their sprites in reverse order to avoid index issues
        ballsToRemove.reverse();
        for (index in ballsToRemove) {
            var ball = bossSpecialBalls[index];
            var sprite = bossSpecialBallSprites.members[index];

            if (ball != null) {
                ball.deactivate();
                bossSpecialBalls.splice(index, 1);
            }
            if (sprite != null) {
                sprite.kill();
                bossSpecialBallSprites.remove(sprite, true);
            }

            // Remove from types array
            if (index < bossSpecialBallTypes.length) {
                var removedType = bossSpecialBallTypes[index];
                bossSpecialBallTypes.splice(index, 1);

                // Update dash ball tracking
                if (removedType == "dash") {
                    bossGreenBallExists = false;
                }
            }
        }
    }

    /**
     * Handle boss mode updates
     */
    private function updateBossMode(elapsed:Float):Void {
        if (!bossMode) return;

        // Update timers
        if (bossPlayerDashCooldown > 0) {
            bossPlayerDashCooldown -= elapsed;
        }
        if (bossGodDashCooldown > 0) {
            bossGodDashCooldown -= elapsed;
        }

        // Check YES phase dash limit
        if (bossPhase == 4 && pongGame != null && pongGame.rightPaddle != null) {
            var paddle = pongGame.rightPaddle;
            if (paddle.bossModeDashLimit > 0 && paddle.bossModeDashUsed >= paddle.bossModeDashLimit) {
                // Disable dashing completely when limit reached
                if (paddle.dashEnabled) {
                    paddle.dashEnabled = false;
                    dashEnabled = false; // Disable global dash system
                    updateDashBarsVisibility(); // Hide dash bars
                    updateInstructionText('YES AI has exhausted all dashes! No more dashing!', true, 3.0);
                    updateBossUI(); // Update the counter display
                }
            }
        }

        // GOD phase timer
        if (bossPhase >= 5) {
            bossTimer += elapsed;
            updateBossUI();

            // Timer expired - enable unlimited speed
            if (bossTimer >= bossMaxTime) {
                if (pongGame != null && pongGame.ball != null) {
                    pongGame.ball.maxSpeed = Math.POSITIVE_INFINITY;
                    updateInstructionText('TIME\'S UP! Ball speed is now UNLIMITED!', true, 3.0);
                }
            }

            // Random star obstacle activation
            if (FlxG.random.float() < 0.01) { // 1% chance per frame
                activateRandomStar();
            }

            // Spawn special balls
            spawnSpecialBalls();

            // Handle ball clones (rare chance when GOD hits ball)
            if (FlxG.random.float() < 0.005) { // 0.5% chance per frame
                createBallClones();
            }
        }

        // Update special balls
        updateSpecialBalls(elapsed);

        // Update star obstacles
        updateStarObstacles(elapsed);
    }

    /**
     * Activate a random star as an obstacle
     */
    private function activateRandomStar():Void {
        if (bossStarObstacles == null || bossStarObstacles.length == 0) return;

        var star = bossStarObstacles.members[FlxG.random.int(0, bossStarObstacles.length - 1)];
        if (star != null) {
            star.activate(FlxG.random.float(3.0, 8.0));
        }
    }

    /**
     * Spawn special balls during GOD phase
     */
    private function spawnSpecialBalls():Void {
        // Green dash ball (only if none exists)
        if (!bossGreenBallExists && FlxG.random.float() < 0.005) {
            createSpecialBall("dash");
        }

        // Freeze ball
        if (FlxG.random.float() < 0.003) {
            createSpecialBall("freeze");
        }

        // Frantic ball
        if (FlxG.random.float() < 0.003) {
            createSpecialBall("frantic");
        }

        // Golden ball (rare, for slowing GOD - can spawn multiple times)
        if (FlxG.random.float() < 0.0015) { // Increased from 0.001 to 0.0015 for slightly better spawn rate
            createSpecialBall("golden");
        }
    }

    /**
     * Create ball clones when GOD hits the ball
     */
    private function createBallClones():Void {
        // TODO: Implement ball cloning system
        // This would need modifications to PongGame to support multiple balls
        updateInstructionText('GOD creates ball illusions!', true, 2.0);
    }

    /**
     * Update special balls
     */
    private function updateSpecialBalls(elapsed:Float):Void {
        if (bossSpecialBalls == null) return;

        for (ball in bossSpecialBalls) {
            if (ball == null || !ball.isAlive()) continue;

            // Update the ball's physics
            ball.update(elapsed);

            // Check if ball went out of bounds (scored)
            if (ball.scoredLeft() || ball.scoredRight(pongGame.fieldWidth)) {
                var type = ball.getType();
                if (type == "dash") {
                    bossGreenBallExists = false;
                }
                ball.deactivate();
                bossSpecialBallTypes.remove(type);
            }
        }
    }

    /**
     * Update star obstacles
     */
    private function updateStarObstacles(elapsed:Float):Void {
        if (bossStarObstacles == null) return;

        for (star in bossStarObstacles.members) {
            if (star == null || !star.getActive()) continue;

            var timer = star.getTimer();
            timer -= elapsed;
            star.setTimer(timer);

            if (timer <= 0) {
                star.deactivate();
            }
        }
    }

    /**
     * Handle boss mode round end
     */
    private function handleBossRoundEnd(winner:PongPlayer):Void {
        if (winner == PongPlayer.RIGHT) {
            // Boss won, player lost a life
            bossLives--;
            if (bossLives <= 0) {
                endBossMode(false);
                return;
            }
            updateInstructionText('Life lost! Lives remaining: $bossLives', true, 2.0);

            // Automatically restart the same phase after a short delay
            new FlxTimer().start(2.0, function(timer) {
                startBossPhase(); // Restart the same phase
            });
        } else {
            // Player won the phase
            bossPhase++;
            if (bossPhase > 5) {
                // Player beat GOD, boss mode complete
                endBossMode(true);
                return;
            }
            updateInstructionText('Phase complete! Advancing to next phase...', true, 3.0);

            // Start next phase after delay
            new FlxTimer().start(2.0, function(timer) {
                startBossPhase();
            });
        }
    }

    /**
     * End boss mode
     */
    private function endBossMode(victory:Bool):Void {
        bossMode = false;
        cheatsDisabled = false;

        // Hide boss UI
        bossLivesText.visible = false;
        bossTimerText.visible = false;
        bossPhaseText.visible = false;

        // Clear boss objects
        if (bossStarObstacles != null) bossStarObstacles.clear();
        if (bossSpecialBalls != null) bossSpecialBalls = [];
        if (bossSpecialBallSprites != null) bossSpecialBallSprites.clear();
        bossSpecialBallTypes = [];

        // Restore background
        bgSprite.color = bossOriginalBgColor;

        // Restore original max score
        if (pongGame != null) {
            pongGame.maxScore = defaultMaxScore;
        }

        if (victory) {
            showBossVictoryScreen();
        } else {
            updateInstructionText('BOSS MODE FAILED! Resetting in 5 seconds...', true, 5.0);
            new FlxTimer().start(5.0, function(timer) {
                backend.MusicBeatState.resetState();
            });
        }
    }

    /**
     * Show boss victory results screen
     */
    private function showBossVictoryScreen():Void {
        updateInstructionText('BOSS MODE VICTORY! You have conquered all difficulties!', true, 5.0);

        // TODO: Create detailed results screen substate
        // For now, just show success message and reset
        new FlxTimer().start(5.0, function(timer) {
            backend.MusicBeatState.resetState();
        });
    }

    /**
     * Handle ball interactions with special objects in boss mode
     */
    private function handleBallSpecialInteractions(ballX:Float, ballY:Float):Void {
        if (!bossMode) return;

        // Check special ball collisions
        if (bossSpecialBalls != null) {
            for (specialBall in bossSpecialBalls) {
                if (specialBall == null || !specialBall.isAlive()) continue;

                // Check collision with main ball using ball position system
                var dx = ballX - specialBall.position.x;
                var dy = ballY - specialBall.position.y;
                var distance = Math.sqrt(dx * dx + dy * dy);

                if (distance < (pongGame.ball.radius + specialBall.radius)) { // Collision detected
                    var type = specialBall.getType();
                    handleSpecialBallEffect(type);
                    specialBall.deactivate();

                    if (type == "dash") {
                        bossGreenBallExists = false;
                    }
                    bossSpecialBallTypes.remove(type);
                }
            }
        }

        // Check star obstacle collisions (red obstacles damage ball)
        if (bossPhase >= 5 && bossStarObstacles != null) {
            for (star in bossStarObstacles.members) {
                if (star == null || !star.getActive()) continue;

                var dx = ballX - (star.x + star.width/2);
                var dy = ballY - (star.y + star.height/2);
                var distance = Math.sqrt(dx * dx + dy * dy);

                if (distance < 12) { // Star collision
                    // Bounce ball away dramatically
                    if (pongGame != null && pongGame.ball != null) {
                        pongGame.ball.velocity.x *= -1.5;
                        pongGame.ball.velocity.y *= -1.5;

                        // Add some randomness
                        pongGame.ball.velocity.x += FlxG.random.float(-100, 100);
                        pongGame.ball.velocity.y += FlxG.random.float(-100, 100);
                    }

                    // Deactivate star
                    star.deactivate();

                    updateInstructionText('Star obstacle hit! Ball deflected!', true, 1.5);
                }
            }
        }
    }

    /**
     * Apply special ball effects
     */
    private function handleSpecialBallEffect(type:String):Void {
        switch (type) {
            case "freeze":
                // Freeze LEFT paddle (player) for 3 seconds - this is an obstacle!
                if (pongGame != null && pongGame.leftPaddle != null) {
                    pongGame.leftPaddle.freezeTimer = 3.0;
                    updateInstructionText('Freeze ball hit! You are frozen for 3 seconds!', true, 2.0);
                }

            case "frantic":
                // Increase ball speed dramatically for 5 seconds
                if (pongGame != null && pongGame.ball != null) {
                    pongGame.ball.speed *= 1.75;
                    updateInstructionText('Frantic ball collected! Ball speed increased!', true, 2.0);

                    // Reset after 5 seconds
                    new FlxTimer().start(5.0, function(timer) {
                        if (pongGame != null && pongGame.ball != null) {
                            pongGame.ball.speed /= 1.75;
                        }
                    });
                }

            case "dash":
                // Enable unlimited player dashing for 8 seconds
                if (pongGame != null && pongGame.leftPaddle != null) {
                    bossPlayerDashCooldown = -8.0; // Negative means unlimited
                    updateInstructionText('Dash ball collected! Unlimited dashing for 8 seconds!', true, 2.0);

                    // Reset after 8 seconds
                    new FlxTimer().start(8.0, function(timer) {
                        bossPlayerDashCooldown = 0;
                    });
                }

            case "golden":
                // PERMANENTLY slow down GOD paddle and enable its dash after 10 seconds
                if (pongGame != null && pongGame.rightPaddle != null) {
                    bossGoldenBallHits++;

                    // Permanent slowdown - multiply by 0.8 each time (gets progressively slower)
                    pongGame.rightPaddle.speed *= 0.8;

                    updateInstructionText('Golden ball collected! GOD permanently slowed down! Hits: $bossGoldenBallHits', true, 2.5);

                    // Enable boss dash ability after 10 seconds (only on first golden ball)
                    if (bossGoldenBallHits == 1) {
                        new FlxTimer().start(10.0, function(timer) {
                            if (pongGame != null && pongGame.rightPaddle != null && bossMode) {
                                pongGame.rightPaddle.dashEnabled = true;
                                bossGodDashCooldown = 0; // Reset cooldown so it can dash immediately
                                updateInstructionText('GOD has unlocked dash ability!', true, 3.0);
                            }
                        });
                    }
                }
        }
    }
}
