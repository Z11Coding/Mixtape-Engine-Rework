package backend.modchart.modifiers.shmoovin.false_paradise;

class Vibrate extends NoteModifier {
	override function getName()
		return 'vibrate';

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField){
		var vib = getValue(player);
		pos.x += (Math.random() - 0.5) * vib * 20;
		pos.y += (Math.random() - 0.5) * vib * 20;

		return pos;
	}
}
