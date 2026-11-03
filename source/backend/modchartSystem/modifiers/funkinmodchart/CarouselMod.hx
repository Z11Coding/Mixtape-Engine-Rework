package backend.modchartSystem.modifiers.funkinmodchart;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import backend.modchartSystem.modifiers.CustomPathModifier.TrollCustomPathMod;
import objects.notes.Strumline;

// From Funkin' Modchart: Makes the notes revolve around the world
class CarouselMod extends Modifier {
  var carouselspeed:ModifierSubValue;

	public function new(name:String)
  {
    super(name, 0);
    unknown = false;
    notPercentage = true;
    pathMod = true;
    specialMod = true;
    notesMod = true;
    holdsMod = true;
    strumsMod = true;
    carouselspeed = createSubMod("carouselspeed", 0.0);
  }

	override public function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false) {
		var player = strumLine.playerNum;
		var carouselVal = currentValue;

		if (carouselVal == 0)
			return;

		var speed = carouselspeed.value;
		if (speed == 0)
			speed = 1.0;

		var keyCount = (ExtraKeys.mania+1);
		var playerCount = MegaManager.playfield.allStrumLines.length;
		var totalKeys = keyCount * playerCount;
		var globalLane = (player * keyCount) + data.direction;
		var spacing = ModConstants.strumSize * 1.5;
		var totalWidth = totalKeys * spacing;
		var timeMultiplier = data.strumTime * 0.001 * Math.abs(speed);
		var carouselSpeed = timeMultiplier * ModConstants.strumSize * Math.abs(carouselVal);
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
		var leftOffset = ModConstants.strumSize * 0.5;
		var newX = screenCenter - carouselCenter + carouselPosition - leftOffset;
		var leftBound = -spacing * 2;
		var rightBound = FlxG.width + spacing * 2;

		while (newX < leftBound) {
			newX += totalWidth;
		}
		while (newX > rightBound) {
			newX -= totalWidth;
		}

		var originalX = data.lastKnownPosition.x;
		data.x += (newX - originalX);
	}

	override public function strumMath(data:NoteData, strumLine:Strumline) {
		var player = strumLine.playerNum;
		var carouselVal = currentValue;

		if (carouselVal == 0)
			return;

		var speed = carouselspeed.value;
		if (speed == 0)
			speed = 1.0;

		var keyCount = (ExtraKeys.mania+1);
		var playerCount = MegaManager.playfield.allStrumLines.length;
		var totalKeys = keyCount * playerCount;
		var globalLane = (player * keyCount) + data.direction;
		var spacing = ModConstants.strumSize * 1.5;
		var totalWidth = totalKeys * spacing;
		var timeMultiplier = data.strumTime * 0.001 * Math.abs(speed);
		var carouselSpeed = timeMultiplier * ModConstants.strumSize * Math.abs(carouselVal);
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
		var leftOffset = ModConstants.strumSize * 0.5;
		var newX = screenCenter - carouselCenter + carouselPosition - leftOffset;
		var leftBound = -spacing * 2;
		var rightBound = FlxG.width + spacing * 2;

		while (newX < leftBound) {
			newX += totalWidth;
		}
		while (newX > rightBound) {
			newX -= totalWidth;
		}

		var originalX = data.lastKnownPosition.x;
		data.x += (newX - originalX);
	}
}
