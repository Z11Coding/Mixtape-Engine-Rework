package states;

import backend.AIPlayer;
import backend.Song;
import flash.media.Sound;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.Timer;
import lime.app.Future;
import lime.utils.Assets;
import objects.Character;
import objects.Note;
import objects.NoteSplash;
import objects.playfields.*;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import stages.StageData;
import states.MixtapeLoadingScreen;
import yutautil.UnoMechanic;
import yutautil.modules.ASync;

#if (target.threaded)
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;
import sys.thread.Thread;
#end

#if HSCRIPT_ALLOWED
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
import psychlua.HScript;
#end

#if cpp
@:headerCode('
#include <iostream>
#include <thread>
')
#end
@:privateAccess(states.MixtapeLoadingScreen)
class LoadingState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;

	static var originalBitmapKeys:Map<String, String> = [];
	static var requestedBitmaps:Map<String, BitmapData> = [];
	static var mutex:Mutex;
	static var threadPool:FixedThreadPool = null;

	static var currentSV:SpeedEvent = {position: 0, startTime: 0, speed: 1 #if EASED_SVs , startSpeed: 1 #end};
	static var speedChanges:Array<SpeedEvent> = [];

	public static var noteCache:Array<Note> = [];

	// Timeout system
	public static var returnState:FlxState = null;
	var loadingTimer:Float = 0;
	var timeoutWarning:FlxText;
	var canEscape:Bool = false;
	static final TIMEOUT_DURATION:Float = 5.0;

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;

		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var barGroup:FlxSpriteGroup;
	var bar:FlxSprite;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var curPercent:Float = 0;
	var stateChangeDelay:Float = 0;

	static var lastSong:String = '';
	static var lastMod:String = '';

	#if PSYCH_WATERMARKS
	var logo:FlxSprite;
	var pessy:FlxSprite;
	var loadingText:FlxText;

	var timePassed:Float;
	var shakeFl:Float;
	var shakeMult:Float = 0;

	var isSpinning:Bool = false;
	var spawnedPessy:Bool = false;
	var pressedTimes:Int = 0;
	#else
	var funkay:FlxSprite;
	#end

	#if HSCRIPT_ALLOWED
	var hscript:HScript;
	#end
	override function create()
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Loading into the song", null);
		#end

		persistentUpdate = true;
		barGroup = new FlxSpriteGroup();
		add(barGroup);

		var barBack:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
		barBack.scale.set(FlxG.width - 300, 25);
		barBack.updateHitbox();
		barBack.screenCenter(X);
		barGroup.add(barBack);

		bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, 15);
		bar.updateHitbox();
		barGroup.add(bar);
		barWidth = Std.int(barBack.width - 10);

		#if HSCRIPT_ALLOWED
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.trim().length > 0)
		{
			var scriptPath:String = 'mods/${Mods.currentModDirectory}/data/LoadingScreen.hx'; //mods/My-Mod/data/LoadingScreen.hx
			if(FileSystem.exists(scriptPath))
			{
				try
				{
					hscript = new HScript(null, scriptPath);
					hscript.set('getLoaded', function() return loaded);
					hscript.set('getLoadMax', function() return loadMax);
					hscript.set('barBack', barBack);
					hscript.set('bar', bar);

					if(hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						trace('initialized hscript interp successfully: $scriptPath');
						return super.create();
					}
					else
					{
						trace('"$scriptPath" contains no \"onCreate" function, stopping script.');
					}
				}
				catch(e:IrisError)
				{
					var pos:HScriptInfos = cast {fileName: scriptPath, showLine: false};
					Iris.error(Printer.errorToString(e, false), pos);
					var hscript:HScript = cast (Iris.instances.get(scriptPath), HScript);
				}
				if(hscript != null) hscript.destroy();
				hscript = null;
			}
		}
		#end

		#if PSYCH_WATERMARKS // PSYCH LOADING SCREEN
		var bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(FlxG.width));
		bg.color = 0xFFD16FFF;
		bg.updateHitbox();
		addBehindBar(bg);

		loadingText = new FlxText(520, 600, 400, Language.getPhrase('now_loading', 'Now Loading', ['...']), 32);
		loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		loadingText.borderSize = 2;
		addBehindBar(loadingText);

		logo = new FlxSprite(0, 0).loadGraphic(Paths.image('loading_screen/icon'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.scale.set(0.75, 0.75);
		logo.updateHitbox();
		logo.screenCenter();
		logo.x -= 50;
		logo.y -= 40;
		addBehindBar(logo);

		#else // BASE GAME LOADING SCREEN
		var bg = new FlxSprite().makeGraphic(1, 1, 0xFFCAFF4D);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
		addBehindBar(bg);

		funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
		funkay.antialiasing = ClientPrefs.data.antialiasing;
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		addBehindBar(funkay);
		#end

		// Timeout warning message
		timeoutWarning = new FlxText(0, FlxG.height - 100, FlxG.width, "", 24);
		timeoutWarning.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeoutWarning.borderSize = 2;
		timeoutWarning.visible = false;
		add(timeoutWarning);

		super.create();

		if (ClientPrefs.data.loadingState == 'Everything' || ClientPrefs.data.loadingState == 'Song Only') {
			if (stateChangeDelay <= 0 && checkLoaded())
			{
				dontUpdate = true;
				onLoad();
			}
		}
		else {
			loadNextDirectory();

			if (stopMusic && FlxG.sound.music != null)
				FlxG.sound.music.stop();

			MusicBeatState.switchState(target);
			transitioning = true;
			finishedLoading = true;
		}
	}

	function addBehindBar(obj:flixel.FlxBasic)
	{
		insert(members.indexOf(barGroup), obj);
	}

	var transitioning:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate || noAccess) return;

		if (!transitioning && !finishedLoading)
		{
			loadingTimer += elapsed;

			if (loadingTimer >= TIMEOUT_DURATION && !canEscape)
			{
				canEscape = true;
				timeoutWarning.text = Language.getPhrase('loading_timeout', 'Loading is taking too long...\nPress ESC to return', []);
				timeoutWarning.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (canEscape && FlxG.keys.justPressed.ESCAPE)
			{
				transitioning = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				if (threadPool != null)
				{
					threadPool.shutdown();
					threadPool = null;
				}

				var targetState:FlxState = (returnState != null) ? returnState : new PlayState();

				if (stopMusic && FlxG.sound.music != null)
					FlxG.sound.music.stop();

				FlxG.camera.fade(FlxColor.BLACK, 0.3, false, function() {
					MusicBeatState.switchState(targetState);
				});
				return;
			}
		}

		if (!transitioning)
		{
			if (!finishedLoading && checkLoaded())
			{
				if(stateChangeDelay <= 0)
				{
					transitioning = true;
					onLoad();
					return;
				}
				else stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
			}
			intendedPercent = loaded / loadMax;
		}

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001) curPercent = intendedPercent;
			else curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();

			if (curPercent > 90 && timePassed > 6000) {
				var yourtakingtoolong:FlxText = new FlxText(520, 400, 400, 'IF YOU\'RE READING THIS, IT\'S STUCK!\nPRESS F4 TO ESCAPE TO THE MAIN MENU!', 32);
				yourtakingtoolong.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
				yourtakingtoolong.borderSize = 2;
				addBehindBar(yourtakingtoolong);
			}
		}

		#if HSCRIPT_ALLOWED
		if(hscript != null)
		{
			if(hscript.exists('onUpdate')) hscript.call('onUpdate', [elapsed]);
			return;
		}
		#end

		#if PSYCH_WATERMARKS // PSYCH LOADING SCREEN
		timePassed += elapsed;
		shakeFl += elapsed * 3000;
		var dots:String = '';
		switch(Math.floor(timePassed % 1 * 3))
		{
			case 0:
				dots = '.';
			case 1:
				dots = '..';
			case 2:
				dots = '...';
		}
		loadingText.text = Language.getPhrase('now_loading', 'Now Loading{1}', [dots]);

		if(!spawnedPessy)
		{
			if(!transitioning && controls.ACCEPT)
			{
				shakeMult = 1;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				pressedTimes++;
			}
			shakeMult = Math.max(0, shakeMult - elapsed * 5);
			logo.offset.x = Math.sin(shakeFl * Math.PI / 180) * shakeMult * 100;

			if(pressedTimes >= 5)
			{
				FlxG.camera.fade(0xAAFFFFFF, 0.5, true);
				logo.visible = false;
				spawnedPessy = true;
				stateChangeDelay = 5;
				FlxG.sound.play(Paths.sound('secret'));

				pessy = new FlxSprite(700, 140);
				pessy.frames = Paths.getSparrowAtlas('loading_screen/pessy');
				pessy.animation.addByPrefix('run', 'run', 24, true);
				pessy.animation.addByPrefix('spin', 'spin', 24, true);
				pessy.antialiasing = ClientPrefs.data.antialiasing;
				pessy.flipX = (logo.offset.x > 0);
				pessy.visible = false;

				new FlxTimer().start(0.01, function(tmr:FlxTimer) {
					pessy.x = FlxG.width + 200;
					pessy.velocity.x = -1100;
					if(pessy.flipX)
					{
						pessy.x = -pessy.width - 200;
						pessy.velocity.x *= -1;
					}

					pessy.visible = true;
					pessy.animation.play('run', true);
					#if ACHIEVEMENTS_ALLOWED Achievements.unlock('pessy_easter_egg'); #end

					insert(members.indexOf(loadingText), pessy);
				});
			}
		}
		else if(!isSpinning && (pessy.flipX && pessy.x > FlxG.width) || (!pessy.flipX && pessy.x < -pessy.width))
		{
			isSpinning = true;
			pessy.animation.play('spin', true);
			pessy.flipX = false;
			pessy.x = 500;
			pessy.y = FlxG.height + 500;
			pessy.velocity.x = 0;
			FlxTween.tween(pessy, {y: 10}, 0.65, {ease: FlxEase.quadOut});
		}
		#end
	}

	#if HSCRIPT_ALLOWED
	override function destroy()
	{
		if(hscript != null)
		{
			if(hscript.exists('onDestroy')) hscript.call('onDestroy');
			hscript.destroy();
		}
		hscript = null;
		super.destroy();
	}
	#end

	var finishedLoading:Bool = false;
	function onLoad()
	{
		_loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.switchState(target);
		transitioning = true;
		finishedLoading = true;
	}

	static function _loaded()
	{
		loaded = 0;
		loadMax = 0;
		initialThreadCompleted = true;
		isIntrusive = false;
		chartLoaded = true;

		FlxTransitionableState.skipNextTransIn = true;
		if (threadPool != null) threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;
	}

	public static function checkLoaded():Bool
	{
		for (key => bitmap in requestedBitmaps)
		{
			if (bitmap != null && Paths.cacheBitmap(originalBitmapKeys.get(key), bitmap) != null) {} //trace('finished preloading image $key');
			else trace('failed to cache image $key');
		}
		requestedBitmaps.clear();
		originalBitmapKeys.clear();
		// trace('we checked if loaded');
		return (loaded >= loadMax && initialThreadCompleted);
	}

	public static function loadNextDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	static var isIntrusive:Bool = false;
	static var noAccess:Bool = false;
	static var preloadAsync:yutautil.modules.ASync.AResult<Bool> = null; // Store async preload result
	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		if (APEntryState.inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem("Stage Access Key")) {
			FlxG.state.openSubState(new Prompt("ERROR: Access key denied.", 0, function() FreeplayManager.openFreeplay(), function() FreeplayManager.openFreeplay(), false, "Return to Freeplay", "Return to Freeplay"));
			noAccess = true;
			loadMax++; //just to be sure it doesn't try to load anyway
		} else {
			noAccess = false;
		}

		// Check if preload setting is enabled and target is PlayState
		if (ClientPrefs.data.preloadSong && Std.isOfType(target, states.PlayState)) {
			trace("LoadingState: Preload enabled, starting async chart generation for PlayState");
			startPlayStatePreload(cast(target, states.PlayState));
		}

		#if !SHOW_LOADING_SCREEN
		intrusive = false;
		#end

		LoadingState.isIntrusive = intrusive;
		_startPool();
		loadNextDirectory();

		if(intrusive)
		{
			// Check the loading screen theme preference
			switch(ClientPrefs.data.loadingScreenTheme)
			{
				case 'Mixtape':
					return new MixtapeLoadingScreen(target, stopMusic);
				case 'Psych':
					return new LoadingState(target, stopMusic);
				default:
					return new LoadingState(target, stopMusic);
			}
		}

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		while(true)
		{
			if(checkLoaded())
			{
				_loaded();
				var _donePlayState:Bool = preloadAsync != null && preloadAsync.get();
				preloadAsync = null;
				break;
			}
			else Sys.sleep(0.001);
		}

		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];
	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null) imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null) soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null) musicToPrepare = musicToPrepare.concat(music);
	}

	static var initialThreadCompleted:Bool = true;
	static var chartLoaded:Bool = true;
	static var dontPreloadDefaultVoices:Bool = false;
	static function _startPool()
	{
		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		#else
		var threadCount:Int = 1;
		#end
		threadPool = new FixedThreadPool(threadCount);
	}

	public static function prepareToSong()
	{
		if(PlayState.SONG == null)
		{
			imagesToPrepare = [];
			soundsToPrepare = [];
			musicToPrepare = [];
			songsToPrepare = [];
			loaded = 0;
			loadMax = 0;
			initialThreadCompleted = true;
			chartLoaded = true;
			isIntrusive = false;
			return;
		}

		lastSong = PlayState.SONG.song;
		lastMod = Mods.currentModDirectory;

		if(PlayState.SONG != null) {
			trace('Preloading Chart');
			chartLoaded = false;
			//preloadChart();
		}

		_startPool();
		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];

		initialThreadCompleted = false;
		var threadsCompleted:Int = 0;
		var threadsMax:Int = 0;
		function completedThread()
		{
			threadsCompleted++;
			if(threadsCompleted == threadsMax)
			{
				clearInvalids();
				startThreads();
				initialThreadCompleted = true;
			}
		}

		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(Song.loadedSongName);
		new Future<Bool>(() -> {
			// LOAD NOTE IMAGE
			var noteSkin:String = Note.defaultNoteSkin;
			if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) noteSkin = PlayState.SONG.arrowSkin;

			var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
			if(Paths.fileExists('images/$customSkin.png', IMAGE)) noteSkin = customSkin;
			imagesToPrepare.push(noteSkin);
			//

			// LOAD NOTE SPLASH IMAGE
			var noteSplash:String = NoteSplash.defaultNoteSplash;
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) noteSplash = PlayState.SONG.splashSkin;
			else noteSplash += NoteSplash.getSplashSkinPostfix();
			imagesToPrepare.push(noteSplash);

			var eventsToLoad:Array<objects.Note.EventNote> = [];
			try
			{
				var eventsChart:SwagSong = Song.getChart('events', song.song);

				if (eventsChart != null) {
					var i = 0;
					for (event in eventsChart.events)
					{
						var subEvent:EventNote = {
							strumTime: event[0] + ClientPrefs.data.noteOffset,
							event: event[1][i][0],
							value1: event[1][i][1],
							value2: event[1][i][2]
						};
						if (subEvent.event == 'Change Character')
						{
							var char = objects.Character.grabCharInfo(subEvent.value2);

							imagesToPrepare.push(char['Health Icon']);
							imagesToPrepare.push(char['Image']);
						}
						i++;

					}
				}
		} catch(e:Dynamic) {
			trace('Failed to load events chart: $e');
		}

		try {
			// SONG EVENTS
			if (song.events != null)
			{
				for (event in song.events)
				{
					if (event[0] == 'Change Character')
					{
						var char = objects.Character.grabCharInfo(event[1][0]);
						if (char != null)
						{
							imagesToPrepare.push(char['Health Icon']);
							imagesToPrepare.push(char['Image']);
						}
					}
				}
			}
		} catch(e:Dynamic) {
			trace('Failed to load song events: $e');
		}


			try
			{
				var path:String = Paths.json('$folder/preload');
				var json:Dynamic = null;

				#if MODS_ALLOWED
				var moddyFile:String = Paths.modsJson('$folder/preload');
				if (FileSystem.exists(moddyFile)) json = Json.parse(File.getContent(moddyFile));
				else json = Json.parse(File.getContent(path));
				#else
				json = Json.parse(Assets.getText(path));
				#end

				if(json != null)
				{
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					for (asset in Reflect.fields(json))
					{
						var filters:Int = Reflect.field(json, asset);
						var asset:String = asset.trim();

						if(filters < 0 || StageData.validateVisibility(filters))
						{
							if(asset.startsWith('images/'))
								imgs.push(asset.substr('images/'.length));
							else if(asset.startsWith('sounds/'))
								snds.push(asset.substr('sounds/'.length));
							else if(asset.startsWith('music/'))
								mscs.push(asset.substr('music/'.length));
						}
					}
					prepare(imgs, snds, mscs);
				} else { // if it is null then just grab everything
					if (ClientPrefs.data.loadingState == 'Everything') {
						trace('NO PRELOAD JSON FOUND! LOADING EVERYTHING THAT CAN BE FOUND INSTEAD!');
						var curDirct:String = Mods.currentModDirectory == '' ? 'assets/${Paths.currentLevel}' : 'mods/${Mods.currentModDirectory}';
						var moddedImages:Array<String> = Paths.crawlDirectory('$curDirct/images', 'png');
						var moddedSounds:Array<String> = Paths.crawlDirectory('$curDirct/sounds', 'png');
						var moddedMusic:Array<String> = Paths.crawlDirectory('$curDirct/music', 'png');
						prepare(moddedImages, moddedSounds, moddedMusic);
						trace('IMAGE LOADING LIST: $moddedImages\nSOUND LOADING LIST: $moddedSounds\nMUSIC LOADING LIST: $moddedMusic');
					}
				}
			}
			catch(e:Dynamic) {
				if (ClientPrefs.data.loadingState == 'Everything') {
					trace('SOMETHING WENT WRONG! LOADING EVERYTHING THAT CAN BE FOUND INSTEAD!');
					//This annoys me to no end
					var curDirct:String = Mods.currentModDirectory == '' ? 'assets/${Paths.currentLevel}' : 'mods/${Mods.currentModDirectory}';
					var moddedImages:Array<String> = [];
					var moddedSounds:Array<String> = [];
					var moddedMusic:Array<String> = [];
					for (thing in Paths.crawlDirectory('$curDirct/images', 'png'))
						moddedImages.push(thing.replace('$curDirct/images/', '').replace('.png', ''));
					for (thing in Paths.crawlDirectory('$curDirct/sounds', 'ogg'))
						moddedSounds.push(thing.replace('$curDirct/sounds/', '').replace('.ogg', ''));
					for (thing in Paths.crawlDirectory('$curDirct/music', 'ogg'))
						moddedMusic.push(thing.replace('$curDirct/music/', '').replace('.ogg', ''));
					prepare(moddedImages, moddedSounds, moddedMusic);
					//trace('IMAGE LOADING LIST: $moddedImages\nSOUND LOADING LIST: $moddedSounds\nMUSIC LOADING LIST: $moddedMusic');
				}
			}
			return true;
		}, isIntrusive)
		.then((_) -> new Future<Bool>(() -> {
			if (song.stage == null || song.stage.length < 1)
				song.stage = StageData.vanillaSongStage(folder);

			var stageData:StageFile = StageData.getStageFile(song.stage);
			if (stageData != null)
			{
				var imgs:Array<String> = [];
				var snds:Array<String> = [];
				var mscs:Array<String> = [];
				if(stageData.preload != null)
				{
					for (asset in Reflect.fields(stageData.preload))
					{
						var filters:Int = Reflect.field(stageData.preload, asset);
						var asset:String = asset.trim();

						if(filters < 0 || StageData.validateVisibility(filters))
						{
							if(asset.startsWith('images/'))
								imgs.push(asset.substr('images/'.length));
							else if(asset.startsWith('sounds/'))
								snds.push(asset.substr('sounds/'.length));
							else if(asset.startsWith('music/'))
								mscs.push(asset.substr('music/'.length));
						}
					}
				}

				if (stageData.objects != null)
				{
					for (sprite in stageData.objects)
					{
						if(sprite.type == 'sprite' || sprite.type == 'animatedSprite')
							if((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
								imgs.push(sprite.image);
					}
				}
				prepare(imgs, snds, mscs);
			}

			if (PlayState.altInstrumentals != null)
			{
				songsToPrepare.push('${Paths.formatToSongPath(PlayState.altInstrumentals)}/Inst');
			}
			else
				songsToPrepare.push('$folder/Inst');

			var player1:String = song.player1;
			var player2:String = song.player2;
			var gfVersion:String = song.gfVersion;
			var prefixVocals:String = song.needsVoices ? '$folder/Voices' : null;
			if (gfVersion == null) gfVersion = 'gf';

			dontPreloadDefaultVoices = false;
			preloadCharacter(player1, prefixVocals);
			if (!dontPreloadDefaultVoices && prefixVocals != null)
			{
				if(Paths.fileExists('$prefixVocals-Player.${Paths.SOUND_EXT}', SOUND, false, 'songs') && Paths.fileExists('$prefixVocals-Opponent.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
				{
					songsToPrepare.push('$prefixVocals-Player');
					songsToPrepare.push('$prefixVocals-Opponent');
				}
				else if(Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
					songsToPrepare.push(prefixVocals);
			}

			if (player2 != player1)
			{
				threadsMax++;
				threadPool.run(() -> {
					try { preloadCharacter(player2, prefixVocals); } catch (e:Dynamic) {}
					completedThread();
				});
			}
			if (!stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
			{
				threadsMax++;
				threadPool.run(() -> {
					try { preloadCharacter(gfVersion); } catch (e:Dynamic) {}
					completedThread();
				});
			}

			if(threadsCompleted == threadsMax)
			{
				clearInvalids();
				startThreads();
				initialThreadCompleted = true;
			}
			return true;
		}, isIntrusive))
		.onError((err:Dynamic) -> {
			trace('ERROR! while preparing song: $err');
		});
	}

	public static function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music',' .${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentFolder:String = null)
	{
		for (folder in arr.copy())
		{
			var nam:String = folder.trim();
			if(nam.endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam'))
				{
					for (file in FileSystem.readDirectory(subfolder))
					{
						if(file.endsWith(ext))
						{
							var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
							if(!arr.contains(toAdd)) arr.push(toAdd);
						}
					}
				}

				//trace('Folder detected! ' + folder);
			}
		}

		var i:Int = 0;
		while(i < arr.length)
		{

			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			if(parentFolder == 'songs') myKey = '$member$ext';

			//trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if(member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentFolder) && (doTrace = true)))
			{
				arr.remove(member);
				if(doTrace) trace('Removed invalid $prefix: $member');
			}
			else i++;
		}
	}

	public static function startThreads()
	{
		mutex = new Mutex();
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length + 1;
		loaded = 0;

		//then start threads
		_threadFunc();
	}

	static function _threadFunc()
	{
		_startPool();
		for (sound in soundsToPrepare) initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
		for (music in musicToPrepare) initThread(() -> preloadSound('music/$music'), 'music $music');
		for (song in songsToPrepare) initThread(() -> preloadSound(song, 'songs', true, false), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare) preloadGraphic(image); //initThread(() -> preloadGraphic(image), 'image $image');

		//Preload Song
		switch (ClientPrefs.data.chartPreload) {
			case 'Off':
				loaded++;
				chartLoaded = true;
			case 'No Threadding':
				preloadChart();
			case 'On':
				initThreadAlt(preloadChart, 'chart');
		}
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		// trace('scheduled $func in threadPool');
		#if debug
		var threadSchedule = Sys.time();
		#end
		threadPool.run(() -> {
			#if debug
			var threadStart = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try {
				if (func() != null) {
					#if debug
					var diff = Sys.time() - threadStart;
					trace('finished preloading $traceData in ${diff}s');
					#end
				} else trace('ERROR! fail on preloading $traceData ');
			}
			catch(e:Dynamic) {
				trace('ERROR! fail on preloading $traceData: $e');
			}
			// mutex.acquire();
			loaded++;
			// mutex.release();
		});
	}

	static function initThreadAlt(func:Void->Void, traceData:String)
	{
		// trace('scheduled $func in threadPool');
		#if debug
		var threadSchedule = Sys.time();
		#end
		threadPool.run(() -> {
			#if debug
			var threadStart = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try {
				func();
			}
			catch(e:Dynamic) {
				trace('ERROR! fail on preloading $traceData: $e');
			}

			loaded++;
		});
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if(!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					imagesToPrepare.push(file.trim());
				}
			}
			#if flxanimate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if(i == 0) st = '';

					if(Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						//trace('found Sprite PNG');
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
			}
			#end

			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
				if(char == PlayState.SONG.player1) dontPreloadDefaultVoices = true;
			}
		}
		catch(e:haxe.Exception)
		{
			trace(e.details());
		}
	}

	// thread safe sound loader
	static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Null<Sound>
	{
		var file:String = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!Paths.currentTrackedSounds.exists(file))
		{
			if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND))
			{
				var sound:Sound = #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file, false) #end;
				mutex.acquire();
				Paths.currentTrackedSounds.set(file, sound);
				mutex.release();
			}
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		mutex.acquire();
		Paths.localTrackedAssets.push(file);
		mutex.release();

		return Paths.currentTrackedSounds.get(file);
	}

	// thread safe sound loader
	static function preloadGraphic(key:String):Null<BitmapData>
	{
		try {
			var requestKey:String = 'images/$key';
			#if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
			if(requestKey.lastIndexOf('.') < 0) requestKey += '.png';

			if (!Paths.currentTrackedAssets.exists(requestKey))
			{
				var file:String = Paths.getPath(requestKey, IMAGE);
				if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE))
				{
					#if sys
					var bitmap:BitmapData = BitmapData.fromFile(file);
					#else
					var bitmap:BitmapData = OpenFlAssets.getBitmapData(file, false);
					#end

					mutex.acquire();
					requestedBitmaps.set(file, bitmap);
					originalBitmapKeys.set(file, requestKey);
					mutex.release();
					loaded++;
					return bitmap;
				}
				else trace('no such image $key exists');
			}
			loaded++;
			return Paths.currentTrackedAssets.get(requestKey).bitmap;
		}
		catch(e:haxe.Exception)
		{
			trace('ERROR! fail on preloading image $key');
		}

		return null;
	}

	static var songSpeed = PlayState.SONG?.speed;
	static function preloadChart() {
		var totalColumns:Int = Note.ammo[PlayState.SONG?.mania != null ? PlayState.SONG?.mania : 3];
		var prevNoteData:Int = -1;
		var initialNoteData:Int = -1;
		var caseExecutionCount:Int = FlxG.random.int(-50, 50);
		var currentModifier:Int = -1;
		var stair:Int = 0;

		var AIPlayMap:Array<Array<Float>> = AIPlayer.active ? AIPlayer.GeneratePlayMap(PlayState.SONG, AIPlayer.diff) : null;
		var oldNote:Note = null;
		var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
		var ghostNotesCaught:Int = 0;
		var daBpm:Float = Conductor.bpm;

		var sectionLoopCount:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		speedChanges.push({
			position: -6000 * 0.45,
			startTime: -6000,
			speed: 1,
			#if EASED_SVs
			startSpeed: 1,
			#end
		});

		speedChanges.sort(svSort);

		#if EASED_SVs
		resetSVDeltas();
		#end

		for (section in sectionsData)
		{
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes:Array<Dynamic> = section.sectionNotes[i];
				var spawnTime:Float = songNotes[0];
				var noteColumn:Int = Std.int(songNotes[1]);
				var noteStartColumn:Int = Std.int(songNotes[1] % Note.ammo[PlayState.SONG.mania != null ? PlayState.SONG.mania : 3]);
				var holdLength:Float = songNotes[2];
				var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				if (Math.isNaN(holdLength)) holdLength = 0.0;

				var gottaHitNote:Bool;
				noteColumn = Std.int(songNotes[1] % Note.ammo[PlayState.SONG.mania != null ? PlayState.SONG.mania : 3]);
				gottaHitNote = (songNotes[1] < (PlayState.SONG.mania != null ? totalColumns : Note.ammo[3]));

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in noteCache) {
						var matches:Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
						if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON) {
							if (evilNote.tail.length > 0)
								for (tail in evilNote.tail)
								{
									tail.destroy();
									noteCache.remove(tail);
								}
							evilNote.destroy();
							noteCache.remove(evilNote);
							ghostNotesCaught++;
							//continue;
						}
					}
				}

				switch (ClientPrefs.getGameplaySetting('chartModifier', 'Normal'))
				{
					case "Random":
						noteColumn = FlxG.random.int(0, PlayState.mania);
					case "RandomBasic":
						var randomDirection:Int;
						do
						{
							randomDirection = FlxG.random.int(0, PlayState.mania);
						}
						while (randomDirection == prevNoteData && PlayState.mania > 1);
						prevNoteData = randomDirection;
						noteColumn = randomDirection;
					case "RandomComplex":
						var thisNoteData = noteColumn;
						if (initialNoteData == -1)
						{
							initialNoteData = noteColumn;
							noteColumn = FlxG.random.int(0, PlayState.mania);
						}
						else
						{
							var newNoteData:Int;
							do
							{
								newNoteData = FlxG.random.int(0, PlayState.mania);
							}
							while (newNoteData == prevNoteData && PlayState.mania > 1);
							if (thisNoteData == initialNoteData)
							{
								noteColumn = prevNoteData;
							}
							else
							{
								noteColumn = newNoteData;
							}
						}
						prevNoteData = noteColumn;
						initialNoteData = thisNoteData;

					case "Mirror": // Broken
						var length = PlayState.mania;
						var mirroredIndex:Int;
						var middle = Math.floor(length / 2);
						if (noteColumn < middle)
						{
							mirroredIndex = (middle - noteColumn) + middle - 1;
						}
						else if (noteColumn > middle)
						{
							mirroredIndex = middle - (noteColumn - middle);
						}
						else
						{
							mirroredIndex = noteColumn;
						}
						noteColumn = mirroredIndex;
					case "ReverseMirror":
						var median:Float = (PlayState.mania + 1) / 2;
						if (noteColumn <= median)
						{
							// For values below the median, mirror downwards
							noteColumn = Std.int(median - (median - noteColumn) - 1);
						}
						else
						{
							// For values above the median, mirror upwards
							noteColumn = Std.int(median + (noteColumn - median) + 1);
						}
						noteColumn = Std.int(Math.max(0, Math.min(noteColumn, PlayState.mania - 1)));

					case "Skip":
						var skipStep = 2; // Define the step size for skipping notes.
						var randomLane = Math.random() < 0.5 ? prevNoteData : (prevNoteData + skipStep) % PlayState.mania;
						var randomDuration = Math.random() * 30; // Randomize the duration before switching lanes (in notes).
						noteColumn = randomLane;
					case "Flip":
						if (gottaHitNote)
						{
							noteColumn = PlayState.mania - Std.int(songNotes[1] % Note.ammo[PlayState.mania]);
						}
					case "Pain":
						noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[PlayState.mania]);
					case "4K Only":
						//trace("4K Only: " + noteColumn);
						noteColumn = PlayState.getNumberFromAnimsSmall(noteColumn, 3);
						//trace("Note: " + noteColumn + " PlayState.mania: " + PlayState.mania + " GottaHit: " + gottaHitNote);
					case "ManiaConverter":
						//trace("ManiaConverter: " + noteColumn);
						noteColumn = PlayState.getNumberFromAnimsSmall(noteColumn, PlayState.mania);
						//trace("Note: " + noteColumn + " PlayState.mania: " + PlayState.mania + " GottaHit: " + gottaHitNote);
					case "Stairs":
						noteColumn = stair % Note.ammo[PlayState.mania];
						stair++;
					case "Wave":
						// Sketchie... WHY?!
						var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
						var luigiSex:Int = (ammoFromFortnite * 2 - 2);
						var marioSex:Int = stair++ % luigiSex;
						if (marioSex < ammoFromFortnite)
						{
							noteColumn = marioSex;
						}
						else
						{
							noteColumn = luigiSex - marioSex;
						}
					case "Trills":
						var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
						var luigiSex:Int = (ammoFromFortnite * 2 - 2);
						var marioSex:Int;
						do
						{
							marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
							if (marioSex < ammoFromFortnite)
							{
								noteColumn = marioSex;
							}
							else
							{
								noteColumn = luigiSex - marioSex;
							}
						}
						while (noteColumn == prevNoteData && PlayState.mania > 1);
						prevNoteData = noteColumn;
					case "Ew":
						// I hate that I used Sketchie's variables as a base for this... ;-;
						var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
						var luigiSex:Int = (ammoFromFortnite * 2 - 2);
						var marioSex:Int = stair++ % luigiSex;
						var noteIndex:Int = Std.int(marioSex / 2);
						var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
						noteColumn = noteIndex + noteDirection;
						// If the note index is out of range, wrap it around
						if (noteColumn < 0)
						{
							noteColumn = 1;
						}
						else if (noteColumn >= ammoFromFortnite)
						{
							noteColumn = ammoFromFortnite - 2;
						}
					case "Death":
						var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
						var luigiSex:Int = (ammoFromFortnite * 4 - 4);
						var marioSex:Int = stair++ % luigiSex;
						var step:Int = Std.int(luigiSex / 3);

						if (marioSex < ammoFromFortnite)
						{
							noteColumn = marioSex % step;
						}
						else if (marioSex < ammoFromFortnite * 2)
						{
							noteColumn = (marioSex - ammoFromFortnite) % step + step;
						}
						else if (marioSex < ammoFromFortnite * 3)
						{
							noteColumn = (marioSex - ammoFromFortnite * 2) % step + step * 2;
						}
						else
						{
							noteColumn = (marioSex - ammoFromFortnite * 3) % step + step * 3;
						}
					case "What":
						switch (stair % (2 * Note.ammo[PlayState.mania]))
						{
							case 0:
							case 1:
							case 2:
							case 3:
							case 4:
								noteColumn = stair % Note.ammo[PlayState.mania];
							default:
								noteColumn = Note.ammo[PlayState.mania] - 1 - (stair % Note.ammo[PlayState.mania]);
						}
						stair++;
					case "Amalgam":
						{
							var modifierNames:Array<String> = [
								"Random",
								"RandomBasic",
								"RandomComplex",
								"Flip",
								"Pain",
								"Stairs",
								"Wave",
								"Huh",
								"Ew",
								"What",
								"Jack Wave",
								"SpeedRando",
								"Trills"
							];

							if (caseExecutionCount <= 0)
							{
								currentModifier = FlxG.random.int(-1, (modifierNames.length - 1)); // Randomly select a case from 0 to 9
								caseExecutionCount = FlxG.random.int(1, 51); // Randomly select a number from 1 to 50
								trace("Active Modifier: " + modifierNames[currentModifier] + ", Notes to edit: " + caseExecutionCount);
							}
							// trace('Notes remaining: ' + caseExecutionCount);
							caseExecutionCount--;
							switch (currentModifier)
							{
								case 0: // "Random"
									noteColumn = FlxG.random.int(0, PlayState.mania);
								case 1: // "RandomBasic"
									var randomDirection:Int;
									do
									{
										randomDirection = FlxG.random.int(0, PlayState.mania);
									}
									while (randomDirection == prevNoteData && PlayState.mania > 1);
									prevNoteData = randomDirection;
									noteColumn = randomDirection;
								case 2: // "RandomComplex"
									var thisNoteData = noteColumn;
									if (initialNoteData == -1)
									{
										initialNoteData = noteColumn;
										noteColumn = FlxG.random.int(0, PlayState.mania);
									}
									else
									{
										var newNoteData:Int;
										do
										{
											newNoteData = FlxG.random.int(0, PlayState.mania);
										}
										while (newNoteData == prevNoteData && PlayState.mania > 1);
										if (thisNoteData == initialNoteData)
										{
											noteColumn = prevNoteData;
										}
										else
										{
											noteColumn = newNoteData;
										}
									}
									prevNoteData = noteColumn;
									initialNoteData = thisNoteData;
								case 3: // "Flip"
									if (gottaHitNote)
									{
										noteColumn = PlayState.mania - Std.int(songNotes[1] % Note.ammo[PlayState.mania]);
									}
								case 4: // "Pain"
									noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[PlayState.mania]);
								case 5: // "Stairs"
									noteColumn = stair % Note.ammo[PlayState.mania];
									stair++;
								case 6: // "Wave"
									// Sketchie... WHY?!
									var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
									var luigiSex:Int = (ammoFromFortnite * 2 - 2);
									var marioSex:Int = stair++ % luigiSex;
									if (marioSex < ammoFromFortnite)
									{
										noteColumn = marioSex;
									}
									else
									{
										noteColumn = luigiSex - marioSex;
									}
								case 7: // "Huh"
									var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
									var luigiSex:Int = (ammoFromFortnite * 4 - 4);
									var marioSex:Int = stair++ % luigiSex;
									var step:Int = Std.int(luigiSex / 3);
									var waveIndex:Int = Std.int(marioSex / step);
									var waveDirection:Int = waveIndex % 2 == 0 ? 1 : -1;
									var waveRepeat:Int = Std.int(waveIndex / 2);
									var repeatStep:Int = marioSex % step;
									if (repeatStep < waveRepeat)
									{
										noteColumn = waveIndex * step + waveDirection * repeatStep;
									}
									else
									{
										noteColumn = waveIndex * step + waveDirection * (waveRepeat * 2 - repeatStep);
									}
									if (noteColumn < 0)
									{
										noteColumn = 0;
									}
									else if (noteColumn >= ammoFromFortnite)
									{
										noteColumn = ammoFromFortnite - 1;
									}
								case 8: // "Ew"
									// I hate that I used Sketchie's variables as a base for this... ;-;
									var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
									var luigiSex:Int = (ammoFromFortnite * 2 - 2);
									var marioSex:Int = stair++ % luigiSex;
									var noteIndex:Int = Std.int(marioSex / 2);
									var noteDirection:Int = marioSex % 2 == 0 ? 1 : -1;
									noteColumn = noteIndex + noteDirection;
									// If the note index is out of range, wrap it around
									if (noteColumn < 0)
									{
										noteColumn = 1;
									}
									else if (noteColumn >= ammoFromFortnite)
									{
										noteColumn = ammoFromFortnite - 2;
									}
								case 9: // "What"
									switch (stair % (2 * Note.ammo[PlayState.mania]))
									{
										case 0:
										case 1:
										case 2:
										case 3:
										case 4:
											noteColumn = stair % Note.ammo[PlayState.mania];
										default:
											noteColumn = Note.ammo[PlayState.mania] - 1 - (stair % Note.ammo[PlayState.mania]);
									}
									stair++;
								case 10: // Jack Wave
									var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
									var luigiSex:Int = (ammoFromFortnite * 2 - 2);
									var marioSex:Int = Std.int((stair++ % (luigiSex * 4)) / 4);
									if (marioSex < ammoFromFortnite)
									{
										noteColumn = marioSex;
									}
									else
									{
										noteColumn = luigiSex - marioSex;
									}
								case 11: // SpeedRando
									// Handled by SpeedRando Code below!
								case 12: // Trills
									var ammoFromFortnite:Int = Note.ammo[PlayState.mania];
									var luigiSex:Int = (ammoFromFortnite * 2 - 2);
									var marioSex:Int;
									do
									{
										marioSex = Std.int((stair++ % (luigiSex * 4)) / 4 + stair % 2);
										if (marioSex < ammoFromFortnite)
										{
											noteColumn = marioSex;
										}
										else
										{
											noteColumn = luigiSex - marioSex;
										}
									}
									while (noteColumn == prevNoteData && PlayState.mania > 1);
									prevNoteData = noteColumn;
								default:
									// Default case (optional)
							}
						}
				}

				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
				holdLength = Math.round(songNotes[2] / curStepCrochet) - 1;
				if (noteCache.length > 0)
					oldNote = noteCache[Std.int(noteCache.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = ClientPrefs.data.useExperimentalNotePool ?
					NotePoolManager.createNote(spawnTime, noteColumn, oldNote, false, false, null) :
					new Note(spawnTime, noteColumn, oldNote, false, false, null, false);
				swagNote.noteIndex = Std.int(noteCache.length);
				swagNote.formerPress = swagNote.mustPress = gottaHitNote;

				swagNote.row = Conductor.secsToRow(spawnTime);
				if (!swagNote.mustPress)
				{
					if (AIPlayMap != null && AIPlayMap.length != 0 && [sectionsData.indexOf(section)] != null)
					{
						swagNote.AIStrumTime = AIPlayMap[sectionsData.indexOf(section)][section.sectionNotes.indexOf(songNotes)];
						if (Math.abs(swagNote.AIStrumTime) > Conductor.safeZoneOffset)
							swagNote.ignoreNote = swagNote.AIMiss = true;
					}
				}
				var isAlt: Bool = section.altAnim && !gottaHitNote;
				swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
				swagNote.animSuffix = isAlt ? "-alt" : "";
				swagNote.sustainLength = songNotes[2] <= curStepCrochet ? songNotes[2] : (holdLength + 1) * curStepCrochet; // +1 because hold end
				swagNote.noteType = noteType;
				swagNote.ID = noteCache.length;
				swagNote.holdType = swagNote.sustainLength > 0 ? HEAD : TAP;
				swagNote.isParent = swagNote.sustainLength > 0;
				//swagNote.scrollFactor.set();
				var setPos:Bool = true;

				if ((swagNote.noteType == null || (swagNote.noteType == '' || swagNote.noteType.length == 0)) && swagNote.mustPress)
				{
					if (FlxG.random.bool(MechanicManager.mechanics['swap_note'].points * 0.16))
					{
						setPos = false;
						swagNote.noteType = 'Swap Note';
						swagNote.copyX = false;
						swagNote.typeOffsetX += 60;
					}
				}

				if (ClientPrefs.getGameplaySetting('chartModifier', 'Normal') == 'Amalgam' && currentModifier == 11)
				{
					swagNote.multSpeed = FlxG.random.float(0.1, 2);
				}

				////

				var playfield:PlayField = swagNote.field;

				if (playfield == null) {
					if (swagNote.fieldIndex == -1)
						swagNote.fieldIndex = swagNote.mustPress ? 0 : 1;
				}

				mutex.acquire();
				noteCache.push(swagNote);
				mutex.release();

				var spot = 0;
				final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet) -1;
				if (roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = noteCache[Std.int(noteCache.length - 1)];

						var sustainNote:Note = ClientPrefs.data.useExperimentalNotePool ?
								NotePoolManager.createNote(spawnTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), noteColumn, oldNote, true, false, null) :
								new Note(spawnTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), noteColumn, oldNote, true, false, null, true);
						sustainNote.mustPress = sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.exNote = swagNote.exNote;
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.noteIndex = swagNote.noteIndex;
						if (ClientPrefs.getGameplaySetting('chartModifier', 'Normal') == 'Amalgam' && currentModifier == 11)
						{
							sustainNote.multSpeed = swagNote.multSpeed;
						}
						if (sustainNote == null || !sustainNote.alive)
							break;
						sustainNote.ID = noteCache.length;
						//sustainNote.scrollFactor.set();
						sustainNote.holdType = roundSus > 0 ? PART : END;
						sustainNote.parent = swagNote;
						sustainNote.fieldIndex = swagNote.fieldIndex;
						sustainNote.field = swagNote.field;
						mutex.acquire();
						swagNote.tail.push(sustainNote);
						swagNote.unhitTail.push(sustainNote);
						noteCache.push(sustainNote);
						mutex.release();
						var setPos:Bool = true;
						if (sustainNote.noteType == 'Swap Note') {
							setPos = false;
							sustainNote.typeOffsetX = swagNote.typeOffsetX;
						}
						if (setPos)
						{
							var originalSusPos:Float = sustainNote.x;

							if (sustainNote.formerPress)
							{
								sustainNote.x += FlxG.width * 0.5; // general offset
							}
						}
						else
							sustainNote.copyX = false;

						sustainNote.parent = swagNote;
						mutex.acquire();
						swagNote.childs.push(sustainNote);
						mutex.release();
						sustainNote.spotInLine = spot;
						spot++;
					}
				}

				#if MECHANICS_MOD_ALLOWED
				if (PlayState.mechanicsMod != null) {
					var sectionLength = (section.sectionBeats*4);

					var sectionStartTime:Float = (Conductor.stepCrochet * sectionLoopCount) * sectionLength;

					// note placement
					var weightedChances:Array<Null<Float>> = [];
					var getChance:Int->Float = function(i)
					{
						if (weightedChances[i] == null)
						{
							weightedChances[i] = 0;
						}

						return weightedChances[i];
					};

					// [MECHANIC NAME, NOTE TYPE]
					var generatedTypes:Array<Array<Dynamic>> = [
						[
							'hurt_note',
							'Hurt Note',
							Math.min(MechanicManager.mechanics['hurt_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / PlayState.SONG.notes.length * 0.2,
								1),
							0.5,
							1
						],
						[
							'kill_note',
							'Kill Note',
							Math.min(MechanicManager.mechanics['kill_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / PlayState.SONG.notes.length * 0.2,
								1),
							0.2,
							0.5
						],
						[
							'burst_note',
							'Burst Note',
							Math.min(MechanicManager.mechanics['burst_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / PlayState.SONG.notes.length * 0.2,
								1),
							0.35,
							0.9
						],
						[
							'sleep_note',
							'Sleep Note',
							Math.min(MechanicManager.mechanics['sleep_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / PlayState.SONG.notes.length * 0.2,
								1),
							0.35,
							0.75
						],
						[
							'fake_note',
							'Fake Note',
							Math.min((MechanicManager.mechanics['fake_note'].points / 2) * FlxMath.remapToRange(sectionLength, 0, 16, 1,
								6) / PlayState.SONG.notes.length * 0.2, 1),
							0.5,
							0.9
						],
						[
							'note_random',
							'No Animation',
							Math.min(MechanicManager.mechanics['note_random'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / PlayState.SONG.notes.length * 0.2,
								1),
							0.9,
							1.1
						]
					];

					for (j in [false, true])
					{
						for (ii in 0...weightedChances.length)
						{
							weightedChances[ii] = 0;
						}
						var hitSectionMulti:Float = 1;

						if (section.mustHitSection != j)
						{
							hitSectionMulti = 0.2;
						}
						if (section.sectionNotes.length < 8)
							hitSectionMulti = 0.04;

						for (i in 0...16)
						{
							for (jj in 0...generatedTypes.length)
							{
								var chance:Float = generatedTypes[jj][2] + (getChance(jj) * generatedTypes[jj][4]);
								if (generatedTypes[jj][0] == 'note_random')
									chance *= hitSectionMulti;
								else if (generatedTypes[jj][0] == 'restore_note' && (!j && !ClientPrefs.getGameplaySetting('bothMode', false)))
									break;
								var placeNote:Note = placeNote(chance, generatedTypes[jj][1], [
									sectionStartTime + (Conductor.stepCrochet * i),
									FlxG.random.int(0, 3),
									j,
									generatedTypes[jj][3]
								]);

								if (placeNote == null)
								{
									weightedChances[jj] += FlxG.random.float(0,
										FlxMath.remapToRange(MechanicManager.mechanics[generatedTypes[jj][0]].points, 0, 20, 0, 2)) * 0.75;
									continue;
								}
								mutex.acquire();
								noteCache.push(placeNote); // just for the sake of convenience
								mutex.release();
								weightedChances[jj] = 0;
							}
						}
					}
					var strumSwapPoints:Int = MechanicManager.mechanics['strum_swap'].points;

					if (FlxG.random.bool(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 8) + getChance(7)))
					{
						PlayState.moveStrumSections[sectionLoopCount] = true;
						weightedChances[7] = 0;
					}
					else
					{
						PlayState.moveStrumSections[sectionLoopCount] = false;
						weightedChances[7] += FlxG.random.float(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 0.4));
					}
					sectionLoopCount += 1;
				}
				#end
			}

			#if MECHANICS_MOD_ALLOWED
			if (PlayState.mechanicsMod != null) {
				if (MechanicManager.mechanics["note_speed"].points > 0)
				{
					for (note in noteCache)
					{
						if (note.isSustainNote)
							continue;
						var speedBound:{min:Float, max:Float};
						var points:Float = MechanicManager.mechanics["note_speed"].points;

						speedBound = {min: FlxMath.remapToRange(points, 0, 20, -0, -0.5), max: FlxMath.remapToRange(points, 0, 20, 0, 0.5)};
						note.multSpeed = songSpeed + FlxG.random.float(speedBound.min, speedBound.max);
						for (sus in note.tail)
						{
							sus.multSpeed = note.multSpeed;
						}
					}
				}
			}
			#end
		}
		trace('Done Preloading Chart!');
		chartLoaded = true;
		loaded++;
	}

	static function placeNote(chance:Float, noteType:String, attributes:Array<Dynamic>):Note
	{
		if (FlxG.random.bool(chance))
		{
			var dataNote:Note = new Note(attributes[0], attributes[1], null, false);
			dataNote.autoGenerated = true;
			dataNote.earlyHitMult = attributes[3];
			dataNote.mustPress = dataNote.formerPress = attributes[2];
			dataNote.noteType = noteType;
			dataNote.scrollSpeed = songSpeed;
			dataNote.scrollFactor.set();

			return dataNote;
		}

		return null;
	}

	private static var svIndex:Int =0;
	private inline static function updateVisualPosition() {
		var event:SpeedEvent = null;

		for (i in svIndex+1...speedChanges.length) {
			var nextEvent = speedChanges[i];
			if (nextEvent.startTime > Conductor.songPosition)
				break;

			svIndex = i;
			event = nextEvent;
		}
		event ??= speedChanges[svIndex];

		Conductor.visualPosition = getTimeFromSV(Conductor.songPosition, event);
		FlxG.watch.addQuick("visualPos", Conductor.visualPosition);
	}

	public static function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}

	#if EASED_SVs
	static var lastSVTime:Float = 0;
	static var lastSVElapsed:Float = 0;
	static var lastSVPos:Float = 0;

	inline static function resetSVDeltas(){
		if(speedChanges.length > 0){
			lastSVTime = speedChanges[0].startTime;
			lastSVElapsed = 0;
			lastSVPos = speedChanges[0].position;
		}else{
			lastSVTime = -5000;
			lastSVElapsed = 0;
			lastSVPos = -5000 * 0.45;
		}
	}
	#end

	public static function getTimeFromSV(time:Float, event:SpeedEvent):Float {
		#if EASED_SVs
		var func:EaseFunction = event.easeFunc;
		if (event.endTime != null) {
			var timeElapsed:Float = FlxMath.remapToRange(time, event.startTime, event.endTime, 0, 1);
			if(timeElapsed > 1)timeElapsed = 1;
			if(timeElapsed < 0)timeElapsed = 0;
			var currentSpeed = FlxMath.lerp(event.startSpeed, event.speed, func(lastSVElapsed));

			var toAdd:Float = time - lastSVTime;
			var finalPosition:Float = lastSVPos + toAdd * currentSpeed;

			lastSVPos = finalPosition;
			lastSVTime = time;
			lastSVElapsed = timeElapsed;
			return finalPosition;
		}
		#end

		return event.position + ((time - event.startTime) * 0.45 * event.speed);
	}

	static function getSV(time:Float){
		var svIndex:Int = 0;

		var event:SpeedEvent = speedChanges[svIndex];
		if (svIndex < speedChanges.length - 1) {
			while (speedChanges[svIndex + 1] != null && speedChanges[svIndex + 1].startTime <= time) {
				event = speedChanges[svIndex + 1];
				svIndex++;
			}
		}

		return event;
	}

	static function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startTime, Obj2.startTime);
	}

	#if cpp
	@:functionCode('
		return std::thread::hardware_concurrency();
    	')
	@:noCompletion
    	public static function getCPUThreadsCount():Int
    	{
        	return -1;
    	}
    	#end

			private static var _doingRestart:Bool = false;

	/**
	 * Start asynchronous preloading for PlayState
	 * Uses ASync to generate song chart without visual objects
	 */
	static function startPlayStatePreload(playStateTarget:states.PlayState):Void {
		if (playStateTarget == null || states.PlayState.SONG == null) {
			trace("LoadingState: Cannot preload - target or SONG is null");
			return;
		}
		trace("Is Restarting: " + _doingRestart);

		trace("LoadingState: Starting async preload for song: " + states.PlayState.SONG.song);


		// Create async function for chart generation
		var preloadFunction = (function():Bool {
			trace("LoadingState: Async preload thread started");

			trace("LoadingState: Waiting for any ongoing GC behavior to finish...");

		while (!MusicBeatState.getState().didGCBehavior || _doingRestart) {
			// Wait for garbage collection behavior to be executed.
			// trace("Restart State: " + _doingRestart + " | Did GC Behavior: " + MusicBeatState.getState().didGCBehavior);
		}


			// Call generateSong with preload=true on the target instance
			@:privateAccess
			playStateTarget.waitingForPreloadFinish = true;
			playStateTarget.forceGenerateSong(true);

			trace("LoadingState: Async preload generation completed");
			return true;
		});

		var A:ASync<Dynamic> = preloadFunction;


		// Start the async operation
		preloadAsync = cast A();

	}
}
