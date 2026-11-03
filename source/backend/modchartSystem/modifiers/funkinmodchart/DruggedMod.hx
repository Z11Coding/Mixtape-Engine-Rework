package backend.modchartSystem.modifiers.funkinmodchart;

import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import backend.modchartSystem.modifiers.CustomPathModifier.TrollCustomPathMod;
import flixel.math.FlxMath;
import objects.notes.Strumline;

// From Shmoovin': Gives the notes a suspicious bottle
class Drugged extends Modifier {
  public function new(name:String)
  {
    super(name, 0);
    specialMod = true;
    pathMod = true;
    notesMod = true;
    holdsMod = true;
    strumsMod = true;
  }

	override public function strumMath(data:NoteData, strumLine:Strumline) {
		var amplitude = 1.;
		var frequency = 1.;

		var x = (data.curPos * 0.009) + (data.direction * 0.125);
		var y = 0.;
		y = sin(x * frequency);
		var t = 0.01 * (-strumLine.conductorInUse.musicPosition * 0.0025 * 130.0);
		y += sin(x * frequency * 2.1 + t) * 4.5;
		y += sin(x * frequency * 1.72 + t * 1.121) * 4.0;
		y += sin(x * frequency * 2.221 + t * 0.437) * 5.0;
		y += sin(x * frequency * 3.1122 + t * 4.269) * 2.5;
		y *= amplitude * 0.06;

		data.x += y * (currentValue/100) * ModConstants.strumSize * 0.8;
	}

	override public function noteMath(data:NoteData, strumLine:Strumline, ?isHoldNote = false, ?isArrowPath:Bool = false) {
		var drug = (currentValue/100);

		var amplitude = 1.;
		var frequency = 1.;

		var x = (data.curPos * 0.025) + (data.direction * 0.3);
		var y = 0.;
		y = sin(x * frequency);
		var t = 0.01 * (-strumLine.conductorInUse.musicPosition * 0.005 * 130.0);
		y += sin(x * frequency * 2.1 + t) * 4.5;
		y += sin(x * frequency * 1.72 + t * 1.121) * 4.0;
		y += sin(x * frequency * 2.221 + t * 0.437) * 5.0;
		y += sin(x * frequency * 3.1122 + t * 4.269) * 2.5;
		y *= amplitude * 0.06;

		y = -FlxMath.bound(y, -1, 1);

		var squishX = 1 + FlxMath.bound(y, -1, 0) * -1 * 0.6;
		var squishY = 1 + FlxMath.bound(y, 0, 1) * 0.6;

		data.scaleX = FlxMath.lerp(data.scaleX, data.scaleX * squishX, drug);
		data.scaleY = FlxMath.lerp(data.scaleY, data.scaleY * squishY, drug);

		var preproduct = Math.asin(y);
		// var cosdY = cos(preproduct);

		data.stealth = FlxMath.lerp(data.stealth, y * -.7, drug);
		data.stealthGlowRed = FlxMath.lerp(data.stealthGlowRed, data.stealthGlowRed - (0.5 + sin(preproduct * 1.4) * .5), drug);
		data.stealthGlowGreen = FlxMath.lerp(data.stealthGlowGreen, data.stealthGlowGreen + (0.4 + cos(preproduct * 0.5) * .6), drug);
		data.stealthGlowBlue = FlxMath.lerp(data.stealthGlowBlue, data.stealthGlowBlue - (0.2 + tan(preproduct) * .8), drug);

		data.x += y * drug;
	}
}
