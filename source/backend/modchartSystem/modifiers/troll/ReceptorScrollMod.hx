package backend.modchartSystem.modifiers.troll;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import flixel.math.FlxMath;
import objects.notes.Strumline;

// From Troll Engine: Makes the strums, come to the notes! (like Drive2, but the notes are pre-placed, and it goes both up AND down)
class ReceptorScrollMod extends Modifier
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

  inline function lerp(a:Float,b:Float,c:Float){
    return a+(b-a)*c;
  }

  override function strumMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var diff = data.strumTime;
    var sPos = songTime;
    var vDiff = -(diff - sPos) / strumLine.scrollSpeed;
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

    var diff = data.curPos;
    var sPos = songTime;
    var vDiff = -(diff - sPos) / strumLine.scrollSpeed;
    var reversed = Math.floor(vDiff)%2 == 0;

    var startY = data.y;
    var revPerc = reversed ? 1-vDiff%1 : vDiff%1;
    // haha perc 30
    var upscrollOffset = 50;
    var downscrollOffset = FlxG.height - 150;

    var endY = upscrollOffset + ((downscrollOffset - ModConstants.strumSize * 0.5) * revPerc);

    data.y = lerp(startY, endY, currentValue);

    var songPos = sPos / strumLine.scrollSpeed;
		var notePos = -(diff - sPos) / strumLine.scrollSpeed;

    if(Math.floor(songPos)!=Math.floor(notePos)){
			data.alpha *= .1;
    }
  }
}
