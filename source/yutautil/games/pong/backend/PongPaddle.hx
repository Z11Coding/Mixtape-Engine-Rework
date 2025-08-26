package yutautil.games.pong.backend;

import flixel.FlxG;
import flixel.math.FlxMath;

/**
 * Represents a paddle in a Pong game
 */
class PongPaddle {
    public var x:Float;
    public var y:Float;
    public var width:Float;
    public var height:Float;
    public var speed:Float;
    public var velocity:Float = 0;

    // Control properties
    public var isPlayer:Bool;
    public var isLeftPaddle:Bool = false; // Simple identifier instead of key system

    // AI properties
    public var aiDifficulty:PongAIDifficulty;
    public var aiReactionTime:Float;
    public var aiAccuracy:Float;
    public var aiPrediction:Float;
    public var aiLastThinkTime:Float = 0;
    public var aiTargetY:Float = 0;

    // Advanced AI properties for "Yes" difficulty
    public var aiStrategy:String = "normal"; // "normal", "aggressive", "defensive", "tricky"
    public var aiStrategyTimer:Float = 0;
    public var aiLastBallDirection:Float = 0;
    public var aiConsecutiveHits:Int = 0;
    public var aiFieldWidth:Float = 800; // Will be set by game
    public var aiFieldHeight:Float = 600; // Will be set by game

    // Bounds
    public var minY:Float = 0;
    public var maxY:Float = 0;

    public function new(x:Float, y:Float, width:Float = 20, height:Float = 100, speed:Float = 300, isPlayer:Bool = true) {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.speed = speed;
        this.isPlayer = isPlayer;

        // Default AI settings
        this.aiDifficulty = NORMAL;
        updateAISettings();
    }

    /**
     * Set which paddle this is (left or right)
     */
    public function setLeftPaddle(isLeft:Bool):Void {
        this.isLeftPaddle = isLeft;
    }

    /**
     * Set AI difficulty
     */
    public function setAIDifficulty(difficulty:PongAIDifficulty):Void {
        this.aiDifficulty = difficulty;
        updateAISettings();
    }

    /**
     * Set field dimensions for advanced AI calculations
     */
    public function setFieldDimensions(width:Float, height:Float):Void {
        this.aiFieldWidth = width;
        this.aiFieldHeight = height;
    }

    private function updateAISettings():Void {
        switch (aiDifficulty) {
            case EASY:
                aiReactionTime = 0.5;
                aiAccuracy = 0.6;
                aiPrediction = 0.3;
            case NORMAL:
                aiReactionTime = 0.3;
                aiAccuracy = 0.8;
                aiPrediction = 0.6;
            case HARD:
                aiReactionTime = 0.15;
                aiAccuracy = 0.95;
                aiPrediction = 0.9;
            case EXPERT:
                aiReactionTime = 0.05;
                aiAccuracy = 1.0;
                aiPrediction = 1.0;
            case YES:
                aiReactionTime = 0.02; // Nearly instant reaction
                aiAccuracy = 1.0; // Perfect accuracy when not being strategic
                aiPrediction = 1.0; // Perfect prediction
        }
    }

    /**
     * Set paddle bounds
     */
    public function setBounds(minY:Float, maxY:Float):Void {
        this.minY = minY;
        this.maxY = maxY - height;
    }

    /**
     * Update paddle (handles input and AI)
     */
    public function update(elapsed:Float, ball:PongBall):Void {
        velocity = 0;

        if (isPlayer) {
            updatePlayerInput();
        } else {
            updateAI(elapsed, ball);
        }

        // Apply movement
        y += velocity * elapsed;

        // Keep within bounds
        y = FlxMath.bound(y, minY, maxY);
    }

    private function updatePlayerInput():Void {
        if (isLeftPaddle) {
            // Left paddle uses W/S keys
            if (FlxG.keys.pressed.W) {
                velocity = -speed;
            } else if (FlxG.keys.pressed.S) {
                velocity = speed;
            }
        } else {
            // Right paddle uses UP/DOWN arrow keys
            if (FlxG.keys.pressed.UP) {
                velocity = -speed;
            } else if (FlxG.keys.pressed.DOWN) {
                velocity = speed;
            }
        }
    }

