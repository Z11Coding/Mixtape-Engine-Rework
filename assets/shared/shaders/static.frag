// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel


#pragma header

uniform float iTime;
uniform bool useFlixelAlpha;

float rawRandom(in float x) {
    return fract(x*43758.5453);
}

float random(in float x){
    return rawRandom(sin(x));
}

void main() {
	vec2 iResolution = openfl_TextureSize;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;

    vec2 uv = (openfl_TextureCoordv*openfl_TextureSize)/openfl_TextureSize.xy;
    uv.x += rawRandom(cos(iTime));
 
    float theNoise = random(uv.x*19.3+uv.y*6574.);
    float theAlpha = 0.;

    if (useFlixelAlpha) {
        theAlpha = flixel_texture2D(bitmap, uv).a;
    }
    else {
        theAlpha = 1.;
    }

    gl_FragColor = vec4(vec3(theNoise * clamp(random(iTime), 0.715, 0.95)), flixel_texture2D(bitmap, uv).a);
}