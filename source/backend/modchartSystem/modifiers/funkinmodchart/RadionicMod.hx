package backend.modchartSystem.modifiers.funkinmodchart;

import backend.math.CoolMath;
import backend.math.Vector3;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import objects.notes.Strumline;

// From Funkin' Modchart:
// Circular motion based on the lane.
// Naming this `Radionic` since it seems like a Radionic Graphic.
// Inspired by `The Poenix NotITG Modchart` at 0:35
// Warning!: This should be AFTER regular modifiers (drunk, beat, transform, etc) and BEFORE rotation modifiers.
class RadionicMod extends Modifier {
	public function new(name:String)
  {
    super(name, 0);
		unknown = false;
    pathMod = true;
		strumsMod = true;
		notesMod = true;
		holdsMod = true;
	}

	override public function strumMath(data:NoteData, strumLine:Strumline) {
		final perc = (currentValue/100);

		if (perc == 0)
			return;

		final reverse = data.getReverse();
		final reverseMult:Float = FlxMath.remapToRange(reverse, 0, 1, 1, -1);

		final angle = ((1 / strumLine.conductorInUse.currentBeatTime) * ((data.strumPosition + data.curPos) * Math.PI * .25) + (Math.PI * strumLine.playerNum));
		final offsetX = data.x - data.whichStrumNote.x;
		final offsetY = data.y * reverseMult;

		final circf = ModConstants.strumSize + data.direction * ModConstants.strumSize;

		final sinAng = sin(angle);
		final cosAng = cos(angle);

		final radionicVec = new Vector3();

		radionicVec.x = FlxG.width * 0.5 + ((sinAng * offsetY + cosAng * (circf + offsetX)) * 0.7) * 1.125;
		radionicVec.y = FlxG.height * 0.5 + ((cosAng * offsetY + sinAng * (circf + offsetX)) * 0.7) * 0.875;
		radionicVec.z = data.z;

		var curPos:Vector3 = new Vector3(data.x, data.y, data.z);
		curPos.lerp(radionicVec, perc, curPos);
		data.x = curPos.x;
    data.y = curPos.y;
    data.z = curPos.z;

		final amount = 0.6;

		data.scaleX = perc * (data.scaleY = 1 + amount - FlxEase.cubeOut((strumLine.conductorInUse.currentBeat - Math.floor(strumLine.conductorInUse.currentBeat))) * amount);
		data.stealth = perc * (-(amount - FlxEase.cubeOut((strumLine.conductorInUse.currentBeat - Math.floor(strumLine.conductorInUse.currentBeat))) * amount) * 2);
	}

	override public function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false) {
		final perc = (currentValue/100);

		if (perc == 0)
			return;

		final reverse = data.getReverse();
		final reverseMult:Float = FlxMath.remapToRange(reverse, 0, 1, 1, -1);

		final angle = ((1 / strumLine.conductorInUse.currentBeatTime) * ((data.strumPosition + data.curPos) * Math.PI * .25) + (Math.PI * strumLine.playerNum));
		final offsetX = data.x - data.whichStrumNote.x;
		final offsetY = data.y * reverseMult;

		final circf = ModConstants.strumSize + data.direction * ModConstants.strumSize;

		final sinAng = sin(angle);
		final cosAng = cos(angle);

		final radionicVec = new Vector3();

		radionicVec.x = FlxG.width * 0.5 + ((sinAng * offsetY + cosAng * (circf + offsetX)) * 0.7) * 1.125;
		radionicVec.y = FlxG.height * 0.5 + ((cosAng * offsetY + sinAng * (circf + offsetX)) * 0.7) * 0.875;
		radionicVec.z = data.z;

		var curPos:Vector3 = new Vector3(data.x, data.y, data.z);
		curPos.lerp(radionicVec, perc, curPos);
		data.x = curPos.x;
    data.y = curPos.y;
    data.z = curPos.z;

		final amount = 0.6;

		data.scaleX = perc * (data.scaleY = 1 + amount - FlxEase.cubeOut((strumLine.conductorInUse.currentBeat - Math.floor(strumLine.conductorInUse.currentBeat))) * amount);
		data.stealth = perc * (-(amount - FlxEase.cubeOut((strumLine.conductorInUse.currentBeat - Math.floor(strumLine.conductorInUse.currentBeat))) * amount) * 2);
	}
}
