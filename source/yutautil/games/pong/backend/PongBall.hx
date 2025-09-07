
package yutautil.games.pong.backend;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

/**
 * Represents the ball in a Pong game
 */
class PongBall {
    public var position:FlxPoint;
    public var velocity:FlxPoint;
    public var radius:Float;
    public var speed:Float;
    public var maxSpeed:Float;
    public var minSpeed:Float;

    // Visual properties
    public var width:Float;
    public var height:Float;

    // Physics properties
    public var bounceSpeedIncrease:Float = 1.05;
    public var maxBounceAngle:Float = 75; // degrees

    // Anti-clip system
    public var antiClipEnabled:Bool = false;
    public var onCollisionCheck:(oldX:Float, oldY:Float, newX:Float, newY:Float) -> Bool = null;
    public var antiClipCooldown:Float = 0.0;
    public var antiClipCooldownDuration:Float = 0.1; // 100ms cooldown after collision detection

    // Momentum system (for boost mechanics)
    public var momentum:Float = 0.0;
    public var momentumDecayRate:Float = 150.0; // Base momentum decay per second - much faster decay for quick burst effect
    public var momentumDecayAcceleration:Float = 2.0; // Acceleration factor for decay - makes decay speed up over time

    // Speed decay system (for when ball exceeds maxSpeed)
    public var speedDecayRate:Float = 50.0; // Speed decay per second when above maxSpeed

    public function new(x:Float = 0, y:Float = 0, radius:Float = 8, speed:Float = 200) {
        this.radius = radius;
        this.width = radius * 2;
        this.height = radius * 2;
        this.speed = speed;
        this.minSpeed = speed * 0.8;
        this.maxSpeed = speed * 2.0;

        position = new FlxPoint(x, y);
        velocity = new FlxPoint();

        resetBall();
    }

    /**
     * Reset ball to center with random direction
     */
    public function resetBall():Void {
        position.x = 0; // Will be set by game based on field center
        position.y = 0;

        // Reset momentum
        resetMomentum();

        // Random angle between -45 and 45 degrees, going left or right
        var angle = FlxG.random.float(-45, 45) * Math.PI / 180;
        var direction = FlxG.random.bool() ? 1 : -1;

        velocity.x = Math.cos(angle) * speed * direction;
        velocity.y = Math.sin(angle) * speed;

        // Ensure minimum speed and that ball isn't too horizontal
        if (Math.abs(velocity.x) < minSpeed * 0.5) {
            velocity.x = velocity.x > 0 ? minSpeed * 0.5 : -minSpeed * 0.5;
        }

        // Ensure ball has some vertical movement
        if (Math.abs(velocity.y) < minSpeed * 0.3) {
            velocity.y = velocity.y > 0 ? minSpeed * 0.3 : -minSpeed * 0.3;
        }
    }

    /**
     * Set ball velocity to launch toward specified player (position should already be set by caller)
     * @param toLeft - true to serve to left player, false to serve to right player
     */
    public function serveToPlayer(toLeft:Bool):Void {
        // Don't reset position - it should already be set to field center by the caller

        // Random angle between -30 and 30 degrees, directed toward the receiving player
        var angle = FlxG.random.float(-30, 30) * Math.PI / 180;
        var direction = toLeft ? -1 : 1; // If serving to left, ball goes left (negative), if serving to right, ball goes right (positive)

        velocity.x = Math.cos(angle) * speed * direction;
        velocity.y = Math.sin(angle) * speed;

        // Ensure minimum speed and that ball isn't too horizontal
        if (Math.abs(velocity.x) < minSpeed * 0.6) {
            velocity.x = velocity.x > 0 ? minSpeed * 0.6 : -minSpeed * 0.6;
        }
    }

    /**
     * Update ball position with anticlip system
     */
    public function update(elapsed:Float):Void {
        // Update anticlip cooldown
        if (antiClipCooldown > 0) {
            antiClipCooldown -= elapsed;
        }

        // Update momentum system
        updateMomentum(elapsed);

        // Update speed decay system (slow down if above maxSpeed)
        updateSpeedDecay(elapsed);

        if (!antiClipEnabled || onCollisionCheck == null) {
            // Normal update with momentum
            applyVelocityWithMomentum(elapsed);
            return;
        }

        // ANTICLIP: Store old position and calculate new position
        var oldX = position.x;
        var oldY = position.y;

        // Calculate new position with momentum consideration
        var newX:Float, newY:Float;
        if (momentum > 0) {
            var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
            if (currentSpeed > 0) {
                var effectiveSpeed = currentSpeed + momentum;
                var directionX = velocity.x / currentSpeed;
                var directionY = velocity.y / currentSpeed;
                newX = position.x + directionX * effectiveSpeed * elapsed;
                newY = position.y + directionY * effectiveSpeed * elapsed;
            } else {
                newX = position.x + velocity.x * elapsed;
                newY = position.y + velocity.y * elapsed;
            }
        } else {
            newX = position.x + velocity.x * elapsed;
            newY = position.y + velocity.y * elapsed;
        }

        // Check if the movement line would intersect with any collision objects
        // Only check if cooldown has expired
        if (antiClipCooldown <= 0 && onCollisionCheck(oldX, oldY, newX, newY)) {
            // Collision detected along the path
            // Move ball to the collision point using line interpolation
            var collisionPoint = findCollisionPoint(oldX, oldY, newX, newY);
            position.x = collisionPoint.x;
            position.y = collisionPoint.y;

            // Start cooldown to prevent immediate re-detection
            antiClipCooldown = antiClipCooldownDuration;

            // Let collision handling take over (don't continue normal movement)
            return;
        }

        // No collision detected or cooldown active, safe to move normally
        position.x = newX;
        position.y = newY;
    }

