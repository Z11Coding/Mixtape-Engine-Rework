package games.uno;

import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxVelocity;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import games.uno.backend.UnoCPU.UnoDifficulty;
import games.uno.backend.UnoCPU;
import games.uno.backend.UnoPlayer;

/**
 * Pong substate for UNO custom card - simplified Pong game
 * Winner determined by first to score, loser draws 4 cards
 * Supports Player vs CPU, CPU vs CPU, and proper player identification
 */
class PongUnoSubstate extends MusicBeatSubstate {
    // Game objects
    private var leftPaddle:FlxSprite;
    private var rightPaddle:FlxSprite;
    private var ball:FlxSprite;

    // UI elements
    private var titleText:FlxText;
    private var instructionText:FlxText;
    private var scoreText:FlxText;

    // Game state
    private var gameActive:Bool = false;
    private var gameEnded:Bool = false;
    private var leftPlayerScore:Int = 0;
    private var rightPlayerScore:Int = 0;
    private var ballSpeed:Float = 200;
    private var paddleSpeed:Float = 300;

    // Players
    private var leftPlayer:UnoPlayer;
    private var rightPlayer:UnoPlayer;
    private var isCPUvsCPU:Bool = false;
    private var watchMode:Bool = false;
    private var servingPlayer:Bool = true; // true = left player serves, false = right player serves

    // CPU difficulties for pong AI
    private var leftPaddleDifficulty:Float = 0.7;
    private var rightPaddleDifficulty:Float = 0.7;

    // Callbacks
    public var onLeftPlayerWin:(UnoPlayer)->Void;
    public var onRightPlayerWin:(UnoPlayer)->Void;

    public function new(leftPlayer:UnoPlayer, rightPlayer:UnoPlayer) {
        super();
        this.leftPlayer = leftPlayer;
        this.rightPlayer = rightPlayer;

        // Check if both are CPUs
        isCPUvsCPU = !leftPlayer.isHuman && !rightPlayer.isHuman;

        // Set CPU difficulties for pong
        if (!leftPlayer.isHuman && Std.isOfType(leftPlayer, UnoCPU)) {
            leftPaddleDifficulty = getCPUPongDifficulty(cast(leftPlayer, UnoCPU).difficulty);
        }
        if (!rightPlayer.isHuman && Std.isOfType(rightPlayer, UnoCPU)) {
            rightPaddleDifficulty = getCPUPongDifficulty(cast(rightPlayer, UnoCPU).difficulty);
        }
    }

    /**
     * Convert UNO CPU difficulty to Pong paddle skill
     */
    private function getCPUPongDifficulty(difficulty:UnoDifficulty):Float {
        return switch(difficulty) {
            case EASY: 0.4;     // Slow reaction
            case NORMAL: 0.65;  // Standard
            case HARD: 0.8;     // Quick reaction
            case EXPERT: 0.95;  // Near perfect
        }
    }

    override public function create():Void {
        super.create();

        // Add semi-transparent black background
        var bg = new FlxSprite();
        bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.8; // Semi-transparent
        add(bg);

        // Handle CPU vs CPU scenario
        if (isCPUvsCPU) {
            handleCPUvsCPU();
            return;
        }

        // Create UI
        createUI();

        // Create game objects
        createGameObjects();

        // Start the game
        startGame();
    }

    /**
     * Handle CPU vs CPU battle - offer choice to watch or auto-resolve
     */
    private function handleCPUvsCPU():Void {
        // Create prompt UI
        titleText = new FlxText(0, FlxG.height/2 - 100, FlxG.width, "CPU VS CPU PONG BATTLE!");
        titleText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
        add(titleText);

        instructionText = new FlxText(0, FlxG.height/2 - 50, FlxG.width,
            '${leftPlayer.name} (${getCPUDifficultyName(leftPlayer)}) VS ${rightPlayer.name} (${getCPUDifficultyName(rightPlayer)})\n\nPress SPACE to watch the battle\nPress ENTER to auto-resolve');
        instructionText.setFormat("VCR OSD Mono", 16, FlxColor.CYAN, CENTER);
        add(instructionText);

        // Wait for input
        gameActive = false;
        gameEnded = false;
    }

    /**
     * Get CPU difficulty name for display
     */
    private function getCPUDifficultyName(player:UnoPlayer):String {
        if (!player.isHuman && Std.isOfType(player, UnoCPU)) {
            return switch(cast(player, UnoCPU).difficulty) {
                case EASY: "Easy";
                case NORMAL: "Normal";
                case HARD: "Hard";
                case EXPERT: "Expert";
            }
        }
        return "Unknown";
    }

