package archipelago.traps;

import backend.MusicBeatState;
import states.PlayState;
import substates.GameOverSubstate;

/**
 * Utility class for forcing death in AP trap games
 */
class TrapDeathHandler {

    /**
     * Forces the boyfriend to die and triggers game over
     * Does not require PlayState to exist - creates GameOverSubstate directly
     * Handles boyfriend detection specifically for AP trap functionality
     *
     * @param customReturnState Optional custom state to return to instead of restarting
     * @param customBackState Optional custom state for BACK button instead of menu
     */
    public static function forceDeath(?customReturnState:MusicBeatState = null, ?customBackState:MusicBeatState = null):Void {
        trace("TrapDeathHandler: Forcing death with custom states");

        // Try to get boyfriend from PlayState.instance if it exists
        var boyfriend:objects.Character = null;
        if (PlayState.instance != null && PlayState.instance.boyfriend != null) {
            boyfriend = PlayState.instance.boyfriend;
            trace("TrapDeathHandler: Found boyfriend in PlayState.instance");
        } else {
            trace("TrapDeathHandler: No PlayState.instance or boyfriend found, GameOverSubstate will create default");
        }

        // Create GameOverSubstate with boyfriend and custom states
        var gameOverSubstate = new GameOverSubstate(boyfriend, customReturnState, customBackState);

        // Switch to the game over substate
        FlxG.switchState(gameOverSubstate);
    }

    /**
     * Check if we can force death (always true now)
     */
    public static function canForceDeath():Bool {
        return true;
    }

    /**
     * Force death with automatic return to main menu
     */
    public static function forceDeathToMenu():Void {
        forceDeath(null, new states.MainMenuState());
    }

    /**
     * Force death with automatic return to previous state
     */
    public static function forceDeathToPreviousState(previousState:MusicBeatState):Void {
        forceDeath(null, previousState);
    }
}
