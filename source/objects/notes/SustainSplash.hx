package objects.notes;

import objects.funkin.graphics.ZSprite;
import shaders.RGBPalette;

// This code was from Psych Online, so credit to NotMagniill and Snirozu for the code

class SustainSplash extends ZSprite
{
	public var rgbShader:NoteSplash.PixelSplashShaderRef;

	public static var startCrochet:Float;
	public static var frameRate:Int;

	public var strumNote:StrumNote;
	public var sustainNote:SustainNote;

	var timer:FlxTimer;

	public static var defaultNoteHoldSplash(default, never):String = 'noteSplashes/holdSplashes/holdSplash';

	// true if using spiral hold, false if not. Done this way so when the hold is finished, it keeps its angle.
	public var isSpiralHold:Bool = false;

	// Custom position logic added by WITF that positions holdCovers at the ends of holds (where they get clipped) instead of at the strumNote.
	public var holdPositioned(default, set):Bool;

	function set_holdPositioned(value:Bool):Bool
	{
		autoCalculatePerspective = !value;
		holdPositioned = value;
		return holdPositioned;
	}

	public function new():Void
	{
		super();
		rgbShader = new NoteSplash.PixelSplashShaderRef();
		shader = rgbShader.shader;
		var skin:String = defaultNoteHoldSplash + getSplashSkinPostfix();
		frames = Paths.getSparrowAtlas(skin);
		if (frames == null)
		{
			skin = defaultNoteHoldSplash;
			frames = Paths.getSparrowAtlas(skin);
		}
		animation.addByPrefix('hold', 'hold', 24, true);
		animation.addByPrefix('end', 'end', 24, false);

		isHoldCover = true;
    coverBehindStrums = false;
    applyAngularVelocityOffset = true;
	}

	public var autoOrigin:Bool = false;
	override function update(elapsed)
	{
		if (autoOrigin) centerOrigin();
		if (!holdPositioned)
		{
			var o = [1.08, 0.75];
			perspectiveWidth = width * o[0];
			perspectiveHeight = height * o[1];
		}
		super.update(elapsed);

		if (strumNote != null)
		{
			setPosition(strumNote.x, strumNote.y);
			visible = strumNote.visible;
			alpha = 1 - (1 - strumNote.alpha);

			if (animation.curAnim.name == "hold"
				&& strumNote.animation.curAnim.name == "static"
				|| animation.curAnim.name == "end"
				&& animation.curAnim.finished)
			{
				x = -50000;
				kill();
			}
		}
	}

	public function playStart():Void
  {
    setPosition(this.x, this.y);
    animation.play('hold');
  }

  public function playContinue():Void
		animation.play('hold');

  public function playEnd():Void
		animation.play('end');

	public function setupSusSplash(strum:StrumNote, daNote:Dynamic, ?playbackRate:Float = 1):Void
	{
		sustainNote = cast (daNote, SustainNote);

		final susLength:Float = (!daNote.isSustainNote ? daNote.sustainLength : daNote.parentSL);
		final lengthToGet:Int = Math.floor(susLength / Conductor.stepCrochet);
		final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parentST;
		final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

		animation.play('hold', true, false, 0);
		animation.curAnim.frameRate = frameRate;
		animation.curAnim.looped = true;

		shader = (ClientPrefs.data.enableColorShader ? rgbShader.shader : null);

		clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

		if (daNote != null && daNote.rgbShader != null)
		{
			var tempShader:RGBPalette = null;
			if ((daNote == null || daNote.noteSplashData.useRGBShader) && (PlayfieldManager.SONG == null || !PlayfieldManager.SONG.disableNoteRGB))
			{
				// If Note RGB is enabled:
				if (daNote != null && !daNote.noteSplashData.useGlobalShader)
				{
					if (daNote.noteSplashData.r != -1)
						daNote.rgbShader.r = daNote.noteSplashData.r;
					if (daNote.noteSplashData.g != -1)
						daNote.rgbShader.g = daNote.noteSplashData.g;
					if (daNote.noteSplashData.b != -1)
						daNote.rgbShader.b = daNote.noteSplashData.b;
					tempShader = daNote.rgbShader.parent;
				}
				else
					tempShader = BaseNote.globalRgbShaders[daNote.noteData];
			}
			rgbShader.copyValues(tempShader);
		}

		strumNote = strum;

		if (timer != null)
			timer.cancel();

		offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);

		setPosition(strumNote.x, strumNote.y);

		timer = new FlxTimer().start(timeThingy, (idk:FlxTimer) ->
		{
			if (daNote.isSustainEnd && daNote.mustPress && !daNote.noteSplashData.disabled && ClientPrefs.data.noteSplashes)
			{
				alpha = 1;
				animation.play('end', true, false, 0);
				animation.curAnim.looped = false;
				animation.curAnim.frameRate = 24;
				clipRect = null;
				animation.finishCallback = (idkEither:Dynamic) ->
				{
					kill();
				}
				return;
			}
			kill();
		});

		final holdOrigin = strumNote.origin;
    if (holdOrigin == null)
    {
      autoOrigin = true;
    }
    else
    {
      autoOrigin = false;
      this.origin.set(holdOrigin.x, holdOrigin.y); // Magic numbers which make it rotate from the center properly!
    }
	}

	public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if (ClientPrefs.data.splashSkin != 'Default')
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}
}
