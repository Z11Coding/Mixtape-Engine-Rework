package games.match3.backend;

import flixel.util.FlxColor;
import games.match3.backend.Match3Piece.Match3PieceType;
import games.match3.backend.Match3Piece.SpecialType;

/**
 * Defines objectives for Match 3 games
 */
class Match3Objective {
    public var type:ObjectiveType;
    public var targetValue:Int;
    public var currentValue:Int = 0;
    public var isCompleted:Bool = false;
    public var description:String;

    public function new(type:ObjectiveType, targetValue:Int, description:String) {
        this.type = type;
        this.targetValue = targetValue;
        this.description = description;
    }

    /**
     * Update objective progress
     */
    public function updateProgress(amount:Int = 1):Void {
        currentValue += amount;
        if (currentValue >= targetValue) {
            currentValue = targetValue;
            isCompleted = true;
        }
    }

    /**
     * Get progress percentage (0-1)
     */
    public function getProgress():Float {
        return targetValue > 0 ? currentValue / targetValue : 0;
    }

    /**
     * Get remaining amount needed
     */
    public function getRemaining():Int {
        return Std.int(Math.max(0, targetValue - currentValue));
    }

    /**
     * Reset objective
     */
    public function reset():Void {
        currentValue = 0;
        isCompleted = false;
    }

    /**
     * Check if a piece match contributes to this objective
     */
    public function checkContribution(pieces:Array<Match3Piece>, board:Match3Board):Int {
        return switch(type) {
            case SCORE(target): pieces.length * 10; // Base scoring
            case CLEAR_COLOR(color, count): countColorMatches(pieces, color);
            case CLEAR_OBSTACLES(count): 0; // Handled separately when obstacles are cleared
            case COLLECT_PIECES(pieceType, count): countTypeMatches(pieces, pieceType);
            case MAKE_COLORED_TILES(color, count): 0; // Handled when tiles change color
            case CLEAR_SPECIAL(specialType, count): countSpecialMatches(pieces, specialType);
            case SURVIVE_TURNS(turns): 0; // Handled by turn manager
            case CASCADE_MATCHES(cascades): 0; // Handled by cascade counter
        }
    }

    private function countColorMatches(pieces:Array<Match3Piece>, targetColor:FlxColor):Int {
        var count = 0;
        for (piece in pieces) {
            if (piece.color == targetColor) {
                count++;
            }
        }
        return count;
    }

    private function countTypeMatches(pieces:Array<Match3Piece>, targetType:Match3PieceType):Int {
        var count = 0;
        for (piece in pieces) {
            if (Match3Piece.typesMatch(piece.type, targetType)) {
                count++;
            }
        }
        return count;
    }

    private function countSpecialMatches(pieces:Array<Match3Piece>, targetSpecial:SpecialType):Int {
        var count = 0;
        for (piece in pieces) {
            if (piece.isSpecial && piece.specialType == targetSpecial) {
                count++;
            }
        }
        return count;
    }

    public function toString():String {
        return '$description: $currentValue/$targetValue';
    }
}

/**
 * Types of objectives
 */
enum ObjectiveType {
    SCORE(target:Int);                                    // Reach target score
    CLEAR_COLOR(color:FlxColor, count:Int);              // Clear X pieces of specific color
    CLEAR_OBSTACLES(count:Int);                          // Clear X obstacles
    COLLECT_PIECES(pieceType:Match3PieceType, count:Int); // Collect X pieces of specific type
    MAKE_COLORED_TILES(color:FlxColor, count:Int);       // Make X tiles turn into specific color
    CLEAR_SPECIAL(specialType:SpecialType, count:Int);   // Create and use X special pieces
    SURVIVE_TURNS(turns:Int);                            // Survive X turns (VS mode)
    CASCADE_MATCHES(cascades:Int);                       // Cause X cascade matches
}

/**
 * Manages multiple objectives for a Match 3 game
 */
class Match3ObjectiveManager {
    public var objectives:Array<Match3Objective> = [];
    public var allCompleted:Bool = false;

    public function new() {}

    /**
     * Add an objective
     */
    public function addObjective(objective:Match3Objective):Void {
        objectives.push(objective);
        updateCompletionStatus();
    }

    /**
     * Process match and update relevant objectives
     */
    public function processMatch(pieces:Array<Match3Piece>, board:Match3Board):Void {
        for (objective in objectives) {
            if (!objective.isCompleted) {
                var contribution = objective.checkContribution(pieces, board);
                if (contribution > 0) {
                    objective.updateProgress(contribution);
                }
            }
        }
        updateCompletionStatus();
    }

    /**
     * Process obstacle clearing
     */
    public function processObstacleClearing(count:Int):Void {
        for (objective in objectives) {
            if (!objective.isCompleted) {
                switch(objective.type) {
                    case CLEAR_OBSTACLES(_):
                        objective.updateProgress(count);
                    case _:
                }
            }
        }
        updateCompletionStatus();
    }

    /**
     * Process tile color changes
     */
    public function processTileColorChange(color:FlxColor, count:Int):Void {
        for (objective in objectives) {
            if (!objective.isCompleted) {
                switch(objective.type) {
                    case MAKE_COLORED_TILES(targetColor, _):
                        if (color == targetColor) {
                            objective.updateProgress(count);
                        }
                    case _:
                }
            }
        }
        updateCompletionStatus();
    }

    /**
     * Process turn completion (for VS mode)
     */
    public function processTurn():Void {
        for (objective in objectives) {
            if (!objective.isCompleted) {
                switch(objective.type) {
                    case SURVIVE_TURNS(_):
                        objective.updateProgress(1);
                    case _:
                }
            }
        }
        updateCompletionStatus();
    }

    /**
     * Process cascade matches
     */
    public function processCascade(cascadeCount:Int):Void {
        for (objective in objectives) {
            if (!objective.isCompleted) {
                switch(objective.type) {
                    case CASCADE_MATCHES(_):
                        objective.updateProgress(cascadeCount);
                    case _:
                }
            }
        }
        updateCompletionStatus();
    }

    /**
     * Update completion status
     */
    private function updateCompletionStatus():Void {
        allCompleted = true;
        for (objective in objectives) {
            if (!objective.isCompleted) {
                allCompleted = false;
                break;
            }
        }
    }

    /**
     * Get completion percentage (0-1)
     */
    public function getOverallProgress():Float {
        if (objectives.length == 0) return 1.0;

        var totalProgress = 0.0;
        for (objective in objectives) {
            totalProgress += objective.getProgress();
        }
        return totalProgress / objectives.length;
    }

    /**
     * Reset all objectives
     */
    public function reset():Void {
        for (objective in objectives) {
            objective.reset();
        }
        allCompleted = false;
    }

    /**
     * Get objectives by type
     */
    public function getObjectivesByType(type:Class<ObjectiveType>):Array<Match3Objective> {
        var result:Array<Match3Objective> = [];
        for (objective in objectives) {
            if (Std.isOfType(objective.type, type)) {
                result.push(objective);
            }
        }
        return result;
    }
}