    /**
     * Find the collision point along the movement line using binary search
     * This helps position the ball at the exact collision point rather than stopping it completely
     */
    private function findCollisionPoint(oldX:Float, oldY:Float, newX:Float, newY:Float):FlxPoint {
        var iterations = 0;
        var maxIterations = 10; // Prevent infinite loops
        var threshold = 0.5; // Pixel accuracy threshold

        var startX = oldX;
        var startY = oldY;
        var endX = newX;
        var endY = newY;

        // Binary search to find collision point
        while (iterations < maxIterations) {
            var midX = (startX + endX) / 2;
            var midY = (startY + endY) / 2;

            // Check if we're close enough
            var distance = Math.sqrt((endX - startX) * (endX - startX) + (endY - startY) * (endY - startY));
            if (distance < threshold) {
                return new FlxPoint(midX, midY);
            }

            // Check collision at midpoint
            if (onCollisionCheck(oldX, oldY, midX, midY)) {
                // Collision happens before midpoint, search first half
                endX = midX;
                endY = midY;
            } else {
                // No collision at midpoint, search second half
                startX = midX;
                startY = midY;
            }

            iterations++;
        }

        // Fallback to start position if binary search fails
        return new FlxPoint(startX, startY);
    }

    /**
     * Bounce off horizontal walls (top/bottom)
     */
    public function bounceVertical():Void {
        velocity.y = -velocity.y;

        // Get base speed and effective speed (with momentum)
        var baseSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        var effectiveSpeed = baseSpeed + momentum;

        // Only increase speed if the base speed would still be under maxSpeed after the increase
        // This allows momentum to exceed maxSpeed while preventing base speed from growing too much
        var potentialNewBaseSpeed = baseSpeed * bounceSpeedIncrease;
        if (potentialNewBaseSpeed <= maxSpeed) {
            velocity.x *= bounceSpeedIncrease;
            velocity.y *= bounceSpeedIncrease;
        }
        // If we can't increase base speed, the effective speed with momentum might still be higher
    }

    /**
     * Bounce off paddle
     */
    public function bouncePaddle(paddleY:Float, paddleHeight:Float, paddleVelocityY:Float = 0):Void {
        // Calculate relative position on paddle (0 = center, -1 to 1 = edges)
        var paddleCenter = paddleY + paddleHeight / 2;
        var relativeHitPos = (position.y - paddleCenter) / (paddleHeight / 2);
        relativeHitPos = FlxMath.bound(relativeHitPos, -1, 1);

        // Calculate new angle based on hit position
        var bounceAngle = relativeHitPos * maxBounceAngle * Math.PI / 180;

        // Get base speed and effective speed (with momentum)
        var baseSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        var effectiveSpeed = baseSpeed + momentum;

        // Use effective speed for bounce physics calculation to account for momentum
        var speedForBounce = effectiveSpeed;

        // Reverse X direction - fix the direction calculation
        var newDirection = velocity.x > 0 ? -1 : 1;

        // Calculate new velocity based on effective speed (including momentum)
        var newVelX = Math.cos(bounceAngle) * speedForBounce * newDirection;
        var newVelY = Math.sin(bounceAngle) * speedForBounce;

        // Add paddle velocity influence
        newVelY += paddleVelocityY * 0.3;

        // Only increase base speed if it would still be under maxSpeed after increase
        var potentialNewBaseSpeed = speedForBounce * bounceSpeedIncrease;

        // If momentum is present, we need to be more careful about speed increases
        if (momentum > 0) {
            // With momentum, only increase if the base speed component would be acceptable
            var baseSpeedAfterBounce = Math.sqrt(newVelX * newVelX + newVelY * newVelY);
            var potentialBaseAfterIncrease = baseSpeedAfterBounce * bounceSpeedIncrease;

            if (potentialBaseAfterIncrease <= maxSpeed) {
                newVelX *= bounceSpeedIncrease;
                newVelY *= bounceSpeedIncrease;
            }
        } else {
            // No momentum, use traditional logic
            if (potentialNewBaseSpeed <= maxSpeed) {
                newVelX *= bounceSpeedIncrease;
                newVelY *= bounceSpeedIncrease;
            }
        }

        // Set the new velocity
        velocity.x = newVelX;
        velocity.y = newVelY;

        // Ensure minimum speed for base velocity
        var finalBaseSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        if (finalBaseSpeed < minSpeed) {
            var scale = minSpeed / finalBaseSpeed;
            velocity.x *= scale;
            velocity.y *= scale;
        }
    }

