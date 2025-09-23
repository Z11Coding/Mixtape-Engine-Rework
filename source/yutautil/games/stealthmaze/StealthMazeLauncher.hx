package yutautil.games.stealthmaze;

import backend.MusicBeatState;
import flixel.FlxG;
import yutautil.games.stealthmaze.backend.MazeData.MazeDifficulty;

/**
 * Utility class for easy Stealth Maze game integration
 * Provides static methods to launch the game with various configurations
 */
class StealthMazeLauncher {

    /**
     * Launch the minigame preview/demo state
     */
    public static function launchMinigame():Void {
        FlxG.switchState(new StealthMazeMinigameState());
    }

    /**
     * Launch the full stealth maze game with default settings (Medium difficulty)
     */
    public static function launch():Void {
        FlxG.switchState(new StealthMazeGameState());
    }

    /**
     * Launch stealth maze game with specific difficulty
     */
    public static function launchWithDifficulty(difficulty:MazeDifficulty):Void {
        FlxG.switchState(new StealthMazeGameState(difficulty));
    }

    /**
     * Launch easy difficulty stealth maze
     */
    public static function launchEasy():Void {
        launchWithDifficulty(EASY);
    }

    /**
     * Launch medium difficulty stealth maze
     */
    public static function launchMedium():Void {
        launchWithDifficulty(MEDIUM);
    }

    /**
     * Launch hard difficulty stealth maze
     */
    public static function launchHard():Void {
        launchWithDifficulty(HARD);
    }

    /**
     * Launch Archipelago trap version with specific settings
     */
    public static function launchAPTrap(difficulty:MazeDifficulty = MEDIUM, duration:Float = 300.0):Void {
        FlxG.switchState(new APStealthMazeTrapState(difficulty, duration));
    }

    /**
     * Quick launch from any state for debugging/easter eggs
     */
    public static function quickLaunch(fromState:MusicBeatState):Void {
        trace("Launching Stealth Maze from " + Type.getClassName(Type.getClass(fromState)));
        launch();
    }

    /**
     * Quick launch minigame preview from any state
     */
    public static function quickLaunchMinigame(fromState:MusicBeatState):Void {
        trace("Launching Stealth Maze minigame from " + Type.getClassName(Type.getClass(fromState)));
        launchMinigame();
    }

    /**
     * Check if stealth maze game is currently active
     */
    public static function isActive():Bool {
        return Std.isOfType(FlxG.state, StealthMazeGameState) ||
               Std.isOfType(FlxG.state, APStealthMazeTrapState);
    }

    /**
     * Check if minigame preview is currently active
     */
    public static function isMinigameActive():Bool {
        return Std.isOfType(FlxG.state, StealthMazeMinigameState);
    }

    /**
     * Get current stealth maze state if active
     */
    public static function getCurrentGameState():StealthMazeGameState {
        if (Std.isOfType(FlxG.state, StealthMazeGameState)) {
            return cast(FlxG.state, StealthMazeGameState);
        }
        if (Std.isOfType(FlxG.state, APStealthMazeTrapState)) {
            return cast(FlxG.state, APStealthMazeTrapState);
        }
        return null;
    }

    /**
     * Get current minigame state if active
     */
    public static function getCurrentMinigameState():StealthMazeMinigameState {
        if (isMinigameActive()) {
            return cast(FlxG.state, StealthMazeMinigameState);
        }
        return null;
    }

    /**
     * Get difficulty string for display
     */
    public static function getDifficultyString(difficulty:MazeDifficulty):String {
        switch (difficulty) {
            case EASY: return "Easy";
            case MEDIUM: return "Medium";
            case HARD: return "Hard";
            case EXPERT: return "Expert";
            case NIGHTMARE: return "Nightmare";
            default: return "Medium";
        }
    }

    /**
     * Get difficulty from string (for settings/config)
     */
    public static function getDifficultyFromString(difficultyStr:String):MazeDifficulty {
        switch (difficultyStr.toLowerCase()) {
            case "easy": return EASY;
            case "medium": return MEDIUM;
            case "hard": return HARD;
            case "expert": return EXPERT;
            case "nightmare": return NIGHTMARE;
            default: return MEDIUM;
        }
    }

    /**
     * Launch AP trap with easy settings for quick testing
     */
    public static function launchAPTrapEasy():Void {
        launchAPTrap(EASY, 180.0); // 3 minutes
    }

    /**
     * Launch AP trap with hard settings for challenging gameplay
     */
    public static function launchAPTrapHard():Void {
        launchAPTrap(HARD, 600.0); // 10 minutes
    }
}