    /**
     * Auto-resolve CPU vs CPU battle based on difficulties and chance
     */
    private function autoResolveCPUvsCPU():Void {
        var leftDiff = leftPaddleDifficulty;
        var rightDiff = rightPaddleDifficulty;

        // Calculate win chance based on difficulties
        var leftWinChance = leftDiff / (leftDiff + rightDiff);

        // Add some randomness
        leftWinChance += FlxG.random.float(-0.2, 0.2);
        leftWinChance = FlxMath.bound(leftWinChance, 0.1, 0.9);

        var leftWins = FlxG.random.bool(leftWinChance * 100);

        // Show result
        titleText.text = "AUTO-RESOLVED BATTLE RESULT:";
        if (leftWins) {
            instructionText.text = '${leftPlayer.name} WINS!\n${rightPlayer.name} draws 4 cards.\n\nPress ENTER to continue...';
            instructionText.color = FlxColor.GREEN;
            if (onLeftPlayerWin != null) onLeftPlayerWin(rightPlayer); // Pass the loser
        } else {
            instructionText.text = '${rightPlayer.name} WINS!\n${leftPlayer.name} draws 4 cards.\n\nPress ENTER to continue...';
            instructionText.color = FlxColor.GREEN;
            if (onRightPlayerWin != null) onRightPlayerWin(leftPlayer); // Pass the loser
        }

        gameEnded = true;
    }

