package backend.modchartSystem.modifiers.shmoovin;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import objects.notes.Strumline;

// From Shmoovin': Makes the notes shake, sometimes voilently
class VibrateMod extends Modifier {

  // If above 0.0, will also vibrate the Z-Axis. Othewise, only shake X and Y
  var vibrateZ:ModifierSubValue;

  var strumResultX:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  var strumResultY:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  var strumResultZ:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  public function new(name:String)
  {
    super(name, 0);
    unknown = false;
    strumsMod = true;
    notesMod = true;
    holdsMod = true;
    pathMod = true;
    vibrateZ = createSubMod("vibrateZ", 0.0);
  }

  override public function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false) {
    if (currentValue != 0) {
      data.x -= strumResultX[data.direction];
      data.y -= strumResultY[data.direction];
    }
    if (vibrateZ.value != 0)
      data.z -= strumResultZ[data.direction];
	}

	override public function strumMath(data:NoteData, strumLine:Strumline) {
    if (currentValue == 0)
    {
      strumResultX[data.direction] = 0.0;
      strumResultY[data.direction] = 0.0;
    }
    else
    {
      var vib = currentValue;
      strumResultX[data.direction] += (Math.random() - 0.5) * vib * 20;
      strumResultY[data.direction] += (Math.random() - 0.5) * vib * 20;
      data.x += strumResultX[data.direction];
      data.y += strumResultY[data.direction];
    }

    if (vibrateZ.value == 0)
    {
      strumResultZ[data.direction] = 0.0;
    }
    else
    {
      var vib = vibrateZ.value;
      strumResultZ[data.direction] += (Math.random() - 0.5) * vib * 20;
      data.z += strumResultZ[data.direction];
    }
	}

}
