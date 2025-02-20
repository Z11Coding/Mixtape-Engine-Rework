package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

import flixel.tweens.FlxTween;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import openfl.utils.Assets;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 80;

	var _defaultScale:Float = 2.0;

	/**The sound used when increasing the volume.**/
	public var volumeUpSound:String = Paths.file2(ClientPrefs.data.volUp, "sounds/soundtray", 'ogg');

	/**The sound used when decreasing the volume.**/
	public var volumeDownSound:String = Paths.file2(ClientPrefs.data.volDown, "sounds/soundtray", 'ogg');

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep

    var graphicScale:Float = 0.30;
    var lerpYPos:Float = 0;
    var alphaTarget:Float = 0;

    var volumeMaxSound:String;
	public function new()
	{
		super();
        var bg:Bitmap = new Bitmap(Assets.getBitmapData(Paths.file2("volumebox", "images/soundtray", "png")));
        bg.scaleX = graphicScale;
        bg.scaleY = graphicScale;
        addChild(bg);

		y = -height;
        visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;

        // makes an alpha'd version of all the bars (bar_10.png)
        var backingBar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.file2("bars_10", "images/soundtray", "png")));
        backingBar.x = 9;
        backingBar.y = 5;
        backingBar.scaleX = graphicScale;
        backingBar.scaleY = graphicScale;
        addChild(backingBar);
        backingBar.alpha = 0.4;

        // clear the bars array entirely, it was initialized
        // in the super class
        _bars = [];

        // 1...11 due to how block named the assets,
        // we are trying to get assets bars_1-10
        for (i in 1...11)
        {
            var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.file2("bars_" + i, "images/soundtray", "png")));
            bar.x = 9;
            bar.y = 5;
            bar.scaleX = graphicScale;
            bar.scaleY = graphicScale;
            addChild(bar);
            _bars.push(bar);
        }

        y = -height;
        screenCenter();

        volumeUpSound = Paths.file2(ClientPrefs.data.volUp, "sounds/soundtray", 'ogg');
        volumeDownSound = Paths.file2(ClientPrefs.data.volDown, "sounds/soundtray", 'ogg');
        volumeMaxSound = Paths.file2(ClientPrefs.data.volMax, "sounds/soundtray", 'ogg');

        trace("Custom tray added!");
	}

	/**
	 * This function updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
        volumeUpSound = Paths.file2(ClientPrefs.data.volUp, "sounds/soundtray", 'ogg');
        volumeDownSound = Paths.file2(ClientPrefs.data.volDown, "sounds/soundtray", 'ogg');
        volumeMaxSound = Paths.file2(ClientPrefs.data.volMax, "sounds/soundtray", 'ogg');
        
		y = CoolUtil.coolLerp(y, lerpYPos, 0.1);
        alpha = CoolUtil.coolLerp(alpha, alphaTarget, 0.25);
        silent = ClientPrefs.data.silentVol;

        // Animate sound tray thing
        if (_timer > 0)
        {
            _timer -= (MS / 1000);
            alphaTarget = 1;
        }
        else if (y >= -height)
        {
            lerpYPos = -height - 10;
            alphaTarget = 0;
        }

        if (y <= -height)
        {
            visible = false;
            active = false;

            #if FLX_SAVE
            // Save sound preferences
            if (FlxG.save.isBound)
            {
                FlxG.save.data.mute = FlxG.sound.muted;
                FlxG.save.data.volume = FlxG.sound.volume;
                FlxG.save.flush();
            }
            #end
        }
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false):Void
	{
		_timer = 1;
        lerpYPos = 10;
        visible = true;
        active = true;
        var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

        if (FlxG.sound.muted)
        {
            globalVolume = 0;
        }

        if (!silent)
        {
            var sound = up ? volumeUpSound : volumeDownSound;

            if (globalVolume == 10) sound = volumeMaxSound;

            if (sound != null) FlxG.sound.load(sound).play();
        }

        for (i in 0..._bars.length)
        {
            if (i < globalVolume)
            {
                _bars[i].visible = true;
            }
            else
            {
                _bars[i].visible = false;
            }
        }
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end