package states;

import backend.window.CppAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIText;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Promise;
import backend.cutscenes.DialogueBoxPsych;
import flixel.FlxCamera;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import lime.app.Application;
import flixel.util.FlxSave;
import flixel.FlxState;
#if windows
import Sys;
import sys.FileSystem;
#end
class WelcomeToPain extends MusicBeatState
{
	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	public var camMESSAGE:FlxCamera;
	var camfilters:Array<BitmapFilter> = [];
	var ch = 2 / 1000;
	public static var itsme:Bool = true;
	public var save:FlxSave = new FlxSave();
	private var originalState:FlxState;
	private var originalStateArgs:Array<Dynamic>;
	public function new(originalState:FlxState = null, ?args:Array<Dynamic>) 
	{
		if (originalState == null)
			originalState = new states.TitleState();
		this.originalState = originalState;
		super();
	}
	
	override public function create():Void 
	{   CppAPI.setWindowOpacity(1);
		camMESSAGE = initPsychCamera();
		super.create();
		camMESSAGE.setFilters(camfilters);
		camMESSAGE.filtersEnabled = true;	
		camfilters.push(shaders.ShadersHandler.chromaticAberration);
		FlxG.sound.playMusic(Paths.music("hello"),1);
		var daStatic:FlxSprite = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('effects/static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.cameras = [camMESSAGE];
		daStatic.animation.addByPrefix('static','lestatic',24, true);
		add(daStatic);
		if (daStatic.alpha != 0)
			daStatic.alpha = 1;
		daStatic.animation.play('static');
		new FlxTimer().start(4, function(deadTime:FlxTimer)
		{
			startDialogue(dialogueJson);
		});
		
	}

	var gotSecret:String = if (Achievements.isUnlocked('secretsuntold')) 'gsecret' else 'nsecret';
	override public function update(elapsed:Float)
	{
		ch = FlxG.random.int(1,5) / 1000;
		ch = FlxG.random.int(1,5) / 1000;
		shaders.ShadersHandler.setChrome(ch);
		super.update(elapsed);
		var file:String = Paths.json('secrets/'+gotSecret); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}
	}
	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			psychDialogue.finishThing = function()
			{
				Application.current.window.alert("Null Object Reference");
				ClientPrefs.data.gotit = true;
				FlxG.switchState(originalState);
				psychDialogue = null;
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camMESSAGE];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			FlxG.switchState(originalState);
		}
	}
	function startNextDialogue()
	{
		dialogueCount++;
	}

	function skipDialogue()
	{
		//callOnLuas('onSkipDialogue', [dialogueCount]);
	}
	
}