package states;

import haxe.Timer;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import animateatlas.AtlasFrameMaker;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import ShadersHandler;
import STMetaFile.MetadataFile;
import Conductor.Rating;
import flixel.FlxG;
import flixel.animation.FlxAnimationController;
import modchart.*;

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

// Etterna
class Wife3
{
	public static var missWeight:Float = -5.5;
	public static var mineWeight:Float = -7;
	public static var holdDropWeight:Float = -4.5;
	public static var a1 = 0.254829592;
	public static var a2 = -0.284496736;
	public static var a3 = 1.421413741;
	public static var a4 = -1.453152027;
	public static var a5 = 1.061405429;
	public static var p = 0.3275911;

	public static function werwerwerwerf(x:Float):Float
	{
		var sign = 1;
		if (x < 0)sign = -1;
		x = Math.abs(x);
		var t = 1 / (1+p*x);
		var y = 1 - (((((a5*t+a4)*t)+a3)*t+a2)*t+a1)*t*Math.exp(-x*x);
		return sign*y;
	}

	public static var timeScale:Float = 1;
	public static function getAcc(noteDiff:Float, ?ts:Float):Float{ // https://github.com/etternagame/etterna/blob/0a7bd768cffd6f39a3d84d76964097e43011ce33/src/RageUtil/Utils/RageUtil.h
		if(ts==null)ts=timeScale;
		if(ts>1)ts=1;
		var jPow:Float = 0.75;
		var maxPoints:Float = 2.0;
		var ridic:Float = 5 * ts;
		var shit_weight:Float = 200;
		var absDiff = Math.abs(noteDiff);
		var zero:Float = 65 * Math.pow(ts, jPow);
		var dev:Float = 22.7 * Math.pow(ts, jPow);

		if(absDiff<=ridic){
			return maxPoints;
		} else if(absDiff<=zero){
			return maxPoints*werwerwerwerf((zero-absDiff)/dev);
		}else if(absDiff<=shit_weight){
			return (absDiff-zero)*missWeight/(shit_weight-zero);
		}
		return missWeight;
	}


}

class PlayState extends MusicBeatState
{
	public var modManager:ModManager;
	var allowManagerStuff:Bool = false;

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var dad2Map:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	#if sys
	public static var animatedShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();
	#end
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var dad2Map:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
	public var modchartObjects:Map<String, FlxSprite> = new Map();
	#if sys
	public static var animatedShaders:Map<String, DynamicShaderHandler> = new Map();
	#end
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var DAD2_X:Float = 100;
	public var DAD2_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var dadGroup2:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;

	public var dad:Character = null;
	public static var dad2:Character = null;
	public var ghostChar:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;
	public var ghostChar2:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var notesToSpawn:Array<Array<Note>> = []; // too lazy to redo all unspawnNotes code so this'll handle the spawning and thats it lol
	public var eventNotes:Array<EventNote> = [];

	public static var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var opponentStrums2:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var healthGF:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var healthBar2:FlxBar;
	public var healthBarGF:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	
	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public static var mania:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var chartModifier:String = 'Normal';

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP22:HealthIcon;
	public var iconP1G:HealthIcon;
	public var iconP2G:HealthIcon;
	public var iconGF:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camCredit:FlxCamera;
	public var camOther:FlxCamera;
	public var camFilters:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var songScore:Int = 0;
	public var gfBopCombo:Int = 0;
	public var gfBopComboBest:Int = 0;
	public var songHits:Int = 0;
	public var gfHits:Int = 0;
	public var songMisses:Int = 0;
	public var gfMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var opponent2CameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';
	#if sys
	public var luaShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();
	#end

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	//aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
	public var bfkilledcheck = false;
	var filters:Array<BitmapFilter> = [];
	var camfilters:Array<BitmapFilter> = [];
	var ch = 2 / 1000;
	public var shaderUpdates:Array<Float->Void> = [];
	var metadata:MetadataFile;
	var hasMetadataFile:Bool = false;
	var Text:Array<String> = [];
	var whiteBG:FlxSprite;
	var blackOverlay:FlxSprite;
	var blackUnderlay:FlxSprite;
	var freezeNotes:Bool = false;
	public var sh_r:Float = 600;
	var rotRate:Float;
	var rotRateSh:Float;
	var derp = 20;
	var fly:Bool = false;
	var stageData:StageFile;
	var diffTxt:FlxText;
	var artistTxt:FlxText;
	var stageTxt:FlxText;
	var songTxt:FlxText;
	var winX = Lib.application.window.x;
	var winY = Lib.application.window.y;
	var charFade:FlxTween;
	var charFade2:FlxTween;
	var chromCheck:Int = 0;
	var shaggyT:FlxTrail;
	var burst:FlxSprite;
	var cutTime = 0;
	public static var threeLanes:Bool = false;
	var hasGlow:Bool = false;
	var strumFocus:Bool = false;
	public static var playAsGF:Bool = false;
	public static var savedTime:Float = 0;
	public static var savedBeat:Int = 0;
	public static var savedStep:Int = 0;
	public var modifitimer:Int = 0;
	public var gimmicksAllowed:Bool = false;
	public var chromOn:Bool = false;
	public var beatchrom:Bool = false;
	public var beatchromfaster:Bool = false;
	public var beatchromfastest:Bool = false;
	public var beatchromslow:Bool = false;
	var abrrmult:Float = 1;
	var defMult:Float = 0.04;
	public var lyrics:FlxText;
	public var lyricsArray:Array<String> = [];
	var daStatic:FlxSprite;
	var daRain:FlxSprite;
	var thunderON:Bool = false;
	var rave:FlxTypedGroup<FlxSprite>;
	var gfScared:Bool = false;
	var precacheList:Map<String, String> = new Map<String, String>();
	
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText;
	var skipTo:Float;

	public var playerField:PlayField;
	public var dadField:PlayField;

	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	override public function create()
	{
		
		Paths.clearStoredMemory(true);
		Paths.clearUnusedMemory();
		precacheList.set(curSong.toLowerCase(), 'inst');
		precacheList.set(curSong.toLowerCase(), 'voices');

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = Keybinds.fill();

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		ratingsData.push(rating);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray[mania].length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		chartModifier = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');
		playAsGF = ClientPrefs.getGameplaySetting('gfMode', false);//dont do it to yourself its not worth it
		gimmicksAllowed = ClientPrefs.gimmicksAllowed;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camCredit = new FlxCamera();
		camOther = new FlxCamera();
		camFilters = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camCredit.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camFilters.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camCredit, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camFilters, false);
		if (ClientPrefs.starHidden) camHUD.alpha = 0;

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		if(ClientPrefs.shaders){
			camGame.setFilters(filters);
			camGame.filtersEnabled = true;
			camHUD.setFilters(camfilters);
			camHUD.filtersEnabled = true;	
			camOther.setFilters(camfilters);
			camOther.filtersEnabled = true;
			camFilters.setFilters(camfilters);
			camFilters.filtersEnabled = true;
			filters.push(ShadersHandler.chromaticAberration);
			camfilters.push(ShadersHandler.chromaticAberration);
			/*filters.push(ShadersHandler.fuckingTriangle); //this shader has a cool feature for all the wrong reasons >:)
			camfilters.push(ShadersHandler.fuckingTriangle);*/
		}

