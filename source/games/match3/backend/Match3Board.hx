package games.match3.backend;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import games.match3.backend.Match3Piece.BasicPieceType;
import games.match3.backend.Match3Piece.SpecialType;

/**
 * The Match 3 game board that manages pieces and matches
 */
class Match3Board {
    public var width:Int;
    public var height:Int;
    public var grid:Array<Array<Match3Piece>>;
    public var isProcessing:Bool = false;
    public var availableIcons:Array<String> = [];
    public var useIcons:Bool = false;

    // Gravity and animation state
    public var fallingPieces:Array<{piece:Match3Piece, fromY:Int, toY:Int}> = [];
    public var matchedPieces:Array<Match3Piece> = [];

    public function new(width:Int = 8, height:Int = 8) {
        this.width = width;
        this.height = height;
        initializeGrid();
    }

    /**
     * Initialize empty grid
     */
    private function initializeGrid():Void {
        grid = [];
        for (x in 0...width) {
            grid[x] = [];
            for (y in 0...height) {
                grid[x][y] = null;
            }
        }
    }

    /**
     * Fill the board with random pieces
     */
    public function fillBoard(?iconList:Array<String>):Void {
        if (iconList != null && iconList.length > 0) {
            availableIcons = iconList;
            useIcons = true;
        }

        for (x in 0...width) {
            for (y in 0...height) {
                if (grid[x][y] == null) {
                    grid[x][y] = generateRandomPiece(x, y);
                }
            }
        }

        // Make sure there are no initial matches
        removeInitialMatches();
    }

    /**
     * Generate a random piece that won't create immediate matches
     */
    public function generateRandomPiece(x:Int, y:Int):Match3Piece {
        var attempts = 0;
        var piece:Match3Piece;

        do {
            piece = createRandomPiece(x, y);
            attempts++;
        } while (wouldCreateMatch(piece, x, y) && attempts < 50);

        return piece;
    }

    /**
     * Create a random piece
     */
    private function createRandomPiece(x:Int, y:Int):Match3Piece {
        if (useIcons && availableIcons.length > 0) {
            var iconName = availableIcons[Std.random(availableIcons.length)];
            return new Match3Piece(ICON(iconName), x, y);
        } else {
            var basicTypes = [BasicPieceType.RED, BasicPieceType.BLUE, BasicPieceType.GREEN, BasicPieceType.YELLOW, BasicPieceType.PURPLE, BasicPieceType.ORANGE];
            var randomType = basicTypes[Std.random(basicTypes.length)];
            return new Match3Piece(BASIC(randomType), x, y);
        }
    }

    /**
     * Check if placing a piece would create an immediate match
     */
    private function wouldCreateMatch(piece:Match3Piece, x:Int, y:Int):Bool {
        // Check horizontal matches
        var horizontalCount = 1;

        // Check left
        var checkX = x - 1;
        while (checkX >= 0 && grid[checkX][y] != null && grid[checkX][y].canMatchWith(piece)) {
            horizontalCount++;
            checkX--;
        }

        // Check right
        checkX = x + 1;
        while (checkX < width && grid[checkX][y] != null && grid[checkX][y].canMatchWith(piece)) {
            horizontalCount++;
            checkX++;
        }

        if (horizontalCount >= 3) return true;

        // Check vertical matches
        var verticalCount = 1;

        // Check up
        var checkY = y - 1;
        while (checkY >= 0 && grid[x][checkY] != null && grid[x][checkY].canMatchWith(piece)) {
            verticalCount++;
            checkY--;
        }

        // Check down
        checkY = y + 1;
        while (checkY < height && grid[x][checkY] != null && grid[x][checkY].canMatchWith(piece)) {
            verticalCount++;
            checkY++;
        }

        return verticalCount >= 3;
    }

    /**
     * Remove any initial matches that might exist
     */
    private function removeInitialMatches():Void {
        var foundMatches = true;
        var attempts = 0;

        while (foundMatches && attempts < 100) {
            foundMatches = false;
            attempts++;

            for (x in 0...width) {
                for (y in 0...height) {
                    if (grid[x][y] != null && wouldCreateMatch(grid[x][y], x, y)) {
                        grid[x][y] = generateRandomPiece(x, y);
                        foundMatches = true;
                    }
                }
            }
        }
    }

    /**
     * Check if two positions are adjacent
     */
    public function areAdjacent(x1:Int, y1:Int, x2:Int, y2:Int):Bool {
        var dx = Math.abs(x1 - x2);
        var dy = Math.abs(y1 - y2);
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
    }

