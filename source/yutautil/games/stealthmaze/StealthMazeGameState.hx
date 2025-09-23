package yutautil.games.stealthmaze;

import backend.MusicBeatState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.MainMenuState;
import yutautil.games.stealthmaze.backend.MazeData.MazeDifficulty;
import yutautil.games.stealthmaze.backend.MazeData.MazeFloor;
import yutautil.games.stealthmaze.backend.MazeData;
import yutautil.games.stealthmaze.backend.MazeGenerator;
import yutautil.games.stealthmaze.backend.MazePathfinder;
import yutautil.games.stealthmaze.objects.MazeEnemy;
import yutautil.games.stealthmaze.objects.MazeObjects.MazeCloset;
import yutautil.games.stealthmaze.objects.MazeObjects.MazeCollectible;
import yutautil.games.stealthmaze.objects.MazeObjects.MazeExit;
import yutautil.games.stealthmaze.objects.MazePlayer;

/**
 * Game state enum for stealth maze
 */
enum StealthMazeGameStateType {
    PLAYING;
    PAUSED;
    WIN;
    LOSE;
}

/**
 * Main game state for the stealth maze game
 */
class StealthMazeGameState extends MusicBeatState {

    // Singleton player instance - only one can exist
    private static var singletonPlayer:MazePlayer = null;

    // Game data
    private var mazeData:MazeData;
    private var currentFloor:MazeFloor;

    // Game objects
    private var player:MazePlayer;
    private var enemies:FlxTypedGroup<MazeEnemy>;
    private var collectibles:FlxTypedGroup<MazeCollectible>;
    private var closets:FlxTypedGroup<MazeCloset>;
    private var exits:FlxTypedGroup<MazeExit>;

    // Visual elements
    private var mazeSprites:FlxTypedGroup<FlxSprite>;
    private var uiGroup:FlxTypedGroup<FlxSprite>;
    private var gameCamera:FlxCamera;
    private var uiCamera:FlxCamera;

    // UI elements
    private var statusText:FlxText;
    private var objectiveText:FlxText;
    private var floorText:FlxText;
    private var pauseButton:FlxButton;

    // Game state
    private var gameState:StealthMazeGameStateType = PLAYING;
    private var isPaused:Bool = false;
    private var hasRedObjective:Bool = false;
    private var score:Int = 0;
    private var currentPlayerCloset:MazeCloset = null;

    // Settings
    private var difficulty:MazeDifficulty = MEDIUM;
    private var tileSize:Int = 32;

    public function new(?difficulty:MazeDifficulty) {
        super();
        if (difficulty != null) {
            this.difficulty = difficulty;
        }
    }

    override function create():Void {
        super.create();

        // Set up cameras
        setupCameras();

        // Generate maze
        generateMaze();

        // Create game objects
        createGameObjects();

        // Set up UI
        setupUI();

        // Start game
        startGame();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Playing Stealth Maze", "Difficulty: " + Std.string(difficulty));
        #end
    }

    /**
     * Set up camera system
     */
    private function setupCameras():Void {
        // Game camera follows player
        gameCamera = FlxG.camera;
        gameCamera.bgColor = FlxColor.fromRGB(20, 20, 25);

        // UI camera for fixed UI elements
        uiCamera = new FlxCamera();
        uiCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(uiCamera, false);
    }

    /**
     * Generate the maze
     */
    private function generateMaze():Void {
        mazeData = MazeGenerator.generateMaze(difficulty);
        currentFloor = mazeData.getCurrentFloor();

        if (currentFloor == null) {
            throw "Failed to generate maze floor";
        }
    }

    /**
     * Create all game objects
     */
    private function createGameObjects():Void {
        // Initialize groups
        mazeSprites = new FlxTypedGroup<FlxSprite>();
        enemies = new FlxTypedGroup<MazeEnemy>();
        collectibles = new FlxTypedGroup<MazeCollectible>();
        closets = new FlxTypedGroup<MazeCloset>();
        exits = new FlxTypedGroup<MazeExit>();
        uiGroup = new FlxTypedGroup<FlxSprite>();

        add(mazeSprites);

        // Create maze visual representation
        createMazeSprites();

        // Create player
        createPlayer();
        add(player);
        add(player.visionCone);

        // Create enemies
        createEnemies();
        add(enemies);

        // Add enemy vision cones
        for (enemy in enemies) {
            add(enemy.visionCone);
        }

        // Create collectibles
        createCollectibles();
        add(collectibles);

        // Create closets
        createClosets();
        add(closets);

        // Create exits
        createExits();
        add(exits);

        // Add UI group to UI camera
        add(uiGroup);
        uiGroup.cameras = [uiCamera];
    }

