package backend;

import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxRect;
import haxe.Json;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets;

class Cache {
    // define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];  //用于列举当前状态的所有资源（包括图形，声音）

  public static var currentTrackedAssets:Map<String, FlxGraphic> = []; //用于列举当前状态的所有图形资源

	public static var currentTrackedBitmaps:Map<String, BitmapData> = []; //用于列举当前状态的所有动画资源

  public static var currentTrackedSounds:Map<String, Sound> = []; //用于列举当前状态的所有声音资源

	public static var currentTrackedFrames:Map<String, FlxFramesCollection> = []; //用于列举当前状态的所有动画帧资源

	public static var currentTrackedAnims:Map<String, FlxAnimationController> = []; //用于列举当前状态的所有动画资源

    public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/shared/music/freakyMenu.$Paths.SOUND_EXT',
		'assets/shared/music/breakfast.$Paths.SOUND_EXT',
		'assets/shared/music/tea-time.$Paths.SOUND_EXT',
	];
}
