
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

        // Debug trace - can remove later
        trace("Ball reset - velocity: " + velocity.x + ", " + velocity.y);
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

        // Debug trace
        trace("Ball served to " + (toLeft ? "left" : "right") + " player - position: " + position.x + ", " + position.y + " velocity: " + velocity.x + ", " + velocity.y);
    }

    /**
     * Update ball position
     */
    public function update(elapsed:Float):Void {
        position.x += velocity.x * elapsed;
        position.y += velocity.y * elapsed;
    }

    /**
     * Bounce off horizontal walls (top/bottom)
     */
    public function bounceVertical():Void {
        velocity.y = -velocity.y;
        // Add slight speed increase
        var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        if (currentSpeed < maxSpeed) {
            velocity.x *= bounceSpeedIncrease;
            velocity.y *= bounceSpeedIncrease;
        }
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

        // Get current speed
        var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);

        // Reverse X direction - fix the direction calculation
        var newDirection = velocity.x > 0 ? -1 : 1;
        velocity.x = Math.cos(bounceAngle) * currentSpeed * newDirection;
        velocity.y = Math.sin(bounceAngle) * currentSpeed;

        // Add paddle velocity influence
        velocity.y += paddleVelocityY * 0.3;

        // Increase speed slightly
        if (currentSpeed < maxSpeed) {
            velocity.x *= bounceSpeedIncrease;
            velocity.y *= bounceSpeedIncrease;
        }

        // Ensure minimum speed
        currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        if (currentSpeed < minSpeed) {
            var scale = minSpeed / currentSpeed;
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
}
