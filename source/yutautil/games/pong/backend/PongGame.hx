package yutautil.games.pong.backend;

import flixel.FlxG;
import flixel.math.FlxMath;
import yutautil.games.pong.backend.PongPaddle.PongAIDifficulty;

/**
 * Core Pong game logic and state management
 */
class PongGame {
    // Game objects
    public var ball:PongBall;
    public var leftPaddle:PongPaddle;
    public var rightPaddle:PongPaddle;

    // Game settings
    public var fieldWidth:Float;
    public var fieldHeight:Float;
    public var maxScore:Int;

    // Game state
    public var leftScore:Int = 0;
    public var rightScore:Int = 0;
    public var isGameActive:Bool = false;
    public var isRoundActive:Bool = false;
    public var isPaused:Bool = false; // Separate pause state
    public var gameMode:PongGameMode;
    public var winner:PongPlayer = null;
    public var servingPlayer:PongPlayer = LEFT; // Track who should serve

    // Timing
    public var roundStartDelay:Float = 2.0;
    public var currentDelay:Float = 0;
    public var gameSpeed:Float = 1.0;

    // Events
    public var onGameStart:Void->Void;
    public var onGameEnd:PongPlayer->Void;
    public var onRoundStart:Void->Void;
    public var onRoundEnd:PongPlayer->Void;
    public var onScore:PongPlayer->Int->Int->Void; // player, leftScore, rightScore
    public var onBallBounce:Void->Void;
    public var onPaddleHit:PongPaddle->Void;

    // Visual feedback
    public var lastScorer:PongPlayer = null;
    public var ballTrail:Array<{x:Float, y:Float, time:Float}> = [];

    // Debug settings
    public var debugTracesEnabled:Bool = false;

    public function new(fieldWidth:Float = 800, fieldHeight:Float = 600, maxScore:Int = 10) {
        this.fieldWidth = fieldWidth;
        this.fieldHeight = fieldHeight;
        this.maxScore = maxScore;
        this.gameMode = PLAYER_VS_AI;

        setupGame();
    }

    /**
     * Initialize game objects
     */
    private function setupGame():Void {
        // Create ball
        ball = new PongBall(fieldWidth / 2, fieldHeight / 2);

        // Create paddles
        var paddleHeight = fieldHeight * 0.15; // 15% of field height
        leftPaddle = new PongPaddle(20, fieldHeight / 2 - paddleHeight / 2, 20, paddleHeight, 350, true);
        rightPaddle = new PongPaddle(fieldWidth - 40, fieldHeight / 2 - paddleHeight / 2, 20, paddleHeight, 350, false);

        // Set paddle bounds
        leftPaddle.setBounds(0, fieldHeight);
        rightPaddle.setBounds(0, fieldHeight);

        // Set paddle identities
        leftPaddle.setLeftPaddle(true);
        rightPaddle.setLeftPaddle(false);

        // Set field dimensions for advanced AI
        leftPaddle.setFieldDimensions(fieldWidth, fieldHeight);
        rightPaddle.setFieldDimensions(fieldWidth, fieldHeight);

        // Set AI difficulty
        rightPaddle.setAIDifficulty(NORMAL);
    }

    /**
     * Start a new game
     */
    public function startGame(mode:PongGameMode = null):Void {
        if (mode != null) {
            gameMode = mode;
        }

        // Configure players based on game mode
        switch (gameMode) {
            case PLAYER_VS_AI:
                leftPaddle.isPlayer = true;
                rightPaddle.isPlayer = false;
            case TWO_PLAYER:
                leftPaddle.isPlayer = true;
                rightPaddle.isPlayer = true;
            case AI_VS_AI:
                leftPaddle.isPlayer = false;
                rightPaddle.isPlayer = false;
                leftPaddle.setAIDifficulty(NORMAL);
        }

        // Reset scores
        leftScore = 0;
        rightScore = 0;
        winner = null;
        lastScorer = null;
        servingPlayer = LEFT; // Left player serves first

        isGameActive = true;
        startRound();

        if (onGameStart != null) {
            onGameStart();
        }
    }

