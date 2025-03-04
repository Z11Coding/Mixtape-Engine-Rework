package objects;

import backend.animation.PsychAnimationController;

import flixel.addons.plugin.FlxMouseControl;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import backend.math.Vector3;
import objects.playfields.PlayField;

class StrumNote extends NoteObject
{

	public var rgbShader:RGBShaderReference;

	public var z:Float = 0;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	
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
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[leData]];
		if(PlayState.instance != null && PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[leData]];
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
		this.ID = noteData;
		// trace(noteData);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		if (Note.getNoteSkinPostfix() != '')
		{
			var customSkin:String = skin + Note.getNoteSkinPostfix();
			if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		}
		else skin = 'noteskins/strums';

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	override function toString()
		return '(column: $column | texture $texture | visible: $visible)';

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;

		frames = Paths.getSparrowAtlas(br);

		antialiasing = ClientPrefs.data.antialiasing;
		setGraphicSize(Std.int(width * 0.7));

		animationArray[0] = Note.keysShit.get(PlayState.mania).get('strumAnims')[column];
		animationArray[1] = Note.keysShit.get(PlayState.mania).get('letters')[column];
		animationArray[2] = Note.keysShit.get(PlayState.mania).get('letters')[column]; //jic
		var pxDV:Int = PlayState.mania != 17 ? Note.pixelNotesDivisionValue[0] : Note.pixelNotesDivisionValue[1];

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / pxDV;
			height = height / 5;
			antialiasing = false;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
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
			frames = Paths.getSparrowAtlas(texture);

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * Note.scales[PlayState.mania]));

			switch (Math.abs(column))
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

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
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