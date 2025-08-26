package archipelago.traps;

import archipelago.traps.games.APPongTrapState;
import archipelago.traps.games.APUnoTrapState;
import backend.MusicBeatState;

/**
 * Utility class for managing Archipelago trap games
 */
class TrapGameManager {

    public static var availableTrapGames:Map<String, Class<MusicBeatState>> = [
        "pong" => APPongTrapState,
        "uno" => APUnoTrapState
    ];

    /**
     * Launch a trap game by name
     * @param trapName Name of the trap game to launch ("pong", "uno")
     * @param previousState State to return to after trap completion
     * @return True if trap was launched, false if not found
     */
    public static function launchTrapGame(trapName:String, ?previousState:MusicBeatState):Bool {
        trapName = trapName.toLowerCase();

        if (!availableTrapGames.exists(trapName)) {
            trace('Trap game "$trapName" not found. Available traps: ${[for (key in availableTrapGames.keys()) key].join(", ")}');
            return false;
        }

        var trapClass = availableTrapGames.get(trapName);
        var trapInstance = Type.createInstance(trapClass, previousState != null ? [previousState] : []);

        FlxG.switchState(trapInstance);
        return true;
    }

    /**
     * Register a new trap game
     * @param name Name/ID of the trap game
     * @param trapClass Class that extends MusicBeatState (the trap games)
     */
    public static function registerTrapGame(name:String, trapClass:Class<MusicBeatState>):Void {
        availableTrapGames.set(name.toLowerCase(), trapClass);
        trace('Registered trap game: $name');
    }

    /**
     * Get list of available trap game names
     */
    public static function getAvailableTrapNames():Array<String> {
        return [for (key in availableTrapGames.keys()) key];
    }

    /**
     * Quick launch methods for specific traps
     */
    public static function launchPongTrap(?previousState:MusicBeatState):Bool {
        return launchTrapGame("pong", previousState);
    }

    public static function launchUnoTrap(?previousState:MusicBeatState):Bool {
        return launchTrapGame("uno", previousState);
    }
}
