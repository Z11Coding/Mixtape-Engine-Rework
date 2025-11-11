package shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * Simple grayscale shader for Mixtape Engine
 * Adapted for VSlice compatibility
 */
class Grayscale extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float amount;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            gl_FragColor = vec4(mix(color.rgb, vec3(gray), amount), color.a);
        }')

    public function new(amount:Float)
    {
        super();
        setAmount(amount);
    }

    public function setAmount(value:Float):Void
    {
        this.amount.value = [value];
    }
}