    /**
     * Swap two pieces
     */
    public function swapPieces(x1:Int, y1:Int, x2:Int, y2:Int):Bool {
        if (!isValidPosition(x1, y1) || !isValidPosition(x2, y2)) {
            return false;
        }

        if (!areAdjacent(x1, y1, x2, y2)) {
            return false;
        }

        var piece1 = grid[x1][y1];
        var piece2 = grid[x2][y2];

        // Temporarily swap
        grid[x1][y1] = piece2;
        grid[x2][y2] = piece1;

        if (piece1 != null) {
            piece1.x = x2;
            piece1.y = y2;
        }
        if (piece2 != null) {
            piece2.x = x1;
            piece2.y = y1;
        }

        // Check if this creates any matches
        var createsMatches = hasMatches();

        if (!createsMatches) {
            // Swap back if no matches
            grid[x1][y1] = piece1;
            grid[x2][y2] = piece2;
            if (piece1 != null) {
                piece1.x = x1;
                piece1.y = y1;
            }
            if (piece2 != null) {
                piece2.x = x2;
                piece2.y = y2;
            }
            return false;
        }

        return true;
    }

    /**
     * Check if position is valid
     */
    public function isValidPosition(x:Int, y:Int):Bool {
        return x >= 0 && x < width && y >= 0 && y < height;
    }

    /**
     * Get piece at position
     */
    public function getPiece(x:Int, y:Int):Match3Piece {
        if (!isValidPosition(x, y)) {
            return null;
        }
        return grid[x][y];
    }

    /**
     * Set piece at position
     */
    public function setPiece(x:Int, y:Int, piece:Match3Piece):Void {
        if (!isValidPosition(x, y)) {
            return;
        }
        grid[x][y] = piece;
        if (piece != null) {
            piece.x = x;
            piece.y = y;
        }
    }

    /**
     * Check if board has any matches
     */
    public function hasMatches():Bool {
        return findAllMatches().length > 0;
    }

    /**
     * Synchronize all piece coordinates with their grid positions
     */
    public function synchronizeCoordinates():Void {
        for (x in 0...width) {
            for (y in 0...height) {
                var piece = grid[x][y];
                if (piece != null) {
                    piece.x = x;
                    piece.y = y;
                }
            }
        }
    }

    /**
     * Find all current matches on the board using precise grid coordinate checking
     */
    public function findAllMatches():Array<Array<Match3Piece>> {
        var matches:Array<Array<Match3Piece>> = [];
        var processedPositions:Array<Array<Bool>> = [];

        // Initialize processed positions tracking
        for (x in 0...width) {
            processedPositions[x] = [];
            for (y in 0...height) {
                processedPositions[x][y] = false;
            }
        }

        // Find horizontal matches
        for (y in 0...height) {
            var x = 0;
            while (x < width) {
                var piece = grid[x][y];

                if (piece == null || piece.type == OBSTACLE || processedPositions[x][y]) {
                    x++;
                    continue;
                }

                // Start a potential match
                var match:Array<Match3Piece> = [piece];
                var matchX = x + 1;

                // Extend the match as far as possible
                while (matchX < width) {
                    var nextPiece = grid[matchX][y];
                    if (nextPiece == null || nextPiece.type == OBSTACLE || !piece.canMatchWith(nextPiece)) {
                        break;
                    }
                    match.push(nextPiece);
                    matchX++;
                }

                // If we have a valid match (3 or more pieces)
                if (match.length >= 3) {
                    matches.push(match);
                    // Mark all positions in this match as processed
                    for (i in 0...match.length) {
                        processedPositions[x + i][y] = true;
                    }
                }

                x = matchX; // Skip to the next unprocessed position
            }
        }

        // Reset processed positions for vertical matches
        for (x in 0...width) {
            for (y in 0...height) {
                processedPositions[x][y] = false;
            }
        }

        // Find vertical matches
        for (x in 0...width) {
            var y = 0;
            while (y < height) {
                var piece = grid[x][y];

                if (piece == null || piece.type == OBSTACLE || processedPositions[x][y]) {
                    y++;
                    continue;
                }

                // Start a potential match
                var match:Array<Match3Piece> = [piece];
                var matchY = y + 1;

                // Extend the match as far as possible
                while (matchY < height) {
                    var nextPiece = grid[x][matchY];
                    if (nextPiece == null || nextPiece.type == OBSTACLE || !piece.canMatchWith(nextPiece)) {
                        break;
                    }
                    match.push(nextPiece);
                    matchY++;
                }

                // If we have a valid match (3 or more pieces)
                if (match.length >= 3) {
                    matches.push(match);
                    // Mark all positions in this match as processed
                    for (i in 0...match.length) {
                        processedPositions[x][y + i] = true;
                    }
                }

                y = matchY; // Skip to the next unprocessed position
            }
        }

        return matches;
    }

