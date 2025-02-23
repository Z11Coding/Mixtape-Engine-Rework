package archipelago;

import openfl.events.Event;
import openfl.geom.Matrix;
import flash.display.BitmapData;
import openfl.Lib;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import archipelago.APEntryState;
import flixel.FlxG;
import flixel.tweens.FlxEase;

enum Icon
{
	Color;
	White;
	Any(color:FlxColor);
}

class ArchPopup extends openfl.display.Sprite {
	public var onFinish:Void->Void = null;
	var alphaTween:FlxTween;
	var lastScale:Float = 1;
    public static var daUnlockSong:String = 'Nothing lol';

	public function new(name:String, desc:String, ?song:String, ?image:String, ?onFinish:Void->Void)
	{
		super();

		// bg
		graphics.beginFill(FlxColor.BLACK);
		graphics.drawRoundRect(0, 0, 420, 130, 16, 16);

		// achievement icon
		var graphic = null;
		var hasAntialias:Bool = ClientPrefs.data.globalAntialiasing;
		var image:String = 'globalIcons/$image';

		graphic = Paths.image(image);

		if(graphic == null) graphic = Paths.image('globalIcons/unknownMod');

		var sizeX = 100;
		var sizeY = 100;

		var imgX = 15;
		var imgY = 15;
		var image = graphic.bitmap;
		graphics.beginBitmapFill(image, new Matrix(sizeX / image.width, 0, 0, sizeY / image.height, imgX, imgY), false, hasAntialias);
		graphics.drawRect(imgX, imgY, sizeX + 10, sizeY + 10);

		var textX = sizeX + imgX + 15;
		var textY = imgY + 20;

		var text:FlxText = new FlxText(0, 0, 270, 'TEST!!!', 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		drawTextAt(text, name, textX, textY);
		drawTextAt(text, desc, textX, textY + 30);
		graphics.endFill();

		text.graphic.bitmap.dispose();
		text.graphic.bitmap.disposeImage();
		text.destroy();

		// other stuff
		FlxG.stage.addEventListener(Event.RESIZE, onResize);
		addEventListener(Event.ENTER_FRAME, update);

		FlxG.game.addChild(this); //Don't add it below mouse, or it will disappear once the game changes states

		// fix scale
		lastScale = (FlxG.stage.stageHeight / FlxG.height);
		this.x = 20 * lastScale;
		this.y = -130 * lastScale;
		this.scaleX = lastScale;
		this.scaleY = lastScale;
		intendedY = 20;
	}

	var bitmaps:Array<BitmapData> = [];
	function drawTextAt(text:FlxText, str:String, textX:Float, textY:Float)
	{
		text.text = str;
		text.updateHitbox();

		var clonedBitmap:BitmapData = text.graphic.bitmap.clone();
		bitmaps.push(clonedBitmap);
		graphics.beginBitmapFill(clonedBitmap, new Matrix(1, 0, 0, 1, textX, textY), false, false);
		graphics.drawRect(textX, textY, text.width + textX, text.height + textY);
	}
	
	var lerpTime:Float = 0;
	var countedTime:Float = 0;
	var timePassed:Float = -1;
	public var intendedY:Float = 0;

	function update(e:Event)
	{
		if(timePassed < 0) 
		{
			timePassed = Lib.getTimer();
			return;
		}

		var time = Lib.getTimer();
		var elapsed:Float = (time - timePassed) / 1000;
		timePassed = time;
		//trace('update called! $elapsed');

		if(elapsed >= 0.5) return; //most likely passed through a loading

		countedTime += elapsed;
		if(countedTime < 3)
		{
			lerpTime = Math.min(1, lerpTime + elapsed);
			y = ((FlxEase.elasticOut(lerpTime) * (intendedY + 130)) - 130) * lastScale;
		}
		else
		{
			y -= FlxG.height * 2 * elapsed * lastScale;
			if(y <= -130 * lastScale)
				destroy();
		}
	}

	private function onResize(e:Event)
	{
		var mult = (FlxG.stage.stageHeight / FlxG.height);
		scaleX = mult;
		scaleY = mult;

		x = (mult / lastScale) * x;
		y = (mult / lastScale) * y;
		lastScale = mult;
	}

	public function destroy()
	{
		_popups.remove(this);
		//trace('destroyed achievement, new count: ' + Achievements._popups.length);

		if (FlxG.game.contains(this))
		{
			FlxG.game.removeChild(this);
		}
		FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		removeEventListener(Event.ENTER_FRAME, update);
		deleteClonedBitmaps();
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

    @:allow(archipelago.ArchPopup)
	private static var _popups:Array<ArchPopup> = [];

	public static var showingPopups(get, never):Bool;
	public static function get_showingPopups()
		return _popups.length > 0;

	public static function startPopupSong(daSong:String, image:String, ?endFunc:Void->Void = null) {
		for (popup in _popups)
		{
			if(popup == null) continue;
            popup.intendedY += 150;
		}
		if (!APEntryState.gonnaRunSync) 
		{
			var newPop:ArchPopup = new ArchPopup('You Got A Song: ' + if (daSong != 'null') daSong else 'Nothing lol', 'Go Check Freeplay!', daSong, image, endFunc);
			_popups.push(newPop);
			FlxG.sound.play(Paths.sound('streamervschat/invuln'));
		}
		//trace('Giving achievement ' + achieve);
	}

    public static function startPopupCustom(massage:String, desc:String, image:String, ?endFunc:Void->Void = null) {
		for (popup in _popups)
		{
			if(popup == null) continue;
            popup.intendedY += 150;
		}

		var newPop:ArchPopup = new ArchPopup(massage, desc, null, image, endFunc);
		_popups.push(newPop);
		//trace('Giving achievement ' + achieve);
	}
}