package yutautil.games.pong.backend;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import yutautil.games.pong.backend.PongGame.PongGameMode;

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
    public var gameMode:PongGameMode = PLAYER_VS_AI; // Current game mode

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

    // Boss mode properties
    public var freezeTimer:Float = 0; // Timer for freeze effect from special balls
    public var bossModeDashLimit:Int = 0; // Dash limit for YES difficulty in boss mode
    public var bossModeDashUsed:Int = 0; // Number of dashes used in boss mode

    // Dash mechanic
    public var dashEnabled:Bool = false;
    public var dashCooldown:Float = 0;
    public var dashSpeed:Float = 1500; // Faster dash speed for shorter, more impactful dashes
    public var isDashing:Bool = false;
    public var dashDuration:Float = 0.5; // Half-second dash duration
    public var dashTimer:Float = 0;
    public var dashCooldownMax:Float = 2.0; // 2 second cooldown

    // AI dash behavior tracking
    public var aiJustHitBall:Bool = false;
    public var aiHitBallCooldown:Float = 0;
    public var aiHitBallCooldownMax:Float = 0.5; // Don't dash for 0.5 seconds after hitting ball

    // Dash ghost trail
    public var dashTrail:Array<{x:Float, y:Float, time:Float, alpha:Float}> = [];
    public var dashTrailEnabled:Bool = true;

    // Boost mechanic
    public var boostEnabled:Bool = false;
    public var boostCooldown:Float = 0;
    public var boostCooldownMax:Float = 3.0; // 3 second cooldown
    public var boostActiveTimer:Float = 0;
    public var boostActiveTime:Float = 0.6; // Time window for boost to affect ball
    public var boostAmount:Float = 300; // Amount of momentum to add to ball - dramatically increased for major impact

    // Callbacks for visual effects
    public var onBoostActivated:Void->Void = null;
    public var onSuccessfulBoost:(ball:PongBall)->Void = null;

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
                                aiGodModeActive = false;

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

        // Update freeze timer
        if (freezeTimer > 0) {
            freezeTimer -= elapsed;
            if (freezeTimer <= 0) {
                freezeTimer = 0;
            }
            // If frozen, skip all movement
            return;
        }

        // Update dash mechanics
        updateDash(elapsed);

        // Update boost mechanics
        updateBoost(elapsed);

        if (isPlayer) {
            updatePlayerInput();
        } else {
            updateAI(elapsed, ball);
        }

        // Apply movement (with dash speed multiplier if dashing)
        var currentSpeed = isDashing ? dashSpeed : speed;
        y += velocity * elapsed * (currentSpeed / speed);

        // Keep within bounds
        y = FlxMath.bound(y, minY, maxY);
    }

    private function updatePlayerInput():Void {
        if (isLeftPaddle) {
            // Left paddle - use custom keys only in single player mode
            if (gameMode == PLAYER_VS_AI) {
                // Single player - use customizable keys (default W/S/A)
                var upKey = FlxG.save.data.pongLeftUpKey != null ? FlxG.save.data.pongLeftUpKey : FlxKey.W;
                var downKey = FlxG.save.data.pongLeftDownKey != null ? FlxG.save.data.pongLeftDownKey : FlxKey.S;
                var dashKey = FlxG.save.data.pongLeftDashKey != null ? FlxG.save.data.pongLeftDashKey : FlxKey.A;

                if (FlxG.keys.checkStatus(upKey, PRESSED)) {
                    velocity = -speed;
                } else if (FlxG.keys.checkStatus(downKey, PRESSED)) {
                    velocity = speed;
                }
                // Left paddle dash with custom key
                if (dashEnabled && FlxG.keys.checkStatus(dashKey, JUST_PRESSED)) {
                    tryDash();
                }

                // Left paddle boost with same key as dash (A)
                if (boostEnabled && FlxG.keys.checkStatus(dashKey, JUST_PRESSED)) {
                    tryBoost();
                }
            } else {
                // Multiplayer - use default W/S/A keys
                if (FlxG.keys.pressed.W) {
                    velocity = -speed;
                } else if (FlxG.keys.pressed.S) {
                    velocity = speed;
                }
                // Left paddle dash with A key
                if (dashEnabled && FlxG.keys.justPressed.A) {
                    tryDash();
                }

                // Left paddle boost with A key
                if (boostEnabled && FlxG.keys.justPressed.A) {
                    tryBoost();
                }
            }
        } else {
            // Right paddle uses UP/DOWN arrow keys (not customizable)
            if (FlxG.keys.pressed.UP) {
                velocity = -speed;
            } else if (FlxG.keys.pressed.DOWN) {
                velocity = speed;
            }
            // Right paddle dash with Right Shift key
            if (dashEnabled && FlxG.keys.justPressed.SHIFT) {
                tryDash();
            }

            // Right paddle boost with Right Shift key
            if (boostEnabled && FlxG.keys.justPressed.SHIFT) {
                tryBoost();
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

        // UNIVERSAL AI DASH LOGIC: Apply to YES and GOD when they're positioning normally
        if ((aiDifficulty == YES || aiDifficulty == GOD) && dashEnabled && canDash() && !aiJustHitBall && ball != null) {
            var isMovingTowardsPaddle = (x < ball.position.x && ball.velocity.x < 0) ||
                                       (x > ball.position.x && ball.velocity.x > 0);

            if (isMovingTowardsPaddle) {
                var timeToReach = Math.abs((x - ball.position.x) / ball.velocity.x);

                if (timeToReach < 1.0 && timeToReach > 0.2) {
                    var paddleCenter = y + height / 2;
                    var distanceToTarget = Math.abs(aiTargetY - paddleCenter);
                    var maxNormalDistance = speed * timeToReach;

                    // Simple check: if we can't reach target in time with normal movement, dash
                    if (maxNormalDistance < distanceToTarget) {
                        var dashProbability = aiDifficulty == YES ? 0.95 : 1.0; // GOD always dashes
                        if (FlxG.random.float() < dashProbability) {
                            tryDash();
                        }
                    }
                }
            }
        }

        // AI BOOST LOGIC: Check if AI should use boost
        if (boostEnabled && canBoost() && ball != null) {
            var currentStrategy = "normal"; // Default strategy

            // Get current strategy for YES difficulty
            if (aiDifficulty == YES) {
                currentStrategy = aiStrategy;
            }

            // Check if AI should boost based on difficulty and strategy
            if (shouldAIBoost(ball, currentStrategy)) {
                tryBoost();
            }
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

        // Basic following - no dash logic needed as they just follow current position
        if (aiPrediction <= 0.3) {
            return ballCenter;
        }

        // Predictive following with integrated dash decision
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

            // BASIC AI INTEGRATED DASH: Simple distance/time calculation for HARD/EXPERT
            if (dashEnabled && canDash() && !aiJustHitBall && timeToReach < 0.8 && timeToReach > 0.2) {
                var paddleCenter = y + height / 2;
                var distanceToTarget = Math.abs(predictedY - paddleCenter);
                var maxNormalDistance = speed * timeToReach;

                // Simple check: if we can't reach it with normal movement, dash
                if (maxNormalDistance < distanceToTarget) {
                    var dashProbability = aiDifficulty == HARD ? 0.8 : (aiDifficulty == EXPERT ? 0.9 : 0.7);
                    if (FlxG.random.float() < dashProbability) {
                        tryDash();
                    }
                }
            }            return predictedY;
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
        var predictedHitPoint = predictMultipleBounces(ball, 3); // Predict up to 3 bounces ahead        // Apply strategy-based adjustments
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

        var timeStep = 0.5 / FlxG.updateFramerate; // Higher precision simulation (half timestep)
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

                // GOD AI INTEGRATED DASH: Simple distance/time calculation (dash when needed, even during antics)
                if (dashEnabled && canDash() && !aiJustHitBall && aiDifficulty == GOD && exactTimeToReach < 1.2) {
                    // Layer 1: We know where ball will go (finalY)
                    // Layer 2: Simple calculation - can we reach it in time?
                    var paddleCenter = y + height / 2;
                    var distanceToTarget = Math.abs(finalY - paddleCenter);
                    var maxNormalDistance = speed * exactTimeToReach;

                    if (exactTimeToReach > 0.25) {
                        // If we can't reach it with normal movement, dash (GOD AI makes perfect decisions)
                        if (maxNormalDistance < distanceToTarget) {
                            // GOD AI will dash even during antics if absolutely necessary
                            tryDash();
                        }
                    }
                }                return finalY;
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

        var timeStep = 1.0 / FlxG.updateFramerate; // Use actual game framerate
        var maxTime = 10.0; // Don't simulate more than 10 seconds
        var currentTime = 0.0;
        var bounces = 0;
        var usedComplexPrediction = false; // Track if we actually did multi-bounce calculations

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
                var predictedY = simY + simVelY * timeToReach;

                // Mark that we used complex prediction if simulation took meaningful time
                usedComplexPrediction = currentTime > 0.3 || bounces > 0;

                // YES AI INTEGRATED DASH: Simple distance/time calculation (removed usedComplexPrediction requirement)
                if (dashEnabled && canDash() && !aiJustHitBall && aiDifficulty == YES) {
                    // Layer 1: We know where ball will go (predictedY)
                    // Layer 2: Simple calculation - can we reach it in time?
                    var paddleCenter = y + height / 2;
                    var distanceToTarget = Math.abs(predictedY - paddleCenter);
                    var maxNormalDistance = speed * timeToReach;

                    if (timeToReach < 1.0 && timeToReach > 0.3) {
                        // If we can't reach it with normal movement, dash
                        if (maxNormalDistance < distanceToTarget && FlxG.random.float() < 0.95) {
                            tryDash();
                        }
                    }
                }                return predictedY;
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

        // Fallback to simple prediction (no dash for fallback)
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

    /**
     * Update dash mechanics
     */
    private function updateDash(elapsed:Float):Void {
        if (!dashEnabled && !isDashing) return;

        // Update cooldown
        if (dashCooldown > 0) {
            dashCooldown -= elapsed;
        }

        // Update AI hit ball cooldown
        if (aiHitBallCooldown > 0) {
            aiHitBallCooldown -= elapsed;
            if (aiHitBallCooldown <= 0) {
                aiJustHitBall = false;
            }
        }

        // Update dash timer and trail
        if (isDashing) {
            dashTimer -= elapsed;

            // Add trail point while dashing
            if (dashTrailEnabled) {
                dashTrail.push({
                    x: x,
                    y: y,
                    time: 0.4, // Trail duration
                    alpha: 0.8
                });
            }

            if (dashTimer <= 0) {
                isDashing = false;
            }
        }

        // Update dash trail
        if (dashTrailEnabled) {
            var i = dashTrail.length - 1;
            while (i >= 0) {
                dashTrail[i].time -= elapsed;
                dashTrail[i].alpha = dashTrail[i].time / 0.4; // Fade out over time

                if (dashTrail[i].time <= 0) {
                    dashTrail.splice(i, 1);
                }
                i--;
            }
        }
    }

    /**
     * Attempt to dash (returns true if successful)
     */
    public function tryDash():Bool {
        if (!dashEnabled || dashCooldown > 0 || isDashing) {
            return false;
        }

        // Boss mode dash limitation for YES difficulty
        if (bossModeDashLimit > 0 && bossModeDashUsed >= bossModeDashLimit ) {
            return false; // Exceeded dash limit in boss mode
        }

        isDashing = true;
        dashTimer = dashDuration;
        dashCooldown = dashCooldownMax;

        // Increment boss mode dash counter if applicable
        if (bossModeDashLimit > 0) {
            bossModeDashUsed++;
        }

        return true;
    }

    /**
     * Check if dash is available
     */
    public function canDash():Bool {
        // Boss mode dash limitation check
        if (bossModeDashLimit > 0 && bossModeDashUsed >= bossModeDashLimit) {
            return false;
        }

        return dashEnabled && dashCooldown <= 0 && !isDashing;
    }

    /**
     * Get dash cooldown progress (0 = ready, 1 = just used)
     */
    public function getDashCooldownProgress():Float {
        if (!dashEnabled) return 0;
        return dashCooldown / dashCooldownMax;
    }

    /**
     * Call this when the paddle hits the ball (prevents immediate dash)
     */
    public function onBallHit():Void {
        aiJustHitBall = true;
        aiHitBallCooldown = aiHitBallCooldownMax;
    }

    /**
     * Check if paddle should apply boost to ball and do so if active
     * Returns true if boost was applied
     */
    public function checkBoostBallInteraction(ball:PongBall):Bool {
        if (!isBoostActive()) return false;

        // Apply momentum to ball
        ball.addMomentum(boostAmount);

        // Reset boost active timer since we used it
        boostActiveTimer = 0;

        // Trigger successful boost callback
        if (onSuccessfulBoost != null) {
            onSuccessfulBoost(ball);
        }

        return true;
    }

    // ================================
    // BOOST MECHANICS
    // ================================

    /**
     * Attempt to boost (returns true if successful)
     */
    public function tryBoost():Bool {
        if (!boostEnabled || boostCooldown > 0 || boostActiveTimer > 0) {
            return false;
        }

        boostActiveTimer = boostActiveTime;
        boostCooldown = boostCooldownMax;

        // Trigger visual effect callback
        if (onBoostActivated != null) {
            onBoostActivated();
        }

        return true;
    }

    /**
     * Check if boost is available
     */
    public function canBoost():Bool {
        return boostEnabled && boostCooldown <= 0 && boostActiveTimer <= 0;
    }

    /**
     * Get boost cooldown progress (0 = ready, 1 = just used)
     */
    public function getBoostCooldownProgress():Float {
        if (!boostEnabled) return 0;
        return boostCooldown / boostCooldownMax;
    }

    /**
     * Check if boost is currently active (within the effect window)
     */
    public function isBoostActive():Bool {
        return boostActiveTimer > 0;
    }

    /**
     * Get boost amount for momentum application
     */
    public function getBoostAmount():Float {
        return boostAmount;
    }

    /**
     * Update boost mechanics
     */
    private function updateBoost(elapsed:Float):Void {
        if (!boostEnabled) return;

        // Update cooldown
        if (boostCooldown > 0) {
            boostCooldown -= elapsed;
        }

        // Update active timer
        if (boostActiveTimer > 0) {
            boostActiveTimer -= elapsed;
        }
    }

    /**
     * AI decision making for boost usage
     */
    public function shouldAIBoost(ball:PongBall, aiStrategy:String = "normal"):Bool {
        if (!boostEnabled || !canBoost()) return false;

        // Don't boost if ball is moving away from us
        var ballTowardsPaddle = isLeftPaddle ? ball.velocity.x < 0 : ball.velocity.x > 0;
        if (!ballTowardsPaddle) return false;

        // Calculate time until ball reaches our X position
        var paddleX = isLeftPaddle ? x + width : x;
        var ballTimeToReach = Math.abs((ball.position.x - paddleX) / ball.velocity.x);

        // Much more restrictive timing - only boost when ball is very close (about to hit)
        // AI should only boost when ball is literally just about to reach the paddle
        if (ballTimeToReach > boostActiveTime * 0.3) return false; // Much more restrictive - from 0.8x to 0.3x

        // Much more restrictive distance check - ball must be very close (within ~100px of paddle)
        var ballDistance = Math.abs(ball.position.x - paddleX);
        var quarterFieldWidth = 100; // Much closer threshold - roughly 1/8 of field width
        if (ballDistance > quarterFieldWidth) return false;

        // Base boost probability based on difficulty
        var baseProbability = switch (aiDifficulty) {
            case EASY: 0.01; // Very rare boost usage
            case NORMAL: 0.03; // Low chance
            case HARD: 0.08; // Moderate chance
            case EXPERT: 0.15; // Good chance
            case YES: 0.05; // Strategy-based (will be modified below)
            case GOD: 0.25; // High base chance (will be modified below)
        };

        // Strategy-based modifications for YES difficulty
        if (aiDifficulty == YES) {
            baseProbability = switch (aiStrategy) {
                case "aggressive": 0.35; // Much more likely when aggressive
                case "tricky": 0.15; // Moderate chance when tricky
                case "defensive": 0.03; // Low chance when defensive
                default: 0.08; // Default normal chance
            };
        }

        // GOD difficulty strategic boost logic
        if (aiDifficulty == GOD) {
            // GOD AI boosts more strategically - when ball is coming fast or at critical moments
            var ballSpeed = Math.sqrt(ball.velocity.x * ball.velocity.x + ball.velocity.y * ball.velocity.y);
            if (ballSpeed > speed * 1.5 && ballTimeToReach < boostActiveTime * 0.2) {
                baseProbability = 0.4; // High chance for strategic boost
            } else if (ballTimeToReach < boostActiveTime * 0.15) {
                baseProbability = 0.6; // Very high chance when ball is very close
            }
        }

        return FlxG.random.float() < baseProbability;
    }

    // ================================
    // AI DECISION MAKING
    // ================================

    /**
     * AI decision making for dash usage - based on prediction capabilities and timing
     */
    private function shouldAIDash(ball:PongBall):Bool {
        if (!dashEnabled || !canDash()) return false;

        // Never dash right after hitting the ball
        if (aiJustHitBall) return false;

        // Don't dash if ball is moving away from us
        var ballTowardsPaddle = isLeftPaddle ? ball.velocity.x < 0 : ball.velocity.x > 0;
        if (!ballTowardsPaddle) return false;

        // Don't dash if we're in "messing around" mode (God difficulty)
        if (aiDifficulty == GOD && aiMessAroundActive) return false;

        var paddleCenter = y + height / 2;
        var paddleX = isLeftPaddle ? x + width : x;
        var ballTimeToReach = Math.abs((ball.position.x - paddleX) / ball.velocity.x);

        // Don't consider dashing if ball is too close (less than 0.2 seconds away)
        if (ballTimeToReach < 0.2) return false;

        // Split logic based on AI prediction capability
        if (aiPrediction > 0.5) {
            // PREDICTION-BASED AI: Only dash after making a prediction
            return shouldPredictiveAIDash(ball, paddleCenter, ballTimeToReach);
        } else {
            // BASIC AI: Only dash reactively for urgent situations
            return shouldBasicAIDash(ball, paddleCenter, ballTimeToReach);
        }
    }

    /**
     * Dash logic for AIs that use predictions (HARD, EXPERT, YES, GOD)
     */
    private function shouldPredictiveAIDash(ball:PongBall, paddleCenter:Float, ballTimeToReach:Float):Bool {
        // Calculate predicted target position (same logic as calculateAITarget)
        var predictedBallY:Float;
        var isMovingTowardsPaddle = (x < ball.position.x && ball.velocity.x < 0) ||
                                   (x > ball.position.x && ball.velocity.x > 0);

        if (isMovingTowardsPaddle) {
            // Predict where ball will be when it reaches paddle
            var timeToReach = Math.abs((x - ball.position.x) / ball.velocity.x);
            var predictedY = ball.position.y + ball.velocity.y * timeToReach;

            // Account for wall bounces in prediction
            if (predictedY < 0 || predictedY > (maxY + height)) {
                predictedY = ball.position.y + ball.velocity.y * timeToReach * 0.5;
            }
            predictedBallY = predictedY;
        } else {
            predictedBallY = ball.position.y; // Fallback to current position
        }

        // Calculate where paddle center would be with normal speed by the time ball arrives
        var currentDistance = Math.abs(predictedBallY - paddleCenter);
        var maxNormalMove = speed * ballTimeToReach; // How far we can move normally

        // Calculate where paddle would be positioned with normal movement
        var predictedPaddleCenter:Float;
        if (predictedBallY > paddleCenter) {
            // Ball above us, we'd move up
            predictedPaddleCenter = paddleCenter + Math.min(maxNormalMove, currentDistance);
        } else {
            // Ball below us, we'd move down
            predictedPaddleCenter = paddleCenter - Math.min(maxNormalMove, currentDistance);
        }

        // Check paddle bounds at predicted position with normal movement
        var normalPaddleTop = predictedPaddleCenter - height / 2;
        var normalPaddleBottom = predictedPaddleCenter + height / 2;

        // Check if ANY part of the paddle bounds would be at the predicted ball position
        var wouldHitWithNormalMovement = predictedBallY >= normalPaddleTop && predictedBallY <= normalPaddleBottom;

        // If we would hit with normal movement, no need to dash
        if (wouldHitWithNormalMovement) return false;

        // Now check if we could hit with dash movement
        var maxDashMove = dashSpeed * ballTimeToReach; // How far we can move with dash
        var predictedDashPaddleCenter:Float;
        if (predictedBallY > paddleCenter) {
            predictedDashPaddleCenter = paddleCenter + Math.min(maxDashMove, currentDistance);
        } else {
            predictedDashPaddleCenter = paddleCenter - Math.min(maxDashMove, currentDistance);
        }

        // Check paddle bounds at predicted position with dash movement
        var dashPaddleTop = predictedDashPaddleCenter - height / 2;
        var dashPaddleBottom = predictedDashPaddleCenter + height / 2;

        // Check if ANY part of the paddle bounds would be at the predicted ball position with dash
        var wouldHitWithDashMovement = predictedBallY >= dashPaddleTop && predictedBallY <= dashPaddleBottom;

        // Only dash if:
        // 1. We wouldn't hit with normal movement
        // 2. We would hit with dash movement
        // 3. The movement distance is significant enough to warrant dashing
        if (!wouldHitWithNormalMovement && wouldHitWithDashMovement && currentDistance > height * 0.3) {
            // High probability for predictive AIs since they calculated the need accurately
            var dashProbability = switch (aiDifficulty) {
                case HARD: 0.85;
                case EXPERT: 0.95;
                case YES: 0.98;
                case GOD: aiMessAroundActive ? 0.0 : 1.0;
                default: 0.8; // Shouldn't happen but safety fallback
            };
            return FlxG.random.float() < dashProbability;
        }

        return false;
    }    /**
     * Dash logic for basic AIs that don't use predictions (EASY, NORMAL)
     */
    private function shouldBasicAIDash(ball:PongBall, paddleCenter:Float, ballTimeToReach:Float):Bool {
        // For basic AI, only react to current ball position, but still check bounds properly
        var ballY = ball.position.y;

        // Only consider urgent situations (ball close to reaching us)
        if (ballTimeToReach > 0.8) return false; // Not urgent enough

        // Calculate where paddle bounds would be with normal speed
        var currentDistance = Math.abs(ballY - paddleCenter);
        var maxNormalMove = speed * ballTimeToReach; // How far we can move normally

        // Calculate where paddle would be positioned with normal movement
        var predictedPaddleCenter:Float;
        if (ballY > paddleCenter) {
            // Ball above us, we'd move up
            predictedPaddleCenter = paddleCenter + Math.min(maxNormalMove, currentDistance);
        } else {
            // Ball below us, we'd move down
            predictedPaddleCenter = paddleCenter - Math.min(maxNormalMove, currentDistance);
        }

        // Check paddle bounds at predicted position with normal movement
        var normalPaddleTop = predictedPaddleCenter - height / 2;
        var normalPaddleBottom = predictedPaddleCenter + height / 2;

        // Check if ANY part of the paddle bounds would be at the ball position
        var wouldHitWithNormalMovement = ballY >= normalPaddleTop && ballY <= normalPaddleBottom;

        // If we would hit with normal movement, no need to dash
        if (wouldHitWithNormalMovement) return false;

        // Now check if we could hit with dash movement
        var maxDashMove = dashSpeed * ballTimeToReach; // How far we can move with dash
        var predictedDashPaddleCenter:Float;
        if (ballY > paddleCenter) {
            predictedDashPaddleCenter = paddleCenter + Math.min(maxDashMove, currentDistance);
        } else {
            predictedDashPaddleCenter = paddleCenter - Math.min(maxDashMove, currentDistance);
        }

        // Check paddle bounds at predicted position with dash movement
        var dashPaddleTop = predictedDashPaddleCenter - height / 2;
        var dashPaddleBottom = predictedDashPaddleCenter + height / 2;

        // Check if ANY part of the paddle bounds would be at the ball position with dash
        var wouldHitWithDashMovement = ballY >= dashPaddleTop && ballY <= dashPaddleBottom;

        // Only dash if:
        // 1. We wouldn't hit with normal movement
        // 2. We would hit with dash movement
        // 3. The movement distance is significant (basic AIs need more distance to justify dashing)
        if (!wouldHitWithNormalMovement && wouldHitWithDashMovement && currentDistance > height * 0.5) {
            // Lower probability for basic AIs - they're more hesitant and reactive
            var dashProbability = switch (aiDifficulty) {
                case EASY: 0.5;
                case NORMAL: 0.7;
                default: 0.6; // Safety fallback
            };
            return FlxG.random.float() < dashProbability;
        }

        return false;
    }

    /**
     * Integrated dash decision based on target prediction and timing
     */
    private function shouldAIDashForTarget(ball:PongBall, targetY:Float):Bool {
        if (!dashEnabled || !canDash()) return false;

        // Don't dash if ball is moving away from us
        var ballTowardsPaddle = isLeftPaddle ? ball.velocity.x < 0 : ball.velocity.x > 0;
        if (!ballTowardsPaddle) return false;

        // Don't dash if we're in "messing around" mode (God difficulty)
        if (aiDifficulty == GOD && aiMessAroundActive) return false;

        var paddleCenter = y + height / 2;
        var distanceToTarget = Math.abs(targetY - paddleCenter);

        // Don't dash if we're already close to our target (avoid wasting dash)
        if (distanceToTarget < height * 0.4) return false;

        // Calculate time until ball reaches our X position
        var paddleX = isLeftPaddle ? x + width : x;
        var ballTimeToReach = Math.abs((ball.position.x - paddleX) / ball.velocity.x);

        // Don't dash if ball is too close (less than 0.25 seconds away)
        if (ballTimeToReach < 0.25) return false;

        // Calculate where our paddle bounds would be with normal movement
        var maxNormalMove = speed * ballTimeToReach;
        var normalMoveDistance = Math.min(maxNormalMove, distanceToTarget);

        var normalFinalCenter:Float;
        if (targetY > paddleCenter) {
            normalFinalCenter = paddleCenter + normalMoveDistance;
        } else {
            normalFinalCenter = paddleCenter - normalMoveDistance;
        }

        // Check if we can reach the target with normal movement
        var normalPaddleTop = normalFinalCenter - height / 2;
        var normalPaddleBottom = normalFinalCenter + height / 2;
        var canReachTargetNormally = targetY >= normalPaddleTop && targetY <= normalPaddleBottom;

        // If we can reach the target normally, no need to dash
        if (canReachTargetNormally) return false;

        // Calculate where our paddle bounds would be with dash movement
        var maxDashMove = dashSpeed * ballTimeToReach;
        var dashMoveDistance = Math.min(maxDashMove, distanceToTarget);

        var dashFinalCenter:Float;
        if (targetY > paddleCenter) {
            dashFinalCenter = paddleCenter + dashMoveDistance;
        } else {
            dashFinalCenter = paddleCenter - dashMoveDistance;
        }

        // Check if we can reach the target with dash movement
        var dashPaddleTop = dashFinalCenter - height / 2;
        var dashPaddleBottom = dashFinalCenter + height / 2;
        var canReachTargetWithDash = targetY >= dashPaddleTop && targetY <= dashPaddleBottom;

        // Only dash if:
        // 1. We can't reach target with normal movement
        // 2. We can reach target with dash movement
        // 3. The difference is significant enough to justify the dash
        if (!canReachTargetNormally && canReachTargetWithDash) {
            // Make sure the dash actually helps significantly
            var normalDistanceFromTarget = Math.abs(targetY - normalFinalCenter);
            var dashDistanceFromTarget = Math.abs(targetY - dashFinalCenter);

            if (dashDistanceFromTarget < normalDistanceFromTarget - height * 0.2) {
                // Dash probability based on difficulty - smarter AIs are more confident
                var dashProbability = switch (aiDifficulty) {
                    case NORMAL: 0.6;
                    case HARD: 0.8;
                    case EXPERT: 0.9;
                    case YES: 0.95;
                    case GOD: aiMessAroundActive ? 0.0 : 1.0;
                    default: 0.5;
                };
                return FlxG.random.float() < dashProbability;
            }
        }

        return false;
    }

    /**
     * Simulate paddle movement to see if it can reach target position in time
     * This is the second layer of simulation for AI dash decisions
     */
    private function simulatePaddleMovement(startY:Float, targetY:Float, timeAvailable:Float, withDash:Bool):Bool {
        var currentPaddleY = startY;
        var currentVelocity = 0.0;
        var timeStep = 1.0 / FlxG.updateFramerate; // Use actual game framerate
        var totalTime = 0.0;
        var hasDashed = false;
        var dashCooldown = 0.0;

        // Simulate paddle movement over time
        while (totalTime < timeAvailable) {
            var distanceToTarget = targetY - currentPaddleY;
            var paddleMovement = 0.0;

            // Update dash cooldown
            if (dashCooldown > 0) {
                dashCooldown -= timeStep;
            }

            // Decide if paddle should dash (only once per simulation)
            if (withDash && !hasDashed && dashCooldown <= 0 && Math.abs(distanceToTarget) > height * 0.4) {
                var remainingTime = timeAvailable - totalTime;
                var maxNormalMove = speed * remainingTime;

                if (maxNormalMove < Math.abs(distanceToTarget)) {
                    // Dash needed - simulate dash
                    var dashDistance = dashSpeed * dashDuration;
                    var dashDirection = distanceToTarget > 0 ? 1 : -1;
                    paddleMovement = dashDirection * Math.min(dashDistance, Math.abs(distanceToTarget));
                    hasDashed = true;
                    dashCooldown = dashCooldownMax; // Use actual dash cooldown duration
                } else {
                    // Normal movement
                    paddleMovement = distanceToTarget > 0 ? speed * timeStep : -speed * timeStep;
                }
            } else {
                // Normal movement only
                if (Math.abs(distanceToTarget) > 2.0) { // Small threshold to avoid jitter
                    paddleMovement = distanceToTarget > 0 ? speed * timeStep : -speed * timeStep;
                } else {
                    paddleMovement = distanceToTarget; // Snap to target if very close
                }
            }

            // Update paddle position
            currentPaddleY += paddleMovement;
            totalTime += timeStep;

            // Check if we've reached the target (within paddle height tolerance)
            if (Math.abs(targetY - currentPaddleY) <= height * 0.3) {
                return true; // Success! Paddle can reach target
            }
        }

        // Time ran out - check if we're close enough to hit the ball
        var finalDistance = Math.abs(targetY - currentPaddleY);
        return finalDistance <= height * 0.4; // Allow some tolerance for hitting
    }

    /**
     * Calculate approximate time for ball to reach this paddle
     */
    private function calculateBallTimeToReach(ball:PongBall):Float {
        var ballTowardsPaddle = isLeftPaddle ? ball.velocity.x < 0 : ball.velocity.x > 0;
        if (!ballTowardsPaddle) return -1; // Ball moving away

        var paddleX = isLeftPaddle ? x + width : x;
        var distanceX = Math.abs(ball.position.x - paddleX);
        return distanceX / Math.abs(ball.velocity.x);
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
