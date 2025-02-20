import flixel.FlxSprite;
import flixel.FlxCamera;

class PsychCameraSprite extends FlxSprite
{
    public var camera:FlxCamera;

    public function new(X:Float = 0, Y:Float = 0)
    {
        super(X, Y);
        camera = new FlxCamera(X, Y, width, height);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        camera.update(elapsed);
    }

    public function updateFollowDelta(?elapsed:Float = 0):Void
    {
        if (camera.target != null)
        {
            if (camera.deadzone == null)
            {
                camera.target.getMidpoint(camera._point);
                camera._point.addPoint(camera.targetOffset);
            }
            else
            {
                // Update deadzone logic here
            }
        }
    }

    public function updateScroll():Void
    {
        camera.updateScroll();
    }

    public function updateFlash(elapsed:Float):Void
    {
        camera.updateFlash(elapsed);
    }

    public function updateFade(elapsed:Float):Void
    {
        camera.updateFade(elapsed);
    }

    public function updateFlashSpritePosition():Void
    {
        camera.updateFlashSpritePosition();
    }

    public function updateShake(elapsed:Float):Void
    {
        camera.updateShake(elapsed);
    }
}