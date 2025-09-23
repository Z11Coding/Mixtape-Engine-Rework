package yutautil.games.pong;

import backend.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import states.MainMenuState;
import yutautil.games.pong.backend.PongGame.PongGameMode;
import yutautil.games.pong.backend.PongPaddle.PongAIDifficulty;

/**
 * Minigame preview state for Pong
 * Shows animated demo and launch options
 */
class PongMinigameState extends MusicBeatState {

    // Demo elements
    private var demoLeftPaddle:FlxSprite;
    private var demoRightPaddle:FlxSprite;
    private var demoBall:FlxSprite;
    private var demoField:FlxSprite;
    private var scoreTextLeft:FlxText;
    private var scoreTextRight:FlxText;
    private var centerLine:FlxSprite;

    // UI elements
    private var titleText:FlxText;
    private var descriptionText:FlxText;
    private var launchButtons:FlxTypedGroup<FlxButton>;
    private var backButton:FlxButton;

    // Animation state
    private var ballVelocity:FlxPoint;
    private var leftScore:Int = 0;
    private var rightScore:Int = 0;
    private var gameTimer:FlxTimer;

    override function create():Void {
        super.create();

        // Set background
        FlxG.cameras.bgColor = FlxColor.fromRGB(10, 10, 15);

        // Initialize ball velocity
        ballVelocity = new FlxPoint(200, 150);

        // Create visual elements
        createTitle();
        createDemoField();
        createUI();

        // Start demo animation
        startDemo();

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Pong Preview", "Viewing classic arcade game");
        #end
    }

    /**
     * Create title and description
     */
    private function createTitle():Void {
        titleText = new FlxText(0, 20, FlxG.width, "CLASSIC PONG", 32);
        titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 2;
        add(titleText);

        descriptionText = new FlxText(20, 70, FlxG.width - 40,
            "The original arcade classic! Control paddles and bounce the ball past your opponent.\n" +
            "• Player vs AI, Two-Player, or AI vs AI modes\n" +
            "• Multiple difficulty levels with smart AI\n" +
            "• Realistic physics and collision detection\n" +
            "• Customizable game settings and controls", 14);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
        descriptionText.borderSize = 1;
        add(descriptionText);
    }

    /**
     * Create the demo Pong field
     */
    private function createDemoField():Void {
        var fieldX = (FlxG.width - 400) * 0.5;
        var fieldY = 180;
        var fieldWidth = 400;
        var fieldHeight = 200;

        // Playing field background
        demoField = new FlxSprite(fieldX, fieldY);
        demoField.makeGraphic(fieldWidth, fieldHeight, FlxColor.fromRGB(20, 20, 20));
        add(demoField);

        // Center line
        centerLine = new FlxSprite(fieldX + fieldWidth * 0.5 - 1, fieldY);
        centerLine.makeGraphic(2, fieldHeight, FlxColor.WHITE);
        add(centerLine);

        // Left paddle (Player)
        demoLeftPaddle = new FlxSprite(fieldX + 20, fieldY + fieldHeight * 0.5 - 30);
        demoLeftPaddle.makeGraphic(8, 60, FlxColor.WHITE);
        add(demoLeftPaddle);

        // Right paddle (AI)
        demoRightPaddle = new FlxSprite(fieldX + fieldWidth - 28, fieldY + fieldHeight * 0.5 - 30);
        demoRightPaddle.makeGraphic(8, 60, FlxColor.WHITE);
        add(demoRightPaddle);

        // Ball
        demoBall = new FlxSprite(fieldX + fieldWidth * 0.5 - 6, fieldY + fieldHeight * 0.5 - 6);
        demoBall.makeGraphic(12, 12, FlxColor.WHITE);
        add(demoBall);

        // Score displays
        scoreTextLeft = new FlxText(fieldX + fieldWidth * 0.25 - 25, fieldY - 40, 50, "0", 24);
        scoreTextLeft.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        add(scoreTextLeft);

        scoreTextRight = new FlxText(fieldX + fieldWidth * 0.75 - 25, fieldY - 40, 50, "0", 24);
        scoreTextRight.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        add(scoreTextRight);
    }

    /**
     * Create UI elements
     */
    private function createUI():Void {
        launchButtons = new FlxTypedGroup<FlxButton>();

        var buttonY = FlxG.height - 100;
        var buttonSpacing = 160;
        var startX = (FlxG.width - (buttonSpacing * 3 - 40)) * 0.5;

        // Player vs AI button
        var vsAIButton = new FlxButton(startX, buttonY, "Player vs AI", function() {
            launchPong(PLAYER_VS_AI);
        });
        vsAIButton.setGraphicSize(140, 35);
        vsAIButton.updateHitbox();
        vsAIButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(vsAIButton);

        // Two Player button
        var twoPlayerButton = new FlxButton(startX + buttonSpacing, buttonY, "Two Player", function() {
            launchPong(TWO_PLAYER);
        });
        twoPlayerButton.setGraphicSize(140, 35);
        twoPlayerButton.updateHitbox();
        twoPlayerButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(twoPlayerButton);

        // AI vs AI button
        var aiVsAIButton = new FlxButton(startX + buttonSpacing * 2, buttonY, "AI vs AI Demo", function() {
            launchPong(AI_VS_AI);
        });
        aiVsAIButton.setGraphicSize(140, 35);
        aiVsAIButton.updateHitbox();
        aiVsAIButton.label.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.BLACK, CENTER);
        launchButtons.add(aiVsAIButton);

