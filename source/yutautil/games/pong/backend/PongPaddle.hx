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

    // Advanced AI properties for "Yes" and "God" difficulty
    public var aiStrategy:String = "normal"; // "normal", "aggressive", "defensive", "tricky"
    public var aiStrategyTimer:Float = 0;
    public var aiLastBallDirection:Float = 0;
    public var aiConsecutiveHits:Int = 0;
    public var aiFieldWidth:Float = 800; // Will be set by game
    public var aiFieldHeight:Float = 600; // Will be set by game

    // God difficulty specific properties
    public var aiGodModeActive:Bool = false;
    public var aiFakeoutTimer:Float = 0;
    public var aiFakeoutDirection:Float = 0;
    public var aiIsExecutingFakeout:Bool = false;
    public var aiMessAroundTimer:Float = 0;
    public var aiMessAroundActive:Bool = false;
    public var aiPerfectPositionKnown:Bool = false;
    public var aiPerfectPosition:Float = 0;
    public var aiTimeToShow:Float = 0; // Time until AI moves to perfect position

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
        resetGodModeStates();
    }

    /**
     * Reset God mode states (useful when starting new rounds or changing difficulty)
     */
    public function resetGodModeStates():Void {
        aiIsExecutingFakeout = false;
        aiMessAroundActive = false;
        aiFakeoutTimer = 0;
        aiMessAroundTimer = 0;
        aiPerfectPositionKnown = false;
        aiTimeToShow = 0;
        aiConsecutiveHits = 0;
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
            case GOD:
                aiReactionTime = 0.001; // Superhuman reaction time
                aiAccuracy = 1.0; // Perfect accuracy
                aiPrediction = 1.0; // Perfect prediction
                aiGodModeActive = true; // Enable god mode behaviors
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

            var targetY = aiDifficulty == GOD ?
                calculateGodAITarget(ball, elapsed) :
                (aiDifficulty == YES ?
                calculateAdvancedAITarget(ball, elapsed) :
                calculateAITarget(ball));

            // Add inaccuracy for easier difficulties (not for YES or GOD)
            if (aiAccuracy < 1.0 && aiDifficulty != YES && aiDifficulty != GOD) {
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
     * God-tier AI target calculation - includes fakeouts, time-wasting, and perfect prediction
     */
    private function calculateGodAITarget(ball:PongBall, elapsed:Float):Float {
        if (ball == null) return y + height / 2;

        // Update all God mode timers
        aiFakeoutTimer += elapsed;
        aiMessAroundTimer += elapsed;

        // Track ball direction changes
        if ((aiLastBallDirection > 0 && ball.velocity.x < 0) || (aiLastBallDirection < 0 && ball.velocity.x > 0)) {
            aiConsecutiveHits++;
        }
        aiLastBallDirection = ball.velocity.x;

        var isMovingTowardsPaddle = (x < ball.position.x && ball.velocity.x < 0) ||
                                   (x > ball.position.x && ball.velocity.x > 0);

        // Calculate the perfect position with unlimited bounce prediction
        aiPerfectPosition = predictUnlimitedBounces(ball);
        aiPerfectPositionKnown = true;

        if (!isMovingTowardsPaddle) {
            // Ball moving away - enter "mess around" mode if there's time
            return calculateGodDefensivePosition(ball, elapsed);
        }

        // Calculate time until ball reaches paddle
        var timeToReach = Math.abs((x - ball.position.x) / ball.velocity.x);

        // If we have lots of time (>2 seconds), mess around or execute fakeouts
        if (timeToReach > 2.0) {
            return executeGodModeAntics(ball, elapsed, timeToReach);
        }
        // If we have some time (>0.5 seconds), might do a small fakeout
        else if (timeToReach > 0.5 && FlxG.random.float(0, 1) < 0.3) {
            return executeSmallFakeout(ball, elapsed, timeToReach);
        }
        // Otherwise, move to perfect position
        else {
            return aiPerfectPosition;
        }
    }

    /**
     * Execute God mode antics when there's plenty of time
     */
    private function executeGodModeAntics(ball:PongBall, elapsed:Float, timeToReach:Float):Float {
        var currentPaddleCenter = y + height / 2;

        // Decision making: should we mess around, fakeout, or just show off?
        if (!aiMessAroundActive && FlxG.random.float(0, 1) < 0.7) {
            aiMessAroundActive = true;
            aiMessAroundTimer = 0;
        }

        if (aiMessAroundActive) {
            // Calculate how long we can mess around before needing to get serious
            aiTimeToShow = timeToReach - 0.3; // Leave 0.3 seconds to get to perfect position

            if (aiMessAroundTimer < aiTimeToShow) {
                // Mess around phase - move in patterns or to obviously wrong positions
                return executeMessAroundBehavior(ball, elapsed);
            } else {
                // Time to get serious - move to perfect position rapidly
                aiMessAroundActive = false;
                return aiPerfectPosition;
            }
        }

        // If not messing around, execute a dramatic fakeout
        return executeDramaticFakeout(ball, elapsed, timeToReach);
    }

    /**
     * Execute mess around behavior - move in patterns or to wrong positions
     */
    private function executeMessAroundBehavior(ball:PongBall, elapsed:Float):Float {
        var fieldCenter = aiFieldHeight / 2;
        var currentCenter = y + height / 2;

        // Choose a mess around pattern
        var pattern = Math.floor(aiMessAroundTimer * 0.5) % 4;

        switch (pattern) {
            case 0: // Sine wave movement
                var waveOffset = Math.sin(aiMessAroundTimer * 3) * (aiFieldHeight * 0.3);
                return fieldCenter + waveOffset;

            case 1: // Move to opposite corner
                var targetCorner = aiPerfectPosition < fieldCenter ?
                    aiFieldHeight - height : 0;
                return targetCorner;

            case 2: // Oscillate between top and bottom
                var oscillate = Math.sin(aiMessAroundTimer * 4) > 0;
                return oscillate ? height : aiFieldHeight - height;

            case 3: // Pretend to track ball incorrectly
                var wrongPrediction = ball.position.y + ball.velocity.y * 0.1; // Very short prediction
                return wrongPrediction + FlxG.random.float(-height, height);
        }

        return fieldCenter;
    }

    /**
     * Execute a dramatic fakeout that looks like the AI will miss
     */
    private function executeDramaticFakeout(ball:PongBall, elapsed:Float, timeToReach:Float):Float {
        if (!aiIsExecutingFakeout) {
            aiIsExecutingFakeout = true;
            aiFakeoutTimer = 0;

            // Choose a fakeout direction (move away from perfect position)
            var perfectCenter = aiPerfectPosition;
            var fieldCenter = aiFieldHeight / 2;

            // Move towards the more dramatic direction
            if (perfectCenter > fieldCenter) {
                aiFakeoutDirection = -1; // Move up when we should move down
            } else {
                aiFakeoutDirection = 1; // Move down when we should move up
            }
        }

        // Calculate when to stop fakeout (leave enough time to reach perfect position)
        var timeToStopFakeout = timeToReach - 0.2; // Leave 0.2 seconds

        if (aiFakeoutTimer < timeToStopFakeout) {
            // Continue fakeout - move to obviously wrong position
            var fakeoutTarget = aiPerfectPosition + (aiFakeoutDirection * height * 2);
            return fakeoutTarget;
        } else {
            // End fakeout, snap to perfect position
            aiIsExecutingFakeout = false;
            return aiPerfectPosition;
        }
    }

    /**
     * Execute a small, subtle fakeout
     */
    private function executeSmallFakeout(ball:PongBall, elapsed:Float, timeToReach:Float):Float {
        if (!aiIsExecutingFakeout) {
            aiIsExecutingFakeout = true;
            aiFakeoutTimer = 0;

            // Small fakeout - just slightly wrong direction
            aiFakeoutDirection = FlxG.random.bool() ? 1 : -1;
        }

        var timeToStopFakeout = timeToReach - 0.1; // Leave 0.1 seconds

        if (aiFakeoutTimer < timeToStopFakeout) {
            // Small offset from perfect position
            return aiPerfectPosition + (aiFakeoutDirection * height * 0.5);
        } else {
            // Snap to perfect position
            aiIsExecutingFakeout = false;
            return aiPerfectPosition;
        }
    }

    /**
     * Calculate defensive position for God AI when ball is moving away
     */
    private function calculateGodDefensivePosition(ball:PongBall, elapsed:Float):Float {
        var fieldCenter = aiFieldHeight / 2;

        // Predict opponent's next move with perfect accuracy
        var opponentPaddleX = isLeftPaddle ? aiFieldWidth - 40 : 40;
        var timeToOpponentPaddle = Math.abs((ball.position.x - opponentPaddleX) / ball.velocity.x);

        // Simulate where the ball will be when opponent hits it
        var predictedOpponentHitY = ball.position.y + ball.velocity.y * timeToOpponentPaddle;

        // Account for wall bounces before reaching opponent
        var simY = ball.position.y;
        var simVelY = ball.velocity.y;
        var simTime = 0.0;
        var timeStep = 0.016;

        while (simTime < timeToOpponentPaddle) {
            simY += simVelY * timeStep;
            simTime += timeStep;

            // Check for wall bounces
            if (simY <= ball.radius) {
                simY = ball.radius;
                simVelY = -simVelY;
            } else if (simY >= aiFieldHeight - ball.radius) {
                simY = aiFieldHeight - ball.radius;
                simVelY = -simVelY;
            }
        }

        predictedOpponentHitY = simY;

        // Now predict where the ball will come back to us after opponent's hit
        // Assume opponent will hit from center of their paddle
        var estimatedReturnY = predictedOpponentHitY; // Simple assumption

        // Position ourselves optimally for the return, but with some showing off
        if (!aiMessAroundActive && FlxG.random.float(0, 1) < 0.4) {
            aiMessAroundActive = true;
            aiMessAroundTimer = 0;
        }

        if (aiMessAroundActive && timeToOpponentPaddle > 1.0) {
            // Show off while waiting
            return executeMessAroundBehavior(ball, elapsed);
        }

        // Move to predicted return position
        return estimatedReturnY;
    }

    /**
     * Predict ball position with unlimited bounce calculations - God tier prediction
     */
    private function predictUnlimitedBounces(ball:PongBall):Float {
        var simX = ball.position.x;
        var simY = ball.position.y;
        var simVelX = ball.velocity.x;
        var simVelY = ball.velocity.y;

        var timeStep = 0.008; // Higher precision simulation
        var maxTime = 30.0; // Much longer prediction time
        var currentTime = 0.0;

        // God mode: track ALL bounces until ball reaches paddle
        while (currentTime < maxTime) {
            // Check if ball will reach paddle X position
            var willReachPaddle = false;
            if (isLeftPaddle && simX <= x + width && simVelX < 0) {
                willReachPaddle = true;
            } else if (!isLeftPaddle && simX >= x && simVelX > 0) {
                willReachPaddle = true;
            }

            if (willReachPaddle) {
                // Calculate exact intersection point
                var exactTimeToReach = Math.abs((x - simX) / simVelX);
                var finalY = simY + simVelY * exactTimeToReach;

                // Ensure the prediction is within bounds
                while (finalY < ball.radius) {
                    finalY = ball.radius + (ball.radius - finalY);
                }
                while (finalY > aiFieldHeight - ball.radius) {
                    finalY = aiFieldHeight - ball.radius - (finalY - (aiFieldHeight - ball.radius));
                }

                return finalY;
            }

            // High precision simulation
            simX += simVelX * timeStep;
            simY += simVelY * timeStep;
            currentTime += timeStep;

            // Handle wall bounces with perfect physics
            if (simY <= ball.radius) {
                simY = ball.radius;
                simVelY = Math.abs(simVelY); // Ensure upward movement
            } else if (simY >= aiFieldHeight - ball.radius) {
                simY = aiFieldHeight - ball.radius;
                simVelY = -Math.abs(simVelY); // Ensure downward movement
            }

            // Handle side wall bounces (shouldn't happen in normal play, but just in case)
            if (simX <= ball.radius || simX >= aiFieldWidth - ball.radius) {
                simVelX = -simVelX;
                simX = simX <= ball.radius ? ball.radius : aiFieldWidth - ball.radius;
            }
        }

        // Fallback - shouldn't reach here in normal gameplay
        return aiFieldHeight / 2;
    }
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
    GOD; // Omniscient AI with perfect prediction, fakeouts, and time-wasting abilities
}
