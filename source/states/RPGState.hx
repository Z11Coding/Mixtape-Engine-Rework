package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import backend.Achievements;
import backend.cutscenes.DialogueBoxPsych;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
#if sys
import sys.FileSystem;
#end
using StringTools;

class RPGState extends MusicBeatState
{

	//keywords for people who need help with RPGing to help them find this better! :) tutorial, rpg, hitbox, wall, door, boss, enemy,

	//Welcome to the RPG section of the Trials Mod! (Code Originally Undertale FNF mod) If you're here, you probably want to incorperate an RPG mechanic in your own mod. Well, this should hopefully help you.
	//In order to add a world, add a variable to the switch(area) function. In there, you'll see coordinates for all the hitboxes, player spawns, ETC. 
	//There are three arrays that you should be aware of: collisionList, obbyList, and interactList. interactList is your dialogue interactions, boss interactions, ETC. obbyList is your custom hitboxes for objets, such as chairs.
	//collisionList is the default list for the Background. It will automatically place a border around your background.
	//Hope this helps somewhat! It's a bit confusing and really really messy. Alot of the stuff I just brute forced and it's hard to apply to other mods. Hopefully, some better coder comes around and cleans up this mess. Good luck, game dev!

	public static var triggerMusic:Bool;

	public static var progression:String = "Yep";
	public static var progress:Float = 0;


	public static var area:String;
	public static var psychEngineVersion:String = '0.7.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public var stunned:Bool	= false;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	public var camMESSAGE:FlxCamera;
	var optionShit:Array<String> = ['story_mode', 'freeplay', #if ACHIEVEMENTS_ALLOWED 'awards', #end 'credits', #if !switch 'donate', #end 'options'];
	var collisionList:Array<FlxSprite> = [];
	var obbyList:Array<FlxSprite> = [];
	var textList:Array<FlxSprite> = [];
	var interactList:Array<FlxSprite> = [];
	var magenta:FlxSprite;
	var overBF:FlxSprite;
	var exit1:FlxSprite = new FlxSprite(-80);
	var exit2:FlxSprite = new FlxSprite(-80);
	var isInteracting:Bool = false;
	var leftHeld:Bool = false;
	var rightHeld:Bool = false;
	var upHeld:Bool = false;
	var downHeld:Bool = false;
	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	var camfilters:Array<BitmapFilter> = [];
	var ch = 2 / 1000;
	public var answer:String = null;
	var allowInputs:Bool = true;
	var allowRetry:Bool = true;
	public static var selectSpr:FlxSprite;
	public static var noText:FlxText;
	public static var yesText:FlxText;


	function findMiddle(len:Float,position:Float)
	{
		return (position - (len/4));
	}
	override function create()
	{
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;
		camMESSAGE = new FlxCamera();
		camMESSAGE.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxG.cameras.add(camMESSAGE);
		FlxCamera.defaultCameras = [camGame];
		camMESSAGE.setFilters(camfilters);
		camMESSAGE.filtersEnabled = true;
		camfilters.push(shaders.ShadersHandler.chromaticAberration);

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80);
		if (triggerMusic)
		{
			FlxG.sound.playMusic(Paths.music('The Void Between Time And Space part 2'));
			triggerMusic = false;
		}
		var daStatic:FlxSprite = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('static', 'pain');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.cameras = [camMESSAGE];
		daStatic.animation.addByPrefix('static','lestatic',24, false);
		add(daStatic);
		if (daStatic.alpha != 0)
			daStatic.alpha = 0.3;
		daStatic.animation.play('static');
		daStatic.animation.finishCallback = function(pog:String)
		{
			daStatic.animation.play('static');
		}
		switch(area)
		{
		case("SaveM" | "SaveE" | "SaveOptions"):
				var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
				bg = new FlxSprite(-80).loadGraphic(Paths.image('voidRoom'));
				bg.setGraphicSize(Std.int(bg.width * 1.1));
				bg.x = 0;
				bg.y = 0;

				overBF = new FlxSprite(-80).loadGraphic(Paths.image('boyfriendrpg'));

				if (area == "SaveM")
				{
					overBF.x = bg.x + (bg.width/2);
					overBF.y = bg.width - 300;
					area = "Save";
				}
				if (area == "SaveOptions")
				{
					overBF.x = bg.x + (bg.width/2);
					overBF.y = bg.width - 300;
					area = "Save";
				}
				/*if (area == "SaveE")
				{
					overBF.x = bg.x + (bg.width/2) - 500;
					overBF.y = bg.width - 1300;
					area = "Save";
				}*/
				overBF.setGraphicSize(Std.int(overBF.width * 0.775));
				overBF.frames = Paths.getSparrowAtlas('rpg/boyfriendrpg');
				overBF.animation.addByPrefix('down', "boyfriend_down", 6);
				overBF.animation.addByPrefix('up', "boyfriend_up", 6);
				overBF.animation.addByPrefix('right', "boyfriend_right", 6);
				overBF.animation.addByPrefix('left', "boyfriend_left", 6);
				overBF.animation.addByPrefix('downE', "boyfriend_down0000", 6);
				overBF.animation.addByPrefix('upE', "boyfriend_up0000", 6);
				overBF.animation.addByPrefix('rightE', "boyfriend_right0000", 6);
				overBF.animation.addByPrefix('leftE', "boyfriend_left0000", 6);
				overBF.animation.play('upE');

				add(bg);
				add(overBF);

				var hitBox1:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('hitbox'));
				hitBox1.width = 300;
				hitBox1.height = 200;
				hitBox1.setGraphicSize(Std.int(hitBox1.width));
				hitBox1.x = bg.x + (bg.width/2) - 350;
				hitBox1.y = bg.width - 1050;
				hitBox1.visible = false;
				add(hitBox1);
				obbyList.push(hitBox1);

				var money:Alphabet = new Alphabet(0, 0, "VOID0000", true);
				money.x = (1110/2) - 150;
				money.y = 1110 - 575;
				money.visible = false;
				add(money);
				textList.push(money);
				
				var interact:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('rpg/hitbox'));
				interact.width = 400;
				interact.height = 400;
				interact.setGraphicSize(Std.int(interact.width));
				interact.x = bg.x + (bg.width/2) - 400;
				interact.y = bg.width - 1075;
				interact.visible = false;
				add(interact);
				interactList.push(interact);

