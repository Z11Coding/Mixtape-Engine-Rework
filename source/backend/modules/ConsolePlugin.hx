package backend.modules;

import flixel.FlxBasic;
import cutscenes.DialogueBoxPsych;

/**
 * A plugin which spawns a console if you press the 'console' keybind.
 * This is useful for accessing console commands without compiling the game.
 */
class ConsolePlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ConsolePlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (Controls.instance?.justPressed('console'))
    {
      NativeAPI.allocConsole();
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
