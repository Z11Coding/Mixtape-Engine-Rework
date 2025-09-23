package yutautil.games.stealthmaze;

import archipelago.Archipelago;
import archipelago.apworld.TrapDeathHandler;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import yutautil.games.stealthmaze.backend.MazeData.MazeDifficulty;
import yutautil.games.stealthmaze.backend.MazeData;
import yutautil.games.stealthmaze.objects.MazeEnemy;
import yutautil.games.stealthmaze.objects.MazePlayer;

/**
 * Archipelago trap version of the stealth maze game
 * Integrates with AP system and uses forceDeath for trap handling
 */
class APStealthMazeTrapState extends StealthMazeGameState {

    // AP integration
    private var archipelago:Archipelago;
    private var trapDeathHandler:TrapDeathHandler;

    // Trap settings
    private var trapDifficulty:MazeDifficulty = MEDIUM;
    private var trapDuration:Float = 300.0; // 5 minutes default
    private var startTime:Float = 0;

    public function new(?difficulty:MazeDifficulty, ?duration:Float) {
        super(difficulty != null ? difficulty : MEDIUM);

        if (difficulty != null) {
            this.trapDifficulty = difficulty;
        }
        if (duration != null) {
            this.trapDuration = duration;
        }
    }

    override function create():Void {
        // Initialize AP integration
        initializeArchipelago();

        super.create();

        // Record start time
        startTime = haxe.Timer.stamp();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Archipelago Trap: Stealth Maze", "Difficulty: " + Std.string(trapDifficulty));
        #end
    }

    /**
     * Initialize Archipelago integration
     */
    private function initializeArchipelago():Void {
        try {
            archipelago = Archipelago.getInstance();
            trapDeathHandler = TrapDeathHandler.getInstance();

            if (trapDeathHandler == null) {
                trace("Warning: TrapDeathHandler not available, creating fallback");
                trapDeathHandler = new TrapDeathHandler();
            }
        } catch (e:Dynamic) {
            trace("Error initializing Archipelago: " + Std.string(e));
            // Create fallback handlers
            trapDeathHandler = new TrapDeathHandler();
        }
    }

    /**
     * Handle enemy catching player (AP trap version)
     */
    override private function enemyCaughtPlayer(player:MazePlayer, enemy:MazeEnemy):Void {
        if (gameState != PLAYING) return;

        // Use AP trap death instead of normal game over
        triggerTrapDeath("Caught by enemy in stealth maze trap!");
    }

    /**
     * Check trap-specific win/lose conditions
     */
    override private function checkGameConditions():Void {
        super.checkGameConditions();

        // Check trap timeout
        var elapsedTime = haxe.Timer.stamp() - startTime;
        if (elapsedTime >= trapDuration) {
            triggerTrapDeath("Time limit exceeded in stealth maze trap!");
        }
    }

    /**
     * Trigger AP trap death
     */
    private function triggerTrapDeath(reason:String):Void {
        if (gameState != PLAYING) return;

        gameState = LOSE;

        // Stop all movement
        if (player != null) {
            player.velocity.set(0, 0);
        }

        trace("Triggering trap death: " + reason);

        try {
            if (trapDeathHandler != null) {
                trapDeathHandler.forceDeath(reason);
            } else {
                trace("Warning: TrapDeathHandler not available, using fallback");
                fallbackTrapDeath(reason);
            }
        } catch (e:Dynamic) {
            trace("Error triggering trap death: " + Std.string(e));
            fallbackTrapDeath(reason);
        }
    }

    /**
     * Fallback trap death handling
     */
    private function fallbackTrapDeath(reason:String):Void {
        // Flash screen red and return to menu
        var flash = new FlxSprite();
        flash.makeGraphic(FlxG.width, FlxG.height, FlxColor.RED);
        flash.alpha = 0.7;
        flash.cameras = [uiCamera];
        add(flash);

        // Show trap death message
        var trapText = new FlxText(0, FlxG.height/2 - 40, FlxG.width, "ARCHIPELAGO TRAP", 32);
        trapText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        trapText.cameras = [uiCamera];
        add(trapText);

        var reasonText = new FlxText(0, FlxG.height/2, FlxG.width, reason, 16);
        reasonText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
        reasonText.cameras = [uiCamera];
        add(reasonText);

        // Auto-close after delay
        new FlxTimer().start(3.0, function(timer) {
            FlxG.switchState(new states.MainMenuState());
        });
    }

