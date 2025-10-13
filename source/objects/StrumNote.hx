package objects;

import backend.animation.PsychAnimationController;
import backend.math.Vector3;
import flixel.addons.plugin.FlxMouseControl;
import objects.playfields.PlayField;
import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette;

class StrumNote extends NoteObject
{
	public var rgbShader:RGBShaderReference;

	public var z:Float = 0;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var formerPosition:FlxPoint = FlxPoint.get();
	public var positionData:Int = 0;
	private var player:Int;

	public static var ogStrumPosX:Array<Null<Float>> = [];
	public static var ogStrumPosY:Array<Null<Float>> = [];

	public var animationArray:Array<String> = ['static', 'pressed', 'confirm'];
	public var static_anim(default, set):String = "static";
	public var pressed_anim(default, set):String = "pressed"; // in case you would use this on lua
	// though, you shouldn't change it
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

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	private var field:PlayField;
	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, ?playField:PlayField) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
		// Use colArray for color indexing on non-pixel stages, pixelAnimIndex for pixel stages
		var colorIndex:Int = (PlayState.instance != null && PlayState.isPixelStage) ?
			Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[leData] :
			Note.keysShit.get(PlayState.mania).get('colArray')[leData];
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[colorIndex];
		if(PlayState.instance != null && PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[colorIndex];
		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		super(x, y);
		objType = STRUM;
		noteData = leData;
		column = leData;
		field = playField;
		this.noteData = leData;
		positionData = noteData;
		this.ID = noteData;

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;

		if (skin == null || skin == '') {
			if (Note.getNoteSkinPostfix() != '')
			{
				var customSkin:String = skin + Note.getNoteSkinPostfix();
				if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
			}
			else {
				var customSkin:String = (PlayState.SONG != null && PlayState.SONG.arrowSkin != null ? PlayState.SONG.arrowSkin : 'NOTE_assets') + Note.getNoteSkinPostfix();
				skin = (PlayState.isPixelStage ? customSkin : 'noteSkins/strums');
			}
		}

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
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
				skin = (PlayState.SONG != null ? PlayState.SONG.arrowSkin : (texture + postfix));
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
		} else if (Paths.fileExists('images/${pixelFolder}noteSkins/$texture.png', IMAGE)) { // If a noteSkins folder exists and the note is in it, use that
			skin = 'noteSkins/$texture$skinPostfix';
		}

		if (PlayState.isPixelStage || postfix.toLowerCase() == '-retribution')
			useRGBShader = false;

		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var pxDV:Int = Note.pixelNotesDivisionValue[1];

		animationArray[0] = Note.keysShit.get(PlayState.mania).get('strumAnims')[column];
		animationArray[1] = Note.keysShit.get(PlayState.mania).get('letters')[column];
		animationArray[2] = Note.keysShit.get(PlayState.mania).get('letters')[column]; //jic

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + skin));
			pxDV = Note.pixelNotesDivisionValue[width == 306 ? 1 : 0];
			width = width / pxDV;
			height = height / 5;
			antialiasing = false;
			loadGraphic(Paths.image('pixelUI/' + skin), true, Math.floor(width), Math.floor(height));
			var daFrames:Array<Int> = Note.keysShit.get(PlayState.mania).get('pixelAnimIndex');

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[PlayState.mania]));
			updateHitbox();
			antialiasing = false;
			animation.add('static', [daFrames[column]]);
			animation.add('pressed', [daFrames[column] + pxDV, daFrames[column] + (pxDV * 2)], 12, false);
			animation.add('confirm', [daFrames[column] + (pxDV * 3), daFrames[column] + (pxDV * 4)], 24, false);
			//i used windows calculator
		}
		else
		{
			var postfix:String = Note.getNoteSkinPostfix();
			var skin:String = texture + postfix;
			//trace("Skin: " + skin);
			if(texture.length < 1)
			{
				skin = (PlayState.SONG != null ? PlayState.SONG.arrowSkin : (texture + postfix));
				if (skin == 'noteSkins/NOTE_assets') {
					skin = "noteSkins/strums";
				}
			}

			//trace("Skin: " + skin);

			frames = Paths.getSparrowAtlas(skin);
			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * Note.scales[PlayState.mania]));

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
		defScale.copyFrom(scale);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	var ogArrowList:Array<String> = [
		"LEFT",
		"DOWN",
		"UP",
		"RIGHT",
	];

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = false)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return false;

		animation.addByPrefix(name, prefix, framerate, doLoop);
		return true;
	}

	public function playerPosition()
	{
		playAnim('static');
		switch (PlayState.mania)
		{
			case 0 | 1 | 2: x += width * column;
			case 3: x += (Note.swagWidth * column);
			default: x += ((width - Note.lessX[PlayState.mania]) * column);
		}

		x += Note.xtra[PlayState.mania];

		x += 50;
		x += ((FlxG.width / 2) * 1);
		x -= Note.posRest[PlayState.mania];
		formerPosition.set(x, y);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

		if(animation.curAnim != null){
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage)
				centerOrigin();

		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?note:Note) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOrigin();
			centerOffsets();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}
