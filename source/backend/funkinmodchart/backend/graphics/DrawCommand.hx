package backend.funkinmodchart.backend.graphics;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BlendMode;

@:publicFields
@:structInit
class DrawCommand {
	// stuff
	var parent:FlxSprite;

	var graphic:FlxGraphic;
	var antialiasing:Bool;
	var blend:BlendMode;
	var shader:FlxShader;
	var cameras:Array<FlxCamera>;

	// rendering
	var vertices:NativeVector<Float>;
	var uvs:NativeVector<Float>;
	var indices:NativeVector<Int>;

	var isColored:Bool;
	var hasColorOffsets:Bool;

	// each has a different use
	var color:Null<ColorTransform> = null;
	var colors:Null<NativeVector<ColorTransform>> = null;

	var zIndex:Int = 0;
}
