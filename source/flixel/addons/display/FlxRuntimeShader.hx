package flixel.addons.display;

#if (nme || flash)
#if (FLX_NO_COVERAGE_TEST && !(doc_gen))
#error "FlxRuntimeShader isn't available with nme or flash."
#end
#else
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxStringUtil;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;

using StringTools;
#if lime
import lime.utils.Float32Array;
#end

/**
 * An wrapper for Flixel/OpenFL's shaders, which takes fragment and vertex source
 * in the constructor instead of using macros so it can be provided at runtime.
 *
 * @author MasterEric
 * @author Mihai Alexandru (M.A. Jigsaw)
 *
 * @see https://github.com/openfl/openfl/blob/develop/src/openfl/utils/_internal/ShaderMacro.hx
 * @see https://dixonary.co.uk/blog/shadertoy
 */
class FlxRuntimeShader extends FlxGraphicsShader
{
	/**
	 * Creates a `FlxRuntimeShader` with specified shader sources.
	 * If none is provided, it will use the default shader sources.
	 *
	 * @param fragmentSource The fragment shader source.
	 * @param vertexSource The vertex shader source.
	 * @param glslVersion The glsl version to use.
	 */
	public function new(?fragmentSource:String, ?vertexSource:String, ?glslVersion:String):Void
	{
		if (glslVersion != null)
			glVersion = glslVersion;

		glFragmentSource = fragmentSource != null && fragmentSource.length > 0 ? fragmentSource : glFragmentSourceRaw;

		glVertexSource = vertexSource != null && vertexSource.length > 0 ? vertexSource : glVertexSourceRaw;

		super();
	}

	/**
	 * Modify a float parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader float parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve a float parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloat(name:String):Null<Float>
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader float parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader float[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		final shaderParameter:ShaderParameter<Float> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader float[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader int parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getInt(name:String):Null<Int>
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader int parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader int[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		final shaderParameter:ShaderParameter<Int> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader int[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader bool parameter "$name" not found.');
			return;
		}

		shaderParameter.value = [value];
	}

	/**
	 * Retrieve a bool parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBool(name:String):Null<Bool>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader bool parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value[0];
	}

	/**
	 * Modify a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader bool[] parameter "$name" not found.');
			return;
		}

		shaderParameter.value = value;
	}

	/**
	 * Retrieve a bool array parameter of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		final shaderParameter:ShaderParameter<Bool> = Reflect.field(data, name);

		if (shaderParameter == null)
		{
			trace('[WARN] Shader bool[] parameter "$name" not found.');
			return null;
		}

		return shaderParameter.value;
	}

	/**
	 * Modify a bitmap data input of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBitmapData(name:String, value:BitmapData):Void
	{
		final shaderInput:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (shaderInput == null)
		{
			trace('[WARN] Shader sampler2D input "$name" not found.');
			return;
		}

		shaderInput.input = value;
	}

	/**
	 * Retrieve a bitmap data input of the shader.
	 *
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBitmapData(name:String):Null<BitmapData>
	{
		final shaderInput:ShaderInput<BitmapData> = Reflect.field(data, name);

		if (shaderInput == null)
		{
			trace('[WARN] Shader sampler2D input "$name" not found.');
			return null;
		}

		return shaderInput.input;
	}

	/**
	 * Convert the shader to a readable string name. Useful for debugging.
	 */
	public function toString():String
	{
		return 'FlxRuntimeShader';
	}

	@:noCompletion
	private override function set_glFragmentSource(value:String):String
	{
		if (value != null)
			value = value.replace("#pragma header", glFragmentHeaderRaw).replace("#pragma body", glFragmentBodyRaw);

		if (value != __glFragmentSource)
			__glSourceDirty = true;

		return __glFragmentSource = value;
	}

	@:noCompletion
	private override function set_glVertexSource(value:String):String
	{
		if (value != null)
			value = value.replace("#pragma header", glVertexHeaderRaw).replace("#pragma body", glVertexBodyRaw);

		if (value != __glVertexSource)
			__glSourceDirty = true;

		return __glVertexSource = value;
	}
}
#end
