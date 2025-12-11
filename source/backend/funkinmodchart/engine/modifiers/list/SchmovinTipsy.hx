package backend.funkinmodchart.engine.modifiers.list;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;

class SchmovinTipsy extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		curPos.y += sin(params.curBeat / 4 * Math.PI + params.lane) * ARROW_SIZEDIV2 * getPercent('schmovinTipsy', params.player);
		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
