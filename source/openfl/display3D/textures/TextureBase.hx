package openfl.display3D.textures;

import lime._internal.graphics.ImageCanvasUtil;
import lime.graphics.Image;
import lime.graphics.RenderContext;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLRenderbuffer;
import lime.graphics.opengl.GLTexture;
import lime.utils.ArrayBufferView;
import lime.utils.Log;
import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.display._internal.SamplerState;
import openfl.errors.Error;
import openfl.events.EventDispatcher;

/**
	The TextureBase class is the base class for Context3D texture objects.

	**Note:** You cannot create your own texture classes using TextureBase. To add
	functionality to a texture class, extend either Texture or CubeTexture instead.
**/
@:access(openfl.display._internal.SamplerState)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.BitmapData)
@:access(openfl.display.Stage)
class TextureBase extends EventDispatcher
{
  @:noCompletion private static var __supportsBGRA:Null<Bool> = null;


	@:noCompletion private var __context:Context3D;
	@:noCompletion private var __glDepthRenderbuffer:GLRenderbuffer;
	@:noCompletion private var __glFramebuffer:GLFramebuffer;
	@:noCompletion private var __glStencilRenderbuffer:GLRenderbuffer;
	@:noCompletion private var __memoryWidth:Int = -1;
	@:noCompletion private var __memoryHeight:Int = -1;
	@:noCompletion private var __memoryFormat:Int = -1;
	@:noCompletion private var __memoryInternalFormat:Int = -1;
	@:noCompletion private var __width:Int;
	@:noCompletion private var __height:Int;
	@:noCompletion private var __format:Int;
	@:noCompletion private var __internalFormat:Int;
	@:noCompletion private var __optimizeForRenderToTexture:Bool;
	@:noCompletion private var __premultiplyAlpha:Bool;
	@:noCompletion private var __samplerState:SamplerState;
	@:noCompletion private var __streamingLevels:Int;
	@:noCompletion private var __textureContext:RenderContext;
	@:noCompletion private var __textureID:GLTexture;
	@:noCompletion private var __textureTarget:Int;

	@:noCompletion private function new(context:Context3D, ?format:Context3DTextureFormat)
	{
    if (__supportsBGRA != null) return;

		super();

		__context = context;
		var gl = __context.gl;

		__textureID = gl.createTexture();
		__textureContext = __context.__context;

		// Since `format` has never been taken into account when creating the `TextureBase`, if `format` is null, keep the old behaviour.
		if (format == null)
		{
			if (OpenGLRenderer.__bgraExtension != null)
			{
        __supportsBGRA = true;
				__internalFormat = OpenGLRenderer.__bgraAsInternalFormat ? OpenGLRenderer.__bgraExtension.BGRA_EXT : gl.RGBA;
				__format = OpenGLRenderer.__bgraExtension.BGRA_EXT;
			}
			else
			{
        __supportsBGRA = false;
				__internalFormat = gl.RGBA;
				__format = gl.RGBA;
			}
		}
		else
		{
			switch (format)
			{
				case RGB:
					__internalFormat = gl.RGB;
					__internalFormat = gl.RGB;
				case BGRA:
					if (OpenGLRenderer.__bgraExtension != null)
					{
            __supportsBGRA = true;
						__internalFormat = OpenGLRenderer.__bgraAsInternalFormat ? OpenGLRenderer.__bgraExtension.BGRA_EXT : gl.RGBA;
						__format = OpenGLRenderer.__bgraExtension.BGRA_EXT;
					}
					else
					{
            __supportsBGRA = false;
						__internalFormat = gl.RGBA;
						__format = gl.RGBA;
					}
				case RGBA:
					__internalFormat = gl.RGBA;
					__format = gl.RGBA;
				case R:
					__internalFormat = gl.R8;
					__internalFormat = gl.RED;
			}
		}
	}

