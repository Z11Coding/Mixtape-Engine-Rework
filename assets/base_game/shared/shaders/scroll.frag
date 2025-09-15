//SHADERTOY PORT FIX
#pragma header
vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define mainImage main
#define time iTime
//SHADERTOY PORT FIX

// https://www.shadertoy.com/view/WtGGRt

void mainImage()
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = fragCoord/iResolution.xy;

    const float timeMulti = 0.2;
    
    const float xSpeed = 0.5;
    const float ySpeed = -0.5;

    
    float time = iTime * timeMulti;
    
    // no floor makes it squiqqly
    float xCoord = floor(fragCoord.x + time * xSpeed * iResolution.x);
    float yCoord = floor(fragCoord.y + time * ySpeed * iResolution.y);
    
    vec2 coord = vec2(xCoord, yCoord);
    coord = mod(coord, iResolution.xy);
 
    
    
	vec2 uv = coord/iResolution.xy;
    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
    float col = texture(iChannel0, uv).x;


    vec3 color = vec3(col);
    
    
    
    // Output to screen
    fragColor = vec4(color,1.0) * texture(iChannel0, uv) + texture(iChannel0, uv);
}