package stages.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
@:keep
typedef LipSyncData = {
  offset:Array<Int>,
  angle:Int
}

// object used for lip sync on characters in SPAGHETTI
@:keep
class SserafimLipSyncSprite extends FlxAnimate
{
  var shouldSing(default, set):Bool = true;

  function set_shouldSing(value:Bool):Bool
  {
    shouldSing = value;

    if (!value)
    {
      animation.curAnim.curFrame = 0;
    }

    return value;
  }

  public function new(x:Float, y:Float, ?suffix:String)
  {
    super(x, y);

    showPivot = false;
    Paths.loadAnimateAtlas(this, (suffix != null ? 'sserafim-lipsync-' + suffix : 'sserafim-lipsync'));
    animation.addBySymbol("lipsync", this.getDefaultSymbol(), 24, false);
    animation.play("lipsync", true);
  }

  override function update(elapsed:Float):Void
  {
    if (this.animation.curAnim != null && shouldSing)
    {
      this.animation.curAnim.curFrame = Math.floor((Conductor.songPosition / 1000) * 24) - 1;
    }
  }
}
