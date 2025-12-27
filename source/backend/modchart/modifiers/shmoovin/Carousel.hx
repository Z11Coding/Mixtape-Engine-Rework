package backend.modchart.modifiers.shmoovin;

class Carousel extends NoteModifier {
  override function getName()return 'carousel';

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:NoteObject, field:NoteField) {
		var carouselVal = getValue(player);

		if (carouselVal == 0)
			return pos;

		var speed = getSubmodValue('carouselSpeed', player);
		if (speed == 0)
			speed = 1.0;

		var keyCount = field.field.keyCount;
		var playerCount = 2;
		var totalKeys = keyCount * playerCount;
		var globalLane = (player * keyCount) + data;
		var spacing = Note.swagWidth * 2;
		var totalWidth = totalKeys * spacing;
		var timeMultiplier = (Conductor.songPosition + visualDiff) * 0.001 * Math.abs(speed);
		var carouselSpeed = timeMultiplier * Note.swagWidth * Math.abs(carouselVal);
		var initialPosition = globalLane * spacing;
		var carouselOffset;

		if (carouselVal > 0) {
			carouselOffset = carouselSpeed;
		} else {
			carouselOffset = -carouselSpeed;
		}

		var carouselPosition = initialPosition + carouselOffset;

		carouselPosition = carouselPosition % totalWidth;
		if (carouselPosition < 0) {
			carouselPosition += totalWidth;
		}

		var screenCenter = FlxG.width * 0.5;
		var carouselCenter = totalWidth * 0.5;
		var leftOffset = -(FlxG.width * 0.5);
		var newX = screenCenter - carouselCenter + carouselPosition - leftOffset;
		var leftBound = -spacing * 2;
		var rightBound = FlxG.width + spacing * 2;

		while (newX < leftBound) {
			newX += totalWidth;
		}
		while (newX > rightBound) {
			newX -= totalWidth;
		}

		var originalX = field.field.strumNotes[data].x;
		pos.x += (newX - originalX);

		return pos;
	}

	override function getSubmods() {
		return ['carouselSpeed'];
	}
}
