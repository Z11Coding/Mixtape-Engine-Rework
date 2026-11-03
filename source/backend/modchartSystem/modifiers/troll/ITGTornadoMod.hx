package backend.modchartSystem.modifiers.troll;

import backend.math.CoolMath;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import objects.notes.Strumline;

// From Troll Engine: OpenITG/NotITG Tornado
class ITGTornadoMod extends Modifier
{
  var speed:ModifierSubValue;
  var offset:ModifierSubValue;
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 200;
    unknown = false;
    specialMod = false;
    pathMod = true;
    notesMod = true;
    holdsMod = true;
    strumsMod = true;
    speedMod = false;
    speed = createSubMod("speed", 3.0, ["mult", "period", "size"]);
    offset = createSubMod("offset", 0.0);
  }

  // An array which represents each arrow direction. Used to undo the strum movement for the notes for the offset submod to function
  var strumResult:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  override function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var wide = (ExtraKeys.mania+1) > 4;
    var width = wide ? 2 : 3;
    var startColumn:Int = Std.int(CoolMath.boundTo(data.direction - width, 0, (ExtraKeys.mania+1) - 1));
    var endColumn:Int = Std.int(CoolMath.boundTo(data.direction + width, 0, (ExtraKeys.mania+1) - 1));

    var minX = strumLine.strumLineNotes.members[startColumn].formerPosition.x;
    var maxX = strumLine.strumLineNotes.members[endColumn].formerPosition.x;
    var realPixel = strumLine.strumLineNotes.members[data.direction].formerPosition.x;

    var posBetween = CoolMath.scale(realPixel, minX, maxX, -1, 1);

    var rads = Math.acos(posBetween);
    rads += (data.curPos + offset.value) * (6 + speed.value * 6) / FlxG.height;
    var adjusted = CoolMath.scale(cos(rads), -1, 1, minX, maxX);
    data.x += (adjusted - realPixel) * currentValue;
  }

  override function strumMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var wide = (ExtraKeys.mania+1) > 4;
    var width = wide ? 2 : 3;
    var startColumn:Int = Std.int(CoolMath.boundTo(data.direction - width, 0, (ExtraKeys.mania+1) - 1));
    var endColumn:Int = Std.int(CoolMath.boundTo(data.direction + width, 0, (ExtraKeys.mania+1) - 1));

    var minX = strumLine.strumLineNotes.members[startColumn].formerPosition.x;
    var maxX = strumLine.strumLineNotes.members[endColumn].formerPosition.x;
    var realPixel = strumLine.strumLineNotes.members[data.direction].formerPosition.x;

    var posBetween = CoolMath.scale(realPixel, minX, maxX, -1, 1);

    var rads = Math.acos(posBetween);
    rads += (data.curPos + offset.value) * (6 + speed.value * 6) / FlxG.height;
    var adjusted = CoolMath.scale(cos(rads), -1, 1, minX, maxX);
    data.x += (adjusted - realPixel) * currentValue;
    // any pN > 0 should go right whereas any pN < 0 should go left
  }
}

class ITGTornadoTanMod extends Modifier
{
  var speed:ModifierSubValue;
  var offset:ModifierSubValue;
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 200;
    unknown = false;
    specialMod = false;
    pathMod = true;
    notesMod = true;
    holdsMod = true;
    strumsMod = true;
    speedMod = false;
    speed = createSubMod("speed", 3.0, ["mult", "period", "size"]);
    offset = createSubMod("offset", 0.0);
  }

  // An array which represents each arrow direction. Used to undo the strum movement for the notes for the offset submod to function
  var strumResult:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  override function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var wide = (ExtraKeys.mania+1) > 4;
    var width = wide ? 2 : 3;
    var startColumn:Int = Std.int(CoolMath.boundTo(data.direction - width, 0, (ExtraKeys.mania+1) - 1));
    var endColumn:Int = Std.int(CoolMath.boundTo(data.direction + width, 0, (ExtraKeys.mania+1) - 1));

    var minX = strumLine.strumLineNotes.members[startColumn].formerPosition.x;
    var maxX = strumLine.strumLineNotes.members[endColumn].formerPosition.x;
    var realPixel = strumLine.strumLineNotes.members[data.direction].formerPosition.x;

    var posBetween = CoolMath.scale(realPixel, minX, maxX, -1, 1);

    var rads = Math.acos(posBetween);
    rads += (data.curPos + offset.value) * (6 + speed.value * 6) / FlxG.height;
    var adjusted = CoolMath.scale(tan(rads), -1, 1, minX, maxX);
    data.x += (adjusted - realPixel) * currentValue;
  }

  override function strumMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var wide = (ExtraKeys.mania+1) > 4;
    var width = wide ? 2 : 3;
    var startColumn:Int = Std.int(CoolMath.boundTo(data.direction - width, 0, (ExtraKeys.mania+1) - 1));
    var endColumn:Int = Std.int(CoolMath.boundTo(data.direction + width, 0, (ExtraKeys.mania+1) - 1));

    var minX = strumLine.strumLineNotes.members[startColumn].formerPosition.x;
    var maxX = strumLine.strumLineNotes.members[endColumn].formerPosition.x;
    var realPixel = strumLine.strumLineNotes.members[data.direction].formerPosition.x;

    var posBetween = CoolMath.scale(realPixel, minX, maxX, -1, 1);

    var rads = Math.acos(posBetween);
    rads += (data.curPos + offset.value) * (6 + speed.value * 6) / FlxG.height;
    var adjusted = CoolMath.scale(tan(rads), -1, 1, minX, maxX);
    data.x += (adjusted - realPixel) * currentValue;
    // any pN > 0 should go right whereas any pN < 0 should go left
  }
}
