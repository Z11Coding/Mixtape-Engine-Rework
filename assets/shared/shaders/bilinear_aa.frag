#pragma header

vec2 uv = openfl_TextureCoordv.xy;
vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
vec2 iResolution = openfl_TextureSize;
uniform float iTime;
#define iChannel0 bitmap
#define texture flixel_texture2D
#define fragColor gl_FragColor
#define time iTime

void main()
{
    // Define the screen resolution
    vec2 resolution = iResolution.xy;
    
    // Sample the four neighboring pixels
    vec2 uv = fragCoord.xy / resolution.xy;
    vec4 color1 = texture(iChannel0, uv);
    vec4 color2 = texture(iChannel0, uv + vec2(0.25 / resolution.x, 0.0));
    vec4 color3 = texture(iChannel0, uv + vec2(0.0, 0.25 / resolution.y));
    vec4 color4 = texture(iChannel0, uv + vec2(0.25 / resolution.x, 0.25 / resolution.y));

    // Calculate the weights for bilinear interpolation
    vec2 f = fract(uv * resolution);
    float w1 = (1.0 - f.x) * (1.0 - f.y);
    float w2 = f.x * (1.0 - f.y);
    float w3 = (1.0 - f.x) * f.y;
    float w4 = f.x * f.y;

    // Perform bilinear interpolation
    vec4 finalColor = w1 * color1 + w2 * color2 + w3 * color3 + w4 * color4;

    // Output the final color
    fragColor = finalColor;
}