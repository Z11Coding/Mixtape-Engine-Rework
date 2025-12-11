package backend.funkinmodchart.engine.modifiers.list;

import backend.funkinmodchart.backend.core.ArrowData;
import backend.funkinmodchart.backend.core.ModifierParameters;
import backend.funkinmodchart.backend.util.ModchartUtil;
import flixel.FlxG;

class CenterRotate extends Rotate {
	override public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		return new Vector3(FlxG.width * 0.5, HEIGHT * 0.5);
	}

	override public function getRotateName():String
		return 'centerRotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
