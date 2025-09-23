package yutautil.games.stealthmaze;

import yutautil.games.stealthmaze.APStealthMazeTrapState;
import yutautil.games.stealthmaze.StealthMazeGameState;
import yutautil.games.stealthmaze.StealthMazeLauncher;
import yutautil.games.stealthmaze.StealthMazeMinigameState;
import yutautil.games.stealthmaze.backend.MazeData.MazeDifficulty;
import yutautil.games.stealthmaze.backend.MazeData;
import yutautil.games.stealthmaze.backend.MazeGenerator;
import yutautil.games.stealthmaze.backend.MazePathfinder;
import yutautil.games.stealthmaze.objects.MazeEnemy;
import yutautil.games.stealthmaze.objects.MazeObjects;
import yutautil.games.stealthmaze.objects.MazePlayer;
/**
 * Index file for Stealth Maze game components
 * Provides easy access to all game classes and utilities
 */

// Main game states
// Backend systems
// Game objects
// Launcher utility

/**
 * Static utility class for accessing Stealth Maze components
 */
class StealthMazeIndex {

    /**
     * Quick access to launch the minigame preview
     */
    public static function launchMinigame():Void {
        StealthMazeLauncher.launchMinigame();
    }

    /**
     * Quick access to launch the full game
     */
    public static function launchGame(?difficulty:MazeData.MazeDifficulty):Void {
        if (difficulty != null) {
            StealthMazeLauncher.launchWithDifficulty(difficulty);
        } else {
            StealthMazeLauncher.launch();
        }
    }

    /**
     * Quick access to launch AP trap version
     */
    public static function launchAPTrap(?difficulty:MazeData.MazeDifficulty, ?duration:Float):Void {
        StealthMazeLauncher.launchAPTrap(difficulty, duration);
    }

    /**
     * Get game information
     */
    public static function getGameInfo():String {
        return "Stealth Maze v1.0 - Navigate mazes while avoiding enemies";
    }

    /**
     * Check if any stealth maze component is active
     */
    public static function isAnyMazeActive():Bool {
        return StealthMazeLauncher.isActive() || StealthMazeLauncher.isMinigameActive();
    }
}
