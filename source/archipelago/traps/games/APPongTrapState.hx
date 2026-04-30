package archipelago.traps.games;

import archipelago.traps.TrapDeathHandler;
import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import stages.StageData;
import yutautil.KonamiTracker;
import yutautil.games.pong.PongGameState;
import yutautil.games.pong.backend.PongGame.PongPlayer;
import yutautil.games.pong.backend.PongPaddle.PongAIDifficulty;

/**
 * Archipelago Pong Trap State
 * Extends PongGameState with restricted functionality for AP traps
 * Features difficulty scaling, speed escalation, and cheat restrictions
 */
class APPongTrapState extends PongGameState {
    // Trap-specific properties
    private var previousState:Class<MusicBeatState>;
    private var trapDifficulty:Int = 2; // 1-5 scale
    private var requiredScore:Int = 2;
    private var trapInfoText:FlxText;
    private var speedEscalationTimer:FlxTimer;
    private var escalationActive:Bool = true;
    private var originalMaxSpeed:Float = 0;
    private var isAPTrapMode:Bool = true;

    public function new(?previousState:MusicBeatState = null, ?difficulty:Int = 2) {
        this.previousState = Type.getClass(previousState);
        this.trapDifficulty = difficulty != null ? difficulty : 2;
        super();
    }

    override function create() {

        if (!archipelago.APEntryState.inArchipelagoMode)
            throw "Error: APPongTrapState can only be used in Archipelago mode!";

        super.create();

        // Configure trap-specific settings
        setupTrapMode();

        // Add trap warning UI
        addTrapWarningUI();

        // Override game settings for trap mode
        setupTrapGame();

        // Start speed escalation system
        startSpeedEscalation();

        // Start the game immediately
        startTrapGame();
    }

    private function setupTrapMode():Void {
        isAPTrapMode = true;

        // Store original max speed for reset on scoring
        if (pongGame != null && pongGame.ball != null) {
            originalMaxSpeed = pongGame.ball.maxSpeed;
        }
    }

    override private function setupCheats():Void {
        konamiTracker = new KonamiTracker();

        // Only allow debug and non-ability cheats in AP mode

        // Debug traces cheat - spell "DEBUG" (allowed)
        konamiTracker.addCheatFromString("DEBUG", function(cheat) {
            debugTracesEnabled = !debugTracesEnabled;
            if (pongGame != null) {
                pongGame.debugTracesEnabled = debugTracesEnabled;
            }
            var status = debugTracesEnabled ? "ENABLED" : "DISABLED";
            updateInstructionText('Debug traces ' + status + '!', true, 2.0);
            if (debugTracesEnabled) {
                trace("Debug traces enabled in AP Pong!");
            }
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
        });

        // Ball debug info cheat - spell "SPEEDOMETER" (allowed)
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

        // Rainbow mode cheat - spell "LGBT" (allowed - cosmetic only)
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

        // Disable ability cheats by not adding them:
        // - UNLIMITED (gives infinite speed)
        // - GODISREAL (unlocks god mode AI)
        // - DASH (enables dash ability)
        // - BOSS (enables boss mode)
        // - FIREPOWER (adds multi-ball)
        // - NIGHTMARE (enables nightmare AI)
        // - OBSTACLE (adds obstacles)

        add(konamiTracker);
    }