    private function createUI():Void {
        // Title
        titleText = new FlxText(0, 20, FlxG.width, "PONG BATTLE!");
        titleText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
        add(titleText);

        // Instructions - dynamic based on players
        var controlsText = getControlsText();
        instructionText = new FlxText(0, 60, FlxG.width, 'First to score wins! Loser draws 4 cards!\n$controlsText');
        instructionText.setFormat("VCR OSD Mono", 16, FlxColor.CYAN, CENTER);
        add(instructionText);

        // Score - dynamic names
        scoreText = new FlxText(0, FlxG.height - 40, FlxG.width, '${leftPlayer.name}: 0 - ${rightPlayer.name}: 0');
        scoreText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER);
        add(scoreText);
    }

    /**
     * Get controls text based on player types
     */
    private function getControlsText():String {
        if (leftPlayer.isHuman && rightPlayer.isHuman) {
            return "Left: WASD | Right: Arrow Keys";
        } else if (leftPlayer.isHuman && !rightPlayer.isHuman) {
            return "Player: WASD | CPU: Auto";
        } else if (!leftPlayer.isHuman && rightPlayer.isHuman) {
            return "CPU: Auto | Player: Arrow Keys";
        } else {
            return "CPU vs CPU - Watch Mode";
        }
    }

    private function createGameObjects():Void {
        // Left paddle (Player)
        leftPaddle = new FlxSprite(30, FlxG.height/2 - 50);
        leftPaddle.makeGraphic(15, 100, FlxColor.WHITE);
        add(leftPaddle);

        // Right paddle (CPU)
        rightPaddle = new FlxSprite(FlxG.width - 45, FlxG.height/2 - 50);
        rightPaddle.makeGraphic(15, 100, FlxColor.WHITE);
        add(rightPaddle);

        // Ball
        ball = new FlxSprite(FlxG.width/2 - 5, FlxG.height/2 - 5);
        ball.makeGraphic(10, 10, FlxColor.WHITE);
        add(ball);
    }

    private function startGame():Void {
        gameActive = true;
        gameEnded = false;

        // Reset ball position to center
        ball.setPosition(FlxG.width/2 - 5, FlxG.height/2 - 5);

        // Serve ball toward the serving player
        var angle = FlxG.random.float(-30, 30) * (Math.PI / 180);
        var direction = servingPlayer ? -1 : 1; // true = left (-1), false = right (1)

        ball.velocity.set(
            Math.cos(angle) * ballSpeed * direction,
            Math.sin(angle) * ballSpeed
        );
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle CPU vs CPU input before game starts
        if (isCPUvsCPU && !gameActive && !gameEnded) {
            if (FlxG.keys.justPressed.SPACE) {
                // Watch the battle
                watchMode = true;
                remove(instructionText);
                remove(titleText);
                createUI();
                createGameObjects();
                startGame();
            } else if (FlxG.keys.justPressed.ENTER) {
                // Auto-resolve
                autoResolveCPUvsCPU();
            }
            return;
        }

        // Handle game over input
        if (gameEnded) {
            if (FlxG.keys.justPressed.ENTER) {
                close();
            }
            return;
        }

        if (!gameActive) return;

        // Left paddle controls
        if (leftPlayer.isHuman) {
            if (FlxG.keys.pressed.W || FlxG.keys.pressed.UP) {
                leftPaddle.velocity.y = -paddleSpeed;
            } else if (FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN) {
                leftPaddle.velocity.y = paddleSpeed;
            } else {
                leftPaddle.velocity.y = 0;
            }
        } else {
            // CPU AI for left paddle
            var cpuTarget = ball.y + ball.height/2 - leftPaddle.height/2;
            var cpuDiff = cpuTarget - leftPaddle.y;

            if (Math.abs(cpuDiff) > 5) {
                leftPaddle.velocity.y = (cpuDiff > 0) ? paddleSpeed * leftPaddleDifficulty : -paddleSpeed * leftPaddleDifficulty;
            } else {
                leftPaddle.velocity.y = 0;
            }
        }

        // Right paddle controls
        if (rightPlayer.isHuman) {
            // Use arrow keys for right player
            if (FlxG.keys.pressed.UP) {
                rightPaddle.velocity.y = -paddleSpeed;
            } else if (FlxG.keys.pressed.DOWN) {
                rightPaddle.velocity.y = paddleSpeed;
            } else {
                rightPaddle.velocity.y = 0;
            }
        } else {
            // CPU AI for right paddle
            var cpuTarget = ball.y + ball.height/2 - rightPaddle.height/2;
            var cpuDiff = cpuTarget - rightPaddle.y;

            if (Math.abs(cpuDiff) > 5) {
                rightPaddle.velocity.y = (cpuDiff > 0) ? paddleSpeed * rightPaddleDifficulty : -paddleSpeed * rightPaddleDifficulty;
            } else {
                rightPaddle.velocity.y = 0;
            }
        }

        // Keep paddles on screen
        leftPaddle.y = FlxMath.bound(leftPaddle.y, 100, FlxG.height - leftPaddle.height - 50);
        rightPaddle.y = FlxMath.bound(rightPaddle.y, 100, FlxG.height - rightPaddle.height - 50);

        // Ball collision with top/bottom
        if (ball.y <= 100 || ball.y >= FlxG.height - ball.height - 50) {
            ball.velocity.y = -ball.velocity.y;
        }

        // Ball collision with paddles
        if (FlxG.overlap(ball, leftPaddle)) {
            if (ball.velocity.x < 0) { // Only bounce if moving toward paddle
                ball.velocity.x = -ball.velocity.x;
                // Add some angle based on where it hit the paddle
                var hitPos = (ball.y + ball.height/2 - leftPaddle.y) / leftPaddle.height;
                ball.velocity.y = (hitPos - 0.5) * ballSpeed;
            }
        }

        if (FlxG.overlap(ball, rightPaddle)) {
            if (ball.velocity.x > 0) { // Only bounce if moving toward paddle
                ball.velocity.x = -ball.velocity.x;
                // Add some angle based on where it hit the paddle
                var hitPos = (ball.y + ball.height/2 - rightPaddle.y) / rightPaddle.height;
                ball.velocity.y = (hitPos - 0.5) * ballSpeed;
            }
        }

        // Scoring
        if (ball.x < 0) {
            // Right player scored
            rightPlayerScored();
        } else if (ball.x > FlxG.width) {
            // Left player scored
            leftPlayerScored();
        }
    }

    private function leftPlayerScored():Void {
        leftPlayerScore++;
        updateScoreDisplay();
        // Right player serves next (player who got scored on serves)
        servingPlayer = false;
        endGame(true); // Left player wins
    }

    private function rightPlayerScored():Void {
        rightPlayerScore++;
        updateScoreDisplay();
        // Left player serves next (player who got scored on serves)
        servingPlayer = true;
        endGame(false); // Right player wins
    }

    private function updateScoreDisplay():Void {
        scoreText.text = '${leftPlayer.name}: $leftPlayerScore - ${rightPlayer.name}: $rightPlayerScore';
    }

    private function endGame(leftPlayerWon:Bool):Void {
        gameActive = false;
        gameEnded = true;

        ball.velocity.set(0, 0);
        leftPaddle.velocity.set(0, 0);
        rightPaddle.velocity.set(0, 0);

        if (leftPlayerWon) {
            instructionText.text = '${leftPlayer.name} WINS! ${rightPlayer.name} draws 4 cards.\nPress ENTER to continue...';
            instructionText.color = FlxColor.GREEN;
            if (onLeftPlayerWin != null) onLeftPlayerWin(rightPlayer); // Pass the losing player
        } else {
            instructionText.text = '${rightPlayer.name} WINS! ${leftPlayer.name} draws 4 cards.\nPress ENTER to continue...';
            instructionText.color = FlxColor.GREEN;
            if (onRightPlayerWin != null) onRightPlayerWin(leftPlayer); // Pass the losing player
        }

        // Auto-close after 2 seconds or ENTER press
        new flixel.util.FlxTimer().start(0.1, function(timer) {
            if (FlxG.keys.justPressed.ENTER || timer.elapsedLoops > 20) {
                close();
            }
        }, 0);
    }
}
