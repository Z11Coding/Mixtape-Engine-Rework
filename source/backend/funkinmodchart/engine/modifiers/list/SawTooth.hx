package backend.funkinmodchart.engine.modifiers.list;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;

class SawTooth extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		final period = 1 + getPercent("sawtoothPeriod", player);
		curPos.x += (getPercent('sawtooth',
			player) * ARROW_SIZE) * ((0.5 / period * params.distance) / ARROW_SIZE - Math.floor((0.5 / period * params.distance) / ARROW_SIZE));

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
