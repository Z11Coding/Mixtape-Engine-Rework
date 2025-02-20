// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define texture flixel_texture2D
#define iResolution openfl_TextureSize
uniform float iTime;
#define iChannel0 bitmap
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

#define PI 3.14159265358979323846
#define PI2 6.28318530718
#define NUM_LAYERS 6.

mat2 rot2D(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float Hash21(vec2 p) {
  p = fract(p*vec2(123.34, 465.21));
  p += dot(p, p+45.32);
  return fract(p.x * p.y);
}

float Star(vec2 uv, float flare) {
    // star
    float d = length(uv);
    float m = 0.05/d;

    float rays = max(0., 1.-abs(uv.x*uv.y*1000.));
    m+=rays*flare;
    uv *= rot2D(PI*.25);
    rays = max(0., 1.-abs(uv.x*uv.y*1000.));
    m += rays*.3*flare;
    
    // prevent glow bleeding into neighbouring cells
    m *= smoothstep(.75, .2, d);
    return m;
}

vec3 StarLayer(vec2 uv, float snd) {
    vec3 col = vec3(0.);
    // fract & floor 2 sides of the same coin
    // grid coord
    vec2 gv = fract(uv)-.5;
    // Tile ID
    vec2 id = floor(uv);
    // iterate through getting neighbours by offset
    for(float y=-1.;y<=1.;y++) {
        for(float x=-1.;x<=1.;x+=1.) {
            vec2 offset = vec2(x, y);
            float n = Hash21(id+offset);// rand between 0 & 1
            float size =  snd;
            vec3 color = sin(vec3(.2, .3, .9)*fract(n*2345.2)*PI2*20.)*.5+.5;
            color *= color *vec3(1., .5, 1.+size);
            float star = Star(gv-offset-vec2(n-.5, fract(n*34.))+.5, smoothstep(.9, 1., size));
            col += star * size * color;
        }
    }
    return col;

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -1 to 1) with aspect ratio fix
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    // actual uv normalised 0-1;
    vec2 UV = fragCoord.xy/iResolution.xy;
    uv*=4.;
    float t = iTime*.05;
    uv*=rot2D(t);
    vec3 snd = texture(iChannel0, UV).rgb;
    vec3 vid = texture(iChannel0, UV).rgb;
    uv = uv *vid.rb;
    //for(int i = 0; i< 1;i++) {
        //uv = abs(uv)/abs(dot(uv, uv))-vec2(vid.x);
    //}
    //  bg color
    vec3 col = vec3(0.);
    for(float i = 0.; i<1.;i+=1./NUM_LAYERS) {
        float depth = fract(i+t);
        float scl = mix(20., snd.x, depth);
        float fade = depth*smoothstep(1.,0.9, depth);
        col+= StarLayer(uv*scl+i*453.2, snd.x*5.)*fade;
    }
    // add red border to grid for debugging
    //if(gv.x>.48||gv.y>.48) col.r=1.;
    
    //col.rb += id * .4;
    //col += Hash21(id);
    // Output to screen
    fragColor = vec4(col,texture(iChannel0, uv).a);
}

void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}