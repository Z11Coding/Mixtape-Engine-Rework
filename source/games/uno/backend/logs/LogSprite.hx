package games.uno.backend.logs;

import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Assets;

@:allow(games.uno.backend.UnoTurnSummary)
class LogSprite extends Sprite {
	public var widthTab:Float = 0;

	public function new(width:Float) {
		super();

		widthTab = width;

		if (stage != null)
			_init();
		else
			addEventListener(Event.ADDED_TO_STAGE, _init);
	}

	public static inline function getDefaultFormat() {
		return new TextFormat(Assets.getFont('assets/fonts/vcr.ttf').fontName, 15, 0xFFFFFFFF);
	}

	var initialized:Bool = false;
	function _init(?e):Void {
		if (!initialized)
			create();
		init();

		initialized = true;
	}
	function create():Void {}
	function init():Void {}
}