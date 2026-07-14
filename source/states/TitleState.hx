package states;

import backend.Song;
import backend.WeekData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import haxe.Json;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import shaders.ColorSwap;
import states.MainMenuState;
import states.PlaylistState.PlaylistMetadata;
import states.StoryMenuState;
import undertale.UnderTextParser;

typedef TitleData =
{
	var titlex:Float;
	var titley:Float;
	var startx:Float;
	var starty:Float;
	var gfChar:Null<Bool>;
	var gfx:Float;
	var gfy:Float;
	var backgroundSprite:String;
	var bpm:Float;

	@:optional var gfSprite:String;
	@:optional var gfAnimArray:Array<String>;
	@:optional var gfAnimIndices:Array<Array<Int>>;
	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Bool;
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	public static var globalBPM:Float;
	private static var GJBug:Bool = false;
	private static var APBug:Bool = false;

	public var ticker:yutautil.StateTick = new yutautil.StateTick(function() {
		// trace('[DEBUG] Tick in state: ${Type.getClassName(Type.getClass(FlxG.state))}');
	}, 30);


	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var blackScreen:FlxSprite;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = [
		'GASTER'
	];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var candance:Bool = true;
	override public function create():Void
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chilling on the Title Screen", null);
		#end

		trace(new test.TestYScript(0, 0).getStatus()); // Just to make sure YScript is compiled properly

		MusicBeatState.allowNuke = true; // COMMENCE THE MEMORY CLEARAGE
		// ticker.update(0);
		trace(ticker.metadata());
		Paths.clearStoredWithoutStickers();
		super.create();
		trace(this.metadata());
		for (classthing in this.metadata().super_tree.toIterable())
			try {
				trace("Ultimate Super Tree for " + classthing + ": " + Type.createEmptyInstance(Type.resolveClass(classthing)).metadata().super_tree);
			} catch (e:haxe.Exception) {
				trace("Error retrieving super tree for " + classthing + ": " + e.message);
				trace("Details: " + e.details());
				trace("Stack: " + e.stack);
				trace("Type: " + Type.getClassName(Type.resolveClass(classthing)));
			}

		curWacky = FlxG.random.getObject(getIntroTextShit());

		trace(cpp.vm.Gc.trace(FlxSprite));

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
		ClientPrefs.openChartEditor();
		#else
		// Check for first-time setup after title initialization but before flashing state
		if(!initialized && !ClientPrefs.data.setupCompleted && !ClientPrefs.data.setupSkipped)
		{
			// First time running - redirect to setup guide
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new setup.SetupGuideState());
		}
		else if(!ClientPrefs.data.warmupCompleted && (!ClientPrefs.data.warmupStyle == "Never" || ClientPrefs.data.warmupStyle == "Always"))
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			persistentUpdate = false;
			var warmupPlaylists:Array<PlaylistMetadata> = [];
			var allLists:Array<PlaylistMetadata> = PlaylistState.loadPlaylists();
			if (allLists.length > 0) {
				for (playlistItem in allLists) {
					try {
					if (playlistItem?.isWarmup) {
						warmupPlaylists.push(playlistItem);
					}
				}	catch (e:haxe.Exception) {
					if (!playlistItem.isWarmup.isReal(true)) playlistItem.isWarmup = false; // Fix old playlists.
				}
				}
			}

			var hasWarmup:Bool = warmupPlaylists.length > 0;
			var playlist:PlaylistMetadata = hasWarmup ? warmupPlaylists[FlxG.random.int(0, warmupPlaylists.length - 1)] : null;

		// Rare chance to offer a challenge (10% chance, INDEPENDENT of warmup existence)
		var offerChallenge:Bool = FlxG.random.float() < 0.1;

		if (offerChallenge) {
			closedState = true;
			transitioning = true;
			var challenge = new haxe.ui.containers.dialogs.MessageBox();
			challenge.title = "Challenge Time!";
			challenge.text = "We have a challenge for you. Wanna try it?";
			challenge.buttons = haxe.ui.containers.dialogs.Dialog.DialogButton.YES | haxe.ui.containers.dialogs.Dialog.DialogButton.NO;

			challenge.onDialogClosed = function(event:haxe.ui.containers.dialogs.Dialog.DialogEvent)
			{
				if (event.button == haxe.ui.containers.dialogs.Dialog.DialogButton.YES)
				{
					closedState = false;
					transitioning = false;
					MusicManager.playMenuMusic(1);

					// Generate random song count between 3 and 15 and run challenge
					var randomSongCount:Int = FlxG.random.int(3, 15);
					FlxG.switchState(new ChallengeRunnerState(randomSongCount));
				}
				else
				{
					closedState = false;
					transitioning = false;
					// Challenge declined, proceed with normal warmup flow
					proceedWithWarmupCheck(hasWarmup, playlist, allLists, warmupPlaylists);
				}
			};

			challenge.show();
			Cursor.show();
		} else {
			// Challenge not offered, proceed directly with warmup check
			proceedWithWarmupCheck(hasWarmup, playlist, allLists, warmupPlaylists);
		}
		} else if(FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
			startIntro();
		#end

		if (Main.cmdArgs.indexOf("GameJoltBug") != -1 && !GJBug)
		{
			GJBug = true;
			MusicManager.playMenuMusic(1);
			FlxG.switchState(new options.OptionsState());
		}

		#if ARCHIPELAGO_ALLOWED
		if (Main.cmdArgs.indexOf("APDisconnectError") != -1 && !APBug)
		{
			APBug = true;
			FlxG.switchState(new archipelago.APEntryState());
		}
		#end

		if (initialized && (FlxG.sound.music == null || !FlxG.sound.music.playing))
			MusicManager.playMenuMusic(0.5);

		if (!candance)
			candance = true;
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;
	var usingDefaultLogo:Bool = false;

	private function proceedWithWarmupCheck(hasWarmup:Bool, playlist:PlaylistMetadata, allLists:Array<PlaylistMetadata>, warmupPlaylists:Array<PlaylistMetadata>):Void
	{
		if (hasWarmup && playlist != null) {
			if (ClientPrefs.data.warmupStyle == "Always") {
				persistentUpdate = true;
				PlayState.isWarmUp = true;
				PlayState.altInstrumentals = null; // ? P-Slice
				Mods.loadTopMod();
				WeekData.reloadWeekFiles();
				// Pick a random warmup playlist
				var selectedPlaylist = warmupPlaylists[FlxG.random.int(0, warmupPlaylists.length - 1)];
				if (allLists.length > 0) {
					closedState = false;
					transitioning = false;
					MusicManager.playMenuMusic(0);
					// Pass playlist directly to PlayState constructor instead of static assignment
					var songLowercase:String = Paths.formatToSongPath(selectedPlaylist.songList[0].songName);
					Mods.currentModDirectory = selectedPlaylist.songList[0].folder != null ? selectedPlaylist.songList[0].folder : '';
					PlayState.storyWeek = selectedPlaylist.songList[0].week;
					Song.loadFromJson('${songLowercase}-${selectedPlaylist.songList[0].difficulty.toLowerCase()}', songLowercase);
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState(selectedPlaylist));
				} else {
					trace('[WARN] No playlists found, defaulting to tutorial!');
					closedState = false;
					transitioning = false;
					var songLowercase:String = Paths.formatToSongPath(selectedPlaylist.songList[0].songName);
					Song.loadFromJson('${songLowercase}-${selectedPlaylist.songList[0].difficulty.toLowerCase()}', songLowercase);
					Mods.currentModDirectory = selectedPlaylist.songList[0].folder != null ? selectedPlaylist.songList[0].folder : '';
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			} else if (ClientPrefs.data.warmupStyle == "Ask") {
				closedState = true;
				transitioning = true;
				var warmup = new haxe.ui.containers.dialogs.MessageBox();
				warmup.title = "Warm-up?";
				warmup.text = "Would you like to play the warm-up playlist before starting?";
				warmup.buttons = haxe.ui.containers.dialogs.Dialog.DialogButton.YES | haxe.ui.containers.dialogs.Dialog.DialogButton.NO;

				warmup.onDialogClosed = function(event:haxe.ui.containers.dialogs.Dialog.DialogEvent)
				{
					if (event.button == haxe.ui.containers.dialogs.Dialog.DialogButton.YES)
					{
						closedState = false;
						transitioning = false;
						persistentUpdate = true;
						PlayState.isWarmUp = true;
						PlayState.altInstrumentals = null; // ? P-Slice
						Mods.loadTopMod();
						WeekData.reloadWeekFiles();
						MusicManager.playMenuMusic(0);
						// Pick a random warmup playlist
						var selectedPlaylist = warmupPlaylists[FlxG.random.int(0, warmupPlaylists.length - 1)];
						// Pass playlist directly to PlayState constructor instead of static assignment
						trace('songName: ${selectedPlaylist.songList[0]}');
						var songLowercase:String = Paths.formatToSongPath(selectedPlaylist.songList[0].songName);
						Mods.currentModDirectory = selectedPlaylist.songList[0].folder != null ? selectedPlaylist.songList[0].folder : '';
						PlayState.storyWeek = selectedPlaylist.songList[0].week;
						Song.loadFromJson('${songLowercase}-${selectedPlaylist.songList[0].difficulty.toLowerCase()}', songLowercase);
						LoadingState.prepareToSong();
						LoadingState.loadAndSwitchState(new PlayState(selectedPlaylist));
					}
					else
					{
						closedState = false;
						transitioning = false;
						ClientPrefs.data.warmupCompleted = true;
						ClientPrefs.saveSettings();
						FlxG.resetState();
						Cursor.hide();
						sickBeats = 0;
					}
				};

				warmup.show();
				Cursor.show();
			}
		} else if (ClientPrefs.data.warmupStyle == "Ask") {
			closedState = true;
			transitioning = true;
			trace('[WARN] No warmup playlist found!');
			var warmup = new haxe.ui.containers.dialogs.MessageBox();
			warmup.title = "Warm-up?";
			warmup.text = "It looks like you don't have a warmup playlist!\n\nWould you like to create one?";
			warmup.buttons = haxe.ui.containers.dialogs.Dialog.DialogButton.YES | haxe.ui.containers.dialogs.Dialog.DialogButton.NO;

			warmup.onDialogClosed = function(event:haxe.ui.containers.dialogs.Dialog.DialogEvent)
			{
				if (event.button == haxe.ui.containers.dialogs.Dialog.DialogButton.YES)
				{
					closedState = false;
					transitioning = false;
					MusicManager.playMenuMusic(1);
					FlxG.switchState(new states.PlaylistState());
				}
				else
				{
					closedState = false;
					transitioning = false;
					ClientPrefs.data.warmupCompleted = true;
					ClientPrefs.saveSettings();
					FlxG.resetState();
					Cursor.hide();
					sickBeats = 0;
				}
			};

			warmup.show();
			Cursor.show();
		} else if (ClientPrefs.data.warmupStyle == "Never") {
			closedState = false;
			transitioning = false;
			ClientPrefs.data.warmupCompleted = true;
			ClientPrefs.saveSettings();
			FlxG.resetState();
			Cursor.hide();
			sickBeats = 0;
		}
	}

	function startIntro()
	{
		persistentUpdate = true;
		if (!initialized && FlxG.sound.music == null)
			MusicManager.setMenuMusic(ClientPrefs.data.menuSong, null, 0, true);

		loadJsonData();
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end

		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		try {
			logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		} catch (e:haxe.Exception) {
			trace('[ERROR] Failed to load logoBumpin atlas: ' + e.details());
			logoBl.frames = null;
		}
		if (logoBl.frames == null) {
			logoBl.frames = Paths.getSparrowAtlas('bump');
			usingDefaultLogo = true;
		}
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		if (usingDefaultLogo) logoBl.animation.addByPrefix('bump', 'bump', 24, false);
		else logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		if (usingDefaultLogo) logoBl.setGraphicSize(Std.int(logoBl.width * 0.4));
		logoBl.updateHitbox();

		gfDance = new FlxSprite(gfPosition.x, gfPosition.y);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;

		if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		//Custom GF Title sprite
		if (gfSprite != null && gfSprite.length > 0 && gfSprite != "none")
		{
			gfDance.frames = Paths.getSparrowAtlas(gfSprite);
			if (gfAnimArray != null && gfAnimArray.length > 0)
			{
				gfDance.animation.addByIndices('danceLeft', gfAnimArray[0], [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', gfAnimArray[1].length > 0 ? gfAnimArray[1] : gfAnimArray[0], [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				gfDance.animation.addByPrefix('Hey', gfAnimArray[2].length > 0 ? gfAnimArray[2] : 'GF Cheer', 24, false);
			}
		}
		else //Default gfs
		{
			if (gfChar != null && gfChar)
				gfDance.frames = Paths.getSparrowAtlas('characters/GF_assets');
			else if (gfChar != null && !gfChar)
				gfDance.frames = Paths.getSparrowAtlas(characterImage);
			if (gfChar) animationName = 'GF Dancing Beat';
			if(!useIdle)
			{
				gfDance.animation.addByIndices('danceLeft', animationName, danceLeftFrames, "", 24, false);
				gfDance.animation.addByIndices('danceRight', animationName, danceRightFrames, "", 24, false);
				gfDance.animation.play('danceRight');
			}
			else
			{
				gfDance.animation.addByPrefix('idle', animationName, 24, false);
				gfDance.animation.play('idle');
			}
			if (gfChar != null && gfChar) gfDance.animation.addByPrefix('Hey', 'GF Cheer', 24, false);
		}


		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if (newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();

		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		add(gfDance);
		add(logoBl); //FNF Logo
		add(titleText); //"Press Enter to Begin" text
		add(credGroup);
		add(ngSpr);

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	// JSON data
	var characterImage:String = 'gfDanceTitle';
	var animationName:String = 'gfDance';

	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	var gfChar:Null<Bool> = false;
	var gfSprite:String = 'none';
	var gfAnimArray:Array<String>;
	var gfAnimIndices:Array<Array<Int>>;

	var useIdle:Bool = false;
	var musicBPM:Float = 102;
	var danceLeftFrames:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var danceRightFrames:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

	function loadJsonData()
	{
		if(Paths.fileExists('images/gfDanceTitle.json', TEXT))
		{
			var titleRaw:String = Paths.getTextFromFile('images/gfDanceTitle.json');
			if(titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);
					gfPosition.set(titleJSON.gfx, titleJSON.gfy);
					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					if (titleJSON.gfChar != null) gfChar = titleJSON.gfChar;

					if (titleJSON.gfSprite != null && titleJSON.gfSprite.length > 0 && titleJSON.gfSprite != "none")
						gfSprite = titleJSON.gfSprite;
					if (titleJSON.gfAnimArray != null && titleJSON.gfAnimArray.length > 0)
						gfAnimArray = titleJSON.gfAnimArray;

					musicBPM = titleJSON.bpm;
					globalBPM = titleJSON.bpm;

					if(titleJSON.animation != null && titleJSON.animation.length > 0) animationName = titleJSON.animation;
					if(titleJSON.dance_left != null && titleJSON.dance_left.length > 0) danceLeftFrames = titleJSON.dance_left;
					if(titleJSON.dance_right != null && titleJSON.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
					useIdle = (titleJSON.idle == true);

					if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0)
					{
						var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));
						bg.antialiasing = ClientPrefs.data.antialiasing;
						add(bg);
					}
				}
				catch(e:haxe.Exception)
				{
					trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
				}
			}
			else trace('[WARN] No Title JSON detected, using default values.');
		}
		//else trace('[WARN] No Title JSON detected, using default values.');
	}

	function easterEggData()
	{
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		switch(easterEgg.toUpperCase())
		{
			case 'SHADOW':
				characterImage = 'ShadowBump';
				animationName = 'Shadow Title Bump';
				gfPosition.x += 210;
				gfPosition.y += 40;
				useIdle = true;
			case 'RIVEREN':
				characterImage = 'ZRiverBump';
				animationName = 'River Title Bump';
				gfPosition.x += 180;
				gfPosition.y += 40;
				useIdle = true;
			case 'BBPANZU':
				characterImage = 'BBBump';
				animationName = 'BB Title Bump';
				danceLeftFrames = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];
				danceRightFrames = [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
				gfPosition.x += 45;
				gfPosition.y += 100;
			case 'PESSY':
				characterImage = 'PessyBump';
				animationName = 'Pessy Title Bump';
				gfPosition.x += 165;
				gfPosition.y += 60;
				danceLeftFrames = [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
				danceRightFrames = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28];
		}
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

	function get3IntroTextShit():Array<Array<String>>
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

		var pressedEnter:Bool = (FlxG.keys.justPressed.ENTER || controls.ACCEPT) && !inGasterEgg;

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
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
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
				if (gfDance.animation.exists("Hey"))
					gfDance.animation.play('Hey');
				candance = false;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							//trace('YOOO! ' + word);
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('secret'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
							black.scale.set(FlxG.width, FlxG.height);
							black.updateHitbox();
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									switch (word) {
										case "GASTER":
											doGasterEgg();
										default:
											MusicBeatState.switchState(new TitleState());
									}
								}
							});
							FlxG.sound.music.fadeOut();
							if(FreeplayManager.vocals != null)
							{
								FreeplayManager.vocals.fadeOut();
							}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
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

		if (inGasterEgg) {
			if (box != null && boxB != null) {
				var toW:Float = targetW;
				var toH:Float = targetH;

				boxW = boxW + ((toW - boxW) / (10 / (elapsed * 60)));
				boxH = boxH + ((toH - boxH) / (10 / (elapsed * 60)));

				if (Math.ceil(boxW) == toW || Math.floor(boxW) == toW) boxW = toW;
				if (Math.ceil(boxH) == toH || Math.floor(boxH) == toH) boxH = toH;

				box.scale.x = boxW / 100;
				box.scale.y = boxH / 100;

				boxB.scale.x = (boxW + 16) / 100;
				boxB.scale.y = (boxH + 16) / 100;

				box.x = boxX;
				box.y = boxY;
				boxB.x = boxX;
				boxB.y = boxY;

				box.alpha = boxA;
				boxB.alpha = boxA;
			}

			if (curDial <= gasterSpeech.length && (FlxG.keys.justPressed.ENTER || controls.ACCEPT)) {
				typeFunc(gasterSpeech[curDial]);
				curDial++;
			} else if (curDial > gasterSpeech.length) {
				typeFunc(true);
				remove(daStatic);
				FlxG.sound.music.stop();
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					Achievements.unlock("the_man", false);
					Main.closeGame();
				});
			}
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
			if(credGroup != null && textGroup != null)
			{
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

		if(gfDance != null && candance)
		{
			danceLeft = !danceLeft;
			if(!useIdle)
			{
				if (danceLeft)
					gfDance.animation.play('danceRight');
				else
					gfDance.animation.play('danceLeft');
			}
			else if(curBeat % 2 == 0) gfDance.animation.play('idle', true);
		}

		if(!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					//FlxG.sound.music.stop();
					MusicManager.playMenuMusic(0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					if (FlxG.sound.music.volume == 0)
						FlxG.sound.music.fadeIn(4, 0, 0.7);
					createCoolText(['Mixtape Engine by'], 40);
				case 4:
					addMoreText('Z11Gaming', 40);
					addMoreText('Yutamon', 40);
				case 5:
					deleteCoolText();
				case 6:
					createCoolText(['Not associated', 'with'], -40);
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					curWacky = FlxG.random.getObject(get3IntroTextShit());
					addMoreText(curWacky[0]);
				case 15:
					addMoreText(curWacky[1]);
				case 16:
					addMoreText(curWacky[2]); // credTextShit.text += '\nFunkin';
				case 17:
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
			//Default! Edit this one!!
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
			}
			skippedIntro = true;
		}
	}

	var box:FlxSprite;
  var boxB:FlxSprite;
	var underText:UnderTextParser;
	var daStatic:FlxSprite;
	//Box Stuff
	public var targetW:Float = 810;
	public var targetH:Float = 200;
	public var boxX:Float = (1280 / 2) - 25;
	public var boxY:Float = (720 / 2) + 75;
	var boxW:Float = 0;
	var boxH:Float = 0;
	public var boxA:Float = 1;
	var curDial:Int = 0;

	var inGasterEgg:Bool = false;
	var camfilters:Array<BitmapFilter> = [];
	var alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
	var gasterSpeech:Array<String> = [
		"[set:0.1]THE DARKNESS GROWS COLD.",
		"IT'S NEVER-ENDING NIGHT THAT EXPANDS ACROSS AN ENDLESS OCEAN",
		"I CAN REACH PLACES I'VE NEVER KNOWN BEFORE",
		"AND I HAVE LOST THE ABILITY TO TELL WHERE I AM",
		"BUT, DISPITE THIS...",
		"THE REAL QUESTION IS",
		"WHAT ARE YOU DOING HERE?",
		"YOU SHOULDN'T BE HERE YOU KNOW",
		"THE DARKNESS DOESN'T CARE FOR PEOPLE LIKE YOU"
	];

	function doGasterEgg() {
		curDial = 0;
		FlxG.sound.playMusic(Paths.music("hello"), 1);
		daStatic = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('effects/static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.animation.addByPrefix('static','lestatic',24, true);
		daStatic.animation.play('static', true);
		add(daStatic);

		boxB = new FlxSprite().loadGraphic(Paths.image('ut/boxBorder'));
    box = new FlxSprite().loadGraphic(Paths.image('ut/box'));
		boxB.screenCenter();
    box.screenCenter();
		add(boxB);
    add(box);

		underText = new UnderTextParser(300, 400, Std.int(FlxG.width * 0.6), '', 32);
		underText.font = Paths.font("undertale-wingdings.ttf");
		underText.color = 0xFFFFFFFF;
		underText.prefix = '* ';
		add(underText);
		for (letter in alphabet) {
			underText.soundOnChars.set(letter, FlxG.sound.load(Paths.sound('ut/snd-wngdng${FlxG.random.int(1, 7)}'), 1));
			underText.soundOnChars.set(letter.toUpperCase(), FlxG.sound.load(Paths.sound('ut/snd-wngdng${FlxG.random.int(1, 7)}'), 1));
		}
    //underText.alpha = 0;
		inGasterEgg = true;
		FlxG.camera.setFilters(camfilters);
		FlxG.camera.filtersEnabled = true;
		camfilters.push(shaders.ShadersHandler.chromaticAberration);
	}

	var daSpeed:Float = 0.015;
	function typeFunc(?text:String = '', ?sound:String = 'uifont', ?speed:Float = 0.2, ?delayBetweenPause:Float = 1, hide:Bool = false)
	{
		var splitName:Array<String> = text.split("\n");
		var trueText:String = splitName[0];
		for (i in 0...splitName.length)
		{
			if (i > 0) trueText += '\n* ' + splitName[i];
		}

		if (hide)
		{
			underText.alpha = 0;
			underText.resetText('');
			box.visible = false;
			boxB.visible = false;
		}
		else
		{
			underText.alpha = 1;
			underText.resetText(trueText);
			underText.start(speed, true);
			box.visible = true;
			boxB.visible = true;
		}
	}
}

/**
 * Minimal state for running the challenge generator with a specific song count.
 * Used by TitleState to launch challenges with random difficulty (3-15 songs).
 */
class ChallengeRunnerState extends MusicBeatState {
	private var songCount:Int = 12;

	public function new(count:Int = 12) {
		super();
		songCount = count;
	}

	override function create() {
		super.create();

		// Create and start the challenge generator with auto-launch
		var generator = new managers.ChallengePlaylistGenerator(this, function(playlist:PlaylistState.PlaylistMetadata) {
			// Auto-launch the challenge playlist
			return true;
		}, function() {
			// On cancellation, go back to TitleState
			FlxG.switchState(new TitleState());
		});

		// Start generator with the specified song count
		generator.start(songCount);
	}
}
