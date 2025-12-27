package backend.modchart.modifiers.shmoovin.false_paradise;

class CounterClockWise extends NoteModifier {
	override function getName()
		return 'counterClockWise';

	override function getOrder()
		return Modifier.ModifierOrder.LAST - 9;

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField) {
		var strumTime = visualDiff;
		var centerX = FlxG.width * .5;
		var centerY = FlxG.height * .5;
		var radiusOffset = Note.swagWidth * (data - 1.5);

		var crochet = Conductor.crochet;

		var radius = 200 + radiusOffset * cos(strumTime / crochet * .25 / 16 * Math.PI);
		var outX = centerX + cos(strumTime / crochet / 4 * Math.PI) * radius;
		var outY = centerY + sin(strumTime / crochet / 4 * Math.PI) * radius;

		return pos.lerp(new Vector3(outX, outY, 0), getValue(player), pos);
	}
}