	/**
		Frees all GPU resources associated with this texture. After disposal, calling
		`upload()` or rendering with this object fails.
	**/
	public function dispose():Void
	{
		var gl = __context.gl;

		if (__textureID != null)
		{
			// Deleting unbinds the texture from every unit, so drop it from the bind cache too.
			__context.__invalidateGLTexture2D(__textureID);
			gl.deleteTexture(__textureID);
			__textureID = null;
		}

		if (__glFramebuffer != null)
		{
			gl.deleteFramebuffer(__glFramebuffer);
			__glFramebuffer = null;
		}

		if (__glDepthRenderbuffer != null)
		{
			gl.deleteRenderbuffer(__glDepthRenderbuffer);
			__glDepthRenderbuffer = null;
		}

		if (__glStencilRenderbuffer != null)
		{
			gl.deleteRenderbuffer(__glStencilRenderbuffer);
			__glStencilRenderbuffer = null;
		}
	}

	@:noCompletion private function __getGLFramebuffer(enableDepthAndStencil:Bool, antiAlias:Int, surfaceSelector:Int):GLFramebuffer
	{
		var gl = __context.gl;

		if (__glFramebuffer == null)
		{
			__glFramebuffer = gl.createFramebuffer();
			__context.__bindGLFramebuffer(__glFramebuffer);
			gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, __textureID, 0);

			if (__context.__enableErrorChecking)
			{
				var code = gl.checkFramebufferStatus(gl.FRAMEBUFFER);

				if (code != gl.FRAMEBUFFER_COMPLETE)
				{
					Log.warn('Error: Context3D.setRenderToTexture status:${code} width:${__width} height:${__height}');
				}
			}
		}

		if (enableDepthAndStencil && __glDepthRenderbuffer == null)
		{
			__context.__bindGLFramebuffer(__glFramebuffer);

			if (Context3D.__glDepthStencil != 0)
			{
				__glDepthRenderbuffer = gl.createRenderbuffer();
				__glStencilRenderbuffer = __glDepthRenderbuffer;

				gl.bindRenderbuffer(gl.RENDERBUFFER, __glDepthRenderbuffer);
				gl.renderbufferStorage(gl.RENDERBUFFER, Context3D.__glDepthStencil, __width, __height);
				gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, __glDepthRenderbuffer);
			}
			else
			{
				__glDepthRenderbuffer = gl.createRenderbuffer();
				__glStencilRenderbuffer = gl.createRenderbuffer();

				gl.bindRenderbuffer(gl.RENDERBUFFER, __glDepthRenderbuffer);
				gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, __width, __height);
				gl.bindRenderbuffer(gl.RENDERBUFFER, __glStencilRenderbuffer);
				gl.renderbufferStorage(gl.RENDERBUFFER, gl.STENCIL_INDEX8, __width, __height);

				gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, __glDepthRenderbuffer);
				gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.STENCIL_ATTACHMENT, gl.RENDERBUFFER, __glStencilRenderbuffer);
			}

			if (__context.__enableErrorChecking)
			{
				var code = gl.checkFramebufferStatus(gl.FRAMEBUFFER);

				if (code != gl.FRAMEBUFFER_COMPLETE)
				{
					Log.warn('Error: Context3D.setRenderToTexture status:${code} width:${__width} height:${__height}');
				}
			}

			gl.bindRenderbuffer(gl.RENDERBUFFER, null);
		}

		return __glFramebuffer;
	}

	@:noCompletion private function __getImage(bitmapData:BitmapData):Image
	{
		var image = bitmapData.image;

		if (!bitmapData.__isValid || image == null)
		{
			return null;
		}

		#if (js && html5)
		ImageCanvasUtil.sync(image, false);
		#end

		#if (js && html5)
		var gl = __context.gl;

		if (image.type != DATA && !image.premultiplied)
		{
			gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);
		}
		else if (!image.premultiplied && image.transparent)
		{
			gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 0);
			image = image.clone();
			image.premultiplied = true;
		}

		// TODO: Some way to support BGRA on WebGL?

		if (image.format != RGBA32)
		{
			image = image.clone();
			image.format = RGBA32;
			image.buffer.premultiplied = true;
		}
		#else
		if (!image.premultiplied && image.transparent)
		{
			image = image.clone();
			image.premultiplied = true;
		}
		#end

		return image;
	}

	@:noCompletion private function __getTexture():GLTexture
	{
		return __textureID;
	}

	@:noCompletion private function __setSamplerState(state:SamplerState):Bool
	{
		if (!state.equals(__samplerState))
		{
			var gl = __context.gl;

			if (__textureTarget == __context.gl.TEXTURE_CUBE_MAP) __context.__bindGLTextureCubeMap(__textureID);
			else
				__context.__bindGLTexture2D(__textureID);

			var wrapModeS = 0, wrapModeT = 0;

			switch (state.wrap)
			{
				case CLAMP:
					wrapModeS = gl.CLAMP_TO_EDGE;
					wrapModeT = gl.CLAMP_TO_EDGE;
				case CLAMP_U_REPEAT_V:
					wrapModeS = gl.CLAMP_TO_EDGE;
					wrapModeT = gl.REPEAT;
				case REPEAT:
					wrapModeS = gl.REPEAT;
					wrapModeT = gl.REPEAT;
				case REPEAT_U_CLAMP_V:
					wrapModeS = gl.REPEAT;
					wrapModeT = gl.CLAMP_TO_EDGE;
				default:
					throw new Error("wrap bad enum");
			}

			var magFilter = 0, minFilter = 0;

			switch (state.filter)
			{
				case NEAREST:
					magFilter = gl.NEAREST;
				default:
					magFilter = gl.LINEAR;
			}

			switch (state.mipfilter)
			{
				case MIPLINEAR:
					minFilter = state.filter == NEAREST ? gl.NEAREST_MIPMAP_LINEAR : gl.LINEAR_MIPMAP_LINEAR;
				case MIPNEAREST:
					minFilter = state.filter == NEAREST ? gl.NEAREST_MIPMAP_NEAREST : gl.LINEAR_MIPMAP_NEAREST;
				case MIPNONE:
					minFilter = state.filter == NEAREST ? gl.NEAREST : gl.LINEAR;
				default:
					throw new Error("mipfiter bad enum");
			}

			gl.texParameteri(__textureTarget, gl.TEXTURE_MIN_FILTER, minFilter);
			gl.texParameteri(__textureTarget, gl.TEXTURE_MAG_FILTER, magFilter);
			gl.texParameteri(__textureTarget, gl.TEXTURE_WRAP_S, wrapModeS);
			gl.texParameteri(__textureTarget, gl.TEXTURE_WRAP_T, wrapModeT);

			if (__samplerState == null)
			{
				__samplerState = state.clone();
			}

			__samplerState.copyFrom(state);

			return true;
		}

		return false;
	}

	@:noCompletion private function __uploadFromImage(image:Image):Void
	{
		var gl = __context.gl;

		if (__textureTarget != gl.TEXTURE_2D)
		{
			return;
		}

		__context.__bindGLTexture2D(__textureID);

		#if (js && html5)
		if (image.type != DATA && !image.premultiplied)
		{
			gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);
		}
		else if (!image.premultiplied && image.transparent)
		{
			gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);
		}

		if (image.type == DATA)
		{
			__uploadTexture2D(__textureTarget, image.buffer.width, image.buffer.height, __internalFormat, __format, image.data);
		}
		else
		{
			gl.texImage2D(__textureTarget, 0, __internalFormat, __format, gl.UNSIGNED_BYTE, image.src);
		}
		#else
		__uploadTexture2D(__textureTarget, image.buffer.width, image.buffer.height, __internalFormat, __format, image.data);
		#end

		__context.__bindGLTexture2D(null);
	}

	@:noCompletion private function __uploadTexture2D(target:Int, width:Int, height:Int, internalFormat:Int, format:Int, data:ArrayBufferView):Void
	{
		var gl = __context.gl;

		if (__memoryWidth == width
			&& __memoryHeight == height
			&& __memoryFormat == format
			&& __memoryInternalFormat == internalFormat)
		{
			gl.texSubImage2D(target, 0, 0, 0, width, height, format, gl.UNSIGNED_BYTE, data);
		}
		else
		{
			gl.texImage2D(target, 0, internalFormat, width, height, 0, format, gl.UNSIGNED_BYTE, data);

			__memoryWidth = width;
			__memoryHeight = height;
			__memoryFormat = format;
			__memoryInternalFormat = internalFormat;
		}
	}
}
