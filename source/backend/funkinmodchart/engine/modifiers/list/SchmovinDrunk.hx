package backend.funkinmodchart.engine.modifiers.list;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;

class SchmovinDrunk extends Modifier {
	final thtdiv = 1 / 222;

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var phaseShift = params.lane * 0.5 + (params.distance * thtdiv) * Math.PI;
		curPos.x += sin(params.curBeat * .25 * Math.PI + phaseShift) * ARROW_SIZEDIV2 * getPercent('schmovinDrunk', params.player);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
