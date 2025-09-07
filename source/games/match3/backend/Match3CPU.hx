package games.match3.backend;

import flixel.math.FlxPoint;
import games.match3.backend.Match3Piece.SpecialType;

/**
 * CPU player for Match 3 VS mode
 */
class Match3CPU {
    public var difficulty:CPUDifficulty;
    public var thinkTime:Float = 1.0; // Time in seconds before making a move
    public var board:Match3Board;

    private var possibleMoves:Array<Match3Move> = [];
    private var lastMoveTime:Float = 0;

    public function new(difficulty:CPUDifficulty = MEDIUM) {
        this.difficulty = difficulty;
        setDifficultyParameters();
    }

    /**
     * Set CPU parameters based on difficulty
     */
    private function setDifficultyParameters():Void {
        switch(difficulty) {
            case EASY:
                thinkTime = 2.0;
            case MEDIUM:
                thinkTime = 1.5;
            case HARD:
                thinkTime = 1.0;
            case EXPERT:
                thinkTime = 0.5;
        }
    }

    /**
     * Set the board this CPU is playing on
     */
    public function setBoard(board:Match3Board):Void {
        this.board = board;
    }

    /**
     * Update CPU and potentially make a move
     */
    public function update(deltaTime:Float):Match3Move {
        if (board == null || board.isProcessing) {
            return null;
        }

        lastMoveTime += deltaTime;

        if (lastMoveTime >= thinkTime) {
            lastMoveTime = 0;
            return makeMove();
        }

        return null;
    }

    /**
     * Make the best move available
     */
    public function makeMove():Match3Move {
        findAllPossibleMoves();

        if (possibleMoves.length == 0) {
            return null;
        }

        var bestMove = selectBestMove();
        return bestMove;
    }

    /**
     * Find all possible moves on the current board
     */
    private function findAllPossibleMoves():Void {
        possibleMoves = [];

        for (x in 0...board.width) {
            for (y in 0...board.height) {
                var piece = board.getPiece(x, y);
                if (piece == null || piece.type == OBSTACLE) {
                    continue;
                }

                // Check all adjacent positions
                var directions = [
                    {dx: 1, dy: 0},
                    {dx: 0, dy: 1},
                    {dx: -1, dy: 0},
                    {dx: 0, dy: -1}
                ];

                for (dir in directions) {
                    var newX = x + dir.dx;
                    var newY = y + dir.dy;

                    if (board.isValidPosition(newX, newY)) {
                        var move = new Match3Move(x, y, newX, newY);
                        var score = evaluateMove(move);
                        if (score > 0) {
                            move.score = score;
                            possibleMoves.push(move);
                        }
                    }
                }
            }
        }
    }

    /**
     * Evaluate how good a move is
     */
    private function evaluateMove(move:Match3Move):Int {
        // Simulate the move
        var piece1 = board.getPiece(move.fromX, move.fromY);
        var piece2 = board.getPiece(move.toX, move.toY);

        // Temporarily make the swap
        board.setPiece(move.fromX, move.fromY, piece2);
        board.setPiece(move.toX, move.toY, piece1);

        var score = 0;
        var matches = board.findAllMatches();

        if (matches.length > 0) {
            // Basic scoring
            for (match in matches) {
                score += match.length * 10;

                // Bonus for larger matches
                if (match.length >= 4) {
                    score += 20;
                }
                if (match.length >= 5) {
                    score += 50;
                }

                // Bonus for creating special pieces
                var specialType = determineSpecialType(match);
                if (specialType != NONE) {
                    score += getSpecialBonus(specialType);
                }
            }

            // Look ahead for cascade potential
            score += evaluateCascadePotential();

            // Difficulty-based adjustments
            score = applyDifficultyModifier(score);
        }

        // Swap back
        board.setPiece(move.fromX, move.fromY, piece1);
        board.setPiece(move.toX, move.toY, piece2);

        return score;
    }

