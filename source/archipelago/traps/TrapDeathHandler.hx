package archipelago.traps;

import archipelago.APEntryState;
import archipelago.APPlayState;
import backend.COD;
import backend.ClientPrefs;
import backend.MusicBeatState;
import managers.FreeplayManager;
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
     * Sets cause of death and triggers death link if enabled
     *
     * @param causeOfDeath The reason for death to be displayed and sent via death link
     * @param customReturnState Optional custom state to return to instead of restarting
     * @param customBackState Optional custom state for BACK button instead of menu
     */
    public static function forceDeath(causeOfDeath:String, ?customReturnState:MusicBeatState = null, ?customBackState:MusicBeatState = null):Void {
        trace("TrapDeathHandler: Forcing death with cause: " + causeOfDeath);

        // Set the cause of death in the backend
        if (causeOfDeath != null && causeOfDeath != "") {
            COD.COD = causeOfDeath;
        } else {
            COD.COD = "Died in Archipelago trap.";
        }

        // Trigger death link if enabled and connected
        if (APInfo.apGame != null && APInfo.apGame.info() != null &&
            ClientPrefs.data.deathlink) {
            try {
                APInfo.apGame.info().sendDeathLink(undertale.UnderTextParser.removeFormatting(COD.COD));
                trace("TrapDeathHandler: Death link sent with cause: " + COD.COD);
            } catch (e:Dynamic) {
                trace("TrapDeathHandler: Failed to send death link: " + e);
            }
        }

        // Try to get boyfriend from PlayState.instance if it exists
        var boyfriend:objects.Character = null;
        if (PlayState.instance != null && PlayState.instance.boyfriend != null) {
            boyfriend = PlayState.instance.boyfriend;
            trace("TrapDeathHandler: Found boyfriend in PlayState.instance");
        } else {
            trace("TrapDeathHandler: No PlayState.instance or boyfriend found, GameOverSubstate will create default");
        }

        // If no custom return state is provided, use FreeplayState from APPlayState
        if (customReturnState == null) {
            customReturnState = cast FreeplayManager.getNewFreeplayInstance();
            trace("TrapDeathHandler: Using FreeplayState as return state");
        }

        // If no custom back state is provided, use FreeplayState from APPlayState
        if (customBackState == null) {
            customBackState = cast FreeplayManager.getNewFreeplayInstance();
            trace("TrapDeathHandler: Using FreeplayState as back state");
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
    public static function forceDeathToMenu(causeOfDeath:String):Void {
        var menuState = new states.MainMenuState();
        forceDeath(causeOfDeath, menuState, menuState);
    }

    /**
     * Force death with automatic return to previous state
     */
    public static function forceDeathToPreviousState(causeOfDeath:String, previousState:MusicBeatState):Void {
        forceDeath(causeOfDeath, previousState, previousState);
    }
}
