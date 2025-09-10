package games.match3;

import backend.MusicBeatState;
import backend.ui.PsychUIButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.match3.backend.*;
import games.match3.backend.Match3Game.GameMode;
import games.match3.backend.Match3Piece.BasicPieceType;
import games.match3.backend.Match3Piece.SpecialType;
import openfl.geom.Rectangle;
import states.MainMenuState;

/**
 * Match 3 Test State - Complete Match 3 game implementation
 */
class Match3TestState extends MusicBeatState {
    // Game components
    private var match3Game:Match3Game;
    private var isGameStarted:Bool = false;

    // VS CPU mode components
    private var cpuBoard:Match3Board;
    private var cpuGame:Match3Game;
    private var cpuGrid:Array<Array<Match3Piece>>;
    private var cpuGridBackground:FlxSprite;
    private var cpuBoardStartX:Int = 600;
    private var cpuBoardStartY:Int = 100;
    private var isPlayerTurn:Bool = true;
    private var cpuThinkTimer:Float = 0;
    private var cpuMoveDelay:Float = 1.5; // Time CPU takes to "think"

    // UI Elements
    private var bgSprite:FlxSprite;
    private var gameStatusText:FlxText;
    private var scoreText:FlxText;
    private var movesText:FlxText;
    private var objectivesText:FlxText;
    private var gridGroup:FlxTypedGroup<FlxSprite>;
    private var pieceSprites:Array<Array<FlxSprite>>;
    private var selectionSprite:FlxSprite;

    // CPU UI Elements (for VS mode)
    private var cpuGridGroup:FlxTypedGroup<FlxSprite>;
    private var cpuPieceSprites:Array<Array<FlxSprite>>;
    private var cpuScoreText:FlxText;
    private var cpuLabel:FlxText;
    private var turnIndicatorText:FlxText;

    // UI Buttons
    private var startButton:PsychUIButton;
    private var resetButton:PsychUIButton;
    private var backButton:PsychUIButton;
    private var modeButton:PsychUIButton;

    // Game settings
    private var currentGameMode:GameMode = CLASSIC;
    private var gridSize:Int = 8;
    private var tileSize:Int = 64;
    private var gridOffsetX:Int = 50;
    private var gridOffsetY:Int = 100;

    // CPU grid positioning (for VS mode) - moved further right to avoid overlap
    private var cpuGridOffsetX:Int = 700;
    private var cpuGridOffsetY:Int = 100;

    // Animation state
    private var animatingPieces:Array<FlxSprite> = [];
    private var isAnimating:Bool = false;
    private var pendingAnimations:Int = 0;
    private var animationQueue:Array<Void->Void> = [];
    private var cascadeQueue:Array<Void->Void> = [];
    private var isProcessingCascades:Bool = false;

    // Color validation
    private var colorValidationTimer:Float = 0;
    private var colorValidationInterval:Float = 5.0; // Check every 5 seconds

    override public function create():Void {
        super.create();

        // Enable mouse cursor for Match 3 gameplay
        FlxG.mouse.visible = true;

        createBackground();
        createUI();
        createGrid();
        setupGame();
    }