    /**
     * Check if ball is out of bounds (left or right)
     */
    public function isOutOfBounds(fieldWidth:Float):Bool {
        return position.x < -radius || position.x > fieldWidth + radius;
    }

    /**
     * Check if ball scored on left side
     */
    public function scoredLeft():Bool {
        return position.x < -radius;
    }

    /**
     * Check if ball scored on right side
     */
    public function scoredRight(fieldWidth:Float):Bool {
        return position.x > fieldWidth + radius;
    }

    /**
     * Get ball bounds for collision detection
     */
    public function getBounds():{left:Float, right:Float, top:Float, bottom:Float} {
        return {
            left: position.x - radius,
            right: position.x + radius,
            top: position.y - radius,
            bottom: position.y + radius
        };
    }

    // ================================
    // MOMENTUM SYSTEM
    // ================================

    /**
     * Add momentum to the ball (from boost mechanics)
     */
    public function addMomentum(amount:Float):Void {
        momentum += amount;
    }

    /**
     * Get current momentum
     */
    public function getMomentum():Float {
        return momentum;
    }

    /**
     * Apply momentum to current speed and handle decay
     */
    public function updateMomentum(elapsed:Float):Void {
        // Accelerating decay over time - starts slow and speeds up
        if (momentum > 0) {
            // Calculate dynamic decay rate based on how much momentum remains
            // Lower momentum = faster decay rate for quicker final decay
            var momentumRatio = momentum / 300.0; // Normalize to new boost amount (300)
            var dynamicDecayRate = momentumDecayRate * (1.0 + momentumDecayAcceleration * (1.0 - momentumRatio));

            momentum -= dynamicDecayRate * elapsed;
            if (momentum < 0) momentum = 0;
        }
    }

    /**
     * Update speed decay when ball exceeds maxSpeed
     */
    public function updateSpeedDecay(elapsed:Float):Void {
        // Check if current base speed (without momentum) exceeds maxSpeed
        var currentBaseSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);

        if (currentBaseSpeed > maxSpeed) {
            // Calculate how much we need to reduce the speed
            var excessSpeed = currentBaseSpeed - maxSpeed;
            var reductionAmount = Math.min(speedDecayRate * elapsed, excessSpeed);

            // Scale down the velocity to reduce speed
            var reductionFactor = (currentBaseSpeed - reductionAmount) / currentBaseSpeed;
            velocity.x *= reductionFactor;
            velocity.y *= reductionFactor;

            // Ensure we don't go below maxSpeed
            var newSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
            if (newSpeed < maxSpeed && currentBaseSpeed > maxSpeed) {
                // Scale back up to exactly maxSpeed
                var scaleFactor = maxSpeed / newSpeed;
                velocity.x *= scaleFactor;
                velocity.y *= scaleFactor;
            }
        }
    }

    /**
     * Get the effective speed including momentum
     */
    public function getEffectiveSpeed():Float {
        var baseSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        return baseSpeed + momentum; // Momentum directly adds to speed, can exceed maxSpeed
    }

    /**
     * Apply velocity with momentum consideration
     */
    public function applyVelocityWithMomentum(elapsed:Float):Void {
        if (momentum > 0) {
            // Get current direction
            var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
            if (currentSpeed > 0) {
                // Calculate effective speed with momentum
                var effectiveSpeed = currentSpeed + momentum;

                // Apply the boosted velocity
                var directionX = velocity.x / currentSpeed;
                var directionY = velocity.y / currentSpeed;

                position.x += directionX * effectiveSpeed * elapsed;
                position.y += directionY * effectiveSpeed * elapsed;
            } else {
                // No base velocity, just move normally
                position.x += velocity.x * elapsed;
                position.y += velocity.y * elapsed;
            }
        } else {
            // No momentum, move normally
            position.x += velocity.x * elapsed;
            position.y += velocity.y * elapsed;
        }
    }

    /**
     * Reset momentum (useful when ball resets)
     */
    public function resetMomentum():Void {
        momentum = 0;
    }
}
