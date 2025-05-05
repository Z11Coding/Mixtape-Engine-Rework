package objects;
import openfl.display.Shape;
import openfl.display.BitmapData;
class Rect extends FlxSprite
{
    public function new(X:Float = 0, Y:Float = 0, width:Float = 0, height:Float = 0, roundWidth:Float = 0, roundHeight:Float = 0, Color:FlxColor = FlxColor.WHITE, ?Alpha:Float = 1)
    {
        super(X, Y);

        loadGraphic(drawRect(width, height, roundWidth, roundHeight));
        antialiasing = ClientPrefs.data.antialiasing;
        color = Color;
        alpha = Alpha;
    }

    function drawRect(width:Float = 0, height:Float = 0, roundWidth:Float = 0, roundHeight:Float = 0):BitmapData {
        var shape:Shape = new Shape();

        shape.graphics.beginFill(0xFFFFFF);
        shape.graphics.drawRoundRect(0, 0, width, height, roundWidth, roundHeight);
        shape.graphics.endFill();

        var bitmap:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
        bitmap.draw(shape);
        return bitmap;
    }
}