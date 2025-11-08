package shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * Simple Gaussian blur shader for Mixtape Engine
 * Adapted for VSlice compatibility
 */
class GaussianBlurShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float blurSize;
        uniform vec2 textureSize;

        void main()
        {
            vec2 texelSize = 1.0 / textureSize;
            vec4 color = vec4(0.0);

            // Simple 5x5 blur kernel
            for(int x = -2; x <= 2; x++)
            {
                for(int y = -2; y <= 2; y++)
                {
                    vec2 offset = vec2(float(x), float(y)) * texelSize * blurSize;
                    color += flixel_texture2D(bitmap, openfl_TextureCoordv + offset);
                }
            }

            gl_FragColor = color / 25.0; // Normalize by kernel size
        }')

    public function new(size:Float = 1.0)
    {
        super();
        this.blurSize.value = [size];
        this.textureSize.value = [1.0, 1.0]; // Will be set by the sprite
    }
}
