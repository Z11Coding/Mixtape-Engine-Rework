package states.editors;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import games.uno.beta.UnoBetaState;
import objects.Alphabet;
import states.MainMenuState;
import yutautil.games.stealthmaze.StealthMazeGameState;

/**
 * Minigame Menu for the Master Editor Menu
 * Provides access to all minigames with previews and launch options
 */
class MinigameMenuState extends MusicBeatState {

    // Game discovery and management
    private var availableGames:Array<MinigameInfo> = [];
    private var currentGameIndex:Int = 0;

    // UI elements
    private var titleText:FlxText;
    private var gameNameText:FlxText;
    private var gameDescriptionText:FlxText;
    private var previewContainer:FlxTypedGroup<FlxSprite>;
    private var menuItems:FlxTypedGroup<Alphabet>;
    private var previewBackground:FlxSprite;
    private var navigationHint:FlxText;
    private var launchButtons:FlxTypedGroup<FlxButton>;

    // Preview animation
    private var previewTimer:FlxTimer;
    private var previewElements:Array<FlxSprite> = [];

    override function create():Void {
        super.create();

        // Set background
        FlxG.camera.bgColor = FlxColor.fromRGB(20, 20, 30);

        // Discover available games
        discoverGames();

        // Create UI elements
        createUI();

        // Start preview animation
        startPreviewAnimation();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Minigame Menu", "Browsing available games");
        #end
    }

    /**
     * Discover all available minigames in the games folder
     */
    private function discoverGames():Void {
        // Pong game
        availableGames.push({
            name: "Pong",
            displayName: "Classic Pong",
            description: "Classic arcade game with AI opponents\n• Player vs AI, Two-Player, AI vs AI modes\n• Multiple difficulty levels\n• Customizable paddle and ball physics\n• Sound effects and visual feedback",
            folder: "yutautil.games.pong",
            launchClass: "yutautil.games.pong.PongGameState",
            minigameLaunchMethod: null, // Pong doesn't have minigame state yet
            icon: FlxColor.WHITE,
            previewElements: createPongPreview
        });

        // Stealth Maze game
        availableGames.push({
            name: "StealthMaze",
            displayName: "Stealth Maze",
            description: "Navigate randomly generated mazes while avoiding enemies\n• Procedurally generated mazes\n• AI enemies with vision cones\n• Stealth mechanics and hiding spots\n• Multiple difficulty levels and floors",
            folder: "yutautil.games.stealthmaze",
            launchClass: "yutautil.games.stealthmaze.StealthMazeGameState",
            minigameLaunchMethod: "yutautil.games.stealthmaze.StealthMazeLauncher.launchMinigame",
            icon: FlxColor.CYAN,
            previewElements: createStealthMazePreview
        });

        // UNO game
        availableGames.push({
            name: "UNO",
            displayName: "UNO Card Game",
            description: "Complete UNO implementation with AI opponents\n• Official UNO rules and special cards\n• CPU players with different difficulty levels\n• Custom game modes and house rules\n• Multiplayer support",
            folder: "games.uno",
            launchClass: "games.uno.UnoTestState",
            minigameLaunchMethod: null, // UNO doesn't have minigame state
            icon: FlxColor.RED,
            previewElements: createUnoPreview
        });

        // Match 3 game
        availableGames.push({
            name: "Match3",
            displayName: "Match 3 Puzzle",
            description: "Colorful match-3 puzzle game with objectives\n• Multiple game modes and objectives\n• Special pieces and power-ups\n• CPU opponent for VS mode\n• Cascading combos and scoring",
            folder: "games.match3",
            launchClass: "games.match3.Match3TestState",
            minigameLaunchMethod: null, // Match3 doesn't have minigame state
            icon: FlxColor.MAGENTA,
            previewElements: createMatch3Preview
        });

        if (availableGames.length == 0) {
            // Fallback if no games found
            availableGames.push({
                name: "NoGames",
                displayName: "No Games Found",
                description: "No minigames were found in the games folder.\nPlease check that the games are properly installed.",
                folder: "",
                launchClass: "",
                minigameLaunchMethod: null,
                icon: FlxColor.GRAY,
                previewElements: createNoGamesPreview
            });
        }
    }

