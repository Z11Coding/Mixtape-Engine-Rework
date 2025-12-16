package backend.modchart.modifiers.shmoovin.false_paradise;

import flixel.math.FlxAngle;

class Wiggle extends NoteModifier {
	override function getName()return 'wiggle';

	override function getPos( visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField) {
		var wiggle = getValue(player);
		pos.x += sin(beat) * wiggle * 20;
		pos.y += sin(beat + 1) * wiggle * 20;

		setOtherValue('rotateZ', (sin(beat) * 0.2 * wiggle) * FlxAngle.TO_DEG, player);

		return pos;
	}
}
