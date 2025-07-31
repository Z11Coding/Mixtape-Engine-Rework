package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxAssets.*;
import openfl.display.Bitmap;
import openfl.display.GraphicsShader;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import shaders.ShaderGroup;

class ShadersHandler
{
	public static var chromaticAberration:ShaderFilter = new ShaderFilter(new shaders.ChromaticAberration());
	public static var greyscale:ShaderFilter = new ShaderFilter(new ShaderGroup.GreyscaleShader());
	public static var perspective:ShaderFilter = new ShaderFilter(new shaders.PerspectiveShader ());
    public static function setChrome(chromeOffset:Float):Void
	{
		chromaticAberration.shader.data.rOffset.value = [chromeOffset];
		chromaticAberration.shader.data.gOffset.value = [0.0];
		chromaticAberration.shader.data.bOffset.value = [chromeOffset * -1];
	}

	public static function setPerspectiveXRot(xrot:Float):Void
	{
		perspective.shader.data.xrot.value = [xrot];
	}
	public static function setPerspectiveYRot(yrot:Float):Void
	{
		perspective.shader.data.yrot.value = [yrot];
	}
	public static function setPerspectiveZRot(zrot:Float):Void
	{
		perspective.shader.data.zrot.value = [zrot];
	}
	public static function setPerspectiveXPos(xpos:Float):Void
	{
		perspective.shader.data.xpos.value = [xpos];
	}
	public static function setPerspectiveYPos(ypos:Float):Void
	{
		perspective.shader.data.yrot.value = [ypos];
	}
	public static function setPerspectiveZPos(zpos:Float):Void
	{
		perspective.shader.data.zpos.value = [zpos];
	}
}