    /**
     * Create UI elements
     */
    private function createUI():Void {
        // Title
        titleText = new FlxText(0, 20, FlxG.width, "MINIGAME MENU", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        // Game list (left side)
        var listX = 50;
        var listY = 100;

        menuItems = new FlxTypedGroup<Alphabet>();
        add(menuItems);

        for (i in 0...availableGames.length) {
            var game = availableGames[i];
            var menuItem = new Alphabet(listX, listY + (i * 20), game.displayName, true);
            menuItem.isMenuItem = true;
            menuItem.targetY = i;
            menuItem.ID = i;
            menuItems.add(menuItem);
        }

        // Preview area (right side)
        var previewX = FlxG.width * 0.5;
        var previewY = 100;
        var previewWidth = FlxG.width * 0.45;
        var previewHeight = 300;

        previewBackground = new FlxSprite(previewX, previewY);
        previewBackground.makeGraphic(Std.int(previewWidth), Std.int(previewHeight), FlxColor.fromRGB(30, 30, 40));
        add(previewBackground);

        previewContainer = new FlxTypedGroup<FlxSprite>();
        add(previewContainer);

        // Game info text
        gameNameText = new FlxText(previewX + 10, previewY + 10, previewWidth - 20, "", 20);
        gameNameText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        gameNameText.borderSize = 1;
        add(gameNameText);

        gameDescriptionText = new FlxText(previewX + 10, previewY + 50, previewWidth - 20, "", 14);
        gameDescriptionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
        gameDescriptionText.borderSize = 1;
        add(gameDescriptionText);

        // Launch buttons
        launchButtons = new FlxTypedGroup<FlxButton>();
        add(launchButtons);

        var buttonY = previewY + previewHeight + 20;

        var previewButton = new FlxButton(previewX, buttonY, "Preview", launchPreview);
        previewButton.setGraphicSize(120, 35);
        previewButton.updateHitbox();
        previewButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(previewButton);

        var playButton = new FlxButton(previewX + 130, buttonY, "Play Full Game", launchFullGame);
        playButton.setGraphicSize(120, 35);
        playButton.updateHitbox();
        playButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(playButton);

        // Navigation hint
        navigationHint = new FlxText(0, FlxG.height - 60, FlxG.width,
            "Use ↑↓ arrows to select games | ENTER to launch | ESCAPE to return to Master Editor Menu", 14);
        navigationHint.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
        add(navigationHint);

        // Update display for first game
        updateGameDisplay();
    }

    /**
     * Update the display for the currently selected game
     */
    private function updateGameDisplay():Void {
        if (currentGameIndex >= availableGames.length) return;

        var game = availableGames[currentGameIndex];

        gameNameText.text = game.displayName;
        gameDescriptionText.text = game.description;

        // Clear previous preview elements
        previewContainer.clear();
        previewElements = [];

        // Create new preview elements
        if (game.previewElements != null) {
            game.previewElements();
        }

        // Update menu item highlighting
        for (i in 0...menuItems.length) {
            var item = menuItems.members[i];
            if (item != null) {
                item.alpha = (i == currentGameIndex) ? 1.0 : 0.6;
                item.color = (i == currentGameIndex) ? game.icon : FlxColor.WHITE;
            }
        }

        // Update button states
        var hasPreview = game.minigameLaunchMethod != null;
        var previewBtn = launchButtons.members[0];
        var playBtn = launchButtons.members[1];

        if (previewBtn != null) {
            previewBtn.visible = hasPreview;
            previewBtn.active = hasPreview;
        }

        if (playBtn != null) {
            playBtn.visible = game.launchClass != "";
            playBtn.active = game.launchClass != "";
        }
    }

    /**
     * Create Pong preview elements
     */
    private function createPongPreview():Void {
        var previewX = previewBackground.x + 20;
        var previewY = previewBackground.y + 120;

        // Create simple pong visualization
        var leftPaddle = new FlxSprite(previewX, previewY + 60);
        leftPaddle.makeGraphic(8, 60, FlxColor.WHITE);
        previewContainer.add(leftPaddle);
        previewElements.push(leftPaddle);

        var rightPaddle = new FlxSprite(previewX + 300, previewY + 40);
        rightPaddle.makeGraphic(8, 60, FlxColor.WHITE);
        previewContainer.add(rightPaddle);
        previewElements.push(rightPaddle);

        var ball = new FlxSprite(previewX + 150, previewY + 60);
        ball.makeGraphic(12, 12, FlxColor.WHITE);
        previewContainer.add(ball);
        previewElements.push(ball);

        // Animate paddles
        FlxTween.tween(leftPaddle, {y: leftPaddle.y - 20}, 1.5, {
            ease: FlxEase.sineInOut,
            type: PINGPONG
        });

        FlxTween.tween(rightPaddle, {y: rightPaddle.y + 20}, 1.2, {
            ease: FlxEase.sineInOut,
            type: PINGPONG
        });

        // Animate ball
        FlxTween.tween(ball, {x: ball.x - 100}, 1.0, {
            ease: FlxEase.sineInOut,
            type: PINGPONG
        });
    }

    /**
     * Create Stealth Maze preview elements
     */
    private function createStealthMazePreview():Void {
        var previewX = previewBackground.x + 20;
        var previewY = previewBackground.y + 120;
        var tileSize = 16;

        // Create mini maze
        var maze = [
            [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
            [1,0,0,0,1,0,0,2,0,0,1,0,0,0,1],
            [1,0,1,0,1,0,1,1,1,0,1,0,1,0,1],
            [1,0,1,0,0,0,0,0,0,0,0,0,1,0,1],
            [1,0,1,1,1,0,1,3,1,0,1,1,1,0,1],
            [1,0,0,0,0,0,1,0,1,0,0,0,0,0,1],
            [1,1,1,0,1,0,1,0,1,0,1,0,1,1,1],
            [1,0,0,0,1,0,0,0,0,0,1,0,0,0,1],
            [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
        ];

        for (y in 0...maze.length) {
            for (x in 0...maze[y].length) {
                var tile = maze[y][x];
                var posX = previewX + x * tileSize;
                var posY = previewY + y * tileSize;

                var sprite:FlxSprite = null;

                switch (tile) {
                    case 1: // Wall
                        sprite = new FlxSprite(posX, posY);
                        sprite.makeGraphic(tileSize, tileSize, FlxColor.GRAY);

                    case 0: // Floor
                        sprite = new FlxSprite(posX, posY);
                        sprite.makeGraphic(tileSize, tileSize, FlxColor.fromRGB(40, 40, 45));

                    case 2: // Collectible
                        sprite = new FlxSprite(posX, posY);
                        sprite.makeGraphic(tileSize, tileSize, FlxColor.fromRGB(40, 40, 45));
                        previewContainer.add(sprite);
                        previewElements.push(sprite);

                        var collectible = new FlxSprite(posX + 2, posY + 2);
                        collectible.makeGraphic(tileSize - 4, tileSize - 4, FlxColor.RED);
                        previewContainer.add(collectible);
                        previewElements.push(collectible);

                        FlxTween.tween(collectible, {y: collectible.y - 2}, 1.0, {
                            ease: FlxEase.sineInOut,
                            type: PINGPONG
                        });
                        continue;

                    case 3: // Enemy
                        sprite = new FlxSprite(posX, posY);
                        sprite.makeGraphic(tileSize, tileSize, FlxColor.fromRGB(40, 40, 45));
                        previewContainer.add(sprite);
                        previewElements.push(sprite);

                        var enemy = new FlxSprite(posX + 1, posY + 1);
                        enemy.makeGraphic(tileSize - 2, tileSize - 2, FlxColor.PURPLE);
                        previewContainer.add(enemy);
                        previewElements.push(enemy);
                        continue;
                }

                if (sprite != null) {
                    previewContainer.add(sprite);
                    previewElements.push(sprite);
                }
            }
        }

        // Add player
        var player = new FlxSprite(previewX + tileSize + 2, previewY + tileSize + 2);
        player.makeGraphic(tileSize - 4, tileSize - 4, FlxColor.CYAN);
        previewContainer.add(player);
        previewElements.push(player);
    }

    /**
     * Create UNO preview elements
     */
    private function createUnoPreview():Void {
        var previewX = previewBackground.x + 50;
        var previewY = previewBackground.y + 200;

        // Create card representations
        var cardColors = [FlxColor.RED, FlxColor.YELLOW, FlxColor.BLUE, FlxColor.GREEN];

        for (i in 0...4) {
            var card = new FlxSprite(previewX + i * 60, previewY);
            card.makeGraphic(50, 70, cardColors[i]);
            previewContainer.add(card);
            previewElements.push(card);

            // Add card border
            var border = new FlxSprite(card.x + 2, card.y + 2);
            border.makeGraphic(46, 66, FlxColor.BLACK);
            previewContainer.add(border);
            previewElements.push(border);

            // Add number
            var numberBg = new FlxSprite(card.x + 4, card.y + 4);
            numberBg.makeGraphic(42, 62, cardColors[i]);
            previewContainer.add(numberBg);
            previewElements.push(numberBg);

            // Animate cards
            FlxTween.tween(card, {y: card.y - 10}, 1.0 + i * 0.2, {
                ease: FlxEase.sineInOut,
                type: PINGPONG
            });
        }
    }

    /**
     * Create Match 3 preview elements
     */
    private function createMatch3Preview():Void {
        var previewX = previewBackground.x + 50;
        var previewY = previewBackground.y + 120;
        var pieceSize = 24;
        var colors = [FlxColor.RED, FlxColor.BLUE, FlxColor.GREEN, FlxColor.YELLOW, FlxColor.PURPLE, FlxColor.ORANGE];

        // Create 8x6 grid of pieces
        for (y in 0...6) {
            for (x in 0...8) {
                var piece = new FlxSprite(previewX + x * pieceSize, previewY + y * pieceSize);
                piece.makeGraphic(pieceSize - 2, pieceSize - 2, colors[FlxG.random.int(0, colors.length - 1)]);
                previewContainer.add(piece);
                previewElements.push(piece);

                // Random floating animation
                if (FlxG.random.bool(30)) {
                    FlxTween.tween(piece, {y: piece.y - 3}, FlxG.random.float(0.8, 1.5), {
                        ease: FlxEase.sineInOut,
                        type: PINGPONG,
                        startDelay: FlxG.random.float(0, 1)
                    });
                }
            }
        }
    }

    /**
     * Create "no games found" preview
     */
    private function createNoGamesPreview():Void {
        var previewX = previewBackground.x + 50;
        var previewY = previewBackground.y + 150;

        var sadFace = new FlxText(previewX, previewY, 200, ":(", 48);
        sadFace.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.GRAY, CENTER);
        previewContainer.add(sadFace);
        previewElements.push(sadFace);

        var message = new FlxText(previewX - 50, previewY + 60, 300, "No minigames found", 16);
        message.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, CENTER);
        previewContainer.add(message);
        previewElements.push(message);
    }

    /**
     * Start preview animation loop
     */
    private function startPreviewAnimation():Void {
        previewTimer = new FlxTimer().start(3.0, function(timer) {
            // Restart animations periodically
            updateGameDisplay();
        }, 0);
    }

    /**
     * Launch preview/minigame version
     */
    private function launchPreview():Void {
        if (currentGameIndex >= availableGames.length) return;

        var game = availableGames[currentGameIndex];
        if (game.minigameLaunchMethod == null) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));
        trace('Launching preview for: ${game.displayName}');

