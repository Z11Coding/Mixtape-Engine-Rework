import games.match3.backend.*;
import games.match3.backend.Match3CPU.CPUDifficulty;
import games.match3.backend.Match3Game.GameMode;
import games.match3.backend.Match3Objective.Match3Objective;
import games.match3.backend.Match3Objective.Match3ObjectiveManager;
import games.match3.backend.Match3Piece.Match3PieceType;
import games.match3.backend.Match3Piece.SpecialType;

class TestMatch3Imports {
    static function main() {
        var piece = new Match3Piece(BASIC(RED), 0, 0);
        var board = new Match3Board(8, 8);
        var game = new Match3Game();
        var cpu = new Match3CPU();
        var objective = new Match3Objective(SCORE(100), 100, "Test");
        var manager = new Match3ObjectiveManager();
        trace("All imports working!");
    }
}
