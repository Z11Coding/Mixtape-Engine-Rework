package backend.modules;

import cutscenes.DialogueBoxPsych;
import flixel.FlxBasic;

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
      if (Main.CommandPrompt.instance == null)
      yutautil.Threader.runInThread(new Main.CommandPrompt().start(), 0, "cmd", true, 0);

    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
