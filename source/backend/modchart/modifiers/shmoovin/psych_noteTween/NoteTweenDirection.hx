package backend.modchart.modifiers.shmoovin.psych_noteTween;

import backend.modchart.modifiers.ReverseModifier;
import objects.StrumNote;
import states.PlayState;

/**
 * Modifier that acts as a bridge between the engine's noteTweenDirection and the modcharts system.
 * Inherits from Reverse to use the already implemented scrollAngleZ system.
 * Reads the current direction value of the StrumNote and converts it to scrollAngleZ.
 */
class NoteTweenDirection extends ReverseModifier {
	override function getName() return 'noteTweenDirection';

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:NoteObject, field:NoteField)
	{
		if (obj != null) {
			// Read the current direction of the StrumNote (modified by noteTweenDirection)
			var currentDirection = field.field.strumNotes[data].direction;

			// Convert direction to scrollAngleZ (default 90 degrees = 0 scrollAngleZ)
			var additionalScrollAngleZ = currentDirection - 90;

			// Apply temporary scrollAngleZ for this render
			var originalScrollAngleZ = getOtherValue('incomingAngleZ', player);
			setOtherValue('incomingAngleZ', originalScrollAngleZ + additionalScrollAngleZ, player);

			// Call Reverse render that already handles scrollAngleZ correctly
			var result = super.getPos(visualDiff, timeDiff, beat, pos, data, player, obj, field);

			// Restore the original value of scrollAngleZ
			setOtherValue('incomingAngleZ', originalScrollAngleZ, player);

			return result;
		}

		// If there is no StrumNote, use normal Reverse behavior
		return super.getPos(visualDiff, timeDiff, beat, pos, data, player, obj, field);
	}

	override function shouldExecute(player:Int, val:Float):Bool {
		// Use the same logic as Reverse (runs for all notes)
		return super.shouldExecute(player, val);
	}

	override function getSubmods(){
		return super.getSubmods();
	}
}
