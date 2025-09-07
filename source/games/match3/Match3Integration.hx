package games.match3;

import flixel.FlxG;
import flixel.util.FlxColor;
import games.match3.Match3TestState;
import games.match3.backend.*;
import games.match3.backend.Match3CPU.CPUDifficulty;
import games.match3.backend.Match3Game.GameMode;

/**
 * Integration helper for adding Match 3 game to existing menus
 */
class Match3Integration {

    /**
     * Launch the Match 3 game with default settings
     */
    public static function launchGame():Void {
        FlxG.switchState(new Match3TestState());
    }

    /**
     * Launch Match 3 with specific game mode
     */
    public static function launchGameMode(mode:GameMode):Void {
        var gameState = new Match3TestState();
        // You could extend Match3TestState to accept initial game mode
        FlxG.switchState(gameState);
    }

    /**
     * Create a quick match with predefined settings
     */
    public static function createQuickMatch():Match3Game {
        var game = new Match3Game(CLASSIC);
        var objectives = [
            new Match3Objective(SCORE(500), 500, "Score 500 points"),
            new Match3Objective(CLEAR_COLOR(FlxColor.RED, 10), 10, "Clear 10 red pieces")
        ];
        game.initialize(objectives, null, 15); // 15 moves limit
        return game;
    }

    /**
     * Create a VS CPU match
     */
    public static function createVSMatch(difficulty:CPUDifficulty = MEDIUM):Match3Game {
        var game = new Match3Game(VS_CPU);
        game.setCPUDifficulty(difficulty);

        var objectives = [
            new Match3Objective(SCORE(1000), 1000, "Score 1,000 points first")
        ];
        game.initialize(objectives);
        return game;
    }

    /**
     * Create an obstacle clearing challenge
     */
    public static function createObstacleChallenge():Match3Game {
        var game = new Match3Game(OBSTACLES);
        var objectives = [
            new Match3Objective(CLEAR_OBSTACLES(10), 10, "Clear all obstacles"),
            new Match3Objective(SCORE(800), 800, "Score 800 points")
        ];
        game.initialize(objectives, null, 20); // 20 moves limit
        return game;
    }

    /**
     * Get menu display name for game modes
     */
    public static function getGameModeDisplayName(mode:GameMode):String {
        return switch(mode) {
            case CLASSIC: "Classic Match 3";
            case TIMED: "Time Attack";
            case MOVES_LIMITED: "Puzzle Mode";
            case VS_CPU: "VS Computer";
            case OBSTACLES: "Clear the Path";
        }
    }

    /**
     * Get description for game modes
     */
    public static function getGameModeDescription(mode:GameMode):String {
        return switch(mode) {
            case CLASSIC: "Match pieces to complete objectives";
            case TIMED: "Race against the clock";
            case MOVES_LIMITED: "Solve puzzles with limited moves";
            case VS_CPU: "Compete against the computer";
            case OBSTACLES: "Clear obstacles by matching nearby";
        }
    }

    /**
     * Check if the game is available (for mod compatibility)
     */
    public static function isAvailable():Bool {
        return true; // Could check for required assets or settings
    }

    /**
     * Get available difficulties for VS mode
     */
    public static function getAvailableDifficulties():Array<CPUDifficulty> {
        return [EASY, MEDIUM, HARD, EXPERT];
    }

    /**
     * Get difficulty display name
     */
    public static function getDifficultyName(difficulty:CPUDifficulty):String {
        return switch(difficulty) {
            case EASY: "Easy";
            case MEDIUM: "Medium";
            case HARD: "Hard";
            case EXPERT: "Expert";
        }
    }
}

/**
 * Example of how to add Match 3 to MainMenuState
 * Add this to your MainMenuState.hx in the button creation section:
 *
 * var match3Button = new PsychUIButton(x, y, "Match 3", function() {
 *     games.match3.Match3Integration.launchGame();
 * });
 * add(match3Button);
 */
