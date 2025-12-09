package backend.modules;

import cutscenes.DialogueBoxPsych;
import flixel.FlxBasic;

/**
 * A plugin which adds functionality to press `F4` to immediately transition to the main menu.
 * This is useful for debugging or if you get softlocked or something.
 */
class EvacuateDebugPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new EvacuateDebugPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.F4)
    {
      // Don't allow F4 evacuation during trap testing mode
      @:privateAccess
      if (backend.MusicBeatState._trapTestingMode) {
        return;
      }

      FlxG.switchState(new states.MainMenuState());
    }

    if (FlxG.keys.justPressed.F5)
    {
      #if ARCHIPELAGO_ALLOWED
      if (Std.is(FlxG.state, archipelago.APPlayState)) {
        states.PlayState.instance.inCutscene = true;
        states.PlayState.instance.paused = true;
      } else {
        backend.MusicBeatState.revokeControls = true;
      }
      #else
      backend.MusicBeatState.revokeControls = true;
      #end
      var psychDialogue:DialogueBoxPsych;
      psychDialogue = new DialogueBoxPsych(DialogueBoxPsych.parseDialogue(Paths.json('apthings/dialogue/0')));
      psychDialogue.scrollFactor.set();
      psychDialogue.autoScroller = true;
      psychDialogue.finishThing = function() {
        #if ARCHIPELAGO_ALLOWED
        if (Std.is(FlxG.state, archipelago.APPlayState)) {
          states.PlayState.instance.paused = false;
          states.PlayState.instance.inCutscene = false;
        } else {
          backend.MusicBeatState.revokeControls = false;
        }
        #else
        backend.MusicBeatState.revokeControls = false;
        #end
        FlxG.state.remove(psychDialogue);
        psychDialogue = null;
      }
      //psychDialogue.screenCenter();
      FlxG.state.add(psychDialogue);
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
