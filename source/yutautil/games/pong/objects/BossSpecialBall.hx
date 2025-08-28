package yutautil.games.pong.objects;

import flixel.FlxG;
import flixel.util.FlxColor;
import yutautil.games.pong.backend.PongBall;

/**
 * Special ball for boss mode that behaves like a normal Pong ball but with special effects
 */
class BossSpecialBall extends PongBall
{
    public var ballType:String;
    public var ballColor:FlxColor;
    public var isActive:Bool = true; // Replaces FlxSprite.alive

    public function new(fieldW:Float = 800, fieldH:Float = 600, type:String = "normal")
    {
        super(0, 0); // Position will be set later

        ballType = type;

        // Set appearance based on type
        ballColor = switch (type) {
            case "freeze": FlxColor.CYAN;
            case "frantic": FlxColor.MAGENTA;
            case "dash": FlxColor.GREEN;
            case "golden": FlxColor.YELLOW;
            case "fake": FlxColor.GRAY;
            default: FlxColor.WHITE;
        };

        // Make special balls slightly slower than normal balls
        this.speed = 150;

        // Start with random movement
        resetBall();
        serveToPlayer(FlxG.random.bool());
    }

    public function getType():String
    {
        return ballType;
    }

    public function getColor():FlxColor
    {
        return ballColor;
    }

    /**
     * Deactivate this special ball (replaces FlxSprite.kill())
     */
    public function deactivate():Void
    {
        isActive = false;
    }

    /**
     * Check if ball is active (replaces FlxSprite.alive)
     */
    public function isAlive():Bool
    {
        return isActive;
    }

    /**
     * Check if ball scored on right side (needs fieldWidth parameter)
     */
    public override function scoredRight(fieldWidth:Float):Bool {
        return position.x > fieldWidth + radius;
    }

    public function randomizeMovement():Void
    {
        // Randomize direction while keeping similar speed
        var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
        var angle = FlxG.random.float(0, Math.PI * 2);

        velocity.x = Math.cos(angle) * currentSpeed;
        velocity.y = Math.sin(angle) * currentSpeed;
    }
}
