package backend.modchartSystem.modifiers.troll;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import objects.notes.Strumline;

// From Troll Engine: Swaps the position of the player and opponent strums
class OpponentMod extends Modifier
{
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 200;
    unknown = false;
    strumsMod = true;
  }

  inline function sign(x:Int)
		return x == 0 ? 0 : (x <= -1 ? -1 : 1);

  override function strumMath(data:NoteData, strumLine:Strumline):Void
  {
    if (currentValue == 0) return; // skip math if mod is 0

    var distX = FlxG.width / MegaManager.playfield.allStrumLines.length;

		data.x += distX * sign((strumLine.playerNum + 1) * 2 - 3) * currentValue;
    // any pN > 0 should go right whereas any pN < 0 should go left
  }
}