    private function updateAI(elapsed:Float, ball:PongBall):Void {
        aiLastThinkTime += elapsed;

        // Only update AI target at intervals based on reaction time
        if (aiLastThinkTime >= aiReactionTime) {
            aiLastThinkTime = 0;

            var targetY = aiDifficulty == YES ?
                calculateAdvancedAITarget(ball, elapsed) :
                calculateAITarget(ball);

            // Add inaccuracy for easier difficulties (not for YES)
            if (aiAccuracy < 1.0 && aiDifficulty != YES) {
                var inaccuracy = (1.0 - aiAccuracy) * height;
                targetY += FlxG.random.float(-inaccuracy, inaccuracy);
            }

            aiTargetY = targetY;
        }

        // Move towards target
        var paddleCenter = y + height / 2;
        var distanceToTarget = aiTargetY - paddleCenter;

        if (Math.abs(distanceToTarget) > 5) {
            velocity = distanceToTarget > 0 ? speed : -speed;
        }
    }

    private function calculateAITarget(ball:PongBall):Float {
        if (ball == null) return y + height / 2;

        var ballCenter = ball.position.y;

        // Basic following
        if (aiPrediction <= 0.3) {
            return ballCenter;
        }

        // Predictive following
        var isMovingTowardsPaddle = (x < ball.position.x && ball.velocity.x < 0) ||
                                   (x > ball.position.x && ball.velocity.x > 0);

        if (isMovingTowardsPaddle && aiPrediction > 0.5) {
            // Predict where ball will be when it reaches paddle
            var timeToReach = Math.abs((x - ball.position.x) / ball.velocity.x);
            var predictedY = ball.position.y + ball.velocity.y * timeToReach;

            // Account for wall bounces in prediction
            if (predictedY < 0 || predictedY > (maxY + height)) {
                predictedY = ball.position.y + ball.velocity.y * timeToReach * 0.5;
            }

            return predictedY;
        }

        return ballCenter;
    }

    /**
     * Advanced AI target calculation for "Yes" difficulty
     * Includes multi-bounce prediction and strategic positioning
     */
    private function calculateAdvancedAITarget(ball:PongBall, elapsed:Float):Float {
        if (ball == null) return y + height / 2;

        // Update strategy timer
        aiStrategyTimer += elapsed;

        // Change strategy every 3-8 seconds for unpredictability
        if (aiStrategyTimer > FlxG.random.float(3.0, 8.0)) {
            aiStrategyTimer = 0;
            var strategies = ["normal", "aggressive", "defensive", "tricky"];
            aiStrategy = strategies[FlxG.random.int(0, strategies.length - 1)];
            trace("AI changed strategy to: " + aiStrategy);
        }

        // Track ball direction changes
        if ((aiLastBallDirection > 0 && ball.velocity.x < 0) || (aiLastBallDirection < 0 && ball.velocity.x > 0)) {
            aiConsecutiveHits++;
        }
        aiLastBallDirection = ball.velocity.x;

        var isMovingTowardsPaddle = (x < ball.position.x && ball.velocity.x < 0) ||
                                   (x > ball.position.x && ball.velocity.x > 0);

        if (!isMovingTowardsPaddle) {
            // Ball moving away - use different strategies
            return calculateDefensivePosition(ball);
        }

        // Calculate multiple bounce prediction
        var predictedHitPoint = predictMultipleBounces(ball, 3); // Predict up to 3 bounces ahead

        // Apply strategy-based adjustments
        switch (aiStrategy) {
            case "aggressive":
                return calculateAggressiveTarget(predictedHitPoint, ball);
            case "defensive":
                return calculateDefensiveTarget(predictedHitPoint, ball);
            case "tricky":
                return calculateTrickyTarget(predictedHitPoint, ball);
            default: // "normal"
                return predictedHitPoint;
        }
    }

