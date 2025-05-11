package backend.util;

import flixel.graphics.FlxGraphic;

//? P-Slice utility class (I think)
class FunkinTools
{
	public static function makeSolidColor(sprite:FlxSprite, width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FlxSprite
	{
		// Create a tiny solid color graphic and scale it up to the desired size.
		var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
		sprite.frames = graphic.imageFrame;
		sprite.scale.set(width / 2.0, height / 2.0);
		sprite.updateHitbox();

		return sprite;
	}
}