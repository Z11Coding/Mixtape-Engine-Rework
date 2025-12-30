package archipelago.console;

import flash.display.BitmapData;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.geom.Matrix;
import openfl.text.TextField;

class MainTab extends TabSprite {
	var nickname:TextField;
	var info:TextField;
  var chatBg:Bitmap;
	var chatInput:TextField;
	static var messages:Array<FlxText> = [];
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

	static var id:Int = 0;
	public static function addMessage(raw:Dynamic) {
		var data = CoolUtil.parseLog(raw);
		var instance:MainTab = cast SideUI.instance.curTab;

		var msg:FlxText = new FlxText(0, (50*id), Std.int(instance.widthTab), data.content, 15);
		msg.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		msg.wordWrap = true;
		msg.ID = id;
		messages.unshift(msg);

		updateMessages();
		id++;
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
			message.fieldWidth = Std.int(instance.widthTab);
			message.y = lastY = ((lastY ?? Lib.application.window.height - instance.chatBg.height) - (message.fieldHeight + 5)) * message.ID;
			message.update(1);
			var bd:BitmapData = message.framePixels; // or ft.pixels / ft.get_pixels()
			var bmp = new Bitmap(bd);
			instance.msgSprite.addChild(bmp);
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
		nickname.text = APEntryState.inArchipelagoMode ? APEntryState.ap.slot : "Archipelago Not Active!";
		info.text =
		  "Song Needed for Completion: "+APEntryState.victorySong
		+ "\nDeathLink: "+APEntryState.deathLink
		+ "\nTotal Song Amount: "+APEntryState.fullSongCount
		+ "\nHint Cost: "+ APEntryState.apGame.info().hintCostPoints
		+ "\nHint Points Left: "+ APEntryState.apGame.info().hintPoints
		+ "\nCurrent Run Time: "+ APEntryState.apGame.info().localConnectTime;

		nickname.x = widthTab / 2 - nickname.width / 2;
		updateMessages();
		Cursor.cursorMode = Default;
		wasVisible = FlxG.mouse.visible;
		if (!FlxG.mouse.visible) {
			Cursor.show();
		}

	}

	var wasVisible:Bool = false;
	override function onHide() {
		Cursor.hide();
	}

	static var bitmaps:Array<BitmapData> = [];
	static function drawTextAt(text:FlxText, str:String, textX:Float, textY:Float)
	{
		var instance:MainTab = cast SideUI.instance.curTab;

		text.text = str;
		text.updateHitbox();

		var clonedBitmap:BitmapData = text.graphic.bitmap.clone();
		bitmaps.push(clonedBitmap);
		instance?.graphics.beginBitmapFill(clonedBitmap, new Matrix(1, 0, 0, 1, textX, textY), false, false);
		instance?.graphics.drawRect(textX, textY, text.width + textX, text.height + textY);
	}

	function deleteClonedBitmaps()
	{
		for (clonedBitmap in bitmaps)
		{
			if(clonedBitmap != null)
			{
				clonedBitmap.dispose();
				clonedBitmap.disposeImage();
			}
		}
		bitmaps = null;
	}

	public function destroy()
	{
		deleteClonedBitmaps();
	}

}
