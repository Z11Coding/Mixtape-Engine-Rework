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
    public static function setChrome(chromeOffset:Float):Void
	{
		chromaticAberration.shader.data.rOffset.value = [chromeOffset];
		chromaticAberration.shader.data.gOffset.value = [0.0];
		chromaticAberration.shader.data.bOffset.value = [chromeOffset * -1];
	}
}