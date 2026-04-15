package backend.modules;

import cutscenes.DialogueBoxPsych;
import flixel.FlxBasic;

/**
 * A plugin which
 * This is useful
 */
class ArchipelagoDebug extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ArchipelagoDebug());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (APEntryState.inArchipelagoMode && FlxG.keys.justPressed.F7)
    {
      try {
          var apClient = APEntryState.apGame.info();
          if (apClient != null) {
              apClient.Sync();
          } else {
              trace('Warning: AP client is null, skipping sync');
          }
      } catch (e) {
          trace('Error during AP sync: ' + e);
      }
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
