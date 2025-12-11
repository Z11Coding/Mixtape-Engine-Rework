package backend.funkinmodchart.engine.modifiers.list;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;
import backend.funkinmodchart.backend.util.ModchartUtil;

class OpponentSwap extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final perc = getPercent('opponentSwap', player);

		if (perc == 0)
			return curPos;

		var distX = WIDTH * .5;
		curPos.x -= distX * ModchartUtil.sign((player + 1) * 2 - 3) * perc;
		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
