package backend.modchart.modifiers.shmoovin.psych_noteTween;

import objects.StrumNote;
import states.PlayState;

/**
 * Modifier that acts as a bridge between noteTweenAngle of the engine and the modcharts system.
 * Reads the current angle value from StrumNote (modified by noteTweenAngle) and applies it
 * as visual rotation (angleZ) to both receivers and notes.
 */
class NoteTweenAngle extends NoteModifier {
	override function getName()return 'noteTweenAngle';
	override function isRenderMod()return true;

	override function modifyVert(beat:Float, vert:Vector3, idx:Int, obj:NoteObject, pos:Vector3, player:Int, data:Int, field:NoteField):Vector3 {
		var data = vert;
		if (obj != null) {
			// Read the current angle of the StrumNote (modified by noteTweenAngle)
			var currentAngle = obj.angle;

			// Apply to modchart visuals system as visual rotation
			// Now affects both receivers and notes
			var radians = FlxAngle.TO_RAD;
			data = VectorHelpers.rotateV3(
				vert,
				vert.x,
				vert.y += currentAngle,
				vert.z,
				vert
			);
		}

		return data;
	}
}
