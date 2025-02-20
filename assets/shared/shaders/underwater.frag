#pragma header

vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor

void main()
{
	vec2 uv = fragCoord.xy / iResolution.xy;

	uv.y += (cos((uv.y + (iTime * 0.04)) * 45.0) * 0.0019) + (cos((uv.y + (iTime * 0.1)) * 10.0) * 0.002);
	uv.x += (sin((uv.y + (iTime * 0.07)) * 15.0) * 0.0029) + (sin((uv.y + (iTime * 0.1)) * 15.0) * 0.002);

	fragColor = texture(iChannel0, uv);
}