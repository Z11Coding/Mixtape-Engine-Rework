package games.match3.backend;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import games.match3.backend.Match3CPU.CPUDifficulty;
import games.match3.backend.Match3Objective.Match3Objective;
import games.match3.backend.Match3Objective.Match3ObjectiveManager;

/**
 * Main Match 3 game logic controller
 */
class Match3Game {
    public var board:Match3Board;
    public var objectiveManager:Match3ObjectiveManager;
    public var gameMode:GameMode;
    public var currentPlayer:Int = 0; // 0 = Player, 1 = CPU (in VS mode)
    public var scores:Array<Int> = [0, 0];
    public var isGameOver:Bool = false;
    public var isProcessing:Bool = false;
    public var movesRemaining:Int = -1; // -1 = unlimited
    public var timeRemaining:Float = -1; // -1 = unlimited
    public var cascadeMultiplier:Int = 1;
    public var consecutiveCascades:Int = 0;

    // CPU for VS mode
    public var cpu:Match3CPU;

    // Game state tracking
    public var selectedPiece:FlxPoint = null;
    public var isWaitingForAnimation:Bool = false;
    public var pendingMatches:Array<Array<Match3Piece>> = [];
    public var totalCascades:Int = 0;

    // Callbacks for UI updates
    public var onScoreChanged:Int->Int->Void; // player, newScore
    public var onObjectiveUpdated:Match3Objective->Void;
    public var onGameOver:Bool->Void; // playerWon
    public var onPieceMatched:Array<Match3Piece>->Void;
    public var onCascade:Int->Void; // cascade count
    public var onSpecialActivated:Match3Piece->Array<Match3Piece>->Void;

    public function new(gameMode:GameMode = CLASSIC) {
        this.gameMode = gameMode;
        this.board = new Match3Board();
        this.objectiveManager = new Match3ObjectiveManager();

        if (gameMode == VS_CPU) {
            this.cpu = new Match3CPU(MEDIUM);
            this.cpu.setBoard(board);
        }

        reset();
    }

    /**
     * Initialize game with objectives and settings
     */
    public function initialize(objectives:Array<Match3Objective>, ?iconList:Array<String>, ?moves:Int, ?timeLimit:Float):Void {
        // Set up objectives
        objectiveManager.objectives = objectives;

        // Set up game limits
        if (moves != null && moves > 0) {
            movesRemaining = moves;
        }
        if (timeLimit != null && timeLimit > 0) {
            timeRemaining = timeLimit;
        }

        // Fill board
        board.fillBoard(iconList);

        isGameOver = false;
    }

    /**
     * Reset game to initial state
     */
    public function reset():Void {
        scores = [0, 0];
        currentPlayer = 0;
        isGameOver = false;
        isProcessing = false;
        isWaitingForAnimation = false;
        selectedPiece = null;
        cascadeMultiplier = 1;
        consecutiveCascades = 0;
        totalCascades = 0;
        pendingMatches = [];

        if (objectiveManager != null) {
            objectiveManager.reset();
        }

        if (cpu != null) {
            cpu.reset();
        }
    }

    /**
     * Update game logic
     */
    public function update(deltaTime:Float):Void {
        if (isGameOver || isWaitingForAnimation) {
            return;
        }

        // Update time limit
        if (timeRemaining > 0) {
            timeRemaining -= deltaTime;
            if (timeRemaining <= 0) {
                endGame(false);
                return;
            }
        }

        // Process any pending cascades
        if (pendingMatches.length > 0) {
            processPendingMatches();
            return;
        }

        // Check if processing animations
        if (isProcessing) {
            return;
        }

        // CPU turn in VS mode
        if (gameMode == VS_CPU && currentPlayer == 1 && cpu != null) {
            var move = cpu.update(deltaTime);
            if (move != null) {
                makeMove(move.fromX, move.fromY, move.toX, move.toY);
            }
        }

        // Check for game over conditions
        checkGameOverConditions();
    }

