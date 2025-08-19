package source.games.uno.backend.logs;

import openfl.events.TextEvent;
import openfl.Lib;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.crypto.Base64;
import openfl.display.Bitmap;
import openfl.text.TextField;
import flash.display.BitmapData;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.display.Sprite;
import openfl.events.Event;

class Logs extends TabSprite {
	var nickname:TextField;	
	var info:TextField;	
    var chatBg:Bitmap;
	var chatInput:TextField;
	static var messages:Array<TextField> = [];
	var msgSprite:Sprite;

	var chatInputPlaceholder:TextField;

	public function new(tabWidth:Float) {
		super(tabWidth);

		msgSprite = new Sprite();
		addChild(msgSprite);

		chatInputPlaceholder = new TextField();
		chatInputPlaceholder.defaultTextFormat = TabSprite.getDefaultFormat();
		chatInputPlaceholder.text = "(Click here or press TAB to chat)";
		chatInputPlaceholder.selectable = false;
		chatInputPlaceholder.y = Lib.application.window.height - (chatInputPlaceholder.textHeight + 5);
		chatInputPlaceholder.width = Std.int(widthTab);

		chatBg = new Bitmap(new BitmapData(Std.int(widthTab), Std.int(chatInputPlaceholder.textHeight + 5), true, FlxColor.fromRGB(0, 0, 0, 200)));
		chatBg.y = Lib.application.window.height - chatBg.height;
		addChild(chatBg);
	}

	override function create() {
		updateMessages();
	}

	public static function addMessage(raw:Dynamic) {
		var data = CoolUtil.parseLog(raw);

		var msg:TextField = new TextField();
		var format = TabSprite.getDefaultFormat();
		format.color = data.hue != null ? FlxColor.fromHSL(data.hue, 1.0, 0.8) : FlxColor.WHITE;
		msg.defaultTextFormat = format;
		msg.height = 10000;
		msg.wordWrap = true;
		msg.text = data.content;
		msg.height = msg.textHeight + 1;
		messages.unshift(msg);

		updateMessages();
	}

	public static function updateMessages() {
		//maybe ill add other tabs later
		if (SideUI.instance?.curTab == null || !(SideUI.instance.curTab is MainTab)) {
			return;
		}

		var instance:MainTab = cast SideUI.instance.curTab;

		if (messages.length > 100) {
			messages.pop();
		}

		instance.msgSprite.removeChildren();

		var lastY:Null<Float> = null;
		for (message in messages) {
			message.width = Std.int(instance.widthTab);
			message.y = lastY = (lastY ?? Lib.application.window.height - instance.chatBg.height) - (message.textHeight + 5);
			instance.msgSprite.addChild(message);
		}
	}

	override function mouseWheel(e:MouseEvent):Void {
		msgSprite.y += e.delta * 30;

		if (msgSprite.y <= 0)
			msgSprite.y = 0;
		if (msgSprite.y >= msgSprite.height)
			msgSprite.y = msgSprite.height;
	}	
}