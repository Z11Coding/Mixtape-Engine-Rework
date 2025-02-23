package archipelago.console;

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

class MainTab extends TabSprite {
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

		nickname = new TextField();
		nickname.selectable = false;
		var format = TabSprite.getDefaultFormat();
		format.size = 20;
		nickname.defaultTextFormat = format;
		nickname.width = widthTab;
		nickname.y = 20;
		nickname.x = widthTab / 2 - nickname.width / 2;
		addChild(nickname);

		info = new TextField();
		info.selectable = false;
		info.wordWrap = true;
		var format = TabSprite.getDefaultFormat();
		format.size = 15;
		info.defaultTextFormat = format;
		info.width = widthTab;
		info.y = 40;
		info.x = widthTab / 2 - nickname.width / 2;
		addChild(info);

		chatInput = new TextField();
		chatInput.defaultTextFormat = TabSprite.getDefaultFormat();
		chatInput.text = "";
		chatInput.type = INPUT;
		chatInput.width = Std.int(widthTab);

		chatInputPlaceholder = new TextField();
		chatInputPlaceholder.defaultTextFormat = TabSprite.getDefaultFormat();
		chatInputPlaceholder.text = "(Click here or press TAB to chat)";
		chatInputPlaceholder.selectable = false;
		chatInputPlaceholder.y = Lib.application.window.height - (chatInputPlaceholder.textHeight + 5);
		chatInputPlaceholder.width = Std.int(widthTab);

		chatInput.y = chatInputPlaceholder.y;

		chatBg = new Bitmap(new BitmapData(Std.int(widthTab), Std.int(chatInputPlaceholder.textHeight + 5), true, FlxColor.fromRGB(0, 0, 0, 200)));
		chatBg.y = Lib.application.window.height - chatBg.height;
		addChild(chatBg);
		addChild(chatInputPlaceholder);
		addChild(chatInput);
	}

	override function create() {
		chatInput.addEventListener(Event.CHANGE, _ -> {
			chatInputPlaceholder.visible = chatInput.text.length <= 0;
		});

		updateMessages();
	}

	public static function addMessage(raw:Dynamic) {
		var data = CoolUtil.parseLog(raw);

		var msg:TextField = new TextField();
		var format = TabSprite.getDefaultFormat();
		format.color = data.hue != null ? FlxColor.fromHSL(data.hue, 1.0, 0.8) : FlxColor.WHITE;
		msg.defaultTextFormat = format;
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

	override function keyDown(event:KeyboardEvent):Void {
		if (stage.focus == chatInput && event.keyCode == 13) {
			if (APEntryState.ap != null) {
				APEntryState.ap.Say(chatInput.text);
			}
			else {
				addMessage("Not connected to the server!");
			}
			
			chatInput.text = '';
			chatInput.dispatchEvent(new Event(Event.CHANGE, true));
		}
	}

	override function mouseDown(e:MouseEvent):Void {
		if (e.localX < width && e.localY >= Lib.application.window.height - chatBg.height - 5) {
			stage.focus = chatInput;
		}
	}

	override function mouseWheel(e:MouseEvent):Void {
		msgSprite.y += e.delta * 30;

		if (msgSprite.y <= 0)
			msgSprite.y = 0;
		if (msgSprite.y >= msgSprite.height)
			msgSprite.y = msgSprite.height;
	}

	override function onShow() {
		var songsLeft = [];
		for (song in APEntryState.apGame.info().missingLocations)
			songsLeft.push(APEntryState.apGame.info().get_location_name(song));
		nickname.text = APEntryState.inArchipelagoMode ? APEntryState.ap.slot : "Archipelago Not Active!";
		info.text = 
		  "Song Needed for Completion: "+APEntryState.victorySong
		+ "\nDeathLink: "+APEntryState.deathLink
		+ "\nTotal Song Amount: "+APEntryState.fullSongCount
		+ "\nSongs Left: "+ songsLeft.toString()
		+ "\nHint Cost: "+ APEntryState.apGame.info().hintCostPoints
		+ "\nHint Points Left: "+ APEntryState.apGame.info().hintPoints
		+ "\nCurrent Run Time: "+ APEntryState.apGame.info().localConnectTime;

		nickname.x = widthTab / 2 - nickname.width / 2;
		updateMessages();
	}
}