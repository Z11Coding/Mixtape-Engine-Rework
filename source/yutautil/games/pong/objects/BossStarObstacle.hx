package yutautil.games.pong.objects;

import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * Star obstacle sprite for boss mode GOD phase with custom data properties
 */
class BossStarObstacle extends FlxSprite
{
    public var isActive:Bool;
    public var timer:Float;

    public function new(x:Float = 0, y:Float = 0)
    {
        super(x, y);

        isActive = false;
        timer = 0;

        makeGraphic(8, 8, FlxColor.YELLOW);
    }

    public function activate(duration:Float):Void
    {
        isActive = true;
        timer = duration;
        color = FlxColor.RED; // Change to red when active
    }

    public function deactivate():Void
    {
        isActive = false;
        timer = 0;
        color = FlxColor.YELLOW; // Change back to yellow when inactive
    }

    public function setTimer(value:Float):Void
    {
        timer = value;
    }

    public function getTimer():Float
    {
        return timer;
    }

    public function getActive():Bool
    {
        return isActive;
    }
}
