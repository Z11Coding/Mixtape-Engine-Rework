package objects.notes;

import backend.animation.PsychAnimationController;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.StrumExtraData;
import objects.funkin.graphics.ZSpriteProjected;
import shaders.HSVNotesShader;
import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette;

class StrumNote extends ZSpriteProjected
{
	public var noteModData:NoteData;
	public var strumExtraModData:StrumExtraData;
	var hsvShader:HSVNotesShader;

	public var strumDistance(default, set):Float;

  function set_strumDistance(value:Float):Float
  {
    this.strumDistance = value;
    if (noteModData != null) noteModData.strumPosition = this.strumDistance;
    return this.strumDistance;
  }


	 /**
   * Set this flag to `true` to disable performance optimizations that cause
   * the Strumline note sprite to ignore `velocity` and `acceleration`.
   */
  public var forceActive:Bool = false;

  public static var hardAlpha:Float = 1; // For hard mode
	public var formerPosition:FlxPoint = FlxPoint.get();
	public var positionData:Int = 0;

  public final animationArray:Array<String> = ['static', 'pressed', 'confirm'];
	public var static_anim(default, set):String = "static";
	public var pressed_anim(default, set):String = "pressed"; // in case you would use this on lua
	public var confirm_anim(default, set):String = "static";

  private function set_static_anim(value:String):String {
		if (!PlayState.isPixelStage) {
			animation.addByPrefix('static', value);
			animationArray[0] = value;
			if (animation.curAnim != null && animation.curAnim.name == 'static') {
				playAnim('static');
			}
		}
		return value;
	}

	private function set_pressed_anim(value:String):String {
		if (!PlayState.isPixelStage) {
			animation.addByPrefix('pressed', value);
			animationArray[1] = value;
			if (animation.curAnim != null && animation.curAnim.name == 'pressed') {
				playAnim('pressed');
			}
		}
		return value;
	}

	private function set_confirm_anim(value:String):String {
		if (!PlayState.isPixelStage) {
			animation.addByPrefix('confirm', value);
			animationArray[2] = value;
			if (animation.curAnim != null && animation.curAnim.name == 'confirm') {
				playAnim('confirm');
			}
		}
		return value;
	}

	public var rgbShader:RGBShaderReference;
	public var notes_angle:Null<Float> = null;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var multAlpha:Float = 1;

	public var player:Int;
	public var ogNoteskin:String = null;

