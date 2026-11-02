package backend.modchartSystem.modifiers.troll.extra;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import objects.notes.Strumline;

// From Tails Gets Trolled: Bends the note path sideways
class FlaccidMod extends Modifier
{
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 200;
    unknown = false;
    pathMod = true;
    notesMod = true;
    holdsMod = true;
  }

  override function noteMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var f = data.curPos / BaseNote.swagWidth;
		data.x += currentValue * f * f;
    // any pN > 0 should go right whereas any pN < 0 should go left
  }
}