    /**
     * Handle successful maze completion (trap survived)
     */
    override private function showGameOver(won:Bool):Void {
        if (won) {
            // Player survived the trap!
            gameState = WIN;

            var elapsedTime = haxe.Timer.stamp() - startTime;
            trace('Player survived stealth maze trap! Time: ${Math.round(elapsedTime)}s, Score: $score');

            // Show success message
            var overlay = new FlxSprite();
            overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0.3, 0, 0.8));
            overlay.cameras = [uiCamera];
            add(overlay);

            var successText = new FlxText(0, FlxG.height/2 - 60, FlxG.width, "TRAP SURVIVED!", 32);
            successText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.GREEN, CENTER);
            successText.cameras = [uiCamera];
            add(successText);

            var timeText = new FlxText(0, FlxG.height/2 - 20, FlxG.width, 'Time: ${Math.round(elapsedTime)}s', 20);
            timeText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
            timeText.cameras = [uiCamera];
            add(timeText);

            var scoreText = new FlxText(0, FlxG.height/2 + 10, FlxG.width, 'Score: $score', 20);
            scoreText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
            scoreText.cameras = [uiCamera];
            add(scoreText);

            // Auto-close after delay
            new FlxTimer().start(4.0, function(timer) {
                FlxG.switchState(new states.MainMenuState());
            });

        } else {
            // Use trap death for loss
            triggerTrapDeath("Failed to complete stealth maze trap!");
        }
    }

    /**
     * Override pause functionality for traps
     */
    override private function pauseGame():Void {
        // Traps typically cannot be paused, but allow it for debugging
        #if debug
        super.pauseGame();
        #else
        // Show "Cannot pause trap" message briefly
        var pauseMessage = new FlxText(0, FlxG.height/2 - 10, FlxG.width, "Cannot pause trap game!", 20);
        pauseMessage.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, CENTER);
        pauseMessage.cameras = [uiCamera];
        add(pauseMessage);

        new FlxTimer().start(1.5, function(timer) {
            remove(pauseMessage);
            pauseMessage.destroy();
        });
        #end
    }

    /**
     * Get remaining time for display
     */
    private function getRemainingTime():Float {
        var elapsedTime = haxe.Timer.stamp() - startTime;
        return Math.max(0, trapDuration - elapsedTime);
    }

    /**
     * Update UI with trap-specific information
     */
    override private function updateUI():Void {
        super.updateUI();

        // Add trap timer to status text
        var remainingTime = getRemainingTime();
        var minutes = Math.floor(remainingTime / 60);
        var seconds = Math.floor(remainingTime % 60);

        statusText.text += ' | Time: ${minutes}:${seconds < 10 ? "0" : ""}${seconds}';

        // Update objective text for trap
        if (!hasRedObjective) {
            objectiveText.text = "TRAP: Find RED square and escape before time runs out!";
            objectiveText.color = FlxColor.ORANGE;
        } else {
            objectiveText.text = "TRAP: RED collected! Find GREEN exit quickly!";
            objectiveText.color = FlxColor.GREEN;
        }
    }

    /**
     * Handle input with trap-specific modifications
     */
    override private function handleInput():Void {
        // Don't allow escape key to pause in trap mode
        #if debug
        super.handleInput();
        #else
        // Only allow interaction and debug keys
        if (FlxG.keys.justPressed.E || FlxG.keys.justPressed.SPACE) {
            handleClosetInteraction();
        }
        #end
    }

    override function destroy():Void {
        archipelago = null;
        trapDeathHandler = null;
        super.destroy();
    }
}
