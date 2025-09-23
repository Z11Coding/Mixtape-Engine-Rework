package yutautil.games.stealthmaze;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.MainMenuState;
import yutautil.games.stealthmaze.backend.MazeData.MazeDifficulty;

/**
 * Minigame state that simulates stealth maze gameplay with graphics
 * Provides visual preview and launch options for the full game
 */
class StealthMazeMinigameState extends MusicBeatState {

    // Demo maze settings
    private static inline var DEMO_WIDTH:Int = 15;
    private static inline var DEMO_HEIGHT:Int = 10;
    private static inline var TILE_SIZE:Int = 24;

    // Visual elements
    private var demoMaze:FlxGroup;
    private var demoPlayer:FlxSprite;
    private var demoEnemies:FlxGroup;
    private var demoCollectibles:FlxGroup;
    private var demoClosets:FlxGroup;
    private var demoTail:FlxGroup;
    private var visionCone:FlxSprite;
    private var enemyVisionCones:FlxGroup;

    // UI elements
    private var titleText:FlxText;
    private var descriptionText:FlxText;
    private var controlsText:FlxText;
    private var launchButtons:FlxGroup;
    private var backButton:FlxButton;

    // Demo simulation
    private var demoTimer:FlxTimer;
    private var playerPath:Array<FlxPoint>;
    private var currentPathIndex:Int = 0;
    private var isSimulating:Bool = false;

    // Demo maze layout (1 = wall, 0 = floor, 2 = collectible, 3 = enemy, 4 = closet)
    private var mazeLaying:Array<Array<Int>> = [
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,0,0,0,1,0,0,2,0,0,1,0,0,4,1],
        [1,0,1,0,1,0,1,1,1,0,1,0,1,0,1],
        [1,0,1,0,0,0,0,0,0,0,0,0,1,0,1],
        [1,0,1,1,1,0,1,3,1,0,1,1,1,0,1],
        [1,0,0,0,0,0,1,0,1,0,0,0,0,0,1],
        [1,1,1,0,1,0,1,0,1,0,1,0,1,1,1],
        [1,0,0,0,1,0,0,0,0,0,1,0,0,2,1],
        [1,0,1,1,1,1,1,0,1,1,1,1,1,0,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    ];

    override function create():Void {
        super.create();

        // Set background
        FlxG.cameras.bgColor = FlxColor.fromRGB(15, 15, 20);

        // Create visual elements
        createTitle();
        createDemoMaze();
        createUIElements();

        // Start demo simulation
        startDemoSimulation();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Stealth Maze Preview", "Viewing minigame demo");
        #end
    }

    /**
     * Create title and description
     */
    private function createTitle():Void {
        titleText = new FlxText(0, 20, FlxG.width, "STEALTH MAZE", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        descriptionText = new FlxText(20, 70, FlxG.width - 40,
            "Navigate randomly generated mazes while avoiding purple enemies!\n" +
            "• Cyan square = YOU (the player)\n" +
            "• Purple squares = ENEMIES with vision cones\n" +
            "• Red squares = OBJECTIVES (creates a tail)\n" +
            "• Brown squares = CLOSETS for hiding\n" +
            "• Use stealth and strategy to escape each floor!", 14);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);
    }

    /**
     * Create the demo maze visualization
     */
    private function createDemoMaze():Void {
        demoMaze = new FlxGroup();
        demoEnemies = new FlxGroup();
        demoCollectibles = new FlxGroup();
        demoClosets = new FlxGroup();
        demoTail = new FlxGroup();
        enemyVisionCones = new FlxGroup();

        var startX = (FlxG.width - (DEMO_WIDTH * TILE_SIZE)) * 0.5;
        var startY = 180;

        // Create maze tiles
        for (y in 0...DEMO_HEIGHT) {
            for (x in 0...DEMO_WIDTH) {
                var tileType = mazeLaying[y][x];
                var posX = startX + x * TILE_SIZE;
                var posY = startY + y * TILE_SIZE;

                var tile:FlxSprite = null;

                switch (tileType) {
                    case 1: // Wall
                        tile = new FlxSprite(posX, posY);
                        tile.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.GRAY);
                        demoMaze.add(tile);

                    case 0: // Floor
                        tile = new FlxSprite(posX, posY);
                        tile.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.fromRGB(40, 40, 45));
                        demoMaze.add(tile);

                    case 2: // Collectible (on floor)
                        // Floor first
                        tile = new FlxSprite(posX, posY);
                        tile.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.fromRGB(40, 40, 45));
                        demoMaze.add(tile);

                        // Collectible on top
                        var collectible = new FlxSprite(posX + 4, posY + 4);
                        collectible.makeGraphic(TILE_SIZE - 8, TILE_SIZE - 8, FlxColor.RED);
                        demoCollectibles.add(collectible);

                        // Animate collectible
                        FlxTween.tween(collectible, {y: collectible.y - 3}, 1.0, {
                            ease: FlxEase.sineInOut,
                            type: PINGPONG
                        });

                    case 3: // Enemy (on floor)
                        // Floor first
                        tile = new FlxSprite(posX, posY);
                        tile.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.fromRGB(40, 40, 45));
                        demoMaze.add(tile);