    /**
     * Create room visual sprites and collision boundaries
     */
    private function createMazeSprites():Void {
        // Draw room floors and walls
        for (room in currentFloor.rooms) {
            // Room floor
            var floorSprite = new FlxSprite(room.bounds.x, room.bounds.y);
            floorSprite.makeGraphic(Std.int(room.bounds.width), Std.int(room.bounds.height), FlxColor.fromRGB(45, 40, 35));
            mazeSprites.add(floorSprite);

            // Room walls
            for (wall in room.walls) {
                var wallSprite = new FlxSprite(wall.x, wall.y);
                wallSprite.makeGraphic(Std.int(wall.width), Std.int(wall.height), FlxColor.GRAY);
                mazeSprites.add(wallSprite);
            }

            // Room obstacles (furniture)
            for (obstacle in room.obstacles) {
                var obstacleSprite = new FlxSprite(obstacle.x, obstacle.y);
                obstacleSprite.makeGraphic(Std.int(obstacle.width), Std.int(obstacle.height), FlxColor.BROWN);
                mazeSprites.add(obstacleSprite);
            }

            // Doors - render based on open/closed state
            for (door in room.doors) {
                var doorSprite = new FlxSprite(door.bounds.x, door.bounds.y);
                var doorColor = door.isOpen ? FlxColor.GREEN : FlxColor.RED;
                if (door.requiresKey) {
                    doorColor = door.isOpen ? FlxColor.YELLOW : FlxColor.ORANGE; // Key doors are different colors
                }
                doorSprite.makeGraphic(Std.int(door.bounds.width), Std.int(door.bounds.height), doorColor);
                mazeSprites.add(doorSprite);
            }
        }

        // Draw stairs - All stairs are green
        for (stair in currentFloor.stairsUp) {
            var stairSprite = new FlxSprite(stair.x - 15, stair.y - 15);
            stairSprite.makeGraphic(30, 30, FlxColor.GREEN);
            mazeSprites.add(stairSprite);
        }

        for (stair in currentFloor.stairsDown) {
            var stairSprite = new FlxSprite(stair.x - 15, stair.y - 15);
            stairSprite.makeGraphic(30, 30, FlxColor.GREEN);
            mazeSprites.add(stairSprite);
        }
    }

    /**
     * Create player - manages singleton instance
     */
    private function createPlayer():Void {
        var startPos = currentFloor.playerStartPosition;

        // Use singleton player or create new one
        if (singletonPlayer == null) {
            singletonPlayer = new MazePlayer(startPos.x, startPos.y);
        } else {
            // Reuse existing player but update position
            singletonPlayer.setPosition(startPos.x, startPos.y);
        }

        player = singletonPlayer;
        player.facingDirection = startPos.direction;
        player.currentFloor = currentFloor; // Set floor reference for collision detection

        // Ensure player is on screen
        if (startPos.x < 50) startPos.x = 50;
        if (startPos.y < 50) startPos.y = 50;
        player.setPosition(startPos.x, startPos.y);

        // Set up camera to follow player
        gameCamera.follow(player, TOPDOWN, 1);
        gameCamera.setScrollBounds(0, currentFloor.bounds.width, 0, currentFloor.bounds.height);
    }

    /**
     * Create enemies
     */
    private function createEnemies():Void {
        var pathfinder = new MazePathfinder(currentFloor);

        for (spawn in currentFloor.enemySpawns) {
            var enemy = new MazeEnemy(spawn.position.x, spawn.position.y, spawn);
            enemy.targetPlayer = player;
            enemy.currentFloor = currentFloor; // Set floor reference for door interaction
            enemy.setMazeData(currentFloor, pathfinder);
            enemies.add(enemy);
        }
    }

