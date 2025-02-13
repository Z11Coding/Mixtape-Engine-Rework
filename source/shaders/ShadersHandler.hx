package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxAssets.*;
import openfl.display.Bitmap;
import openfl.display.GraphicsShader;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import shaders.Shaders;

class ShadersHandler
{
	public static var chromaticAberration:ShaderFilter = new ShaderFilter(new shaders.ChromaticAberration());
	public static var fuckingTriangle:ShaderFilter = new ShaderFilter(new shaders.Shaders.FuckingTriangle());
	public static var visualizer:ShaderFilter = new ShaderFilter(new shaders.VisualizerShader());
	public static var heatwaveShader:ShaderFilter = new ShaderFilter(new shaders.HeatwaveShader().shader);
	public static var rainShader:RainShader;
    // public static var rtxShader:RTX = new RTX();

	public static function setupRainShader()
	{
		rainShader = new RainShader();
		rainShader.scale = FlxG.height / 200;
		rainShader.intensity = 0;
	}

   	public static function setChrome(chromeOffset:Float):Void
	{
		chromaticAberration.shader.data.rOffset.value = [chromeOffset];
		chromaticAberration.shader.data.gOffset.value = [0.0];
		chromaticAberration.shader.data.bOffset.value = [chromeOffset * -1];
	}

	public static function setTriangleX(triangle:Float):Void
	{
		fuckingTriangle.shader.data.rotX.value = [triangle];
	}

	public static function setTriangleY(triangle:Float):Void
	{
		fuckingTriangle.shader.data.rotY.value = [triangle];
	}
	
	public static function setVisAmpl(vis:Float):Void
	{
		visualizer.shader.data.ampl.value = [vis];
	}

	public static function updateHeat(curDate:Float):Void
	{
		heatwaveShader.shader.data.iTime.value = [curDate];
	}
}