    override private function setupMenu():Void {
        menuGroup = new FlxTypedGroup<FlxSprite>();
        menuTexts = new FlxTypedGroup<FlxText>();

        // Menu background
        var menuBg = new FlxSprite();
        menuBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.8));
        menuGroup.add(menuBg);

        // Restricted menu options for AP trap mode - only Resume button
        var menuOptions = [
            "Resume Game"
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

    override function handleMenuSelection():Void {
        if (!showingMenu) return;

        switch(selectedMenuItem) {
            case 0: // Resume Game
                if (pongGame != null) {
                    pongGame.togglePause();
                }
                toggleMenu();
            default:
                // No other options available in AP trap mode
        }
    }

    private function addTrapWarningUI():Void {
        // Add prominent trap warning at the top
        var difficultyName = getTrapDifficultyName(trapDifficulty);
        trapInfoText = new FlxText(10, 30, FlxG.width - 20,
            "⚠️ ARCHIPELAGO PONG TRAP ⚠️\n" +
            "Difficulty: " + difficultyName + "\n" +
            "Score " + requiredScore + " points to survive! Losing means DEATH!", 16);
        trapInfoText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER);
        add(trapInfoText);

        // Modify existing UI colors to warning theme
        if (bgSprite != null) {
            bgSprite.color = FlxColor.fromRGB(25, 15, 15); // Dark red tint
        }
    }

    private function setupTrapGame():Void {
        if (pongGame != null) {
            // Override the game end callback for trap behavior
            pongGame.onGameEnd = (winner) -> {
                isGameStarted = false;
                escalationActive = false;

                if (speedEscalationTimer != null) {
                    speedEscalationTimer.cancel();
                }

                if (winner == LEFT) {
                    // Player won - return to previous state
                    updateInstructionText("YOU SURVIVED THE PONG TRAP! Returning to game...");
                    new FlxTimer().start(2.0, function(timer) {
                        archipelago.APItem.APPongTrap.onTrapStateExit();
                        archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;
                        // Save AP Data.
                            APEntryState.apGame.updateSaveData();
                        if (previousState != null) {
                            FlxG.switchState(Type.createInstance(previousState, []));
                        } else {
                            StageData.loadDirectory(PlayfieldManager.SONG);
                            LoadingState.loadAndSwitchState(new archipelago.APPlayState());
                        }
                    });
                } else {
                    // Player lost - force death
                    updateInstructionText("AI WINS! PREPARE TO DIE!");
                    new FlxTimer().start(2.0, function(timer) {
                        archipelago.APItem.APPongTrap.onTrapStateExit();
                        archipelago.APInfo.inMinigame = archipelago.APInfo.APMinigame.None;
                        TrapDeathHandler.forceDeath("Lost Pong Challenge");
                    });
                }
            };

            // Override score callback to reset speed on scoring
            var originalOnScore = pongGame.onScore;
            pongGame.onScore = (player, leftScore, rightScore) -> {
                // Call original score handler
                if (originalOnScore != null) {
                    originalOnScore(player, leftScore, rightScore);
                }

                // Reset speed to original when point is scored
                if (pongGame.ball != null && originalMaxSpeed > 0) {
                    pongGame.ball.maxSpeed = originalMaxSpeed;
                    if (debugTracesEnabled) {
                        trace("Speed reset to " + originalMaxSpeed + " after score");
                    }
                }
            };

            // Set required score for trap
            pongGame.maxScore = requiredScore;

            pongGame.leftPaddle.dashEnabled = APItem.hasDashMechanic;
            pongGame.rightPaddle.dashEnabled = APItem.hasDashMechanic;

                    updateDashBarsVisibility();

        }
    }

    private function startTrapGame():Void {
        if (pongGame != null) {
            // Reset and start as Player vs AI with difficulty-based AI
            pongGame.resetGame();
            pongGame.startGame(PLAYER_VS_AI);

            // Set AI difficulty based on trap difficulty
            var aiDifficulty = getAIDifficultyFromTrapDifficulty(trapDifficulty);
            pongGame.setAIDifficulty(pongGame.rightPaddle, aiDifficulty);

            var difficultyName = getTrapDifficultyName(trapDifficulty);
            updateInstructionText("TRAP ACTIVE! " + difficultyName + " difficulty - Score " + requiredScore + " points to survive!");
        }
    }

    private function startSpeedEscalation():Void {
        escalationActive = true;

        // Every minute (60 seconds), add 200 to max speed
        speedEscalationTimer = new FlxTimer().start(60.0, function(timer) {
            if (escalationActive && pongGame != null && pongGame.ball != null) {
                pongGame.ball.maxSpeed += 200;
                if (debugTracesEnabled) {
                    trace("Speed escalated to: " + pongGame.ball.maxSpeed);
                }
                updateInstructionText("SPEED INCREASED! Max speed now: " + Std.int(pongGame.ball.maxSpeed), true, 3.0);

                // Continue escalation
                if (escalationActive) {
                    startSpeedEscalation();
                }
            }
        });
    }

    private function getTrapDifficultyName(difficulty:Int):String {
        return switch(difficulty) {
            case 1: "Easy";
            case 2: "Normal";
            case 3: "Hard";
            case 4: "Expert";
            case 5: "Nightmare";
            default: "Unknown";
        }
    }

    private function getAIDifficultyFromTrapDifficulty(trapDiff:Int):PongAIDifficulty {
        return switch(trapDiff) {
            case 1: EASY;
            case 2: NORMAL;
            case 3: HARD;
            case 4: EXPERT;
            case 5: YES; // Map "Nightmare" to YES difficulty
            default: GOD;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        #if ARCHIPELAGO_ALLOWED
		if (APEntryState.apGame != null && APEntryState.inArchipelagoMode)
			APEntryState.apGame.info()?.poll();
		#end
    }

    override function destroy():Void {
        if (speedEscalationTimer != null) {
            speedEscalationTimer.cancel();
            speedEscalationTimer.destroy();
        }

        escalationActive = false;

        super.destroy();
    }
}