    /**
     * Create collectibles
     */
    private function createCollectibles():Void {
        for (collectible in currentFloor.collectibles) {
            var sprite = new MazeCollectible(collectible.position.x, collectible.position.y, collectible.type);
            collectibles.add(sprite);
        }
    }

    /**
     * Create closets in appropriate rooms
     */
    private function createClosets():Void {
        // Add closets to bedrooms and closet rooms
        for (room in currentFloor.rooms) {
            if (room.type == BEDROOM || room.type == CLOSET_ROOM) {
                var closetType = Math.random() < 0.3 ? CLOSET_1P : CLOSET_2P;
                var point = room.getRandomPointInRoom();
                var closet = new MazeCloset(point.x, point.y, closetType);
                closets.add(closet);
            }
        }
    }

    /**
     * Create exits on the ground floor
     */
    private function createExits():Void {
        // Only create exits on ground floor
        if (currentFloor.floorIndex == 0) {
            // Find the living room or hallway for main exit
            var exitRoom = currentFloor.getRandomRoomOfType(LIVING_ROOM);
            if (exitRoom == null) exitRoom = currentFloor.getRandomRoomOfType(HALLWAY);
            if (exitRoom == null) exitRoom = currentFloor.getRandomRoom();

            if (exitRoom != null) {
                var exitPoint = exitRoom.getRandomPointInRoom();
                var exit = new MazeExit(exitPoint.x, exitPoint.y, true);
                exits.add(exit);
            }
        }
    }

    /**
     * Set up UI elements
     */
    private function setupUI():Void {
        // Status text
        statusText = new FlxText(10, 10, 300, "", 16);
        statusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
        uiGroup.add(statusText);

        // Objective text
        objectiveText = new FlxText(10, 40, 400, "Find the RED square to activate the exit!", 14);
        objectiveText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.YELLOW, LEFT);
        uiGroup.add(objectiveText);