                        // Enemy on top
                        var enemy = new FlxSprite(posX + 2, posY + 2);
                        enemy.makeGraphic(TILE_SIZE - 4, TILE_SIZE - 4, FlxColor.PURPLE);
                        demoEnemies.add(enemy);

                        // Enemy vision cone
                        var visionCone = new FlxSprite(posX - TILE_SIZE, posY - TILE_SIZE);
                        visionCone.makeGraphic(TILE_SIZE * 3, TILE_SIZE * 3, FlxColor.fromRGBFloat(0.8, 0.2, 0.8, 0.3));
                        enemyVisionCones.add(visionCone);

                        // Animate vision cone
                        FlxTween.tween(visionCone, {alpha: 0.1}, 1.5, {
                            ease: FlxEase.sineInOut,
                            type: PINGPONG
                        });

                    case 4: // Closet (on floor)
                        // Floor first
                        tile = new FlxSprite(posX, posY);
                        tile.makeGraphic(TILE_SIZE, TILE_SIZE, FlxColor.fromRGB(40, 40, 45));
                        demoMaze.add(tile);

                        // Closet on top
                        var closet = new FlxSprite(posX + 1, posY + 1);
                        closet.makeGraphic(TILE_SIZE - 2, TILE_SIZE - 2, FlxColor.fromRGB(139, 69, 19));
                        demoClosets.add(closet);
                }
            }
        }

        // Create player
        demoPlayer = new FlxSprite(startX + 1 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3);
        demoPlayer.makeGraphic(TILE_SIZE - 6, TILE_SIZE - 6, FlxColor.CYAN);

        // Create player vision cone
        visionCone = new FlxSprite();
        visionCone.makeGraphic(TILE_SIZE * 2, TILE_SIZE * 2, FlxColor.fromRGBFloat(0.0, 1.0, 1.0, 0.2));
        updatePlayerVision();

        // Add groups in correct order
        add(demoMaze);
        add(enemyVisionCones);
        add(visionCone);
        add(demoClosets);
        add(demoCollectibles);
        add(demoTail);
        add(demoEnemies);
        add(demoPlayer);
    }

    /**
     * Create UI control elements
     */
    private function createUIElements():Void {
        launchButtons = new FlxGroup();

        var buttonY = FlxG.height - 120;
        var buttonSpacing = 150;
        var startX = (FlxG.width - (buttonSpacing * 3 - 50)) * 0.5;

        // Easy button
        var easyButton = new FlxButton(startX, buttonY, "EASY", function() {
            launchGame(EASY);
        });
        easyButton.setGraphicSize(120, 35);
        easyButton.updateHitbox();
        easyButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(easyButton);

        // Medium button
        var mediumButton = new FlxButton(startX + buttonSpacing, buttonY, "MEDIUM", function() {
            launchGame(MEDIUM);
        });
        mediumButton.setGraphicSize(120, 35);
        mediumButton.updateHitbox();
        mediumButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(mediumButton);

        // Hard button
        var hardButton = new FlxButton(startX + buttonSpacing * 2, buttonY, "HARD", function() {
            launchGame(HARD);
        });
        hardButton.setGraphicSize(120, 35);
        hardButton.updateHitbox();
        hardButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(hardButton);

        add(launchButtons);

        // Controls text
        controlsText = new FlxText(20, FlxG.height - 80, FlxG.width - 40,
            "Controls: WASD/Arrow Keys = Move | SHIFT = Sprint | E/SPACE = Interact with closets", 12);
        controlsText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, CENTER);
        add(controlsText);

        // Back button
        backButton = new FlxButton(20, FlxG.height - 50, "Back to Menu", function() {
            FlxG.switchState(new MainMenuState());
        });
        backButton.setGraphicSize(120, 30);
        backButton.updateHitbox();
        backButton.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER);
        add(backButton);
    }

    /**
     * Start the demo simulation
     */
    private function startDemoSimulation():Void {
        if (isSimulating) return;

        isSimulating = true;
        currentPathIndex = 0;

        // Define a path for the player to follow
        var startX = (FlxG.width - (DEMO_WIDTH * TILE_SIZE)) * 0.5;
        var startY = 180;

        playerPath = [
            new FlxPoint(startX + 1 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3), // Start
            new FlxPoint(startX + 2 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3),
            new FlxPoint(startX + 3 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3),
            new FlxPoint(startX + 3 * TILE_SIZE + 3, startY + 3 * TILE_SIZE + 3),
            new FlxPoint(startX + 7 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3), // Near collectible
            new FlxPoint(startX + 7 * TILE_SIZE + 3, startY + 3 * TILE_SIZE + 3),
            new FlxPoint(startX + 13 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3), // Near closet
            new FlxPoint(startX + 13 * TILE_SIZE + 3, startY + 7 * TILE_SIZE + 3),
            new FlxPoint(startX + 13 * TILE_SIZE + 3, startY + 7 * TILE_SIZE + 3), // Near second collectible
        ];

        // Start moving
        moveToNextPoint();

        // Restart simulation periodically
        demoTimer = new FlxTimer().start(15.0, function(timer) {
            restartSimulation();
        }, 0);
    }

    /**
     * Move player to next point in path
     */
    private function moveToNextPoint():Void {
        if (currentPathIndex >= playerPath.length) {
            // Restart from beginning
            currentPathIndex = 0;

            // Clear tail
            demoTail.clear();
        }

        var targetPoint = playerPath[currentPathIndex];
        var duration = 1.5;

        // Smooth movement tween
        FlxTween.tween(demoPlayer, {x: targetPoint.x, y: targetPoint.y}, duration, {
            ease: FlxEase.sineInOut,
            onComplete: function(tween) {
                // Add tail segment occasionally
                if (currentPathIndex == 4 || currentPathIndex == 8) {
                    addTailSegment();
                }

                currentPathIndex++;

                // Continue moving after a short delay
                new FlxTimer().start(0.5, function(timer) {
                    if (isSimulating) {
                        moveToNextPoint();
                    }
                });
            },
            onUpdate: function(tween) {
                updatePlayerVision();
            }
        });
    }

    /**
     * Add a tail segment behind player
     */
    private function addTailSegment():Void {
        var segment = new FlxSprite(demoPlayer.x - 8, demoPlayer.y - 8);
        segment.makeGraphic(TILE_SIZE - 12, TILE_SIZE - 12, FlxColor.fromRGB(200, 100, 100));
        demoTail.add(segment);

        // Animate segment appearance
        segment.scale.set(0, 0);
        FlxTween.tween(segment.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

        // Limit tail length
        if (demoTail.length > 3) {
            var oldSegment = demoTail.members[0];
            demoTail.remove(oldSegment, true);
            oldSegment.destroy();
        }
    }

    /**
     * Update player vision cone
     */
    private function updatePlayerVision():Void {
        if (visionCone != null && demoPlayer != null) {
            visionCone.x = demoPlayer.x - TILE_SIZE * 0.5;
            visionCone.y = demoPlayer.y - TILE_SIZE * 0.5;
        }
    }

    /**
     * Restart the simulation
     */
    private function restartSimulation():Void {
        // Stop current tweens
        FlxTween.cancelTweensOf(demoPlayer);

        // Clear tail
        demoTail.clear();

        // Reset player position
        var startX = (FlxG.width - (DEMO_WIDTH * TILE_SIZE)) * 0.5;
        var startY = 180;
        demoPlayer.setPosition(startX + 1 * TILE_SIZE + 3, startY + 1 * TILE_SIZE + 3);
        updatePlayerVision();

        // Start again
        isSimulating = false;
        new FlxTimer().start(1.0, function(timer) {
            startDemoSimulation();
        });
    }

    /**
     * Launch the full game with specified difficulty
     */
    private function launchGame(difficulty:MazeDifficulty):Void {
        trace('Launching Stealth Maze with difficulty: $difficulty');

        // Stop simulation
        isSimulating = false;
        if (demoTimer != null) {
            demoTimer.cancel();
        }
        FlxTween.cancelTweensOf(demoPlayer);

        // Launch game
        FlxG.switchState(new StealthMazeGameState(difficulty));
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle input
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new MainMenuState());
        }

        // Easter egg: click player to add tail
        if (FlxG.mouse.justPressed) {
            var mousePoint = FlxG.mouse.getPosition();
            if (demoPlayer != null && demoPlayer.overlapsPoint(mousePoint)) {
                addTailSegment();
            }
        }
    }

    override function destroy():Void {
        isSimulating = false;

        if (demoTimer != null) {
            demoTimer.cancel();
            demoTimer = null;
        }

        FlxTween.cancelTweensOf(demoPlayer);

        // Clear all groups
        if (demoMaze != null) demoMaze.clear();
        if (demoEnemies != null) demoEnemies.clear();
        if (demoCollectibles != null) demoCollectibles.clear();
        if (demoClosets != null) demoClosets.clear();
        if (demoTail != null) demoTail.clear();
        if (enemyVisionCones != null) enemyVisionCones.clear();
        if (launchButtons != null) launchButtons.clear();

        super.destroy();
    }
}
