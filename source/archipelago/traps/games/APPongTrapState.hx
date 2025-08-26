package archipelago.traps.games;

import archipelago.traps.TrapDeathHandler;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import yutautil.games.pong.PongGameState;
import yutautil.games.pong.backend.PongGame.PongPlayer;

/**
 * Archipelago Pong Trap State
 * Extends PongGameState and modifies behavior for trap functionality
 * Player must score 5 points to win, losing results in forced death
 */
class APPongTrapState extends PongGameState {

    // Trap-specific properties
    private var previousState:MusicBeatState;
    private var requiredScore:Int = 5;
    private var trapInfoText:FlxText;
    public function new(?previousState:MusicBeatState = null) {
        this.previousState = previousState;
        super();
    }

    override function create() {
        super.create();

        // Add trap warning UI
        addTrapWarningUI();

        // Override game settings for trap mode
        setupTrapGame();

        // Start the game immediately
        startTrapGame();
    }

    private function addTrapWarningUI():Void {
        // Add prominent trap warning at the top
        trapInfoText = new FlxText(10, 10, FlxG.width - 20, "⚠️ ARCHIPELAGO TRAP ⚠️\nScore 5 points to survive! Losing means DEATH!", 20);
        trapInfoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, CENTER);
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
                if (winner == LEFT) {
                    // Player won - return to previous state
                    updateInstructionText("YOU SURVIVED THE PONG TRAP! Returning to game...");
                    new FlxTimer().start(2.0, function(timer) {
                        if (previousState != null) {
                            MusicBeatState.switchState(previousState);
                        } else {
                            MusicBeatState.switchState(new states.MainMenuState());
                        }
                    });
                } else {
                    // Player lost - force death
                    updateInstructionText("AI WINS! PREPARE TO DIE!");
                    new FlxTimer().start(2.0, function(timer) {
                        TrapDeathHandler.forceDeath(null, previousState);
                    });
                }
            };

            // Set required score for trap
            pongGame.maxScore = requiredScore;
        }
    }

    private function startTrapGame():Void {
        if (pongGame != null) {
            // Reset and start as Player vs AI with hard difficulty
            pongGame.resetGame();
            pongGame.startGame(PLAYER_VS_AI);
            pongGame.setAIDifficulty(pongGame.rightPaddle, HARD);
            updateInstructionText("TRAP ACTIVE! Score " + requiredScore + " points to survive!");
        }
    }
}