    /**
     * Start a new round
     */
    public function startRound():Void {
        isRoundActive = false;
        currentDelay = roundStartDelay;

        // Reset ball position to center of field
        ball.position.x = fieldWidth / 2;
        ball.position.y = fieldHeight / 2;

        // Serve the ball toward the serving player
        ball.serveToPlayer(servingPlayer == LEFT);

        // Clear ball trail
        ballTrail = [];

        // Reset God mode states for both paddles
        leftPaddle.resetGodModeStates();
        rightPaddle.resetGodModeStates();

        if (onRoundStart != null) {
            onRoundStart();
        }
    }

    /**
     * End current round
     */
    private function endRound(scorer:PongPlayer):Void {
        isRoundActive = false;
        lastScorer = scorer;

        // Update score
        if (scorer == LEFT) {
            leftScore++;
        } else if (scorer == RIGHT) {
            rightScore++;
        }

        // The player who got scored on serves next (traditional pong rule)
        servingPlayer = (scorer == LEFT) ? RIGHT : LEFT;

        if (onScore != null) {
            onScore(scorer, leftScore, rightScore);
        }

        // Check for game end
        if (leftScore >= maxScore || rightScore >= maxScore) {
            endGame();
        } else {
            startRound();
        }

        if (onRoundEnd != null) {
            onRoundEnd(scorer);
        }
    }

    /**
     * End the game
     */
    private function endGame():Void {
        isGameActive = false;
        isRoundActive = false;

        winner = leftScore >= maxScore ? LEFT : RIGHT;

        if (onGameEnd != null) {
            onGameEnd(winner);
        }
    }

    /**
     * Update game state
     */
    public function update(elapsed:Float):Void {
        if (!isGameActive || isPaused) return; // Check for pause

        elapsed *= gameSpeed;

        // Handle round start delay
        if (!isRoundActive) {
            currentDelay -= elapsed;
            if (currentDelay <= 0) {
                isRoundActive = true;
            } else {
                return;
            }
        }

        // Update ball trail
        updateBallTrail(elapsed);

        // Update paddles
        leftPaddle.update(elapsed, ball);
        rightPaddle.update(elapsed, ball);

        // Update ball
        ball.update(elapsed);

        // Check collisions
        checkCollisions();

        // Check for scoring
        checkScoring();
    }

    /**
     * Update ball trail for visual effects
     */
    private function updateBallTrail(elapsed:Float):Void {
        // Add current position to trail
        ballTrail.push({x: ball.position.x, y: ball.position.y, time: 0});

        // Update trail times and remove old entries
        var i = ballTrail.length - 1;
        while (i >= 0) {
            ballTrail[i].time += elapsed;
            if (ballTrail[i].time > 0.5) { // Keep trail for 0.5 seconds
                ballTrail.splice(i, 1);
            }
            i--;
        }
    }

