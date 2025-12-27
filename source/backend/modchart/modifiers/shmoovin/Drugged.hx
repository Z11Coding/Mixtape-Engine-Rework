package backend.modchart.modifiers.shmoovin;

import backend.funkinmodchart.backend.util.ModchartUtil;
import flixel.math.FlxMath;

class Drugged extends NoteModifier {
	override function getName()return 'drugged';
	override function isRenderMod()return true;
	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField) {
		var amplitude = 1.;
		var frequency = 1.;

		var x = (timeDiff * 0.009) + (data * 0.125);
		var y = 0.;
		y = sin(x * frequency);
		var t = 0.01 * (-Conductor.songPosition * 0.0025 * 130.0);
		y += sin(x * frequency * 2.1 + t) * 4.5;
		y += sin(x * frequency * 1.72 + t * 1.121) * 4.0;
		y += sin(x * frequency * 2.221 + t * 0.437) * 5.0;
		y += sin(x * frequency * 3.1122 + t * 4.269) * 2.5;
		y *= amplitude * 0.06;

		pos.x += y * getValue(player) * Note.swagWidth * 0.8;

		return pos;
	}

	override public function getExtraInfo(diff:Float, tDiff:Float, beat:Float, info:RenderInfo, obj:NoteObject, player:Int, column:Int):RenderInfo {
		var drug = getValue(player);

		var amplitude = 1.;
		var frequency = 1.;

		var x = (tDiff * 0.025) + (column * 0.3);
		var y = 0.;
		y = sin(x * frequency);
		var t = 0.01 * (-Conductor.songPosition * 0.005 * 130.0);
		y += sin(x * frequency * 2.1 + t) * 4.5;
		y += sin(x * frequency * 1.72 + t * 1.121) * 4.0;
		y += sin(x * frequency * 2.221 + t * 0.437) * 5.0;
		y += sin(x * frequency * 3.1122 + t * 4.269) * 2.5;
		y *= amplitude * 0.06;

		y = -FlxMath.bound(y, -1, 1);

		var squishX = 1 + FlxMath.bound(y, -1, 0) * -1 * 0.6;
		var squishY = 1 + FlxMath.bound(y, 0, 1) * 0.6;

		info.scale.y *= squishX * drug;
		info.scale.y *= squishY * drug;

		var preproduct = Math.asin(y);
		// var cosdY = cos(preproduct);

		info.glow = y * -.7;
		setOtherValue('flashR-a', getSubmodValue('flashR-a', player) - 0.5 + sin(preproduct * 1.4) * .5, player);
		setOtherValue('flashG-a', getSubmodValue('flashG-a', player) + 0.4 + cos(preproduct * 0.5) * .6, player);
		setOtherValue('flashB-a', getSubmodValue('flashB-a', player) - 0.2 + tan(preproduct) * .8, player);

		return info;

		// curPos.x += y * getPercent('drugged', params.player);
	}
}
