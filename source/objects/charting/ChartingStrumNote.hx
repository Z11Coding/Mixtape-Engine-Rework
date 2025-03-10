package objects.charting;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class ChartingStrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;

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

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
		
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[leData];
		
		if(leData <= arr.length)
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
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		if (Note.getNoteSkinPostfix() != '')
		{
			var customSkin:String = skin + Note.getNoteSkinPostfix();
			if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		}
		else {
			var customSkin:String = 'NOTE_assets' + Note.getNoteSkinPostfix();
			skin = 'noteskins/' + (PlayState.isPixelStage ? customSkin : 'strums');
		}

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	override function toString()
		return '(column: $noteData | texture $texture | visible: $visible)';

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;

		frames = Paths.getSparrowAtlas(br);

		antialiasing = ClientPrefs.data.antialiasing;
		setGraphicSize(Std.int(width * 0.7));

		animationArray[0] = Note.keysShit.get(PlayState.mania).get('strumAnims')[noteData];
		animationArray[1] = Note.keysShit.get(PlayState.mania).get('letters')[noteData];
		animationArray[2] = Note.keysShit.get(PlayState.mania).get('letters')[noteData]; //jic
		var pxDV:Int = Note.pixelNotesDivisionValue[1];

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
			switch (Math.abs(noteData))
			{
				case 0:
					animation.add('static', [daFrames[0]]);
					animation.add('pressed', [daFrames[0] + pxDV, daFrames[0] + (pxDV * 2)], 12, false);
					animation.add('confirm', [daFrames[0] + (pxDV * 3), daFrames[0] + (pxDV * 4)], 24, false);
				case 1:
					animation.add('static', [daFrames[1]]);
					animation.add('pressed', [daFrames[1] + pxDV, daFrames[1] + (pxDV * 2)], 12, false);
					animation.add('confirm', [daFrames[1] + (pxDV * 3), daFrames[1] + (pxDV * 4)], 24, false);
				case 2:
					animation.add('static', [daFrames[2]]);
					animation.add('pressed', [daFrames[2] + pxDV, daFrames[2] + (pxDV * 2)], 12, false);
					animation.add('confirm', [daFrames[2] + (pxDV * 3), daFrames[2] + (pxDV * 4)], 24, false);
				case 3:
					animation.add('static', [daFrames[3]]);
					animation.add('pressed', [daFrames[3] + pxDV, daFrames[3] + (pxDV * 2)], 12, false);
					animation.add('confirm', [daFrames[3] + (pxDV * 3), daFrames[3] + (pxDV * 4)], 24, false);
			}
			//i used windows calculator
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);

			antialiasing = ClientPrefs.data.antialiasing;
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

	public function playerPosition()
	{
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
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

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}