    private function createBackground():Void {
        bgSprite = new FlxSprite();
        bgSprite.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(25, 25, 40));
        add(bgSprite);
    }

    private function createUI():Void {
        // Title
        var titleText = new FlxText(0, 10, FlxG.width, "Match 3 Game");
        titleText.setFormat(null, 32, FlxColor.WHITE, CENTER);
        add(titleText);

        // Game status
        gameStatusText = new FlxText(10, 50, FlxG.width - 20, "Press Start to begin!");
        gameStatusText.setFormat(null, 16, FlxColor.WHITE, CENTER);
        add(gameStatusText);

        // Score display - positioned above player board
        scoreText = new FlxText(gridOffsetX, gridOffsetY - 30, gridSize * tileSize, "Score: 0");
        scoreText.setFormat(null, 18, FlxColor.WHITE, CENTER);
        add(scoreText);

        // Player board label
        var playerLabel = new FlxText(gridOffsetX, gridOffsetY - 50, gridSize * tileSize, "PLAYER");
        playerLabel.setFormat(null, 16, FlxColor.CYAN, CENTER);
        add(playerLabel);

        // CPU Score display (for VS mode) - positioned above CPU board
        cpuScoreText = new FlxText(cpuGridOffsetX, cpuGridOffsetY - 30, gridSize * tileSize, "CPU Score: 0");
        cpuScoreText.setFormat(null, 18, FlxColor.WHITE, CENTER);
        cpuScoreText.visible = false;
        add(cpuScoreText);

        // CPU board label
        cpuLabel = new FlxText(cpuGridOffsetX, cpuGridOffsetY - 50, gridSize * tileSize, "CPU");
        cpuLabel.setFormat(null, 16, FlxColor.RED, CENTER);
        cpuLabel.visible = false;
        add(cpuLabel);

        // Turn indicator (for VS mode) - positioned between the two boards
        turnIndicatorText = new FlxText(300, gridOffsetY - 60, 400, "");
        turnIndicatorText.setFormat(null, 20, FlxColor.YELLOW, CENTER);
        turnIndicatorText.visible = false;
        add(turnIndicatorText);

        // Moves remaining - positioned to the right of player board
        movesText = new FlxText(gridOffsetX + (gridSize * tileSize) + 20, gridOffsetY, 200, "Moves: Unlimited");
        movesText.setFormat(null, 16, FlxColor.WHITE);
        add(movesText);

        // Objectives - positioned below moves text
        objectivesText = new FlxText(gridOffsetX + (gridSize * tileSize) + 20, gridOffsetY + 30, 200, "Objectives:");
        objectivesText.setFormat(null, 14, FlxColor.YELLOW);
        add(objectivesText);

        // Buttons
        var buttonY = FlxG.height - 100;

        startButton = new PsychUIButton(50, buttonY, "Start Game", startGame);
        startButton.resize(120, 30);
        add(startButton);

        resetButton = new PsychUIButton(180, buttonY, "Reset", resetGame);
        resetButton.resize(80, 30);
        add(resetButton);

        modeButton = new PsychUIButton(270, buttonY, "Mode: Classic", cycleGameMode);
        modeButton.resize(140, 30);
        add(modeButton);

        backButton = new PsychUIButton(420, buttonY, "Back to Menu", backToMenu);
        backButton.resize(120, 30);
        add(backButton);
    }

    private function createGrid():Void {
        // Player grid
        gridGroup = new FlxTypedGroup<FlxSprite>();
        add(gridGroup);

        pieceSprites = [];
        for (x in 0...gridSize) {
            pieceSprites[x] = [];
            for (y in 0...gridSize) {
                pieceSprites[x][y] = null;
            }
        }

        // CPU grid (for VS mode)
        cpuGridGroup = new FlxTypedGroup<FlxSprite>();
        cpuGridGroup.visible = false;
        add(cpuGridGroup);

        cpuPieceSprites = [];
        for (x in 0...gridSize) {
            cpuPieceSprites[x] = [];
            for (y in 0...gridSize) {
                cpuPieceSprites[x][y] = null;
            }
        }

        // Create selection indicator
        selectionSprite = new FlxSprite();
        selectionSprite.makeGraphic(tileSize, tileSize, FlxColor.TRANSPARENT);
        // Draw border manually by creating a border graphic
        var borderThickness = 3;
        selectionSprite.makeGraphic(tileSize, tileSize, FlxColor.TRANSPARENT);
        // Create border effect by drawing colored lines
        selectionSprite.pixels.fillRect(new Rectangle(0, 0, tileSize, borderThickness), FlxColor.YELLOW);
        selectionSprite.pixels.fillRect(new Rectangle(0, tileSize - borderThickness, tileSize, borderThickness), FlxColor.YELLOW);
        selectionSprite.pixels.fillRect(new Rectangle(0, 0, borderThickness, tileSize), FlxColor.YELLOW);
        selectionSprite.pixels.fillRect(new Rectangle(tileSize - borderThickness, 0, borderThickness, tileSize), FlxColor.YELLOW);
        selectionSprite.visible = false;
        add(selectionSprite);
    }

    private function setupGame():Void {
        match3Game = new Match3Game(currentGameMode);

        // Set up callbacks
        match3Game.onScoreChanged = onScoreChanged;
        match3Game.onGameOver = onGameOver;
        match3Game.onPieceMatched = onPieceMatched;
        match3Game.onCascade = onCascade;
        match3Game.onSpecialActivated = onSpecialActivated;

        // Setup CPU game for VS mode
        if (currentGameMode == VS_CPU) {
            cpuGame = new Match3Game(CLASSIC); // CPU plays in classic mode
            cpuBoard = cpuGame.board;

            // Initialize CPU grid
            cpuGrid = [];
            for (x in 0...gridSize) {
                cpuGrid[x] = [];
                for (y in 0...gridSize) {
                    cpuGrid[x][y] = cpuGame.board.getPiece(x, y);
                }
            }

            // Create CPU grid background
            cpuGridBackground = new FlxSprite(cpuGridOffsetX - 5, cpuGridOffsetY - 5);
            cpuGridBackground.makeGraphic((gridSize * tileSize) + 10, (gridSize * tileSize) + 10, 0xFF222222);
            add(cpuGridBackground);

            // Add CPU grid background before CPU pieces so pieces appear on top
            remove(cpuGridGroup);
            add(cpuGridGroup);

            // Set up CPU callbacks
            cpuGame.onScoreChanged = function(player:Int, newScore:Int) {
                onCPUScoreChanged(player, newScore);
            };
            cpuGame.onPieceMatched = function(pieces:Array<Match3Piece>) {
                onCPUPieceMatched(pieces);
            };

            // Show CPU UI elements
            cpuScoreText.visible = true;
            cpuLabel.visible = true;
            turnIndicatorText.visible = true;
            cpuGridGroup.visible = true;
            cpuGridBackground.visible = true;

            // Initialize turn state
            isPlayerTurn = true;
            updateTurnDisplay();
        } else {
            // Hide CPU UI elements for other modes
            cpuScoreText.visible = false;
            cpuLabel.visible = false;
            turnIndicatorText.visible = false;
            cpuGridGroup.visible = false;
            if (cpuGridBackground != null) {
                cpuGridBackground.visible = false;
            }
        }
    }

    private function startGame():Void {
        if (isGameStarted) return;

        var objectives = getObjectivesForMode(currentGameMode);
        var moves = (currentGameMode == MOVES_LIMITED) ? 20 : -1;
        var timeLimit = (currentGameMode == TIMED) ? 120.0 : -1;

        match3Game.initialize(objectives, getIconList(), moves, timeLimit);

        // Initialize CPU game for VS mode
        if (currentGameMode == VS_CPU) {
            var cpuObjectives = getObjectivesForMode(CLASSIC);
            cpuGame.initialize(cpuObjectives, getIconList(), -1, -1);
            updateCPUGameDisplay();
            updateCPUBoardVisuals();
            isPlayerTurn = true;
            cpuThinkTimer = 0;
            updateTurnDisplay();
        }

        isGameStarted = true;
        updateGameDisplay();
        updateUI();

        // Validate colors after initial board creation
        // validateAllPieceColors();

        // Check if the initial board has possible moves, shuffle if not
        if (!hasPossibleMoves()) {
            shuffleBoard();
        } else {
            if (currentGameMode == VS_CPU) {
                gameStatusText.text = "VS CPU Mode! Your turn - Click pieces to match them.";
            } else {
                gameStatusText.text = "Game Started! Click pieces to match them.";
            }
        }
    }

    private function resetGame():Void {
        isGameStarted = false;
        match3Game.reset();
        clearGrid();
        updateUI();
        gameStatusText.text = "Press Start to begin!";
    }

    private function cycleGameMode():Void {
        if (isGameStarted) return;

        currentGameMode = switch(currentGameMode) {
            case CLASSIC: TIMED;
            case TIMED: MOVES_LIMITED;
            case MOVES_LIMITED: VS_CPU;
            case VS_CPU: OBSTACLES;
            case OBSTACLES: CLASSIC;
        }

        modeButton.label = "Mode: " + getModeDisplayName(currentGameMode);
        setupGame();
    }

    private function getModeDisplayName(mode:GameMode):String {
        return switch(mode) {
            case CLASSIC: "Classic";
            case TIMED: "Timed";
            case MOVES_LIMITED: "Limited Moves";
            case VS_CPU: "VS CPU";
            case OBSTACLES: "Obstacles";
        }
    }

    private function getObjectivesForMode(mode:GameMode):Array<Match3Objective> {
        return switch(mode) {
            case CLASSIC: Match3Game.createClassicObjectives();
            case OBSTACLES: Match3Game.createObstacleObjectives();
            case VS_CPU: Match3Game.createVSObjectives();
            case _: Match3Game.createClassicObjectives();
        }
    }

    private function getIconList():Array<String> {
        // Use character icons sometimes
        // if (Math.random() < 0.3) {
        //     return Match3Game.getAvailableIcons();
        // }
        return null; // Use basic colored pieces
    }

    private function backToMenu():Void {
        FlxG.switchState(new MainMenuState());
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (isGameStarted && match3Game != null) {
            match3Game.update(elapsed);
            updateUI();

            // Periodic color validation to catch any corruption
            colorValidationTimer += elapsed;
            if (colorValidationTimer >= colorValidationInterval) {
                // validateAllPieceColors();
                colorValidationTimer = 0;
            }

            // Handle CPU turn in VS mode
            if (currentGameMode == VS_CPU && cpuGame != null) {
                handleCPUTurn(elapsed);
            }
        }

        handleInput();
    }

    private function handleCPUTurn(elapsed:Float):Void {
        if (!isPlayerTurn && !isAnimating && !isProcessingCascades) {
            cpuThinkTimer += elapsed;

            if (cpuThinkTimer >= cpuMoveDelay) {
                // CPU makes a move
                makeCPUMove();
                cpuThinkTimer = 0;

                // Switch back to player turn after CPU move completes
                new FlxTimer().start(1.0, function(timer:FlxTimer) {
                    if (!isProcessingCascades) {
                        switchToPlayerTurn();
                    }
                });
            }
        }
    }

    private function makeCPUMove():Void {
        // Find possible moves for CPU
        var possibleMoves = findPossibleMovesForBoard(cpuGame.board);

        if (possibleMoves.length > 0) {
            // Pick a random move (simple AI)
            var move = possibleMoves[Std.random(possibleMoves.length)];

            // Highlight the pieces being moved
            var sprite1 = cpuPieceSprites[move.x1][move.y1];
            var sprite2 = cpuPieceSprites[move.x2][move.y2];

            if (sprite1 != null && sprite2 != null) {
                // Flash the pieces to show the move
                FlxTween.tween(sprite1, {alpha: 0.5}, 0.2, {type: FlxTweenType.PINGPONG});
                FlxTween.tween(sprite2, {alpha: 0.5}, 0.2, {type: FlxTweenType.PINGPONG});

                // After highlighting, perform the swap
                new FlxTimer().start(0.6, function(timer:FlxTimer) {
                    sprite1.alpha = 1.0;
                    sprite2.alpha = 1.0;
                    simulateSwapOnCPUBoard(move.x1, move.y1, move.x2, move.y2);
                });
            } else {
                // No animation, just do the swap
                simulateSwapOnCPUBoard(move.x1, move.y1, move.x2, move.y2);
            }

            gameStatusText.text = "CPU is making a move...";
        } else {
            // CPU has no moves, shuffle their board
            shuffleCPUBoard();
        }
    }

    private function findPossibleMovesForBoard(board:Match3Board):Array<{x1:Int, y1:Int, x2:Int, y2:Int}> {
        var moves:Array<{x1:Int, y1:Int, x2:Int, y2:Int}> = [];

        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = board.getPiece(x, y);
                if (piece == null || piece.type == OBSTACLE) continue;

                // Check adjacent positions
                var directions = [
                    {dx: 1, dy: 0}, {dx: 0, dy: 1},
                    {dx: -1, dy: 0}, {dx: 0, dy: -1}
                ];

                for (dir in directions) {
                    var newX = x + dir.dx;
                    var newY = y + dir.dy;

                    if (board.isValidPosition(newX, newY)) {
                        var adjacentPiece = board.getPiece(newX, newY);
                        if (adjacentPiece == null || adjacentPiece.type == OBSTACLE) continue;

                        // Test the swap
                        board.setPiece(x, y, adjacentPiece);
                        board.setPiece(newX, newY, piece);
                        board.synchronizeCoordinates();

                        var matches = board.findAllMatches();

                        // Swap back
                        board.setPiece(x, y, piece);
                        board.setPiece(newX, newY, adjacentPiece);
                        board.synchronizeCoordinates();

                        if (matches.length > 0) {
                            moves.push({x1: x, y1: y, x2: newX, y2: newY});
                        }
                    }
                }
            }
        }

        return moves;
    }

    private function simulateSwapOnCPUBoard(x1:Int, y1:Int, x2:Int, y2:Int):Void {
        // Perform swap on CPU board
        var piece1 = cpuGame.board.getPiece(x1, y1);
        var piece2 = cpuGame.board.getPiece(x2, y2);

        cpuGame.board.setPiece(x1, y1, piece2);
        cpuGame.board.setPiece(x2, y2, piece1);

        // Update CPU board sprites with animation
        var sprite1 = cpuPieceSprites[x1][y1];
        var sprite2 = cpuPieceSprites[x2][y2];

        if (sprite1 != null && sprite2 != null) {
            // Animate the swap visually
            var targetX1 = cpuGridOffsetX + x2 * tileSize;
            var targetY1 = cpuGridOffsetY + y2 * tileSize;
            var targetX2 = cpuGridOffsetX + x1 * tileSize;
            var targetY2 = cpuGridOffsetY + y1 * tileSize;

            // Animate both pieces
            FlxTween.tween(sprite1, {x: targetX1, y: targetY1}, 0.3, {ease: FlxEase.quadInOut});
            FlxTween.tween(sprite2, {x: targetX2, y: targetY2}, 0.3, {ease: FlxEase.quadInOut});

            // Update sprite array references
            cpuPieceSprites[x1][y1] = sprite2;
            cpuPieceSprites[x2][y2] = sprite1;
        }

        cpuGame.board.synchronizeCoordinates();

        // Process matches and start cascade after a brief delay
        new FlxTimer().start(0.4, function(timer:FlxTimer) {
            processCPUCascades();
        });
    }

    private function processCPUCascades():Void {
        var matches = cpuGame.board.findAllMatches();

        if (matches.length > 0) {
            // Update CPU score
            var totalMatched = 0;
            for (match in matches) {
                totalMatched += match.length;
                cpuGame.addToScore(match.length * 10);
            }

            // Remove matched pieces and update CPU display
            removeCPUMatchedPieces(matches);
            applyCPUGravity();
            fillCPUEmptySpaces();
            updateCPUGameDisplay();

            // Check for more matches
            new FlxTimer().start(0.3, function(timer:FlxTimer) {
                processCPUCascades();
            });
        } else {
            // CPU turn is complete, switch back to player
            new FlxTimer().start(0.5, function(timer:FlxTimer) {
                switchToPlayerTurn();
            });
        }
    }

    private function removeCPUMatchedPieces(matches:Array<Array<Match3Piece>>):Void {
        for (match in matches) {
            for (piece in match) {
                var sprite = cpuPieceSprites[piece.x][piece.y];
                if (sprite != null) {
                    sprite.kill();
                    cpuGridGroup.remove(sprite);
                    cpuPieceSprites[piece.x][piece.y] = null;
                }
                cpuGame.board.setPiece(piece.x, piece.y, null);
            }
        }
    }

    private function switchToPlayerTurn():Void {
        isPlayerTurn = true;
        updateTurnDisplay();
        gameStatusText.text = "Your turn! Make a match.";
    }

    private function updateTurnIndicator():Void {
        if (currentGameMode == VS_CPU && turnIndicatorText != null) {
            turnIndicatorText.text = isPlayerTurn ? "YOUR TURN" : "CPU TURN";
            turnIndicatorText.color = isPlayerTurn ? 0x00FF00 : 0xFF0000;
        }
    }

    private function switchToCPUTurn():Void {
        isPlayerTurn = false;
        cpuThinkTimer = 0;
        updateTurnDisplay();
        gameStatusText.text = "CPU is thinking...";
    }

    private function updateTurnDisplay():Void {
        if (currentGameMode == VS_CPU) {
            turnIndicatorText.text = isPlayerTurn ? "Your Turn" : "CPU Turn";
            turnIndicatorText.color = isPlayerTurn ? FlxColor.GREEN : FlxColor.RED;
        }
    }

    private function handleInput():Void {
        if (!isGameStarted || isAnimating || isProcessingCascades) return;

        // In VS CPU mode, only allow input during player turn
        if (currentGameMode == VS_CPU && !isPlayerTurn) return;

        if (FlxG.mouse.justPressed) {
            var mouseX = FlxG.mouse.x;
            var mouseY = FlxG.mouse.y;

            // Check if click is within grid
            if (mouseX >= gridOffsetX && mouseX < gridOffsetX + (gridSize * tileSize) &&
                mouseY >= gridOffsetY && mouseY < gridOffsetY + (gridSize * tileSize)) {

                var gridX = Math.floor((mouseX - gridOffsetX) / tileSize);
                var gridY = Math.floor((mouseY - gridOffsetY) / tileSize);

                if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
                    handlePieceClick(gridX, gridY);
                }
            }
        }
    }

    private function handlePieceClick(gridX:Int, gridY:Int):Void {
        var piece = match3Game.board.getPiece(gridX, gridY);
        if (piece == null) return;

        if (match3Game.selectedPiece == null) {
            // First piece selection
            match3Game.selectedPiece = new FlxPoint(gridX, gridY);
            updateSelectionDisplay();
        } else {
            // Second piece selection - attempt swap
            var selectedX = Std.int(match3Game.selectedPiece.x);
            var selectedY = Std.int(match3Game.selectedPiece.y);

            // Check if pieces are adjacent
            var dx = Math.abs(selectedX - gridX);
            var dy = Math.abs(selectedY - gridY);

            if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1)) {
                // Valid adjacent pieces - animate the swap
                animateSwap(selectedX, selectedY, gridX, gridY);
            } else {
                // Not adjacent, select new piece
                match3Game.selectedPiece = new FlxPoint(gridX, gridY);
                updateSelectionDisplay();
            }
        }
    }

    private function animateSwap(x1:Int, y1:Int, x2:Int, y2:Int):Void {
        isAnimating = true;
        pendingAnimations = 2;

        var sprite1 = pieceSprites[x1][y1];
        var sprite2 = pieceSprites[x2][y2];

        if (sprite1 == null || sprite2 == null) {
            completeSwap(x1, y1, x2, y2);
            return;
        }

        var targetX1 = gridOffsetX + (x2 * tileSize);
        var targetY1 = gridOffsetY + (y2 * tileSize);
        var targetX2 = gridOffsetX + (x1 * tileSize);
        var targetY2 = gridOffsetY + (y1 * tileSize);

        // Animate both pieces simultaneously
        FlxTween.tween(sprite1, {x: targetX1, y: targetY1}, 0.3, {
            ease: FlxEase.quadInOut,
            onComplete: function(tween:FlxTween) {
                pendingAnimations--;
                if (pendingAnimations <= 0) {
                    completeSwap(x1, y1, x2, y2);
                }
            }
        });

        FlxTween.tween(sprite2, {x: targetX2, y: targetY2}, 0.3, {
            ease: FlxEase.quadInOut,
            onComplete: function(tween:FlxTween) {
                pendingAnimations--;
                if (pendingAnimations <= 0) {
                    completeSwap(x1, y1, x2, y2);
                }
            }
        });
    }

    private function completeSwap(x1:Int, y1:Int, x2:Int, y2:Int):Void {
        // Check for matches BEFORE making the swap permanent
        var piece1 = match3Game.board.getPiece(x1, y1);
        var piece2 = match3Game.board.getPiece(x2, y2);

        // Temporarily swap pieces to check for matches
        match3Game.board.setPiece(x1, y1, piece2);
        match3Game.board.setPiece(x2, y2, piece1);

        // Temporarily swap sprite references to match piece coordinates
        var tempSprite = pieceSprites[x1][y1];
        pieceSprites[x1][y1] = pieceSprites[x2][y2];
        pieceSprites[x2][y2] = tempSprite;

        // Ensure coordinates are synchronized
        match3Game.board.synchronizeCoordinates();

        // Check for matches
        var matches = match3Game.board.findAllMatches();

        if (matches.length > 0) {
            // Valid move - sprites and pieces are already properly swapped

            // Clear selection
            match3Game.selectedPiece = null;
            updateSelectionDisplay();

            // Validate colors after successful swap
            // validateAllPieceColors();

            startCascadeSequence();
        } else {
            // Invalid move - swap everything back
            match3Game.board.setPiece(x1, y1, piece1);
            match3Game.board.setPiece(x2, y2, piece2);

            // Swap sprites back too
            var tempSprite = pieceSprites[x1][y1];
            pieceSprites[x1][y1] = pieceSprites[x2][y2];
            pieceSprites[x2][y2] = tempSprite;

            // Ensure coordinates are synchronized
            match3Game.board.synchronizeCoordinates();

            // Clear selection
            match3Game.selectedPiece = null;
            updateSelectionDisplay();

            // Show feedback for invalid move
            gameStatusText.text = "Invalid move! Try again.";

            // Animate sprites back to original positions
            animateSwapBack(x1, y1, x2, y2);
        }
    }

    private function animateSwapBack(x1:Int, y1:Int, x2:Int, y2:Int):Void {
        pendingAnimations = 2;

        var sprite1 = pieceSprites[x1][y1];
        var sprite2 = pieceSprites[x2][y2];

        if (sprite1 == null || sprite2 == null) {
            isAnimating = false;
            return;
        }

        // Calculate original positions for each sprite
        var originalX1 = gridOffsetX + (x1 * tileSize);
        var originalY1 = gridOffsetY + (y1 * tileSize);
        var originalX2 = gridOffsetX + (x2 * tileSize);
        var originalY2 = gridOffsetY + (y2 * tileSize);

        // Animate sprites back to their original positions
        FlxTween.tween(sprite1, {x: originalX1, y: originalY1}, 0.3, {
            ease: FlxEase.quadInOut,
            onComplete: function(tween:FlxTween) {
                pendingAnimations--;
                if (pendingAnimations <= 0) {
                    isAnimating = false;
                }
            }
        });

        FlxTween.tween(sprite2, {x: originalX2, y: originalY2}, 0.3, {
            ease: FlxEase.quadInOut,
            onComplete: function(tween:FlxTween) {
                pendingAnimations--;
                if (pendingAnimations <= 0) {
                    isAnimating = false;
                }
            }
        });
    }

    private function startCascadeSequence():Void {
        isProcessingCascades = true;
        processCascadeStep();
    }

    private function processCascadeStep():Void {
        // Ensure all coordinates are synchronized before checking matches
        match3Game.board.synchronizeCoordinates();

        var matches = match3Game.board.findAllMatches();

        if (matches.length == 0) {
            // No more matches, end cascade sequence
            isProcessingCascades = false;
            isAnimating = false;
            match3Game.cascadeMultiplier = 1; // Reset cascade multiplier

            // Validate all piece colors after cascade completion
            // validateAllPieceColors();

            // In VS CPU mode, switch turns after player's cascade ends
            if (currentGameMode == VS_CPU && isPlayerTurn) {
                new FlxTimer().start(0.5, function(timer:FlxTimer) {
                    switchToCPUTurn();
                });
                return;
            }

            // Check if there are any possible moves left
            if (!hasPossibleMoves()) {
                shuffleBoard();
            }
            return;
        }

        // Process matches and update score
        var totalMatched = 0;
        for (match in matches) {
            totalMatched += match.length;
            match3Game.addToScore(match.length * 10 * match3Game.cascadeMultiplier);
        }

        match3Game.cascadeMultiplier++;
        onPieceMatched(flattenMatches(matches));

        // Animate piece removal
        animateMatchedPieces(matches, function() {
            // After pieces are removed, animate falling
            animateFallingPieces(function() {
                // After falling, create new pieces
                animateNewPieces(function() {
                    // After new pieces, check for more matches with reduced delay
                    new FlxTimer().start(0.1, function(timer:FlxTimer) {
                        processCascadeStep();
                    });
                });
            });
        });
    }

    private function animateMatchedPieces(matches:Array<Array<Match3Piece>>, onComplete:Void->Void):Void {
        var allMatchedPieces:Array<Match3Piece> = [];
        for (match in matches) {
            for (piece in match) {
                allMatchedPieces.push(piece);
            }
        }

        pendingAnimations = allMatchedPieces.length;

        if (pendingAnimations == 0) {
            onComplete();
            return;
        }

        for (piece in allMatchedPieces) {
            // Find sprite by piece coordinates
            var sprite = pieceSprites[piece.x][piece.y];
            if (sprite != null) {
                // Scale and fade animation for matched pieces with reduced timing
                FlxTween.tween(sprite.scale, {x: 1.3, y: 1.3}, 0.15, {ease: FlxEase.quadOut});
                FlxTween.tween(sprite, {alpha: 0}, 0.25, {
                    ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween) {
                        sprite.kill();
                        gridGroup.remove(sprite);
                        pieceSprites[piece.x][piece.y] = null;
                        match3Game.board.setPiece(piece.x, piece.y, null);

                        pendingAnimations--;
                        if (pendingAnimations <= 0) {
                            onComplete();
                        }
                    }
                });
            } else {
                // Still need to remove the piece from the board
                match3Game.board.setPiece(piece.x, piece.y, null);
                pendingAnimations--;
                if (pendingAnimations <= 0) {
                    onComplete();
                }
            }
        }
    }

    private function animateFallingPieces(onComplete:Void->Void):Void {
        var fallingPieces:Array<{sprite:FlxSprite, fromY:Int, toY:Int, x:Int}> = [];

        // Apply gravity and find falling pieces
        for (x in 0...gridSize) {
            var writeIndex = gridSize - 1;

            // Collect non-null pieces from bottom to top
            for (y in 0...gridSize) {
                var readY = gridSize - 1 - y;
                var piece = match3Game.board.getPiece(x, readY);
                var sprite = pieceSprites[x][readY];

                if (piece != null && sprite != null) {
                    if (writeIndex != readY) {
                        // Piece needs to fall
                        fallingPieces.push({
                            sprite: sprite,
                            fromY: readY,
                            toY: writeIndex,
                            x: x
                        });

                        // Update game board
                        match3Game.board.setPiece(x, writeIndex, piece);
                        match3Game.board.setPiece(x, readY, null);

                        // Update sprite array
                        pieceSprites[x][writeIndex] = sprite;
                        pieceSprites[x][readY] = null;
                    }
                    writeIndex--;
                }
            }
        }

        // Ensure coordinates are synchronized after gravity
        match3Game.board.synchronizeCoordinates();

        pendingAnimations = fallingPieces.length;

        if (pendingAnimations == 0) {
            onComplete();
            return;
        }

        for (falling in fallingPieces) {
            var targetY = gridOffsetY + (falling.toY * tileSize);
            var fallDistance = falling.toY - falling.fromY;
            var animTime = 0.15 + (fallDistance * 0.05); // Reduced animation time

            FlxTween.tween(falling.sprite, {y: targetY}, animTime, {
                ease: FlxEase.quadOut,
                onComplete: function(tween:FlxTween) {
                    pendingAnimations--;
                    if (pendingAnimations <= 0) {
                        onComplete();
                    }
                }
            });
        }
    }

    private function animateNewPieces(onComplete:Void->Void):Void {
        var newPieces:Array<{piece:Match3Piece, x:Int, y:Int}> = [];

        // Create new pieces for empty spaces at the top
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                if (match3Game.board.getPiece(x, y) == null) {
                    var newPiece = match3Game.board.generateRandomPiece(x, y);
                    match3Game.board.setPiece(x, y, newPiece);
                    newPieces.push({piece: newPiece, x: x, y: y});
                }
            }
        }

        // Ensure coordinates are synchronized after new pieces
        match3Game.board.synchronizeCoordinates();

        // Validate colors for all new pieces
        for (newPieceData in newPieces) {
            if (newPieceData.piece.color == 0 || newPieceData.piece.color == FlxColor.WHITE) {
                newPieceData.piece.color = getDefaultColorForPiece(newPieceData.piece);
            }
        }

        pendingAnimations = newPieces.length;

        if (pendingAnimations == 0) {
            onComplete();
            return;
        }

        for (newPieceData in newPieces) {
            var sprite = createPieceSprite(newPieceData.piece, newPieceData.x, newPieceData.y);

            // Start above the grid and fall down
            var startY = gridOffsetY - tileSize;
            var targetY = gridOffsetY + (newPieceData.y * tileSize);
            sprite.y = startY;
            sprite.alpha = 0;

            // Fade in and drop animation with reduced timing
            FlxTween.tween(sprite, {alpha: 1}, 0.15);
            FlxTween.tween(sprite, {y: targetY}, 0.3, {
                ease: FlxEase.quadOut,
                startDelay: Math.random() * 0.05, // Reduced random delay
                onComplete: function(tween:FlxTween) {
                    pendingAnimations--;
                    if (pendingAnimations <= 0) {
                        onComplete();
                    }
                }
            });
        }
    }

    private function updateSelectionDisplay():Void {
        if (match3Game.selectedPiece != null) {
            selectionSprite.visible = true;
            selectionSprite.x = gridOffsetX + (Std.int(match3Game.selectedPiece.x) * tileSize);
            selectionSprite.y = gridOffsetY + (Std.int(match3Game.selectedPiece.y) * tileSize);
        } else {
            selectionSprite.visible = false;
        }
    }

    private function updateGameDisplay():Void {
        clearGrid();

        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = match3Game.board.getPiece(x, y);
                if (piece != null) {
                    createPieceSprite(piece, x, y);
                }
            }
        }

        // Validate all piece colors after display update
        // validateAllPieceColors();
    }

    private function createPieceSprite(piece:Match3Piece, x:Int, y:Int):FlxSprite {
        var sprite = new FlxSprite();
        var posX = gridOffsetX + (x * tileSize);
        var posY = gridOffsetY + (y * tileSize);

        sprite.x = posX;
        sprite.y = posY;

        // Create piece visual based on type - backend handles logic, frontend only handles visuals
        switch(piece.type) {
            case BASIC(basicType):
                // Use piece color directly (backend sets this properly)
                sprite.makeGraphic(tileSize - 2, tileSize - 2, piece.color, true);

            case POWER_UP(specialType, powerUpColor):
                // Create base graphic with unique flag to prevent shared graphics issues
                sprite.makeGraphic(tileSize - 2, tileSize - 2, powerUpColor, true);
                // Add visual effects for power-ups (visuals only, no logic)
                addVisualEffects(sprite, specialType);

            case ICON(iconName):
                // Try to load character icon, fallback to colored square
                var iconPath = 'icons/$iconName/icon';
                if (Paths.fileExists('images/$iconPath.png', IMAGE)) {
                    sprite.loadGraphic(Paths.image(iconPath));
                    sprite.setGraphicSize(tileSize - 4, tileSize - 4);
                    sprite.updateHitbox();
                } else {
                    // Use piece color from backend
                    sprite.makeGraphic(tileSize - 2, tileSize - 2, piece.color, true);
                }

            case OBSTACLE:
                sprite.makeGraphic(tileSize - 2, tileSize - 2, FlxColor.GRAY, true);
                // Add border visual effect
                addVisualBorder(sprite, FlxColor.BLACK);
        }

        sprite.updateHitbox();
        gridGroup.add(sprite);
        pieceSprites[x][y] = sprite;

        return sprite;
    }

    /**
     * Add visual effects to powerup sprites (frontend visual only)
     */
    private function addVisualEffects(sprite:FlxSprite, specialType:SpecialType):Void {
        switch(specialType) {
            case HORIZONTAL_STRIPE:
                // Draw horizontal stripe visual
                sprite.pixels.fillRect(new Rectangle(0, (tileSize - 2) / 2 - 2, tileSize - 2, 4), FlxColor.WHITE);
            case VERTICAL_STRIPE:
                // Draw vertical stripe visual
                sprite.pixels.fillRect(new Rectangle((tileSize - 2) / 2 - 2, 0, 4, tileSize - 2), FlxColor.WHITE);
            case BOMB:
                // Create bomb visual effect
                var bombSize = 16;
                var bombX = Std.int((tileSize - 2) / 2 - bombSize / 2);
                var bombY = Std.int((tileSize - 2) / 2 - bombSize / 2);
                sprite.pixels.fillRect(new Rectangle(bombX, bombY, bombSize, bombSize), FlxColor.WHITE);
            case COLOR_BOMB:
                // Create color bomb visual effect
                var outerSize = 24;
                var innerSize = 16;
                var outerX = Std.int((tileSize - 2) / 2 - outerSize / 2);
                var outerY = Std.int((tileSize - 2) / 2 - outerSize / 2);
                var innerX = Std.int((tileSize - 2) / 2 - innerSize / 2);
                var innerY = Std.int((tileSize - 2) / 2 - innerSize / 2);
                sprite.pixels.fillRect(new Rectangle(outerX, outerY, outerSize, outerSize), FlxColor.YELLOW);
                sprite.pixels.fillRect(new Rectangle(innerX, innerY, innerSize, innerSize), FlxColor.WHITE);
            case RAINBOW:
                // Draw rainbow visual effect
                var colors = [FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW, FlxColor.GREEN, FlxColor.BLUE, FlxColor.PURPLE];
                for (i in 0...colors.length) {
                    var stripeHeight = Std.int((tileSize - 2) / colors.length);
                    sprite.pixels.fillRect(new Rectangle(0, i * stripeHeight, tileSize - 2, stripeHeight), colors[i]);
                }
            case _:
        }
    }

    /**
     * Add visual border to sprites (frontend visual only)
     */
    private function addVisualBorder(sprite:FlxSprite, borderColor:FlxColor, thickness:Int = 2):Void {
        sprite.pixels.fillRect(new Rectangle(0, 0, tileSize - 2, thickness), borderColor);
        sprite.pixels.fillRect(new Rectangle(0, 0, thickness, tileSize - 2), borderColor);
        sprite.pixels.fillRect(new Rectangle(tileSize - 2 - thickness, 0, thickness, tileSize - 2), borderColor);
        sprite.pixels.fillRect(new Rectangle(0, tileSize - 2 - thickness, tileSize - 2, thickness), borderColor);
    }

    private function clearGrid():Void {
        gridGroup.clear();
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                pieceSprites[x][y] = null;
            }
        }
    }

    // Legacy method - replaced by new animation system
    private function animateMove(gridX:Int, gridY:Int):Void {
        // This method is now handled by the new animation system
        // Keeping for compatibility but functionality moved to handlePieceClick
    }

    private function updateUI():Void {
        if (match3Game == null) return;

        // Update score
        scoreText.text = "Score: " + match3Game.getScore();

        // Update moves
        if (match3Game.movesRemaining >= 0) {
            movesText.text = "Moves: " + match3Game.movesRemaining;
        } else {
            movesText.text = "Moves: Unlimited";
        }

        // Update objectives
        var objectiveText = "Objectives:\n";
        for (objective in match3Game.objectiveManager.objectives) {
            var status = objective.isCompleted ? "✓" : "○";
            objectiveText += '$status ${objective.description}\n   ${objective.currentValue}/${objective.targetValue}\n';
        }
        objectivesText.text = objectiveText;

        // Update game mode specific UI
        if (currentGameMode == TIMED && match3Game.timeRemaining > 0) {
            var timeStr = "Time: " + Math.ceil(match3Game.timeRemaining) + "s";
            gameStatusText.text = timeStr;
        }
    }

    private function flattenMatches(matches:Array<Array<Match3Piece>>):Array<Match3Piece> {
        var result:Array<Match3Piece> = [];
        for (match in matches) {
            for (piece in match) {
                result.push(piece);
            }
        }
        return result;
    }

    private function hasPossibleMoves():Bool {
        // Check all possible adjacent swaps to see if any would create a match
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = match3Game.board.getPiece(x, y);
                if (piece == null || piece.type == OBSTACLE) continue;

                // Check right and down directions only (to avoid duplicate checks)
                var directions = [
                    {dx: 1, dy: 0},  // right
                    {dx: 0, dy: 1}   // down
                ];

                for (dir in directions) {
                    var newX = x + dir.dx;
                    var newY = y + dir.dy;

                    if (match3Game.board.isValidPosition(newX, newY)) {
                        var adjacentPiece = match3Game.board.getPiece(newX, newY);
                        if (adjacentPiece == null || adjacentPiece.type == OBSTACLE) continue;

                        // Temporarily swap pieces
                        match3Game.board.setPiece(x, y, adjacentPiece);
                        match3Game.board.setPiece(newX, newY, piece);

                        // Update coordinates temporarily
                        var originalX1 = piece.x, originalY1 = piece.y;
                        var originalX2 = adjacentPiece.x, originalY2 = adjacentPiece.y;
                        piece.x = newX; piece.y = newY;
                        adjacentPiece.x = x; adjacentPiece.y = y;

                        // Check if this creates any matches
                        var matches = match3Game.board.findAllMatches();

                        // Swap back
                        match3Game.board.setPiece(x, y, piece);
                        match3Game.board.setPiece(newX, newY, adjacentPiece);
                        piece.x = originalX1; piece.y = originalY1;
                        adjacentPiece.x = originalX2; adjacentPiece.y = originalY2;

                        if (matches.length > 0) {
                            return true; // Found a possible move
                        }
                    }
                }
            }
        }
        return false; // No possible moves found
    }

    private function shuffleBoard():Void {
        gameStatusText.text = "No moves available! Shuffling board...";
        isAnimating = true;

        // Collect all non-obstacle pieces
        var allPieces:Array<Match3Piece> = [];
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = match3Game.board.getPiece(x, y);
                if (piece != null && piece.type != OBSTACLE) {
                    allPieces.push(piece);
                    match3Game.board.setPiece(x, y, null);
                    // Remove sprites temporarily
                    if (pieceSprites[x][y] != null) {
                        pieceSprites[x][y].kill();
                        gridGroup.remove(pieceSprites[x][y]);
                        pieceSprites[x][y] = null;
                    }
                }
            }
        }

        // Shuffle the pieces array
        for (i in 0...allPieces.length) {
            var randomIndex = Math.floor(Math.random() * allPieces.length);
            var temp = allPieces[i];
            allPieces[i] = allPieces[randomIndex];
            allPieces[randomIndex] = temp;
        }

        // Place pieces back on the board
        var pieceIndex = 0;
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var existingPiece = match3Game.board.getPiece(x, y);
                if (existingPiece == null && pieceIndex < allPieces.length) {
                    var piece = allPieces[pieceIndex];
                    piece.x = x;
                    piece.y = y;
                    match3Game.board.setPiece(x, y, piece);

                    // Create new sprite with animation
                    var sprite = createPieceSprite(piece, x, y);
                    sprite.alpha = 0;
                    sprite.scale.set(0.5, 0.5);

                    // Animate the piece appearing
                    FlxTween.tween(sprite, {alpha: 1}, 0.3, {startDelay: Math.random() * 0.5});
                    FlxTween.tween(sprite.scale, {x: 1, y: 1}, 0.4, {
                        ease: FlxEase.backOut,
                        startDelay: Math.random() * 0.5
                    });

                    pieceIndex++;
                }
            }
        }

        // Wait for animations to finish then check for moves again
        new FlxTimer().start(1.0, function(timer:FlxTimer) {
            isAnimating = false;
            gameStatusText.text = "Board shuffled! Continue playing.";

            // Validate all piece colors after shuffle
            // validateAllPieceColors();

            // If still no moves after shuffle, shuffle again (shouldn't happen often)
            if (!hasPossibleMoves()) {
                shuffleBoard();
            }
        });
    }

    // Game event callbacks
    private function onScoreChanged(player:Int, newScore:Int):Void {
        trace('Player $player score: $newScore');
    }

    private function onGameOver(playerWon:Bool):Void {
        isGameStarted = false;
        var message = playerWon ? "Congratulations! You won!" : "Game Over!";
        gameStatusText.text = message;
        trace(message);
    }

    private function onPieceMatched(pieces:Array<Match3Piece>):Void {
        trace('Matched ${pieces.length} pieces');
        // Animation is now handled by the cascade system
        // This callback is mainly for sound effects and UI updates
        gameStatusText.text = 'Match! +${pieces.length * 10} points';
    }

    private function onCascade(cascadeCount:Int):Void {
        trace('Cascade #$cascadeCount');
        gameStatusText.text = 'Cascade! x$cascadeCount';
    }

    private function onSpecialActivated(piece:Match3Piece, affectedPieces:Array<Match3Piece>):Void {
        trace('Special activated: ${piece.specialType}, affected ${affectedPieces.length} pieces');
        gameStatusText.text = 'Special Power Activated!';
    }

    private function validateAllPieceColors():Void {
        var fixedCount = 0;
        var recreatedSprites = 0;

        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = match3Game.board.getPiece(x, y);
                if (piece != null) {
                    var originalColor = piece.color;
                    var sprite = pieceSprites[x][y];

                    // Check if piece color is invalid
                    if (piece.color == 0 || piece.color == FlxColor.WHITE) {
                        // Fix the piece color
                        piece.color = getDefaultColorForPiece(piece);
                        fixedCount++;

                        // Recreate the sprite with correct color
                        if (sprite != null) {
                            sprite.kill();
                            gridGroup.remove(sprite);
                        }
                        pieceSprites[x][y] = null;
                        createPieceSprite(piece, x, y);
                        recreatedSprites++;
                    }
                    // Also check if sprite color doesn't match piece color
                    else if (sprite != null && sprite.color != piece.color) {
                        sprite.color = piece.color;
                        fixedCount++;
                    }
                }
            }
        }

        if (fixedCount > 0) {
            trace('Color validation: Fixed $fixedCount pieces, recreated $recreatedSprites sprites');
        }
    }

    private function getDefaultColorForPiece(piece:Match3Piece):Int {
        return switch(piece.type) {
            case BASIC(basicType):
                switch(basicType) {
                    case RED: FlxColor.RED;
                    case BLUE: FlxColor.BLUE;
                    case GREEN: FlxColor.GREEN;
                    case YELLOW: FlxColor.YELLOW;
                    case PURPLE: FlxColor.PURPLE;
                    case ORANGE: FlxColor.ORANGE;
                }
            case POWER_UP(_, powerUpColor): powerUpColor;
            case ICON(_): FlxColor.CYAN;
            case OBSTACLE: FlxColor.GRAY;
        }
    }

    // Missing CPU-related methods
    private function shuffleCPUBoard():Void {
        if (cpuGame == null) return;

        // Collect all non-null pieces from CPU board
        var pieces:Array<Match3Piece> = [];
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = cpuGame.board.getPiece(x, y);
                if (piece != null && piece.type != OBSTACLE) {
                    pieces.push(piece);
                    cpuGame.board.setPiece(x, y, null);
                }
            }
        }

        // Shuffle the pieces array
        for (i in 0...pieces.length) {
            var j = Std.random(pieces.length);
            var temp = pieces[i];
            pieces[i] = pieces[j];
            pieces[j] = temp;
        }

        // Redistribute pieces back to board
        var pieceIndex = 0;
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                if (cpuGame.board.getPiece(x, y) == null && pieceIndex < pieces.length) {
                    var piece = pieces[pieceIndex];
                    piece.x = x;
                    piece.y = y;
                    cpuGame.board.setPiece(x, y, piece);
                    pieceIndex++;
                }
            }
        }

        // Update CPU grid reference
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                cpuGrid[x][y] = cpuGame.board.getPiece(x, y);
            }
        }

        updateCPUBoardVisuals();
    }

    private function updateCPUBoardVisuals():Void {
        // Clear existing CPU sprites
        cpuGridGroup.clear();
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                cpuPieceSprites[x][y] = null;
            }
        }

        // Create new sprites for all CPU pieces
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                var piece = cpuGame.board.getPiece(x, y);
                if (piece != null) {
                    var sprite = createCPUPieceSprite(piece, x, y);
                    cpuPieceSprites[x][y] = sprite;
                    cpuGridGroup.add(sprite);

                    // Ensure sprite is visible
                    sprite.visible = true;
                    sprite.alpha = 1.0;
                }
            }
        }

        // Ensure the CPU grid group is visible
        cpuGridGroup.visible = true;
    }

    private function drawCPUGameBoard():Void {
        updateCPUBoardVisuals();
    }

    private function createCPUPieceSprite(piece:Match3Piece, x:Int, y:Int):FlxSprite {
        var sprite = new FlxSprite();
        sprite.x = cpuGridOffsetX + x * tileSize;
        sprite.y = cpuGridOffsetY + y * tileSize;

        // Create visual based on piece type - backend handles logic, frontend only handles visuals
        switch(piece.type) {
            case BASIC(basicType):
                // Use piece color directly (backend sets this properly)
                sprite.makeGraphic(tileSize - 2, tileSize - 2, piece.color, true);

            case POWER_UP(specialType, powerUpColor):
                // Create base graphic with unique flag to prevent shared graphics issues
                sprite.makeGraphic(tileSize - 2, tileSize - 2, powerUpColor, true);
                // Add visual effects for power-ups (visuals only, no logic)
                addVisualEffects(sprite, specialType);

            case ICON(iconName):
                // Use piece color from backend
                sprite.makeGraphic(tileSize - 2, tileSize - 2, piece.color, true);

            case OBSTACLE:
                sprite.makeGraphic(tileSize - 2, tileSize - 2, FlxColor.GRAY, true);
                // Add border visual effect
                addVisualBorder(sprite, FlxColor.BLACK);
        }

        // Add border for better visibility
        var borderThickness = 2;
        sprite.pixels.fillRect(new Rectangle(0, 0, tileSize - 2, borderThickness), FlxColor.BLACK);
        sprite.pixels.fillRect(new Rectangle(0, tileSize - 2 - borderThickness, tileSize - 2, borderThickness), FlxColor.BLACK);
        sprite.pixels.fillRect(new Rectangle(0, 0, borderThickness, tileSize - 2), FlxColor.BLACK);
        sprite.pixels.fillRect(new Rectangle(tileSize - 2 - borderThickness, 0, borderThickness, tileSize - 2), FlxColor.BLACK);

        return sprite;
    }

    private function updateCPUGameDisplay():Void {
        if (cpuScoreText != null) {
            cpuScoreText.text = "CPU Score: " + cpuGame.getScore();
        }
    }

    private function onCPUScoreChanged(player:Int, newScore:Int):Void {
        cpuScoreText.text = "CPU Score: " + newScore;
    }

    private function onCPUPieceMatched(pieces:Array<Match3Piece>):Void {
        // Visual feedback for CPU piece matches could be added here
        // For now, just update the display
        updateCPUGameDisplay();
    }

    private function applyCPUGravity():Void {
        for (x in 0...cpuGame.board.width) {
            var writeIndex = cpuGame.board.height - 1;

            // Move pieces down
            for (y in (cpuGame.board.height - 1)...(-1)) {
                var piece = cpuGame.board.getPiece(x, y);
                if (piece != null) {
                    if (y != writeIndex) {
                        cpuGame.board.setPiece(x, writeIndex, piece);
                        cpuGame.board.setPiece(x, y, null);

                        // Move sprite with animation
                        if (cpuPieceSprites[x][y] != null) {
                            cpuPieceSprites[x][writeIndex] = cpuPieceSprites[x][y];
                            cpuPieceSprites[x][y] = null;

                            // Animate falling
                            var targetY = cpuGridOffsetY + writeIndex * tileSize;
                            FlxTween.tween(cpuPieceSprites[x][writeIndex], {y: targetY}, 0.2, {ease: FlxEase.quadOut});
                        }
                    }
                    writeIndex--;
                }
            }
        }
        cpuGame.board.synchronizeCoordinates();
    }

    private function fillCPUEmptySpaces():Void {
        for (x in 0...cpuGame.board.width) {
            for (y in 0...cpuGame.board.height) {
                if (cpuGame.board.getPiece(x, y) == null) {
                    var basicTypes = [BasicPieceType.RED, BasicPieceType.BLUE, BasicPieceType.GREEN, BasicPieceType.YELLOW, BasicPieceType.PURPLE, BasicPieceType.ORANGE];
                    var randomType = basicTypes[Std.random(basicTypes.length)];
                    var newPiece = new Match3Piece(BASIC(randomType), x, y);
                    cpuGame.board.setPiece(x, y, newPiece);

                    var sprite = createCPUPieceSprite(newPiece, x, y);
                    cpuPieceSprites[x][y] = sprite;
                    cpuGridGroup.add(sprite);

                    // Animate new piece falling from above
                    sprite.y = cpuGridOffsetY - tileSize;
                    sprite.alpha = 0.5;
                    var targetY = cpuGridOffsetY + y * tileSize;
                    FlxTween.tween(sprite, {y: targetY, alpha: 1.0}, 0.3, {
                        ease: FlxEase.quadOut,
                        startDelay: Math.random() * 0.1
                    });
                }
            }
        }
    }

    override public function destroy():Void {
        // Reset mouse cursor visibility when leaving the state
        FlxG.mouse.visible = false;
        super.destroy();
    }
}
