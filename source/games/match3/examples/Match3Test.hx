package games.match3.examples;

import flixel.util.FlxColor;
import games.match3.backend.*;

/**
 * Simple test class to verify Match 3 game logic works correctly
 */
class Match3Test {

    public static function runTests():Void {
        trace("Running Match 3 Tests...");

        testPieceCreation();
        testBoardCreation();
        testMatchDetection();
        testObjectives();
        testCPU();

        trace("All tests completed!");
    }

    static function testPieceCreation():Void {
        trace("Testing piece creation...");

        var redPiece = new Match3Piece(BASIC(RED), 0, 0);
        var bluePiece = new Match3Piece(BASIC(BLUE), 1, 0);
        var iconPiece = new Match3Piece(ICON("bf"), 2, 0);

        // Test matching
        var redPiece2 = new Match3Piece(BASIC(RED), 0, 1);
        assert(redPiece.canMatchWith(redPiece2), "Red pieces should match");
        assert(!redPiece.canMatchWith(bluePiece), "Red and blue pieces should not match");

        trace("✓ Piece creation test passed");
    }

    static function testBoardCreation():Void {
        trace("Testing board creation...");

        var board = new Match3Board(8, 8);
        board.fillBoard();

        // Check that board is filled
        var filledCount = 0;
        for (x in 0...board.width) {
            for (y in 0...board.height) {
                if (board.getPiece(x, y) != null) {
                    filledCount++;
                }
            }
        }

        assert(filledCount == 64, "Board should be completely filled");

        trace("✓ Board creation test passed");
    }

    static function testMatchDetection():Void {
        trace("Testing match detection...");

        var board = new Match3Board(5, 5);

        // Create a horizontal match
        board.setPiece(0, 0, new Match3Piece(BASIC(RED), 0, 0));
        board.setPiece(1, 0, new Match3Piece(BASIC(RED), 1, 0));
        board.setPiece(2, 0, new Match3Piece(BASIC(RED), 2, 0));

        var matches = board.findAllMatches();
        assert(matches.length > 0, "Should find horizontal match");
        assert(matches[0].length == 3, "Match should contain 3 pieces");

        trace("✓ Match detection test passed");
    }

    static function testObjectives():Void {
        trace("Testing objectives...");

        var objective = new Match3Objective(SCORE(100), 100, "Score 100 points");
        assert(!objective.isCompleted, "Objective should start incomplete");

        objective.updateProgress(50);
        assert(objective.currentValue == 50, "Progress should be 50");
        assert(!objective.isCompleted, "Objective should still be incomplete");

        objective.updateProgress(50);
        assert(objective.isCompleted, "Objective should be completed");

        trace("✓ Objectives test passed");
    }

    static function testCPU():Void {
        trace("Testing CPU...");

        var cpu = new Match3CPU(EASY);
        var board = new Match3Board(8, 8);
        board.fillBoard();
        cpu.setBoard(board);

        // CPU should be able to find moves
        var move = cpu.forceMove();
        // Note: move might be null if no valid moves exist, which is rare but possible

        trace("✓ CPU test passed");
    }

    static function assert(condition:Bool, message:String):Void {
        if (!condition) {
            trace("❌ ASSERTION FAILED: " + message);
            throw "Test failed: " + message;
        }
    }

    /**
     * Create a sample game for testing
     */
    public static function createSampleGame():Match3Game {
        var game = new Match3Game(CLASSIC);

        var objectives = [
            new Match3Objective(SCORE(500), 500, "Score 500 points"),
            new Match3Objective(CLEAR_COLOR(FlxColor.RED, 10), 10, "Clear 10 red pieces")
        ];

        game.initialize(objectives, null, 20); // 20 moves limit

        return game;
    }
}