    /**
     * Process all matches and create power-ups
     */
    public function processMatches():Array<Match3Piece> {
        var allMatches = findAllMatches();
        var removedPieces:Array<Match3Piece> = [];
        var powerUpsToCreate:Array<{x:Int, y:Int, type:SpecialType}> = [];

        for (match in allMatches) {
            // Determine if special power-up should be created
            var specialType = determineSpecialType(match);

            if (specialType != NONE && match.length > 0) {
                // Create power-up at the position of the first piece in the match
                var firstPiece = match[0];
                powerUpsToCreate.push({x: firstPiece.x, y: firstPiece.y, type: specialType});
            }

            // Mark pieces for removal
            for (piece in match) {
                piece.isMatched = true;
                removedPieces.push(piece);
                grid[piece.x][piece.y] = null;
            }
        }

        // Create power-ups
        for (powerUpData in powerUpsToCreate) {
            var newPowerUp = createRandomPiece(powerUpData.x, powerUpData.y);
            var powerUp = newPowerUp.createPowerUp(powerUpData.type);
            setPiece(powerUpData.x, powerUpData.y, powerUp);
        }

        return removedPieces;
    }

    /**
     * Determine what type of special power-up to create based on match
     */
    private function determineSpecialType(match:Array<Match3Piece>):SpecialType {
        if (match.length == 4) {
            // Determine if it's horizontal or vertical
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
     * Apply gravity to make pieces fall
     */
    public function applyGravity():Bool {
        var piecesMoving = false;
        fallingPieces = [];

        for (x in 0...width) {
            var writeY = height - 1;

            for (readY in (0...height)) {
                var actualReadY = height - 1 - readY;
                var piece = grid[x][actualReadY];

                if (piece != null && piece.type != OBSTACLE) {
                    if (actualReadY != writeY) {
                        // Piece needs to fall
                        fallingPieces.push({piece: piece, fromY: actualReadY, toY: writeY});
                        grid[x][actualReadY] = null;
                        grid[x][writeY] = piece;
                        piece.y = writeY;
                        piecesMoving = true;
                    }
                    writeY--;
                }
            }

            // Fill empty spaces at the top
            for (y in 0...writeY + 1) {
                if (grid[x][y] == null) {
                    grid[x][y] = generateRandomPiece(x, y);
                    fallingPieces.push({piece: grid[x][y], fromY: -1, toY: y});
                    piecesMoving = true;
                }
            }
        }

        return piecesMoving;
    }

    /**
     * Check if there are any possible moves
     */
    public function hasPossibleMoves():Bool {
        for (x in 0...width) {
            for (y in 0...height) {
                // Try swapping with adjacent pieces
                var directions = [
                    {dx: 1, dy: 0},
                    {dx: 0, dy: 1},
                    {dx: -1, dy: 0},
                    {dx: 0, dy: -1}
                ];

                for (dir in directions) {
                    var newX = x + dir.dx;
                    var newY = y + dir.dy;

                    if (isValidPosition(newX, newY)) {
                        // Temporarily swap and check for matches
                        var piece1 = grid[x][y];
                        var piece2 = grid[newX][newY];

                        grid[x][y] = piece2;
                        grid[newX][newY] = piece1;

                        var hasMatches = this.hasMatches();

                        // Swap back
                        grid[x][y] = piece1;
                        grid[newX][newY] = piece2;

                        if (hasMatches) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }

    /**
     * Activate a power-up at the given position
     */
    public function activatePowerUp(x:Int, y:Int):Array<Match3Piece> {
        var piece = getPiece(x, y);
        if (piece == null || !piece.isSpecial) {
            return [];
        }

        var affectedPieces:Array<Match3Piece> = [];

        switch(piece.specialType) {
            case HORIZONTAL_STRIPE:
                // Clear entire row
                for (clearX in 0...width) {
                    var targetPiece = getPiece(clearX, y);
                    if (targetPiece != null) {
                        affectedPieces.push(targetPiece);
                        grid[clearX][y] = null;
                    }
                }

            case VERTICAL_STRIPE:
                // Clear entire column
                for (clearY in 0...height) {
                    var targetPiece = getPiece(x, clearY);
                    if (targetPiece != null) {
                        affectedPieces.push(targetPiece);
                        grid[x][clearY] = null;
                    }
                }

            case BOMB:
                // Clear 3x3 area
                for (clearX in (x-1)...(x+2)) {
                    for (clearY in (y-1)...(y+2)) {
                        if (isValidPosition(clearX, clearY)) {
                            var targetPiece = getPiece(clearX, clearY);
                            if (targetPiece != null) {
                                affectedPieces.push(targetPiece);
                                grid[clearX][clearY] = null;
                            }
                        }
                    }
                }

            case COLOR_BOMB:
                // Clear all pieces of the same color
                var targetColor = piece.color;
                for (clearX in 0...width) {
                    for (clearY in 0...height) {
                        var targetPiece = getPiece(clearX, clearY);
                        if (targetPiece != null && targetPiece.canMatchWith(piece)) {
                            affectedPieces.push(targetPiece);
                            grid[clearX][clearY] = null;
                        }
                    }
                }

            case _:
        }

        return affectedPieces;
    }
}
