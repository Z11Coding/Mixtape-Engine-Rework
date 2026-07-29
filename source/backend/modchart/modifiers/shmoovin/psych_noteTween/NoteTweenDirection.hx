package backend.modchart.modifiers.shmoovin.psych_noteTween;
import objects.StrumNote;
import states.PlayState;

/**
 * Modifier that acts as a bridge between the engine's noteTweenDirection and the modcharts system.
 * Inherits from Reverse to use the already implemented scrollAngleZ system, except it doesn't need to do that, so it doesn't
 * Reads the current direction value of the StrumNote and converts it to scrollAngleZ.
 */
class NoteTweenDirection extends NoteModifier {
	override function getName() return 'noteTweenDirection';

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:NoteObject, field:NoteField)
	{
		if (obj != null) {
			try {
				// Read the current direction of the StrumNote (modified by noteTweenDirection)
				var currentDirection = field.field.strumNotes[data].direction;

				// Convert direction to scrollAngleZ (default 90 degrees = 0 scrollAngleZ)
				var additionalScrollAngleZ = currentDirection - 90;

				// Apply temporary scrollAngleZ for this render
				var originalScrollAngleZ = getOtherValue('incomingAngleZ-a', player);
				setOtherValue('incomingAngleZ-a', originalScrollAngleZ + additionalScrollAngleZ, player);
			} catch(e) {}
		}

		return pos;
	}
}
