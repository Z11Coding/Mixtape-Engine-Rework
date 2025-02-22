// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform)
	{
		return color;
	}
	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}
	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform float iTimeDelta;
uniform float iFrameRate;
uniform int iFrame;
#define iChannelTime float[4](iTime, 0., 0., 0.)
#define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
uniform vec4 iMouse;
uniform vec4 iDate;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Readbackground and foreground images.
    vec3 bg = texture(iChannel0, uv).rgb;
    vec3 fg = texture(iChannel1, uv).rgb;

    // Foreground ghosting.
    const float ghostliness = 0.2;
    fg = mix(fg, bg, ghostliness);
    
    // Greenscreen mask.
	float ref = fg.r;
	if(ref < fg.b) ref = fg.b;
	float amask = fg.g - ref;
	amask = smoothstep(0.1,0.2,amask);
    
    // Apply mask.
    vec3 col = mix(fg, bg, amask);

    // Sepia tone, from
    // https://www.techrepublic.com/blog/how-do-i/how-do-i-convert-images-to-grayscale-and-sepia-tone-using-c
	vec3 sepia = vec3(
        col.r * .393 + col.g *.769 + col.b * .189,
        col.r * .349 + col.g *.686 + col.b * .168,
		col.r * .272 + col.g *.534 + col.b * .131);
    
    // Film grain, from
    // https://www.reddit.com/r/opengl/comments/1rr4fy/any_good_ways_of_generating_film_grain_noise
    const float noiseStrength = 50.0;
    float x = (uv.x + 4.0) * (uv.y + 4.0) * (iTime * 10.0);
    vec3 grain = vec3(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01) - 0.005) * noiseStrength;

    // This one is optional, it makes a small "tear" every now and then
    //if(mod(time, 100) > 98 && mod(texcoord.y, 10) > 7) grain = vec3(-3.0, -3.0, -3.0);
    
    // Output to screen
    fragColor = vec4(sepia+grain,texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}