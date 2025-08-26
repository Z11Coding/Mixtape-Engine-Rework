package yutautil.games.pong;

import backend.MusicBeatState;
import flixel.FlxG;
import yutautil.games.pong.backend.PongGame.PongGameMode;
import yutautil.games.pong.backend.PongPaddle.PongAIDifficulty;

/**
 * Utility class for easy Pong game integration
 * Provides static methods to launch Pong with various configurations
 */
class PongLauncher {

    /**
     * Launch basic Pong game (Player vs AI, Normal difficulty)
     */
    public static function launch():Void {
        FlxG.switchState(new PongGameState());
    }

    /**
     * Launch Pong with specific game mode
     */
    public static function launchWithMode(mode:PongGameMode):Void {
        var pongState = new PongGameState();
        // Set the default mode - will be applied when game starts
        pongState.setDefaultGameMode(mode);
        FlxG.switchState(pongState);
    }

    /**
     * Launch two-player Pong
     */
    public static function launchTwoPlayer():Void {
        launchWithMode(TWO_PLAYER);
    }

    /**
     * Launch AI vs AI demonstration
     */
    public static function launchAIDemo():Void {
        launchWithMode(AI_VS_AI);
    }

    /**
     * Launch Pong with custom settings
     */
    public static function launchCustom(
        mode:PongGameMode = PLAYER_VS_AI,
        difficulty:PongAIDifficulty = NORMAL,
        maxScore:Int = 10,
        ballSpeed:Float = 200,
        paddleSpeed:Float = 350
    ):Void {
        var pongState = new PongGameState();
        pongState.setDefaultSettings(mode, difficulty, maxScore, ballSpeed, paddleSpeed);
        FlxG.switchState(pongState);
    }

    /**
     * Check if Pong is currently active
     */
    public static function isActive():Bool {
        return Std.isOfType(FlxG.state, PongGameState);
    }

    /**
     * Get current Pong state if active
     */
    public static function getCurrentState():PongGameState {
        if (isActive()) {
            return cast(FlxG.state, PongGameState);
        }
        return null;
    }

    /**
     * Quick access to launch from any state
     * Useful for debug menus or easter eggs
     */
    public static function quickLaunch(fromState:MusicBeatState):Void {
        trace("Launching Pong from " + Type.getClassName(Type.getClass(fromState)));
        launch();
    }
}
