package games.uno.backend.logs;

import flixel.FlxG;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.events.Event;
import substates.Prompt;
import motion.Actuate;
import openfl.Lib;

class UnoTurnSummary extends Sprite {
	public static var instance:UnoTurnSummary;
	public var cursor:Bitmap;

	var _wasMouseShown:Bool = false;

	public var curTab:LogSprite = null;

	public function new() {
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?e:Event) {
		var bitmap = new Bitmap(new BitmapData(-500, 0, true, FlxColor.fromRGB(255, 255, 255, 190)));
		addChild(bitmap);

		alpha = 1;
		x = 0;

		curTab = new LogSprite(bitmap.width);

		instance = this;
	}
}