    /**
     * Attempt to select a piece or make a move
     */
    public function handleClick(x:Int, y:Int):Bool {
        if (isGameOver || isProcessing || isWaitingForAnimation) {
            return false;
        }

        // In VS mode, check if it's player's turn
        if (gameMode == VS_CPU && currentPlayer != 0) {
            return false;
        }

        if (selectedPiece == null) {
            // Select piece
            var piece = board.getPiece(x, y);
            if (piece != null && piece.type != OBSTACLE) {
                selectedPiece = new FlxPoint(x, y);
                return true;
            }
        } else {
            // Try to make a move
            var success = makeMove(Std.int(selectedPiece.x), Std.int(selectedPiece.y), x, y);
            selectedPiece = null;
            return success;
        }

        return false;
    }

    /**
     * Make a move between two positions
     */
    public function makeMove(fromX:Int, fromY:Int, toX:Int, toY:Int):Bool {
        if (isGameOver || isProcessing) {
            return false;
        }

        // Check if this would create a valid match
        var success = board.swapPieces(fromX, fromY, toX, toY);

        if (success) {
            isProcessing = true;
            cascadeMultiplier = 1;
            consecutiveCascades = 0;

            // Use up a move if limited
            if (movesRemaining > 0) {
                movesRemaining--;
            }

            // Process initial matches
            processAllMatches();

            // Switch turns in VS mode
            if (gameMode == VS_CPU) {
                currentPlayer = (currentPlayer + 1) % 2;
            }

            return true;
        }

        return false;
    }

    /**
     * Process all matches and cascades
     */
    private function processAllMatches():Void {
        var hasMatches = board.hasMatches();

        if (hasMatches) {
            var matches = board.findAllMatches();
            var allMatchedPieces:Array<Match3Piece> = [];

            // Collect all matched pieces
            for (match in matches) {
                for (piece in match) {
                    allMatchedPieces.push(piece);
                }
            }

            // Update score
            var pointsEarned = calculateScore(allMatchedPieces);
            scores[currentPlayer] += pointsEarned;

            if (onScoreChanged != null) {
                onScoreChanged(currentPlayer, scores[currentPlayer]);
            }

            // Update objectives
            objectiveManager.processMatch(allMatchedPieces, board);

            if (onPieceMatched != null) {
                onPieceMatched(allMatchedPieces);
            }

            // Remove matched pieces and create power-ups
            var removedPieces = board.processMatches();

            // Check for special piece activations
            for (piece in removedPieces) {
                if (piece.isSpecial) {
                    var affected = board.activatePowerUp(piece.x, piece.y);
                    if (onSpecialActivated != null) {
                        onSpecialActivated(piece, affected);
                    }
                }
            }

            // Apply gravity and check for cascades
            isWaitingForAnimation = true;
            scheduleGravityAndCascadeCheck();
        } else {
            isProcessing = false;
        }
    }

    /**
     * Schedule gravity application and cascade checking
     */
    private function scheduleGravityAndCascadeCheck():Void {
        // This would normally be called after animations complete
        // For now, we'll process immediately
        applyGravityAndCheckCascades();
    }

    /**
     * Apply gravity and check for new cascades
     */
    private function applyGravityAndCheckCascades():Void {
        var piecesMoving = board.applyGravity();

        if (piecesMoving) {
            // Wait for falling animation to complete
            isWaitingForAnimation = true;
            // In a real implementation, this would be called by animation completion
            checkForNewMatches();
        } else {
            checkForNewMatches();
        }
    }

    /**
     * Check for new matches after pieces have fallen
     */
    private function checkForNewMatches():Void {
        isWaitingForAnimation = false;

        if (board.hasMatches()) {
            consecutiveCascades++;
            cascadeMultiplier++;
            totalCascades++;

            if (onCascade != null) {
                onCascade(consecutiveCascades);
            }

            objectiveManager.processCascade(1);

            // Process new matches
            processAllMatches();
        } else {
            // No more matches, turn is over
            cascadeMultiplier = 1;
            consecutiveCascades = 0;
            isProcessing = false;
        }
    }

    /**
     * Process pending matches (used for delayed processing)
     */
    private function processPendingMatches():Void {
        if (pendingMatches.length > 0) {
            var matches = pendingMatches.shift();
            // Process the match
            processAllMatches();
        }
    }

