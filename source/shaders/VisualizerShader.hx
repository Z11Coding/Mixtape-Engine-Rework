package shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.utils.Assets;
import flixel.FlxG;
import openfl.Lib;

// TODO: maybe make a GreenScreenSprite or whatever

class VisualizerShader extends FlxShader // https://www.shadertoy.com/view/4dX3WN
{

  @:glFragmentSource('
    #pragma header
    uniform float ampl 1.
	#define seuil .0
	#define steps 100.
	#define space .1
	#define def .2
	#define opacity .8

	void main()
	{
		vec2 uv = openfl_TextureCoordv;
		
		float sound = flixel_texture2D(bitmap,vec2(floor(steps*uv.x)/steps,0)).r;
		sound *=ampl;
		sound -=seuil;
		sound = max(def, sound);
		if (uv.x*steps-floor (uv.x*steps)<space)sound = 0.;

		vec4 color = flixel_texture2D(bitmap,uv);
		// uv.y +=textuflixel_texture2Dre(bitmap,vec2(floor(steps*uv.x)/steps,1)).r/20.; // make the spectrum analysis dance with the waveform â™«â™¥
		if (abs((0.,5.*uv.y-1.5))< sound*sound*sound)color =mix(color, vec4(1),opacity);
		gl_FragColor =color;
	}

  ')
  public function new()
  {
    super();
  }
}