    /**
     * Predict where the ball will be after multiple bounces
     */
    private function predictMultipleBounces(ball:PongBall, maxBounces:Int):Float {
        var simX = ball.position.x;
        var simY = ball.position.y;
        var simVelX = ball.velocity.x;
        var simVelY = ball.velocity.y;

        var timeStep = 0.016; // Simulate at ~60 FPS
        var maxTime = 10.0; // Don't simulate more than 10 seconds
        var currentTime = 0.0;
        var bounces = 0;

        while (currentTime < maxTime && bounces < maxBounces) {
            // Check if ball will reach paddle X position
            var willReachPaddle = false;
            if (isLeftPaddle && simX <= x + width && simVelX < 0) {
                willReachPaddle = true;
            } else if (!isLeftPaddle && simX >= x && simVelX > 0) {
                willReachPaddle = true;
            }

            if (willReachPaddle) {
                // Calculate exact time to reach paddle
                var timeToReach = Math.abs((x - simX) / simVelX);
                return simY + simVelY * timeToReach;
            }

            // Simulate movement
            simX += simVelX * timeStep;
            simY += simVelY * timeStep;
            currentTime += timeStep;

            // Check for wall bounces (top/bottom)
            if (simY <= ball.radius) {
                simY = ball.radius;
                simVelY = -simVelY;
                bounces++;
            } else if (simY >= aiFieldHeight - ball.radius) {
                simY = aiFieldHeight - ball.radius;
                simVelY = -simVelY;
                bounces++;
            }
        }

        // Fallback to current prediction
        var timeToReach = Math.abs((x - ball.position.x) / ball.velocity.x);
        return ball.position.y + ball.velocity.y * timeToReach;
    }

    /**
     * Calculate aggressive target (aim for corners/edges to make difficult returns)
     */
    private function calculateAggressiveTarget(predictedY:Float, ball:PongBall):Float {
        var paddleCenter = y + height / 2;

        // Occasionally aim for extreme angles
        if (FlxG.random.float(0, 1) < 0.3) {
            // Aim with edge of paddle for sharp angle
            if (predictedY < paddleCenter) {
                return predictedY - height * 0.35; // Hit with top part
            } else {
                return predictedY + height * 0.35; // Hit with bottom part
            }
        }

        return predictedY;
    }

    /**
     * Calculate defensive target (prioritize safe returns)
     */
    private function calculateDefensiveTarget(predictedY:Float, ball:PongBall):Float {
        // Always try to hit with center of paddle for most control
        return predictedY;
    }

    /**
     * Calculate tricky target (unpredictable play to confuse opponent)
     */
    private function calculateTrickyTarget(predictedY:Float, ball:PongBall):Float {
        // Randomly offset position to create unpredictable bounces
        var trickOffset = FlxG.random.float(-height * 0.3, height * 0.3);

        // Sometimes pretend to miss then recover at last second
        if (FlxG.random.float(0, 1) < 0.2 && aiConsecutiveHits > 2) {
            trickOffset *= 2; // Larger offset for more dramatic effect
        }

        return predictedY + trickOffset;
    }

    /**
     * Calculate defensive position when ball is moving away
     */
    private function calculateDefensivePosition(ball:PongBall):Float {
        // Move to center or anticipate opponent's return
        var fieldCenter = aiFieldHeight / 2;

        // Try to anticipate where opponent might hit the ball
        if (ball.velocity.x != 0) {
            var timeToOpponentPaddle = Math.abs((ball.position.x - (isLeftPaddle ? aiFieldWidth - 40 : 40)) / ball.velocity.x);
            var predictedOpponentHitY = ball.position.y + ball.velocity.y * timeToOpponentPaddle;

            // Move slightly toward predicted return area
            return (fieldCenter + predictedOpponentHitY) / 2;
        }

        return fieldCenter;
    }

    /**
     * Check collision with ball
     */
    public function checkCollision(ball:PongBall):Bool {
        var ballBounds = ball.getBounds();

        return !(ballBounds.right < x ||
                 ballBounds.left > x + width ||
                 ballBounds.bottom < y ||
                 ballBounds.top > y + height);
    }

    /**
     * Get paddle center position
     */
    public function getCenterY():Float {
        return y + height / 2;
    }

    /**
     * Get paddle bounds
     */
    public function getBounds():{left:Float, right:Float, top:Float, bottom:Float} {
        return {
            left: x,
            right: x + width,
            top: y,
            bottom: y + height
        };
    }
}

/**
 * AI difficulty levels for Pong
 */
enum PongAIDifficulty {
    EASY;
    NORMAL;
    HARD;
    EXPERT;
    YES; // Ultra-advanced AI with strategic play and multi-bounce prediction
}
