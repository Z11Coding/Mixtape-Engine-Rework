package backend.modchartSystem.modifiers.shmoovin;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import flixel.math.FlxAngle;
import objects.notes.Strumline;

// From Shmoovin': Makes the notes do a lil boogie
class WiggleMod extends Modifier {
  public function new(name:String)
  {
    super(name, 0);
    unknown = false;
    strumsMod = true;
    notesMod = true;
    holdsMod = true;
    specialMod = true;
    pathMod = true;
  }

  // Apply it to everything
	override public function strumMath(data:NoteData, strumLine:Strumline) {
    if (currentValue == 0) return;

		var wiggle = currentValue;
		data.x += sin(strumLine.conductorInUse.currentBeat) * wiggle * 20;
		data.y += sin(strumLine.conductorInUse.currentBeat + 1) * wiggle * 20;

    // No idea if this works, but its worth a shot lol
		ModConstants.createNewMod('rotatez', true).currentValue = (sin(strumLine.conductorInUse.currentBeat) * 0.2 * wiggle) * FlxAngle.TO_DEG;
	}

  override public function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false) {
    if (currentValue == 0) return;

    var wiggle = currentValue;
		data.x += sin(strumLine.conductorInUse.currentBeat) * wiggle * 20;
		data.y += sin(strumLine.conductorInUse.currentBeat + 1) * wiggle * 20;
	}
}