    /**
     * Check all collisions
     */
    private function checkCollisions():Void {
        // Wall collisions (top/bottom)
        if (ball.position.y - ball.radius <= 0) {
            if (debugTracesEnabled) {
                trace("Ball hit top wall - Y position: " + ball.position.y + ", velocity before: " + ball.velocity.y);
            }
            ball.position.y = ball.radius; // Fix position to prevent getting stuck
            ball.bounceVertical();
            if (debugTracesEnabled) {
                trace("Ball velocity after bounce: " + ball.velocity.y);
            }
            if (onBallBounce != null) {
                onBallBounce();
            }
        } else if (ball.position.y + ball.radius >= fieldHeight) {
            if (debugTracesEnabled) {
                trace("Ball hit bottom wall - Y position: " + ball.position.y + ", velocity before: " + ball.velocity.y);
            }
            ball.position.y = fieldHeight - ball.radius; // Fix position to prevent getting stuck
            ball.bounceVertical();
            if (debugTracesEnabled) {
                trace("Ball velocity after bounce: " + ball.velocity.y);
            }
            if (onBallBounce != null) {
                onBallBounce();
            }
        }

        // Paddle collisions
        if (leftPaddle.checkCollision(ball)) {
            ball.bouncePaddle(leftPaddle.y, leftPaddle.height, leftPaddle.velocity);
            // Move ball out of paddle to prevent multiple collisions
            ball.position.x = leftPaddle.x + leftPaddle.width + ball.radius;

            if (onPaddleHit != null) {
                onPaddleHit(leftPaddle);
            }
        }

        if (rightPaddle.checkCollision(ball)) {
            ball.bouncePaddle(rightPaddle.y, rightPaddle.height, rightPaddle.velocity);
            // Move ball out of paddle to prevent multiple collisions
            ball.position.x = rightPaddle.x - ball.radius;

            if (onPaddleHit != null) {
                onPaddleHit(rightPaddle);
            }
        }
    }

    /**
     * Check for scoring
     */
    private function checkScoring():Void {
        if (ball.scoredLeft()) {
            endRound(RIGHT);
        } else if (ball.scoredRight(fieldWidth)) {
            endRound(LEFT);
        }
    }

    /**
     * Reset game
     */
    public function resetGame():Void {
        isGameActive = false;
        isRoundActive = false;
        isPaused = false;
        leftScore = 0;
        rightScore = 0;
        winner = null;
        lastScorer = null;
        servingPlayer = LEFT; // Reset to left player serving
        ballTrail = [];

        // Reset ball
        ball.position.x = fieldWidth / 2;
        ball.position.y = fieldHeight / 2;
        ball.velocity.x = 0;
        ball.velocity.y = 0;

        // Reset paddles
        leftPaddle.y = fieldHeight / 2 - leftPaddle.height / 2;
        rightPaddle.y = fieldHeight / 2 - rightPaddle.height / 2;
        leftPaddle.velocity = 0;
        rightPaddle.velocity = 0;
    }

    /**
     * Pause/unpause game
     */
    public function togglePause():Bool {
        isPaused = !isPaused;
        return isPaused; // Returns true if now paused
    }

    /**
     * Set game speed multiplier
     */
    public function setGameSpeed(speed:Float):Void {
        gameSpeed = FlxMath.bound(speed, 0.1, 3.0);
    }

    /**
     * Set AI difficulty for computer players
     */
    public function setAIDifficulty(paddle:PongPaddle, difficulty:PongAIDifficulty):Void {
        if (paddle != null && !paddle.isPlayer) {
            paddle.setAIDifficulty(difficulty);
        }
    }

    /**
     * Get current game status string
     */
    public function getGameStatus():String {
        if (!isGameActive) {
            if (winner != null) {
                var winnerName = winner == LEFT ? "Left Player" : "Right Player";
                return '$winnerName Wins! Final Score: $leftScore - $rightScore';
            }
            return 'Game Ready - Press ENTER to start';
        }

        if (isPaused) {
            return 'Score: $leftScore - $rightScore | GAME PAUSED - Press P to resume';
        }

        if (!isRoundActive) {
            var servingPlayerName = servingPlayer == LEFT ? "Left" : "Right";
            return 'Score: $leftScore - $rightScore | $servingPlayerName serves | Starting in ${Math.ceil(currentDelay)}...';
        }

        return 'Score: $leftScore - $rightScore | Playing to $maxScore';
    }
}

/**
 * Pong game modes
 */
enum PongGameMode {
    PLAYER_VS_AI;
    TWO_PLAYER;
    AI_VS_AI;
}

/**
 * Player identification
 */
enum PongPlayer {
    LEFT;
    RIGHT;
}
