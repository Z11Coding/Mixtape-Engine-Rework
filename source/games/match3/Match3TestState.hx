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

    // UI Elements
    private var bgSprite:FlxSprite;
    private var gameStatusText:FlxText;
    private var scoreText:FlxText;
    private var movesText:FlxText;
    private var objectivesText:FlxText;
    private var gridGroup:FlxTypedGroup<FlxSprite>;
    private var pieceSprites:Array<Array<FlxSprite>>;
    private var selectionSprite:FlxSprite;

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

    // Animation state
    private var animatingPieces:Array<FlxSprite> = [];
    private var isAnimating:Bool = false;

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

        // Score display
        scoreText = new FlxText(gridOffsetX + (gridSize * tileSize) + 20, gridOffsetY, 200, "Score: 0");
        scoreText.setFormat(null, 18, FlxColor.WHITE);
        add(scoreText);

        // Moves remaining
        movesText = new FlxText(gridOffsetX + (gridSize * tileSize) + 20, gridOffsetY + 30, 200, "Moves: Unlimited");
        movesText.setFormat(null, 16, FlxColor.WHITE);
        add(movesText);

        // Objectives
        objectivesText = new FlxText(gridOffsetX + (gridSize * tileSize) + 20, gridOffsetY + 60, 200, "Objectives:");
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
        gridGroup = new FlxTypedGroup<FlxSprite>();
        add(gridGroup);

        pieceSprites = [];
        for (x in 0...gridSize) {
            pieceSprites[x] = [];
            for (y in 0...gridSize) {
                pieceSprites[x][y] = null;
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
    }

    private function startGame():Void {
        if (isGameStarted) return;

        var objectives = getObjectivesForMode(currentGameMode);
        var moves = (currentGameMode == MOVES_LIMITED) ? 20 : -1;
        var timeLimit = (currentGameMode == TIMED) ? 120.0 : -1;

        match3Game.initialize(objectives, getIconList(), moves, timeLimit);

        isGameStarted = true;
        updateGameDisplay();
        updateUI();

        gameStatusText.text = "Game Started! Click pieces to match them.";
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
        if (Math.random() < 0.3) {
            return Match3Game.getAvailableIcons();
        }
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
        }

        handleInput();
    }

    private function handleInput():Void {
        if (!isGameStarted || isAnimating) return;

        if (FlxG.mouse.justPressed) {
            var mouseX = FlxG.mouse.x;
            var mouseY = FlxG.mouse.y;

            // Check if click is within grid
            if (mouseX >= gridOffsetX && mouseX < gridOffsetX + (gridSize * tileSize) &&
                mouseY >= gridOffsetY && mouseY < gridOffsetY + (gridSize * tileSize)) {

                var gridX = Math.floor((mouseX - gridOffsetX) / tileSize);
                var gridY = Math.floor((mouseY - gridOffsetY) / tileSize);

                if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
                    var success = match3Game.handleClick(gridX, gridY);
                    updateSelectionDisplay();

                    if (success) {
                        animateMove(gridX, gridY);
                    }
                }
            }
        }
    }

    private function updateSelectionDisplay():Void {
        if (match3Game.selectedPiece != null) {
            selectionSprite.visible = true;
            selectionSprite.x = gridOffsetX + (match3Game.selectedPiece.x * tileSize);
            selectionSprite.y = gridOffsetY + (match3Game.selectedPiece.y * tileSize);
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
    }

    private function createPieceSprite(piece:Match3Piece, x:Int, y:Int):FlxSprite {
        var sprite = new FlxSprite();
        var posX = gridOffsetX + (x * tileSize);
        var posY = gridOffsetY + (y * tileSize);

        sprite.x = posX;
        sprite.y = posY;

        // Create piece visual based on type
        switch(piece.type) {
            case BASIC(_) | POWER_UP(_, _):
                sprite.makeGraphic(tileSize - 2, tileSize - 2, piece.color);

                // Add special effects for power-ups
                if (piece.isSpecial) {
                    addSpecialEffects(sprite, piece.specialType);
                }

            case ICON(iconName):
                // Try to load character icon, fallback to colored square
                var iconPath = 'characters/$iconName/icon';
                if (Paths.fileExists('images/$iconPath.png', IMAGE)) {
                    sprite.loadGraphic(Paths.image(iconPath));
                    sprite.setGraphicSize(tileSize - 4, tileSize - 4);
                } else {
                    sprite.makeGraphic(tileSize - 2, tileSize - 2, piece.color);
                }

            case OBSTACLE:
                sprite.makeGraphic(tileSize - 2, tileSize - 2, FlxColor.GRAY);
                // Add border manually
                var borderThickness = 2;
                sprite.pixels.fillRect(new Rectangle(0, 0, tileSize - 2, borderThickness), FlxColor.BLACK);
                sprite.pixels.fillRect(new Rectangle(0, tileSize - 2 - borderThickness, tileSize - 2, borderThickness), FlxColor.BLACK);
                sprite.pixels.fillRect(new Rectangle(0, 0, borderThickness, tileSize - 2), FlxColor.BLACK);
                sprite.pixels.fillRect(new Rectangle(tileSize - 2 - borderThickness, 0, borderThickness, tileSize - 2), FlxColor.BLACK);
        }

        sprite.updateHitbox();
        gridGroup.add(sprite);
        pieceSprites[x][y] = sprite;

        return sprite;
    }

    private function addSpecialEffects(sprite:FlxSprite, specialType:SpecialType):Void {
        switch(specialType) {
            case HORIZONTAL_STRIPE:
                // Draw horizontal stripe manually
                sprite.pixels.fillRect(new Rectangle(0, tileSize / 2 - 2, tileSize - 2, 4), FlxColor.WHITE);
            case VERTICAL_STRIPE:
                // Draw vertical stripe manually
                sprite.pixels.fillRect(new Rectangle(tileSize / 2 - 2, 0, 4, tileSize - 2), FlxColor.WHITE);
            case BOMB:
                // Create bomb effect - simplified as a square for now
                var bombSize = 16;
                var bombX = Std.int(tileSize / 2 - bombSize / 2);
                var bombY = Std.int(tileSize / 2 - bombSize / 2);
                sprite.pixels.fillRect(new Rectangle(bombX, bombY, bombSize, bombSize), FlxColor.WHITE);
            case COLOR_BOMB:
                // Create color bomb effect - simplified as nested squares
                var outerSize = 24;
                var innerSize = 16;
                var outerX = Std.int(tileSize / 2 - outerSize / 2);
                var outerY = Std.int(tileSize / 2 - outerSize / 2);
                var innerX = Std.int(tileSize / 2 - innerSize / 2);
                var innerY = Std.int(tileSize / 2 - innerSize / 2);
                sprite.pixels.fillRect(new Rectangle(outerX, outerY, outerSize, outerSize), FlxColor.YELLOW);
                sprite.pixels.fillRect(new Rectangle(innerX, innerY, innerSize, innerSize), FlxColor.WHITE);
            case RAINBOW:
                // Draw rainbow effect
                var colors = [FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW, FlxColor.GREEN, FlxColor.BLUE, FlxColor.PURPLE];
                for (i in 0...colors.length) {
                    var stripeHeight = Std.int((tileSize - 2) / colors.length);
                    sprite.pixels.fillRect(new Rectangle(0, i * stripeHeight, tileSize - 2, stripeHeight), colors[i]);
                }
            case _:
        }
    }

    private function clearGrid():Void {
        gridGroup.clear();
        for (x in 0...gridSize) {
            for (y in 0...gridSize) {
                pieceSprites[x][y] = null;
            }
        }
    }

    private function animateMove(gridX:Int, gridY:Int):Void {
        isAnimating = true;

        // Simple animation - just update display after a short delay
        new FlxTimer().start(0.3, function(timer:FlxTimer) {
            updateGameDisplay();
            isAnimating = false;
        });
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

        // Add visual effects for matched pieces
        for (piece in pieces) {
            var sprite = pieceSprites[piece.x][piece.y];
            if (sprite != null) {
                FlxTween.tween(sprite, {alpha: 0}, 0.3, {
                    ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween) {
                        sprite.kill();
                    }
                });
            }
        }
    }

    private function onCascade(cascadeCount:Int):Void {
        trace('Cascade #$cascadeCount');
        gameStatusText.text = 'Cascade! x$cascadeCount';
    }

    private function onSpecialActivated(piece:Match3Piece, affectedPieces:Array<Match3Piece>):Void {
        trace('Special activated: ${piece.specialType}, affected ${affectedPieces.length} pieces');
        gameStatusText.text = 'Special Power Activated!';
    }

    override public function destroy():Void {
        // Reset mouse cursor visibility when leaving the state
        FlxG.mouse.visible = false;
        super.destroy();
    }
}
