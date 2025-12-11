package backend.funkinmodchart.engine.modifiers.list.false_paradise;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;
import flixel.math.FlxAngle;

class Wiggle extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var wiggle = getPercent('wiggle', params.player);
		curPos.x += sin(params.curBeat) * wiggle * 20;
		curPos.y += sin(params.curBeat + 1) * wiggle * 20;

		setPercent('rotateZ', (sin(params.curBeat) * 0.2 * wiggle) * FlxAngle.TO_DEG);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getPercent('wiggle', params.player) != 0;
}
