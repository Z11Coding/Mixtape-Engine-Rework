package backend;

import flixel.math.FlxPoint;
import flixel.util.FlxSave;
import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import flixel.system.FlxSound;
import lime.app.Application;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

import haxe.Json;

class CoolUtil
{
	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}
	
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
		return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

	inline public static function clamp(n:Float, l:Float, h:Float)
	{
		if (n > h)
			n = h;
		if (n < l)
			n = l;

		return n;
	}

	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point == null ? FlxPoint.weak() : point;
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}

	public static function triangle(angle:Float){
		var fAngle:Float = angle % (Math.PI * 2.0);
		if(fAngle < 0.0)
		{
			fAngle+= Math.PI * 2.0;
		}
		var result:Float = fAngle * (1 / Math.PI);
		if(result < .5)
		{
			return result * 2.0;
		}
		else if(result < 1.5)
		{
			return 1.0 - ((result - .5) * 2.0);
		}
		else
		{
			return -4.0 + (result * 2.0);
		}
	}

	inline public static function quantizeAlpha(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}

	inline public static function quantize(f:Float, snap:Float)
	{
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

	inline public static function snap(f:Float, snap:Float):Float
		return backend.math.CoolMath.snap(f, snap);
	
	public static function getLastOfArray<T>(a:Array<T>):T {
		return a[a.length - 1];
	}

	public static function wrapInt(e:Int, min:Int, max:Int) {
		if (min == max) return min;
		var result = (e - min) % (max - min);
		if (result < 0) result += (max - min);
		return result + min;
	}
	
	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	inline public static function capitalize(text:String)
	{
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function parseLog(msg:Dynamic):LogData {
		try {
			if (msg is String)
				return cast(Json.parse(msg));
			return cast(msg);
		}
		catch (e) {
			return {
				content: msg,
				hue: null
			}
		}
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function formatAccuracy(value:Float)
	{
		var conversion:Map<String, String> = [
			'0' => '0.00',
			'0.0' => '0.00',
			'0.00' => '0.00',
			'00' => '00.00',
			'00.0' => '00.00',
			'00.00' => '00.00', // gotta do these as well because lazy
			'000' => '000.00'
		]; // these are to ensure you're getting the right values, instead of using complex if statements depending on string length

		var stringVal:String = Std.string(value);
		var converVal:String = '';
		for (i in 0...stringVal.length)
		{
			if (stringVal.charAt(i) == '.')
				converVal += '.';
			else
				converVal += '0';
		}

		var wantedConversion:String = conversion.get(converVal);
		var convertedValue:String = '';

		for (i in 0...wantedConversion.length)
		{
			if (stringVal.charAt(i) == '')
				convertedValue += wantedConversion.charAt(i);
			else
				convertedValue += stringVal.charAt(i);
		}

		if (convertedValue.length == 0)
			return '$value';

		return convertedValue;
	}

	public static function updateTheEngine():Void
	{
		// Get the directory of the executable
		var exePath = Sys.programPath();
		var exeDir = haxe.io.Path.directory(exePath);

		// Construct the source directory path based on the executable location
		var sourceDirectory = haxe.io.Path.join([exeDir, "update", "raw"]);
		var sourceDirectory2 = haxe.io.Path.join([exeDir, "update"]);

		// Escape backslashes for use in the batch script
		sourceDirectory = sourceDirectory.split('\\').join('\\\\');

		var excludeFolder = "mods";

		// Construct the batch script with echo statements
		var theBatch = "@echo off\r\n";
		theBatch += "setlocal enabledelayedexpansion\r\n";
		theBatch += "set \"sourceDirectory=" + sourceDirectory + "\"\r\n";
		theBatch += "set \"sourceDirectory2=" + sourceDirectory2 + "\"\r\n";
		theBatch += "set \"destinationDirectory=" + exeDir + "\"\r\n";
		theBatch += "set \"excludeFolder=mods\"\r\n";
		theBatch += "if not exist \"!sourceDirectory!\" (\r\n";
		theBatch += "  echo Source directory does not exist: !sourceDirectory!\r\n";
		theBatch += "  pause\r\n";
		theBatch += "  exit /b\r\n";
		theBatch += ")\r\n";
		theBatch += "taskkill /F /IM MixEngine.exe\r\n";
		theBatch += "cd /d \"%~dp0\"\r\n";
		theBatch += "xcopy /e /y \"!sourceDirectory!\" \"!destinationDirectory!\"\r\n";
		theBatch += "rd /s /q \"!sourceDirectory!\"\r\n";
		theBatch += "start /d \"!destinationDirectory!\" MixEngine.exe\r\n";
		theBatch += "rd /s /q \"%~dp0\\update\"\r\n";
		theBatch += "del \"%~f0\"\r\n";
		theBatch += "endlocal\r\n";

		// Save the batch file in the executable's directory
		File.saveContent(haxe.io.Path.join([exeDir, "update.bat"]), theBatch);

		// Execute the batch file
		new Process(exeDir + "/update.bat", []);
		Sys.exit(0);
	}

	public static function getSizeLabel(num:UInt):String{
        var size:Float = num;
        var data = 0;
        var dataTexts = ["B", "KB", "MB", "GB", "TB", "PB"];
        while(size > 1024 && data < dataTexts.length - 1) {
          data++;
          size = size / 1024;
        }
        
        size = Math.round(size * 100) / 100;
        return size + " " + dataTexts[data];
    }

	public static function deleteFolder(delete:String) {
		#if sys
		if (!sys.FileSystem.exists(delete)) return;
		var files:Array<String> = sys.FileSystem.readDirectory(delete);
		for(file in files) {
			if (sys.FileSystem.isDirectory(delete + "/" + file)) {
				deleteFolder(delete + "/" + file);
				FileSystem.deleteDirectory(delete + "/" + file);
			} else {
				try {
					FileSystem.deleteFile(delete + "/" + file);
				} catch(e) {
					Application.current.window.alert("Could not delete " + delete + "/" + file + ", click OK to skip.");
				}
			}
		}
		#end
	}

	public static function exists(path:String):Bool{
		#if desktop
		return FileSystem.exists(path);
        #else
        return Assets.exists(path);
		#end
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	// could probably use a macro
	public static function getEaseFromString(?name:String):EaseFunction
	{
		return switch(name)
		{
 			case "backIn": FlxEase.backIn;
 			case "backInOut": FlxEase.backInOut;
 			case "backOut": FlxEase.backOut;
 			case "bounceIn": FlxEase.bounceIn;
 			case "bounceInOut": FlxEase.bounceInOut;
 			case "bounceOut": FlxEase.bounceOut;
 			case "circIn": FlxEase.circIn;
 			case "circInOut": FlxEase.circInOut;
 			case "circOut": FlxEase.circOut;
 			case "cubeIn": FlxEase.cubeIn;
 			case "cubeInOut": FlxEase.cubeInOut;
 			case "cubeOut": FlxEase.cubeOut;
 			case "elasticIn": FlxEase.elasticIn;
 			case "elasticInOut": FlxEase.elasticInOut;
 			case "elasticOut": FlxEase.elasticOut;
 			case "expoIn": FlxEase.expoIn;
 			case "expoInOut": FlxEase.expoInOut;
 			case "expoOut": FlxEase.expoOut;
 			case "quadIn": FlxEase.quadIn;
 			case "quadInOut": FlxEase.quadInOut;
 			case "quadOut": FlxEase.quadOut;
 			case "quartIn": FlxEase.quartIn;
 			case "quartInOut": FlxEase.quartInOut;
 			case "quartOut": FlxEase.quartOut;
 			case "quintIn": FlxEase.quintIn;
 			case "quintInOut": FlxEase.quintInOut;
 			case "quintOut": FlxEase.quintOut;
 			case "sineIn": FlxEase.sineIn;
 			case "sineInOut": FlxEase.sineInOut;
 			case "sineOut": FlxEase.sineOut;
 			case "smoothStepIn": FlxEase.smoothStepIn;
 			case "smoothStepInOut": FlxEase.smoothStepInOut;
 			case "smoothStepOut": FlxEase.smoothStepOut;
 			case "smootherStepIn": FlxEase.smootherStepIn;
 			case "smootherStepInOut": FlxEase.smootherStepInOut;
 			case "smootherStepOut": FlxEase.smootherStepOut;

 			case "instant": ((t:Float) -> return 1);
			default: FlxEase.linear;
		}
	}

	/** Quick Function to Fix Save Files for Flixel 5
		if you are making a mod, you are gonna wanna change "ShadowMario" to something else
		so Base Psych saves won't conflict with yours
		@BeastlyGabi
	**/
	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function easeInOutCirc(x:Float):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
		return (result == Math.NaN) ? 1.0 : result;
	}

	public static function easeInBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		return (1 + c) * x * x * x - c * x * x;
	}

	public static function easeOutBack(x:Float, ?c:Float = 1.70158):Float
	{
		if (x <= 0.0) return 0.0;
		if (x >= 1.0) return 1.0;
		return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
	}

	/**
	 * Perform linear interpolation between the base and the target, based on the current framerate.
	 * @param base The starting value, when `progress <= 0`.
	 * @param target The ending value, when `progress >= 1`.
	 * @param ratio Value used to interpolate between `base` and `target`.
	 *
	 * @return The interpolated value.
	 */
	@:deprecated('Use smoothLerp instead')
	public static function coolLerp(base:Float, target:Float, ratio:Float):Float
	{
		return base + cameraLerp(ratio) * (target - base);
	}

	/**
	 * Perform linear interpolation based on the current framerate.
	 * @param lerp Value used to interpolate between `base` and `target`.
	 *
	 * @return The interpolated value.
	 */
	@:deprecated('Use smoothLerp instead')
	public static function cameraLerp(lerp:Float):Float
	{
		return lerp * (FlxG.elapsed / (1 / 60));
	}
}

typedef LogData = {
	var content:String;
	var hue:Null<Float>;
}