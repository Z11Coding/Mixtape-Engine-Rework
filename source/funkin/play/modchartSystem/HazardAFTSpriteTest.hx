package funkin.play.modchartSystem;

import flixel.FlxG;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import lime.graphics.Image;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import funkin.graphics.ZSprite;
import funkin.play.modchartSystem.HazardAFT;

class HazardAFTSpriteTest extends ZSprite
{
  public var aft:HazardAFT;

  public function new(aftTarget:HazardAFT)
  {
    super(0, 0);
    aft = aftTarget;
    makeGraphic(aftTarget.w, aftTarget.h, FlxColor.TRANSPARENT);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    this.pixels = aft.bitmap;
    // aft.bitmap.disposeImage(); // To prevent memory leak lol
  }
}