				var hitBox2:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('rpg/hitbox'));
				hitBox2.width = 3300;
				hitBox2.height = 300;
				hitBox2.setGraphicSize(Std.int(hitBox1.height));
				hitBox2.x = bg.x + (bg.width/2) - 850;
				hitBox2.y = bg.width - 1900;
				hitBox2.visible = false;
				add(hitBox2);
				obbyList.push(hitBox2);


				exit1 = new FlxSprite(-80).loadGraphic(Paths.image('rpg/7i3box'));
				exit1.width = 400;
				exit1.height = 400;
				exit1.setGraphicSize(Std.int(exit1.width));
				exit1.x = hitBox2.x;
				exit1.y = hitBox2.y + 50;
				exit1.visible = false;
				add(exit1);
				obbyList.push(exit1);
		}
		
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		collisionList.push(bg);
		var scoreText:FlxText = new FlxText(10, 10, 0, progression, 36);
		scoreText.setFormat("VCR OSD Mono", 32);



		camGame.minScrollX = bg.x;
		camGame.minScrollY = bg.y;
		camGame.maxScrollX = bg.x + bg.width;
		camGame.maxScrollY = bg.y + bg.height;


		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		//magenta.scrollFactor.set(.99, .99);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.data.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		// magenta.scrollFactor.set();




		// NG.core.calls.event.logEvent('swag').send();

		super.create();
		if (ClientPrefs.data.progression >= 1)
		{
			allowInputs = false;
			allowRetry = false;
		}
		selectSpr = new FlxSprite(840, 390).makeGraphic(160, 90, FlxColor.WHITE);
		selectSpr.alpha = 0.5;
		yesText = new FlxText(850, 400, 0, 'YES', 48);
		yesText.font = 'Pixel Arial 11 Bold';
		yesText.color = FlxColor.WHITE;

		noText = new FlxText(1075, 400, 0, 'NO', 48);
		noText.font = 'Pixel Arial 11 Bold';
		noText.color = FlxColor.WHITE;

		yesText.cameras = [camMESSAGE];
		noText.cameras = [camMESSAGE];
		selectSpr.cameras = [camMESSAGE];
	}
	function nextArea(name:FlxSprite)
	{
		
	}
	function addInteractText()
	{
		for (i in 0...textList.length)
			textList[i].visible = true;
	}

	function removeInteractText()
	{
		for (i in 0...textList.length)
			textList[i].visible = false;
	}
	function checkInteractables(xCoord:Float,yCoord:Float)
	{
		var minX:Float;
		var minY:Float;
		var maxX:Float;
		var maxY:Float;
		var checkDetect:Bool = true;

			for (i in 0...interactList.length) 
		{
			
			minX = interactList[i].x + 150;
			minY = interactList[i].y + 50;
			maxX = interactList[i].x  + interactList[i].width +150;
			maxY = interactList[i].y + interactList[i].height +150;

			if (overBF.y + yCoord < minY || overBF.y + yCoord > maxY || overBF.x + xCoord < minX || overBF.x + xCoord > maxX)
			{
				if(checkDetect)
				{
					//jack shit
				}
			}
			else
			{
				if (checkDetect)
				{
					checkDetect = false;
				}
			}
			if (checkDetect)
			{
				if (ClientPrefs.data.progression >= 1)
				{
					removeInteractText();
					trace("Ended interaction.");
				}
				else
					addInteractText();
				isInteracting = false;
			}
			else
			{
				addInteractText();
				trace("Started interaction.");
				isInteracting = true;
			}

		}
	}
	function checkCollision(xCoord:Float,yCoord:Float)
	{
		var minX:Float;
		var minY:Float;
		var maxX:Float;
		var maxY:Float;
		for (i in 0...obbyList.length) 
		{
			minX = obbyList[i].x + 150;
			minY = obbyList[i].y + 50;
			maxX = obbyList[i].x  + obbyList[i].width +150;
			maxY = obbyList[i].y + obbyList[i].height +150;

			if (overBF.y + yCoord < minY || overBF.y + yCoord > maxY || overBF.x + xCoord < minX || overBF.x + xCoord > maxX)
			{
				//nothing
			}
			else
			{
				if (obbyList[i] == exit1 || obbyList[i] == exit2)
				{
					nextArea(obbyList[i]);
				}
				return false;
			}
		}



		for (i in 0...collisionList.length) 
		{
			var minX:Float = collisionList[i].x - 50;
			var minY:Float = collisionList[i].y -50;
			var maxX:Float = collisionList[i].x + collisionList[i].width - 250;
			var maxY:Float = collisionList[i].y + collisionList[i].height -250;

			if (overBF.y + yCoord < minY || overBF.y + yCoord > maxY || overBF.x + xCoord < minX || overBF.x + xCoord > maxX)
			{
				return false;
			}
		}
		return true;
	}
	function checkHeld()
	{
		if (downHeld)
		{
			overBF.animation.play('down');
			return true;
		}
		else if (upHeld)
		{
			overBF.animation.play('up');
			return true;
		}
		else if (rightHeld)
		{
			overBF.animation.play('right');
			return true;
		}
		else if (leftHeld)
		{
			overBF.animation.play('left');
			return true;
		}
		else
		{
			return false;
		}
	}

	var selectedSomethin:Bool = false;
	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		#if debug
		if (FlxG.keys.justPressed.R)
		{
			ClientPrefs.data.progression = 0;
		}
		#end

		ch = FlxG.random.int(1,5) / 1000;
		ch = FlxG.random.int(1,5) / 1000;
		shaders.ShadersHandler.setChrome(ch);
		var file:String = Paths.json('secret/secretdialogue2'); // Checks for json/Psych Engine dialogue
		var file2:String = Paths.json('secret/secretdialogue2alt');
		if (OpenFlAssets.exists(file) && ClientPrefs.data.progression == 1)
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}
		if (OpenFlAssets.exists(file2) && ClientPrefs.data.progression == 2)
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file2);
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);
		FlxG.camera.follow(overBF,FlxCameraFollowStyle.LOCKON);
		if (!selectedSomethin)
		{
			if (controls.UI_UP)
			{
				if (checkCollision(0,-10))
				{
					overBF.y -= 10 * (60/ClientPrefs.data.framerate);
				}
				checkInteractables(0,0);
			}

			if (controls.UI_DOWN)
			{
				if (checkCollision(0,10))
				{
					overBF.y += 10 * (60/ClientPrefs.data.framerate);
				}
				checkInteractables(0,0);
			}

			if (controls.UI_LEFT)
			{
				if (checkCollision(-10,0))
				{
					overBF.x -= 10 * (60/ClientPrefs.data.framerate);
				}
				checkInteractables(0,0);
			}

			if (controls.UI_RIGHT)
			{
				if (checkCollision(10,0))
				{
					overBF.x += 10 * (60/ClientPrefs.data.framerate);
				}
				checkInteractables(0,0);

			}

			if (controls.UI_UP_P)
			{
				upHeld = true;
				overBF.animation.play('up');
			}

			if (controls.UI_DOWN_P)
			{
				downHeld = true;
				overBF.animation.play('down');
			}

			if (controls.UI_LEFT_P)
			{
				leftHeld = true;
				overBF.animation.play('left');
			}

			if (controls.UI_RIGHT_P)
			{
				rightHeld = true;
				overBF.animation.play('right');
			}
			if (controls.UI_UP_R)
			{
				upHeld = false;
				if (!checkHeld())
				{
				overBF.animation.play('upE');
				}
			}

			if (controls.UI_DOWN_R)
			{
				downHeld = false;
				if (!checkHeld())
				{
				overBF.animation.play('downE');
				}
			}

			if (controls.UI_LEFT_R)
			{
				leftHeld = false;
				if (!checkHeld())
				{
				overBF.animation.play('leftE');
				}
			}

			if (controls.UI_RIGHT_R)
			{
				rightHeld = false;
				if (!checkHeld())
				{
				overBF.animation.play('rightE');
				}
			}
			if (controls.ACCEPT)
			{
				if(area == "Save" && isInteracting)
				{
					startDialogue(dialogueJson);
				}
			}
		}

		super.update(elapsed);

		if (allowInputs && controls.ACCEPT)
		{
			if (allowRetry)
			{
				PlayState.isStoryMode = true;
				/*
				if (Main.godmode)
					PlayState.SONG = Song.loadFromJson("null-god", "null");
				else
					PlayState.SONG = Song.loadFromJson("null-true", "null");
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = 4;*/
				psychDialogue = null;
			}
			else
			{
				allowInputs = false;
				remove(selectSpr);
				remove(yesText);
				remove(noText);
				Application.current.window.alert("All In Good Time...", 'Dont Worry.');
				psychDialogue = null;
				answer = null;
			}
		}

		if (allowInputs && controls.BACK)
		{
			psychDialogue = null;
			answer = null;
		}

		if (!allowRetry && controls.UI_LEFT_P && selectSpr.x == 1040)
		{
			selectSpr.x = 840;
		}
		else if (!allowRetry && controls.UI_RIGHT_P && selectSpr.x == 840)
		{
			selectSpr.x = 1040;
		}

		if (ClientPrefs.data.progression >= 1 && dialogueJson.dialogue[5].text == 'Questions Or A Rematch?')
		{
			add(selectSpr);
			add(yesText);
			add(noText);
			allowInputs = true;
			allowRetry = true;
		}
		else
		{
			allowInputs = true;
			allowRetry = true;
		}
	}

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
				if (answer == null)
				{
					/*PlayState.isStoryMode = true;
					if (Main.godmode)
						PlayState.SONG = Song.loadFromJson("null-god", "null");
					else
						PlayState.SONG = Song.loadFromJson("null-true", "null");
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = 4;
					openSubState(new LoadingsState());
					FlxTransitionableState.skipNextTransIn = true;
					var toSwitchToState = new PlayState();
					LoadingState.loadAndSwitchState(toSwitchToState, true,true);*/
					MusicBeatState.switchState(new CategoryState());
					psychDialogue = null;
				}
				else 
				{
					psychDialogue = null;
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camMESSAGE];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			/*PlayState.isStoryMode = true;
			if (Main.godmode)
				PlayState.SONG = Song.loadFromJson("null-god", "null");
			else
				PlayState.SONG = Song.loadFromJson("null-true", "null");
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 4;
			TrialsLoader.nextState = new PlayState();
			MusicBeatState.switchState(new TrialsLoader());*/
			psychDialogue = null;
			MusicBeatState.switchState(new CategoryState());
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