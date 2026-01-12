package backend.modules;

import backend.util.TimerUtil;
import flixel.FlxBasic;

/**
 * A plugin which adds functionality to press `Ins` to immediately perform memory garbage collection.
 */
class MemoryGCPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new MemoryGCPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.INSERT)
    {
      var perfStart:Float = TimerUtil.start();
      backend.util.MemoryUtilBase.compact();
      backend.util.MemoryUtilBase.collect(true);
      trace('Memory GC took: ${TimerUtil.seconds(perfStart)}');
    } else if (FlxG.keys.justPressed.DELETE) {
      var perfStart:Float = TimerUtil.start();
      Paths.nukeMemory();
      trace('Memory GC took: ${TimerUtil.seconds(perfStart)}');
      FlxG.resetState();
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