        // Floor indicator
        floorText = new FlxText(FlxG.width - 200, 10, 190, "", 14);
        floorText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN, RIGHT);
        uiGroup.add(floorText);

        // Pause button
        pauseButton = new FlxButton(FlxG.width - 100, 40, "Pause", pauseGame);
        uiGroup.add(pauseButton);

        updateUI();
    }

    /**
     * Start the game
     */
    private function startGame():Void {
        gameState = PLAYING;
        isPaused = false;
        hasRedObjective = false;
        score = 0;
        updateUI();
    }

    /**
     * Update UI elements
     */
    private function updateUI():Void {
        statusText.text = 'Score: $score | Tail: ${player != null ? player.tailSegments.length : 0}';

        if (!hasRedObjective) {
            objectiveText.text = "Find the RED square to activate the exit!";
            objectiveText.color = FlxColor.YELLOW;
        } else {
            objectiveText.text = "RED square collected! Find the GREEN exit!";
            objectiveText.color = FlxColor.GREEN;
        }

        floorText.text = 'Floor ${mazeData.currentFloor + 1}/${mazeData.getFloorCount()}';
    }

    override function update(elapsed:Float):Void {
        if (gameState != PLAYING || isPaused) {
            super.update(elapsed);
            return;
        }

        super.update(elapsed);

        // Check input
        handleInput();

        // Update game logic
        updateGameLogic();

        // Check win/lose conditions
        checkGameConditions();

        // Update UI
        updateUI();
    }

    /**
     * Handle player input
     */
    private function handleInput():Void {
        // Pause
        if (controls.PAUSE || FlxG.keys.justPressed.ESCAPE) {
            pauseGame();
        }

        // Interact with closets
        if (FlxG.keys.justPressed.E || FlxG.keys.justPressed.SPACE) {
            handleClosetInteraction();
            handleStairInteraction();
        }

        // Debug keys
        #if debug
        if (FlxG.keys.justPressed.R) {
            // Restart floor
            FlxG.resetState();
        }
        if (FlxG.keys.justPressed.N) {
            // Next floor (debug)
            if (mazeData.nextFloor()) {
                loadCurrentFloor();
            }
        }
        #end
    }

    /**
     * Handle closet interaction
     */
    private function handleClosetInteraction():Void {
        if (currentPlayerCloset != null) {
            // Exit closet
            currentPlayerCloset.exitPlayer(player);
            currentPlayerCloset = null;
        } else {
            // Try to enter nearby closet
            for (closet in closets) {
                if (closet.isPlayerInRange(player)) {
                    if (closet.hidePlayer(player)) {
                        currentPlayerCloset = closet;
                        break;
                    }
                }
            }
        }
    }

    /**
     * Handle stair interaction
     */
    private function handleStairInteraction():Void {
        var playerCenter = new FlxPoint(player.x + player.width/2, player.y + player.height/2);

        // Check stairs up
        for (stair in currentFloor.stairsUp) {
            var distance = playerCenter.distanceTo(stair);
            if (distance < 40) { // Interaction range
                // Go to next floor
                if (mazeData.currentFloor < mazeData.floors.length - 1) {
                    mazeData.currentFloor++;
                    loadCurrentFloor();

                    // Position player near stairs down on new floor
                    var newFloor = mazeData.getCurrentFloor();
                    if (newFloor.stairsDown.length > 0) {
                        var stairDown = newFloor.stairsDown[0];
                        player.x = stairDown.x;
                        player.y = stairDown.y + 50; // Slightly below stairs
                    }
                }
                return;
            }
        }

        // Check stairs down
        for (stair in currentFloor.stairsDown) {
            var distance = playerCenter.distanceTo(stair);
            if (distance < 40) { // Interaction range
                // Go to previous floor
                if (mazeData.currentFloor > 0) {
                    mazeData.currentFloor--;
                    loadCurrentFloor();

                    // Position player near stairs up on new floor
                    var newFloor = mazeData.getCurrentFloor();
                    if (newFloor.stairsUp.length > 0) {
                        var stairUp = newFloor.stairsUp[0];
                        player.x = stairUp.x;
                        player.y = stairUp.y - 50; // Slightly above stairs
                    }
                }
                return;
            }
        }
    }

    /**
     * Update game logic
     */
    private function updateGameLogic():Void {
        // Update closet prompts
        updateClosetPrompts();

        // Check collectible pickups
        FlxG.overlap(player, collectibles, collectCollectible);

        // Check enemy collisions
        if (!player.isHidden) {
            FlxG.overlap(player, enemies, enemyCaughtPlayer);
        }

        // Check exit usage
        FlxG.overlap(player, exits, checkExitUsage);
    }

    /**
     * Update closet interaction prompts
     */
    private function updateClosetPrompts():Void {
        for (closet in closets) {
            if (closet.isPlayerInRange(player)) {
                closet.showPrompt();
            } else {
                closet.hidePrompt();
            }
        }
    }

    /**
     * Handle collectible pickup
     */
    private function collectCollectible(player:MazePlayer, collectible:MazeCollectible):Void {
        if (collectible.isCollected) return;

        collectible.collect();

        switch (collectible.collectibleType) {
            case RED_OBJECTIVE:
                hasRedObjective = true;
                // Activate all real exits
                for (exit in exits) {
                    exit.activate();
                }

                // Add red tail segment
                var segment = player.addTailSegment(RED_OBJECTIVE);
                if (segment != null) {
                    add(segment);
                }

            case GOLDEN_BONUS:
                score += 100;

                // Add golden tail segment
                var segment = player.addTailSegment(GOLDEN_BONUS);
                if (segment != null) {
                    add(segment);
                }
        }
    }

    /**
     * Handle enemy catching player
     */
    private function enemyCaughtPlayer(player:MazePlayer, enemy:MazeEnemy):Void {
        if (gameState != PLAYING) return;

        // Player caught!
        gameState = LOSE;

        // Stop all movement
        player.velocity.set(0, 0);
        enemy.velocity.set(0, 0);

        // Flash screen red
        var flash = new FlxSprite();
        flash.makeGraphic(FlxG.width, FlxG.height, FlxColor.RED);
        flash.alpha = 0.5;
        flash.cameras = [uiCamera];
        add(flash);

        FlxTween.tween(flash, {alpha: 0}, 1.0, {
            onComplete: function(tween) {
                remove(flash);
                flash.destroy();
            }
        });

        // Show game over
        showGameOver(false);
    }

    /**
     * Check exit usage
     */
    private function checkExitUsage(player:MazePlayer, exit:MazeExit):Void {
        if (gameState != PLAYING) return;

        if (FlxG.keys.justPressed.E || FlxG.keys.justPressed.SPACE) {
            if (exit.useExit(player)) {
                // Successfully used exit
                if (mazeData.nextFloor()) {
                    // Go to next floor
                    loadNextFloor();
                } else {
                    // Completed all floors!
                    gameState = WIN;
                    showGameOver(true);
                }
            }
        }
    }

    /**
     * Load next floor
     */
    private function loadNextFloor():Void {
        // Clean up current floor
        cleanupCurrentFloor();

        // Load new floor
        currentFloor = mazeData.getCurrentFloor();

        // Recreate everything for new floor
        createGameObjects();

        // Reset player state but keep tail
        var startPos = currentFloor.playerStartPosition;
        player.x = startPos.x;
        player.y = startPos.y;
        player.facingDirection = startPos.direction;
        player.unhide();

        hasRedObjective = false; // Must find new red objective
        currentPlayerCloset = null;

        updateUI();
    }

    /**
     * Clean up current floor objects
     */
    private function cleanupCurrentFloor():Void {
        mazeSprites.clear();
        enemies.clear();
        collectibles.clear();
        closets.clear();
        exits.clear();
    }

    /**
     * Check win/lose conditions
     */
    private function checkGameConditions():Void {
        // Game over conditions are handled in specific collision functions
    }

    /**
     * Pause/unpause game
     */
    private function pauseGame():Void {
        isPaused = !isPaused;

        if (isPaused) {
            gameState = PAUSED;
            pauseButton.text = "Resume";
            // Show pause overlay
            var pauseOverlay = new FlxSprite();
            pauseOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.7));
            pauseOverlay.cameras = [uiCamera];
            uiGroup.add(pauseOverlay);

            var pauseText = new FlxText(0, FlxG.height/2 - 20, FlxG.width, "PAUSED", 32);
            pauseText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
            pauseText.cameras = [uiCamera];
            uiGroup.add(pauseText);
        } else {
            gameState = PLAYING;
            pauseButton.text = "Pause";
            // Remove pause overlay (last 2 items added)
            uiGroup.remove(uiGroup.members[uiGroup.members.length - 1], true);
            uiGroup.remove(uiGroup.members[uiGroup.members.length - 1], true);
        }
    }

    /**
     * Show game over screen
     */
    private function showGameOver(won:Bool):Void {
        var overlay = new FlxSprite();
        overlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.8));
        overlay.cameras = [uiCamera];
        add(overlay);

        var resultText = new FlxText(0, FlxG.height/2 - 60, FlxG.width, "", 32);
        resultText.setFormat(Paths.font("vcr.ttf"), 32, won ? FlxColor.GREEN : FlxColor.RED, CENTER);
        resultText.text = won ? "YOU ESCAPED!" : "CAUGHT!";
        resultText.cameras = [uiCamera];
        add(resultText);

        var scoreText = new FlxText(0, FlxG.height/2 - 20, FlxG.width, 'Final Score: $score', 20);
        scoreText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
        scoreText.cameras = [uiCamera];
        add(scoreText);

        var restartButton = new FlxButton(FlxG.width/2 - 60, FlxG.height/2 + 20, "Play Again", function() {
            FlxG.resetState();
        });
        restartButton.cameras = [uiCamera];
        add(restartButton);

        var menuButton = new FlxButton(FlxG.width/2 - 60, FlxG.height/2 + 60, "Main Menu", function() {
            FlxG.switchState(new MainMenuState());
        });
        menuButton.cameras = [uiCamera];
        add(menuButton);
    }

    /**
     * Load current floor (used for floor transitions)
     */
    private function loadCurrentFloor():Void {
        cleanupCurrentFloor();
        currentFloor = mazeData.getCurrentFloor();
        createGameObjects();

        var startPos = currentFloor.playerStartPosition;
        player.x = startPos.x;
        player.y = startPos.y;
        player.resetPlayer();

        hasRedObjective = false;
        currentPlayerCloset = null;
        updateUI();
    }

    override function destroy():Void {
        if (player != null) {
            player.destroy();
        }

        super.destroy();
    }
}
