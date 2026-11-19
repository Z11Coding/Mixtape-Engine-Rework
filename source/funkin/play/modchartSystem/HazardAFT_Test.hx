package funkin.play.modchartSystem;

import flixel.FlxG;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import lime.graphics.Image;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import flixel.FlxCamera;
import flixel.util.FlxColor;

// import funkin.graphics.FunkinCamera;
class HazardAFT_Test
{
  // Set to true if you want it to not clear out the old bitmap data
  public var recursive:Bool = true;

  // The camera to target (copy the pixels from)
  // TODO -> CHANGE THIS TO BE AN ARRAY OF CAMERAS
  public var targetCAM:FlxCamera = null;

  // Multiply the bitmap data by this amount ! Useful for limiting the effects of recursive
  public var alpha:Float = 1.0;

  // The actual bitmap data
  public var bitmap:BitmapData;

  // For limiting the AFT update rate. Useful to make it less framerate dependent.
  // TODO -> Make a public function called limitAFT() which takes a target FPS (like the mirin template plugin)
  public var updateTimer:Float = 0.0;
  public var updateRate:Float = 0.25;

  // Just a basic rectangle which fills the entire bitmap when clearing out the old pixel data
  var rec:Rectangle;

  public var blendMode:String = "normal";
  public var colTransf:ColorTransform;

  var previousBitmapData:BitmapData = null;

  public var trueAFT:Bool = false;

  var framesSinceStarted:Int = 0;

  public var copyFilters:Bool = false;
  public var testTEST:Bool = false;

  public function updateAFT():Void
  {
    bitmap.lock();

    if (trueAFT && recursive && alpha > 0.0)
    {
      if (!recursive || alpha == 0)
      {
        clearAFT();
        bitmap.draw(targetCAM.canvas);
      }
      else
      {
        if (framesSinceStarted < 5)
        {
          // bitmap.draw(targetCAM.canvas, null, null, blendMode);
        }
        else
        {
          trace("spicy take!");
          // bitmap.draw(targetCAM.grabScreen(false, false));
          bitmap.draw(targetCAM.canvas, null, null, blendMode);
          var alphaMod:Int = Std.int(alpha * 255);
          var cTransform:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0 - alphaMod);

          bitmap.colorTransform(rec, cTransform);
        }

        framesSinceStarted++;

        // clearAFT();
        // var alphaMod:Int = Std.int(alpha * 255);
        // var cTransform:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0 - alphaMod);
        // bitmap.draw(targetCAM.canvas);
        // bitmap.colorTransform(rec, cTransform);

        /*
          clearAFT();

          if (previousBitmapData != null)
          {
            bitmap = previousBitmapData.clone();
            var alphaMod:Int = Std.int(alpha * 255);
            var cTransform:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0 - alphaMod);
            bitmap.colorTransform(rec, cTransform);
          }
          else
          {
            previousBitmapData = new BitmapData(w, h, true, 0);
            // trace("created previous data!\n" + previousBitmapData);
          }
          // bitmap = previousBitmapData.clone();
          // var alphaMod:Int = Std.int(alpha * 255);
          // var cTransform:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0 - alphaMod);
          // bitmap.colorTransform(rec, cTransform);
          // bitmap.draw(targetCAM.canvas, null, cTransform, blendMode);
          bitmap.draw(targetCAM.canvas, null, null, blendMode);
          previousBitmapData = bitmap.clone();
         */
      }
    }
    else
    {
      bitmap.disposeImage();
      if (!recursive)
      {
        clearAFT();
      }
      if (testTEST)
      {
        var wasX:Float = targetCAM.flashSprite.x;
        var wasY:Float = targetCAM.flashSprite.y;
        targetCAM.flashSprite.x = 0;
        targetCAM.flashSprite.y = 0;
        bitmap.draw(targetCAM.flashSprite);
        targetCAM.flashSprite.x = wasX;
        targetCAM.flashSprite.y = wasY;
      }
      else
      {
        bitmap.draw(targetCAM.canvas);
      }
    }

    /*
      if (!recursive || alpha == 0) // clear out the old bitmap data before drawing
      {

        bitmap.draw(targetCAM.canvas);
      }
      else
      {

        if (previousBitmapData != null)
        {
          bitmap = previousBitmapData.clone();
          var alphaMod:Int = Std.int(alpha * 255);
          var cTransform:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0 - alphaMod);
          bitmap.colorTransform(rec, cTransform);
          // trace("Bitmap data copied from previous!\n" + bitmap);
        }
        else
        {
          previousBitmapData = new BitmapData(w, h, true, 0);
          // trace("created previous data!\n" + previousBitmapData);
        }
        // bitmap.draw(targetCAM.canvas, null, colTransf, blendMode);

        previousBitmapData = bitmap.clone();
        // trace("end.bitmapdata-previous: \n" + previousBitmapData);
      }
     */

    if (copyFilters && targetCAM.filtersEnabled)
    {
      // for each(i in iterable) x 1000
      for (f in targetCAM.filters)
      {
        bitmap.applyFilter(bitmap, rec, null, f);
      }
    }

    bitmap.unlock();
  }

  // clear out the old bitmap data
  public function clearAFT():Void
  {
    bitmap.fillRect(rec, 0);
  }

  public function targetFps(fps:Float = 60)
  {
    if (fps == 0)
    {
      updateRate = 0;
    }
    else
    {
      updateRate = 1 / fps;
    }
  }

  public function update(elapsed:Float = 0.0):Void
  {
    if (targetCAM != null && bitmap != null)
    {
      if (updateTimer >= 0 && updateRate != 0)
      {
        updateTimer -= (elapsed / FlxG.timeScale);
      }
      else if (updateTimer < 0 || updateRate == 0)
      {
        updateTimer = updateRate;
        updateAFT();
      }
    }
  }

  public var w:Int = 0;
  public var h:Int = 0;

  public function new(cameraTarget:FlxCamera, width:Int = -1, height:Int = -1)
  {
    if (width == -1 || height == -1)
    {
      width = FlxG.width;
      height = FlxG.height;
    }
    this.targetCAM = cameraTarget;
    bitmap = new BitmapData(width, height, true, 0);
    rec = new Rectangle(0, 0, width, height);
    colTransf = new ColorTransform();
    w = width;
    h = height;
  }
}
