package debug;

import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxStringUtil;
import lime.system.System;
import debug.Memory;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Float;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memory(get, never):Float;
	inline function get_memory():Float
		return Memory.gay();

	var mempeak:Float = 0;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x00000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];
	}

	var timeColor:Float = 0.0;

	var fpsMultiplier:Float = 1.0;
	var deltaTimeout:Float = 0.0;
	public var timeoutDelay:Float = 50;
	var now:Float = 0;
	// Event Handlers
	override function __enterFrame(deltaTime:Float):Void
	{
		if (!ClientPrefs.data.showFPS) return;
		now = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000 / fpsMultiplier) times.shift();
		if (deltaTimeout <= timeoutDelay)
		{
			deltaTimeout += deltaTime;
			return;
		}

		if (Std.isOfType(FlxG.state, states.PlayState) && !states.PlayState.instance.trollingMode)
		{
			try { fpsMultiplier = states.PlayState.instance.playbackRate; }
			catch (e:Dynamic) { fpsMultiplier = 1.0; }
		}
		else fpsMultiplier = 1.0;

		if (memory > mempeak) mempeak = memory;

		currentFPS = Math.min(FlxG.drawFramerate, times.length) / fpsMultiplier;
		updateText();

		if (ClientPrefs.data.rainbowFPS)
		{
			timeColor = (timeColor % 360.0) + (1.0 / (ClientPrefs.data.framerate / 120));
			textColor = FlxColor.fromHSB(timeColor, 1, 1);
		}
		else if (!ClientPrefs.data.ffmpegMode)
		{
			textColor = 0xFFFFFFFF;
			if (currentFPS <= ClientPrefs.data.framerate / 2 && currentFPS >= ClientPrefs.data.framerate / 3)
				textColor = 0xFFFFFF00;

			if (currentFPS <= ClientPrefs.data.framerate / 3 && currentFPS >= ClientPrefs.data.framerate / 4)
				textColor = 0xFFFF8000;

			if (currentFPS <= ClientPrefs.data.framerate / 4)
				textColor = 0xFFFF0000;
		}
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void   // so people can override it in hscript
	{
		text = "FPS: " + (ClientPrefs.data.ffmpegMode ? ClientPrefs.data.targetFPS : Math.round(currentFPS));
		if (ClientPrefs.data.ffmpegMode)
			text += " (Rendering Mode)";

		if (ClientPrefs.data.showRamUsage) text += "\nRAM: " + FlxStringUtil.formatBytes(memory) + (ClientPrefs.data.showMaxRamUsage ? " / " + FlxStringUtil.formatBytes(mempeak) : "");
		if (ClientPrefs.data.debugInfo)
		{
			text += '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
			if (FlxG.state.subState != null)
				text += '\nSubstate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';
			text += "\nSystem: " + '${System.platformLabel} ${System.platformVersion}';
		}
	}
}
