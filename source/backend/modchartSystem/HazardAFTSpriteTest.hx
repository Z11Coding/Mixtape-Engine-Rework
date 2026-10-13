package backend.modchartSystem;

import backend.modchartSystem.HazardAFT;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import funkin.graphics.ZSprite;
import lime.graphics.Image;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

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