		camHUD.filtersEnabled = true;
		camGame.filtersEnabled = true;

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		rave = new FlxTypedGroup<FlxSprite>();
		//add(rave);
		for (i in 0...8)
		{
			var light2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('rave/ravelight' + i, 'rave'));
			light2.scrollFactor.set(0, 0);
			light2.cameras = [camHUD];
			light2.visible = false;
			light2.updateHitbox();
			light2.antialiasing = true;
			rave.add(light2);
		}

		try
		{
			metadata = cast Json.parse(Assets.getText(Paths.json(SONG.song.toLowerCase() + '/meta')));
			trace(Assets.getText(Paths.json(SONG.song.toLowerCase() + '/meta')));
			trace(metadata);
			hasMetadataFile = true;
			trace("Found metadata for " + SONG.song.toLowerCase());
		} catch(e) {
			trace("No metadata for " + SONG.song.toLowerCase());
		}

		persistentUpdate = true;
		persistentDraw = true;

		mania = SONG.mania;
		if (mania > Note.maxMania)
			mania = Note.defaultMania;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');
	
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		/*if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}*/

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}

		stageData = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				opponent2: [100, 200],
				hide_girlfriend: false,
			
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_opponent2: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		if (stageData.opponent2 != null)
		{
			DAD2_X = stageData.opponent2[0];
			DAD2_Y = stageData.opponent2[1];
		}

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		if(opponent2CameraOffset != null)
			opponent2CameraOffset = stageData.camera_opponent2;
		else
			opponent2CameraOffset = [0, 0];
		
		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		dadGroup2 = new FlxSpriteGroup(DAD2_X, DAD2_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		whiteBG = new FlxSprite(-480, -480).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		whiteBG.updateHitbox();
		whiteBG.antialiasing = true;
		whiteBG.scrollFactor.set(0, 0);
		whiteBG.active = false;
		//whiteBG.cameras;
		whiteBG.alpha = 0.0;

		blackOverlay = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackOverlay.updateHitbox();
		blackOverlay.screenCenter();
		blackOverlay.antialiasing = true;
		blackOverlay.scrollFactor.set(0, 0);
		blackOverlay.active = false;
		blackOverlay.alpha = 0;
		blackOverlay.setGraphicSize(Std.int(blackOverlay.width * 10.5));

		blackUnderlay = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackUnderlay.updateHitbox();
		blackUnderlay.screenCenter();
		blackUnderlay.antialiasing = true;
		blackUnderlay.scrollFactor.set(0, 0);
		blackUnderlay.active = false;
		blackUnderlay.alpha = 0;
		blackUnderlay.setGraphicSize(Std.int(blackUnderlay.width * 10.5));

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': //Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if(!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		dadbattleSmokes = new FlxSpriteGroup(); //troll'd

		switch(Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(dadGroup2);
		add(boyfriendGroup);

		if (curStage != 'spooky')  //to avoid dups
		{
			halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
			halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
			halloweenWhite.alpha = 0;
			halloweenWhite.blend = ADD;
			add(halloweenWhite);
		}
		
		switch(curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}
			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			if(gfVersion == 'pico-speaker')
			{
				if(!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if(FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

		ghostChar = new Character(0, 0, SONG.player2);
		startCharacterPos(ghostChar, true, true, false);
		dadGroup.add(ghostChar);
		startCharacterLua(ghostChar.curCharacter);
		ghostChar.alpha = 0;

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		if (SONG.player4 != null) 
		{
			dad2 = new Character(0, 0, SONG.player4);
			startCharacterPos(dad2, true);
			dadGroup2.add(dad2);
			startCharacterLua(dad2.curCharacter);
			threeLanes = true;
		}
		else
		{
			dad2 = null;
		}
		
		ghostChar2 = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(ghostChar2, false, true, true);
		boyfriendGroup.add(ghostChar2);
		startCharacterLua(ghostChar2.curCharacter);
		ghostChar2.alpha = 0;
		
		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		if(dad2 != null && dad2.curCharacter.startsWith('gf')) {
			dad2.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		if(ghostChar.curCharacter.startsWith('gf')) {
			ghostChar.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		add(rave);

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);
		}

		addBehindGF(whiteBG);
		addBehindGF(blackUnderlay);

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("FridayNightFunkin.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 4800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(playfields);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		opponentStrums = new FlxTypedGroup<StrumNote>();
		opponentStrums2 = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		modManager = new ModManager(this);
		Modcharts.isModcharted(songName.toLowerCase());
		if (mania == 3 && !threeLanes) 
		{
			allowManagerStuff = true;
		}
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		callOnLuas("prePlayfieldCreation", []);
		playerField = new PlayField(modManager);
		playerField.modNumber = 0;
		playerField.characters = [];
		for(n => ch in boyfriendMap)playerField.characters.push(ch);
		
		playerField.isPlayer = true;
		playerField.autoPlayed = cpuControlled;
		playerField.noteHitCallback = goodNoteHit;

		dadField = new PlayField(modManager);
		dadField.isPlayer = false;
		dadField.autoPlayed = !dadField.isPlayer || cpuControlled;
		dadField.modNumber = 1;
		dadField.characters = [];
		for(n => ch in dadMap)dadField.characters.push(ch);
		dadField.noteHitCallback = opponentNoteHit;

		dad.idleWhenHold = !dadField.isPlayer;
		boyfriend.idleWhenHold = !playerField.isPlayer;

		playfields.add(dadField);
		playfields.add(playerField);

		for(field in playfields)
			initPlayfield(field);

		callOnLuas("postPlayfieldCreation", []);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		if(!playAsGF)
		{
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'health', 0, 2);
			healthBar.scrollFactor.set();
			// healthBar
			healthBar.visible = !ClientPrefs.hideHud;
			healthBar.alpha = ClientPrefs.healthBarAlpha;
			healthBarBG.sprTracker = healthBar;

			healthBar2 = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), if (SONG.player4 != null) Std.int(healthBarBG.height - 13) else Std.int(healthBarBG.height - 8), this,
				'health', 0, 2);
			healthBar2.scrollFactor.set();
			// healthBar
			healthBar2.visible = !ClientPrefs.hideHud;
			healthBar2.alpha = ClientPrefs.healthBarAlpha;
			add(healthBar);
			if (dad2 != null)
				add(healthBar2);

			iconP1 = new HealthIcon(boyfriend.healthIcon, true);
			iconP1.y = healthBar.y - 75;
			iconP1.visible = !ClientPrefs.hideHud;
			iconP1.alpha = ClientPrefs.healthBarAlpha;
			add(iconP1);

			iconP1G = new HealthIcon(boyfriend.healthIcon, true);
			iconP1G.y = healthBar.y - 125;
			iconP1G.visible = !ClientPrefs.hideHud;
			if (ghostChar2 != null)
				iconP1G.alpha = ghostChar2.alpha;
			add(iconP1G);

			iconP2 = new HealthIcon(dad.healthIcon, false);
			iconP2.y = healthBar.y - 75;
			iconP2.visible = !ClientPrefs.hideHud;
			iconP2.alpha = ClientPrefs.healthBarAlpha;
			add(iconP2);

			if (dad2 != null)
			{
				iconP22 = new HealthIcon(dad2.healthIcon, false);
				iconP22.y = healthBar.y - 115;
				iconP22.visible = !ClientPrefs.hideHud;
				iconP22.alpha = ClientPrefs.healthBarAlpha;
				add(iconP22);
			}

			iconP2G = new HealthIcon(dad.healthIcon, false);
			iconP2G.y = healthBar.y - 125;
			iconP2G.visible = !ClientPrefs.hideHud;
			if (ghostChar != null)
				iconP2G.alpha = ghostChar.alpha;
			add(iconP2G);
			reloadHealthBarColors();
		}

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("FridayNightFunkin.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("FridayNightFunkin.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled || playAsGF && cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}
		if(playAsGF)
		{
			botplayTxt.text = "GFPLAY";
			healthBarGF = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, HORIZONTAL_INSIDE_OUT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'healthGF', 0, 2);
			healthBarGF.scrollFactor.set();
			// healthBar
			healthBarGF.visible = !ClientPrefs.hideHud;
			healthBarGF.alpha = ClientPrefs.healthBarAlpha;
			healthBarBG.sprTracker = healthBarGF;
			add(healthBarGF);

			if (gf != null)
			{
				iconGF = new HealthIcon(gf.healthIcon, true);
				iconGF.y = healthBarGF.y - 75;
				iconGF.visible = !ClientPrefs.hideHud;
				iconGF.alpha = ClientPrefs.healthBarAlpha;
				add(iconGF);
			}
			reloadHealthBarColors();
		}
		

		if (!playAsGF)
		{
			playerField.cameras = [camHUD];
			dadField.cameras = [camHUD];
			playfields.cameras = [camHUD];
			strumLineNotes.cameras = [camHUD];
			notes.cameras = [camHUD];
			healthBar.cameras = [camHUD];
			healthBar2.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			iconP1.cameras = [camHUD];
			iconP2.cameras = [camHUD];
			if (dad2 != null)
				iconP22.cameras = [camHUD];
			iconP1G.cameras = [camHUD];
			iconP2G.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
		}
		else
		{
			healthBarGF.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			if (gf != null)
				iconGF.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
		}
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;


		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		
		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			switch (daSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		if (gf != null)
		{
			#if desktop
			// Updating Discord Rich Presence.
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
			#end
		}

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);
		
		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		add(blackOverlay);

		lyrics = new FlxText(0,100,1280,"",32,true);
		lyrics.scrollFactor.set();
		lyrics.cameras = [camOther];
		//lyricsArray = CoolUtil.coolTextFile("assets/data/endless/endlessLyrics.txt");
		lyrics.alignment = FlxTextAlign.CENTER;
		lyrics.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		lyrics.borderSize = 4;
		lyrics.text = '';
		add(lyrics);

		daStatic = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('static');
		daStatic.animation.addByPrefix('static','lestatic',24, false);
		daStatic.animation.play('static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.cameras = [camOther];
		daStatic.alpha = 0;
		add(daStatic);
		daStatic.animation.play('static');
		daStatic.animation.finishCallback = function(pog:String)
		{
			daStatic.animation.play('static');
		}

		daRain = new FlxSprite(0, 0);
		daRain.frames = Paths.getSparrowAtlas('rain');
		daRain.animation.addByIndices('rain','rain tho', [0, 2, 4, 6, 8, 10, 12, 14, 16, 18], "", 24, false);
		daRain.animation.play('rain');
		daRain.setGraphicSize(FlxG.width, FlxG.height);
		daRain.screenCenter();
		daRain.cameras = [camFilters];
		daRain.alpha = 0;
		add(daRain);
		daRain.animation.play('rain');
		daRain.animation.finishCallback = function(pog:String)
		{
			daRain.animation.play('rain');
		}

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	function doStaticSign(lestatic:Int = 0)
	{
		trace ('static Time Number: ' + lestatic );
	
		switch(lestatic)
		{
			case 0:
				daStatic.alpha = 1;
			case 1:
				daStatic.alpha = 0.5;
			case 2:
				daStatic.alpha = 0;

			daStatic.animation.play('static');
			daStatic.animation.finishCallback = function(pog:String)
			{
				daStatic.animation.play('static');
			}
		}
	}

	function doStaticSignFade(lestatictime:Float = 0, lestaticamount:Float = 0)
	{
	
		FlxTween.tween(daStatic, {alpha: lestaticamount}, lestatictime, {ease: FlxEase.expoInOut});

		daStatic.animation.play('static');
		daStatic.animation.finishCallback = function(pog:String)
		{
			daStatic.animation.play('static');
		}
	}
	
	function doThunderstorm(stormType:Int = 0)
	{
		switch(stormType)
		{
			case 0:
				FlxTween.tween(daRain, {alpha: 0.3}, 2, {ease: FlxEase.expoInOut});
				thunderON = false;
			case 1:
				FlxTween.tween(daRain, {alpha: 1}, 2, {ease: FlxEase.expoInOut});
				thunderON = false;
			case 2:
				FlxTween.tween(daRain, {alpha: 1}, 2, {ease: FlxEase.expoInOut});
				thunderON = true;
			case 3:
				FlxTween.tween(daRain, {alpha: 0}, 2, {ease: FlxEase.expoInOut});
				thunderON = false;

			daRain.animation.play('rain');
			daRain.animation.finishCallback = function(pog:String)
			{
				daRain.animation.play('rain');
			}
		}
	}

	function mirror()
		{
			camGame.flashSprite.scaleX *= -1;
			camHUD.flashSprite.scaleX *= -1;
		}

	function upsidedown()
		{
			camGame.flashSprite.scaleY *= -1;
			camHUD.flashSprite.scaleY *= -1;
		}
	function resetcam()
		{
			camGame.flashSprite.scaleY *= 1;
			camHUD.flashSprite.scaleY *= 1;
			camGame.flashSprite.scaleX *= 1;
			camHUD.flashSprite.scaleX *= 1;
		}

	
	public static function randString(Length:Int)
	{
		var string:String = '';
		var data:String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUBWXYZ1234567890';

		for (i in 0...Length)
		{
			string += data.charAt(FlxG.random.int(0, data.length - 1));
		}
		return string;
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end


	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			/* 			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio); */
			for(note in allNotes)note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		if (!playAsGF)
		{
			healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			
			if (dad2 != null) 
			{
				healthBar2.createFilledBar(FlxColor.fromRGB(dad2.healthColorArray[0], dad2.healthColorArray[1], dad2.healthColorArray[2]),
				FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
				healthBar2.updateBar();
			}
			
			healthBar.updateBar();
		}
		else
		{
			if (gf != null)
			{
				healthBarGF.createFilledBar(FlxColor.fromRGB(gf.healthColorArray[0], gf.healthColorArray[1], gf.healthColorArray[2]),
				FlxColor.fromRGB(gf.healthColorArray[0] - 75, gf.healthColorArray[1] - 75, gf.healthColorArray[2] - 75));
			}
			else
			{
				healthBarGF.createFilledBar(FlxColor.fromRGB(255, 0, 0), FlxColor.fromRGB(255 - 75, 0 - 75, 0 - 75));
			}
			healthBarGF.updateBar();
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					if(playerField!=null)
						playerField.characters.push(newBoyfriend);
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					if(dadField!=null)
						dadField.characters.push(newDad);
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
			case 3:
				if(dad2 != null && !dad2Map.exists(newCharacter)) {
					var newDad2:Character = new Character(0, 0, newCharacter);
					newDad2.scrollFactor.set(0.95, 0.95);
					dad2Map.set(newCharacter, newDad2);
					dadGroup2.add(newDad2);
					startCharacterPos(newDad2);
					newDad2.alpha = 0.00001;
					startCharacterLua(newDad2.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}
	
	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false, ?isGhost:Bool = false, ?isBF:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		if (isGhost)
		{
			if (isBF) char.x += char.positionArray[0] + 200 else char.x += char.positionArray[0] - 200;
			if (isBF) char.y += char.positionArray[1] - 20 else char.y += char.positionArray[1];
		}
		else
		{
			char.x += char.positionArray[0];
			char.y += char.positionArray[1];
		}
	}


	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		//inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true);
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var startTimer2:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			if (allowManagerStuff)
			{
				callOnLuas('preReceptorGeneration', []);
				playerField.generateStrums(0);
				dadField.generateStrums(1);
				/*for(field in playfields.members)
					field.generateStrums();*/

				callOnLuas('postReceptorGeneration', []);
				for(field in playfields.members)
					field.fadeIn(isStoryMode || skipArrowStartTween); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode
				modManager.receptors = [playerField.strumNotes, dadField.strumNotes];
				callOnLuas('preModifierRegister', []);
				modManager.registerDefaultModifiers();
				callOnLuas('postModifierRegister', []);
			}
			else
			{
				generateStaticArrows(0);
				generateStaticArrows(1);
			}
			if (threeLanes) generateStaticArrows(2);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}
			if (threeLanes)
			{
				for (i in 0...opponentStrums2.length) {
					setOnLuas('defaultOpponent2StrumX' + i, opponentStrums2.members[i].x);
					setOnLuas('defaultOpponent2StrumY' + i, opponentStrums2.members[i].y);
					//if(ClientPrefs.middleScroll) opponentStrums2.members[i].visible = false;
				}
			}
			
			if (allowManagerStuff)
			{
				modManager.receptors = [playerStrums.members, opponentStrums.members];
				callOnLuas('preModifierRegister', []);
				modManager.registerDefaultModifiers();
				callOnLuas('postModifierRegister', []);
				//Modcharts.loadModchart(modManager, SONG.song);

			}

			startedCountdown = true;
			countActive = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}


			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}
				if (dad2 != null)
				{
					if (tmr.loopsLeft % dad2.danceEveryNumBeats == 0 && dad2.animation.curAnim != null && !dad2.animation.curAnim.name.startsWith('sing') && !dad2.stunned)
					{
						dad2.dance();
					}
				}
				if (ghostChar != null)
				{
					if (tmr.loopsLeft % ghostChar.danceEveryNumBeats == 0 && ghostChar.animation.curAnim != null && !ghostChar.animation.curAnim.name.startsWith('sing') && !ghostChar.stunned)
					{
						ghostChar.alpha = 0;
						ghostChar.dance();
					}
				}
				if (ghostChar2 != null)
				{
					if (tmr.loopsLeft % ghostChar2.danceEveryNumBeats == 0 && ghostChar2.animation.curAnim != null && !ghostChar2.animation.curAnim.name.startsWith('sing') && !ghostChar2.stunned)
					{
						ghostChar2.alpha = 0;
						ghostChar2.dance();
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {y: countdownReady.y + 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {y: countdownSet.y + 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {y: countdownGo.y + 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						if (ClientPrefs.starHidden) FlxTween.tween(camHUD, {alpha: 1}, 5, {ease: FlxEase.circOut});
					case 4:
						if (chartModifier == '4K Only' && Note.ammo[mania] == 4) changeMania(0, true);
						countActive = false;
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function startCountdownPause():Void
	{
		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdownPause', []);
		if(ret != FunkinLua.Function_Stop && !countActive) {
			startedCountdown = false;
			setOnLuas('startedPauseCountdown', true);
			callOnLuas('onPauseCountdownStarted', []);
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			var swagCounter2:Int = 0;

			
			startTimer2 = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}
				if (dad2 != null)
				{
					if (tmr.loopsLeft % dad2.danceEveryNumBeats == 0 && dad2.animation.curAnim != null && !dad2.animation.curAnim.name.startsWith('sing') && !dad2.stunned)
					{
						dad2.dance();
					}
				}
				if (ghostChar != null)
				{
					if (tmr.loopsLeft % ghostChar.danceEveryNumBeats == 0 && ghostChar.animation.curAnim != null && !ghostChar.animation.curAnim.name.startsWith('sing') && !ghostChar.stunned)
					{
						ghostChar.alpha = 0;
						ghostChar.dance();
					}
				}
				if (ghostChar2 != null)
				{
					if (tmr.loopsLeft % ghostChar2.danceEveryNumBeats == 0 && ghostChar2.animation.curAnim != null && !ghostChar2.animation.curAnim.name.startsWith('sing') && !ghostChar2.stunned)
					{
						ghostChar2.alpha = 0;
						ghostChar2.dance();
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter2)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {y: countdownReady.y + 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {y: countdownSet.y + 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {y: countdownGo.y + 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
						startedCountdown = true;
						if (FlxG.sound.music != null)
						{
							resyncVocals();
						}
				}

				callOnLuas('onCountdownTick', [swagCounter2]);

				swagCounter2 += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{

		var i:Int = allNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = allNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.ignoreNote = true;
				if (modchartObjects.exists('note${daNote.ID}'))
					modchartObjects.remove('note${daNote.ID}');
				for (field in playfields)
					field.removeNote(daNote);




			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		if (!playAsGF)
		{
			scoreTxt.text = 'Score: ' + songScore
			+ ' | Misses: ' + songMisses
			+ ' | Rating: ' + ratingName
			+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');
		}
		else
		{
			scoreTxt.text = 'Combo: ' + gfBopCombo
			+ ' | Highest Combo: ' + gfBopComboBest
			+ ' | Misses: ' + gfMisses;
		}

		if(ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
		{
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		}
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		Conductor.songPosition += savedTime;
		trace("Saved Time:" + savedTime);
		if (savedTime != 0)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			Conductor.songPosition += savedTime;
			trace("Saved Time:");
			trace(savedTime);
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime > Conductor.songPosition-1000 && daNote.strumTime < Conductor.songPosition+1000) {
					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
			for (i in 0...unspawnNotes.length) {
				var daNote:Note = unspawnNotes[0];
				if(daNote.strumTime + 1200 >= Conductor.songPosition) {
					break;
				}

				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
				daNote.destroy();
			}

			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();

			vocals.time = Conductor.songPosition;
			vocals.play();	
		}

		/*if (!isStoryMode && playbackRate == 1)
		{
			for (i in 0...unspawnNotes.length + 1)
			{
				var daNote:Note = unspawnNotes[i];
				if (daNote != null && daNote.strumTime > 1000)
				{
					needSkip = true;
					skipTo = daNote.strumTime - 1000;
				}
				else
				{
					needSkip = false;
				}
			}
			
		}*/

		FlxG.sound.music.time = Conductor.songPosition;
		FlxG.sound.music.play();

		vocals.time = Conductor.songPosition;
		vocals.play();

		if (needSkip)
		{
			skipActive = true;
			skipText = new FlxText(healthBarBG.x + 80, healthBarBG.y - 110, 500);
			skipText.text = "Press Space to Skip Intro";
			skipText.size = 30;
			skipText.color = FlxColor.WHITE;
			skipText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
			skipText.cameras = [camHUD];
			skipText.alpha = 0;
			FlxTween.tween(skipText, {alpha: 1}, 0.2);
			add(skipText);
		}
		else
		{
			if (skipText != null) FlxTween.tween(skipText, {alpha: 0}, 0.2);
		}

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		if (!playAsGF)
		{
			#if desktop
			// Updating Discord Rich Presence (with Time Left)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter(), true, songLength);
			#end
		}
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	var stair:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}


		for(i in 0...songData.mania + 1)
			notesToSpawn[i] = [];

		trace('KYS: ' + notesToSpawn);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % Note.ammo[mania]);
				var gottaHitNote:Bool = section.mustHitSection;
				if (songNotes[1] > mania)
				{
					gottaHitNote = !section.mustHitSection;
				}
				switch (chartModifier)
				{
					case "Random":
						daNoteData = FlxG.random.int(0, mania);

					case "Flip":
						if (gottaHitNote)
						{
							daNoteData = mania - Std.int(songNotes[1] % Note.ammo[mania]);
						}

					case "4K Only":
						daNoteData = daNoteData - Std.int(songNotes[1] % Note.ammo[mania]);

					case "Stairs":
						daNoteData = stair % Note.ammo[mania];
						stair++;

					case "Wave":
						/*var stairway:String = 'left';

						if (stairway == 'left')
						{
							trace('left');
							daNoteData = stair;
							stair++;
							if (stair % Note.ammo[mania] == 0 && stairway == 'left')
							{stairway = 'right';}
						}
						else if (stairway == 'right')
						{
							trace('right');
							daNoteData = stair;
							stair++;
							if (stair % Note.ammo[mania] == 2 && stairway == 'right')
							{stairway = 'left';}			
						}*/

						var ammoFromFortnite:Int = Note.ammo[mania];
						var luigiSex:Int = (ammoFromFortnite * 2 - 2);
						var marioSex:Int = stair++ % luigiSex;

						if (marioSex < ammoFromFortnite) {
							daNoteData = marioSex;
						} else {
							daNoteData = luigiSex - marioSex;
						}

					case "What":
						switch (stair % (2 * Note.ammo[mania]))
						{
							case 0:
								daNoteData = FlxG.random.int(0, mania);
							case 1:
								if (gottaHitNote)
								{
									daNoteData = mania - Std.int(songNotes[1] % Note.ammo[mania]);
								}
							case 2:
								daNoteData = daNoteData - Std.int(songNotes[1] % Note.ammo[mania]);
							case 3:
								daNoteData = stair % Note.ammo[mania];
								stair++;
							case 4:
								daNoteData = stair % Note.ammo[mania];


							default:
								daNoteData = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);

						}
						stair++;
				}
				var oldNote:Note;
				if (allNotes.length > 0)
					oldNote = allNotes[Std.int(allNotes.length - 1)];
				else
					oldNote = null;
				
				var type:Dynamic = songNotes[3];
				var swagNote:Note; //TODO: get third character noteskin strums working
				if (gottaHitNote)
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false);
				else
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
				swagNote.exNote = (section.exSection && (songNotes[1] < Note.ammo[mania]));
				swagNote.noteType = songNotes[3];
				swagNote.mania = mania;
				if (swagNote.gfNote || section.gfSection)
				{
					playAsGF = false;
				}
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;
				susLength = susLength / Conductor.stepCrochet;
				swagNote.ID = allNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				//unspawnNotes.push(swagNote);
				

				notesToSpawn[swagNote.noteData].push(swagNote);

				if(swagNote.fieldIndex==-1 && swagNote.field==null)
					swagNote.field = swagNote.mustPress ? playerField : dadField;

				if(swagNote.field!=null)
					swagNote.fieldIndex = playfields.members.indexOf(swagNote.field);


				var playfield:PlayField = playfields.members[swagNote.fieldIndex];

				if (playfield!=null){
					playfield.queue(swagNote); // queues the note to be spawned
					allNotes.push(swagNote); // just for the sake of convenience
				}else{
					swagNote.destroy();
					continue;
				}

				/*#if LUA_ALLOWED
				if(swagNote.noteScript != null && swagNote.noteScript.scriptType == 'lua'){
					callScript(swagNote.noteScript, 'setupNote', [
						allNotes.indexOf(swagNote),
						Math.abs(swagNote.noteData),
						swagNote.noteType,
						swagNote.isSustainNote,
						swagNote.ID
					]);
				}
				#end*/

				var floorSus:Int = Math.floor(susLength);
				var type = 0;

				if (floorSus > 0)
				{
					if (ClientPrefs.inputSystem == 'Kade Engine')
						swagNote.isParent = true;
					for (susNote in 0...floorSus)
					{
						oldNote = allNotes[Std.int(allNotes.length - 1)];

						var sustainNote:Note;
						if (gottaHitNote)
						{
							sustainNote = new Note(daStrumTime 
								+ (Conductor.stepCrochet * susNote) 
								+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), 
								daNoteData, oldNote, true, false);
						}
						else
						{
							sustainNote = new Note(daStrumTime 
								+ (Conductor.stepCrochet * susNote) 
								+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), 
								daNoteData, oldNote, true, false);
						}

						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < Note.ammo[mania]));
						sustainNote.exNote = (section.exSection && (songNotes[1] < Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.ID = allNotes.length;
						//modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						//sustainNote.startPos = calculateStrumtime(sustainNote, daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)));
						swagNote.tail.push(sustainNote);
						swagNote.unhitTail.push(sustainNote);
						sustainNote.parent = swagNote;
						sustainNote.fieldIndex = swagNote.fieldIndex;
						playfield.queue(sustainNote);
						allNotes.push(sustainNote);
						notesToSpawn[swagNote.noteData].push(sustainNote);
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1)
							{
								// Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
						if (ClientPrefs.inputSystem == 'Kade Engine')
						{ 
							// if fireable ever plays this
							sustainNote.parent = swagNote;
							swagNote.tail.push(sustainNote);
							sustainNote.spotInLine = type;
							type++;
						}
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width * 0.5; // general offset
						} 
					}
				}
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width * 0.5; // general offset
				}
				else if (ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		allNotes.sort(sortByShit);

		for(fuck in allNotes)
			unspawnNotes.push(fuck);
		
		for (field in playfields.members)
		{
			var goobaeg:Array<Note> = [];
			for(column in field.noteQueue){
				if(column.length>=2){
					for(nIdx in 1...column.length){
						var last = column[nIdx-1];
						var current = column[nIdx];
						if(last==null || current==null)continue;
						if(last.isSustainNote || current.isSustainNote)continue; // holds only get fukt if their parents get fukt
						if(!last.alive || !current.alive)continue; // just incase
						if (Math.abs(last.strumTime - current.strumTime) <= Conductor.stepCrochet / (192 / 16)){
							if(last.sustainLength < current.sustainLength) // keep the longer hold
								field.removeNote(last);
							else{
								current.kill();
								goobaeg.push(current); // mark to delete after, cant delete here because otherwise it'd fuck w/ stuff	
							}
						}

					}
				}
			}
			for(note in goobaeg)
				field.removeNote(note);

		}

		#if(LUA_ALLOWED && PE_MOD_COMPATIBILITY)
		for(key => script in notetypeScripts){
			if(script.scriptType == 'lua')
				script.call("onCreate");
			
		}
		#end

		//unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	public inline function getVisualPosition()
		return getTimeFromSV(Conductor.songPosition, songSpeed);

	public inline function getTimeFromSV(time:Float, event:Float)
		return modManager.getVisPos(songTime) + (modManager.getBaseVisPosD(time - Conductor.songPosition, 1) * event);

	public function getNoteInitialTime(time:Float)
	{
		return getTimeFromSV(time, songSpeed);
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					case 'dad2' | 'opponent2' | '2':
						charType = 3;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				if (curStage == 'philly') // Can you tell which i did first :)
					insert(members.indexOf(phillyStreet), blammedLightsBlack);
				else
					insert(members.indexOf(gfGroup) - 1, blammedLightsBlack);

				if (curStage == 'philly') // to make sure its ACTUALLY philly
				{
					phillyWindowEvent = new BGSprite('window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);
				}


				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);

			case 'Rave Mode':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				if (curStage == 'philly') // Can you tell which i did first :)
					insert(members.indexOf(phillyStreet), blammedLightsBlack);
				else
					insert(members.indexOf(gfGroup) - 1, blammedLightsBlack);

				if (curStage == 'philly') // to make sure its ACTUALLY philly
				{
					phillyWindowEvent = new BGSprite('window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);
				}


				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
	
	function sortByOrderNote(wat:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	function sortByOrderStrumNote(wat:Int, Obj1:StrumNote, Obj2:StrumNote):Int
	{
		return FlxSort.byValues(FlxSort.DESCENDING, Obj1.zIndex, Obj2.zIndex);
	}
		
	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
/* 		var targetAlpha:Float = 1;
		if (player < 1){
			if(!ClientPrefs.opponentStrums) targetAlpha = 0;
			else if(ClientPrefs.middleScroll) targetAlpha = 0.35;
		}

		for (i in 0...4){
			var babyArrow:StrumNote = new StrumNote(
				ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X,
				ClientPrefs.downScroll ? FlxG.height - 162 : 50,
				i
			);

			babyArrow.downScroll = ClientPrefs.downScroll;

			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width * 0.5 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		} */
	}

	function updateNote(note:Note)
	{
		var tMania:Int = mania + 1;
		var noteData:Int = note.noteData;

		note.scale.set(1, 1);
		note.updateHitbox();

		/*
		if (!isPixelStage) {
			note.setGraphicSize(Std.int(note.width * Note.noteScales[mania]));
			note.updateHitbox();
		} else {
			note.setGraphicSize(Std.int(note.width * daPixelZoom * (Note.noteScales[mania] + 0.3)));
			note.updateHitbox();
		}
		*/

		// Like reloadNote()

		var lastScaleY:Float = note.scale.y;
		if (isPixelStage) {
			//if (note.isSustainNote) {note.originalHeightForCalcs = note.height;}

			note.setGraphicSize(Std.int(note.width * daPixelZoom * Note.pixelScales[mania]));
		} else {
			// Like loadNoteAnims()

			note.setGraphicSize(Std.int(note.width * Note.scales[mania]));
			note.updateHitbox();
		}

		if (note.isSustainNote) {note.scale.y = lastScaleY;}
		note.updateHitbox();

		// Like new()

		var prevNote:Note = note.prevNote;
		
		if (note.isSustainNote && prevNote != null) {
			
			note.offsetX += note.width / 2;

			note.animation.play(Note.keysShit.get(mania).get('letters')[noteData] + ' tail');

			note.updateHitbox();

			note.offsetX -= note.width / 2;

			if (note != null && prevNote != null && prevNote.isSustainNote && prevNote.animation != null) { // haxe flixel
				prevNote.animation.play(Note.keysShit.get(mania).get('letters')[noteData % tMania] + ' hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				prevNote.scale.y *= songSpeed;

				if(isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / note.height);
				}

				prevNote.updateHitbox();
				//trace(prevNote.scale.y);
			}
			
			if (isPixelStage){
				prevNote.scale.y *= daPixelZoom * (Note.pixelScales[mania]); //Fuck urself
				prevNote.updateHitbox();
			}
		} else if (!note.isSustainNote && noteData > - 1 && noteData < tMania) {
			if (note.changeAnim) {
				var animToPlay:String = '';

				animToPlay = Note.keysShit.get(mania).get('letters')[noteData % tMania];
				
				note.animation.play(animToPlay);
			}
		}

		// Like set_noteType()

		if (note.changeColSwap) {
			var hsvNumThing = Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData % tMania]);
			var colSwap = note.colorSwap;

			colSwap.hue = ClientPrefs.arrowHSV[hsvNumThing][0] / 360;
			colSwap.saturation = ClientPrefs.arrowHSV[hsvNumThing][1] / 100;
			colSwap.brightness = ClientPrefs.arrowHSV[hsvNumThing][2] / 100;
		}
	}


	public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false)
	{
		//funny dissapear transitions
		//while new strums appear
		var daOldMania = mania;
				
		mania = newValue;
		if (!skipStrumFadeOut) {
			for (i in 0...strumLineNotes.members.length) {
				var oldStrum:FlxSprite = strumLineNotes.members[i].clone();
				oldStrum.x = strumLineNotes.members[i].x;
				oldStrum.y = strumLineNotes.members[i].y;
				oldStrum.alpha = strumLineNotes.members[i].alpha;
				oldStrum.scrollFactor.set();
				oldStrum.cameras = [camHUD];
				oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[daOldMania]));
				oldStrum.updateHitbox();
				add(oldStrum);
	
				FlxTween.tween(oldStrum, {alpha: 0}, 0.3 / playbackRate, {onComplete: function(_) {
					remove(oldStrum);
				}});
			}
		}

		playerStrums.clear();
		opponentStrums.clear();
		if (threeLanes) opponentStrums2.clear();
		strumLineNotes.clear();
		setOnLuas('mania', mania);

		notes.forEachAlive(function(note:Note) {updateNote(note);});

		for (noteI in 0...unspawnNotes.length) {
			var note:Note = unspawnNotes[noteI];

			updateNote(note);
		}

		callOnLuas('onChangeMania', [mania, daOldMania]);

		generateStaticArrows(0);
		generateStaticArrows(1);
		if (threeLanes) generateStaticArrows(2);
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (startTimer2 != null && !startTimer2.finished)
				startTimer2.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			paused = false;

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad, dad2];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			callOnLuas('onResume', []);
			startCountdownPause();

			if (gf != null)
			{
				#if desktop
				if (startTimer != null && startTimer.finished)
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
				}
				#end
			}
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (gf != null)
		{
			#if desktop
			if (health > 0 && !paused)
			{
				if (Conductor.songPosition > 0.0)
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
				}
			}
			#end
		}

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		if (gf != null)
		{
			#if desktop
			if (health > 0 && !paused)
			{
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
			}
			#end
		}

		super.onFocusLost();
	}

	// good to call this whenever you make a playfield
	public function initPlayfield(field:PlayField){
		field.noteRemoved.add((note:Note, field:PlayField) -> {
			if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
			allNotes.remove(note);
			unspawnNotes.remove(note);
			notes.remove(note);
		});
		field.noteMissed.add((daNote:Note, field:PlayField) -> {
			if (field.isPlayer && !field.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
				noteMiss(daNote);

		});
		field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
			callOnLuas('onSpawnNote', [dunceNote]);
			#if LUA_ALLOWED
			callOnLuas('onSpawnNote', [
				allNotes.indexOf(dunceNote),
				dunceNote.noteData,
				dunceNote.noteType,
				dunceNote.isSustainNote
			]);
			#end

			notes.add(dunceNote);
			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);

			callOnLuas('onSpawnNotePost', [dunceNote]);
			if (dunceNote.noteScript != null)
			{
				var script:FunkinScript = dunceNote.noteScript;

				#if LUA_ALLOWED
				if (script.scriptType == 'lua')
				{
					callOnLuas('postSpawnNote', [
						notes.members.indexOf(dunceNote),
						Math.abs(dunceNote.noteData),
						dunceNote.noteType,
						dunceNote.isSustainNote,
						dunceNote.ID
					]);
				}
				else
				#end
				callOnLuas("postSpawnNote", [dunceNote]);
			}
		});
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var countActive:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;
	var alreadyChanged:Bool = false;
	var camResize:Float = 0;

	function die():Void
	{
		bfkilledcheck = true;
		doDeathCheck(true);
		health = 0;
		noteMissPress(3); //just to make sure you actually die
	}

	function updateThirdStrum() 
	{
		if (SONG.player4 != null) //god this was annoying
		{
			for (i in Note.ammo[mania] * 2...Note.ammo[mania] * 2 + Note.ammo[mania]) //4kaaa
			{
				if (strumLineNotes.members[i] != null)
				{
					strumLineNotes.members[i].scrollFactor.x = 1;
					strumLineNotes.members[i].scrollFactor.y = 1;
					strumLineNotes.members[i].downScroll = false;
					strumLineNotes.members[i].cameras = [camGame];
					strumLineNotes.members[i].x = dad2.x + if (Note.ammo[mania] == 4) (112*(i%Note.ammo[mania])) - 25 else (66.5*(i%Note.ammo[mania])) - 75;
					strumLineNotes.members[i].y = dad2.y + dad2.height - if (dad2.strumOffset != dad2.defStrumOffset) dad2.strumOffset else 220;
					strumLineNotes.members[i].downScroll = ClientPrefs.downScroll;
					if (ClientPrefs.middleScroll)
						strumLineNotes.members[i].alpha = 0.35;
					if (ClientPrefs.downScroll)
						strumLineNotes.members[i].y = dad2.y + dad2.height + if (dad2.strumOffsetDown != dad2.defStrumOffsetDown) dad2.strumOffsetDown else -420;
				}
				
			}
			for (i in unspawnNotes)
			{
				if (i.exNote)
				{
					i.cameras = [camGame];
					i.scrollFactor.x = 1;
					i.scrollFactor.y = 1;
					for (note in notes) note.mania = mania;
					for (note in unspawnNotes) note.mania = mania;
					//i.x = Std.int(strumLineNotes.members[i].x);
				}
			}
			for (i in notes)
			{
				if (i.exNote)
				{
					i.cameras = [camGame];
					i.scrollFactor.x = 1;
					i.scrollFactor.y = 1;
					for (note in notes) note.mania = mania;
					for (note in unspawnNotes) note.mania = mania;
					//i.x = Std.int(strumLineNotes.members[i].x);
				}
			}
		}
	}

	var didntPress:Bool = false;

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}

		if(phillyGlowParticles != null)
		{
			var i:Int = phillyGlowParticles.members.length-1;
			while (i > 0)
			{
				var particle = phillyGlowParticles.members[i];
				if(particle.alpha < 0)
				{
					particle.kill();
					phillyGlowParticles.remove(particle, true);
					particle.destroy();
				}
				--i;
			}
		}

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}
		if (strumFocus)
		{
			if (SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
			{	
				for (i in 0...playerStrums.length) {
					FlxTween.tween(playerStrums.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums.length) {
					FlxTween.tween(opponentStrums.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums2.length) {
					FlxTween.tween(opponentStrums2.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
			}
			else if (!SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
			{	
				for (i in 0...playerStrums.length) {
					FlxTween.tween(playerStrums.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums.length) {
					FlxTween.tween(opponentStrums.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums2.length) {
					FlxTween.tween(opponentStrums2.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
			}
			else if (threeLanes && !SONG.notes[curSection].mustHitSection && SONG.notes[curSection].exSection)
			{	
				for (i in 0...playerStrums.length) {
					FlxTween.tween(playerStrums.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums.length) {
					FlxTween.tween(opponentStrums.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums2.length) {
					FlxTween.tween(opponentStrums2.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				}
			}
		}
		else if (startingSong)
		{
			for (i in 0...playerStrums.length) {
				FlxTween.tween(playerStrums.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
			}
			for (i in 0...opponentStrums.length) {
				FlxTween.tween(opponentStrums.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
			}
			for (i in 0...opponentStrums2.length) {
				FlxTween.tween(opponentStrums2.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
			}
		}


		if (cpuControlled && !alreadyChanged && !playAsGF)
		{
			botplayTxt.color = FlxColor.RED;
			botplayTxt.visible = true;
			scoreTxt.visible = false;
			alreadyChanged = true;
			switch (FlxG.random.int(1, 7))
			{
				case 1:
					botplayTxt.text = "CHEATER'S NEVER PROSPER";
				case 2:
					botplayTxt.text = "NOT COOL, DUDE.";
				case 3:
					botplayTxt.text = "Z11 KNOWS YOU'RE CHEATING RIGHT NOW.";
				case 4:
					botplayTxt.text = "SMH. I THOUGHT YOU WERE BETTER.";
				case 5:
					botplayTxt.text = "YOU BOT";
				case 6:
					botplayTxt.text = "SHADOWMARIO KNOWS YOU'RE CHEATING RIGHT NOW.";
				case 7:
					botplayTxt.text = "POV: SONG TOO HARD";
			}
		}
		else if (!cpuControlled && alreadyChanged && !playAsGF)
		{
			botplayTxt.color = FlxColor.fromInt(CoolUtil.dominantColor(iconP2));
			scoreTxt.visible = true;
			botplayTxt.visible = false;
			switch (FlxG.random.int(1, 7))
			{
				case 1:
					botplayTxt.text = "CHEATER'S NEVER PROSPER";
				case 2:
					botplayTxt.text = "NOT COOL, DUDE.";
				case 3:
					botplayTxt.text = "Z11 KNOWS YOU'RE CHEATING RIGHT NOW.";
				case 4:
					botplayTxt.text = "SMH. I THOUGHT YOU WERE BETTER.";
				case 5:
					botplayTxt.text = "YOU BOT";
				case 6:
					botplayTxt.text = "SHADOWMARIO KNOWS YOU'RE CHEATING RIGHT NOW.";
				case 7:
					botplayTxt.text = "POV: SONG TOO HARD";
			}
			alreadyChanged = false;
		}
		else if (playAsGF)
		{
			botplayTxt.color = Std.parseInt("0xFFFF0000");
			scoreTxt.visible = true;
			botplayTxt.visible = true;
			botplayTxt.text = "GFPLAY";
		}
		else if (playAsGF && cpuControlled)
		{
			botplayTxt.color = FlxColor.fromInt(CoolUtil.dominantColor(iconP2));
			scoreTxt.visible = true;
			botplayTxt.visible = true;
			botplayTxt.text = "GFPLAY\n(What song are you playing that you can't tap to the beat?)";
		}

		if (!playAsGF)
		{
			if (ghostChar2 != null)
				iconP1G.alpha = ghostChar2.alpha;
			if (ghostChar != null)
				iconP2G.alpha = ghostChar.alpha;
		}

		if (ghostChar != null)
		{
			if (ghostChar.alpha == 0.7 && (ghostChar.animation.curAnim.finished || ghostChar.animation.curAnim.name == 'idle' && !ghostChar.specialAnim || ghostChar.curCharacter == 'shaggy')) /*|| ghostChar.curCharacter == 'shaggy'))*/ //i wont resort to this yet...
			{
				charFade = FlxTween.tween(ghostChar, {alpha: 0}, 0.2, {ease: FlxEase.sineOut});
			}
			if (ghostChar.animation.curAnim.name != 'idle' && ghostChar.animation.curAnim.name.startsWith('sing') || !ghostChar.animation.curAnim.name.startsWith('dance') && ghostChar.animation.curAnim.name.startsWith('sing'))
			{
				charFade = null;
				ghostChar.alpha = 0.7;
			}
		}
		if (ghostChar2 != null)
		{
			if (ghostChar2.alpha == 0.7 && (ghostChar2.animation.curAnim.finished || ghostChar2.animation.curAnim.name == 'idle' && !ghostChar2.specialAnim))
			{
				charFade2 = FlxTween.tween(ghostChar2, {alpha: 0}, 0.2, {ease: FlxEase.sineOut});
			}
			if (ghostChar2.animation.curAnim.name != 'idle')
			{
				charFade2 = null;
				ghostChar2.alpha = 0.7;
			}
		}

		switch (curStage)
		{
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		rotRateSh = curStep / 9.5;
		var sh_toy = -Math.sin(rotRateSh * 2) * sh_r * 0.45;
		var sh_tox = -Math.cos(rotRateSh) * sh_r;

		if (fly)
		{
			dad2.x += (sh_tox - dad2.x) / 12;
			dad2.y += (sh_toy - dad2.y) / 12;
			if (ghostChar != null)
			{
				ghostChar.x += (sh_tox - ghostChar.x) / 12;
				ghostChar.y += (sh_toy - ghostChar.y) / 12;
			}
			if (dad2.animation.name == 'idle')
			{
				var pene = 0.07;
				dad2.angle = Math.sin(rotRateSh) * sh_r * pene / 4;
				if (ghostChar != null)
					ghostChar.angle = Math.sin(rotRateSh) * sh_r * pene / 4;
			}
			else
			{
				dad2.angle = 0;
				if (ghostChar != null)
					ghostChar.angle = 0;
				sh_r = 600;
			}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if (!playAsGF)
		{
			if(ratingName == '?') {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
			} else {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
			}
		}
		else
		{
			scoreTxt.text = 'Combo: ' + gfBopCombo + ' | Highest Combo: ' + gfBopComboBest + ' | Misses: ' + gfMisses;
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();
					}
					openSubState(new PauseSubStateLost(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				}
				else if (playAsGF)
				{
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();	
					}
					openSubState(new PauseSubState(gf.getScreenPosition().x, gf.getScreenPosition().y));
				}
				else {
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();
					}
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				}
		
				if (gf != null)
				{
					#if desktop
					DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
					#end
				}
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		if (!playAsGF)
		{
			var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();

			var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();

			if (dad2 != null) 
			{
				var mult:Float = FlxMath.lerp(1, iconP22.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP22.scale.set(mult, mult);
				iconP22.updateHitbox();
			}

			var mult:Float = FlxMath.lerp(1, iconP1G.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP1G.scale.set(mult, mult);
			iconP1G.updateHitbox();

			var mult:Float = FlxMath.lerp(1, iconP2G.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP2G.scale.set(mult, mult);
			iconP2G.updateHitbox();

			var iconOffset:Int = 26;

			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			if (dad2 != null)
				iconP22.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP22.scale.x) / 2 - iconOffset * 4;
			iconP1G.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1G.scale.x - 150) / 2 - iconOffset + 100;
			iconP2G.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2G.scale.x) / 2 - iconOffset * 2 - 100;

			iconP1G.animation.curAnim.curFrame = iconP1.animation.curAnim.curFrame;
			iconP2G.animation.curAnim.curFrame = iconP2.animation.curAnim.curFrame;
			if (dad2 != null)
				iconP22.animation.curAnim.curFrame = iconP2.animation.curAnim.curFrame;

			if (healthBar.percent < 20)
				iconP1.animation.curAnim.curFrame = 1;
			else
				iconP1.animation.curAnim.curFrame = 0;

			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else
				iconP2.animation.curAnim.curFrame = 0;
		}
		else
		{
			if (gf != null)
			{
				var mult:Float = FlxMath.lerp(1, iconGF.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconGF.scale.set(mult, mult);
				iconGF.updateHitbox();
				iconGF.x = healthBarGF.getGraphicMidpoint().x - 50;

				if (healthBarGF.percent < 20)
					iconGF.animation.curAnim.curFrame = 1;
				else
					iconGF.animation.curAnim.curFrame = 0;
			}
		}

		if (playAsGF)
		{
			if (gf != null)
			{
																//this part is here for latency reasons 
																//(cuz some people dont have rhythm)
				if (((curStep % 16 / gfSpeed == 0 || curStep % 16 / gfSpeed  == 8) || (curStep % 16 / gfSpeed  == 1 || curStep % 16 / gfSpeed  == 9) || (curStep % 16 / gfSpeed  == 2 || curStep % 16 / gfSpeed  == 10)) && gf.animation.curAnim.name != null && gf.animation.curAnim.name == 'danceLeft')
				{
					if (FlxG.keys.justPressed.LEFT)
					{
						goodGFBop();
					}
				}
				else if (((curStep % 16 / gfSpeed  == 4 || curStep % 16 / gfSpeed  == 12) || (curStep % 16 / gfSpeed  == 5 || curStep % 16 / gfSpeed  == 13) || (curStep % 16 / gfSpeed  == 6 || curStep % 16 / gfSpeed  == 14)) && gf.animation.curAnim.name != null && gf.animation.curAnim.name == 'danceRight')
				{
					if (FlxG.keys.justPressed.RIGHT)
					{
						goodGFBop();
					}
				}
				if ((((curStep % 16 / gfSpeed  == 0 || curStep % 16 / gfSpeed  == 8) || (curStep % 16 / gfSpeed  == 1 || curStep % 16 / gfSpeed  == 9) || (curStep % 16 / gfSpeed  == 2 || curStep % 16 / gfSpeed  == 10)) && gf.animation.curAnim.name != null && gf.animation.curAnim.name == 'danceLeft' && !didLastBeat) 
					|| (((curStep % 16 / gfSpeed  == 4 || curStep % 16 / gfSpeed  == 12) || (curStep % 16 / gfSpeed  == 5 || curStep % 16 / gfSpeed  == 13) || (curStep % 16 / gfSpeed  == 6 || curStep % 16 / gfSpeed  == 14)) && gf.animation.curAnim.name != null && gf.animation.curAnim.name == 'danceRight' && !didLastBeat))
				{
					if (!didntPress)
					{
						didntPress = true;
					}
				}

				if (!((curStep % 16 / gfSpeed  == 0 || curStep % 16 == 8) || (curStep % 16 / gfSpeed  == 1 || curStep % 16 / gfSpeed  == 9)) && gf.animation.curAnim.name != null && gf.animation.curAnim.name == 'danceLeft')
				{
					if (FlxG.keys.justPressed.LEFT)
					{
						badGFBop();
					}
				}
				else if (!((curStep % 16 / gfSpeed  == 4 || curStep % 16 / gfSpeed == 12) || (curStep % 16 / gfSpeed  == 5 || curStep % 16 / gfSpeed  == 13)) && gf.animation.curAnim.name != null && gf.animation.curAnim.name == 'danceRight')
				{
					if (FlxG.keys.justPressed.RIGHT)
					{
						badGFBop();
					}
				}
			}
			else
			{
																//this part is here for latency reasons 
																//(cuz some people dont have rhythm)
				if (((curStep % 16 / gfSpeed == 0 || curStep % 16 / gfSpeed  == 8) || (curStep % 16 / gfSpeed  == 1 || curStep % 16 / gfSpeed  == 9) || (curStep % 16 / gfSpeed  == 2 || curStep % 16 / gfSpeed  == 10)))
				{
					if (FlxG.keys.justPressed.LEFT)
					{
						goodGFBop();
					}
				}
				else if (((curStep % 16 / gfSpeed  == 4 || curStep % 16 / gfSpeed  == 12) || (curStep % 16 / gfSpeed  == 5 || curStep % 16 / gfSpeed  == 13) || (curStep % 16 / gfSpeed  == 6 || curStep % 16 / gfSpeed  == 14)))
				{
					if (FlxG.keys.justPressed.RIGHT)
					{
						goodGFBop();
					}
				}
				if ((((curStep % 16 / gfSpeed  == 0 || curStep % 16 / gfSpeed  == 8) || (curStep % 16 / gfSpeed  == 1 || curStep % 16 / gfSpeed  == 9) || (curStep % 16 / gfSpeed  == 2 || curStep % 16 / gfSpeed  == 10)) && !didLastBeat) 
					|| (((curStep % 16 / gfSpeed  == 4 || curStep % 16 / gfSpeed  == 12) || (curStep % 16 / gfSpeed  == 5 || curStep % 16 / gfSpeed  == 13) || (curStep % 16 / gfSpeed  == 6 || curStep % 16 / gfSpeed  == 14)) && !didLastBeat))
				{
					if (!didntPress)
					{
						didntPress = true;
					}
				}

				if (!((curStep % 16 / gfSpeed  == 0 || curStep % 16 == 8) || (curStep % 16 / gfSpeed  == 1 || curStep % 16 / gfSpeed  == 9)))
				{
					if (FlxG.keys.justPressed.LEFT)
					{
						badGFBop();
					}
				}
				else if (!((curStep % 16 / gfSpeed  == 4 || curStep % 16 / gfSpeed == 12) || (curStep % 16 / gfSpeed  == 5 || curStep % 16 / gfSpeed  == 13)))
				{
					if (FlxG.keys.justPressed.RIGHT)
					{
						badGFBop();
					}
				}
			}
		}

		if (health > 2)
			health = 2;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
            LoadingState.loadAndSwitchState(new CharacterEditorState(SONG.player2), true);
		}

		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (skipActive && Conductor.songPosition >= skipTo)
		{
			remove(skipText);
			skipActive = false;
		}

		if (FlxG.keys.justPressed.SPACE && skipActive)
		{
			clearNotesBefore(skipTo);
			FlxG.sound.music.pause();
			vocals.pause();
			Conductor.songPosition = skipTo;

			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();

			vocals.time = Conductor.songPosition;
			vocals.play();
			FlxTween.tween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength * playbackRate);

					var songCalc:Float = (songLength - curTime  * playbackRate);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000  * playbackRate);
					if(secondsTotal < 0) secondsTotal = 0;

					if (ClientPrefs.timeBarType != 'Song Name')
					{
						if (modifitimer == 0 && !endingSong)
							timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
					}
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (chromOn){
		
			ch = FlxG.random.int(1,5) / 1000;
			ch = FlxG.random.int(1,5) / 1000;
			ShadersHandler.setChrome(ch);
			ShadersHandler.setTriangleX(ch);
			ShadersHandler.setTriangleY(ch);
			//ShadersHandler.setRadialBlur(640+(FlxG.random.int(-100,100)),360+(FlxG.random.int(-100,100)),FlxG.random.float(0.001,0.005));
			//ShadersHandler.setRadialBlur(640+(FlxG.random.int(-10,10)),360+(FlxG.random.int(-10,10)),FlxG.random.float(0.001,0.005));
		}else{
			if (!beatchrom)
			{
				ShadersHandler.setChrome(0);
			}
			//ShadersHandler.setRadialBlur(0,0,0);
			ShadersHandler.setTriangleX(0);
			ShadersHandler.setTriangleY(0);
			
		}

		if (chromCheck > 0 && (dad.animation.curAnim.name == 'idle' || dad2 != null && dad2.animation.curAnim.name == 'idle'))
		{
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				FlxTween.tween(ShadersHandler, {setChrome: 0}, 1, {ease: FlxEase.circOut});
				FlxTween.tween(chromCheck, {value: 0}, 1, {ease: FlxEase.circOut});
			});
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		if (beatchrom)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			ShadersHandler.setChrome(0.1 * abrrmult);
			beatchromfaster = false;
			beatchromfastest = false;
			beatchromslow = false;
		}
		else if (beatchromfaster)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			ShadersHandler.setChrome(0.1 * abrrmult);
			beatchrom = false;
			beatchromfastest = false;
			beatchromslow = false;
		}
		else if (beatchromfastest)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			ShadersHandler.setChrome(0.1 * abrrmult);
			beatchrom = false;
			beatchromfaster = false;
			beatchromslow = false;
		}
		else if (beatchromslow)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			ShadersHandler.setChrome(0.1 * abrrmult);
			beatchrom = false;
			beatchromfaster = false;
			beatchromfastest = false;
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		daStatic.animation.play('static');

		Conductor.visualPosition = getVisualPosition();
		FlxG.watch.addQuick("visualPos", Conductor.visualPosition);


		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();
		if (allowManagerStuff)
		{
			modManager.updateTimeline(curDecStep);
			modManager.update(elapsed);
		}

		/*for(column in notesToSpawn){
			if(column[0]!=null){
				var time:Float = (modManager.getValue("noteSpawnTime", 0) + modManager.getValue("noteSpawnTime", 1)) / 2;
				if (songSpeed < 1)
					time /= songSpeed;
				while (column.length > 0 && column[0].strumTime - Conductor.songPosition < time / ((column[0].multSpeed<1) ? column[0].multSpeed : 1))
				{
					var dunceNote:Note = column[0];
					notes.insert(0, dunceNote);
					dunceNote.spawned = true;
					callOnLuas('onSpawnNote', [
						notes.members.indexOf(dunceNote),
						dunceNote.noteData,
						dunceNote.noteType,
						dunceNote.isSustainNote
					]);

					unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
					unspawnNotes.splice(column.indexOf(dunceNote), 1);

				}
			}
		}*/
		/*if (allowManagerStuff)
		{
			if(unspawnNotes[0]!=null){
				var time:Float = (modManager.getValue("noteSpawnTime", 0) + modManager.getValue("noteSpawnTime", 1)) / 2;
				if (songSpeed < 1)
					time /= songSpeed;
				while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
				{
					var dunceNote:Note = unspawnNotes[0];
					notes.insert(0, dunceNote);
					dunceNote.spawned = true;
					callOnLuas('onSpawnNote', [
						notes.members.indexOf(dunceNote),
						dunceNote.noteData,
						dunceNote.noteType,
						dunceNote.isSustainNote
					]);

					unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
					//unspawnNotes.splice(column.indexOf(dunceNote), 1);

				}
			}
		}
		else
		{
			if (unspawnNotes[0] != null)
			{
				var time:Float = spawnTime;
				if(songSpeed < 1) time /= songSpeed;
				if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
	
				while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
				{
					var dunceNote:Note = unspawnNotes[0];
					notes.insert(0, dunceNote);
					dunceNote.spawned=true;
					callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);
	
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
				}
			}
		}*/

		updateThirdStrum();

		/*if (allowManagerStuff)
		{
			opponentStrums.forEachAlive(function(strum:StrumNote)
			{
				var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 1, strum, [], strum.vec3Cache);
				modManager.updateObject(curDecBeat, strum, pos, 1);
				strum.x = pos.x;
				strum.y = pos.y;
				strum.z = pos.z;
			});

			if (SONG.player4 != null) //god this was REALLY annoying
			{
				opponentStrums2.forEachAlive(function(strum:StrumNote)
				{
					var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 1, strum, [], strum.vec3Cache);
					modManager.updateObject(curDecBeat, strum, pos, 1);
					strum.x = pos.x;
					strum.y = pos.y;
					strum.z = pos.z;
				});
			}

			playerStrums.forEachAlive(function(strum:StrumNote)
			{
				var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 0, strum, [], strum.vec3Cache);
				modManager.updateObject(curDecBeat, strum, pos, 0);
				strum.x = pos.x;
				strum.y = pos.y;
				strum.z = pos.z;
			});

			strumLineNotes.sort(sortByOrderStrumNote);
		}*/

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled || !playAsGF) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				} else if(ghostChar2 != null && ghostChar2.holdTimer > Conductor.stepCrochet * 0.001 * ghostChar2.singDuration && ghostChar2.animation.curAnim.name.startsWith('sing') && !ghostChar2.animation.curAnim.name.endsWith('miss')) {
					ghostChar2.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.sort(sortByOrderNote);
			notes.forEachAlive(function(daNote:Note)
			{
				if (mania != SONG.mania && !daNote.isSustainNote)
				{
					daNote.applyManiaChange();
				}

				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress && (!daNote.exNote || !SONG.notes[curSection].exSection)) strumGroup = opponentStrums;
				if(!daNote.mustPress && (daNote.exNote || SONG.notes[curSection].exSection)) strumGroup = opponentStrums2;
				/*if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}*/

				var roundedSpeed:Float = FlxMath.roundDecimal(songSpeed, 2);

				// i am so fucking sorry for this if condition
				var strumX:Float = 0;
				var strumY:Float = 0;
				var strumAngle:Float = 0;
				var strumAlpha:Float = 0;
				var strumHeight:Float = 0;
				var strumDirection:Float = 0;
				var strumScroll:Bool = false;
				if (daNote.mustPress && (!daNote.exNote || !SONG.notes[curSection].exSection))
				{
					if (playerStrums.members[daNote.noteData] == null)
						daNote.noteData = mania; // crash prevention ig?

					strumX = playerStrums.members[daNote.noteData].x;
					strumY = playerStrums.members[daNote.noteData].y;
					strumAngle = playerStrums.members[daNote.noteData].angle;
					strumDirection = playerStrums.members[daNote.noteData].direction;
					strumAlpha = playerStrums.members[daNote.noteData].alpha;
					strumHeight = playerStrums.members[daNote.noteData].height;
					strumScroll = playerStrums.members[daNote.noteData].downScroll;
				}
				else if ((daNote.exNote || SONG.notes[curSection].exSection) && threeLanes)
				{
					if (opponentStrums2.members[daNote.noteData] == null)
						daNote.noteData = mania;

					strumX = opponentStrums2.members[daNote.noteData].x;
					strumY = opponentStrums2.members[daNote.noteData].y;
					strumAngle = opponentStrums2.members[daNote.noteData].angle;
					strumDirection = opponentStrums2.members[daNote.noteData].direction;
					strumAlpha = opponentStrums2.members[daNote.noteData].alpha;
					strumHeight = opponentStrums2.members[daNote.noteData].height;
					strumScroll = opponentStrums2.members[daNote.noteData].downScroll;
				}
				else
				{
					if (opponentStrums.members[daNote.noteData] == null)
						daNote.noteData = mania;

					strumX = opponentStrums.members[daNote.noteData].x;
					strumY = opponentStrums.members[daNote.noteData].y;
					strumAngle = opponentStrums.members[daNote.noteData].angle;
					strumDirection = opponentStrums.members[daNote.noteData].direction;
					strumAlpha = opponentStrums.members[daNote.noteData].alpha;
					strumHeight = opponentStrums.members[daNote.noteData].height;
					strumScroll = opponentStrums.members[daNote.noteData].downScroll;
				}

				strumScroll = ClientPrefs.downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				if (allowManagerStuff)
				{
				
					var pN:Int = daNote.mustPress ? 0 : 1;
					var pos = modManager.getPos(daNote.strumTime, modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed),
						curDecBeat, daNote.noteData, pN, daNote, [], daNote.vec3Cache);

					if (!freezeNotes)
					{
						modManager.updateObject(curDecBeat, daNote, pN);
						pos.x += daNote.offsetX;
						pos.y += daNote.offsetY;
						daNote.x = pos.x;
						daNote.y = pos.y;
						daNote.z = pos.z;
						if (daNote.isSustainNote)
						{
							var futureSongPos = Conductor.songPosition + 75;
							var diff = daNote.strumTime - futureSongPos;
							var vDiff = modManager.getVisPos(futureSongPos, daNote.strumTime, songSpeed);

							var nextPos = modManager.getPos(vDiff, diff, Conductor.getStep(futureSongPos) / 4, daNote.noteData, pN, daNote, [],
								daNote.vec3Cache);
							nextPos.x += daNote.offsetX;
							nextPos.y += daNote.offsetY;
							var diffX = (nextPos.x - pos.x);
							var diffY = (nextPos.y - pos.y);
							var rad = Math.atan2(diffY, diffX);
							var deg = rad * (180 / Math.PI);
							if (deg != 0)
								daNote.mAngle = (deg + 90);
							else
								daNote.mAngle = 0;
						}
					}
				}
				else
				{
					var center:Float = strumY + strumHeight / 2;

					if(!freezeNotes){
						if (strumScroll) //Downscroll
						{
							//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
							daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
						}
						else //Upscroll
						{
							//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
							daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
						}
					}

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if(daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if(daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if (daNote.copyY && !freezeNotes)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if(strumScroll && daNote.isSustainNote && ClientPrefs.inputSystem != 'Kade Engine')
						{
							if (daNote.animation.curAnim.name.endsWith('end')) {
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if(PlayState.isPixelStage) {
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
								} else {
									daNote.y -= 19;
								}
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
						}
					}
				}
				

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if (daNote.mustPress && (cpuControlled || playAsGF))
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit)
						{
							goodNoteHit(daNote);
						}
					}
					else if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress))
					{
						goodNoteHit(daNote);
					}
				}
				
				if(daNote.garbage){
					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}else{
					if (Conductor.songPosition > noteKillOffset + daNote.strumTime && daNote.active)
					{
						if (daNote.mustPress && !cpuControlled && !playAsGF && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						{
							noteMiss(daNote);
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
			});
		}
		checkEventNote();
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		setOnLuas('playingAsGF', playAsGF);
		callOnLuas('onUpdatePost', [elapsed]);
		#if sys
		for (shader in animatedShaders)
		{
			shader.update(elapsed);
		}
		#end
		for (i in shaderUpdates)
		{
			i(elapsed);
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		LoadingState.loadAndSwitchState(new ChartingState(), true);
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && bfkilledcheck || playAsGF && healthGF <= 0)
		{
			savedTime = 0;
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				if (gf != null)
				{
					#if desktop
					// Game Over doesn't get his own variable because it's only used here
					DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
					#end
				}
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if(val == null) val = 0;

				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val == 1) //enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if(val > 2) who = boyfriend;
						//2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							dadbattleSmokes.visible = false;
						}});
				}

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							if (curStage == 'philly') phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							if (curStage == 'philly') phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							if (curStage == 'philly') phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						if (curStage == 'philly')phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						if (curStage == 'philly')phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.x = val1;
						camFollow.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Set Game Cam Zoom and angle':
				var var1:Float = Std.parseFloat(value1);
				var var2:Float = Std.parseFloat(value2);
				if (Math.isNaN(var1))
					var1 = 0;
				if (Math.isNaN(var2))
					var2 = 0;

				if (!Math.isNaN(Std.parseFloat(value1)))
				{
					FlxTween.tween(camGame, {zoom: var1}, 0.5, {ease: FlxEase.expoIn});
					// camGame.zoom = var1;
					if (var2 != 0)
						camZooming = true;
					else
						camZooming = false;
				}

				if (!Math.isNaN(Std.parseFloat(value2)))
				{
					FlxTween.tween(camGame, {angle: var2}, 0.5, {ease: FlxEase.expoIn});
					// camGame.angle = var2;
				}

			case 'Set hud Cam Zoom and angle':
				var var1:Float = Std.parseFloat(value1);
				var var2:Float = Std.parseFloat(value2);
				if (Math.isNaN(var1))
					var1 = 0;
				if (Math.isNaN(var2))
					var2 = 0;

				if (!Math.isNaN(Std.parseFloat(value1)))
				{
					FlxTween.tween(camHUD, {zoom: var1}, 0.5, {ease: FlxEase.expoIn});
					// camHUD.zoom = var1;
					if (var2 != 0)
						camZooming = true;
					else
						camZooming = false;
				}

				if (!Math.isNaN(Std.parseFloat(value2)))
				{
					FlxTween.tween(camHUD, {angle: var2}, 0.5, {ease: FlxEase.expoIn});
					// camHUD.angle = var2;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
							iconGF.changeIcon(gf.healthIcon);
						}
				}
				reloadHealthBarColors();

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}
			
			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;

				newMania = Std.parseInt(value1);
				if(Math.isNaN(newMania) && newMania < Note.minMania && newMania > Note.maxMania)
					newMania = 0;
				changeMania(newMania, skipTween);	

			case 'Super Burst':
				powerup();

			case 'Burst Dad':
				burstRelease(dad.getMidpoint().x - 1000, dad.getMidpoint().y - 100);
			
			case 'Burst Dad 2':
				burstRelease(dad2.getMidpoint().x - 1000, dad2.getMidpoint().y - 100);

			case 'Switch Scroll':
				daAnswer(value1);

			case 'Dad Fly':
				daAnswer2(value1);

			case 'Turn on StrumFocus':
				strumFocus = true;

			case 'Turn off StrumFocus':
				strumFocus = false;

			case 'Fade Out':
				FlxTween.tween(blackUnderlay, {alpha: 1}, Std.parseFloat(value1));
				FlxTween.tween(camHUD, {alpha: 0}, Std.parseFloat(value1));

			case 'Fade In':
				FlxTween.tween(blackUnderlay, {alpha: 1}, Std.parseFloat(value1));
				FlxTween.tween(camHUD, {alpha: 0}, Std.parseFloat(value1));

			case 'Silhouette':
				theShadow(value1);

			case 'Save Song Posititon':
				trace(Conductor.songPosition);
				savedTime = Conductor.songPosition;
				savedBeat = curBeat;
				savedStep = curStep;

			case 'False Timer':
				modifitimer = Std.parseInt(value1);
				FlxTween.num(modifitimer, 0, Std.parseFloat(value2), {ease: FlxEase.elasticInOut});

			case 'Chromatic Aberration':
				why(value1);
				defMult = 0.0 + Std.parseFloat(value1);
				if (value1 == '' || value1 == null)
				{
					defMult = 0.04;
				}

			case 'Move Window':
				var val1:Int = Std.parseInt(value1);
				var val2:Int = Std.parseInt(value2);
				if(Math.isNaN(val1)) val1 = winX;
				if(Math.isNaN(val2)) val2 = winY;
				Lib.application.window.move(winX + val1, winY + val2);

			case 'Spin Notes':
				strumLineNotes.forEach(function(tospin:FlxSprite)
				{
					FlxTween.angle(tospin, 0, 360, 0.2, {ease: FlxEase.quintOut});
				});

			case 'Static':
				if (value1 == 'true' || value1 == 'True' || value1 == 'on' || value1 == 'On' )
				{
					doStaticSign(Std.parseInt(value2));
					daStatic.alpha == 1;
				}
				else
				{
					daStatic.alpha == 0;
				}
				if (value2 == '' || value2 == null)
				{
					doStaticSign(3);
					daStatic.alpha == 0;
				}
			case 'Static Fade':
				doStaticSignFade(Std.parseFloat(value1), Std.parseFloat(value2));

			case 'Thunderstorm Trigger':
				if (value1 == '' || value1 == null)
				{
					doThunderstorm(3);
					daRain.alpha == 0;
				}
				else
				{
					doThunderstorm(Std.parseInt(value1));
				}

			case 'Rave Mode':
				if (ClientPrefs.flashing)
				{
					switch (value1)
					{
						case '0':
							ravemode = false;
							ravemodeV2 = false;
							doPhilly(0);
							doSpotlight(0);
						case '1':
							ravemode = true;
							ravemodeV2 = false;
							doPhilly(0);
							doSpotlight(0);
						case '2':
							ravemode = true;
							ravemodeV2 = false;
							doSpotlight(1);
						case '3':
							doPhilly(1);
							ravemode = true;
							ravemodeV2 = false;
						case '4':
							doSpotlight(1);
							doPhilly(1);
							ravemode = true;
							ravemodeV2 = false;
						case '5':
							ravemode = false;
							ravemodeV2 = true;
							doPhilly(0);
							doSpotlight(0);
						case '6':
							ravemode = false;
							ravemodeV2 = true;
							doSpotlight(1);
						case '7':
							doPhilly(1);
							ravemode = false;
							ravemodeV2 = true;
						case '8':
							doSpotlight(1);
							doPhilly(1);
							ravemode = false;
							ravemodeV2 = true;
					}
				}

				if (Std.string(value2) == 'A')
				{
					autoBotsRollOut = true;
				}
				else
				{
					autoBotsRollOut = false;
				}

			case 'gfScared':
				var newValue:Bool = false;
				if(value1.toLowerCase()=="true")
					newValue = true;
				gfScared = newValue;

			case 'Freeze Notes':
				if (value1 == 'true' || value1 == 'True')
				{
					freezeNotes = true;
				}
				else
				{
					freezeNotes = false;
				}

			case 'Funnie Window Tween':
				var split:Array<String> = value1.split(',');
				var val1:Int = Std.parseInt(split[0]);
				var val2:Int = Std.parseInt(split[1]);
				if(Math.isNaN(val1)) val1 = winX;
				if(Math.isNaN(val2)) val2 = winY;
				if (gimmicksAllowed) FlxTween.tween(openfl.Lib.application.window, { x: winX + Std.int(val1), y: winY + Std.int(val2) }, Std.parseInt(value2), {ease: FlxEase.quadInOut });

			case 'Chrom Beat Effect':
				if (gimmicksAllowed)
				{
					if (value1.toLowerCase() == 'slow') 
					{
						beatchrom = true;
						beatchromfaster = false;
						beatchromfastest = false;
						beatchromslow = false;
					}
					else if (value1.toLowerCase() == 'fast') 
					{
						beatchromfaster = true;
						beatchrom = false;
						beatchromfastest = false;
						beatchromslow = false;
					}
					else if (value1.toLowerCase() == 'faster') 
					{
						beatchromfastest = true;
						beatchrom = false;
						beatchromfaster = false;
						beatchromslow = false;
					}
					else if (value1.toLowerCase() == 'slower') 
					{
						beatchromslow = true;
						beatchrom = false;
						beatchromfaster = false;
						beatchromfastest = false;
					}
					else
					{
						beatchrom = false;
						beatchromslow = false;
						beatchromfaster = false;
						beatchromfastest = false;
					}
					defMult = 0.0 + Std.parseFloat(value2);
					if (value2 == '' || value2 == null)
					{
						defMult = 0.06;
					}
				}

			case 'Change Lyric':
				lyrics.text = value1;
				var split:Array<String> = value2.split(',');
				var color:String = split[0];
				var effect:String = split[1];
				if (split[0] != null)
					colorSwitch(split[0].trim());
				if (split[1] != null)
					effectSwitch(split[1].trim());
				if (color == null || color == '')
					colorSwitch('white');
				if (effect == null || effect == '')
					effectSwitch('none');
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function doSpotlight(whichChar:Int)
	{
		var val:Null<Int> = whichChar;
		if(val == null) val = 0;

		switch(whichChar)
		{
			case 1, 2, 3: //enable and target dad
				if(val == 1) //enable
				{
					dadbattleLight.visible = true;
					dadbattleSmokes.visible = true;
					blammedLightsBlack.visible = true;
					isActiveRN = true;
				}

				var who:Character = dad;
				if(val > 2) who = boyfriend;
				//2 only targets dad
				dadbattleLight.alpha = 0;
				new FlxTimer().start(0.12, function(tmr:FlxTimer) {
					dadbattleLight.alpha = 0.375;
				});
				dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

				dadbattleLight.color = publicColor;
				dadbattleSmokes.color = publicColor;

			default:
				dadbattleLight.visible = false;
				blammedLightsBlack.visible = false;
				FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
				{
					dadbattleSmokes.visible = false;
				}});
				isActiveRN = false;
		}
	}

	var publicColor:FlxColor = FlxColor.WHITE;

	function doPhilly(whichFill:Int)
	{
		var lightId:Int = whichFill;
		if(Math.isNaN(lightId)) lightId = 0;

		var doFlash:Void->Void = function() {
			var color:FlxColor = FlxColor.WHITE;
			if(!ClientPrefs.flashing) color.alphaFloat = 0.5;
			publicColor = color;
			FlxG.camera.flash(color, 0.15, null, true);
		};

		var chars:Array<Character> = [boyfriend, gf, dad];
		switch(lightId)
		{
			case 0:
				if(phillyGlowGradient.visible)
				{
					doFlash();
					if(ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.5;
						camHUD.zoom += 0.1;
					}

					blammedLightsBlack.visible = false;
					if (curStage == 'philly') phillyWindowEvent.visible = false;
					phillyGlowGradient.visible = false;
					phillyGlowParticles.visible = false;
					curLightEvent = -1;

					for (who in chars)
					{
						who.color = FlxColor.WHITE;
					}
					if (curStage == 'philly') phillyStreet.color = FlxColor.WHITE;
				}

			case 1: //turn on
				curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
				var color:FlxColor = phillyLightsColors[curLightEvent];

				if(!phillyGlowGradient.visible)
				{
					doFlash();
					if(ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.5;
						camHUD.zoom += 0.1;
					}

					blammedLightsBlack.visible = true;
					blammedLightsBlack.alpha = 1;
					if (curStage == 'philly') phillyWindowEvent.visible = true;
					phillyGlowGradient.visible = true;
					phillyGlowParticles.visible = true;
				}
				else if(ClientPrefs.flashing)
				{
					var colorButLower:FlxColor = color;
					colorButLower.alphaFloat = 0.25;
					FlxG.camera.flash(colorButLower, 0.5, null, true);
				}

				var charColor:FlxColor = color;
				if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
				else charColor.saturation *= 0.75;

				for (who in chars)
				{
					who.color = charColor;
				}
				phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
				{
					particle.color = color;
				});
				phillyGlowGradient.color = color;
				if (curStage == 'philly')phillyWindowEvent.color = color;

				color.brightness *= 0.5;
				if (curStage == 'philly')phillyStreet.color = color;

			case 2: // spawn particles
				if(!ClientPrefs.lowQuality)
				{
					var particlesNum:Int = FlxG.random.int(8, 12);
					var width:Float = (2000 / particlesNum);
					var color:FlxColor = phillyLightsColors[curLightEvent];
					for (j in 0...3)
					{
						for (i in 0...particlesNum)
						{
							var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
							phillyGlowParticles.add(particle);
						}
					}
				}
				phillyGlowGradient.bop();
		}
	}

	function why(convertedvalue:String)
	{
		if (gimmicksAllowed)
		{
			if (convertedvalue == 'On' || convertedvalue == 'on')
			{
				chromOn = true;
			}
			else
			{
				chromOn = false;
			}
		}
	}

	function theShadow(convertedvalue:String)
	{
		if (gimmicksAllowed)
		{
			if (convertedvalue == 'black' || convertedvalue == 'Black')
			{
				FlxTween.tween(whiteBG, {alpha: 1}, 0.1);
				FlxTween.tween(blackOverlay, {alpha: 0}, 0.1);
				if (dad2 != null) FlxTween.tween(dad2, {color: FlxColor.BLACK}, 0.1);
				if (gf != null) FlxTween.tween(gf, {color: FlxColor.BLACK}, 0.1);
				FlxTween.tween(dad, {color: FlxColor.BLACK}, 0.1);
				FlxTween.tween(boyfriend, {color: FlxColor.BLACK}, 0.1);
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				//boyfriend.color = FlxColor.BLACK;
				//gf.color = FlxColor.BLACK;
				//dad.color = FlxColor.BLACK;
			}
			else if (convertedvalue == 'white' || convertedvalue == 'White')
			{
				FlxTween.tween(blackOverlay, {alpha: 1}, 0.1);
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1);
				if (dad2 != null) FlxTween.tween(dad2, {color: 0xecffffff}, 0.1);
				if (gf != null) FlxTween.tween(gf, {color: 0xecffffff}, 0.1);
				FlxTween.tween(dad, {color: 0xecffffff}, 0.1);
				FlxTween.tween(boyfriend, {color: 0xecffffff}, 0.1);
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				//boyfriend.color = 0xffffffff;
				//gf.color = 0xffffffff;
				//dad.color = 0xffffffff;
			}
			else
			{
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1);
				FlxTween.tween(blackOverlay, {alpha: 0}, 0.1);
				if (dad2 != null) FlxTween.tween(dad2, {color: FlxColor.WHITE}, 0.1);
				if (gf != null) FlxTween.tween(gf, {color: FlxColor.WHITE}, 0.1);
				FlxTween.tween(dad, {color: FlxColor.WHITE}, 0.1);
				FlxTween.tween(boyfriend, {color: FlxColor.WHITE}, 0.1);
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				//boyfriend.color = FlxColor.WHITE;
				//gf.color = FlxColor.WHITE;
				//dad.color = FlxColor.WHITE;
			}
		}
	}

	public function colorSwitch(daColor:String):Void
	{
		switch (daColor)
		{
			case 'red':
				lyrics.color = FlxColor.RED;
			case 'blue':
				lyrics.color = FlxColor.BLUE;
			case 'green':
				lyrics.color = FlxColor.GREEN;
			case 'white':
				lyrics.color = FlxColor.WHITE;
		}
	}

	public function effectSwitch(daEffect:String):Void
	{
		switch (daEffect)
		{
			case 'none':
				lyrics.alpha = 1;
			case 'fadeout':
				FlxTween.tween(lyrics, {alpha: 0}, 1, {ease: FlxEase.expoIn});
			case 'fadein':
				FlxTween.tween(lyrics, {alpha: 1}, 1, {ease: FlxEase.expoIn});
		}
	}

	function daAnswer(ans:String)
	{
		if (ans == 'true' || ans == 'True' || ans == 'TRUE')
		{
			forceChange(true);
		}
		else
		{
			forceChange(false);
		}
	}

	function daAnswer2(ans:String)
	{
		if (ans == 'true' || ans == 'True' || ans == 'TRUE')
		{
			fly = true;
		}
		else
		{
			fly = false;
		}
	}

	function powerup()
	{
		var curDadPos:String = "dad";
		var curDad:Character = dad;
		if (!SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
		{
			curDadPos = "dad";
			curDad = dad;
		}
		else if (!SONG.notes[curSection].mustHitSection && SONG.notes[curSection].exSection || SONG.notes[curSection].mustHitSection && SONG.notes[curSection].exSection)
		{
			curDadPos = "dad2";
			curDad = dad2;
		}
		else
		{
			curDadPos = "bf";
			curDad = boyfriend;
		}
		new FlxTimer().start(0.008, function(ct:FlxTimer)
		{
			switch (cutTime)
			{
				case 0:
					camFollow.x = dad.getMidpoint().x - 100;
					camFollow.y = dad.getMidpoint().y;
				case 15:
					dad.playAnim('powerup');
				case 48:
					dad.playAnim('idle_s');
					burst = new FlxSprite(-1110, 0);
					FlxG.sound.play(Paths.sound('burst'));
					remove(burst);
					burst = new FlxSprite(curDad.getMidpoint().x - 1000, curDad.getMidpoint().y - 100);
					burst.frames = Paths.getSparrowAtlas('characters/shaggy');
					burst.animation.addByPrefix('burst', "burst", 30);
					burst.animation.play('burst');
					//burst.setGraphicSize(Std.int(burst.width * 1.5));
					burst.antialiasing = true;
					add(burst);

					FlxG.sound.play(Paths.sound('powerup'), 1);
					triggerEventNote("Alt Idle Animation", curDadPos, "-alt");
				case 62:
					burst.y = 0;
					remove(burst);
				case 95:
					FlxG.camera.angle = 0;
			}

			var ssh:Float = 45;
			var stime:Float = 30;
			var corneta:Float = (stime - (cutTime - ssh)) / stime;

			if (cutTime % 6 >= 3)
			{
				corneta *= -1;
			}
			if (cutTime >= ssh && cutTime <= ssh + stime)
			{
				FlxG.camera.angle = corneta * 5;
			}
			cutTime ++;
			ct.reset(0.008);
		});
	}

	public function burstRelease(bX:Float, bY:Float)
	{
		FlxG.sound.play(Paths.sound('burst'));
		remove(burst);
		burst = new FlxSprite(bX - 1000, bY - 100);
		burst.frames = Paths.getSparrowAtlas('shaggy');
		burst.animation.addByPrefix('burst', "burst", 30);
		burst.animation.play('burst');
		//burst.setGraphicSize(Std.int(burst.width * 1.5));
		burst.antialiasing = true;
		add(burst);
		new FlxTimer().start(0.5, function(rem:FlxTimer)
		{
			remove(burst);
		});
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (dad2 != null && SONG.notes[curSection].exSection)
		{
			moveCamera(false, true);
			callOnLuas('onMoveCamera', ['dad2']);
		}
		else if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
			if (isActiveRN) doSpotlight(2);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
			if (isActiveRN) doSpotlight(3);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool, ?isDad2:Bool = false)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else if(isDad2)
		{
			camFollow.set(dad2.getMidpoint().x + 150, dad2.getMidpoint().y - 100);
			camFollow.x += dad2.cameraPosition[0] + opponent2CameraOffset[0];
			camFollow.y += dad2.cameraPosition[1] + opponent2CameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	var daEnding:String;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		savedTime = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end
		
		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore && !cpuControlled && !playAsGF)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				if (!cpuControlled && !playAsGF)
				{
					campaignScore += songScore;
					campaignMisses += songMisses;
				}

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore && !playAsGF)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(allNotes.length > 0) {
			var daNote:Note = allNotes[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			// daNote.destroy();
		}
		allNotes = [];
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);
		
		for (i in 0...10) {
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(!practiceMode && !cpuControlled && !playAsGF) {
			songScore += score;

			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];
			
			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}


	var closestNotes:Array<Note> = [];
	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !playAsGF && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				switch (ClientPrefs.inputSystem)
				{
					case 'Native':
						//more accurate hit time for the ratings?
						var lastTime:Float = Conductor.songPosition;
						Conductor.songPosition = FlxG.sound.music.time;

						var canMiss:Bool = !ClientPrefs.ghostTapping;

						// heavily based on my own code LOL if it aint broke dont fix it
						var pressNotes:Array<Note> = [];
						//var notesDatas:Array<Int> = [];
						var notesStopped:Bool = false;

						var sortedNotesList:Array<Note> = [];
						notes.forEachAlive(function(daNote:Note)
						{
							if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
							{
								if(daNote.noteData == key)
								{
									sortedNotesList.push(daNote);
									//notesDatas.push(daNote.noteData);
								}
								canMiss = true;
							}
						});
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							for (epicNote in sortedNotesList)
							{
								for (doubleNote in pressNotes) {
									if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
										doubleNote.kill();
										notes.remove(doubleNote, true);
										doubleNote.destroy();
									} else
										notesStopped = true;
								}
									
								// eee jack detection before was not super good
								if (!notesStopped) {
									goodNoteHit(epicNote);
									pressNotes.push(epicNote);
								}

							}
						}
						else if (canMiss) {
							noteMissPress(key);
							callOnLuas('noteMissPress', [key]);
						}

						// I dunno what you need this for but here you go
						//									- Shubs

						// Shubs, this is for the "Just the Two of Us" achievement lol
						//									- Shadow Mario
						keysPressed[key] = true;

						//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
						Conductor.songPosition = lastTime;
					case "Beat Engine":
						if (!boyfriend.stunned && generatedMusic && !endingSong)
						{
							// more accurate hit time for the ratings?
							var lastTime:Float = Conductor.songPosition;
							Conductor.songPosition = FlxG.sound.music.time;

							var canMiss:Bool = !ClientPrefs.ghostTapping;

							// heavily based on my own code LOL if it aint broke dont fix it
							var pressNotes:Array<Note> = [];
							// var notesDatas:Array<Int> = [];
							var notesStopped:Bool = false;

							var sortedNotesList:Array<Note> = [];
							notes.forEachAlive(function(daNote:Note)
							{
								if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
								{
									if (daNote.noteData == key)
									{
										sortedNotesList.push(daNote);
										// notesDatas.push(daNote.noteData);
									}
									canMiss = true;
								}
							});
							sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

							if (sortedNotesList.length > 0)
							{
								for (epicNote in sortedNotesList)
								{
									for (doubleNote in pressNotes)
									{
										if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
										{
											//if(modchartObjects.exists('note${doubleNote.ID}'))modchartObjects.remove('note${doubleNote.ID}');
											doubleNote.kill();
											notes.remove(doubleNote, true);
											doubleNote.destroy();
										}
										else
											notesStopped = true;
									}

									// eee jack detection before was not super good
									if (!notesStopped)
									{
										goodNoteHit(epicNote);
										pressNotes.push(epicNote);
									}
								}
							}
							else if (canMiss)
							{
								noteMissPress(key);
								callOnLuas('noteMissPress', [key]);
							}

							// I dunno what you need this for but here you go
							//									- Shubs

							// Shubs, this is for the "Just the Two of Us" achievement lol
							//									- Shadow Mario
							keysPressed[key] = true;

							// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
							Conductor.songPosition = lastTime;
						}
					case 'OS Engine':
						if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
						{
							if(!boyfriend.stunned && generatedMusic && !endingSong)
							{
								//more accurate hit time for the ratings?
								var lastTime:Float = Conductor.songPosition;
								Conductor.songPosition = FlxG.sound.music.time;
				
								var canMiss:Bool = !ClientPrefs.ghostTapping;
				
								// heavily based on my own code LOL if it aint broke dont fix it
								var pressNotes:Array<Note> = [];
								//var notesDatas:Array<Int> = [];
								var notesStopped:Bool = false;
				
								var sortedNotesList:Array<Note> = [];
								notes.forEachAlive(function(daNote:Note)
								{
									if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
									{
										if(daNote.noteData == key)
										{
											sortedNotesList.push(daNote);
											//notesDatas.push(daNote.noteData);
										}
										canMiss = true;
									}
								});
								sortedNotesList.sort(sortHitNotes);
				
								if (sortedNotesList.length > 0) {
									for (epicNote in sortedNotesList)
									{
										for (doubleNote in pressNotes) {
											if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
												doubleNote.kill();
												notes.remove(doubleNote, true);
												doubleNote.destroy();
											} else
												notesStopped = true;
										}
				
										// eee jack detection before was not super good
										if (!notesStopped) {
											goodNoteHit(epicNote);
											pressNotes.push(epicNote);
										}
				
									}
								}
								else{
									callOnLuas('onGhostTap', [key]);
									if (canMiss) {
										noteMissPress(key);
									}
								}
				
								// I dunno what you need this for but here you go
								//									- Shubs
				
								// Shubs, this is for the "Just the Two of Us" achievement lol
								//									- Shadow Mario
								keysPressed[key] = true;
								//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
								Conductor.songPosition = lastTime;
							}
				
							var spr:StrumNote = playerStrums.members[key];
							if(spr != null && spr.animation.curAnim.name != 'confirm')
							{
								spr.playAnim('pressed');
								spr.resetAnim = 0;
							}
							callOnLuas('onKeyPress', [key]);
						}
					case 'Kade Engine': // 1.8 input btw
						var canMiss:Bool = !ClientPrefs.ghostTapping;

						if (keysPressed[key])
						{
							trace('bro this key already held');
							return;
						}

						keysPressed[key] = true;

						closestNotes = [];

						notes.forEachAlive(function(daNote:Note)
						{
							if (daNote.canBeHit && daNote.mustPress && !daNote.wasGoodHit)
								closestNotes.push(daNote);
						}); // Collect notes that can be hit

						closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						var dataNotes = [];
						for (i in closestNotes)
							if (i.noteData == key && !i.isSustainNote)
								dataNotes.push(i);

						if (dataNotes.length != 0)
						{
							var coolNote = null;

							for (i in dataNotes)
							{
								coolNote = i;
								break;
							}

							if (dataNotes.length > 1) // stacked notes or really close ones
							{
								for (i in 0...dataNotes.length)
								{
									if (i == 0) // skip the first note
										continue;

									var note = dataNotes[i];

									if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == key)
									{
										trace('found a stacked/really close note ' + (note.strumTime - coolNote.strumTime));
										// just fuckin remove it since it's a stacked note and shouldn't be there
										note.kill();
										notes.remove(note, true);
										note.destroy();
									}
								}
							}

							goodNoteHit(coolNote);
						}
						else if (canMiss && generatedMusic)
						{
							noteMissPress(key);
							callOnLuas('noteMissPress', [key]);
							health -= 0.20; // kade is evillll
						}

						keysPressed[key] = true;
					case 'ZoroForce EK':
						// more accurate hit time for the ratings?
						var lastTime:Float = Conductor.songPosition;
						var hittableNotes = [];
						var closestNotes = [];

						notes.forEachAlive(function(daNote:Note)
						{
							if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
							{
								closestNotes.push(daNote);
							}
						});
						closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						for (i in closestNotes)
							if (i.noteData == key)
								hittableNotes.push(i);

						if (hittableNotes.length != 0)
						{
							var daNote = null;

							for (i in hittableNotes)
							{
								daNote = i;
								break;
							}

							if (daNote == null)
								return;

							if (hittableNotes.length > 1)
							{
								for (shitNote in hittableNotes)
								{
									if (shitNote.strumTime == daNote.strumTime)
										goodNoteHit(shitNote);
									else if ((!shitNote.isSustainNote && (shitNote.strumTime - daNote.strumTime) < 15))
										goodNoteHit(shitNote);
								}
							}
							goodNoteHit(daNote);
						}
						else if (!ClientPrefs.ghostTapping && generatedMusic)
							noteMissPress(key);

						keysPressed[key] = true;

						//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
						Conductor.songPosition = lastTime;
					case 'Psych (0.6.3)':
						//trace('Pressed: ' + eventKey);

						if (!cpuControlled && !playAsGF && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
						{
							if(!boyfriend.stunned && generatedMusic && !endingSong)
							{
								//more accurate hit time for the ratings?
								var lastTime:Float = Conductor.songPosition;
								Conductor.songPosition = FlxG.sound.music.time;

								var canMiss:Bool = !ClientPrefs.ghostTapping;

								// heavily based on my own code LOL if it aint broke dont fix it
								var pressNotes:Array<Note> = [];
								//var notesDatas:Array<Int> = [];
								var notesStopped:Bool = false;

								var sortedNotesList:Array<Note> = [];
								notes.forEachAlive(function(daNote:Note)
								{
									if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
									{
										if(daNote.noteData == key)
										{
											sortedNotesList.push(daNote);
											//notesDatas.push(daNote.noteData);
										}
										canMiss = true;
									}
								});
								sortedNotesList.sort(sortHitNotes);

								if (sortedNotesList.length > 0) {
									for (epicNote in sortedNotesList)
									{
										for (doubleNote in pressNotes) {
											if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
												doubleNote.kill();
												notes.remove(doubleNote, true);
												doubleNote.destroy();
											} else
												notesStopped = true;
										}

										// eee jack detection before was not super good
										if (!notesStopped) {
											goodNoteHit(epicNote);
											pressNotes.push(epicNote);
										}

									}
								}
								else{
									callOnLuas('onGhostTap', [key]);
									if (canMiss) {
										noteMissPress(key);
									}
								}

								// I dunno what you need this for but here you go
								//									- Shubs

								// Shubs, this is for the "Just the Two of Us" achievement lol
								//									- Shadow Mario
								keysPressed[key] = true;

								//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
								Conductor.songPosition = lastTime;
							}

							var spr:StrumNote = playerStrums.members[key];
							if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
							{
								spr.playAnim('pressed');
								spr.resetAnim = 0;
							}
							callOnLuas('onKeyPress', [key]);
						}
					case "Forever Engine":
						if ((key > -1)
						&& !cpuControlled
						&& !playAsGF
						&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode)
						&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
						{
							if (generatedMusic)
							{
								var previousTime:Float = Conductor.songPosition;
								Conductor.songPosition = FlxG.sound.music.time;
								// improved this a little bit, maybe its a lil
								var possibleNoteList:Array<Note> = [];
								var pressedNotes:Array<Note> = [];
				
								notes.forEachAlive(function(daNote:Note)
								{
									if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
										possibleNoteList.push(daNote);
								});
								possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				
								// if there is a list of notes that exists for that control
								if (possibleNoteList.length > 0)
								{
									var eligable = true;
									var firstNote = true;
									// loop through the possible notes
									for (coolNote in possibleNoteList)
									{
										for (noteDouble in pressedNotes)
										{
											if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
												firstNote = false;
											else
												eligable = false;
										}
				
										if (eligable)
										{
											goodNoteHit(coolNote); // then hit the note
											pressedNotes.push(coolNote);
										}
										// end of this little check
									}
									//
								}
								else // else just call bad notes
									if (!ClientPrefs.ghostTapping)
										noteMissPress(key);

								keysPressed[key] = true;
								Conductor.songPosition = previousTime;
							}
			
							if (playerStrums.members[key] != null
								&& playerStrums.members[key].animation.curAnim.name != 'confirm')
								playerStrums.members[key].playAnim('pressed');

							callOnLuas('onKeyPress', [key]);
						}
					case 'Hypno Input':
						if ((key > -1)
							&& !cpuControlled
							&& !playAsGF
							&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
							&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
						{
							if (generatedMusic && !inCutscene)
							{
								var previousTime:Float = Conductor.songPosition;
								Conductor.songPosition = FlxG.sound.music.time;
								// improved this a little bit, maybe its a lil
								var possibleNoteList:Array<Note> = [];
								var pressedNotes:Array<Note> = [];
				
								notes.forEachAlive(function(daNote:Note)
								{
									if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
										possibleNoteList.push(daNote);
								});
								possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				
								// if there is a list of notes that exists for that control
								if (possibleNoteList.length > 0)
								{
									var eligable = true;
									var firstNote = true;
									// loop through the possible notes
									for (coolNote in possibleNoteList)
									{
										for (noteDouble in pressedNotes)
										{
											if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
												firstNote = false;
											else
												eligable = false;
										}
				
										if (eligable) {
											goodNoteHit(coolNote); // then hit the note
											pressedNotes.push(coolNote);
										}
										// end of this little check
									}
									//
								}
								else // else just call bad notes
									if (!ClientPrefs.ghostTapping)
										noteMissPress(key);
								keysPressed[key] = true;
								Conductor.songPosition = previousTime;
							}
				
							if (playerStrums.members[key] != null
								&& playerStrums.members[key].animation.curAnim.name != 'confirm')
								playerStrums.members[key].playAnim('pressed');
						}
				}
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !playAsGF && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			if (ClientPrefs.inputSystem == 'Kade Engine')
				keysPressed[key] = false;
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray[mania].length)
			{
				for (j in 0...keysArray[mania][i].length)
				{
					if (key == keysArray[mania][i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function keysArePressed():Bool
	{
		for (i in 0...keysArray[mania].length)
		{
			for (j in 0...keysArray[mania][i].length)
			{
				if (FlxG.keys.checkStatus(keysArray[mania][i][j], PRESSED))
					return true;
			}
		}

		return false;
	}

	private function dataKeyIsPressed(data:Int):Bool
	{
		for (i in 0...keysArray[mania][data].length)
		{
			if (FlxG.keys.checkStatus(keysArray[mania][data][i], PRESSED))
				return true;
		}

		return false;
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();
		// FlxG.watch.addQuick('asdfa', upP);
		if((ClientPrefs.inputSystem == 'Psych (0.6.3)' || ClientPrefs.inputSystem == 'Forever Engine') && ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[mania][i][0]));
				}
			}
		}
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				switch (ClientPrefs.inputSystem)
				{
					case 'Native' | 'ZoroForce EK':
						if (daNote.isSustainNote && dataKeyIsPressed(daNote.noteData) && daNote.canBeHit && daNote.mustPress && !daNote.tooLate
							&& !daNote.wasGoodHit)
						{
							goodNoteHit(daNote);
						}
					case 'Kade Engine':
						if (daNote.isSustainNote && dataKeyIsPressed(daNote.noteData) && daNote.canBeHit && daNote.mustPress && daNote.susActive)
						{
							goodNoteHit(daNote);
						}
					case 'Psych (0.6.3)':
						if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
						&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
							goodNoteHit(daNote);
						}
					case 'Forever Engine':
						if (daNote.canBeHit
							&& daNote.mustPress
							&& !daNote.tooLate
							&& daNote.isSustainNote
							&& strumsBlocked[daNote.noteData] != true)
							goodNoteHit(daNote);
					case 'Hypno Input':
						if (!cpuControlled && !playAsGF) {
							// check if anything is held
							if (dataKeyIsPressed(daNote.noteData))
							{
								// check notes that are alive
								notes.forEachAlive(function(coolNote:Note)
								{
									if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
									&& coolNote.canBeHit
									&& !coolNote.tooLate && coolNote.isSustainNote
									&& strumsBlocked[coolNote.noteData] != true)
										goodNoteHit(coolNote);
								});
								//
							}
						}
				}
			});

			if (keysArePressed() && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null)
				{
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
			else if (ghostChar2 != null 
				&& ghostChar2.holdTimer > Conductor.stepCrochet * 0.001 * ghostChar2.singDuration
				&& ghostChar2.animation.curAnim.name.startsWith('sing')
				&& !ghostChar2.animation.curAnim.name.endsWith('miss'))
				ghostChar2.dance();

			if((ClientPrefs.inputSystem == 'Psych (0.6.3)' || ClientPrefs.inputSystem == 'Forever Engine') && (ClientPrefs.controllerMode || strumsBlocked.contains(true)))
			{
				var parsedArray:Array<Bool> = parseKeys('_R');
				if(parsedArray.contains(true))
				{
					for (i in 0...parsedArray.length)
					{
						if(parsedArray[i] || strumsBlocked[i] == true)
							onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[mania][i][0]));
					}
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		bfkilledcheck = true;

		health -= daNote.missHealth * healthLoss;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
			bfkilledcheck = true;
		}

		switch(daNote.noteType) {
			case 'Parry Note': //Parry Note
				if(boyfriend.animation.getByName('hurt') != null) {
					dad.playAnim('singLEFT-alt', true);
					boyfriend.playAnim('hurt', true);
					boyfriend.specialAnim = true;
					dad.specialAnim = true;
					camGame.shake(0.01, 0.2);
					camHUD.shake(0.01, 0.2);
					Lib.application.window.move(winX + 30, winY - 30);
					Lib.application.window.move(winX - 30, winY + 30);
					Lib.application.window.move(winX, winY);
				}
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode && !playAsGF) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char != null && char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		bfkilledcheck = true;
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
				bfkilledcheck = true;
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode && !playAsGF) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note, ?field:PlayField):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
			if (ghostChar != null)
			{
				ghostChar.playAnim('hey', true);
				ghostChar.specialAnim = true;
				ghostChar.heyTimer = 0.6;
			}
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			if(note.gfNote) {
				char = gf;
			}
			if(note.exNote) {
				char = dad2;
				altAnim = '';
			}

			if(ghostChar != null && note.ghostNote)
			{
				if (!note.animation.curAnim.name.endsWith('tail'))
				{
					ghostChar.alpha = 0.7;
					ghostChar.playAnim(animToPlay, true);
					ghostChar.holdTimer = 0;
				}
			}

			if(char != null && !note.ghostNote)
			{
				if (!note.animation.curAnim.name.endsWith('tail'))
				{
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
				}
			}
		}

		switch(note.noteType) {
			case 'Power Note': //Parry Note
				camGame.shake(0.01, 0.2);
				camHUD.shake(0.01, 0.2);
				Lib.application.window.move(winX + 60, winY - 60);
				Lib.application.window.move(winX - 60, winY + 60);
				Lib.application.window.move(winX, winY);
				if (ClientPrefs.drain && health >= 0.30)
				{
					if (note.isSustainNote)
					{
						health -= 0.0115 + 0.015;
					} else {
						//health -= 0.04;
						health -= 0.0375 + 0.015;	
					}	
					camGame.shake(0.01, 0.2);
					camHUD.shake(0.01, 0.2);
				}
				ch = FlxG.random.int(1,5) / 1000 * 4;
				ch = FlxG.random.int(1,5) / 1000 * 4;
				ShadersHandler.setChrome(ch);
				chromCheck = Std.int(ch);
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}

		if (!note.exNote && Note.ammo[mania] == 4)
			StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time, false);
		else
			StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time, true);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}

		var curSection:Int = Math.floor(curStep / 16);

		function theShadow(convertedvalue:String)
		{
			if (convertedvalue == 'black' || convertedvalue == 'Black')
			{
				FlxTween.tween(whiteBG, {alpha: 1}, 0.1);
				FlxTween.tween(blackOverlay, {alpha: 0}, 0.1);
				if (gf != null) FlxTween.tween(gf, {color: FlxColor.BLACK}, 0.1);
				FlxTween.tween(dad, {color: FlxColor.BLACK}, 0.1);
				FlxTween.tween(boyfriend, {color: FlxColor.BLACK}, 0.1);
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				//boyfriend.color = FlxColor.BLACK;
				//gf.color = FlxColor.BLACK;
				//dad.color = FlxColor.BLACK;
			}
			else if (convertedvalue == 'white' || convertedvalue == 'White')
			{
				FlxTween.tween(blackOverlay, {alpha: 1}, 0.1);
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1);
				if (gf != null) FlxTween.tween(gf, {color: 0xffffffff}, 0.1);
				FlxTween.tween(dad, {color: 0xffffffff}, 0.1);
				FlxTween.tween(boyfriend, {color: 0xffffffff}, 0.1);
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				//boyfriend.color = 0xffffffff;
				//gf.color = 0xffffffff;
				//dad.color = 0xffffffff;
			}
			else
			{
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1);
				FlxTween.tween(blackOverlay, {alpha: 0}, 0.1);
				if (gf != null) FlxTween.tween(gf, {color: FlxColor.WHITE}, 0.1);
				FlxTween.tween(dad, {color: FlxColor.WHITE}, 0.1);
				FlxTween.tween(boyfriend, {color: FlxColor.WHITE}, 0.1);
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				//boyfriend.color = FlxColor.WHITE;
				//gf.color = FlxColor.WHITE;
				//dad.color = FlxColor.WHITE;
			}
		}

		function how(convertedvalue:String)
		{
			if (convertedvalue == 'true' || convertedvalue == 'True')
			{
				sh_r += (60 - sh_r) / 32;
			}
			else
			{
				sh_r = 600;
			}
		}
	}

	public var animToPlay:String;

	function goodNoteHit(note:Note, ?field:PlayField):Void
	{
		animToPlay = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if((cpuControlled || playAsGF) && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				//var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];
				if(note.ghostNote) 
				{
					if(ghostChar2 != null)
					{
						if (!note.animation.curAnim.name.endsWith('tail'))
						{
							ghostChar2.alpha = 0.7;
							ghostChar2.playAnim(animToPlay + daAlt, true);
							ghostChar2.holdTimer = 0;
						}
					}
				}
				else if(note.gfNote) 
				{
					if(gf != null)
					{
						if (!note.animation.curAnim.name.endsWith('tail'))
						{
							gf.playAnim(animToPlay + daAlt, true);
							gf.holdTimer = 0;
						}
					}
				}
				else if(note.exNote) 
				{
					if(dad2 != null)
					{
						if (!note.animation.curAnim.name.endsWith('tail'))
						{
							dad2.playAnim(animToPlay + daAlt, true);
							dad2.holdTimer = 0;
						}
					}
				}
				else
				{
					if (!note.animation.curAnim.name.endsWith('tail'))
					{
						boyfriend.playAnim(animToPlay + daAlt, true);
						boyfriend.holdTimer = 0;
					}
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
			bfkilledcheck = false;
			if(cpuControlled || playAsGF) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time, false);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
		switch(note.noteType) {
			case 'Parry Note': //Parry Note
				if(boyfriend.animation.getByName('block') != null) {
					dad.playAnim('singLEFT-alt', true);
					boyfriend.playAnim('block', true);
					boyfriend.specialAnim = true;
					dad.specialAnim = true;
					camGame.shake(0.01, 0.2);
					camHUD.shake(0.01, 0.2);
					Lib.application.window.move(winX + 30, winY - 30);
					Lib.application.window.move(winX - 30, winY + 30);
					Lib.application.window.move(winX, winY);
				}
		}
	}

	var didLastBeat:Bool = false;
	function goodGFBop():Void
	{
		gfBopCombo++;
		if (gfBopCombo > gfBopComboBest)
		{
			gfBopComboBest++;
		}
		healthGF += 0.023;
		bfkilledcheck = false;
		didntPress = false;
		didLastBeat = true;
	}

	function badGFBop():Void
	{
		gfBopCombo = 0;
		gfMisses++;
		healthGF -= 0.0475;
		bfkilledcheck = true;
		if (gf != null)
		{
			gf.color = Std.parseInt("0xFFFF0000");
			FlxTween.tween(gf, {color: FlxColor.WHITE}, 0.1);
		}
		didntPress = true;
		didLastBeat = false;
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function lightningStrikeShitAlt():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared'))
		{
			boyfriend.playAnim('scared', true);
		}
		if(gf != null)
		{
			if (gf.animOffsets.exists('scared'))
			{
				gf.playAnim('scared', true);
			}
		}

		if (ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming)
			{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
			FlxG.camera.flash(FlxColor.WHITE);
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}


	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(gfScared && curStep % 2 == 0)
		{
			gf.playAnim('scared', true);
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	
	var ravemode:Bool = false;
	var ravemodeV2:Bool = false;
	var autoBotsRollOut:Bool = false;
	var isActiveRN:Bool = false;
	var chromvar:Float = 0.01;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (curBeat % 4 / gfSpeed == 0) didLastBeat = false;

		if (autoBotsRollOut)
		{
			doPhilly(1);
		}

		if (!playAsGF)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
			if (dad2 != null)
				iconP22.scale.set(1.2, 1.2);
			iconP1G.scale.set(1.2, 1.2);
			iconP2G.scale.set(1.2, 1.2);

			iconP1.updateHitbox();
			iconP2.updateHitbox();
			if (dad2 != null)
				iconP22.updateHitbox();
			iconP1G.updateHitbox();
			iconP2G.updateHitbox();
		}
		else
		{
			if (gf != null)
			{
				if (curBeat % 2 / gfSpeed == 0) iconGF.angle = -15;
				else if (curBeat % 2 / gfSpeed == 1) iconGF.angle = 15;
				iconGF.updateHitbox();
			}
		}

		if ((ravemode || ravemodeV2) && camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.flashing)
		{
			if (ClientPrefs.flashing) {
				rave.forEach(function(light2:FlxSprite)
				{
					light2.visible = false;
				});

				curLight++;
				if (curLight > rave.length - 1)
					curLight = 0;

				rave.members[curLight].visible = true;
				rave.members[curLight].alpha = 1;
				FlxTween.tween(rave.members[curLight], {alpha: 0}, 0.3, {
				});

			}
		
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
		}
		else
		{
			rave.members[curLight].visible = false;
			rave.members[curLight].alpha = 0;
		}

		if (didntPress)
		{
			badGFBop();
			didntPress = false;
		}
		
		if (gf != null && !gfScared && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}
		if (dad2 != null)
		{
			if (curBeat % dad2.danceEveryNumBeats == 0 && dad2.animation.curAnim != null && !dad2.animation.curAnim.name.startsWith('sing') && !dad2.stunned)
			{
				dad2.dance();
			}
		}
		if (ghostChar != null)
		{
			if (curBeat % ghostChar.danceEveryNumBeats == 0 && ghostChar.animation.curAnim != null && !ghostChar.animation.curAnim.name.startsWith('sing') && !ghostChar.stunned)
			{
				ghostChar.dance();
				ghostChar.alpha = 0;
			}
		}
		if (ghostChar2 != null)
		{
			if (curBeat % ghostChar2.danceEveryNumBeats == 0 && ghostChar2.animation.curAnim != null && !ghostChar2.animation.curAnim.name.startsWith('sing') && !ghostChar2.stunned)
			{
				ghostChar2.dance();
			}
		}

		switch (curStage)
		{
			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		if (thunderON && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShitAlt();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
			setOnLuas('exSection', SONG.notes[curSection].exSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}


	public var lastUpdatedDownscroll = false;
	public function forceChange(bool:Bool)
	{
		trace('changing downscroll to ' + bool);
		ClientPrefs.downScroll = bool;
		//ClientPrefs.downScroll = bool;
		//SaveData.P2downscroll = bool;
		lastUpdatedDownscroll = bool;
		if (ClientPrefs.downScroll)
		{
			strumLine.y = FlxG.height - 150;
			timeTxt.y = FlxG.height - 44;
			timeBarBG.x = timeTxt.x;
			timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
			timeBar.x = timeBarBG.x + 4;
			timeBar.y = timeBarBG.y + 4;
			healthBarBG.y = 0.11 * FlxG.height;
			if (!playAsGF)
			{
				healthBar.x = healthBarBG.x + 4;
				healthBar.y = healthBarBG.y + 4;
				healthBar2.x = healthBarBG.x + 4;
				healthBar2.y = healthBarBG.y + 4;
				iconP1.y = healthBar.y - 75;
				iconP1G.y = healthBar.y - 125;
				iconP2.y = healthBar.y - 75;
				if (dad2 != null)
					iconP22.y = healthBar.y - 115;
				iconP2G.y = healthBar.y - 125;
			}
			else
			{
				healthBarGF.x = healthBarBG.x + 4;
				healthBarGF.y = healthBarBG.y + 4;
				if (gf != null) iconGF.y = healthBar.y - 75;
			}
			scoreTxt.y = healthBarBG.y + 36;
			botplayTxt.y = timeBarBG.y - 78;

		}
		else
		{
			strumLine.y = 50;
			timeTxt.y = 19;
			timeBarBG.x = timeTxt.x;
			timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
			timeBar.x = timeBarBG.x + 4;
			timeBar.y = timeBarBG.y + 4;
			healthBarBG.y = FlxG.height * 0.89;
			if (!playAsGF)
			{
				healthBar.x = healthBarBG.x + 4;
				healthBar.y = healthBarBG.y + 4;
				healthBar2.x = healthBarBG.x + 4;
				healthBar2.y = healthBarBG.y + 4;
				iconP1.y = healthBar.y - 75;
				iconP1G.y = healthBar.y - 125;
				iconP2.y = healthBar.y - 75;
				if (dad2 != null)
					iconP22.y = healthBar.y - 115;
				iconP2G.y = healthBar.y - 125;
			}
			else
			{
				healthBarGF.x = healthBarBG.x + 4;
				healthBarGF.y = healthBarBG.y + 4;
				if (gf != null) iconGF.y = healthBar.y - 75;
			}
			scoreTxt.y = healthBarBG.y + 36;
			botplayTxt.y = timeBarBG.y + 55;
		}
	
		for(i in strumLineNotes.members)
			i.y = strumLine.y;
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool && ret != 0) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float, ?isDad2:Bool = false) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		}else if(isDad2) {
			spr = opponentStrums2.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				
				if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				if (achievementName.contains('smooth_moves'))
				{
					if(campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				if (achievementName.contains('way_too_spoopy') && WeekData.getCurrentWeek().weekName == 'week2')
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode && !playAsGF) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice && !playAsGF) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100 && !playAsGF) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice && !playAsGF) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice && !playAsGF) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice && Note.ammo[mania] > 2  && !playAsGF) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ !ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice && !playAsGF) {
							unlock = true;
						}
					case 'not_4k':
						if(chartModifier == "4K Only" && Note.ammo[mania] == 4 && !usedPractice && !cpuControlled && !playAsGF) {
							unlock = true;
						}
					case 'gf_mode':
						if(playAsGF && !usedPractice && !cpuControlled) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
