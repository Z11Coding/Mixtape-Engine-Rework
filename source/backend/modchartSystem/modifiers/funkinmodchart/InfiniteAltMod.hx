package backend.modchartSystem.modifiers.funkinmodchart;

import backend.math.CoolMath;
import backend.math.Vector3;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import flixel.math.FlxMath;
import objects.notes.Strumline;

// From Funkin' Modchart: Makes the notes go in an infinite symbol path
class InfiniteAltMod extends Modifier {
  public function new(name:String)
  {
    super(name, 0);
    modPriority = 21;
    pathMod = true;
    notesMod = true;
    holdsMod = true;
    strumsMod = true;
  }

	override function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false) {
		var perc = (currentValue/100);

		if (perc == 0)
			return;

		var infinite = new Vector3();

		// alternate the angles
		var rat = data.direction % 2 == 0 ? 1 : -1;
		// adding 45° so arrow hit position is at center
		var fTime = (-data.curPos * Math.PI * 0.001) + rat * Math.PI / 2;
		// used for make the curve
		final invTransf = (2 / (3 - cos(fTime * 2)));

		// apply the scroll
		infinite.setTo(FlxG.width * .5 + invTransf * cos(fTime) * 580, FlxG.height * .5 + invTransf * (sin(fTime * 2) * .5) * 750, 0);

		var pos:Vector3 = new Vector3(data.x, data.y, data.z);
    pos.lerp(infinite, perc, pos);
    data.x = pos.x;
    data.y = pos.y;
    data.z = pos.z;
	}

	override function strumMath(data:NoteData, strumLine:Strumline) {
		var perc = (currentValue/100);

		if (perc == 0)
			return;

		var infinite = new Vector3();

		// alternate the angles
		var rat = data.direction % 2 == 0 ? 1 : -1;
		// adding 45° so arrow hit position is at center
		var fTime = (-data.curPos * Math.PI * 0.001) + rat * Math.PI / 2;
		// used for make the curve
		final invTransf = (2 / (3 - cos(fTime * 2)));

		// apply the scroll
		infinite.setTo(FlxG.width * .5 + invTransf * cos(fTime) * 580, FlxG.height * .5 + invTransf * (sin(fTime * 2) * .5) * 750, 0);

		var pos:Vector3 = new Vector3(data.x, data.y, data.z);
    pos.lerp(infinite, perc, pos);
    data.x = pos.x;
    data.y = pos.y;
    data.z = pos.z;
	}
}
