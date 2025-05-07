package states.freeplay.osu;

class SongBox extends FlxSprite
{
    public var posY:Float = 0;

    override function update(elapsed:Float):Void {
        var targetY = FlxMath.lerp(y, (FlxG.height - height) / 2 + posY * 82, CoolUtil.boundTo(elapsed * 9, 0, 1));
        y = targetY;
    }

}