    /**
     * Determine special type that would be created from a match
     */
    private function determineSpecialType(match:Array<Match3Piece>):SpecialType {
        if (match.length == 4) {
            // Check if horizontal or vertical
            var isHorizontal = true;
            if (match.length > 1) {
                var firstY = match[0].y;
                for (i in 1...match.length) {
                    if (match[i].y != firstY) {
                        isHorizontal = false;
                        break;
                    }
                }
            }
            return isHorizontal ? HORIZONTAL_STRIPE : VERTICAL_STRIPE;
        } else if (match.length == 5) {
            return COLOR_BOMB;
        } else if (match.length >= 6) {
            return BOMB;
        }
        return NONE;
    }

    /**
     * Get bonus score for creating special pieces
     */
    private function getSpecialBonus(specialType:SpecialType):Int {
        return switch(specialType) {
            case HORIZONTAL_STRIPE | VERTICAL_STRIPE: 30;
            case BOMB: 50;
            case COLOR_BOMB: 100;
            case RAINBOW: 75;
            case NONE: 0;
        }
    }

    /**
     * Evaluate potential for cascade matches
     */
    private function evaluateCascadePotential():Int {
        // Simple heuristic: count pieces that would fall and potentially create matches
        var cascadeScore = 0;

        // This is a simplified version - a full implementation would simulate gravity
        for (x in 0...board.width) {
            for (y in 0...board.height) {
                if (board.getPiece(x, y) == null) {
                    // Empty space could lead to cascades
                    cascadeScore += 5;
                }
            }
        }

        return cascadeScore;
    }

    /**
     * Apply difficulty modifier to move score
     */
    private function applyDifficultyModifier(baseScore:Int):Int {
        return switch(difficulty) {
            case EASY:
                // Easy CPU sometimes makes suboptimal moves
                Math.floor(baseScore * (0.6 + Math.random() * 0.4));
            case MEDIUM:
                // Medium CPU is fairly consistent
                Math.floor(baseScore * (0.8 + Math.random() * 0.3));
            case HARD:
                // Hard CPU is very consistent
                Math.floor(baseScore * (0.9 + Math.random() * 0.2));
            case EXPERT:
                // Expert CPU always makes optimal moves
                baseScore;
        }
    }

    /**
     * Select the best move from available options
     */
    private function selectBestMove():Match3Move {
        if (possibleMoves.length == 0) {
            return null;
        }

        // Sort moves by score (highest first)
        possibleMoves.sort((a, b) -> b.score - a.score);

        // Difficulty affects move selection
        var selectedIndex = switch(difficulty) {
            case EASY:
                // Pick from top 3 moves randomly, or random if less available
                Math.floor(Math.random() * Math.min(3, possibleMoves.length));
            case MEDIUM:
                // Pick from top 2 moves randomly, or best if only one
                Math.floor(Math.random() * Math.min(2, possibleMoves.length));
            case HARD | EXPERT:
                // Always pick the best move
                0;
        }

        return possibleMoves[selectedIndex];
    }

    /**
     * Force CPU to make an immediate move (for testing)
     */
    public function forceMove():Match3Move {
        lastMoveTime = thinkTime;
        return makeMove();
    }

    /**
     * Reset CPU state
     */
    public function reset():Void {
        possibleMoves = [];
        lastMoveTime = 0;
    }
}

/**
 * CPU difficulty levels
 */
enum CPUDifficulty {
    EASY;
    MEDIUM;
    HARD;
    EXPERT;
}

/**
 * Represents a potential move
 */
class Match3Move {
    public var fromX:Int;
    public var fromY:Int;
    public var toX:Int;
    public var toY:Int;
    public var score:Int = 0;

    public function new(fromX:Int, fromY:Int, toX:Int, toY:Int) {
        this.fromX = fromX;
        this.fromY = fromY;
        this.toX = toX;
        this.toY = toY;
    }

    public function toString():String {
        return 'Move ($fromX, $fromY) -> ($toX, $toY) [Score: $score]';
    }
}