        // Use reflection to call the minigame launcher
        try {
            var parts = game.minigameLaunchMethod.split('.');
            var className = parts.slice(0, -1).join('.');
            var methodName = parts[parts.length - 1];

            var clazz = Type.resolveClass(className);
            if (clazz != null) {
                var method = Reflect.field(clazz, methodName);
                if (method != null) {
                    Reflect.callMethod(clazz, method, []);
                } else {
                    trace('Method not found: $methodName');
                    fallbackLaunch(game);
                }
            } else {
                trace('Class not found: $className');
                fallbackLaunch(game);
            }
        } catch (e:Dynamic) {
            trace('Error launching preview: $e');
            fallbackLaunch(game);
        }
    }

    /**
     * Launch full game version
     */
    private function launchFullGame():Void {
        if (currentGameIndex >= availableGames.length) return;

        var game = availableGames[currentGameIndex];
        if (game.launchClass == "") {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            return;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));
        trace('Launching full game: ${game.displayName}');

        fallbackLaunch(game);
    }

    /**
     * Fallback launch method using class resolution
     */
    private function fallbackLaunch(game:MinigameInfo):Void {
        try {
            var stateClass = Type.resolveClass(game.launchClass);
            if (stateClass != null) {
                var state = Type.createInstance(stateClass, []);
                FlxG.switchState(state);
            } else {
                trace('Could not resolve class: ${game.launchClass}');
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
        } catch (e:Dynamic) {
            trace('Error launching game: $e');
            FlxG.sound.play(Paths.sound('cancelMenu'));
        }
    }

    /**
     * Change selected game
     */
    private function changeSelection(change:Int):Void {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        currentGameIndex = FlxMath.wrap(currentGameIndex + change, 0, availableGames.length - 1);
        updateGameDisplay();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle input
        if (controls.UI_UP_P) {
            changeSelection(-1);
        }
        if (controls.UI_DOWN_P) {
            changeSelection(1);
        }

        if (controls.ACCEPT) {
            launchFullGame();
        }

        if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new MasterEditorMenu());
        }

        // Preview launch with P key
        if (FlxG.keys.justPressed.P) {
            launchPreview();
        }
    }

    override function destroy():Void {
        if (previewTimer != null) {
            previewTimer.cancel();
            previewTimer = null;
        }

        // Clear preview elements
        previewElements = [];

        super.destroy();
    }
}

/**
 * Information about a discovered minigame
 */
typedef MinigameInfo = {
    name:String,
    displayName:String,
    description:String,
    folder:String,
    launchClass:String,
    minigameLaunchMethod:Null<String>,
    icon:FlxColor,
    previewElements:Null<Void->Void>
}
