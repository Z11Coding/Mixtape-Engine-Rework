package backend.modchartSystem.modifiers.troll;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import flixel.math.FlxMath;
import objects.notes.Strumline;

// From Troll Engine: Makes the strums, come to the notes! (like Drive2, but the notes are pre-placed, and it goes both up AND down)
class ReceptorScrollMod extends Modifier
{
  var moveSpeed:ModifierSubValue;
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 200;
    unknown = false;
    strumsMod = true;
    notesMod = true;
    holdsMod = true;
    pathMod = true;
    moveSpeed = createSubMod("movespeed", beatTime * 4, ["speed"]);
  }

  inline function lerp(a:Float,b:Float,c:Float){
    return a+(b-a)*c;
  }

  override function strumMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var diff = data.strumTime;
    var sPos = songTime;
    var vDiff = -(diff - sPos) / moveSpeed.value;
    var reversed = Math.floor(vDiff)%2 == 0;

    var startY = data.y;
    var revPerc = reversed ? 1-vDiff%1 : vDiff%1;
    // haha perc 30
    var upscrollOffset = 50;
    var downscrollOffset = FlxG.height - 150;

    var endY = upscrollOffset + ((downscrollOffset - ModConstants.strumSize * 0.5) * revPerc);

    data.y = lerp(startY, endY, currentValue);
  }

  override function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var speed = strumLine.scrollSpeed * data.speedMod;

		var timeDiff = (strumLine.conductorInUse.musicPosition - data.curPos);

		var diff = timeDiff;
		var sPos = strumLine.conductorInUse.musicPosition;

    var songPos = sPos / moveSpeed.value;
		var notePos = -(diff - sPos) / moveSpeed.value;

    if(Math.floor(songPos)!=Math.floor(notePos)){
			data.alpha *= .1;
    }
  }
}
