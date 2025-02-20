package objects;

import backend.animation.PsychAnimationController;

import flixel.addons.plugin.FlxMouseControl;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import backend.math.Vector3;

using StringTools;

class StrumNote extends NoteObject
{

	public var rgbShader:RGBShaderReference;
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code

	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;
	
	override function destroy()
	{
		defScale.put();
		super.destroy();
	}	
	public var isQuant:Bool = false;
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	
	//private var player:Int;

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
	
	var field:PlayField;
	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, ?field:PlayField) {
		FlxG.plugins.add(new FlxMouseControl());
		animation = new PsychAnimationController(this);
		
		if (PlayState.mania <= 8)
		{
			rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
			rgbShader.enabled = false;
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
			var arr:Array<FlxColor> = ClientPrefs.data.arrowRGBExtra[Note.gfxIndex[PlayState.mania][leData]];
			if(PlayState.instance != null && PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixelExtra[Note.gfxIndex[PlayState.mania][leData]];
			if(leData <= PlayState.mania)
			{
				@:bypassAccessor
				{
					rgbShader.r = arr[0];
					rgbShader.g = arr[1];
					rgbShader.b = arr[2];
				}
			}
		}
		else useRGBShader = false;
		this.field = field;
		super(x, y);
		objType = STRUM;
		noteData = leData;
		this.noteData = leData;
		this.ID = noteData;
		// trace(noteData);

		var skin:String = 'normal';
		if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1 && (!Paths.doesImageAssetExist(Paths.modsImages('noteskins/normal')) || !Paths.doesImageAssetExist(Paths.getPath('images/noteskins/normal')))) skin = 'normal';
			texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;

		frames = Paths.getSparrowAtlas(br);

		antialiasing = ClientPrefs.data.globalAntialiasing;
		setGraphicSize(Std.int(width * 0.7));

		animationArray[0] = Note.keysShit.get(PlayState.mania).get('strumAnims')[noteData];
		animationArray[1] = Note.keysShit.get(PlayState.mania).get('letters')[noteData];
		animationArray[2] = Note.keysShit.get(PlayState.mania).get('letters')[noteData]; //jic
		var pxDV:Int = Note.pixelNotesDivisionValue;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('noteskins/pixelUI/' + texture));
			width = width / Note.pixelNotesDivisionValue;
			height = height / 5;
			antialiasing = false;
			loadGraphic(Paths.image('noteskins/pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
			var daFrames:Array<Int> = Note.keysShit.get(PlayState.mania).get('pixelAnimIndex');

			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[PlayState.mania]));
			updateHitbox();
			antialiasing = false;
			animation.add('static', [daFrames[noteData]]);
			animation.add('pressed', [daFrames[noteData] + pxDV, daFrames[noteData] + (pxDV * 2)], 12, false);
			animation.add('confirm', [daFrames[noteData] + (pxDV * 3), daFrames[noteData] + (pxDV * 4)], 24, false);
			//i used windows calculator
		}
		else
		{
			frames = Paths.getSparrowAtlas('noteskins/'+texture);

			antialiasing = ClientPrefs.data.globalAntialiasing;

			setGraphicSize(Std.int(width * Note.scales[PlayState.mania]));
	
			animation.addByPrefix('static', 'arrow' + animationArray[0]);
			animation.addByPrefix('pressed', animationArray[1] + ' press', 24, false);
			animation.addByPrefix('confirm', animationArray[1] + ' confirm', 24, false);
		}
		defScale.copyFrom(scale);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

/* 	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width* 0.5) * player);
		ID = noteData;
	} */
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

	public function playAnim(anim:String, ?force:Bool = false, ?note:Note) {
		animation.play(anim, force);
		centerOrigin();
		centerOffsets();
		updateZIndex();
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}