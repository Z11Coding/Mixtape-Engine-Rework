package debug;

import haxe.Timer;
import openfl.events.Event;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import debug.FPSSprite;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end
import flixel.FlxG;
import flixel.FlxGame;
import flixel.util.FlxColor;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end
import openfl.system.System;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
/*
#if windows
@:headerCode("
#include <windows.h>
#include <psapi.h>
")
#end*/

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Float;

	public var curMemory:Float;
	public var maxMemory:Float;
	public var realAlpha:Float = 1;
	public var lagging:Bool = false;
	public var forceUpdateText(default, set):Bool = false;

	public static var initMemory:Dynamic;

	public var spriteParent:FPSSprite;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		initMemory = this.sizeIn(yutautil.CollectionUtils.Size.Bytes);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(getFont(Paths.font("vcr.ttf")), 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	public function getFont(Font:String):String
	{
		embedFonts = true;

		var newFontName:String = Font;

		if (Font != null)
		{
			if (Assets.exists(Font, AssetType.FONT))
			{
				newFontName = Assets.getFont(Font).fontName;
			}
		}
		return newFontName;
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var minAlpha:Float = 0.5;
		var aggressor:Float = 1;

		if ((FlxG.mouse.screenX >= this.x && FlxG.mouse.screenX <= this.x + this.width)
			&& (FlxG.mouse.screenY >= this.y && FlxG.mouse.screenY <= this.y + this.height) && FlxG.mouse.visible)
		{
			minAlpha = 0.1;
			aggressor = 2.5;
		}

		if (!lagging)
			realAlpha = CoolUtil.boundTo(realAlpha - (deltaTime / 1000) * aggressor, minAlpha, 1);
		else
			realAlpha = CoolUtil.boundTo(realAlpha + (deltaTime / 1000), 0.3, 1);

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		var optionFramerate = ClientPrefs.data.unlockFramerate ? 1000 : ClientPrefs.data.framerate;
		if (currentFPS > optionFramerate) currentFPS = optionFramerate;

		_updateMemTimer += FlxG.elapsed / 1000;

		// fucking hell this is weird
		if ((currentCount != cacheCount || _updateMemTimer >= 100.0) && visible)
		{
			updateText();
		}

		cacheCount = currentCount;

		alpha = realAlpha;
	}

	private function set_forceUpdateText(value:Bool):Bool
	{
		updateText();
		return value;
	}

	private var _updateMemTimer:Float = 0.0;
	private var _ms:Float = 0.0;



	private function updateText():Void
	{
		text = "FPS: " + Math.round(currentFPS);

		#if debug
		_ms = FlxMath.lerp(_ms, 1 / Math.round(currentFPS) * 1000, CoolUtil.boundTo(FlxG.elapsed * 3.75 * ((Math.abs(_ms - 1 / Math.round(currentFPS) * 1000) < 0.45) ? 2.5 : 1.0), 0, 1));
		text += ' (${FlxMath.roundDecimal(_ms, 2)} ms)';
		#end

		lagging = false;

		textColor = FlxColor.fromRGBFloat(1, 1, 1, realAlpha);
		if (currentFPS <= ClientPrefs.data.framerate / 2)
		{
			textColor = FlxColor.fromRGBFloat(1, 0, 0, realAlpha);
			lagging = true;
		}

		text += '\n';

		if (ClientPrefs.data.performanceCounter.contains('mem'))
		{
			curMemory = _updateMemTimer >= 100.0 ? curMemory : obtainMemory();
			if (curMemory >= maxMemory)
				maxMemory = curMemory;
			text += 'MEM: ${CoolUtil.formatMemory(Std.int(curMemory))}';
			if (ClientPrefs.data.performanceCounter.contains('peak'))
				text += ' / ${CoolUtil.formatMemory(Std.int(maxMemory))}';
			text += '\n';

			_updateMemTimer = 0.0;
		}
		#if debug
		text += '\nDEBUG INFO:\n';
		text += 'USAGE:\n';
		text += '\nRUNTIME: ${FlxStringUtil.formatTime(currentTime / 1000)}';
		text += "\n";
		text += 'STATE: ${Type.getClassName(Type.getClass(FlxG.state))}';
		if (FlxG.state.subState != null)
			text += ' (SUBSTATE: ${Type.getClassName(Type.getClass(FlxG.state.subState))})';
		text += "\n";
		#end

				if (ClientPrefs.data.showInitialMemoryUsage && initMemory != null && Sys.args().indexOf('-livereload') != -1)
			text += '\nInitial Memory: ${flixel.util.FlxStringUtil.formatBytes(initMemory)}';
	}

	function obtainMemory():Dynamic
	{
		return Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 1));
	}
	// #end

	public var textAfter:String = '';
}