package shaders;

import shaders.MosaicShader;

class MosaicEffect
{
	/**
	 * The effect's "start-value" on the x/y-axes (the effect is not visible with this value).
	 */
	public static inline var DEFAULT_STRENGTH:Float = 1;

	/**
	 * The instance of the actual shader class
	 */
	public var shader(default, null):MosaicShader;

	/**
	 * The effect's strength on the x-axis.
	 */
	public var strengthX(default, null):Float = DEFAULT_STRENGTH;

	/**
	 * The effect's strength on the y-axis.
	 */
	public var strengthY(default, null):Float = DEFAULT_STRENGTH;

	public function new():Void
	{
		shader = new MosaicShader();
		shader.data.uBlocksize.value = [strengthX, strengthY];
	}

	public function setStrength(strengthX:Float, strengthY:Float):Void
	{
		this.strengthX = strengthX;
		this.strengthY = strengthY;
		shader.uBlocksize.value[0] = strengthX;
		shader.uBlocksize.value[1] = strengthY;
	}
}