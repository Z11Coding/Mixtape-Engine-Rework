package backend.modchartSystem.modifiers.shmoovin;

import backend.math.CoolMath;
import backend.math.Vector3;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import flixel.math.FlxMath;
import objects.notes.Strumline;

// From Shmoovin': Makes the notes go in a counter clockwise direction in the middle of the screen
class CounterClockWiseMod extends Modifier
{
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 200;
    unknown = false;
    strumsMod = true;
    notesMod = true;
    holdsMod = true;
    pathMod = true;
  }

  override function strumMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var strumTime = data.strumPosition + data.curPos;
		var centerX = FlxG.width * .5;
		var centerY = FlxG.height * .5;
		var radiusOffset = ModConstants.strumSize * (data.direction - 1.5);

		var crochet = strumLine.conductorInUse.currentBeatTime;

		var radius = 200 + radiusOffset * cos(strumTime / crochet * .25 / 16 * Math.PI);
		var outX = centerX + cos(strumTime / crochet / 4 * Math.PI) * radius;
		var outY = centerY + sin(strumTime / crochet / 4 * Math.PI) * radius;

    var curPos:Vector3 = new Vector3(data.x, data.y, data.z);
    CoolMath.lerpVector3D(curPos, new Vector3(outX, outY, 0), currentValue);
    data.x = curPos.x;
    data.y = curPos.y;
    data.z = curPos.z;
  }

  override function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var strumTime = data.strumTime + data.curPos;
		var centerX = FlxG.width * .5;
		var centerY = FlxG.height * .5;
		var radiusOffset = ModConstants.strumSize * (data.direction - 1.5);

		var crochet = strumLine.conductorInUse.currentBeatTime;

		var radius = 200 + radiusOffset * cos(strumTime / crochet * .25 / 16 * Math.PI);
		var outX = centerX + cos(strumTime / crochet / 4 * Math.PI) * radius;
		var outY = centerY + sin(strumTime / crochet / 4 * Math.PI) * radius;

    var curPos:Vector3 = new Vector3(data.x, data.y, data.z);
    CoolMath.lerpVector3D(curPos, new Vector3(outX, outY, 0), currentValue);
    data.x = curPos.x;
    data.y = curPos.y;
    data.z = curPos.z;
  }
}
