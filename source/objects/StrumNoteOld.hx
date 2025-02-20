package objects;

import flixel.math.FlxPoint;
import math.Vector3;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxExtendedSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.plugin.FlxMouseControl;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.utils.AssetType;
import openfl.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
using StringTools;

class StrumNote extends NoteObject
{
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code

	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;

	override function destroy()
	{
		defScale.put();
		super.destroy();
	}
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	public var openNoteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var char:String = "normal";

	public var player:Int;
	public static var players:Int;
	public var doAntialiasing:Bool = ClientPrefs.globalAntialiasing;

	public var animationArray:Array<String> = ['static', 'pressed', 'confirm'];
	public var static_anim(default, set):String = "static";
	public var pressed_anim(default, set):String = "pressed"; // in case you would use this on lua
	// though, you shouldn't change it
	public var confirm_anim(default, set):String = "static";

	public var noteSkin:String = 'normal';

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

	public function getZIndex()
	{
		var animZOffset:Float = 0;
		if (animation.curAnim != null && animation.curAnim.name == 'confirm')
			animZOffset += 1;
		return z + desiredZIndex + animZOffset - (player == 0 ? 1 : 0);
	}

	function updateZIndex()
	{
		zIndex = getZIndex();
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, char:String, ?opendata:Int = 0, ?inEditor:Bool = false) {
		FlxG.plugins.add(new FlxMouseControl());

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		openNoteData = opendata;
		this.player = player;
		this.noteData = leData;
		this.char = char;
		super(x, y);

		players = player;

		animationArray[0] = Note.keysShit.get(PlayState.mania).get('strumAnims')[leData];
		animationArray[1] = Note.keysShit.get(PlayState.mania).get('letters')[leData];
		animationArray[2] = Note.keysShit.get(PlayState.mania).get('letters')[leData]; //jic
		var skin:String;
		skin = 'noteskins/normal';

		doAntialiasing = ClientPrefs.globalAntialiasing;
		
		//if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		if (char != null && animationArray[0].contains('CIRCLE')) skin = "noteskins/" + char;
		else 'noteskins/normal';

		/*if (Note.ammo[PlayState.mania] < 9)
		{
			
		}
		else
		{
			skin = 'noteskins/normal';
		}*/
		if (inEditor)
		{
			skin = 'noteskins/normal'; 
		}
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		var pxDV:Int = Note.pixelNotesDivisionValue;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / Note.pixelNotesDivisionValue;
			height = height / 5;
			antialiasing = false;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
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
			frames = Paths.getSparrowAtlas(texture);

			antialiasing = ClientPrefs.globalAntialiasing;

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

	public function postAddedToGroup() {
		playAnim('static');
		/**
		 * list of complicated math that occurs down below:
		 * start by adding X value to strum
		 * add extra X value accordng to Note.xtra
		 * add 50 for centered strum
		 * put the strums in the correct side
		 * subtract X value for centered strum
		**/

		switch (PlayState.mania)
		{
			case 0 | 1 | 2: x += width * noteData;
			case 3: x += (Note.swagWidth * noteData);
			default: x += ((width - Note.lessX[PlayState.mania]) * noteData);
		}

		x += Note.xtra[PlayState.mania];
	
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
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
		/*if(animation.curAnim != null){ //my bad i was upset
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}*/
		if(animation.curAnim != null){
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) 
				centerOrigin();
			
		}
		updateZIndex();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		updateZIndex();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if (noteData > -1 && noteData < ClientPrefs.arrowHSV.length && Note.ammo[PlayState.mania] < 4)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][2] / 100;
			}
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}
}
