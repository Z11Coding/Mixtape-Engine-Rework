package objects.notes;

import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette;

class StrumNote extends FlxSprite
{
  public static var hardAlpha:Float = 1; // For hard mode

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

	public var player:Int;
	public var ogNoteskin:String = null;

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = (value != null ? value : "noteskins/NOTE_assets" + Note.getNoteSkinPostfix());
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
    animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));

    if (PlayfieldManager.SONG != null && PlayfieldManager.SONG.disableNoteRGB) {
      rgbShader.enabled = false;
      if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB || !ClientPrefs.data.enableColorShader)
        useRGBShader = false;
    }

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

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

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

		scrollFactor.set();
	}

  override function toString()
		return '(column: $column | texture $texture | visible: $visible)';

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
			skin = 'noteSkins/$texture$skinPostfix';
		}

    if (PlayState.isPixelStage || postfix.toLowerCase() == '-retribution') {
			useRGBShader = false;
			rgbShader.forceDisabled = forcedOff = true;
		}

		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var pxDV:Int = ExtraKeys.pixelNotesDivisionValue[width == 306 ? 1 : 0];

    animationArray[0] = ExtraKeys.keysShit.get(ExtraKeys.mania).get('strumAnims')[column];
		animationArray[1] = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[column];
		animationArray[2] = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[column]; //jic

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + skin));
			pxDV = Note.pixelNotesDivisionValue[width == 306 ? 1 : 0];
			width = width / pxDV;
			height = height / 5;
			antialiasing = false;
			loadGraphic(Paths.image('pixelUI/' + skin), true, Math.floor(width), Math.floor(height));
      var daFrames:Array<Int> = Note.keysShit.get(PlayfieldManager.mania[0]).get('pixelAnimIndex');

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[ExtraKeys.mania]));
      updateHitbox();
			antialiasing = false;
			animation.add('static', [daFrames[column]]);
			animation.add('pressed', [daFrames[column] + pxDV, daFrames[column] + (pxDV * 2)], 12, false);
			animation.add('confirm', [daFrames[column] + (pxDV * 3), daFrames[column] + (pxDV * 4)], 24, false);
		}
		else
		{
      var postfix:String = Note.getNoteSkinPostfix();
			var skin:String = texture + postfix;
			//trace("Skin: " + skin);
			if(texture.length < 1)
			{
				skin = (PlayfieldManager.SONG != null ? PlayfieldManager.SONG.arrowSkin : (texture + postfix));
				if (skin == 'noteSkins/NOTE_assets') {
					skin = "noteSkins/strums";
				}
			}

			trace("Skin: " + skin);

			frames = Paths.getSparrowAtlas(skin);
      antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * Note.scales[ExtraKeys.mania]));

			// Get the appropriate animation name for this column from the mania mapping
			var strumAnim:String = animationArray[0]; // This is the strumAnims value
			var letterAnim:String = animationArray[1]; // This is the letters value

			// First try the hardcoded switch for traditional 4K animations (backwards compatibility)
			switch (Math.abs(column))
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
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

    alpha *= multAlpha;
    alpha *= hardAlpha;
		super.update(elapsed);
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
			if (texture == "noteskins/" + noteskin || noteskin == ogNoteskin || texture == noteskin) return; //if the noteskin to change to is the same as before then don't update it
			if (noteskin != null && noteskin.length > 0) texture = "noteskins/" + noteskin;
			else texture = "noteskins/NOTE_assets" + Note.getNoteSkinPostfix();
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
			switch (ClientPrefs.noteColorStyle)
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
}
