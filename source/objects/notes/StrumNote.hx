package objects.notes;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.notes.NoteObject;
import objects.playfields.PlayField;
import backend.math.Vector3;
import states.PlayState;

class StrumNote extends NoteObject
{
	public var rgbShader:RGBShaderReference;
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code

	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;
    public var notes_angle:Null<Float> = null;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	public var player:Int;
	public var ogNoteskin:String = null;
	
	public var animationArray:Array<String> = ['static', 'pressed', 'confirm'];
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = (value != null ? value : "noteskins/NOTE_assets" + Note.getNoteSkinPostfix());
			reloadNote();
		}
		return value;
	}
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

	public var useRGBShader:Bool = true;

	public function getAngle() {
		return (notes_angle == null ? angle : notes_angle);
	}

	public function getZIndex(?daZ:Float)
	{
		if(daZ==null)daZ = z;
		var animZOffset:Float = 0;
		if (animation.curAnim != null && animation.curAnim.name == 'confirm')
			animZOffset += 1;
		return z + desiredZIndex + animZOffset;
	}

	function updateZIndex()
	{
		zIndex = getZIndex();
	}

	public function new(x:Float, y:Float, leData:Int, ?player:Null<Int>, ?inEditor:Bool = false, ?field:PlayField) {
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB || !ClientPrefs.data.enableColorShader) useRGBShader = false;
		
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[leData];
		if(leData <= arr.length && useRGBShader)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
		noteData = leData;
		if (player != null) this.player = player;
		else player = 1;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		ogNoteskin = skin;

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);

			antialiasing = ClientPrefs.data.globalAntialiasing;
			setGraphicSize(Std.int(width * Note.scales[PlayState.mania]));

			switch (Math.abs(noteData))
			{
				case 0:
					attemptToAddAnimationByPrefix('static', 'arrowLEFT');
					attemptToAddAnimationByPrefix('pressed', 'left press', 24, false);
					attemptToAddAnimationByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					attemptToAddAnimationByPrefix('static', 'arrowDOWN');
					attemptToAddAnimationByPrefix('pressed', 'down press', 24, false);
					attemptToAddAnimationByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					attemptToAddAnimationByPrefix('static', 'arrowUP');
					attemptToAddAnimationByPrefix('pressed', 'up press', 24, false);
					attemptToAddAnimationByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					attemptToAddAnimationByPrefix('static', 'arrowRIGHT');
					attemptToAddAnimationByPrefix('pressed', 'right press', 24, false);
					attemptToAddAnimationByPrefix('confirm', 'right confirm', 24, false);
			}

			attemptToAddAnimationByPrefix('static', 'arrow' + animationArray[0]);
			attemptToAddAnimationByPrefix('pressed', animationArray[1] + ' press');
			attemptToAddAnimationByPrefix('confirm', animationArray[1] + ' confirm', 24, false);
		}
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

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	public function playerPosition()
	{
		playAnim('static');
		switch (PlayState.mania)
		{
			case 0 | 1 | 2: x += width * noteData;
			case 3: x += (Note.swagWidth * noteData);
			default: x += ((width - Note.lessX[PlayState.mania]) * noteData);
		}

		x += Note.xtra[PlayState.mania];
	
		x += 50;
		x += ((FlxG.width / 2) * 1);
		x -= Note.posRest[PlayState.mania];
	}

	override function update(elapsed:Float) {
		if (ClientPrefs.data.ffmpegMode) elapsed = 1 / ClientPrefs.data.targetFPS;
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
		updateZIndex();
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?r:FlxColor, ?g:FlxColor, ?b:FlxColor) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
			updateZIndex();
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
        if (rgbShader != null)
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
}