package states;

import backend.WeekData;
import backend.Highscore;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;
import flixel.math.FlxRandom;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;
import objects.Alphabet.ColoredAlphabet;

import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;

import haxe.Http;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

import backend.gamejolt.GameJolt.GameJoltAPI;
import tentools.api.FlxGameJolt as GJApi;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}
class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	public static var globalBPM:Float;
	private static var GJBug:Bool = false;

	var blackScreen:FlxSprite;
	var gradientBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 1, 0xFF6800BD);
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;
	
	var titleTextColors:Array<FlxColor> = [0xFF9900FF, 0xA46700A3];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	var curCrazy:Array<String> = [];

	var wackyImage:FlxSprite;

	var mustUpdate:Bool = false;

	var titleJSON:TitleData;

	#if sys
	var thrd:Thread;
	#end

	public static var updateVersion:String = '';
	public static var cueSong:Bool;

	override public function create():Void
	{
		//var checkSickBeatsEvent = new EventFunc("CheckSickBeats", EqualTo(true), (sickBeats == 2).createVariable(), function() { Sys.println('A'); }, true);
		//var checkSickBeatsEvent2 = new EventFunc("CheckSickBeats2", EqualTo(4), sickBeats.createVariable(), function() { Sys.println('B'); }, true);
		//var checkSickBeatsEvent3 = new EventFunc("CheckSickBeats3", Change, curWacky[0].createVariable(), function() { Sys.println('C'); }, false);
		curWacky = FlxG.random.getObject(getIntroTextShit());
		curCrazy = FlxG.random.getObject(getMoreIntroTextShit()); 

		// DEBUG BULLSHIT
		swagShader = new ColorSwap();
		
		super.create();

		//ClientPrefs.toggleVolumeKeys(true);

		Highscore.load();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if (cueSong) MusicBeatState.playSong(['beat-battle'], false, 1, 'TransitionState', 'stickers');
		else if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			if (initialized)
				startIntro();
			else
			{
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					startIntro();
				});
			}
		}
		#end
		if (Main.cmdArgs.indexOf("GameJoltBug") != -1 && !GJBug)
		{
			GJBug = true;
			FlxG.sound.playMusic(Paths.music('panixPress'), 0);
			
		
			FlxG.switchState(new options.OptionsState());
		}
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
	function startIntro()
	{
		if (!initialized)
		{
			/*var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;*/

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();

			if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
				FlxG.sound.playMusic(Paths.music('panixPress'), 0);
			}

			GameJoltAPI.connect();
			GameJoltAPI.authDaUser(FlxG.save.data.gjUser, FlxG.save.data.gjToken);
		}

		Conductor.bpm = titleJSON.bpm;
		globalBPM = titleJSON.bpm;
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		// bg.antialiasing = ClientPrefs.globalAntialiasing;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');

		logoBl.antialiasing = ClientPrefs.data.globalAntialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		swagShader = new ColorSwap();
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);

		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		if(easterEgg == null) easterEgg = ''; //html5 fix

		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		
		gfDance.antialiasing = ClientPrefs.data.globalAntialiasing;

		add(gfDance);
		gfDance.shader = swagShader.shader;
		add(logoBl);
		logoBl.shader = swagShader.shader;

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.data.globalAntialiasing;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.globalAntialiasing;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.elasticInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		Paths.clearUnusedMemory();
		// credGroup.add(credTextShit);
	}

	
	public static function transitionRandom():Void {
		// List of all transition types.
		var transitionTypes:Array<String> = ["fadeOut", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown", "slideRandom", "fallRandom", "fallSequential", "stickers"];
		
		// Randomly select a transition type using FlxG.random for better seed management
		var randomTransitionType:String = transitionTypes[FlxG.random.int(0, transitionTypes.length - 1)];
		
		// Randomly select a color for fadeColor transition, if chosen, using FlxG.random
		var randomColor:Int = randomTransitionType == "fadeColor" ? FlxG.random.color() : FlxColor.BLACK;
		
		// Define options with random values
		var options:Dynamic = {
			transitionType: randomTransitionType,
			duration: FlxG.random.float(0.5, 2), // Random duration between 0.5 and 2 seconds
			color: randomColor, // Only used if fadeColor is selected
			createInstance: true,
			// For fallRandom and fallSequential, decide randomly if objects should fall in random directions
			randomDirection: FlxG.random.bool()
		};
		
		// Call transitionState with MainMenuState as the target state and random options
		trace("Transitioning to MainMenuState with random transition: " + options);
		TransitionState.transitionState(MainMenuState, options, null, true);
		trace("Transition complete");
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	function getMoreIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/thefunnie.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('thefunnie'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
			var skipUpdate = FlxG.keys.pressed.SHIFT;
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;
				// FlxG.sound.music.stop();

				var tmr = new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					transitionRandom();
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function createCoolColoredText(textArray:Array<String>, ?offset:Float = 0, ?color:FlxColor = FlxColor.WHITE)
	{
		for (i in 0...textArray.length)
		{
			var money:ColoredAlphabet = new ColoredAlphabet(0, 0, textArray[i], true, color);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function addMoreColoredText(text:String, ?offset:Float = 0, ?color:FlxColor = FlxColor.WHITE)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:ColoredAlphabet = new ColoredAlphabet(0, 0, text, true, color);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					if (!playJingle) {
						try {
							FlxG.sound.playMusic(Paths.music('panixPress'), 0);
							FlxG.sound.music.time = 0;
							FlxG.sound.music.fadeIn(4, 0, 0.7);
							playJingle = true;
						} catch (e:Dynamic) {
							trace("Error playing music: " + e);
							try {
								FlxG.sound.playMusic(Paths.music('panixPress'), 0);
								FlxG.sound.music.time = 0;
								FlxG.sound.music.fadeIn(4, 0, 0.7);
								playJingle = true;
							} catch (e2:Dynamic) {
								trace("Error playing music on retry: " + e2);
								playJingle = true;
							}
						}
					}
				case 2:
					#if PSYCH_WATERMARKS
					createCoolText(['Psych Engine by'], 15);
					#else
					createCoolText(['Mixtape Engine by'], 15);
					#end
				// credTextShit.visible = true;
				case 4:
					#if PSYCH_WATERMARKS
					addMoreText('Shadow Mario', 15);
					addMoreText('RiverOaken', 15);
					addMoreText('shubs', 15);
					#else
					addMoreText('Z11Gaming', 15);
					#end
				// credTextShit.text += '\npresent...';
				// credTextShit.addText();
				case 5:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = 'In association \nwith';
				// credTextShit.screenCenter();
				case 6:
					#if PSYCH_WATERMARKS
					createCoolText(['Not associated', 'with'], -40);
					#else
					createCoolText(["That\'s", 'right'], -40);
					#end
				case 8:
					addMoreText('This Mofo', -40);
					ngSpr.visible = true;
				// credTextShit.text += '\nNewgrounds';
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				// credTextShit.visible = false;

				// credTextShit.text = 'Shoutouts Tom Fulp';
				// credTextShit.screenCenter();
				case 10:
					createCoolText(['Alright']);
				// credTextShit.visible = true;
				case 12:
					addMoreText('Time For');
				// credTextShit.text += '\nlmao';
				case 13:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = "Friday";
				// credTextShit.screenCenter();
				case 14:
					addMoreText('Random');
				// credTextShit.visible = true;
				case 15:
					addMoreText('Text');
				// credTextShit.text += '\nNight';
				case 16:
					addMoreText('Quotes');

				case 17:
					deleteCoolText();

				case 18:
					createCoolText([curWacky[0]]);
				// credTextShit.visible = true;
				case 20:
					addMoreText(curWacky[1]);
				// credTextShit.text += '\nlmao';
				case 21:
					deleteCoolText();

				case 22:
					curWacky = FlxG.random.getObject(getIntroTextShit());
					createCoolText([curWacky[0]]);
				// credTextShit.visible = true;
				case 24:
					addMoreText(curWacky[1]);
				// credTextShit.text += '\nlmao';
				case 25:
					deleteCoolText();

				case 26:
					curCrazy = FlxG.random.getObject(getMoreIntroTextShit());
					addMoreText(curCrazy[0]);
				// credTextShit.visible = true;
				case 27:
					addMoreText(curCrazy[1]);
				// credTextShit.text += '\nNight';
				case 28:
					addMoreText(curCrazy[2]);

				case 29:
					deleteCoolText();

				case 30:
					addMoreColoredText('Z11\'s', 0, 0xFF7B1788);
				// credTextShit.visible = true;
				case 31:
					addMoreColoredText('Modpack', 0, 0xFFFFFFFF);
				// credTextShit.text += '\nNight';
				case 32:
					addMoreColoredText('Mixup', 0, 0xFF353535);

				case 33:
					deleteCoolText();
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);
			remove(credGroup);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}