	public var targetScale:Float = 0.7;

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = (value != null ? value : "noteSkins/NOTE_assets" + Note.getNoteSkinPostfix());
			reloadNote();
		}
		return value;
	}
	public var useRGBShader:Bool = true;
  public var forcedOff:Bool = false;

	public function getAngle() {
		return (notes_angle == null ? angle : notes_angle);
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?inEditor:Bool = false) {
    //animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));

    if (PlayfieldManager.SONG != null && PlayfieldManager.SONG.disableNoteRGB) {
      rgbShader.enabled = false;
      if (PlayfieldManager.SONG != null && PlayfieldManager.SONG.disableNoteRGB || !ClientPrefs.data.enableColorShader)
        useRGBShader = false;
    }

		noteModData = new NoteData();
		strumExtraModData = new StrumExtraData(this);
		//this.applyAngularVelocityOffset = true;

    var colorIndex:Int = (PlayState.instance != null && PlayState.isPixelStage) ?
			ExtraKeys.keysShit.get(ExtraKeys.mania).get('pixelAnimIndex')[leData] :
			ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[leData];
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[colorIndex];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[colorIndex];
		if(arr != null && leData <= arr.length && useRGBShader)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);
		this.positionData = leData;

		var skin:String = null;
		if(PlayfieldManager.SONG != null && PlayfieldManager.SONG.arrowSkin != null && PlayfieldManager.SONG.arrowSkin.length > 1) skin = PlayfieldManager.SONG.arrowSkin;
		else skin = BaseNote.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if (skin == null || skin == '') {
			if (Note.getNoteSkinPostfix() != '')
			{
				var customSkin:String = skin + Note.getNoteSkinPostfix();
				if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
			}
			else {
				var customSkin:String = (PlayfieldManager.SONG != null && PlayfieldManager.SONG.arrowSkin != null ? PlayfieldManager.SONG.arrowSkin : 'NOTE_assets') + Note.getNoteSkinPostfix();
				skin = (PlayState.isPixelStage ? customSkin : 'noteSkins/strums');
			}
		}

		texture = skin; //Load texture and anims
		ogNoteskin = skin;

		this.hsvShader = new HSVNotesShader();

		scrollFactor.set();

		trace('STRUM $leData CREATED!');
	}

  override function toString()
		return '(column: $noteData | texture $texture | visible: $visible)';

	public function reloadNote()
	{
    var postfix:String = Note.getNoteSkinPostfix();
		var skin:String = texture + postfix;
		if (!PlayState.isPixelStage) {
			if(texture.length < 1 || skin == 'null')
			{
				skin = (PlayfieldManager.SONG != null && PlayfieldManager.SONG.arrowSkin?.length != 0 ? PlayfieldManager.SONG.arrowSkin : (texture + postfix));
				if (skin == null || skin.length < 1) {
					if (postfix == null || postfix.length < 1)
						skin = "noteSkins/strums";
					else
						skin = "noteSkins/NOTE_assets" + postfix;
				}
			}
		}

		//Now lets do a psych 0.6.x and below check to see if the notes ARE there, just not in a noteSkins folder
		var pixelFolder:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		var skinPostfix:String = Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$pixelFolder$texture$skinPostfix.png', IMAGE)) { // If a varient of a skin exists and is selected, load it
			skin = texture + skinPostfix;
		} else if (Paths.fileExists('images/${pixelFolder}noteSkins/$texture$skinPostfix.png', IMAGE)) { // If a noteSkins folder exists and the note is in it, use that
			if (skinPostfix == null || skinPostfix.length < 1)
				skin = "noteSkins/strums";
			else
				skin = 'noteSkins/$texture$skinPostfix';
		}

    if (PlayState.isPixelStage || postfix.toLowerCase() == '-retribution') {
			useRGBShader = false;
			rgbShader.forceDisabled = forcedOff = true;
		}

		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var pxDV:Int = ExtraKeys.pixelNotesDivisionValue[width == 306 ? 1 : 0];

    animationArray[0] = ExtraKeys.keysShit.get(ExtraKeys.mania).get('strumAnims')[noteData];
		animationArray[1] = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData];
		animationArray[2] = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData]; //jic

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + skin));
			pxDV = ExtraKeys.pixelNotesDivisionValue[width == 306 ? 1 : 0];
			width = width / pxDV;
			height = height / 5;
			antialiasing = false;
			loadGraphic(Paths.image('pixelUI/' + skin), true, Math.floor(width), Math.floor(height));
      var daFrames:Array<Int> = ExtraKeys.keysShit.get(ExtraKeys.mania).get('pixelAnimIndex');

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * ExtraKeys.pixelScales[ExtraKeys.mania]));
      updateHitbox();
			antialiasing = false;
			animation.add('static', [daFrames[noteData]]);
			animation.add('pressed', [daFrames[noteData] + pxDV, daFrames[noteData] + (pxDV * 2)], 12, false);
			animation.add('confirm', [daFrames[noteData] + (pxDV * 3), daFrames[noteData] + (pxDV * 4)], 24, false);
		}
		else
		{
      var skin:String = texture;
			//trace("Skin: " + skin);
			skin = (PlayfieldManager.SONG != null && (PlayfieldManager.SONG.arrowSkin != null && PlayfieldManager.SONG.arrowSkin.length > 0) ? PlayfieldManager.SONG.arrowSkin : texture);
			if (skin == 'noteSkins/NOTE_assets' || skin == null) {
				skin = "noteSkins/strums";
			}

			trace("Skin: " + skin);

			frames = Paths.getAtlas(skin);
      antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * ExtraKeys.scales[ExtraKeys.mania]));

			// Get the appropriate animation name for this column from the mania mapping
			var strumAnim:String = animationArray[0]; // This is the strumAnims value
			var letterAnim:String = animationArray[1]; // This is the letters value

			// First try the hardcoded switch for traditional 4K animations (backwards compatibility)
			switch (Math.abs(noteData))
			{
				case 0:
					attemptToAddAnimationByPrefix('static', 'arrowLEFT', 24, true);
					attemptToAddAnimationByPrefix('pressed', 'left press');
					attemptToAddAnimationByPrefix('confirm', 'left confirm');
				case 1:
					attemptToAddAnimationByPrefix('static', 'arrowDOWN', 24, true);
					attemptToAddAnimationByPrefix('pressed', 'down press');
					attemptToAddAnimationByPrefix('confirm', 'down confirm');
				case 2:
					attemptToAddAnimationByPrefix('static', 'arrowUP', 24, true);
					attemptToAddAnimationByPrefix('pressed', 'up press');
					attemptToAddAnimationByPrefix('confirm', 'up confirm');
				case 3:
					attemptToAddAnimationByPrefix('static', 'arrowRIGHT', 24, true);
					attemptToAddAnimationByPrefix('pressed', 'right press');
					attemptToAddAnimationByPrefix('confirm', 'right confirm');
			}

			// Then try using the mania-specific animations (for extended mania support)
			// First try with the original strumAnim, only fall back to UP if SPACE animation doesn't exist
			var staticAdded:Bool = attemptToAddAnimationByPrefix('static', 'arrow' + strumAnim, 24, true);
			if (!staticAdded && strumAnim == 'SPACE') {
				// If SPACE animation doesn't exist, fall back to UP for visual consistency
				attemptToAddAnimationByPrefix('static', 'arrow' + 'UP', 24, true);
			}
			attemptToAddAnimationByPrefix('pressed', letterAnim + ' press');
			attemptToAddAnimationByPrefix('confirm', letterAnim + ' confirm');

			// For noteskins that only have 4K support, try using the proper directional confirm animations
			// based on the strumAnim value instead of letterAnim
			var confirmDirection:String = strumAnim.toLowerCase();
			if (confirmDirection == 'space') confirmDirection = 'up'; // Handle SPACE -> UP mapping
			attemptToAddAnimationByPrefix('confirm', confirmDirection + ' confirm');
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

  function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = false)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return false;

		animation.addByPrefix(name, prefix, framerate, doLoop);
		return true;
	}

	public function postAddedToGroup() {
		playAnim('static');
		switch (ExtraKeys.mania)
		{
			case 0 | 1 | 2: x += width * noteData;
			case 3: x += (BaseNote.swagWidth * noteData);
			default: x += ((width - ExtraKeys.lessX[ExtraKeys.mania]) * noteData);
		}
		x += 50;
		x += ExtraKeys.xtra[ExtraKeys.mania];
		x += ((FlxG.width / 2) * player);
		x -= ExtraKeys.posRest[ExtraKeys.mania];
		ID = noteData;
		formerPosition.set(x, y);
		targetScale = this.scale.x;
	}

	override function update(elapsed:Float) {
		if (this.alpha <= 0 || !this.visible || !this.alive)
			return;
		super.update(elapsed);
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

    alpha *= multAlpha;
    alpha *= hardAlpha;
	}

	public function playAnim(anim:String, ?force:Bool = false, ?r:FlxColor, ?g:FlxColor, ?b:FlxColor) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader)
		{
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
			if (r != null && g != null && b != null) updateRGBColors(r, g, b);
		} else if (!useRGBShader && rgbShader != null) rgbShader.enabled = false;
	}
	public function updateNoteSkin(noteskin:String) {
			if (texture == "noteSkins/" + noteskin || noteskin == ogNoteskin || texture == noteskin) return; //if the noteskin to change to is the same as before then don't update it
			if (noteskin != null && noteskin.length > 0) texture = "noteSkins/" + noteskin;
			else texture = "noteSkins/NOTE_assets" + Note.getNoteSkinPostfix();
	}

	public function updateRGBColors(?r:FlxColor, ?g:FlxColor, ?b:FlxColor) {
    if (rgbShader != null && useRGBShader)
		{
			rgbShader.r = r;
			rgbShader.g = g;
			rgbShader.b = b;
		}
	}

	public function resetRGB()
	{
		if (rgbShader != null && animation.curAnim != null && animation.curAnim.name == 'static')
		{
			switch (ClientPrefs.data.noteColorStyle)
			{
				case 'Quant-Based', 'Rainbow', 'Char-Based':
				rgbShader.r = 0xFFF9393F;
				rgbShader.g = 0xFFFFFFFF;
				rgbShader.b = 0xFF651038;
				case 'Grayscale':
				rgbShader.r = 0xFFA0A0A0;
				rgbShader.g = FlxColor.WHITE;
				rgbShader.b = 0xFF424242;
				default:

			}
			rgbShader.enabled = false;
		}
	}

	@:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (this.alpha <= 0 || !this.visible || !this.alive)
    {
      return;
    }

    this.playfieldSkewCenterX = strumExtraModData.playfieldX;
    this.playfieldSkewCenterY = strumExtraModData.playfieldY;
    this.playfieldSkewCenterZ = strumExtraModData.playfieldZ;

    //projectionEnabled = strumExtraModData?.threeD ?? false;
    super.draw();
  }

	public function playStatic():Void
  {
    this.active = (forceActive || isAnimationDynamic('static'));
    this.playAnim('static', true);
  }

  public function playPress():Void
  {
    this.active = (forceActive || isAnimationDynamic('press'));
    this.playAnim('press', true);
  }

  public function playConfirm():Void
  {
    this.active = (forceActive || isAnimationDynamic('confirm'));
    this.playAnim('confirm', true);

    // On opponent, run a timer to stop playing the confirm animation.
    // On player, stop the timer to avoid stopping the confirm animation earlier.
    resetAnim = player==1 ? -1 : 0;
  }

  public function isConfirm():Bool
  {
    return getCurrentAnimation().startsWith('confirm');
  }

  public function holdConfirm():Void
  {
    this.active = true;

    if (getCurrentAnimation() == "confirm")
    {
      if (isAnimationFinished())
      {
        this.resetAnim = -1;
        //this.playAnim('confirm-hold', false, false);
      }
    }
    else
    {
      this.playAnim('confirm', false);
    }
  }

	// call this to reset stealthGlow back to default values
  public function resetStealthGlow(skipUpdate:Bool = false):Void
  {
    this.stealthGlow = 0.0;
    this.stealthGlowBlue = 1.0;
    this.stealthGlowGreen = 1.0;
    this.stealthGlowRed = 1.0;
    if (!skipUpdate) updateStealthGlow();
  }

  // call this to update the stealthglow on the hsv shader
  public function updateStealthGlow():Void
  {
    this.hsvShader.stealthGlow = stealthGlow;
    this.hsvShader.stealthGlowBlue = stealthGlowBlue;
    this.hsvShader.stealthGlowGreen = stealthGlowGreen;
    this.hsvShader.stealthGlowRed = stealthGlowRed;
  }
}
