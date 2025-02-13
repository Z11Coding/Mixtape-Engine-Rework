package backend.modchart.modifiers;

import backend.modchart.*;
import backend.math.Vector3;
import objects.playfields.NoteField;

class FlaccidModifier extends NoteModifier
{ // Tails did indeed get trolled
	override function getName()
		return "flaccid";

	override function getPos( visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField)
	{
		var f = visualDiff / Note.swagWidth;
		pos.x += this.getValue(player) * f * f;
		
		return pos;
	}
}