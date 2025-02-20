package backend.modules;

import flixel.FlxBasic;

/**
 * A plugin which forcibly crashes the application.
 * TODO: Should we disable this in release builds?
 */
class ForceCrashPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ForceCrashPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Ctrl + Shift + L = Crash the game for debugging purposes
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.L)
    {
      // TODO: Make this message 87% funnier.
      throw "You Shouldn't Have Done That.";
      Sys.exit(1); //Makes sure the came closes
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
