#pragma header

//edited to work like Psych HSV. (For easier hue shifting)
//V0.7a - Now has stealth glow!
//V0.7.6a - Now has sudden and hidden stealth support for holds!


uniform float _hue;
uniform float _sat;
uniform float _val;

uniform float _hue2;
uniform float _sat2;
uniform float _val2;

uniform vec3 _rgbR;
uniform vec3 _rgbG;
uniform vec3 _rgbB;
uniform float _rgbMult;

uniform float _stealthGlow;
uniform float _stealthR;
uniform float _stealthG;
uniform float _stealthB;


uniform bool _isHold;
uniform float _holdHeight;

//Values are % (0-1)
uniform float _stealthSustainSuddenStart;
uniform float _stealthSustainSuddenEnd;

uniform float _stealthSustainHiddenStart;
uniform float _stealthSustainHiddenEnd;

//the rest

uniform float _stealthSustainSuddenAmount;
uniform float _stealthSustainHiddenAmount;

uniform float _stealthSustainSuddenNoGlow;
uniform float _stealthSustainHiddenNoGlow;

//fuck you vanish
uniform float _stealthSustainVanish_SuddenStart;
uniform float _stealthSustainVanish_SuddenEnd;
uniform float _stealthSustainVanish_HiddenStart;
uniform float _stealthSustainVanish_HiddenEnd;
uniform float _stealthSustainVanishAmount;
uniform float _stealthSustainVanishNoGlow;







vec3 normalizeColor(vec3 color)
{
    return vec3(
        color[0] / 255.0,
        color[1] / 255.0,
        color[2] / 255.0
    );
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
	vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

	if (hasTransform && color.a != 0.0 && _rgbMult != 0.0) {
		vec3 rgbColor = min(color.r * _rgbR + color.g * _rgbG + color.b * _rgbB, vec3(1.0));
		color.rgb = mix(color.rgb, rgbColor, clamp(_rgbMult, 0.0, 1.0));
	}

	//color[3] = 1.0; //SET ALPHA TO 1 FOR NOW

	vec4 swagColor = vec4(rgb2hsv(vec3(color[0], color[1], color[2])), color[3]);
	//swagColor.x *= _hue;
	swagColor.x += _hue + _hue2;
	swagColor.y *= _sat * _sat2;
	swagColor.z *= _val * _val2;
	// approximate "lightness" changing!!
	//swagColor.z *= (_hue * 0.5) + 0.5; //AND REMOVED THIS SILLY NONSENSE
	color = vec4(hsv2rgb(vec3(swagColor[0], swagColor[1], swagColor[2])), swagColor[3]);


	//vec2 uv = openfl_TextureCoordv;
	//uv *= 5.0;





	vec4 glow = vec4(_stealthR,_stealthG,_stealthB, 1.0);
	float _stealthGlow_clamped = clamp(_stealthGlow, 0.0, 1.0);
	glow *=  color[3]; //Apply Alpha from texture
	glow = clamp(glow, 0.0, 1.0);


	color = mix(color, glow, _stealthGlow_clamped);

	if(_isHold){



		float uvY_real = openfl_TextureCoordv.y / _holdHeight;
		float c = step(0.5,  fract(openfl_TextureCoordv.x * 4.0));
		if(c >= 0.5){ //HOLD UV OFFSET
			uvY_real = uvY_real + 1.0;
		}


		float holdMixSudden = smoothstep(_stealthSustainSuddenStart, _stealthSustainSuddenEnd, uvY_real);
		holdMixSudden = clamp(holdMixSudden, 0.0, _stealthSustainSuddenAmount);
		//0.0 -> 0.5 stealth glow
		//0.5 -> 1.0 is alpha
		float holdGlowMix_Hidden =  clamp(holdMixSudden * 2.0, 0.0, 1.0) * (1.0 - _stealthSustainSuddenNoGlow);
		float holdAlphaMix_Hidden = clamp((holdMixSudden * 2.0) - 1.0, 0.0, 1.0) ;



		float holdMixHidden = smoothstep(_stealthSustainHiddenStart, _stealthSustainHiddenEnd, uvY_real);
		holdMixHidden = clamp(holdMixHidden, 0.0, _stealthSustainHiddenAmount);
		//0.0 -> 0.5 stealth glow
		//0.5 -> 1.0 is alpha
		float holdGlowMix_Sudden =  clamp(holdMixHidden * 2.0, 0.0, 1.0) * (1.0 - _stealthSustainHiddenNoGlow);
		float holdAlphaMix_Sudden = clamp((holdMixHidden * 2.0) - 1.0, 0.0, 1.0);



		//FUCK YOU VANISH MOD
		float holdMix_Vanish_Hidden = smoothstep(_stealthSustainVanish_HiddenStart, _stealthSustainVanish_HiddenEnd, uvY_real);
		holdMix_Vanish_Hidden = clamp(holdMix_Vanish_Hidden, 0.0, _stealthSustainVanishAmount);

		float holdMix_Vanish_Sudden = smoothstep(_stealthSustainVanish_SuddenStart, _stealthSustainVanish_SuddenEnd, uvY_real);
		holdMix_Vanish_Sudden = clamp(holdMix_Vanish_Sudden, 0.0, _stealthSustainVanishAmount);

		float holdMix_Vanish = holdMix_Vanish_Hidden - (1.0-holdMix_Vanish_Sudden);

		//0.0 -> 0.5 stealth glow
		//0.5 -> 1.0 is alpha
		float holdGlowMix_vanish =  clamp(holdMix_Vanish * 2.0, 0.0, 1.0) * (1.0 - _stealthSustainVanishNoGlow);
		float holdAlphaMix_vanish = clamp((holdMix_Vanish * 2.0) - 1.0, 0.0, 1.0);




		float holdGlowMix = 0.0;
		float holdAlphaMix = 0.0;

		holdGlowMix = holdGlowMix_vanish + holdGlowMix_Sudden + holdGlowMix_Hidden;
		holdAlphaMix = holdAlphaMix_vanish + holdAlphaMix_Sudden + holdAlphaMix_Hidden;
		holdGlowMix = clamp(holdGlowMix,0.0,1.0);
		holdAlphaMix = clamp(holdAlphaMix,0.0,1.0);


		color = mix(color, glow, holdGlowMix);
		color = mix(color, vec4(0.0), holdAlphaMix);


	}


	gl_FragColor = color;

}
