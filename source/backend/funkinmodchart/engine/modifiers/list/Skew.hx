package backend.funkinmodchart.engine.modifiers.list;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;
import backend.funkinmodchart.backend.core.VisualParameters;
import backend.funkinmodchart.backend.util.ModchartUtil;

class Skew extends Modifier {
	var xID = 0;
	var yID = 0;

	public function new(pf) {
		super(pf);

		xID = findID('skewX');
		yID = findID('skewY');
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final receptorName = Std.string(params.lane);
		final player = params.player;

		final x = getUnsafe(xID, player) + getPercent('skewX' + receptorName, player);
		final y = getUnsafe(yID, player) + getPercent('skewY' + receptorName, player);

		data.skewX += x;
		data.skewY += y;

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
