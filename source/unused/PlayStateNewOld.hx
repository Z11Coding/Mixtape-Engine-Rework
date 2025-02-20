package states;

import backend.Achievements;
import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Section;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;

import psychlua.FunkinLua;

import cutscenes.CutsceneHandler;
import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.PauseSubStateLost;
import substates.GameOverSubstate;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end

import objects.Note.EventNote;
import objects.*;
import states.stages.BaseStage;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
#end

//Mixtape Stuff
import modchart.ModManager;
import shaders.DynamicShaderHandler;
import openfl.filters.BitmapFilter;
import backend.STMetaFile.MetadataFile;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import backend.PlayField;
import openfl.Lib;

typedef SpeedEvent =
{
	position:Float, // the y position when the change happens (modManager.getVisPos(songTime))
	songTime:Float, // the song position (conductor.songTime) when the changer happens
	speed:Float // speed mult after the change
}

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
	public var boyfriendMap2:Map<String, Boyfriend> = new Map();
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
	public var boyfriendMap2:Map<String, Boyfriend> = new Map<String, Boyfriend>();
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
	public var BF2_X:Float = 770;
	public var BF2_Y:Float = 100;
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
	public var boyfriendGroup2:FlxSpriteGroup;
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
	public var dadVocals:FlxSound;
	public var bfVocals:FlxSound;

	public var dad:Character = null;
	public static var dad2:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;
	public var bf2:Boyfriend = null;

	public var notes = new FlxTypedGroup<Note>();
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
	
	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var fullComboFunction:Void->Void = null;

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
	public var practiceMode:Bool = false;
	public var chartModifier:String = 'Normal';

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP12:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP22:HealthIcon;
	public var iconGF:HealthIcon;
	public var camHUD:FlxCamera;
	public var barCam:FlxCamera;
	public var camVisual:FlxCamera;
	public var camGame:FlxCamera;
	public var camCredit:FlxCamera;
	public var camOther:FlxCamera;
	public var camFilters:FlxCamera;
	public var cameraSpeed:Float = 1;

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
	public var boyfriend2CameraOffset:Array<Float> = null;
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
	var boyfriend2IdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;
	var boyfriend2Idled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	#if LUA_ALLOWED
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';
	#if sys
	public var luaShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();
	#end

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	public var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	//aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
	public var bfkilledcheck = false;
	public var filters:Array<BitmapFilter> = [];
	public var lavaFilters:Array<BitmapFilter> = [];
	var camfilters2:Array<BitmapFilter> = [];
	var ch = 2 / 1000;
	public var shaderUpdates:Array<Float->Void> = [];
	var metadata:MetadataFile;
	var hasMetadataFile:Bool = false;
	var Text:Array<String> = [];
	var whiteBG:FlxSprite;
	var blackOverlay:FlxSprite;
	var blackUnderlay:FlxSprite;
	public var freezeNotes:Bool = false;
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
	var bfT:FlxTrail;
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
	public var gimmicksAllowed:Bool = true;
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
	
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText;
	var skipTo:Float;

	public var playerField:PlayField;
	public var dadField:PlayField;

	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes

	public var noteHits:Array<Float> = [];
	public var nps:Int = 0;

	var speedChanges:Array<SpeedEvent> = [];
	public var currentSV:SpeedEvent = {position: 0, songTime:0, speed: 1};

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	public var precacheList:Map<String, String> = new Map<String, String>();
	public var songName:String;

	public static var preventSong:Bool = false;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	public var halloweenWhite:BGSprite;
	public var blammedLightsBlack:FlxSprite;
	private var timerExtensions:Array<Float>;
	public var maskedSongLength:Float = -1;
	public var saveScore:Bool = true; // whether to save the score. modcharted songs should set this to false if disableModcharts is true
	public var songDetails:FlxText;
	public var disableModcharts:Bool = false;
	var giveHealthAmount:Float = 0.023;

	/*function chromaVideo(name:String){
		var video = new hxcodec.VideoSprite(0,0);
		video.scrollFactor.set();
		video.cameras = [camHUD];
		video.shader = new GreenScreenShader();
		video.playVideo(Paths.video(name));
		return video;
	}*/
	public var cpuControlled(default, set) = false;
	public function set_cpuControlled(value){
		cpuControlled = value;

		setOnLuas('botPlay', cpuControlled);

		/// oughhh
		for (playfield in playfields.members){
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled; 
		}

		return value;
	}

	override public function create()
	{
		
		MemoryUtil.clearMajor();
		precacheList.set(curSong.toLowerCase(), 'inst');
		precacheList.set(curSong.toLowerCase(), 'voices');

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		fullComboFunction = function() {
			var marvs:Int = 0;
			var sicks:Int;
			var goods:Int;
			var bads:Int;
			var shits:Int;
			if (ClientPrefs.data.useMarvs)
			{
				marvs = ratingsData[0].hits;
				sicks = ratingsData[1].hits;
				goods = ratingsData[2].hits;
				bads = ratingsData[3].hits;
				shits = ratingsData[4].hits;
			}
			else
			{
				sicks = ratingsData[0].hits;
				goods = ratingsData[1].hits;
				bads = ratingsData[2].hits;
				shits = ratingsData[3].hits;
			}

			ratingFC = 'Clear';
			if(songMisses < 1) {
				if (ClientPrefs.data.useMarvs)
				{
					if (bads > 0 || shits > 0) ratingFC = 'FC';
					else if (goods > 0) ratingFC = 'GFC';
					else if (sicks > 0) ratingFC = 'SFC';
					else if (marvs > 0) ratingFC = 'MFC';
				}
				else
				{
					if (bads > 0 || shits > 0) ratingFC = 'FC';
					else if (goods > 0) ratingFC = 'GFC';
					else if (sicks > 0) ratingFC = 'SFC';
				}
			} else if (songMisses < 10) {
				ratingFC = 'SDCB';
			}
		};

		keysArray = backend.Keybinds.fill();

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		speedChanges.push({
			position: 0,
			songTime: 0,
			speed: 1
		});

		/*//Ratings
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
		ratingsData.push(rating);*/

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
		gimmicksAllowed = ClientPrefs.data.gimmicksAllowed;
		disableModcharts = !ClientPrefs.data.modcharts;
		
		saveScore = !cpuControlled;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		barCam = new FlxCamera();
		camHUD = new FlxCamera();
		camVisual = new FlxCamera();
		camCredit = new FlxCamera();
		camOther = new FlxCamera();
		camFilters = new FlxCamera();
		barCam.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camVisual.bgColor.alpha = 0;
		camCredit.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camFilters.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(barCam, false);
		FlxG.cameras.add(camHUD, false);
		//FlxG.cameras.add(camVisual, false);
		FlxG.cameras.add(camCredit, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camFilters, false);
		if (ClientPrefs.data.starHidden) 
		{
			camHUD.alpha = 0;
			barCam.alpha = 0;
		}

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		if(ClientPrefs.data.shaders){
			if (SONG.stage == 'lavapit')
			{
				camGame.setFilters(lavaFilters);
				camGame.filtersEnabled = true;
			}
			else
			{
				camGame.setFilters(filters);
				camGame.filtersEnabled = true;
			}
			barCam.setFilters(filters);
			barCam.filtersEnabled = true;
			camHUD.setFilters(filters);
			camHUD.filtersEnabled = true;
			//camVisual.setFilters(camfilters2);
			//camVisual.filtersEnabled = true;	
			camOther.setFilters(filters);
			camOther.filtersEnabled = true;
			camFilters.setFilters(filters);
			camFilters.filtersEnabled = true;
			lavaFilters.push(shaders.ShadersHandler.heatwaveShader);
			lavaFilters.push(shaders.ShadersHandler.chromaticAberration);
			filters.push(shaders.ShadersHandler.chromaticAberration);
			camfilters2.push(shaders.ShadersHandler.visualizer);
			/*filters.push(ShadersHandler.fuckingTriangle); //this shader has a cool feature for all the wrong reasons >:)
			camfilters.push(ShadersHandler.fuckingTriangle);*/
		}

		camHUD.filtersEnabled = true;
		camGame.filtersEnabled = true;
		if (ClientPrefs.data.downScroll)
		{
			camGame.flashSprite.scaleY *= -1;
		}

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

		setOnLuas('mania', mania);

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');
	
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = Difficulty.getString();

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
		songName = StringTools.replace(Paths.formatToSongPath(SONG.song), '-', ' ');
		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		if (stageData.boyfriend2 != null)
		{
			BF2_X = stageData.boyfriend2[0];
			BF2_Y = stageData.boyfriend2[1];
		}
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

		boyfriend2CameraOffset = stageData.camera_boyfriend2;
		if(boyfriend2CameraOffset == null)
			boyfriend2CameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		opponent2CameraOffset = stageData.camera_opponent2;
		if(opponent2CameraOffset == null)
			opponent2CameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		boyfriendGroup2 = new FlxSpriteGroup(BF2_X, BF2_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		dadGroup2 = new FlxSpriteGroup(DAD2_X, DAD2_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': new states.stages.StageWeek1(); //Week 1
			case 'mansion': new states.stages.Mansion();
			case 'sky': new states.stages.Sky();
			case 'portal': new states.stages.Portal();
			case 'lavapit': new states.stages.Lavapit();
		}

		var barHUDTop:FlxSprite = new FlxSprite().loadGraphic(Paths.image('hudTOP'));
		barHUDTop.cameras = [barCam];
		barHUDTop.screenCenter();
		add(barHUDTop);

		var subTextCuzICantSpell:String = Difficulty.getString().toUpperCase();

		if (subTextCuzICantSpell == 'CANNON') subTextCuzICantSpell = 'CANON'; //Too lazy to find all the issues.
																			  //+ It breaks everything and I do NOT wanna sort through everything when it works fine now.

		songDetails = new FlxText((FlxG.width / 2) - 828, 15, 800, "", 15);
		songDetails.setFormat(Paths.font("Jack Armstrong Bold.ttf"), 15, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songDetails.text = SONG.song + ' - ' + subTextCuzICantSpell;
		songDetails.cameras = [camHUD];
		add(songDetails);

		whiteBG = new FlxSprite(-480, -480).makeGraphic(Std.int(FlxG.width * 2000), Std.int(FlxG.height * 2000), FlxColor.WHITE);
		whiteBG.updateHitbox();
		whiteBG.antialiasing = true;
		whiteBG.scrollFactor.set(0, 0);
		whiteBG.active = false;
		whiteBG.cameras = [camOther];
		//whiteBG.cameras;
		whiteBG.alpha = 0.0;

		blackOverlay = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackOverlay.updateHitbox();
		blackOverlay.screenCenter();
		blackOverlay.antialiasing = true;
		blackOverlay.scrollFactor.set(0, 0);
		blackOverlay.active = false;
		blackOverlay.alpha = 0;
		blackOverlay.cameras = [camOther];
		blackOverlay.setGraphicSize(Std.int(blackOverlay.width * 10.5));

		blackUnderlay = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackUnderlay.updateHitbox();
		blackUnderlay.screenCenter();
		blackUnderlay.antialiasing = true;
		blackUnderlay.scrollFactor.set(0, 0);
		blackUnderlay.active = false;
		blackUnderlay.alpha = 0;
		blackUnderlay.setGraphicSize(Std.int(blackUnderlay.width * 10.5));

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);
		add(dadGroup);
		add(dadGroup2);
		add(boyfriendGroup);
		add(boyfriendGroup2);

		if (curStage != 'spooky')  //to avoid dups
		{
			halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
			halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
			halloweenWhite.alpha = 0;
			halloweenWhite.blend = ADD;
			add(halloweenWhite);
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

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
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
		startLuasOnFolder('stages/' + curStage + '.lua');
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
		}

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
		
		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		if (SONG.player5 != null) 
		{
			bf2 = new Boyfriend(0, 0, SONG.player5);
			startCharacterPos(bf2, true);
			boyfriendGroup2.add(bf2);
			startCharacterLua(bf2.curCharacter);
		}
		else
		{
			bf2 = null;
		}
		
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

		addBehindGF(whiteBG);
		addBehindGF(blackUnderlay);

		stagesFunc(function(stage:BaseStage) stage.createPost());
		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.data.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();
		//barHUD.y += 500;

		var barHUDBottom:FlxSprite = new FlxSprite().loadGraphic(Paths.image('hudBOTTOM'));
		barHUDBottom.cameras = [barCam];
		barHUDBottom.screenCenter();
		add(barHUDBottom);

		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 29, 400, "", 32);
		timeTxt.setFormat(Paths.font("Jack Armstrong Bold.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.y -= 10;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('bars/timeBarGREY');
		timeBarBG.x = timeTxt.x - 50;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4) - 25;
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x, timeBarBG.y, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createImageEmptyBar(Paths.image('bars/timeBarGREY'));
		timeBar.createImageFilledBar(Paths.image('bars/timeBar'));
		timeBar.numDivisions = 4800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.setGraphicSize(Std.int(timeBar.width * 0.7));
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(playfields);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		opponentStrums = new FlxTypedGroup<StrumNote>();
		opponentStrums2 = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		modManager = new ModManager(this);
		modchart.Modcharts.loadModchart(modManager, songName.toLowerCase());
		allowManagerStuff = true;

		callOnLuas("prePlayfieldCreation", []);
		playerField = new PlayField(modManager);
		playerField.modNumber = 0;
		playerField.characters = [];
		for(n => ch in boyfriendMap)playerField.characters.push(ch);
		for(n => ch in boyfriendMap2)playerField.characters.push(ch);
		
		playerField.isPlayer = !playAsGF;
		playerField.autoPlayed = cpuControlled || playAsGF;
		playerField.noteHitCallback = goodNoteHit;

		dadField = new PlayField(modManager);
		dadField.isPlayer = false;
		dadField.autoPlayed = true;
		dadField.modNumber = 1;
		dadField.characters = [];
		for(n => ch in dadMap)dadField.characters.push(ch);
		for(n => ch in dad2Map)dadField.characters.push(ch);
		dadField.noteHitCallback = opponentNoteHit;

		dad.idleWhenHold = false;
		boyfriend.idleWhenHold = !playerField.isPlayer;
		if (bf2 != null) bf2.idleWhenHold = !playerField.isPlayer;

		playfields.add(dadField);
		playfields.add(playerField);

		for(field in playfields)
			initPlayfield(field);

		callOnLuas("postPlayfieldCreation", []);

		generateSong(SONG.song);
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

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

		healthBarBG = new AttachedSprite('bars/healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.data.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		//add(healthBarBG);
		if(ClientPrefs.data.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		if(!playAsGF)
		{
			healthBar = new FlxBar(healthBarBG.x, healthBarBG.y - 22, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'health', 0, 2);
			healthBar.scrollFactor.set();
			healthBar.setGraphicSize(Std.int(healthBar.width * 0.7));
			// healthBar
			healthBar.visible = !ClientPrefs.data.hideHud;
			healthBar.alpha = ClientPrefs.data.healthBarAlpha;
			healthBarBG.sprTracker = healthBar;
			add(healthBar);
			//healthBar.barWidth = Std.int(healthBarBG.width);
           // healthBar.barHeight = Std.int(healthBarBG.height);

			/*healthBar2 = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), if (SONG.player4 != null) Std.int(healthBarBG.height - 13) else Std.int(healthBarBG.height - 8), this,
				'health', 0, 2);
			healthBar2.scrollFactor.set();
			// healthBar
			healthBar2.visible = !ClientPrefs.data.hideHud;
			healthBar2.alpha = ClientPrefs.data.healthBarAlpha;
			if (dad2 != null)
				add(healthBar2);*/

			iconP1 = new HealthIcon(boyfriend.healthIcon, true);
			iconP1.y = healthBar.y - if (boyfriend.healthIcon == 'shagerexbf') 45 else 15;
			iconP1.visible = !ClientPrefs.data.hideHud;
			iconP1.alpha = ClientPrefs.data.healthBarAlpha;
			add(iconP1);

			if (bf2 != null)
			{
				iconP12 = new HealthIcon(bf2.healthIcon, true);
				iconP12.y = healthBar.y - if (bf2.healthIcon == 'shagerexbf') 45 else 15;
				iconP12.visible = !ClientPrefs.data.hideHud;
				iconP12.alpha = ClientPrefs.data.healthBarAlpha;
				add(iconP12);
			}

			iconP2 = new HealthIcon(dad.healthIcon, false);
			iconP2.y = healthBar.y - if (dad.healthIcon == 'shagerex') 45 else 15;
			iconP2.visible = !ClientPrefs.data.hideHud;
			iconP2.alpha = ClientPrefs.data.healthBarAlpha;
			add(iconP2);

			if (dad2 != null)
			{
				iconP22 = new HealthIcon(dad2.healthIcon, false);
				iconP22.y = healthBar.y - if (dad.healthIcon == 'shagerex') 45 else 15;
				iconP22.visible = !ClientPrefs.data.hideHud;
				iconP22.alpha = ClientPrefs.data.healthBarAlpha;
				add(iconP22);
			}
			reloadHealthBarColors();
		}

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("Jack Armstrong Bold.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("FridayNightFunkin.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled || playAsGF && cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.data.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}
		if(playAsGF)
		{
			botplayTxt.text = "GFPLAY";
			healthBarGF = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, HORIZONTAL_INSIDE_OUT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'healthGF', 0, 2);
			healthBarGF.scrollFactor.set();
			// healthBar
			healthBarGF.visible = !ClientPrefs.data.hideHud;
			healthBarGF.alpha = ClientPrefs.data.healthBarAlpha;
			healthBarBG.sprTracker = healthBarGF;
			add(healthBarGF);

			if (gf != null)
			{
				iconGF = new HealthIcon(gf.healthIcon, true);
				iconGF.y = healthBarGF.y - 75;
				iconGF.visible = !ClientPrefs.data.hideHud;
				iconGF.alpha = ClientPrefs.data.healthBarAlpha;
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
			//healthBar2.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			iconP1.cameras = [camHUD];
			iconP2.cameras = [camHUD];
			if (dad2 != null) iconP22.cameras = [camHUD];
			if (bf2 != null) iconP12.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
		}
		else
		{
			healthBarGF.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			if (gf != null) iconGF.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
		}
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
		{
			startLuasOnFolder('custom_notetypes/' + notetype + '.lua');
		}
		for (event in eventsPushed)
		{
			startLuasOnFolder('custom_events/' + event + '.lua');
		}
		#end
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
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

		startCallback();
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.data.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.data.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');
		resetRPC();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnLuas('onCreatePost', []);

		if (gf != null)
		{
			#if desktop
			// Updating Discord Rich Presence.
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
			#end
		}
		
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
		add(rave);

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
		
		shaggyT = new FlxTrail(dad, null, 3, 6, 0.3, 0.002);
		shaggyT.visible = false;
		addBehindDad(shaggyT);

		bfT = new FlxTrail(boyfriend, null, 3, 6, 0.3, 0.002);
		bfT.visible = false;
		addBehindBF(bfT);
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
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
	public function addBehindBF2(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup2), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}
	public function addBehindDad2 (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup2), obj);
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

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
		if(!ClientPrefs.data.shaders) return false;

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
			if(dadVocals != null) dadVocals.pitch = value;
			if(bfVocals != null) bfVocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
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
			healthBar.createImageEmptyBar(Paths.image('bars/healthBarWHITE'));
			healthBar.createImageFilledBar(Paths.image('bars/healthBarBLUE'));
			
			/*if (dad2 != null) 
			{
				healthBar2.createFilledBar(FlxColor.fromRGB(dad2.healthColorArray[0], dad2.healthColorArray[1], dad2.healthColorArray[2]),
				FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
				healthBar2.updateBar();
			}*/
			
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
			case 4:
				if(bf2 != null && !boyfriendMap2.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap2.set(newCharacter, newBoyfriend);
					boyfriendGroup2.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					if(playerField!=null)
						playerField.characters.push(newBoyfriend);
					startCharacterLua(newBoyfriend.curCharacter);
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

	function startCharacterPos(char:Character, ?gfCheck:Bool = false, ?isBF:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
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

		var video:VideoHandler = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				startAndEnd();
				return;
			}, true);
			#else
			// Older versions
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				startAndEnd();
				return;
			}
			#end
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
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
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
					if (!preventSong) endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					if (!preventSong) startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
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

	public function startCountdown()
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
				//playerField.generateStrums(0);
				//dadField.generateStrums(1);
				for(field in playfields.members)
					field.generateStrums();

				callOnLuas('postReceptorGeneration', []);
				for(field in playfields.members)
				{
					field.fadeIn(false);
				}
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
			/* 
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
			*/

			startedCountdown = true;
			countActive = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);
			changeMania(SONG.startMania, isStoryMode || skipArrowStartTween);

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
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					gf.dance();
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
					boyfriend.dance();
				if (bf2 != null && tmr.loopsLeft % bf2.danceEveryNumBeats == 0 && bf2.animation.curAnim != null && !bf2.animation.curAnim.name.startsWith('sing') && !bf2.stunned)
					bf2.dance();
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					dad.dance();
				if (dad2 != null)
				{
					if (tmr.loopsLeft % dad2.danceEveryNumBeats == 0 && dad2.animation.curAnim != null && !dad2.animation.curAnim.name.startsWith('sing') && !dad2.stunned)
					{
						dad2.dance();
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.data.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				var tick:states.stages.BaseStage.Countdown = THREE;
				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownReady = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownReady = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
						if (ClientPrefs.data.starHidden)
						{ 
							FlxTween.tween(camHUD, {alpha: 1}, 5, {ease: FlxEase.circOut});
							FlxTween.tween(barCam, {alpha: 1}, 5, {ease: FlxEase.circOut});
						}
					case 4:
						tick = START;
						if (chartModifier == '4K Only' && Note.ammo[mania] == 4) changeMania(0, true);
						countActive = false;
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.data.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camOther];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
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
				dadVocals.pause();
				bfVocals.pause();
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
				if (bf2 != null && tmr.loopsLeft % bf2.danceEveryNumBeats == 0 && bf2.animation.curAnim != null && !bf2.animation.curAnim.name.startsWith('sing') && !bf2.stunned)
				{
					bf2.dance();
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

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.data.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
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

		if(ClientPrefs.data.scoreZoom && !miss && !cpuControlled)
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
		dadVocals.pause();
		bfVocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		if (Conductor.songPosition <= dadVocals.length)
		{
			dadVocals.time = time;
			dadVocals.pitch = playbackRate;
		}
		if (Conductor.songPosition <= bfVocals.length)
		{
			bfVocals.time = time;
			bfVocals.pitch = playbackRate;
		}
		vocals.play();
		dadVocals.play();
		bfVocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
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
		dadVocals.play();
		bfVocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		dadVocals.pause();
		bfVocals.pause();
		Conductor.songPosition += savedTime;
		trace("Saved Time:" + savedTime);
		if (savedTime != 0)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			dadVocals.pause();
			bfVocals.pause();
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
			dadVocals.time = Conductor.songPosition;
			dadVocals.play();
			bfVocals.time = Conductor.songPosition;
			bfVocals.play();	
		}

		FlxG.sound.music.time = Conductor.songPosition;
		FlxG.sound.music.play();

		vocals.time = Conductor.songPosition;
		vocals.play();
		dadVocals.time = Conductor.songPosition;
		dadVocals.play();
		bfVocals.time = Conductor.songPosition;
		bfVocals.play();

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
			dadVocals.pause();
			bfVocals.pause();
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
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private function generateSong(dataPath:String):Void
	{
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

		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));
		//inst = new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song));

		if (!SONG.newVoiceStyle)
		{
			if (SONG.needsVoices)
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			else
				vocals = new FlxSound();

			dadVocals = new FlxSound();
			bfVocals = new FlxSound();
			FlxG.sound.list.add(vocals);
		}
		else
		{
			if (SONG.needsVoices)
			{
				dadVocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, true, PlayState.SONG.newVoiceStyle));
				bfVocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, false, PlayState.SONG.newVoiceStyle));
			}
			else
			{
				dadVocals = new FlxSound();
				bfVocals = new FlxSound();	
			}	
			vocals = new FlxSound();
			FlxG.sound.list.add(dadVocals);
			FlxG.sound.list.add(bfVocals);
		}
		//FlxG.sound.list.add(inst);

		/*if (SONG.extraTracks != null){
			for (trackName in SONG.extraTracks){
				var newTrack = new FlxSound().loadEmbedded(Paths.track(PlayState.SONG.song, trackName));
				tracks.push(newTrack);
				FlxG.sound.list.add(newTrack);
			}
		}*/

		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		songName = Paths.formatToSongPath(SONG.song);
		trace(songName);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}


		speedChanges.sort(svSort);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % Note.ammo[mania]);
				var gottaHitNote:Bool = section.mustHitSection;

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

				if (songNotes[1] > mania)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (allNotes.length > 0)
					oldNote = allNotes[Std.int(allNotes.length - 1)];
				else
					oldNote = null;

				var type:Dynamic = songNotes[3];
				//if(!Std.isOfType(type, String)) type = editors.ChartingState.noteTypeList[type];

				// TODO: maybe make a checkNoteType n shit but idfk im lazy
				// or maybe make a "Transform Notes" event which'll make notes which don't change texture change into the specified one

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				swagNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
				swagNote.exNote = (section.exSection && (songNotes[1]<Note.ammo[mania]));
				swagNote.noteType = type;
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				swagNote.ID = allNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);


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

				var floorSus:Int = Math.round(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus)
					{
						oldNote = allNotes[Std.int(allNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = type;
						if(sustainNote==null || !sustainNote.alive)
							break;
						sustainNote.ID = allNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						swagNote.unhitTail.push(sustainNote);
						sustainNote.parent = swagNote;
						//allNotes.push(sustainNote);
						sustainNote.fieldIndex = swagNote.fieldIndex;
						playfield.queue(sustainNote);
						allNotes.push(sustainNote);

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

			}
			daBeats += 1;
		}

		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		// playerCounter += 1;

		allNotes.sort(sortByShit);

		for(fuck in allNotes)
			unspawnNotes.push(fuck);
		
		for (field in playfields.members)
		{
			var goobaeg:Array<Note> = [];
			for(column in field.noteQueue){
				if(column.length>=Note.ammo[mania]){
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

		checkEventNote();
		generatedMusic = true;
	}

	public function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}

	public inline function getTimeFromSV(time:Float, event:SpeedEvent)
		return event.position + (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);

	public function getSV(time:Float){
		var event:SpeedEvent = {
			position: 0,
			songTime: 0,
			speed: 1
		};
		for (shit in speedChanges)
		{
			if (shit.songTime <= time && shit.songTime >= shit.songTime)
				event = shit;
		}

		return event;
	}


	public inline function getVisualPosition()
		return getTimeFromSV(Conductor.songPosition, currentSV);

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Mult SV' | 'Constant SV':
				var speed:Float = 1;
				if(event.event == 'Constant SV'){
					var b = Std.parseFloat(event.value1);
					if(Math.isNaN(b))speed = songSpeed;
					speed = songSpeed / b;
				}else{
					speed = Std.parseFloat(event.value1);
					if(Math.isNaN(speed))speed = 1;
				}

				speedChanges.sort(svSort);
				speedChanges.push({
					position: getNoteInitialTime(event.strumTime),
					songTime: event.strumTime,
					speed: speed
				});
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
			case 'False Timer':
				if (timerExtensions == null)
					timerExtensions = new Array();

				timerExtensions.push(event.strumTime);
				maskedSongLength = timerExtensions[0];
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
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

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
	}

	function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.songTime, Obj2.songTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		/*var targetAlpha:Float = 1;
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

			colSwap.hue = ClientPrefs.data.arrowHSV[hsvNumThing][0] / 360;
			colSwap.saturation = ClientPrefs.data.arrowHSV[hsvNumThing][1] / 100;
			colSwap.brightness = ClientPrefs.data.arrowHSV[hsvNumThing][2] / 100;
		}
	}


	public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false)
	{
		var daOldMania = mania;
				
		mania = newValue;

		playerField.strumNotes = [];
		dadField.strumNotes = [];
		setOnLuas('mania', mania);

		notes.forEachAlive(function(note:Note) {updateNote(note);});

		for (noteI in 0...allNotes.length) {
			var note:Note = allNotes[noteI];

			updateNote(note);
		}

		callOnLuas('onChangeMania', [mania, daOldMania]);

		callOnLuas('preReceptorGeneration', []);
		//playerField.generateStrums(0);
		//dadField.generateStrums(1);
		for(field in playfields.members)
			field.generateStrums();

		callOnLuas('postReceptorGeneration', []);
		for(field in playfields.members)
			field.fadeIn(skipStrumFadeOut); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode
		modManager.receptors = [playerField.strumNotes, dadField.strumNotes];
		callOnLuas('preModifierRegister', []);
		modManager.registerDefaultModifiers();
		callOnLuas('postModifierRegister', []);
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				dadVocals.pause();
				bfVocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (startTimer2 != null && !startTimer2.finished)
				startTimer2.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			if (dad2 != null) chars.push(dad2);
			if (bf2 != null) chars.push(bf2);
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
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			paused = false;

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			if (dad2 != null) chars.push(dad2);
			if (bf2 != null) chars.push(bf2);
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
			resetRPC(startTimer != null && startTimer.finished);
			if (startingSong) startCountdownPause();

			if (gf != null)
			{
				#if desktop
				if (startTimer != null && startTimer.finished)
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
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
		stagesFunc(function(stage:BaseStage) stage.onFocus());
		if (gf != null)
		{
			resetRPC(Conductor.songPosition > 0.0);
		}

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		stagesFunc(function(stage:BaseStage) stage.onFocusLost());
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
				noteMiss(daNote, field);

		});
		field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
			notes.add(dunceNote);
			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);

			callOnLuas('onSpawnNotePost', [dunceNote]);
		});
	}

	// Updating Discord Rich Presence.
	function resetRPC(?cond:Bool = false)
	{
		#if desktop
		if (cond)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", if (playAsGF && gf != null) iconGF.getCharacter() else iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		dadVocals.pause();
		bfVocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		if (Conductor.songPosition <= dadVocals.length)
		{
			dadVocals.time = Conductor.songPosition;
			dadVocals.pitch = playbackRate;
		}
		dadVocals.play();
		if (Conductor.songPosition <= bfVocals.length)
		{
			bfVocals.time = Conductor.songPosition;
			bfVocals.pitch = playbackRate;
		}
		bfVocals.play();
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
					strumLineNotes.members[i].downScroll = ClientPrefs.data.downScroll;
					if (ClientPrefs.data.middleScroll)
						strumLineNotes.members[i].alpha = 0.35;
					if (ClientPrefs.data.downScroll)
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

		if (!isStoryMode && playbackRate == 1)
		{
			var daNote:Note = allNotes[0];
			if (daNote != null && daNote.strumTime > 100)
			{
				needSkip = true;
				skipTo = daNote.strumTime - 100;
			}
			else
			{
				needSkip = false;
			}
			
		}

		shaders.ShadersHandler.updateHeat(elapsed);
		if (curStage == 'lavapit') shaders.ShadersHandler.setChrome(0.2);

		if (FlxG.sound.music != null)
			shaders.ShadersHandler.setVisAmpl(FlxG.sound.music.amplitude);

		for(field in playfields)
			field.noteField.songSpeed = songSpeed;

		if(noteHits.length > 0){
			while (noteHits.length > 0 && (noteHits[0] + 2000) < Conductor.songPosition)
				noteHits.shift();
		}

		nps = Math.floor(noteHits.length / 2);
		FlxG.watch.addQuick("notes per second", nps);

		callOnLuas('onUpdate', [elapsed]);
		if (strumFocus)
		{
			if (SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
			{	
				for (i in 0...playerField.strumNotes.length) {
					FlxTween.tween(playerField.strumNotes[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...dadField.strumNotes.length) {
					FlxTween.tween(dadField.strumNotes[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums2.length) {
					FlxTween.tween(opponentStrums2.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
			}
			else if (!SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
			{	
				for (i in 0...playerField.strumNotes.length) {
					FlxTween.tween(playerField.strumNotes[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...dadField.strumNotes.length) {
					FlxTween.tween(dadField.strumNotes[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums2.length) {
					FlxTween.tween(opponentStrums2.members[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
			}
			else if (threeLanes && !SONG.notes[curSection].mustHitSection && SONG.notes[curSection].exSection)
			{	
				for (i in 0...playerField.strumNotes.length) {
					FlxTween.tween(playerField.strumNotes[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...dadField.strumNotes.length) {
					FlxTween.tween(dadField.strumNotes[i], {alpha: 0.3}, 0.1, {ease: FlxEase.sineInOut});
				}
				for (i in 0...opponentStrums2.length) {
					FlxTween.tween(opponentStrums2.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				}
			}
		}
		else if (startingSong)
		{
			for (i in 0...playerField.strumNotes.length) {
				FlxTween.tween(playerField.strumNotes[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
			}
			for (i in 0...dadField.strumNotes.length) {
				FlxTween.tween(dadField.strumNotes[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
			}
			for (i in 0...opponentStrums2.length) {
				FlxTween.tween(opponentStrums2.members[i], {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
			}
		}


		if (cpuControlled && !alreadyChanged && !playAsGF)
		{
			botplayTxt.color = FlxColor.fromInt(CoolUtil.dominantColor(iconP2));
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
		else if (playAsGF && !cpuControlled)
		{
			botplayTxt.color = FlxColor.fromInt(CoolUtil.dominantColor(iconGF));
			scoreTxt.visible = true;
			botplayTxt.visible = true;
			botplayTxt.text = "GFPLAY";
		}
		else if (playAsGF && cpuControlled)
		{
			botplayTxt.color = FlxColor.fromInt(CoolUtil.dominantColor(iconGF));
			scoreTxt.visible = true;
			botplayTxt.visible = true;
			botplayTxt.text = "GFPLAY\n(What song are you playing that you can't tap to the beat?)";
		}

		rotRateSh = curStep / 9.5;
		var sh_toy = -Math.sin(rotRateSh * 2) * sh_r * 0.45;
		var sh_tox = -Math.cos(rotRateSh) * sh_r;

		if (fly)
		{
			dad2.x += (sh_tox - dad2.x) / 12;
			dad2.y += (sh_toy - dad2.y) / 12;
			if (dad2.animation.name == 'idle')
			{
				var pene = 0.07;
				dad2.angle = Math.sin(rotRateSh) * sh_r * pene / 4;
			}
			else
			{
				dad2.angle = 0;
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
			if (bf2 != null)
			{
				if(!startingSong && !endingSong && bf2.animation.curAnim != null && bf2.animation.curAnim.name.startsWith('idle')) {
					boyfriend2IdleTime += elapsed;
					if(boyfriend2IdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
						boyfriend2Idled = true;
					}
				} else {
					boyfriend2IdleTime = 0;
				}
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if (!playAsGF)
		{
			if(ratingName == '?') {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' | NPS: ' + nps;
			} else {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC + ' | NPS: ' + nps;//peeps wanted no integer rating
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
						dadVocals.pause();
						bfVocals.pause();
					}
					openSubState(new PauseSubStateLost(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				}
				else if (playAsGF)
				{
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();
						dadVocals.pause();
						bfVocals.pause();
					}
					openSubState(new PauseSubState(gf.getScreenPosition().x, gf.getScreenPosition().y));
				}
				else {
					if(FlxG.sound.music != null) {
						FlxG.sound.music.pause();
						vocals.pause();
						dadVocals.pause();
						bfVocals.pause();
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

			if (bf2 != null) 
			{
				var mult:Float = FlxMath.lerp(1, iconP12.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP12.scale.set(mult, mult);
				iconP12.updateHitbox();
			}

			var iconOffset:Int = 356;

			iconP1.x = healthBar.width + iconOffset + 30;
			iconP2.x = ((healthBar.width/2)/1) - iconOffset;
			var multA:Float = FlxMath.lerp(1, iconP1.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP1.angle = multA;
			var multA:Float = FlxMath.lerp(1, iconP2.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP2.angle = multA;
			if (iconP22 != null)
			{
				var multA:Float = FlxMath.lerp(1, iconP22.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP22.angle = multA;
				switch (iconP22.type) {
					case SINGLE: iconP22.animation.curAnim.curFrame = 0;
					case WINNING: iconP22.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
					default: iconP22.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);
				}
				iconP22.x = iconP2.x + 25;
			}
			if (iconP12 != null)
			{
				var multA:Float = FlxMath.lerp(1, iconP12.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP12.angle = multA;
				switch (iconP12.type) {
					case SINGLE: iconP12.animation.curAnim.curFrame = 0;
					case WINNING: iconP12.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
					default: iconP12.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);
				}
				iconP12.x = iconP1.x - 25;
			}

			switch (iconP1.type) {
				case SINGLE: iconP1.animation.curAnim.curFrame = 0;
				case WINNING: iconP1.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
				default: iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
			}

			switch (iconP2.type) {
				case SINGLE: iconP2.animation.curAnim.curFrame = 0;
				case WINNING: iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
           		default: iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);
			}
		}
		else
		{
			if (gf != null)
			{
				var mult:Float = FlxMath.lerp(1, iconGF.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				var multA:Float = FlxMath.lerp(1, iconGF.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconGF.angle = multA;
				iconGF.scale.set(mult, mult);
				iconGF.updateHitbox();
				iconGF.x = healthBarGF.getGraphicMidpoint().x - 95;

				if (healthBarGF.percent < 20)
					iconGF.animation.curAnim.curFrame = 1;
				else
					iconGF.animation.curAnim.curFrame = 0;
			}
		}

		if (playAsGF && !cpuControlled)
		{
			if (gf != null)
			{
				//this part is here for latency reasons 
				//(cuz some people dont have rhythm)
				//also yeah i know there are better ways of doing it nut this took me weeks so if you wanna make it better be my guest and let me know
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
				//does this even work?!?
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
			KillNotes();
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
			dadVocals.pause();
			bfVocals.pause();
			Conductor.songPosition = skipTo;

			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();

			vocals.time = Conductor.songPosition;
			vocals.play();
			dadVocals.time = Conductor.songPosition;
			dadVocals.play();
			bfVocals.time = Conductor.songPosition;
			bfVocals.play();
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

				if (updateTime)
				{
					var timeBarType:String = ClientPrefs.data.timeBarType;
					var curTime:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;

					var lengthUsing:Float = (maskedSongLength > 0) ? maskedSongLength : songLength;

					curTime = Math.max(curTime, 0);
					songPercent = (curTime / lengthUsing);

					var songCalc:Float = (lengthUsing - curTime);
					if (timeBarType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(Math.max((songCalc / 1000 * playbackRate), 0));
					if (timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (chromOn){
		
			ch = FlxG.random.int(1,5) / 1000;
			ch = FlxG.random.int(1,5) / 1000;
			shaders.ShadersHandler.setChrome(ch);
			shaders.ShadersHandler.setTriangleX(ch);
			shaders.ShadersHandler.setTriangleY(ch);
			//ShadersHandler.setRadialBlur(640+(FlxG.random.int(-100,100)),360+(FlxG.random.int(-100,100)),FlxG.random.float(0.001,0.005));
			//ShadersHandler.setRadialBlur(640+(FlxG.random.int(-10,10)),360+(FlxG.random.int(-10,10)),FlxG.random.float(0.001,0.005));
		}else{
			if (!beatchrom)
			{
				shaders.ShadersHandler.setChrome(0);
			}
			//ShadersHandler.setRadialBlur(0,0,0);
			shaders.ShadersHandler.setTriangleX(0);
			shaders.ShadersHandler.setTriangleY(0);
			
		}

		if (chromCheck > 0 && (dad.animation.curAnim.name == 'idle' || dad2 != null && dad2.animation.curAnim.name == 'idle'))
		{
			new FlxTimer().start(0.1, function(tmr:FlxTimer) {
				FlxTween.tween(shaders.ShadersHandler, {setChrome: 0}, 1, {ease: FlxEase.circOut});
				FlxTween.tween(chromCheck, {value: 0}, 1, {ease: FlxEase.circOut});
			});
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		barCam.zoom = camHUD.zoom;

		if (beatchrom)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			shaders.ShadersHandler.setChrome(0.1 * abrrmult);
			beatchromfaster = false;
			beatchromfastest = false;
			beatchromslow = false;
		}
		else if (beatchromfaster)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			shaders.ShadersHandler.setChrome(0.1 * abrrmult);
			beatchrom = false;
			beatchromfastest = false;
			beatchromslow = false;
		}
		else if (beatchromfastest)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			shaders.ShadersHandler.setChrome(0.1 * abrrmult);
			beatchrom = false;
			beatchromfaster = false;
			beatchromslow = false;
		}
		else if (beatchromslow)
		{
			abrrmult -= (Conductor.crochet / (400 / (defMult * 10))) * elapsed;
			if (abrrmult < 0)
				abrrmult = 0;
			shaders.ShadersHandler.setChrome(0.1 * abrrmult);
			beatchrom = false;
			beatchromfaster = false;
			beatchromfastest = false;
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		daStatic.animation.play('static');

		currentSV = getSV(Conductor.songPosition);
		Conductor.visualPosition = getVisualPosition();
		FlxG.watch.addQuick("visualPos", Conductor.visualPosition);


		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();
		modManager.updateTimeline(curDecStep);
		modManager.update(elapsed);

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
				} else if(bf2 != null && bf2.holdTimer > Conductor.stepCrochet * 0.001 * bf2.singDuration && bf2.animation.curAnim.name.startsWith('sing') && !bf2.animation.curAnim.name.endsWith('miss')) {
					bf2.dance();
					//boyfriend.animation.curAnim.finish();
				}
				for(field in playfields){
					if(field.isPlayer){
						for(char in field.characters){
							if (char.animation.curAnim != null
								&& char.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * char.singDuration
									&& char.animation.curAnim.name.startsWith('sing')
									&& !char.animation.curAnim.name.endsWith('miss')
									&& (char.idleWhenHold || !pressedGameplayKeys.contains(true)))
								char.dance();

						}
					}
				}
			}

			/*if (ClientPrefs.inputSystem != 'Native')
			{
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
					}

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
			}*/
		}
		checkEventNote();
		
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
		KillNotes();
		cancelMusicFadeTween();
		LoadingState.loadAndSwitchState(new ChartingState(), true);
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && bfkilledcheck || playAsGF && healthGF <= 0)
		{
			savedTime = 0;
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				if (bf2 != null) bf2.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				dadVocals.stop();
				bfVocals.stop();
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
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		
		switch(eventName) {
			case 'Change Focus':
				switch(value1.toLowerCase().trim()){
					case 'dad' | 'opponent':
						moveCamera(true);
					case 'gf':
						moveCamera(false, true);
					case 'dad2' | 'opponent2':
						moveCamera(false, false, true);
					case 'bf2' | 'boyfriend2':
						moveCamera(false, false, false, true);
					default:
						moveCamera(false);
				}
			case 'Enable or Disable Dad Trail':
				shaggyT.visible = value1 == "true" ? true : false;
			case 'Enable or Disable BF Trail':
				bfT.visible = value1 == "true" ? true : false;
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'bf2' | 'boyfriend2' | '00':
						value = 3;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
					case 'dad2' | 'opponent2' | '22':
						value = 4;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				switch (value)
				{
					case 0:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = flValue2;
					case 1:
						if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = flValue2;
						} else if (gf != null) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = flValue2;
						}
					case 2:
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					case 3:
						bf2.playAnim('hey', true);
						bf2.specialAnim = true;
						bf2.heyTimer = flValue2;
					case 4:
						dad2.playAnim('cheer', true);
						dad2.specialAnim = true;
						dad2.heyTimer = flValue2;

				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'bf2' | 'boyfriend2':
						char = bf2;
					case 'dad2' | 'opponent2':
						char = dad2;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
							case 3: char = dad2;
							case 4: char = bf2;
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
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					case 'bf2' | 'boyfriend2':
						char = bf2;
					case 'dad2' | 'opponent2':
						char = dad2;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
							case 3: char = dad2;
							case 4: char = bf2;
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
						}

					case 3:
						if (dad2 != null) 
						{
							if(dad2.curCharacter != value2) {
								if(!dad2Map.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var wasGf:Bool = dad2.curCharacter.startsWith('gf');
								var lastAlpha:Float = dad2.alpha;
								dad2.alpha = 0.00001;
								dad2 = dad2Map.get(value2);
								if(!dad2.curCharacter.startsWith('gf')) {
									if(wasGf && gf != null) {
										gf.visible = true;
									}
								} else if(gf != null) {
									gf.visible = false;
								}
								dad2.alpha = lastAlpha;
								iconP22.changeIcon(dad2.healthIcon);
							}
							setOnLuas('dad2Name', dad2.curCharacter);
						}
					case 4:
						if (bf2 != null)
						{
							if(bf2.curCharacter != value2) {
								if(!boyfriendMap2.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = bf2.alpha;
								bf2.alpha = 0.00001;
								bf2 = boyfriendMap2.get(value2);
								bf2.alpha = lastAlpha;
								iconP12.changeIcon(bf2.healthIcon);
							}
							setOnLuas('bf2Name', bf2.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					LuaUtils.setVarInArray(this, value1, value2);
				}
		
			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;
				
				for(field in playfields){
					field.skipFade = skipTween;
				}

				newMania = Std.parseInt(value1);
				if(Math.isNaN(newMania) && newMania < Note.minMania && newMania > Note.maxMania)
					newMania = Note.defaultMania;
				changeMania(newMania, skipTween);	

			case 'Super Burst':
				powerup();

			case 'Burst Dad':
				burstRelease(dad.getMidpoint().x, dad.getMidpoint().y - 100);
			
			case 'Burst Boyfriend':
				burstRelease(boyfriend.getMidpoint().x, boyfriend.getMidpoint().y - 100);

			case 'Burst BF2':
				burstRelease(bf2.getMidpoint().x, bf2.getMidpoint().y - 100);

			case 'Switch Scroll':
				daAnswer(value1);

			case 'Dad Fly':
				daAnswer2(value1);

			case 'Turn on StrumFocus':
				strumFocus = true;

			case 'Turn off StrumFocus':
				strumFocus = false;

			case 'Fade Out':
				FlxTween.tween(blackOverlay, {alpha: 1}, Std.parseFloat(value1));
				FlxTween.tween(camHUD, {alpha: 0}, Std.parseFloat(value1));

			case 'Fade In':
				FlxTween.tween(blackOverlay, {alpha: 0}, Std.parseFloat(value1));
				FlxTween.tween(camHUD, {alpha: 1}, Std.parseFloat(value1));

			case 'Silhouette':
				theShadow(value1);

			case 'Save Song Posititon':
				trace(Conductor.songPosition);
				savedTime = Conductor.songPosition;
				savedBeat = curBeat;
				savedStep = curStep;

			case 'False Timer':
				if (timerExtensions != null)
				{
					timerExtensions.shift();

					var next:Dynamic = timerExtensions[0];
					var toValue:Float = (next != null && next > 0) ? next : songLength;
					// maskedSongLength = value; instead of tweenMask.bind(timeTxt)
					FlxTween.num(maskedSongLength, toValue, Conductor.crochet / 1000, {
						ease: FlxEase.elasticInOut,
						onComplete: function(twn:FlxTween)
						{
							maskedSongLength = toValue;
							if (twn.active)
								twn.cancel();
							twn.active = false;
							twn.destroy();
						}
					}, function(value:Float) {
						maskedSongLength = value;
					});
				}

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
				if (ClientPrefs.data.flashing)
				{
					switch (value1)
					{
						case '0':
							ravemode = false;
							ravemodeV2 = false;
						case '1':
							ravemode = true;
							ravemodeV2 = false;
						case '2':
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
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnLuas('onEvent', [eventName, value1, value2, strumTime]);
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
				FlxTween.tween(blackUnderlay, {alpha: 0}, 0.1);
				if (dad2 != null) FlxTween.tween(dad2, {color: FlxColor.BLACK}, 0.1);
				if (bf2 != null) FlxTween.tween(bf2, {color: FlxColor.BLACK}, 0.1);
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
				FlxTween.tween(blackUnderlay, {alpha: 1}, 0.1);
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1);
				if (dad2 != null) FlxTween.tween(dad2, {color: 0xecffffff}, 0.1);
				if (bf2 != null) FlxTween.tween(bf2, {color: 0xecffffff}, 0.1);
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
				FlxTween.tween(blackUnderlay, {alpha: 0}, 0.1);
				if (dad2 != null) FlxTween.tween(dad2, {color: FlxColor.WHITE}, 0.1);
				if (bf2 != null) FlxTween.tween(bf2, {color: FlxColor.WHITE}, 0.1);
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
					burst = new FlxSprite(dad.getMidpoint().x - 1000, dad.getMidpoint().y - 100);
					burst.frames = Paths.getSparrowAtlas('characters/shaggy');
					burst.animation.addByPrefix('burst', "burst", 30);
					burst.animation.play('burst');
					//burst.setGraphicSize(Std.int(burst.width * 1.5));
					burst.antialiasing = true;
					add(burst);

					FlxG.sound.play(Paths.sound('powerup'), 1);
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
		burst.frames = Paths.getSparrowAtlas('characters/shaggy');
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

	function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (dad2 != null && SONG.notes[curSection].exSection && !SONG.notes[curSection].mustHitSection)
		{
			camFollow.set(dad2.getMidpoint().x, dad2.getMidpoint().y);
			camFollow.x += dad2.cameraPosition[0] + opponent2CameraOffset[0];
			camFollow.y += dad2.cameraPosition[1] + opponent2CameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['dad2']);
			return;
		}

		if (bf2 != null && SONG.notes[curSection].exSection && SONG.notes[curSection].mustHitSection)
		{
			camFollow.set(bf2.getMidpoint().x, bf2.getMidpoint().y);
			camFollow.x += bf2.cameraPosition[0] + boyfriend2CameraOffset[0];
			camFollow.y += bf2.cameraPosition[1] + boyfriend2CameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['bf2']);
			return;
		}

		if (!SONG.notes[curSection].exSection && !SONG.notes[curSection].gfSection)
		{
			if (!SONG.notes[curSection].mustHitSection)
			{
				moveCamera(true);
				callOnLuas('onMoveCamera', ['dad']);
			}
			else if (SONG.notes[curSection].mustHitSection)
			{
				moveCamera(false);
				callOnLuas('onMoveCamera', ['boyfriend']);
			}
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool, ?isGF:Bool = false, ?isDad2:Bool = false, isBf2:Bool = false)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else if (isGF)
		{
			if (gf != null)
			{
				camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
				camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
				camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
				tweenCamIn();
				callOnLuas('onMoveCamera', ['gf']);
			}
		}
		else if (isDad2)
		{
			if (dad2 != null)
			{
				camFollow.set(dad2.getMidpoint().x, dad2.getMidpoint().y);
				camFollow.x += dad2.cameraPosition[0] + opponent2CameraOffset[0];
				camFollow.y += dad2.cameraPosition[1] + opponent2CameraOffset[1];
				tweenCamIn();
				callOnLuas('onMoveCamera', ['dad2']);
			}
		}
		else if (isBf2)
		{
			if (bf2 != null)
			{
				camFollow.set(bf2.getMidpoint().x, bf2.getMidpoint().y);
				camFollow.x += bf2.cameraPosition[0] + boyfriend2CameraOffset[0];
				camFollow.y += bf2.cameraPosition[1] + boyfriend2CameraOffset[1];
				tweenCamIn();
				callOnLuas('onMoveCamera', ['bf2']);
			}
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

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		dadVocals.volume = 0;
		dadVocals.pause();
		bfVocals.volume = 0;
		bfVocals.pause();
		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	var daEnding:String;
	public function endSong()
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
				return false;
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
		if(achievementObj != null)
			return false;
		else
		{
			var noMissWeek:String = WeekData.getWeekFileName() + '_nomiss';
			var achieve:String = checkForAchievement([noMissWeek, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 
				'debugger', 'smooth_moves', 'way_too_spoopy', 'gf_mode', 'beat_battle', 'beat_battle_master', 'beat_battle_god']);

			if(achieve != null) {
				startAchievement(achieve);
				return false;
			}
		}
		#end	
		
		var ret:Dynamic = callOnLuas('onEndSong', [], false);
		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (!cpuControlled && !playAsGF && saveScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent, songMisses);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
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
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
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
		return true;
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementPopup = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementPopup(achieve, camOther);
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
			allNotes.remove(daNote);
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
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		dadVocals.volume = 1;
		bfVocals.volume = 1;

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
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;
		if (!note.customHealthHit)
		{
			switch (daRating.name)
			{
				case 'marv':
					giveHealthAmount = 0.083;
				case 'sick':
					giveHealthAmount = 0.023;
				case 'good':
					giveHealthAmount = 0.013;
				case 'bad':
					giveHealthAmount = 0.005;
				case 'shit':
					giveHealthAmount = 0.001;
			}
		}

		if(!practiceMode && !cpuControlled) {
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
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.data.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.data.globalAntialiasing;
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
		if (!ClientPrefs.data.comboStacking)
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
			numScore.x = coolText.x + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
			if (!ClientPrefs.data.comboStacking)
				lastScore.push(numScore);

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.data.globalAntialiasing;
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
			numScore.visible = !ClientPrefs.data.hideHud;

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

	/*private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}*/


	var closestNotes:Array<Note> = [];
	public var strumsBlocked:Array<Bool> = [];
	var pressed:Array<FlxKey> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !playAsGF && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.data.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				switch (ClientPrefs.data.inputSystem)
				{
					case 'Native':
						pressed.push(eventKey);
						var hitNotes:Array<Note> = [];
						if(strumsBlocked[key]) return;

						for(field in playfields.members){
							if(!field.autoPlayed && field.isPlayer && field.inControl){
								field.keysPressed[key] = true;
								keysPressed[key] = true;
								if(generatedMusic && !endingSong){
									var note:Note = field.input(key);
									if(note==null){
										var spr:StrumNote = field.strumNotes[key];
										if (spr != null && spr.animation.curAnim.name != 'confirm')
										{
											spr.playAnim('pressed');
											spr.resetAnim = 0;
										}
									}else
										hitNotes.push(note);

								}
							}
						}
						if(hitNotes.length==0){
							if (!ClientPrefs.data.ghostTapping)
							{
								noteMissPress(key);
							}
						}
					case 'Mixtape Input':
						//more accurate hit time for the ratings?
						var lastTime:Float = Conductor.songPosition;
						Conductor.songPosition = FlxG.sound.music.time;

						var canMiss:Bool = !ClientPrefs.data.ghostTapping;

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
									//goodNoteHit(epicNote);
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

							var canMiss:Bool = !ClientPrefs.data.ghostTapping;

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
										//goodNoteHit(epicNote);
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
						if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.data.controllerMode))
						{
							if(!boyfriend.stunned && generatedMusic && !endingSong)
							{
								//more accurate hit time for the ratings?
								var lastTime:Float = Conductor.songPosition;
								Conductor.songPosition = FlxG.sound.music.time;
				
								var canMiss:Bool = !ClientPrefs.data.ghostTapping;
				
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
											//goodNoteHit(epicNote);
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
						var canMiss:Bool = !ClientPrefs.data.ghostTapping;

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

							//goodNoteHit(coolNote);
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
									//if (shitNote.strumTime == daNote.strumTime)
										//goodNoteHit(shitNote);
									//else if ((!shitNote.isSustainNote && (shitNote.strumTime - daNote.strumTime) < 15))
										//goodNoteHit(shitNote);
								}
							}
							//goodNoteHit(daNote);
						}
						else if (!ClientPrefs.data.ghostTapping && generatedMusic)
							noteMissPress(key);

						keysPressed[key] = true;

						//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
						Conductor.songPosition = lastTime;
					case 'Psych (0.6.3)':
						//trace('Pressed: ' + eventKey);

						if (!cpuControlled && !playAsGF && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.data.controllerMode))
						{
							if(!boyfriend.stunned && generatedMusic && !endingSong)
							{
								//more accurate hit time for the ratings?
								var lastTime:Float = Conductor.songPosition;
								Conductor.songPosition = FlxG.sound.music.time;

								var canMiss:Bool = !ClientPrefs.data.ghostTapping;

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
											//goodNoteHit(epicNote);
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
						&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.data.controllerMode)
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
											//goodNoteHit(coolNote); // then hit the note
											pressedNotes.push(coolNote);
										}
										// end of this little check
									}
									//
								}
								else // else just call bad notes
									if (!ClientPrefs.data.ghostTapping)
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
											//goodNoteHit(coolNote); // then hit the note
											pressedNotes.push(coolNote);
										}
										// end of this little check
									}
									//
								}
								else // else just call bad notes
									if (!ClientPrefs.data.ghostTapping)
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
		if (ClientPrefs.data.inputSystem == 'Native') if(pressed.contains(eventKey))pressed.remove(eventKey);
		if(!cpuControlled && !playAsGF && startedCountdown && !paused && key > -1)
		{
			if (ClientPrefs.data.inputSystem != 'Native')
			{
				var spr:StrumNote = playerStrums.members[key];
				if(spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
				if (ClientPrefs.data.inputSystem == 'Kade Engine')
					keysPressed[key] = false;
				callOnLuas('onKeyRelease', [key]);
			}
			else
			{
				// doesnt matter if THIS is done while paused
				// only worry would be if we implemented Lifts
				// but afaik we arent doing that
				// (though could be interesting to add)
				for(field in playfields.members){
					if (field.inControl && !field.autoPlayed && field.isPlayer)
					{
						field.keysPressed[key] = false;
						var spr:StrumNote = field.strumNotes[key];
						if (spr != null)
						{
							spr.playAnim('static');
							spr.resetAnim = 0;
						}
					}
				}
			}
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
	public static var pressedGameplayKeys:Array<Bool> = [];

	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();
		pressedGameplayKeys = parsedHoldArray;
		// FlxG.watch.addQuick('asdfa', upP);
		if((ClientPrefs.data.inputSystem == 'Psych (0.6.3)' || ClientPrefs.data.inputSystem == 'Forever Engine') && ClientPrefs.data.controllerMode)
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
				switch (ClientPrefs.data.inputSystem)
				{
					case 'Native':
						if (parsedHoldArray.contains(true) && !endingSong) {
							#if ACHIEVEMENTS_ALLOWED
							var achieve:String = checkForAchievement(['oversinging']);
							if (achieve != null) {
								startAchievement(achieve);
							}
							#end
						}
					case 'Mixtape Input' | 'ZoroForce EK':
						if (daNote.isSustainNote && dataKeyIsPressed(daNote.noteData) && daNote.canBeHit && daNote.mustPress && !daNote.tooLate
							&& !daNote.wasGoodHit)
						{
							//goodNoteHit(daNote);
						}
					case 'Kade Engine':
						if (daNote.isSustainNote && dataKeyIsPressed(daNote.noteData) && daNote.canBeHit && daNote.mustPress && daNote.susActive)
						{
							//goodNoteHit(daNote);
						}
					case 'Psych (0.6.3)':
						if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
						&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
							//goodNoteHit(daNote);
						}
					case 'Forever Engine':
						if (daNote.canBeHit
							&& daNote.mustPress
							&& !daNote.tooLate
							&& daNote.isSustainNote
							&& strumsBlocked[daNote.noteData] != true){}
							//goodNoteHit(daNote);
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
									&& strumsBlocked[coolNote.noteData] != true){}
										//goodNoteHit(coolNote);
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
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();

			if((ClientPrefs.data.inputSystem == 'Psych (0.6.3)' || ClientPrefs.data.inputSystem == 'Forever Engine' || ClientPrefs.data.inputSystem == 'Native') && (ClientPrefs.data.controllerMode || strumsBlocked.contains(true)))
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

	function noteMiss(daNote:Note, field:PlayField):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		for(note in field.spawnedNotes){
			if(!note.alive || daNote.tail.contains(note) || note.isSustainNote) continue;
			if (daNote != note && field.isPlayer && daNote.noteData == note.noteData && Math.abs(daNote.strumTime - note.strumTime) < 1) 
				field.removeNote(note);
			
		}
		if(!daNote.isSustainNote && daNote.unhitTail.length > 0){
			for(tail in daNote.unhitTail){
				tail.tooLate = true;
				tail.blockHit = true;
				tail.ignoreNote = true;
				health -= daNote.missHealth * healthLoss; // this is kinda dumb tbh no other VSRG does this just FNF
			}
		}
		if(daNote.isSustainNote && daNote.unhitTail.length > 0){
			for(tail in daNote.unhitTail){
				tail.tooLate = true;
				tail.blockHit = true;
				tail.ignoreNote = true;
				health -= daNote.missHealth * healthLoss; // this is kinda dumb tbh no other VSRG does this just FNF
			}
		}
		if(!daNote.isSustainNote){
			health -= daNote.missHealth * healthLoss;
		}
		if(!daNote.noMissAnimation)
		{
			var chars:Array<Character> = daNote.characters;

			if (daNote.gfNote && gf != null)
				chars.push(gf);
			else if (chars.length == 0)
				chars = field.characters;

			if (combo > 10 && gf!=null && chars.contains(gf) == false && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}

			for(char in chars){
				if(char != null)
				{
					var daAlt = (daNote.noteType == 'Alt Animation') ? '-alt' : '';
					var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[Std.int(Math.abs(daNote.noteData))] + 'miss';

					char.playAnim(animToPlay, true);
				}	
			}
		}
		if (!daNote.isSustainNote) // i missed this sound
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		combo = 0;

		bfkilledcheck = true;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			bfVocals.volume = 0;
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
		bfVocals.volume = 0;
		if(!practiceMode && !playAsGF) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}
		if(daNote.exNote) {
			char = bf2;
		}

		if(char != null && char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
		{
			gf.playAnim('sad');
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it
		bfkilledcheck = true;
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				dadVocals.volume = 0;
				bfVocals.volume = 0;
				doDeathCheck(true);
				bfkilledcheck = true;
			}

			if(ClientPrefs.data.ghostTapping) return;

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
			for (field in playfields.members)
			{
				if (!field.isPlayer)
					continue;

				for(char in field.characters)
				{
					char.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
						if(!char.hasMissAnimations)
							char.color = 0xFFC6A6FF;
				}
			}

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			if (bf2 != null && bf2.hasMissAnimations) {
				bf2.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			vocals.volume = 0;
			bfVocals.volume = 0;
		}
	}

	function getFieldFromNote(note:Note){

		for (playfield in playfields)
		{
			if (playfield.hasNote(note))
				return playfield;
		}

		return playfields.members[0];
	}

	function opponentNoteHit(note:Note, field:PlayField):Void
	{

		if (note.wasGoodHit || (field.autoPlayed && (note.ignoreNote || note.breaksCombo)))
			return;

		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		var chars:Array<Character> = note.characters;
		if (note.gfNote)
			chars.push(gf);
		else if (chars.length == 0)
			chars = field.characters;


		for(char in chars){
			if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
				dad.playAnim('hey', true);
				dad.specialAnim = true;
				dad.heyTimer = 0.6;
			} else if(!note.noAnimation) {
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[Std.int(Math.abs(note.noteData))];

				var curSection = SONG.notes[curSection];
				if ((curSection != null && curSection.altAnim) || note.noteType == 'Alt Animation')
					animToPlay += '-alt';

				if (dad != null){
					dad.playAnim(animToPlay, true);
					dad.holdTimer = 0;
				}
			}
		}

		if(!note.noAnimation && !note.exNote) {
			if (dad != null){
				if (!note.animation.curAnim.name.endsWith('tail'))
				{
					var daAlt = (note.noteType == 'Alt Animation') ? '-alt' : '';
					dad.playAnim('sing' + Note.keysShit.get(mania).get('anims')[Std.int(Math.abs(note.noteData))] + daAlt, true);
					dad.holdTimer = 0;
				}
			}
		}

		if(!note.noAnimation && note.exNote && !note.mustPress) {
			if (dad2 != null){
				if (!note.animation.curAnim.name.endsWith('tail'))
				{
					var daAlt = (note.noteType == 'Alt Animation') ? '-alt' : '';
					dad2.playAnim('sing' + Note.keysShit.get(mania).get('anims')[Std.int(Math.abs(note.noteData))] + daAlt, true);
					dad2.holdTimer = 0;
				}
			}
		}

		if (note.visible){
			var time:Float = 0.15;
			if (note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
			time += 0.15;

			StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time, note);
		}

		note.hitByOpponent = true;
		vocals.volume = 1;
		#if LUA_ALLOWED
		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);
		#end

		if (!note.isSustainNote && note.sustainLength == 0)
		{
			field.removeNote(note);
		}
		else if (note.isSustainNote)
			if (note.parent.unhitTail.contains(note))
				note.parent.unhitTail.remove(note);


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


	function goodNoteHit(note:Note, field:PlayField):Void
	{

		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(!note.isSustainNote)
			noteHits.push(Conductor.songPosition);

		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
		
		// Strum animations
		if (note.visible){
			if(field.autoPlayed){
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
					time += 0.15;

				StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time, note);
			}else{
				var spr = field.strumNotes[note.noteData];
				if(spr != null && field.keysPressed[note.noteData])
					spr.playAnim('confirm', true, note);
			}
		}

		//if (cpuControlled)SONG.validScore = false; // if botplay hits a note, then you lose scoring
		
		if(note.hitCausesMiss) {
			switch(note.noteType) {
				case 'Hurt Note': //Hurt note
					if(boyfriend.animation.getByName('hurt') != null) {
						boyfriend.playAnim('hurt', true);
						boyfriend.specialAnim = true;
					}
			}
			note.wasGoodHit = true;
			if (!note.isSustainNote && note.tail.length==0)
				field.removeNote(note);
			else if(note.isSustainNote){
				if (note.parent != null)
					if (note.parent.unhitTail.contains(note))
						note.parent.unhitTail.remove(note);
				
			}
			return;
		}

		if (!note.isSustainNote)
		{
			//combo += 1;
			//popUpScore(note);
			//if(combo > 9999) combo = 9999;
		}

		if (cpuControlled) saveScore = false; // if botplay hits a note, then you lose scoring

		var chars:Array<Character> = note.characters;
		if (note.gfNote)
			chars.push(gf);
		else if(chars.length==0)
			chars = field.characters;


		if(!note.noAnimation) {
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[Std.int(Math.abs(note.noteData))];
			var daAlt = (note.noteType == 'Alt Animation') ? '-alt' : '';

			var curSection = SONG.notes[curSection];
			if ((curSection != null && curSection.altAnim) || note.noteType == 'Alt Animation')
				animToPlay += '-alt';
			
			for(char in chars){
				if (char != null){
					char.playAnim(animToPlay + daAlt, true);
					char.holdTimer = 0;
				}
			}

			if (boyfriend != null && !note.gfNote && !note.exNote){
				if (!note.animation.curAnim.name.endsWith('tail'))
				{
					boyfriend.playAnim(animToPlay, true);
					boyfriend.holdTimer = 0;
					if (gf != null && gf.animation.curAnim.name == 'scared')
					{
						gf.playAnim('danceLeft', true);
					}
				}
			}

			if(!note.noAnimation && note.exNote && note.mustPress) {
				if (bf2 != null){
					if (!note.animation.curAnim.name.endsWith('tail'))
					{
						bf2.playAnim(animToPlay + daAlt, true);
						bf2.holdTimer = 0;
					}
				}
			}

			if (gf != null && note.gfNote){
				if (!note.animation.curAnim.name.endsWith('tail'))
				{
					gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
				if (boyfriend != null && boyfriend.animation.curAnim.name == 'scared')
				{
					boyfriend.playAnim('idle', true);
				}
			}

			if(note.noteType == 'Hey!') {
				if(boyfriend.animOffsets.exists('hey')) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = 0.6;
				}
				if(bf2 != null && bf2.animOffsets.exists('hey')) {
					bf2.playAnim('hey', true);
					bf2.specialAnim = true;
					bf2.heyTimer = 0.6;
				}
				if(gf != null && gf.animOffsets.exists('cheer')) {
					gf.playAnim('cheer', true);
					gf.specialAnim = true;
					gf.heyTimer = 0.6;
				}
			}
		}
		note.wasGoodHit = true;

		if (!note.isSustainNote && !playAsGF)
		{
			combo += 1;
			popUpScore(note);
			//if(combo > 9999) combo = 9999;
		}
		health += giveHealthAmount * healthGain;
		bfkilledcheck = false;
		vocals.volume = 1;
		bfVocals.volume = 1;
		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;
		callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if (!note.isSustainNote && note.tail.length == 0)
			field.removeNote(note);
		else if (note.isSustainNote)
		{
			if (note.parent != null)
				if (note.parent.unhitTail.contains(note))
					note.parent.unhitTail.remove(note);
		}
		/*if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if((cpuControlled || playAsGF) && (note.ignoreNote || note.hitCausesMiss)) return;

			if(!note.isSustainNote) noteHits.push(Conductor.songPosition);

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

			if (!note.isSustainNote && note.tail.length == 0)
			field.removeNote(note);
			else if (note.isSustainNote)
			{
				if (note.parent != null)
					if (note.parent.unhitTail.contains(note))
						note.parent.unhitTail.remove(note);
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				//if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				//var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];
				if(note.gfNote) 
				{
					if(gf != null)
					{
						if (note.isSustainNote && note.tail.length != 0 || !note.isSustainNote)
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
						if (note.isSustainNote && note.tail.length != 0 || !note.isSustainNote)
						{
							dad2.playAnim(animToPlay + daAlt, true);
							dad2.holdTimer = 0;
						}
					}
				}
				else
				{
					if (note.isSustainNote && note.tail.length != 0 || !note.isSustainNote || cpuControlled)
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
		}*/
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

	function lightningStrikeShitAlt():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared'))
		{
			boyfriend.playAnim('scared', true);
		}
		if (bf2 != null && bf2.animOffsets.exists('scared'))
		{
			bf2.playAnim('scared', true);
		}
		if(gf != null)
		{
			if (gf.animOffsets.exists('scared'))
			{
				gf.playAnim('scared', true);
			}
		}

		if (ClientPrefs.data.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming)
			{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.data.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
			FlxG.camera.flash(FlxColor.WHITE);
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

		if(!ClientPrefs.data.controllerMode)
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
		if (vocals != null)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && !SONG.newVoiceStyle && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		if (bfVocals != null)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && SONG.newVoiceStyle && Math.abs(bfVocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		if (dadVocals != null)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && SONG.newVoiceStyle && Math.abs(dadVocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}
		
		if (curSong.toLowerCase() == 'testimony')
		{
			if (curStep == 1953)
			{
				playerField.set_camera(camOther);
				playerField.cameras = [camOther];
				healthBar.cameras = [camOther];
				camHUD.alpha = 0;
			}
			if (curStep == 2465)
			{
				playerField.set_camera(camHUD);
				playerField.cameras = [camHUD];
				healthBar.cameras = [camHUD];
				camHUD.alpha = 1;
			}
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

		/*if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}*/

		if (curBeat % 4 / gfSpeed == 0) didLastBeat = false;

		if (!playAsGF)
		{

			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
			if (dad2 != null)
				iconP22.scale.set(1.2, 1.2);
			if (bf2 != null)
				iconP12.scale.set(1.2, 1.2);

			if (curBeat % 2 / gfSpeed == 0)
			{ 
				iconP1.angle = -15;
				iconP2.angle = -15;
				if (iconP22 != null) iconP22.angle = -15;
				if (iconP12 != null) iconP12.angle = -15;
			}
			else if (curBeat % 2 / gfSpeed == 1)
			{
				iconP1.angle = 15;
				iconP2.angle = 15;
				if (iconP22 != null) iconP22.angle = 15;
				if (iconP12 != null) iconP12.angle = 15;
			}

			iconP1.updateHitbox();
			iconP2.updateHitbox();
			if (dad2 != null)
				iconP22.updateHitbox();
			if (bf2 != null)
				iconP12.updateHitbox();
		}
		else
		{
			if (gf != null)
			{
				if (gf.animation.curAnim.name=='danceRight') iconGF.angle = -15;
				else if (gf.animation.curAnim.name=='danceLeft') iconGF.angle = 15;
			}
			else
			{
				if (curBeat % 4 / gfSpeed == 0) iconGF.angle = -15;
				else if (curBeat % 4 / gfSpeed == 2) iconGF.angle = 15;
			}
			iconGF.updateHitbox();
		}

		if ((ravemode || ravemodeV2) && camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.flashing)
		{
			if (ClientPrefs.data.flashing) {
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
		if (bf2 != null && curBeat % bf2.danceEveryNumBeats == 0 && bf2.animation.curAnim != null && !bf2.animation.curAnim.name.startsWith('sing') && !bf2.stunned)
		{
			bf2.dance();
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

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
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

	#if LUA_ALLOWED
	public function startLuasOnFolder(luaFile:String)
	{
		for (script in luaArray)
		{
			if(script.scriptName == luaFile) return false;
		}

		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		else
		{
			luaToLoad = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
				return true;
			}
		}
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		#end
		return false;
	}
	#end


	public var lastUpdatedDownscroll = false;
	public function forceChange(bool:Bool)
	{
		trace('changing downscroll to ' + bool);
		ClientPrefs.data.downScroll = bool;
		//ClientPrefs.downScroll = bool;
		//SaveData.P2downscroll = bool;
		lastUpdatedDownscroll = bool;
		if (ClientPrefs.data.downScroll)
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
				iconP1.y = healthBar.y + 75;
				iconP2.y = healthBar.y - 75;
				if (dad2 != null)
					iconP22.y = healthBar.y - 115;
				if (bf2 != null)
					iconP12.y = healthBar.y - 115;
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
				iconP1.y = healthBar.y + 75;
				iconP2.y = healthBar.y - 75;
				if (dad2 != null)
					iconP22.y = healthBar.y - 115;
				if (bf2 != null)
					iconP12.y = healthBar.y - 115;
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

	function StrumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note) {
		var spr:StrumNote = field.strumNotes[id];

		if(spr != null) {
			spr.playAnim('confirm', true, note);
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
			fullComboFunction();
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
		var songName:String = Paths.formatToSongPath(SONG.song);

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				
				if (achievementName == WeekData.getWeekFileName() + '_nomiss') // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				if (achievementName == 'smooth_moves' && songName.toLowerCase() == 'tutorial')
				{
					if(CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 
						&& !changedDifficulty && !usedPractice && ratingName == 'SFC' && !playAsGF)
						unlock = true;
				}
				if (achievementName == 'way_too_spoopy' && WeekData.getCurrentWeek().weekName == 'week2')
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice && !playAsGF)
						unlock = true;
				}
				if (achievementName == 'beat_battle' && songName.toLowerCase() == 'beat batte')
				{
					if((CoolUtil.difficultyString() == 'REASONABLE' || CoolUtil.difficultyString() == 'UNREASONABLE' || CoolUtil.difficultyString() == 'SEMIIMPOSSIBLE' || CoolUtil.difficultyString() == 'IMPOSSIBLE') 
						&& !changedDifficulty && !usedPractice && !playAsGF)
						unlock = true;
				}
				if (achievementName == 'beat_battle_master' && songName.toLowerCase() == 'beat batte')
				{
					if((CoolUtil.difficultyString() == 'REASONABLE' || CoolUtil.difficultyString() == 'UNREASONABLE' || CoolUtil.difficultyString() == 'SEMIIMPOSSIBLE' || CoolUtil.difficultyString() == 'IMPOSSIBLE') 
						&& !changedDifficulty && !usedPractice && songMisses < 11 && !playAsGF)
						unlock = true;
				}
				if (achievementName == 'beat_battle_god' && songName.toLowerCase() == 'beat batte')
				{
					if((CoolUtil.difficultyString() == 'SEMIIMPOSSIBLE' || CoolUtil.difficultyString() == 'IMPOSSIBLE') 
						&& !changedDifficulty && !usedPractice && songMisses < 26 && !playAsGF)
						unlock = true;
				}
				switch(achievementName)
				{
					case 'ur_bad':
						if(ratingPercent < 0.2 && !usedPractice && !playAsGF) {
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
						if(!usedPractice && Note.ammo[mania] > 2 && !playAsGF) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice && !playAsGF) {
							unlock = true;
						}
					case 'not_4k':
						if(chartModifier == "4K Only" && Note.ammo[mania] == 2 && !usedPractice && !playAsGF) {
							unlock = true;
						}
					case 'gf_mode':
						if(playAsGF && !usedPractice) {
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
