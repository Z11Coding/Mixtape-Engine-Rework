package backend.modules;

import flixel.FlxBasic;

/**
 * A plugin which enables and disables fullscreen.
 */
class FullScreenPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new FullScreenPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Fullscreen Keybind = Toggles Fullscreen lol
    if (Controls.instance?.justPressed('fullscreen'))
    {
      FlxG.fullscreen = !FlxG.fullscreen;
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