        add(launchButtons);

        // Back button
        backButton = new FlxButton(20, FlxG.height - 50, "Back to Menu", function() {
            FlxG.switchState(new MainMenuState());
        });
        backButton.setGraphicSize(120, 30);
        backButton.updateHitbox();
        backButton.label.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.BLACK, CENTER);
        add(backButton);

        // Controls hint
        var controlsText = new FlxText(20, FlxG.height - 80, FlxG.width - 40,
            "Player 1: W/S keys | Player 2: ↑/↓ arrows | ENTER launches game", 12);
        controlsText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, CENTER);
        add(controlsText);
    }

    /**
     * Start the demo animation
     */
    private function startDemo():Void {
        gameTimer = new FlxTimer().start(0.016, updateDemoGame, 0); // ~60 FPS
    }

    /**
     * Update demo game simulation
     */
    private function updateDemoGame(timer:FlxTimer):Void {
        var elapsed = 0.016;

        // Move ball
        demoBall.x += ballVelocity.x * elapsed;
        demoBall.y += ballVelocity.y * elapsed;

        // Ball collision with top/bottom walls
        if (demoBall.y <= demoField.y || demoBall.y + demoBall.height >= demoField.y + demoField.height) {
            ballVelocity.y = -ballVelocity.y;
            demoBall.y = Math.max(demoField.y, Math.min(demoBall.y, demoField.y + demoField.height - demoBall.height));
        }

        // Ball collision with paddles
        if (demoBall.overlaps(demoLeftPaddle)) {
            ballVelocity.x = Math.abs(ballVelocity.x);
            ballVelocity.y += FlxG.random.float(-50, 50); // Add some randomness
            demoBall.x = demoLeftPaddle.x + demoLeftPaddle.width;
        }

        if (demoBall.overlaps(demoRightPaddle)) {
            ballVelocity.x = -Math.abs(ballVelocity.x);
            ballVelocity.y += FlxG.random.float(-50, 50); // Add some randomness
            demoBall.x = demoRightPaddle.x - demoBall.width;
        }

        // Ball goes off screen (scoring)
        if (demoBall.x < demoField.x) {
            // Right player scores
            rightScore++;
            scoreTextRight.text = Std.string(rightScore);
            resetBall(false);
        } else if (demoBall.x > demoField.x + demoField.width) {
            // Left player scores
            leftScore++;
            scoreTextLeft.text = Std.string(leftScore);
            resetBall(true);
        }

        // AI paddle movement (simple AI)
        var leftPaddleCenter = demoLeftPaddle.y + demoLeftPaddle.height * 0.5;
        var rightPaddleCenter = demoRightPaddle.y + demoRightPaddle.height * 0.5;
        var ballCenter = demoBall.y + demoBall.height * 0.5;

        var paddleSpeed = 120 * elapsed;

        // Left paddle AI
        if (leftPaddleCenter < ballCenter - 10) {
            demoLeftPaddle.y += paddleSpeed;
        } else if (leftPaddleCenter > ballCenter + 10) {
            demoLeftPaddle.y -= paddleSpeed;
        }

        // Right paddle AI (slightly different for variety)
        if (rightPaddleCenter < ballCenter - 15) {
            demoRightPaddle.y += paddleSpeed * 0.8;
        } else if (rightPaddleCenter > ballCenter + 15) {
            demoRightPaddle.y -= paddleSpeed * 0.8;
        }

        // Keep paddles in bounds
        demoLeftPaddle.y = Math.max(demoField.y, Math.min(demoLeftPaddle.y, demoField.y + demoField.height - demoLeftPaddle.height));
        demoRightPaddle.y = Math.max(demoField.y, Math.min(demoRightPaddle.y, demoField.y + demoField.height - demoRightPaddle.height));

        // Reset game if score gets too high
        if (leftScore >= 5 || rightScore >= 5) {
            leftScore = 0;
            rightScore = 0;
            scoreTextLeft.text = "0";
            scoreTextRight.text = "0";
            resetBall(FlxG.random.bool());
        }
    }

    /**
     * Reset ball position and direction
     */
    private function resetBall(toRight:Bool):Void {
        demoBall.x = demoField.x + demoField.width * 0.5 - demoBall.width * 0.5;
        demoBall.y = demoField.y + demoField.height * 0.5 - demoBall.height * 0.5;

        ballVelocity.x = toRight ? 200 : -200;
        ballVelocity.y = FlxG.random.float(-150, 150);
    }

    /**
     * Launch Pong with specified game mode
     */
    private function launchPong(mode:PongGameMode):Void {
        trace('Launching Pong with mode: $mode');

        // Stop demo
        if (gameTimer != null) {
            gameTimer.cancel();
        }

        // Launch using PongLauncher
        PongLauncher.launchWithMode(mode);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle input
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new MainMenuState());
        }

        if (controls.ACCEPT) {
            launchPong(PLAYER_VS_AI);
        }

        // Number keys for quick launch
        if (FlxG.keys.justPressed.ONE) {
            launchPong(PLAYER_VS_AI);
        }
        if (FlxG.keys.justPressed.TWO) {
            launchPong(TWO_PLAYER);
        }
        if (FlxG.keys.justPressed.THREE) {
            launchPong(AI_VS_AI);
        }
    }

    override function destroy():Void {
        if (gameTimer != null) {
            gameTimer.cancel();
            gameTimer = null;
        }

        super.destroy();
    }
}
