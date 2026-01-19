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
class SserafimLipSyncSprite extends FunkinSprite
{
  var shouldSing(default, set):Bool = true;

  function set_shouldSing(value:Bool):Bool
  {
    shouldSing = value;

    if (!value)
    {
      anim.curAnim.curFrame = 0;
    }

    return value;
  }

  public function new(x:Float, y:Float, ?suffix:String)
  {
    super(x, y);

    loadTextureAtlas(suffix != null ? 'sserafim-lipsync-' + suffix : 'sserafim-lipsync', "sserafim");
    anim.addBySymbol("lipsync", this.getDefaultSymbol(), 24, false);
    anim.play("lipsync", true);
  }

  override function update(elapsed:Float):Void
  {
    if (this.anim.curAnim != null && shouldSing)
    {
      this.anim.curAnim.curFrame = Math.floor((Conductor.songPosition / 1000) * 24) - 1;
    }
  }
}