    /**
     * Calculate score from matched pieces
     */
    private function calculateScore(pieces:Array<Match3Piece>):Int {
        var baseScore = 0;

        for (piece in pieces) {
            baseScore += switch(piece.type) {
                case BASIC(_): 10;
                case ICON(_): 15;
                case POWER_UP(_, _): 50;
                case OBSTACLE: 25;
            }
        }

        // Apply cascade multiplier
        return Math.floor(baseScore * cascadeMultiplier);
    }

    /**
     * Check for game over conditions
     */
    private function checkGameOverConditions():Void {
        // Check objectives completion
        if (objectiveManager.allCompleted) {
            endGame(true);
            return;
        }

        // Check moves limit
        if (movesRemaining == 0) {
            endGame(false);
            return;
        }

        // Check if no moves are possible
        if (!board.hasPossibleMoves()) {
            endGame(false);
            return;
        }

        // VS mode specific checks
        if (gameMode == VS_CPU) {
            // Could add specific VS winning conditions here
        }
    }

    /**
     * End the game
     */
    private function endGame(playerWon:Bool):Void {
        isGameOver = true;
        isProcessing = false;

        if (onGameOver != null) {
            onGameOver(playerWon);
        }
    }

    /**
     * Get current score for a player
     */
    public function getScore(player:Int = 0):Int {
        if (player >= 0 && player < scores.length) {
            return scores[player];
        }
        return 0;
    }

    /**
     * Add points to a player's score
     */
    public function addToScore(points:Int, player:Int = 0):Void {
        if (player >= 0 && player < scores.length) {
            scores[player] += points;
            if (onScoreChanged != null) {
                onScoreChanged(player, scores[player]);
            }
        }
    }

    /**
     * Get game progress (for objectives)
     */
    public function getProgress():Float {
        return objectiveManager.getOverallProgress();
    }

    /**
     * Check if a position is selected
     */
    public function isPositionSelected(x:Int, y:Int):Bool {
        return selectedPiece != null && selectedPiece.x == x && selectedPiece.y == y;
    }

    /**
     * Clear current selection
     */
    public function clearSelection():Void {
        selectedPiece = null;
    }

    /**
     * Set CPU difficulty (for VS mode)
     */
    public function setCPUDifficulty(difficulty:CPUDifficulty):Void {
        if (cpu != null) {
            cpu.difficulty = difficulty;
        }
    }

    /**
     * Get available character icons from game assets
     */
    public static function getAvailableIcons():Array<String> {
        // This would scan for available character icons
        // For now, return some default examples
        return [
            "bf", "dad", "gf", "mom", "spooky", "pico",
            "monster", "senpai", "spirit", "tankman"
        ];
    }

    /**
     * Create preset objectives for different game modes
     */
    public static function createClassicObjectives():Array<Match3Objective> {
        return [
            new Match3Objective(SCORE(1000), 1000, "Score 1,000 points"),
            new Match3Objective(CLEAR_COLOR(FlxColor.RED, 20), 20, "Clear 20 red pieces"),
            new Match3Objective(CLEAR_SPECIAL(HORIZONTAL_STRIPE, 3), 3, "Create 3 stripe power-ups")
        ];
    }

    public static function createObstacleObjectives():Array<Match3Objective> {
        return [
            new Match3Objective(CLEAR_OBSTACLES(15), 15, "Clear 15 obstacles"),
            new Match3Objective(SCORE(1500), 1500, "Score 1,500 points"),
            new Match3Objective(CASCADE_MATCHES(5), 5, "Create 5 cascade matches")
        ];
    }

    public static function createVSObjectives():Array<Match3Objective> {
        return [
            new Match3Objective(SCORE(2000), 2000, "Score 2,000 points"),
            new Match3Objective(SURVIVE_TURNS(10), 10, "Survive 10 turns")
        ];
    }
}

/**
 * Game mode types
 */
enum GameMode {
    CLASSIC;        // Single player with objectives
    TIMED;          // Time-limited mode
    MOVES_LIMITED;  // Limited moves mode
    VS_CPU;         // Player vs CPU
    OBSTACLES;      // Board with obstacles to clear
}
