package states;

import backend.Highscore;
import stages.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import haxe.Json;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if !flash
import openfl.filters.ShaderFilter;
#end

import shaders.ErrorHandledShader;

import objects.VideoSprite;
import objects.Note.EventNote;
import objects.NoteObject;
import objects.*;
import stages.*;
import stages.objects.*;

import metadata.STMetaFile.MetadataFile;

import backend.modchart.Modifier;
import backend.modchart.ModManager;
import objects.playfields.*;
import objects.playfields.PlayField.NoteCallback;
import objects.Note.SustainPart;

import backend.AIPlayer;

#if LUA_ALLOWED
import psychlua.*;
using psychlua.IntegratedScript;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/

 /*
	okay SO im gonna explain how these work

	All speed changes are stored in an array, .sort()'d by the time
	if changes[0].songTime is above conductor.songposition then 
		- it'll remove the first element of changes
		- it'll store the position, songTime and speed of the change somewhere
		- and then it'll songVisualPos = event.position + getVisPos(conductor.songPosition - event.songTime, songSpeed * event.speed)

	all notes will also store their visualPos in a variable when creation and then when moving notes it's just
		note.y = note.visualPos - event.position
	:3

	EDIT: not EXACTLY how it works but its a good enough summary
*/
typedef SpeedEvent =
{
	position:Float, // the y position where the change happens (modManager.getVisPos(songTime))
	startTime:Float, // the song position (conductor.songTime) where the change starts
	#if EASED_SVs
	startSpeed:Float, // the previous event's speed
	?endTime:Float, // the song position (conductor.songTime) when the change ends
	?easeFunc:EaseFunction,
	#end
	speed:Float // speed mult after the change
}
@:noScripting
class PlayState extends MusicBeatState
{
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
	public var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var boyfriendMap2:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap2:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end


	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
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
	public var currentRate:Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var boyfriendGroup2:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var dadGroup2:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;
	var raveLight:FlxSprite;
	var raveLightsColors:Array<Int>;
	var ravemode:Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;
	public var gfVocals:FlxSound;

	public var dad:Character = null;
	public var dad2:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	public var bf2:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	public var curEvents:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var MaxHP:Float = 2;
	public var extraHealth:Float = 0;
	public var noHeal:Bool = false;
	public var combo:Int = 0;
	public var comboOpp:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	@:noCompletion function set_cpuControlled(value:Bool):Bool {
		cpuControlled = value;

		setOnScripts('botPlay', value);

		/// oughhh
		for (playfield in playfields.members){
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled || ClientPrefs.getGameplaySetting('showcase', false);
		}

		return value;
	}

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP12:HealthIcon;
	public var iconP22:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camCredit:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
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
	private var singAnimations:Array<String> = Note.keysShit.get(mania).get('singAnims');

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var boyfriend2CameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var opponent2CameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = [];
	public var legacyLuaArray:Array<LegacyFunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	public static var keysArray:Array<Array<Dynamic>>;
	private var controlArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;

	// Start of Mixtape Engine's large amount of bull
	public static var mania:Int = 3;
	public static var gameplayArea:String = "Story";
	public static var Crashed:Bool = false;
	public static var savedTime:Float = 0;
	public static var playAsGF:Bool = false;
	private var specialOverlays:FlxTypedGroup<FlxSprite>;
	private var timerExtensions:Array<Float>;
	public var introStageBar:FlxSprite;
	public var introStageText:FlxTypedGroup<FlxText>;
	public var introStageStuff:FlxTypedGroup<Dynamic>;
	public var mashViolations:Int = 0;
	public var mashing:Int = 0;
	public var maskedSongLength:Float = -1;
	public var saveMod:String = ""; // The modifier that allows sperate saves depending how how you want to play the game
	public var lyrics:FlxText;
	public var rainIntensity:Float = 0;
	var lastUpdateTime:Float = 0.0;
	var endingTimeLimit:Int = 20;
	var metadata:MetadataFile;
	var hasMetadataFile:Bool = false;
	var Text:Array<String> = [];
	var whiteBG:FlxSprite;
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText;
	var skipTo:Float;
	var blackOverlay:FlxSprite;
	var blackUnderlay:FlxSprite;
	var credText:Array<String> = [];
	var songTxt:FlxText;
	var artistTxt:FlxText;
	var charterTxt:FlxText;
	var modTxt:FlxText;

	// AI things. You wouldn't get it.
	var AIMode:Bool = false;
	var AIDifficulty:String = 'Average FNF Player';

	// things from trials
	public var bfkilledcheck:Bool = false;
	public var freezeNotes:Bool = false;
	public var localFreezeNotes:Bool = false;
	var justmissed:Bool = false;
	var middlecircle:FlxSprite;
	var hasGlow:Bool = false;
	var strumFocus:Bool = false;
	var daStatic:FlxSprite;
	var thunderON:Bool = false;
	var gfScared:Bool = false;

	// Troll Engine
	private var AIScore:Int = 0;
	private var AIMisses:Int = 0;
	private var AITotalNotesHit:Float = 0;
	private var AITotalPlayed:Int = 0;
	public var modManager:ModManager;
	public var notefields = new NotefieldRenderer();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes
	public var playerField:PlayField;
	public var dadField:PlayField;
	public var holdsGiveHP:Bool = false;
	public var playerScoreTxt:FlxText;
	public var opponentScoreTxt:FlxText;
	public var ratingNameAI:String = '?';
	public var ratingPercentAI:Float;
	public var ratingFCAI:String;
	public var currentSV:SpeedEvent = {position: 0, startTime: 0, speed: 1 #if EASED_SVs , startSpeed: 1 #end};
	var speedChanges:Array<SpeedEvent> = [];
	var aiText:String;

	public var camGamefilters:Array<BitmapFilter> = [];
	public var camHUDfilters:Array<BitmapFilter> = [];
	public var camVisualfilters:Array<BitmapFilter> = [];
	public var camOtherfilters:Array<BitmapFilter> = [];
	public var camDialoguefilters:Array<BitmapFilter> = [];
	public var delayOffset:Float = 0; // for the delay effect
	
	public var chartModifier:String = 'Normal';
	public var convertMania:Int = ClientPrefs.getGameplaySetting('convertMania', 3);
	public var opponentmode:Bool = ClientPrefs.getGameplaySetting('opponentplay', false);
	public var bothMode:Bool = ClientPrefs.getGameplaySetting('bothMode', false);
	public var loopMode:Bool = ClientPrefs.getGameplaySetting('loopMode', false);
	public var loopModeChallenge:Bool = ClientPrefs.getGameplaySetting('loopModeC', false);
	public var loopPlayMult:Float = ClientPrefs.getGameplaySetting('loopPlayMult', 1.05);
	public var maniaMode:Bool = ClientPrefs.getGameplaySetting('maniaMode', false);
	public var RandomSpeedChange:Bool = ClientPrefs.getGameplaySetting('randomspeedchange', false);
	public var gimmicksAllowed:Bool = false;
	public var mixupMode:Bool = false;

	// Archipelago / Streamer Vs. Chat stuff
	public var instVolumeMultiplier:Float = 1;
	public var vocalVolumeMultiplier:Float = 1;
	var inArchipelagoMode:Bool = false;

	// End of Mixtape Engine's large amount of bull


	override public function create()
	{
		if (SONG == null) {
			var songLowercase:String = Paths.formatToSongPath('tutorial');
			var poop:String = Highscore.formatSong(songLowercase, storyDifficulty);	
			Song.loadFromJson(poop, songLowercase);
		}
		inArchipelagoMode = archipelago.APEntryState.inArchipelagoMode;
		if (inArchipelagoMode && !(this is archipelago.APPlayState))
		{
			FlxG.switchState(new archipelago.APPlayState());
		}
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		if(nextReloadAll)
		{
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;

		modManager = new ModManager(this);
		setOnScripts("modManager", modManager);
		setOnScripts("newPlayField", newPlayfield);
		setOnScripts("initPlayfield", initPlayfield);

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = backend.Keybinds.fill();

		controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];

		speedChanges.push({
			position: -6000 * 0.45,
			startTime: -6000,
			speed: 1, 
			#if EASED_SVs
			startSpeed: 1,
			#end
		});

		// Because some things do actually use these lol
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		chartModifier = ClientPrefs.getGameplaySetting('chartModifier', 'Normal');
		trace("Chart Modifier: " + chartModifier);
		bothMode = ClientPrefs.getGameplaySetting('bothMode', false);
		mixupMode = (ClientPrefs.data.mixupMode /*|| SONG.song == "Small Argument" && !inArchipelagoMode*/) && !bothMode;
		opponentmode = ClientPrefs.getGameplaySetting('opponentplay', false) && !bothMode;
		playAsGF = ClientPrefs.getGameplaySetting('gfMode', false) && !bothMode && !opponentmode; // dont do it to yourself its not worth it
		holdsGiveHP = ClientPrefs.getGameplaySetting('holdsgivehp', holdsGiveHP);
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		AIMode = ClientPrefs.data.mixupMode && !bothMode;
		AIDifficulty = /*(SONG.song == "Small Argument" && !inArchipelagoMode) ? "Baby Mode" : */ClientPrefs.data.aiDifficulty;
		gimmicksAllowed = ClientPrefs.data.gimmicksAllowed;
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		if (bothMode)
			saveMod += "-bothMode";
		else if (opponentmode)
			saveMod += "-opponentMode";
		else if (playAsGF)
			saveMod += "-gfMode";
		if (chartModifier != "Normal")
			saveMod += "-" + chartModifier;
		if (!gimmicksAllowed)
			saveMod += "-noGimmick";
		if (!ClientPrefs.data.modcharts)
			saveMod += "-noModchart";
		if (ClientPrefs.data.noAntimash)
			saveMod += "-noAntimash";
		if (!ClientPrefs.data.drain)
			saveMod += "-noHealthDrain";
		if (!ClientPrefs.data.useMarvs)
			saveMod += "-noMarvs";
		if (loopModeChallenge)
			saveMod += "-endlessChallenge";
		else if (loopMode)
			saveMod += "-endless";

		AIPlayer.active = AIMode && !bothMode;
		switch (AIDifficulty)
		{
			case 'Baby Mode':
				AIPlayer.diff = 0;
			case 'Easier':
				AIPlayer.diff = 1;
			case 'Normal':
				AIPlayer.diff = 2;
			case 'Harder':
				AIPlayer.diff = 3;
			case 'Hardest':
				AIPlayer.diff = 4;
			case 'Average FNF Player':
				AIPlayer.diff = 5;
			case 'Dont':
				AIPlayer.diff = 6;
		}

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camCredit = new FlxCamera();
		camOther = new FlxCamera();
		camCredit.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camCredit, false);
		FlxG.cameras.add(camOther, false);
		
		try
		{
			metadata = cast Json.parse(Assets.getText(Paths.json(Paths.formatToSongPath(SONG.song.toLowerCase()) + '/meta')));
			trace(Assets.getText(Paths.json(Paths.formatToSongPath(SONG.song.toLowerCase()) + '/meta')));
			trace(metadata);
			hasMetadataFile = true;
			trace("Found metadata for " + SONG.song.toLowerCase());
		}
		catch (e)
		{
			try
			{
				trace("No metadata for " + SONG.song.toLowerCase());
			}
			catch (e)
			{
				trace("No metadata found. No song either apparently.");
			}
		}
		persistentUpdate = true;
		persistentDraw = true;

		convertMania = ClientPrefs.getGameplaySetting('convertMania', 3);

		if (chartModifier == "4K Only")
			mania = 3;
		else if (chartModifier == "ManiaConverter")
			mania = convertMania;
		else if (SONG.mania != null)
			mania = SONG.mania;
		else mania = 3;

		if (mania > Note.maxMania)
			mania = Note.defaultMania;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		if (stageData.boyfriend2 != null) 
		{BF2_X = stageData.boyfriend2[0];
		BF2_Y = stageData.boyfriend2[1];}
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		if (stageData.opponent2 != null)
		{DAD2_X = stageData.opponent2[0];
		DAD2_Y = stageData.opponent2[1];}

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriend2CameraOffset = stageData.camera_boyfriend2;
		if (boyfriend2CameraOffset == null)
			boyfriend2CameraOffset = [0, 0];

		opponent2CameraOffset = stageData.camera_opponent2;
		if (opponent2CameraOffset == null)
			opponent2CameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		boyfriendGroup2 = new FlxSpriteGroup(BF2_X, BF2_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		dadGroup2 = new FlxSpriteGroup(DAD2_X, DAD2_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage':
				new StageWeek1(); // Week 1
			case 'spooky':
				new Spooky(); // Week 2
			case 'philly':
				new Philly(); // Week 3
			case 'limo':
				new Limo(); // Week 4
			case 'mall':
				new Mall(); // Week 5 - Cocoa, Eggnog
			case 'mallEvil':
				new MallEvil(); // Week 5 - Winter Horrorland
			case 'school':
				new School(); // Week 6 - Senpai, Roses
			case 'schoolEvil':
				new SchoolEvil(); // Week 6 - Thorns
			case 'tank':
				new Tank(); // Week 7 - Ugh, Guns, Stress
			case 'phillyStreets':
				new PhillyStreets(); // Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin':
				new PhillyBlazin(); // Weekend 1 - Blazin
			case 'mainStageErect':
				new MainStageErect(); // Week 1 Special
			case 'spookyMansionErect':
				new SpookyMansionErect(); // Week 2 Special
			case 'phillyTrainErect':
				new PhillyTrainErect(); // Week 3 Special
			case 'limoRideErect':
				new LimoRideErect(); // Week 4 Special
			case 'mallXmasErect':
				new MallXmasErect(); // Week 5 Special
			case 'phillyStreetsErect':
				new PhillyStreetsErect(); // Weekend 1 Special
			#if windows 
			case 'desktop':
				new Desktop(); // Literally your desktop as a stage lmao
			#end
		}
		if (isPixelStage) introSoundsSuffix = '-pixel';

		var zoomOut = 1 / defaultCamZoom;
		var screenWidth = Std.int(FlxG.width * zoomOut * 2);
		var screenHeight = Std.int(FlxG.height * zoomOut * 2);

		whiteBG = new FlxSprite(-480, -480).makeGraphic(screenWidth, screenHeight, FlxColor.WHITE);
		whiteBG.updateHitbox();
		whiteBG.antialiasing = true;
		whiteBG.scrollFactor.set(0, 0);
		whiteBG.active = false;
		whiteBG.alpha = 0.0;
		blackOverlay = new FlxSprite(0, 0).makeGraphic(screenWidth, screenHeight, FlxColor.BLACK);
		blackOverlay.updateHitbox();
		blackOverlay.screenCenter();
		blackOverlay.antialiasing = true;
		blackOverlay.scrollFactor.set(0, 0);
		blackOverlay.alpha = maniaMode ? 1 : 0;
		blackUnderlay = new FlxSprite(0, 0).makeGraphic(screenWidth, screenHeight, FlxColor.BLACK);
		blackUnderlay.updateHitbox();
		blackUnderlay.screenCenter();
		blackUnderlay.antialiasing = true;
		blackUnderlay.scrollFactor.set(0, 0);
		blackUnderlay.active = false;
		blackUnderlay.alpha = 0;
		specialOverlays = new FlxTypedGroup<FlxSprite>();
		specialOverlays.add(whiteBG);
		specialOverlays.add(blackOverlay);
		specialOverlays.add(blackUnderlay);

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		if (SONG.player4 != null)
		{
			dad2 = new Character(0, 0, SONG.player4);
			startCharacterPos(dad2, true);
			dadGroup2.add(dad2);
			//threeLanes = true; later
		}
		else dad2 = null;

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		if (SONG.player5 != null)
		{
			bf2 = new Character(0, 0, SONG.player5, true);
			startCharacterPos(bf2, true);
			boyfriendGroup2.add(bf2);
		}
		else bf2 = null;
		
		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, dadGroup2, boyfriendGroup2, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup);
			add(dadGroup2);
			add(boyfriendGroup2);
			add(dadGroup);
			add(boyfriendGroup);
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					(ClientPrefs.getGameplaySetting('legacyMode', false) ? new LegacyFunkinLua(folder + file) : new FunkinLua(folder + file));
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			
		#end
}	
			
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
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

		if (dad2 != null && dad2.curCharacter.startsWith('gf')) {
			dad2.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('stages/' + curStage + '.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('stages/' + curStage + '.hx'); #end

		// CHARACTER SCRIPTS
		if(gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);
		if(bf2 != null) startCharacterScripts(bf2.curCharacter);
		if(dad2 != null) startCharacterScripts(dad2.curCharacter);
		#end

		addBehindGF(whiteBG);
		addBehindGF(blackUnderlay);
		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);

		if (ClientPrefs.data.doubleGhosts) {
			trace("Running Double Ghost");
			IntegratedScript.runNamelessHScript("
			import psychlua.LuaUtils;

			var options = {
				alphaToSubtract: 0.3,
				blendMode: 'add',
				fadeTime: 0.2,
				easeType: 'expoIn'
			}

			var getCharFromString = function(name:String) {
				switch (name) {
					case 'dad': return game.dad;
					case 'gf': return game.gf != null ? game.gf : (daNote.mustPress ? game.boyfriend : game.dad);
					case 'boyfriend': return game.boyfriend;
					case '': return null;
					default: return getVar(name);
				}
				return null;
			}
			function jumpCheck(daNote:Note, setChar:String, ?useFakeNoAnim:Bool = false) {
				if (!daNote.isSustainNote) {
					debugPrint('Ghost Check');
					final char:Character = getCharFromString(setChar); if (char == null) return;
					final prevNote:Note = char.extraData.exists('prevNote') ? char.extraData.get('prevNote') : null;
					final noAnim:Bool = useFakeNoAnim ? (daNote.extraData.exists('noAnimation') ? daNote.extraData.get('noAnimation') : false) : daNote.noAnimation;
					final prevNoAnim:Bool = prevNote == null ? !useFakeNoAnim : (useFakeNoAnim ? (prevNote.extraData.exists('noAnimation') ? prevNote.extraData.get('noAnimation') : false) : prevNote.noAnimation);
					if (prevNote != null && ((!noAnim && prevNoAnim) || (noAnim && !prevNoAnim) || (!noAnim && !prevNoAnim))) {
						if (prevNote.strumTime == daNote.strumTime && prevNote.noteData != daNote.noteData) {
							final setNote:Note = prevNote.sustainLength > daNote.sustainLength ? daNote : prevNote;
							setNote.extraData.set('noAnimation', true);
							setNote.noAnimation = true;
							for (susNote in setNote.tail) {
								susNote.extraData.set('noAnimation', true);
								susNote.noAnimation = true;
							}
							// if (setNote == prevNote) char.playAnim(game.singAnimations[setNote.noteData] + setNote.animSuffix, true);
							createAfterImage(setChar, setNote);
							createGlobalCallback('ghostAnim', setNote);
						}
					}
					char.extraData.set('prevNote', daNote);
				}
				if (daNote.extraData.exists('afterImage') && daNote.extraData.get('afterImage') != null) {
					final afterImage:Character = daNote.extraData.get('afterImage');
					if (!afterImage.stunned) {
						afterImage.playAnim(game.singAnimations[daNote.noteData] + daNote.animSuffix, true);
						afterImage.holdTimer = 0;
					}
				}
			}
			// Normal note hits.
			function opponentNoteHitPre(daNote:Note) jumpCheck(daNote, daNote.gfNote ? 'gf' : 'dad');
			function goodNoteHitPre(daNote:Note) jumpCheck(daNote, daNote.gfNote ? 'gf' : 'boyfriend');
			// Extra for vs impostor stuff I'm working on.
			function gfNoteHitPre(daNote:Note) jumpCheck(daNote, 'gf');
			function momNoteHitPre(daNote:Note) jumpCheck(daNote, 'mom');
			// For extra character script.
			function extraNoteHitPre(daNote:Note, setChar:Dynamic, isPlayerNote:Bool) jumpCheck(daNote, setChar.name, true);
			function otherStrumHitPre(daNote:Note, strumLane) jumpCheck(daNote, strumLane.attachmentVar == 'gfNote' ? 'gf' : '');

			// decided to make it not kill it because the game would yell at you after hitting a note with the dead after image... even tho there are NULL CHECKS
			function killAfterImage(daNote:Note) {
				if (daNote.extraData.exists('afterImage') && daNote.extraData.get('afterImage') != null) {
					final afterImage:Character = daNote.extraData.get('afterImage');
					FlxTween.tween(afterImage.colorTransform, {alphaMultiplier: 0}, (options.fadeTime / 2) / game.playbackRate, {ease: LuaUtils.getTweenEaseByString(options.easeType)});
					afterImage.playAnim(game.singAnimations[daNote.noteData] + (afterImage.hasMissAnimations ? 'miss' : '') + daNote.animSuffix, true);
					afterImage.stunned = true;
				}
			}
			function noteMiss(daNote:Note) killAfterImage(daNote);
			function opponentNoteMiss(daNote:Note) killAfterImage(daNote); // jic
			function extraNoteMiss(daNote:Note, setChar:Dynamic, isPlayerNote:Bool) killAfterImage(daNote);

			function createAfterImage(char:String, daNote:Note) {
				final mainChar:Character = getCharFromString(char);
				if (mainChar == null || !mainChar.visible || mainChar.alpha < 1 || daNote.extraData.exists('afterImage')) return;

				var groupCheck = function(char:Character) {
					switch (char) {
						case game.dad: return game.dadGroup;
						case game.gf: return game.gfGroup;
						case game.boyfriend: return game.boyfriendGroup;
						default: return char;
					}
					return;
				}
				var afterImage:Character = new Character(mainChar.x, mainChar.y, mainChar.curCharacter, mainChar.isPlayer);
				afterImage.camera = mainChar.camera;
				insert(game.members.indexOf(groupCheck(mainChar)), afterImage);
				

				// Tell me if there's anything else I should add!
				afterImage.flipX = mainChar.flipX;
				afterImage.flipY = mainChar.flipY;
				afterImage.scale.x = mainChar.scale.x; // would've done copyFrom if it wouldn't fucking crash
				afterImage.scale.y = mainChar.scale.y;
				afterImage.alpha = mainChar.alpha - options.alphaToSubtract;
				afterImage.shader = mainChar.shader;
				afterImage.blend = LuaUtils.blendModeFromString(options.blendMode);

				afterImage.skipDance = true; // prevent after image from going idle
				afterImage.color = FlxColor.fromRGB(mainChar.healthColorArray[0] + 50, mainChar.healthColorArray[1] + 50, mainChar.healthColorArray[2] + 50);
				if (!afterImage.stunned) { // jic
					afterImage.playAnim(game.singAnimations[daNote.noteData] + daNote.animSuffix, true);
					afterImage.holdTimer = 0;
				}
				
				daNote.extraData.set('afterImage', afterImage); // funny sustain shit
				for (susNote in daNote.tail) susNote.extraData.set('afterImage', afterImage);
				FlxTween.tween(afterImage, {alpha: 0}, options.fadeTime / game.playbackRate, {
					ease: LuaUtils.getTweenEaseByString(options.easeType),
					startDelay: ((daNote.sustainLength / 1000) - (options.fadeTime / 2)) / game.playbackRate,
					onComplete: function(_) {
						daNote.extraData.remove('afterImage'); // jic
						for (susNote in daNote.tail) susNote.extraData.remove('afterImage');
						afterImage.kill();
						afterImage.destroy();
					}
				});
			}
			");
		}

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		//noteGroup.add(strumLineNotes);

		//// Generate playfields so you can actually, well, play the game
		#if ALLOW_DEPRECATION
		callOnScripts("prePlayfieldCreation"); // backwards compat
		// TODO: add deprecation messages to function callbacks somehow
		#end
		callOnScripts("onPlayfieldCreation"); // you should use this
		playfields.cameras = [camHUD];
		
		trace("Making New Playfields!");
		modManager.playerAmount = 2;
		for (i in 0...modManager.playerAmount)
			newPlayfield();

		trace("Making PlayerField!");
		playerField = playfields.members[0];
		if (playerField != null) {
			playerField.noteField.isEditor = false;
			playerField.characters = [for(ch in boyfriendMap) ch];
			playerField.isPlayer = !opponentmode && !playAsGF || bothMode;
			playerField.autoPlayed = !playerField.isPlayer || opponentmode || cpuControlled || playAsGF;
			playerField.noteHitCallback = opponentmode ? opponentNoteHit : goodNoteHit;
		}

		trace("Making DadField!");
		dadField = playfields.members[1];
		if (dadField != null) {
			dadField.noteField.isEditor = false;
			dadField.isPlayer = opponentmode && !playAsGF || bothMode;
			dadField.autoPlayed = !dadField.isPlayer || (!opponentmode || (opponentmode && cpuControlled) || playAsGF) || (bothMode && cpuControlled);
			dadField.AIPlayer = AIMode;
			dadField.noteHitCallback = opponentmode ? goodNoteHit : opponentNoteHit;
		}
		
		#if ALLOW_DEPRECATION
		callOnScripts("postPlayfieldCreation"); // backwards compat
		#end
		callOnScripts("onPlayfieldCreationPost");

		trace("Adding Playfields!");
		add(playfields);
		add(notefields);
		trace("Playfields Created!");
		////

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var prevTime = Sys.time();
		generateSong();
		trace('generateSong() took ${Sys.time() - prevTime} seconds');

		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, MaxHP);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);
		
		if (opponentmode) healthBar.leftToRight = true;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		if (bf2 != null)
		{
			iconP12 = new HealthIcon(bf2.healthIcon, true);
			iconP12.y = healthBar.y - 115;
			iconP12.alpha = ClientPrefs.data.healthBarAlpha;
			uiGroup.add(iconP12);
		}
		else iconP12 = null;

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		if (dad2 != null)
		{
			iconP22 = new HealthIcon(dad2.healthIcon, false);
			iconP22.y = healthBar.y - 115;
			iconP22.alpha = ClientPrefs.data.healthBarAlpha;
			uiGroup.add(iconP22);
		} else iconP22 = null;

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		introStageText = new FlxTypedGroup<FlxText>();
		songTxt = new FlxText(0, 1280 / 6, FlxG.width, "", 32);
		songTxt.setFormat(Paths.font("mania-free.ttf"), 32, FlxColor.ORANGE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songTxt.scrollFactor.set();
		songTxt.screenCenter(X);
		songTxt.borderSize = 1.25;
		songTxt.alpha = 0;
		introStageText.insert(0, songTxt);
		artistTxt = new FlxText(songTxt.x, songTxt.y + 40, FlxG.width, "", 32);
		artistTxt.setFormat(Paths.font("mania-free.ttf"), 32, FlxColor.ORANGE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		artistTxt.scrollFactor.set();
		artistTxt.borderSize = 1.25;
		artistTxt.alpha = 0;
		introStageText.insert(0, artistTxt);
		charterTxt = new FlxText(artistTxt.x, artistTxt.y + 40, FlxG.width, "", 32);
		charterTxt.setFormat(Paths.font("mania-free.ttf"), 32, FlxColor.ORANGE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charterTxt.scrollFactor.set();
		charterTxt.borderSize = 1.25;
		charterTxt.alpha = 0;
		introStageText.insert(0, charterTxt);
		modTxt = new FlxText(charterTxt.x, charterTxt.y + 40, FlxG.width, "", 32);
		modTxt.setFormat(Paths.font("mania-free.ttf"), 32, FlxColor.ORANGE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modTxt.scrollFactor.set();
		modTxt.borderSize = 1.25;
		modTxt.alpha = 0;
		introStageText.insert(0, modTxt);
		if (hasMetadataFile)
		{
			Text = [
				metadata.song.name,
				metadata.song.artist,
				metadata.song.charter,
				metadata.song.mod
			];
		}
		else
		{
			Text = [curSong, '???', '???', 'Unknown'];
		}
		introStageStuff = new FlxTypedGroup<Dynamic>();
		add(introStageStuff);
		var daText:Array<FlxText> = [songTxt, artistTxt, charterTxt, modTxt];

		if (hasMetadataFile)
		{
			songTxt.text = metadata.song.name;
			if (metadata.song.artist != null && metadata.song.artist.length > 0)
				artistTxt.text = 'Composed by: ' + metadata.song.artist;
			if (metadata.song.charter != null && metadata.song.charter.length > 0)
				charterTxt.text = 'Charted by: ' + metadata.song.charter;
			if (metadata.song.mod != null && metadata.song.mod.length > 0)
				modTxt.text = 'Song From: ' + metadata.song.mod;
		}
		for (i in 0...Text.length)
		{
			if (Text[i] != null && Text[i].length > 0)
			{
				// Dont ask
				introStageBar = new FlxSprite(daText[i].x, if (i == 2) daText[i].y else daText[i].y - 25).loadGraphic(Paths.image('invisabar'));
				introStageBar.scale.x = 2;
				introStageBar.scale.y = 3;
				introStageBar.scrollFactor.set();
				introStageBar.updateHitbox();
				introStageBar.screenCenter(X);
				introStageBar.ID = i;
				introStageBar.scrollFactor.set(0, 0);
				introStageStuff.insert(0, introStageBar);
				introStageStuff.insert(1, introStageText);
			}
		}
		introStageStuff.visible = false;

		introStageStuff.cameras = [camCredit];
		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					(ClientPrefs.getGameplaySetting('legacyMode', false) ? new LegacyFunkinLua(folder + file) : new FunkinLua(folder + file));
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		speedChanges.sort(svSort);
		#if EASED_SVs
		resetSVDeltas();
		#end

		if(eventNotes.length > 0)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if(!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnScripts('onCreatePost');
		currentRate = playbackRate;

		super.create();
		Paths.clearUnusedMemory();

		add(blackOverlay);

		
		daStatic = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('effects/static');
		daStatic.animation.addByPrefix('static', 'lestatic', 24, true);
		daStatic.animation.play('static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.cameras = [camOther];
		daStatic.alpha = 0;
		add(daStatic);

		raveLight = new FlxSprite(0, 0).makeGraphic(screenWidth, screenHeight, FlxColor.BLACK);
		raveLight.cameras = [camHUD];
		raveLight.antialiasing = true;
		raveLight.scrollFactor.set(0, 0);
		raveLight.updateHitbox();
		raveLight.screenCenter();
		raveLight.active = false;
		raveLight.alpha = 0;
		raveLight.visible = false;

		daStatic = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('effects/static');
		daStatic.animation.addByPrefix('static', 'lestatic', 24, true);
		daStatic.animation.play('static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.cameras = [camOther];
		daStatic.alpha = 0;
		add(daStatic);

		lyrics = new FlxText(0, 100, 1280, "", 32, true);
		lyrics.scrollFactor.set();
		lyrics.cameras = [camOther];
		lyrics.alignment = FlxTextAlign.CENTER;
		lyrics.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		lyrics.borderSize = 4;
		lyrics.text = '';
		add(lyrics);

		cacheCountdown();
		cachePopUpScore();

		if(eventNotes.length < 1) checkEventNote();

		switch(ClientPrefs.data.healthMode) {
			case "Kade":
				pressMissDamage = 0.20; //nah that's cruel
			default:
				pressMissDamage = 0.05;
		}

		raveLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		if (!inArchipelagoMode) MaxHP = 2 + ClientPrefs.data.healthMode == "Tabi" ? 1 : 0;
		initY = healthBar.y;
	}

	function doStaticSign(lestatic:Int = 0)
	{
		trace('static Time Number: ' + lestatic);

		switch (lestatic)
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
		switch (stormType)
		{
			case 0:
				FlxTween.num(rainIntensity, 0.04, 2, {ease: FlxEase.expoOut}, function(num)
				{
					rainIntensity = num;
				});
				thunderON = false;
			case 1:
				FlxTween.num(rainIntensity, 0.07, 2, {ease: FlxEase.expoOut}, function(num)
				{
					rainIntensity = num;
				});
				thunderON = false;
			case 2:
				FlxTween.num(rainIntensity, 0.09, 2, {ease: FlxEase.expoOut}, function(num)
				{
					rainIntensity = num;
				});
				thunderON = true;
			case 3:
				FlxTween.num(rainIntensity, 0, 2, {ease: FlxEase.expoOut}, function(num)
				{
					rainIntensity = num;
				});
				thunderON = false;
		}
	}	

	function set_songSpeed(value:Float):Float
	{
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			gfVocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if(videoCutscene != null && videoCutscene.videoSprite != null) videoCutscene.videoSprite.bitmap.rate = value;
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

			//for later
		var dCol = if (dad2 != null) FlxColor.fromRGB(dad2.healthColorArray[0], dad2.healthColorArray[1],
			dad2.healthColorArray[2]) else FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var bCol = if (bf2 != null) FlxColor.fromRGB(bf2.healthColorArray[0], bf2.healthColorArray[1],
			bf2.healthColorArray[2]) else FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);

	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
			case 3:
				if (dad2 != null && !dadMap2.exists(newCharacter))
				{
					var newDad2:Character = new Character(0, 0, newCharacter);
					newDad2.scrollFactor.set(0.95, 0.95);
					dadMap2.set(newCharacter, newDad2);
					dadGroup2.add(newDad2);
					startCharacterPos(newDad2);
					newDad2.alpha = 0.00001;
					startCharacterScripts(newDad2.curCharacter);
				}
			case 4:
				if (bf2 != null && !boyfriendMap2.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap2.set(newCharacter, newBoyfriend);
					boyfriendGroup2.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					if (playerField != null)
						playerField.characters.push(newBoyfriend);
					startCharacterScripts(newBoyfriend.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush)
				(ClientPrefs.getGameplaySetting('legacyMode', false) ? new LegacyFunkinLua(luaFile) : new FunkinLua(luaFile));

		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(Iris.instances.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
		{
			#if LUA_ALLOWED
			if (modchartSprites.exists(tag))
				return modchartSprites.get(tag);
			if (text && modchartTexts.exists(tag))
				return modchartTexts.get(tag);
			if (variables.exists(tag))
				return variables.get(tag);
			#end
			return null;
		}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if(forMidSong) videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
			else add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
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
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			seenCutscene = true;
			inCutscene = false;

			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			trace("Starting Countdown!");
			canPause = true;
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerField.baseXPositions[i]);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, dadField.baseXPositions[i]);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;
	
			try {generateStrums();}catch(e){trace("Strums are NULL!");}

			#if ALLOW_DEPRECATION
			callOnScripts('preModifierRegister'); // deprecated
			#end

			if (callOnScripts('onModifierRegister') != LuaUtils.Function_Stop) {
				modManager.registerDefaultModifiers();

				if (ClientPrefs.data.middleScroll) {
					var off:Float = Math.min(FlxG.width, 1280) / 4;
					var opp:Int = opponentmode ? 0 : 1;
					
					var halfKeys:Int = Math.floor(Note.ammo[mania] / 2);
					if (Note.ammo[mania] % 2 != 0) // middle receptor dissappears, if there is one
						modManager.setValue('alpha${halfKeys + 1}', 1.0, opp);
					
					for (i in 0...halfKeys)
						modManager.setValue('transform${i}X', -off, opp);
					for (i in Note.ammo[mania]-halfKeys...Note.ammo[mania])
						modManager.setValue('transform${i}X', off, opp);
		
					modManager.setValue("alpha", 0.6, opp);
					modManager.setValue("opponentSwap", 0.5);
				}
			}
			#if ALLOW_DEPRECATION
			callOnScripts('postModifierRegister'); // deprecated
			#end
			callOnScripts('onModifierRegisterPost');

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');
			if (SONG.startMania != null && SONG.startMania != mania) {
				trace("Fixing Mania");
				changeMania(chartModifier != 'ManiaConverter' ? SONG.startMania : convertMania, isStoryMode || skipArrowStartTween);
			}
			else if (chartModifier == "ManiaConverter") {
				trace("Setting the mania");
				changeMania(convertMania, isStoryMode || skipArrowStartTween);
			}

			callOnScripts("generateModchart"); // this is where scripts should generate modcharts from here on out lol

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			trace("Started Countdown!");

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

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
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							FlxTween.tween(camCredit, {alpha: 0, y: 1000}, 1, {ease: FlxEase.circInOut});
						});
						tick = START;
				}

				if(!skipArrowStartTween)
				{
					notes.forEachAlive(function(note:Note) {
						if(ClientPrefs.data.opponentStrums || note.mustPress)
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if(ClientPrefs.data.middleScroll && !note.mustPress)
								note.alpha *= 0.35;
						}
					});
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
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

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}
	public function addBehindBF2(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup2), obj);
	}
	public function addBehindDad2(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup2), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = allNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = allNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.ignoreNote = true;
				for (field in playfields)
					field.removeNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public function updateScoreAI(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScoreAI', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScoreAI', [miss]);
	}

	public dynamic function updateScoreText()
	{
		var str:String = Language.getPhrase('rating_$ratingName', ratingName);
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ' + Language.getPhrase(ratingFC);
		}

		if (health <= 0.0475 && (ClientPrefs.data.healthMode == "Mixtape" || ClientPrefs.data.healthMode == "Tabi"))
		{
			scoreTxt.text = "DON'T MISS!";
			scoreTxt.borderColor = FlxColor.fromRGB(255, 0, 0);
		}
		else {
			var tempScore:String;
			if(!instakillOnMiss) tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [songScore, songMisses, str]);
			else tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [songScore, str]);
			scoreTxt.text = '$tempScore | Health: ${CoolUtil.floorDecimal((health/2) * 100, 2)}%';
			scoreTxt.borderColor = FlxColor.fromRGB(0, 0, 0);
		}
	}

	public dynamic function fullComboFunction()
	{
		ratingFC = "";

		var marvs:Int = ratingsData[0].hits;
		var sicks:Int = ratingsData[1].hits;
		var goods:Int = ratingsData[2].hits;
		var bads:Int = ratingsData[3].hits;
		var shits:Int = ratingsData[4].hits;

		if (songMisses == 0)
		{
			if (bads > 0 || shits > 0)
				ratingFC = '[Full Combo]';
			else if (goods > 0)
				ratingFC = '[Good Full Combo]';
			else if (sicks > 0)
				ratingFC = '[Sick Full Combo]';
			else if (marvs > 0)
				ratingFC = '[Marvioulus Full Combo]';
		}
		else
		{
			if (songMisses < 10)
				ratingFC = '[Single Digit Combo Break]';
			else
				ratingFC = '[Ok I guess...]';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();
		gfVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition < vocals.length)
		{
			vocals.time = time - Conductor.offset;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
			vocals.play();
		}
		else vocals.pause();

		if (Conductor.songPosition < opponentVocals.length)
		{
			opponentVocals.time = time - Conductor.offset;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
			opponentVocals.play();
		}
		else opponentVocals.pause();

		if (Conductor.songPosition < gfVocals.length)
		{
			gfVocals.time = time - Conductor.offset;
			#if FLX_PITCH gfVocals.pitch = playbackRate; #end
			gfVocals.play();
		}
		else gfVocals.pause();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();
		gfVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
			gfVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end

		if (savedTime > 0) {
			Conductor.songPosition = savedTime;
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
			gfVocals.pause();
			trace('Saved Time: $savedTime');
			clearNotesBefore(savedTime);
			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();

			vocals.time = Conductor.songPosition;
			vocals.play();
			opponentVocals.time = Conductor.songPosition;
			opponentVocals.play();
			gfVocals.time = Conductor.songPosition;
			gfVocals.play();
			savedTime = 0;
		}

		if (needSkip && !skipActive)
		{
			skipActive = true;
			skipText = new FlxText(healthBar.x + 80, healthBar.y - 110, 500);
			skipText.text = "Press Space to Skip Intro";
			skipText.size = 30;
			skipText.color = FlxColor.WHITE;
			skipText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
			skipText.cameras = [camHUD];
			skipText.alpha = 0;
			skipText.font = Paths.font('comboFont.ttf');
			FlxTween.tween(skipText, {alpha: 1}, 0.2);
			add(skipText);
		}
		else
		{
			if (skipText != null)
				FlxTween.tween(skipText, {alpha: 0}, 0.2);
		}

		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns:Int = Note.ammo[SONG?.mania != null ? SONG?.mania : mania];
	var prevNoteData:Int = -1;
	var initialNoteData:Int = -1;
	var caseExecutionCount:Int = FlxG.random.int(-50, 50);
	var currentModifier:Int = -1;
	var stair:Int = 0;

	public static function getNumberFromAnims(note:Int, mania:Int):Int {
		var animMap:Map<String, Int> = new Map<String, Int>();
		animMap.set("LEFT", 0);
		animMap.set("DOWN", 1);
		animMap.set("UP", 2);
		animMap.set("RIGHT", 3);

		var anims:Array<String> = Note.keysShit.get(mania).get("anims");
		var animKeys:Array<String> = [
			for (key in animMap.keys())
				if (key == "LEFT") "RIGHT" else if (key == "RIGHT") "LEFT" else key
		];

		var result:Int;

		if (mania > 3) {
			var anim = animKeys[note];
			var matchingIndices:Array<Int> = [];
			if (note < animKeys.length) {
				for (i in 0...anims.length) {
					if (anims[i] == anim) {
						matchingIndices.push(i);
					}
				}
				if (matchingIndices.length > 0) {
					var randomIndex = Std.int(Math.random() * matchingIndices.length);
					result = matchingIndices[randomIndex];
				} else {
					var randomIndex = Std.int(Math.random() * mania);
					result = randomIndex;
				}
			} else {
				if (matchingIndices.length > 0) {
					var randomIndex = Std.int(Math.random() * matchingIndices.length);
					result = matchingIndices[randomIndex];
				} else {
					var randomIndex = Std.int(Math.random() * mania);
					result = randomIndex;
				}
			}
		} else { // mania == 3
			var anim = anims[note];
			if (note < anims.length) {
				if (animMap.exists(anim)) {
					result = animMap.get(anim);
				} else {
					throw 'No matching animation found';
				}
			} else {
				result = animMap.get(anim);
			}
		}

		// Ensure result is within bounds
		if (result < 0 || result > mania) {
			trace("OOB NOtE: " + note + " MANIA: " + mania + " RESULT: " + result);
			var foundValidAnimation = false;
			while (!foundValidAnimation) {
				var randomIndex = Std.int(Math.random() * anims.length);
				var randomAnim = anims[randomIndex];
				if (animMap.exists(randomAnim)) {
					result = animMap.get(randomAnim);
					foundValidAnimation = true;
				}
			}
		}

		return result;
	}

	private function generateSong():Void
	{

		
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		gfVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var currentMod = backend.WeekData.getCurrentWeek().folder;
				if (currentMod != null && currentMod != "")
				{
					var generalVocals = Paths.voices(songData.song);
					if (generalVocals != null && generalVocals.length > 0)
					{
						vocals.loadEmbedded(generalVocals);
					}
					else
					{
						var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
						vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));
						
						var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
						if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

						var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
						if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
					}
				}
				else
				{
					var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
					vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));
					
					var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
					if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

					var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
					if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
				}
			}
		}
		catch (e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		gfVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);
		FlxG.sound.list.add(gfVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		try
		{
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if(eventsChart != null)
				for (event in eventsChart.events) //Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch(e:Dynamic) {}

		var AIPlayMap:Array<Array<Float>> = AIPlayer.active ? AIPlayer.GeneratePlayMap(SONG, AIPlayer.diff) : null;

		var oldNote:Note = null;
		var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
		var ghostNotesCaught:Int = 0;
		var daBpm:Float = Conductor.bpm;
	
		for (section in sectionsData)
		{
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes: Array<Dynamic> = section.sectionNotes[i];
				var spawnTime:Float = songNotes[0];
				var noteColumn:Int = Std.int(songNotes[1] % totalColumns);
				var noteStartColumn:Int = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
				var holdLength:Float = songNotes[2];
				var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				if (Math.isNaN(holdLength)) holdLength = 0.0;

				if (chartModifier != "4K Only" && chartModifier != "ManiaConverter") {
					noteColumn = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
				}
				else {
					noteColumn = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
				}

				var gottaHitNote:Bool = (songNotes[1] < (SONG.mania != null ? totalColumns : Note.ammo[3]));
				//if (songData.format.contains("mixtape_v1")) gottaHitNote = section.mustHitSection;

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in allNotes) {
						var matches: Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
						if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON) {
							var playfield:PlayField = playfields.members[evilNote.fieldIndex];
							if (evilNote.tail.length > 0)
								for (tail in evilNote.tail)
								{
									tail.destroy();
									allNotes.remove(tail);
									if (playfield != null) playfield.unqueue(tail);
								}
							evilNote.destroy();
							allNotes.remove(evilNote);
							if (playfield != null) playfield.unqueue(evilNote);
							ghostNotesCaught++;
							//continue;
						}
					}
				}

				switch (chartModifier)
				{
					case "Random":
						noteColumn = FlxG.random.int(0, mania);
					case "RandomBasic":
						var randomDirection:Int;
						do
						{
							randomDirection = FlxG.random.int(0, mania);
						}
						while (randomDirection == prevNoteData && mania > 1);
						prevNoteData = randomDirection;
						noteColumn = randomDirection;
					case "RandomComplex":
						var thisNoteData = noteColumn;
						if (initialNoteData == -1)
						{
							initialNoteData = noteColumn;
							noteColumn = FlxG.random.int(0, mania);
						}
						else
						{
							var newNoteData:Int;
							do
							{
								newNoteData = FlxG.random.int(0, mania);
							}
							while (newNoteData == prevNoteData && mania > 1);
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

					// case "Sequential":
					// 	if (prevNoteData == 0) {
					// 		noteColumn = 1;
					// 		direction = 1;
					// 	} else if (prevNoteData == mania - 1) {
					// 		noteColumn = mania - 2;
					// 		direction = -1;
					// 	} else {
					// 		noteColumn = prevNoteData + direction;
					// 	}
					// 	break;
					case "Mirror": // Broken
						var length = mania;
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
						var median:Float = (mania + 1) / 2;
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
						noteColumn = Std.int(Math.max(0, Math.min(noteColumn, mania - 1)));

					case "Skip":
						var skipStep = 2; // Define the step size for skipping notes.
						var randomLane = Math.random() < 0.5 ? prevNoteData : (prevNoteData + skipStep) % mania;
						var randomDuration = Math.random() * 30; // Randomize the duration before switching lanes (in notes).
						noteColumn = randomLane;
					case "Flip":
						if (gottaHitNote)
						{
							noteColumn = mania - Std.int(songNotes[1] % Note.ammo[mania]);
						}
					case "Pain":
						noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[mania]);
					case "4K Only":
						noteColumn = getNumberFromAnims(noteStartColumn, 3);
					case "ManiaConverter":
						noteColumn = getNumberFromAnims(noteStartColumn, mania);
					case "Stairs":
						noteColumn = stair % Note.ammo[mania];
						stair++;
					case "Wave":
						// Sketchie... WHY?!
						var ammoFromFortnite:Int = Note.ammo[mania];
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
						var ammoFromFortnite:Int = Note.ammo[mania];
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
						while (noteColumn == prevNoteData && mania > 1);
						prevNoteData = noteColumn;
					case "Ew":
						// I hate that I used Sketchie's variables as a base for this... ;-;
						var ammoFromFortnite:Int = Note.ammo[mania];
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
						var ammoFromFortnite:Int = Note.ammo[mania];
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
						switch (stair % (2 * Note.ammo[mania]))
						{
							case 0:
							case 1:
							case 2:
							case 3:
							case 4:
								noteColumn = stair % Note.ammo[mania];
							default:
								noteColumn = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
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
									noteColumn = FlxG.random.int(0, mania);
								case 1: // "RandomBasic"
									var randomDirection:Int;
									do
									{
										randomDirection = FlxG.random.int(0, mania);
									}
									while (randomDirection == prevNoteData && mania > 1);
									prevNoteData = randomDirection;
									noteColumn = randomDirection;
								case 2: // "RandomComplex"
									var thisNoteData = noteColumn;
									if (initialNoteData == -1)
									{
										initialNoteData = noteColumn;
										noteColumn = FlxG.random.int(0, mania);
									}
									else
									{
										var newNoteData:Int;
										do
										{
											newNoteData = FlxG.random.int(0, mania);
										}
										while (newNoteData == prevNoteData && mania > 1);
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
										noteColumn = mania - Std.int(songNotes[1] % Note.ammo[mania]);
									}
								case 4: // "Pain"
									noteColumn = noteColumn - Std.int(songNotes[1] % Note.ammo[mania]);
								case 5: // "Stairs"
									noteColumn = stair % Note.ammo[mania];
									stair++;
								case 6: // "Wave"
									// Sketchie... WHY?!
									var ammoFromFortnite:Int = Note.ammo[mania];
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
									var ammoFromFortnite:Int = Note.ammo[mania];
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
									var ammoFromFortnite:Int = Note.ammo[mania];
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
									switch (stair % (2 * Note.ammo[mania]))
									{
										case 0:
										case 1:
										case 2:
										case 3:
										case 4:
											noteColumn = stair % Note.ammo[mania];
										default:
											noteColumn = Note.ammo[mania] - 1 - (stair % Note.ammo[mania]);
									}
									stair++;
								case 10: // Jack Wave
									var ammoFromFortnite:Int = Note.ammo[mania];
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
									var ammoFromFortnite:Int = Note.ammo[mania];
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
									while (noteColumn == prevNoteData && mania > 1);
									prevNoteData = noteColumn;
								default:
									// Default case (optional)
							}
						}
				}

				if (allNotes.length > 0)
					oldNote = allNotes[Std.int(allNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
				swagNote.mustPress = gottaHitNote;
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
				swagNote.sustainLength = songNotes[2];
				swagNote.noteType = noteType;
				swagNote.ID = allNotes.length;
				swagNote.holdType = swagNote.sustainLength > 0 ? HEAD : TAP;
				swagNote.isParent = swagNote.sustainLength > 0;
				swagNote.scrollFactor.set();
				if (chartModifier == 'Amalgam' && currentModifier == 11)
				{
					swagNote.multSpeed = FlxG.random.float(0.1, 2);
				}
	
				////

				callOnScripts("onGeneratedNote", [swagNote, section]);
			
				if (swagNote.fieldIndex == -1 && swagNote.field == null)
					swagNote.field = swagNote.mustPress ? playerField : dadField;

				if (swagNote.field != null)
					swagNote.fieldIndex = playfields.members.indexOf(swagNote.field);

				var playfield:PlayField = playfields.members[swagNote.fieldIndex];
				//notes.insert(swagNote.ID, swagNote); // just for the sake of convenience

				if (playfield != null)
				{
					playfield.queue(swagNote); // queues the note to be spawned
					allNotes.push(swagNote); // just for the sake of convenience
				}
				else
				{
					swagNote.destroy();
					continue;
				}

				var spot = 0;
				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
				final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet) -1;
				if (roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = allNotes[Std.int(allNotes.length - 1)];

						var sustainNote:Note = new Note(spawnTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), noteColumn, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.exNote = swagNote.exNote;
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.noteIndex = swagNote.noteIndex;
						if (chartModifier == 'Amalgam' && currentModifier == 11)
						{
							sustainNote.multSpeed = swagNote.multSpeed;
						}
						if (sustainNote == null || !sustainNote.alive)
							break;
						sustainNote.ID = allNotes.length;
						sustainNote.scrollFactor.set();
						sustainNote.holdType = roundSus > 0 ? PART : END;
						sustainNote.parent = swagNote;
						sustainNote.fieldIndex = swagNote.fieldIndex;
						swagNote.tail.push(sustainNote);
						swagNote.unhitTail.push(sustainNote);
						playfield.queue(sustainNote);
						allNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width * 0.5; // general offset
						}

						sustainNote.parent = swagNote;
						swagNote.childs.push(sustainNote);
						sustainNote.spotInLine = spot;
						spot++;
					}
				}

				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);
			}
		}
		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		allNotes.sort(sortByTime);

		for (fuck in allNotes)
			unspawnNotes.push(fuck);

		for (field in playfields.members)
			field.clearStackedNotes();
		generatedMusic = true;
	}

	function updateNote(note:Note)
	{
		if (note != null) {
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
			if (isPixelStage)
			{
				// if (note.isSustainNote) {note.originalHeightForCalcs = note.height;}

				note.setGraphicSize(Std.int(note.width * daPixelZoom * Note.pixelScales[mania]));
			}
			else
			{
				// Like loadNoteAnims()

				note.setGraphicSize(Std.int(note.width * Note.scales[mania]));
				note.updateHitbox();
			}

			if (note.isSustainNote)
			{
				note.scale.y = lastScaleY;
			}
			note.updateHitbox();

			// Like new()

			var prevNote:Note = note.prevNote;

			if (note.isSustainNote && prevNote != null)
			{
				note.offsetX += note.width / 2;

				note.animation.play(Note.keysShit.get(mania).get('letters')[noteData] + ' tail');

				note.updateHitbox();

				note.offsetX -= note.width / 2;

				if (note != null && prevNote != null && prevNote.isSustainNote && prevNote.animation != null)
				{ // haxe flixel
					prevNote.animation.play(Note.keysShit.get(mania).get('letters')[noteData % tMania] + ' hold');

					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
					prevNote.scale.y *= songSpeed;

					if (isPixelStage)
					{
						prevNote.scale.y *= 1.19;
						prevNote.scale.y *= (6 / note.height);
					}

					prevNote.updateHitbox();
					// trace(prevNote.scale.y);
				}

				if (isPixelStage)
				{
					prevNote.scale.y *= daPixelZoom * (Note.pixelScales[mania]); // Fuck urself
					prevNote.updateHitbox();
				}
			}
			else if (!note.isSustainNote && noteData > -1 && noteData < tMania)
			{
				if (note.changeAnim)
				{
					var animToPlay:String = '';

					animToPlay = Note.keysShit.get(mania).get('letters')[noteData % tMania];

					note.animation.play(animToPlay);
				}
			}

			// Like set_noteType()
		}
	}

	public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false, ?modifyNotes = false)
	{
		if (chartModifier == '4K Only' || chartModifier == 'maniaConverter')
			return;
		var daOldMania = mania;

		mania = newValue;

		playerField.strumNotes = [];
		dadField.strumNotes = [];
		setOnScripts('mania', mania);

		notes.forEachAlive(function(note:Note)
		{
			updateNote(note);
		});

		for (noteI in 0...allNotes.length)
		{
			var note:Note = allNotes[noteI];
			updateNote(note);
		}

		setOnScripts('onChangeMania', [mania, daOldMania]);

		callOnScripts('preReceptorGeneration'); // backwards compat, deprecated
		callOnScripts('onReceptorGeneration');

		for (field in playfields.members)
		{
			field.keyCount = Note.ammo[mania];
			if (modifyNotes)
			{
				for (note in allNotes)
				{
					field.unqueue(note);
					field.queue(note);
				}
			}
			field.generateStrums();
		}

		callOnScripts('postReceptorGeneration'); // deprecated
		callOnScripts('onReceptorGenerationPost');

		for (field in playfields.members)
			field.fadeIn(skipStrumFadeOut); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode

		singAnimations = Note.keysShit.get(mania).get('singAnims');
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		if (event.value1 == null) event.value1 = '';
		if (event.value2 == null) event.value2 = '';
		switch(event.event) {
			case 'Change Scroll Speed': // Negative duration means using the event time as the tween finish time
				var duration = Std.parseFloat(event.value2);
				if (!Math.isNaN(duration) && duration < 0.0){
					event.strumTime -= duration * 1000;
					event.value2 = Std.string(-duration);
				}

			case 'Mult SV' | 'Constant SV':
				var speed:Float = 1;
				if(event.event == 'Constant SV'){
					var b = Std.parseFloat(event.value1);
					speed = Math.isNaN(b) ? 1 : (b / songSpeed);
				}else{
					speed = Std.parseFloat(event.value1);
					if (Math.isNaN(speed)) speed = 1;
				}
				#if EASED_SVs
				var endTime:Null<Float> = null;
				var easeFunc:Null<EaseFunction> = null;

				var tweenOptions = event.value2.split("/");
				if(tweenOptions.length >= 1){
					easeFunc = FlxEase.linear;
					var parsed:Float = Std.parseFloat(tweenOptions[0]);
					if(!Math.isNaN(parsed))
						endTime = event.strumTime + (parsed * 1000);

					if(tweenOptions.length > 1){
						var f:EaseFunction = ScriptingUtil.getFlxEaseByString(tweenOptions[1]);
						if(f != null)
							easeFunc = f;
					}
				}

				var lastChange:SpeedEvent = speedChanges[speedChanges.length - 1];
				speedChanges.push({
					position: getTimeFromSV(event.strumTime, lastChange),
					startTime: event.strumTime,
					endTime: endTime,
					easeFunc: easeFunc,
					startSpeed: lastChange.startSpeed,
					speed: speed
				});
				#else
				var lastChange:SpeedEvent = speedChanges[speedChanges.length - 1];
				speedChanges.push({
					position: getTimeFromSV(event.strumTime, lastChange),
					startTime: event.strumTime,
					speed: speed
				});
				#end

			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound

			case 'False Timer':
				if (timerExtensions == null)
					timerExtensions = new Array();

				timerExtensions.push(event.strumTime);
				maskedSongLength = timerExtensions[0];
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
		if(returnedValue != null && returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startTime, Obj2.startTime);
	}

	private function generateStrums():Void
	{
		trace('GENERATING STRUMS!');
		#if ALLOW_DEPRECATION
		callOnScripts('preReceptorGeneration'); // backwards compat, deprecated
		#end
		callOnScripts('onReceptorGeneration');

		for(field in playfields.members) {
			field.keyCount = Note.ammo[mania];
			field.generateStrums();
		}

		#if ALLOW_DEPRECATION
		callOnScripts('postReceptorGeneration'); // deprecated
		#end
		callOnScripts('onReceptorGenerationPost');

		for(field in playfields.members)
			field.fadeIn(skipArrowStartTween);

		#if PE_MOD_COMPATIBILITY
		for (i in dadField.strumNotes) {
			opponentStrums.add(i);
			strumLineNotes.add(i);
		}

		for (i in playerField.strumNotes) {
			playerStrums.add(i);
			strumLineNotes.add(i);
		}
		
		#end
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		curEvents.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	/*private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}*/

	// Might make scripted video pausing better in the future but this works for now.
	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
				gfVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);

			for (tag in MusicBeatState.getVariables().keys())
				if (tag.contains("_video")) MusicBeatState.getVariables().get(tag).pause();
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);
			for (tag in MusicBeatState.getVariables().keys())
				if (tag.contains("_video")) MusicBeatState.getVariables().get(tag).resume();

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	#if DISCORD_ALLOWED
	override public function onFocus():Void
	{
		super.onFocus();
		if (!paused && health > 0)
		{
			resetRPC(Conductor.songPosition > 0.0);
		}
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!paused && health > 0 && autoUpdateRPC)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
	}
	#end

	public function newPlayfield()
	{
		try {
			var field = new PlayField(modManager);
			field.modNumber = playfields.members.length;
			field.playerId = field.modNumber;
			field.cameras = playfields.cameras;
			initPlayfield(field);
			playfields.add(field);
			return field;
		}
		catch(e) {
			trace("Playfield Failed to make a Field!");
			return null;
		}
	}

	// good to call this whenever you make a playfield
	public function initPlayfield(field:PlayField){
		notefields.add(field.noteField);

		field.holdPressCallback = pressHold;
		field.holdStepCallback = stepHold;
		field.holdReleaseCallback = releaseHold;

		field.noteRemoved.add((note:Note, field:PlayField) -> {
			allNotes.remove(note);
			unspawnNotes.remove(note);
			notes.remove(note);
		});
		field.noteMissed.add((daNote:Note, field:PlayField) -> {
			if (field.isPlayer && !field.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
				noteMiss(daNote, field);

		});

		field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
			callOnScripts('onSpawnNote', [dunceNote]);
			#if LUA_ALLOWED
			callOnLuas('onSpawnNote', [
				allNotes.indexOf(dunceNote),
				dunceNote.column,
				dunceNote.noteType,
				dunceNote.isSustainNote,
				dunceNote.strumTime
			]);
			#end

			notes.add(dunceNote);
			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);

			callOnScripts('onSpawnNotePost', [dunceNote]);
		});


		field.holdDropped.add((daNote:Note, field:PlayField) -> {
			if (!field.isPlayer)return;
		});

		field.holdFinished.add((daNote:Note, field:PlayField) -> {
			if (!field.isPlayer)return;
		}); 

	}

	//Yes this is all these do
	inline function stepHold(note:Note, field:PlayField)
	{
		callOnScripts("onHoldStep", [note, field]);
		
		if(field.isPlayer){
			if (holdsGiveHP){
				health += note.hitHealth * healthGain;
			}
		}
	}
	inline function pressHold(note:Note, field:PlayField) {
		callOnScripts("onHoldPress", [note, field]);
	}

	inline function releaseHold(note:Note, field:PlayField):Void {
		callOnScripts("onHoldRelease", [note, field]);
	}
	//No im not kidding

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var checkVocals = [vocals, opponentVocals, gfVocals];
		for (voc in checkVocals)
		{
			if (FlxG.sound.music.time < vocals.length)
			{
				voc.time = FlxG.sound.music.time;
				#if FLX_PITCH voc.pitch = playbackRate; #end
				voc.play();
			}
			else voc.pause();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	public var startedCountdown:Bool = false;
	public var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	private var svIndex:Int =0;
	private inline function updateVisualPosition() {
		var event:SpeedEvent = null;

		for (i in svIndex+1...speedChanges.length) {
			var nextEvent = speedChanges[i];
			if (nextEvent.startTime > Conductor.songPosition)
				break;

			svIndex = i;
			event = nextEvent;
		}
		event ??= speedChanges[svIndex];
		
		if (!freezeNotes) Conductor.visualPosition = getTimeFromSV(Conductor.songPosition, event);
		FlxG.watch.addQuick("visualPos", Conductor.visualPosition);
	}

	public function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}

	#if EASED_SVs
	var lastSVTime:Float = 0;
	var lastSVElapsed:Float = 0;
	var lastSVPos:Float = 0;
	
	inline function resetSVDeltas(){
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

	public function getTimeFromSV(time:Float, event:SpeedEvent):Float {
		#if EASED_SVs
		var func:EaseFunction = event.easeFunc == null ? FlxEase.linear : event.easeFunc;
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

	public function getSV(time:Float){
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

	public function die():Void
	{
		bfkilledcheck = true;
		doDeathCheck(true);
		health = 0;
		noteMissPress(3, opponentmode ? dadField : playerField); // just to make sure you actually die
	}

	var initY:Float;
	override public function update(elapsed:Float)
	{
		if(!inCutscene && !paused && !freezeCamera) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
			var idleAnim:Bool = (boyfriend.getAnimationName().startsWith('idle') || boyfriend.getAnimationName().startsWith('danceLeft') || boyfriend.getAnimationName().startsWith('danceRight'));
			if(!startingSong && !endingSong && idleAnim) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		//Just to make sure
		if (maniaMode) {
			camGame.alpha = 0;
			camGame.visible = false;
		}

		if (ClientPrefs.data.healthMode == "Tabi")
		{
			if (health > 0)
			{
				health -= 0.001 / (ClientPrefs.data.framerate / 60);
			}
		}

		super.update(elapsed);
		updateVisualPosition();
		modManager.update(elapsed, curDecBeat, curDecStep);

		// TODO: Figure this out
		/*for (note in 0...playerStrums.members.length) {
			modManager.setValue('psychTransform${note}X', playerStrums.members[note].x, 1);
			modManager.setValue('psychTransform${note}Y', playerStrums.members[note].y, 1); 
		}
		for (note in 0...opponentStrums.members.length) {
			modManager.setValue('psychTransform${note}X', opponentStrums.members[note].x, 0);
			modManager.setValue('psychTransform${note}Y', opponentStrums.members[note].y, 0);
		}*/

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if (strumFocus)
		{
			if (SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
			{
				modManager.queueEase(curStep, curStep + 4, 'alpha', 0.8, 'sineInOut', 1);
				modManager.queueEase(curStep, curStep + 4, 'alpha', 0, 'sineInOut', 0);
			}
			else if (!SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].exSection)
			{
				modManager.queueEase(curStep, curStep + 4, 'alpha', 0.8, 'sineInOut', 0);
				modManager.queueEase(curStep, curStep + 4, 'alpha', 0, 'sineInOut', 1);
			}
		}	

		if (!isStoryMode)
		{
			var daNote:Note = allNotes[0];
			if (daNote != null && daNote.strumTime > 100)
			{
				needSkip = true;
				skipTo = daNote.strumTime - 500;
			}
			else
			{
				needSkip = false;
			}
			
		}

		for (field in playfields)
			field.noteField.songSpeed = songSpeed;

		for (playfield in playfields.members)
		{
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || (archipelago.APItem.activeItem?.name == 'Tutorial Trap' && PlayState.SONG.song.toLowerCase() != 'Tutorial'.toLowerCase()); 
		}

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause && !endingSong)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1'))
				openChartEditor();
			else if (controls.justPressed('debug_2'))
				openCharacterEditor();
		}

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset)
			{
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= Conductor.offset)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		}
		else if (!paused && updateTime)
		{
			if (Conductor.songPosition - lastUpdateTime >= 1.0)
				lastUpdateTime = Conductor.songPosition;

			var timeBarType:String = ClientPrefs.data.timeBarType;
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			var lengthUsing:Float = (maskedSongLength > 0) ? maskedSongLength : songLength;
			songPercent = (curTime / lengthUsing);

			var songCalc:Float = (lengthUsing - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			archipelago.APPlayState.deathByLink = true; //To prevent self-made deaths (People would hate you for this)
			health = 0;
			die();
			COD.setPresetCOD('r');
			trace("RESET = True");
		}
		doDeathCheck();

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) keysCheck();
				else playerDance();
			}
			checkEventNote();
		}

		if (health < 0) health = 0;
		if (health > MaxHP) health = MaxHP;

		if (!inArchipelagoMode && ClientPrefs.data.healthMode == "Tabi") {
			healthBar.x = FlxG.width / 2 - healthBar.width / 2;
			healthBar.y = initY; 
			if (health >= 2) {
				var amount = (health - 2) * 100;
				var rX = FlxG.random.float(-2, 2);
				var rY = FlxG.random.float(-2, 2);
		
				for (spr in [healthBar, iconP1, iconP2]) {
					spr.x -= amount;
					spr.x += rX;
					spr.y += rY;
				}
			}

			for (icon in [iconP1, iconP2])
				icon.y = healthBar.y - (icon.height / 2);
		}

		if (ClientPrefs.data.healthMode != "Tabi") { //Don't want to cause an overlap
			if (health < MaxHP && extraHealth > 0)
			{
				var neededHealth = MaxHP - health;
				var healthToAdd = Math.min(extraHealth, neededHealth);
				health += healthToAdd;
				extraHealth -= healthToAdd;
			}

			if (noHeal)
			{
				MaxHP = health;
				if (extraHealth > 0)
				{
					MaxHP += extraHealth;
					health += extraHealth;
					extraHealth = 0;
				}
			}
		}

		if ((loopMode || loopModeChallenge/* || curSong == "Small Argument" && !inArchipelagoMode*/)
			&& startedCountdown
			&& !endingSong)
		{
			if (FlxG.sound.music.length - Conductor.songPosition <= endingTimeLimit)
			{
				songAboutToLoop = true;
				if (AIScore >= songScore && AIMode)
				{
					if (FlxG.sound.music.time < 0 || Conductor.songPosition < 0)
					{
						FlxG.sound.music.time = 0;
						resyncVocals();
					}
					loopCallback(0);
					endingSong = false;
					die();
				}
				else
				{
					if (FlxG.sound.music.time < 0 || Conductor.songPosition < 0)
					{
						FlxG.sound.music.time = 0;
						resyncVocals();
					}
					loopCallback(0);
				}
			}
		}

		if (skipActive && Conductor.songPosition >= skipTo)
		{
			remove(skipText);
			skipActive = false;
		}

		if (FlxG.keys.justPressed.SPACE && skipActive)
		{
			// clearNotesBefore(skipTo);
			callOnScripts('onSkipIntro', [skipTo]);
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
			gfVocals.pause();
			Conductor.songPosition = skipTo;

			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.play();

			vocals.time = Conductor.songPosition;
			vocals.play();
			opponentVocals.time = Conductor.songPosition;
			opponentVocals.play();
			gfVocals.time = Conductor.songPosition;
			gfVocals.play();
			FlxTween.tween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}

		//#if debug
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
		//#end

		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		switch (ClientPrefs.data.iconBounce) {
			case "Base":
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
				iconP1.scale.set(mult, mult);
				iconP1.updateHitbox();

				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
				iconP2.scale.set(mult, mult);
				iconP2.updateHitbox();

			case "Mixtape":
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
				iconP1.scale.set(mult, mult);
				iconP1.updateHitbox();

				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
				iconP2.scale.set(mult, mult);
				iconP2.updateHitbox();

				var multA:Float = FlxMath.lerp(1, iconP1.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP1.angle = multA;

				var multA:Float = FlxMath.lerp(1, iconP2.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP2.angle = multA;

				if (iconP22 != null)
				{
					var multA:Float = FlxMath.lerp(1, iconP22.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
					iconP22.angle = multA;
					var mult:Float = FlxMath.lerp(1, iconP22.scale.x, Math.exp(-elapsed * 9 * playbackRate));
					iconP22.scale.set(mult, mult);
					iconP22.updateHitbox();
				}

				if (iconP12 != null)
				{
					var multA:Float = FlxMath.lerp(1, iconP12.angle, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
					iconP12.angle = multA;
					var mult:Float = FlxMath.lerp(1, iconP12.scale.x, Math.exp(-elapsed * 9 * playbackRate));
					iconP12.scale.set(mult, mult);
					iconP12.updateHitbox();
				}
		}
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		var healthRatio:Float = health / MaxHP;
		switch (ClientPrefs.data.healthMode) {
			default:
				if (!noHeal) {
					iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
					iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
				}
				else {
					iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset + (healthRatio * 150 - 75);
					iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2 + (healthRatio * 150 - 75);
				}

				if (iconP12 != null)
					iconP12.x = iconP1.x + 25;
				if (iconP22 != null)
					iconP22.x = iconP2.x - 25;
		}
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		if (opponentmode)
		{
			switch (iconP1.type)
			{
				case SINGLE:
					iconP1.animation.curAnim.curFrame = 0;
				case WINNING:
					iconP1.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
				default:
					iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 0 : 1);
			}

			switch (iconP2.type)
			{
				case SINGLE:
					iconP2.animation.curAnim.curFrame = 0;
				case WINNING:
					iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
				default:
					iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 0 : 1);
			}

			if (iconP22 != null)
			{
				switch (iconP22.type)
				{
					case SINGLE:
						iconP22.animation.curAnim.curFrame = 0;
					case WINNING:
						iconP22.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
					default:
						iconP22.animation.curAnim.curFrame = (healthBar.percent > 80 ? 0 : 1);
				}
			}
			if (iconP12 != null)
			{
				switch (iconP12.type)
				{
					case SINGLE:
						iconP12.animation.curAnim.curFrame = 0;
					case WINNING:
						iconP12.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
					default:
						iconP12.animation.curAnim.curFrame = (healthBar.percent < 20 ? 0 : 1);
				}
			}
		}
		else
		{
			switch (iconP1.type)
			{
				case SINGLE:
					iconP1.animation.curAnim.curFrame = 0;
				case WINNING:
					iconP1.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
				default:
					iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
			}

			switch (iconP2.type)
			{
				case SINGLE:
					iconP2.animation.curAnim.curFrame = 0;
				case WINNING:
					iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
				default:
					iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);
			}

			if (iconP22 != null)
			{
				switch (iconP22.type)
				{
					case SINGLE:
						iconP22.animation.curAnim.curFrame = 0;
					case WINNING:
						iconP22.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
					default:
						iconP22.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : 0);
				}
			}
			if (iconP12 != null)
			{
				switch (iconP12.type)
				{
					case SINGLE:
						iconP12.animation.curAnim.curFrame = 0;
					case WINNING:
						iconP12.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
					default:
						iconP12.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
				}
			}
		}
		updateScoreText(); //For the "Don't Miss!" text to update properly
		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
			gfVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		chartingMode = true;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();
		if(gfVocals != null)
			gfVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();
		if(gfVocals != null)
			gfVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	var songAboutToLoop:Bool = false;
	public function loopCallback(startingPoint:Float = 0) // this took so much effort to get working I really hope people use this
	{
		// KillNotes(); // kill any existing notes...except there should be any
		FlxG.sound.music.time = startingPoint;
		if (SONG.needsVoices) setVocalsTime(startingPoint);
		lastUpdateTime = startingPoint;
		Conductor.songPosition = startingPoint;
		Conductor.visualPosition = startingPoint;
		curStep = lastStepHit = curBeat = lastBeatHit = curSection = stepsToDo = 0;
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		//reGenerating = true;
		endingSong = false;
		songAboutToLoop = false;

		/*if ((curSong == "Small Argument" && !inArchipelagoMode)
			&& AIPlayer.diff != 6
			&& AIScore != songScore) // Six is the highest there is. It's literally botplay at that point.
			AIPlayer.diff += 1;*/

		trace("AI LEVEL: " + AIPlayer.diff);
		var AIPlayMap = [];
		if (AIPlayer.active)
		{
			songScore = 0;
			songMisses = 0;
			songHits = 0;
			combo = 0;
			ratingPercent = 0;
			ratingName = "";
			ratingFC = "";
			RecalculateRating();

			AIPlayMap = AIPlayer.GeneratePlayMap(SONG, AIPlayer.diff);
			comboOpp = 0;
			/*
			AIScore = 0;
			AIMisses = 0;
			AITotalNotesHit = 0;
			AITotalPlayed = 0;
			ratingFCAI = "";
			ratingNameAI = "";
			ratingPercentAI = 0;
			RecalculateRatingAI();*/
		}

		// backend.Threader.runInThread(regenerateNotes(SONG, AIPlayMap), 0, "generateNotes");
		//regenerateNotes(SONG, AIPlayMap);
		//allNotes = curChart.copy();
		//unspawnNotes = curChart.copy();
		eventNotes = curEvents.copy();

		if (loopModeChallenge)
		{
			playbackRate *= loopPlayMult;
			currentRate *= loopPlayMult;
		}
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	var killPlayer:Bool;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		switch (ClientPrefs.data.healthMode) {
			case "OG":
				killPlayer = health <= 0 
				&& !practiceMode 
				&& !isDead 
				&& gameOverTimer == null;
			
			case "Mixtape":
				killPlayer = health <= 0 
				&& !practiceMode 
				&& !isDead 
				&& bfkilledcheck
				&& gameOverTimer == null;

			case "Kade":
				killPlayer = health <= 0 
				&& !practiceMode 
				&& !isDead 
				&& gameOverTimer == null;

			case "Tabi":
				killPlayer = health <= 0 
				&& !practiceMode 
				&& !isDead 
				&& bfkilledcheck
				&& gameOverTimer == null;

			default:
				killPlayer = health <= 0 
				&& !practiceMode 
				&& !isDead 
				&& gameOverTimer == null;
		}
		if (skipHealthCheck || instakillOnMiss && killPlayer || killPlayer)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop)
			{
				savedTime = -1;
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				if (bf2 != null)
					bf2.stunned = true;
				deathCounter++;

				if (loopMode || loopModeChallenge/* || curSong == "Small Argument" && !inArchipelagoMode*/)
				{
					Highscore.saveEndlessScore(SONG.song.toLowerCase() + saveMod, songScore);
				}

				paused = true;
				canResync = false;
				canPause = false;
				#if VIDEOS_ALLOWED
				if(videoCutscene != null)
				{
					videoCutscene.destroy();
					videoCutscene = null;
				}
				#end

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				FlxG.camera.setFilters([]);

				if(GameOverSubstate.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						gfVocals.stop();
						FlxG.sound.music.stop();
						openSubState(new GameOverSubstate(boyfriend));
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					gfVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverSubstate(boyfriend));
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
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

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
		{
			var pressed:Bool = Reflect.getProperty(controls, key);
			// trace('Control result: ' + pressed);
			return pressed;
		}

	public function triggerEvent(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Change Focus':
				isCameraOnForcedPos = true;
				switch (value1.toLowerCase().trim())
				{
					case 'dad' | 'opponent':
						moveCamera(true);
					case 'gf':
						moveCameraToGirlfriend();
					case 'dad2' | 'opponent2':
						moveCameraToDad2();
					case 'bf2' | 'boyfriend2':
						moveCameraToBF2();
					case 'bf' | 'boyfriend':
						moveCamera(false);
					default:
						isCameraOnForcedPos = false;
				}

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
					case 'both':
						value = 5;
					case 'bothalt':
						value = 6;
					case 'all':
						value = 7;
					case 'allalt':
						value = 8;
					case 'trueall':
						value = 9;
					default: value = 2;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				switch (value)
				{
					case 0:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = flValue2;
					case 1:
						if (dad.curCharacter.startsWith('gf'))
						{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = flValue2;
						}
						else if (gf != null)
						{
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = flValue2;
						}
					case 2:
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					case 3:
						bf2.playAnim('hey', true);
						bf2.specialAnim = true;
						bf2.heyTimer = flValue2;
					case 4:
						dad2.playAnim('hey', true);
						dad2.specialAnim = true;
						dad2.heyTimer = flValue2;
					case 5:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = flValue2;
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					case 6:
						bf2.playAnim('hey', true);
						bf2.specialAnim = true;
						bf2.heyTimer = flValue2;
						dad2.playAnim('hey', true);
						dad2.specialAnim = true;
						dad2.heyTimer = flValue2;
					case 7:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = flValue2;
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					case 8:
						bf2.playAnim('hey', true);
						bf2.specialAnim = true;
						bf2.heyTimer = flValue2;
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
						dad2.playAnim('hey', true);
						dad2.specialAnim = true;
						dad2.heyTimer = flValue2;
					case 9:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = flValue2;
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
						bf2.playAnim('hey', true);
						bf2.specialAnim = true;
						bf2.heyTimer = flValue2;
						dad2.playAnim('hey', true);
						dad2.specialAnim = true;
						dad2.heyTimer = flValue2;
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
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
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad2' | 'opponent2':
						char = dad2;
					case 'bf2' | 'boyfriend2':
						char = bf2;
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
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					case 'dad2' | 'opponent2':
						charType = 3;
					case 'bf2' | 'boyfriend2':
						charType = 4;
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
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
					case 3:
						if (dad2 != null)
						{
							if (dad2.curCharacter != value2)
							{
								if (!dadMap2.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var wasGf:Bool = dad2.curCharacter.startsWith('gf');
								var lastAlpha:Float = dad2.alpha;
								dad2.alpha = 0.00001;
								dad2 = dadMap2.get(value2);
								if (!dad2.curCharacter.startsWith('gf'))
								{
									if (wasGf && gf != null)
									{
										gf.visible = true;
									}
								}
								else if (gf != null)
								{
									gf.visible = false;
								}
								dad2.alpha = lastAlpha;
								iconP22.changeIcon(dad2.healthIcon);
							}
							setOnScripts('dad2Name', dad2.curCharacter);
						}
					case 4:
						if (bf2 != null)
						{
							if (bf2.curCharacter != value2)
							{
								if (!boyfriendMap2.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = bf2.alpha;
								bf2.alpha = 0.00001;
								bf2 = boyfriendMap2.get(value2);
								bf2.alpha = lastAlpha;
								iconP12.changeIcon(bf2.healthIcon);
							}
							setOnScripts('bf2Name', bf2.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
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
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;

					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], trueValue);
					} else {
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;

				newMania = Std.parseInt(value1);
				if (Math.isNaN(newMania) && newMania < Note.minMania && newMania > Note.maxMania)
					newMania = 0;
				changeMania(newMania, skipTween);

			case 'False Timer':
				if (timerExtensions != null)
				{
					timerExtensions.shift();

					var next:Dynamic = timerExtensions[0];
					var toValue:Float = (next != null && next > 0) ? next : songLength;
					// maskedSongLength = value; instead of tweenMask.bind(timeTxt)
					FlxTween.num(maskedSongLength, toValue, if (flValue1 != null) flValue1 else Conductor.stepCrochet * 0.001 * 16, {
						ease: LuaUtils.getTweenEaseByString(value2),
						onComplete: function(twn:FlxTween)
						{
							maskedSongLength = toValue;
							if (twn.active)
								twn.cancel();
							twn.active = false;
							twn.destroy();
						}
					}, function(value:Float)
					{
						maskedSongLength = value;
					});
				}
			case 'Change Lyric':
				lyrics.text = value1;
				var split:Array<String> = value2.split(',');
				var color:String = split[0];
				var effect:String = split[1];
				lyricManager(split[0].trim(), split[1].trim());

			case 'Turn on StrumFocus':
				strumFocus = true;

			case 'Turn off StrumFocus':
				strumFocus = false;
				modManager.queueEase(curStep, curStep + 4, 'alpha', 0, 'sineInOut', 0);
				modManager.queueEase(curStep, curStep + 4, 'alpha', 0, 'sineInOut', 1);

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

			case 'Change Stage':
				var stageName = value1;
				// var newStageDatas = new Array<Dynamic>();

				for (lua in luaArray)
				{ 
					var lua:Dynamic = cast(lua);
					if (lua.scriptName == 'stages/' + stageName + '.lua')
					{
						return;
					}
					else if (lua.scriptName == 'stages/' + curStage + '.lua')
					{
						lua.call('onDestroy', []);
						lua.closed = true;
						lua.stop();
					}
				}
				for (hscript in hscriptArray)
				{
					if (hscript.origin == 'stages/' + stageName + '.hx')
					{
						return;
					}
					else if (hscript.origin == 'stages/' + curStage + '.hx')
					{
						if(hscript != null)
						{
							if(hscript.exists('onDestroy')) hscript.call('onDestroy');
							hscript.destroy();
						}
					}
				}

				// for (stage in MusicBeatState.stages)
				// {
				// 	if (stage is BaseStage)
				// 	{
				// 		stage.destroy();
				// 	}
				// }

				stagesFunc(function(stage:BaseStage) stage.destroy());

				switch (stageName)
				{
					case 'stage':
						new StageWeek1(); // Week 1
					case 'spooky':
						new Spooky(); // Week 2
					case 'philly':
						new Philly(); // Week 3
					case 'limo':
						new Limo(); // Week 4
					case 'mall':
						new Mall(); // Week 5 - Cocoa, Eggnog
					case 'mallEvil':
						new MallEvil(); // Week 5 - Winter Horrorland
					case 'school':
						new School(); // Week 6 - Senpai, Roses
					case 'schoolEvil':
						new SchoolEvil(); // Week 6 - Thorns
					case 'tank':
						new Tank(); // Week 7 - Ugh, Guns, Stress
					case 'phillyStreets':
						new PhillyStreets(); // Weekend 1 - Darnell, Lit Up, 2Hot
					case 'phillyBlazin':
						new PhillyBlazin(); // Weekend 1 - Blazin
					case 'mainStageErect':
						new MainStageErect(); // Week 1 Special
					case 'spookyMansionErect':
						new SpookyMansionErect(); // Week 2 Special
					case 'phillyTrainErect':
						new PhillyTrainErect(); // Week 3 Special
					case 'limoRideErect':
						new LimoRideErect(); // Week 4 Special
					case 'mallXmasErect':
						new MallXmasErect(); // Week 5 Special
					case 'phillyStreetsErect':
						new PhillyStreetsErect(); // Weekend 1 Special
					case 'desktop':
						new Desktop(); // Literally your desktop as a stage lmao
					default:
				}

				#if LUA_ALLOWED
				startLuasNamed('stages/' + stageName + '.lua');
				#end
				#if HSCRIPT_ALLOWED
				startHScriptsNamed('stages/' + stageName + '.hx');
				#end
				var scripts:Array<Array<Dynamic>> = [luaArray, hscriptArray];
				stagesFunc(function(stage:BaseStage) stage.createPost());
				for (stuff in scripts)
				{
					for (script in stuff)
					{
						if (script is HScript)
						{
							var script:HScript = cast(script);
							if (script.origin == 'stages/' + stageName + '.hx' || script.origin == 'stages/' + stageName + '.lua')
							{
								script.call('onCreatePost', []);
							}
						}
						else if (script is FunkinLua)
						{
							var script:FunkinLua = cast(script);
							if (script.scriptName == 'stages/' + stageName + '.lua')
							{
								script.call('onCreatePost', []);
							}
						}
					}
				}
			
			case 'Static':
				if (value1 == 'true' || value1 == 'True' || value1 == 'on' || value1 == 'On')
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

			case 'Rave Mode':
				if (ClientPrefs.data.flashing)
				{
					switch (value1.toLowerCase())
					{
						case '0' | 'off' | 'false':
							ravemode = false;
						case '1' | 'on' | 'true':
							ravemode = true;
					}
				}

			case 'gfScared':
				var newValue:Bool = false;
				if (value1.toLowerCase() == "true")
					newValue = true;
				gfScared = newValue;

			case 'Freeze Notes':
				if (value1 == 'true' || value1 == 'True')
				{
					freezeNotes = true;
					localFreezeNotes = true;
				}
				else
				{
					freezeNotes = false;
					localFreezeNotes = false;
				}
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	function theShadow(convertedvalue:String)
	{
		if (gimmicksAllowed)
		{
			if (convertedvalue.toLowerCase() == 'black')
			{
				FlxTween.tween(whiteBG, {alpha: 1}, 0.1);
				FlxTween.tween(blackUnderlay, {alpha: 0}, 0.1);
				if (dad2 != null)
					FlxTween.tween(dad2.colorTransform, {blueOffset: -255, redOffset: -255, greenOffset: -255}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(boyfriend.colorTransform, {blueOffset: -255, redOffset: -255, greenOffset: -255}, 0.1, {ease: FlxEase.sineInOut});
				if (bf2 != null)
					FlxTween.tween(bf2.colorTransform, {blueOffset: -255, redOffset: -255, greenOffset: -255}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(dad.colorTransform, {blueOffset: -255, redOffset: -255, greenOffset: -255}, 0.1, {ease: FlxEase.sineInOut});
				if (gf != null)
					FlxTween.tween(gf.colorTransform, {blueOffset: -220, redOffset: -220, greenOffset: -220}, 0.1, {ease: FlxEase.sineInOut});
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				// boyfriend.color = FlxColor.BLACK;
				// gf.color = FlxColor.BLACK;
				// dad.color = FlxColor.BLACK;
			}
			else if (convertedvalue.toLowerCase() == 'white')
			{
				FlxTween.tween(blackUnderlay, {alpha: 1}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1, {ease: FlxEase.sineInOut});
				if (dad2 != null)
					FlxTween.tween(dad2.colorTransform, {blueOffset: 255, redOffset: 255, greenOffset: 255}, 0.1, {ease: FlxEase.sineInOut});
				if (bf2 != null)
					FlxTween.tween(bf2.colorTransform, {blueOffset: 255, redOffset: 255, greenOffset: 255}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(boyfriend.colorTransform, {blueOffset: 255, redOffset: 255, greenOffset: 255}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(dad.colorTransform, {blueOffset: 255, redOffset: 255, greenOffset: 255}, 0.1, {ease: FlxEase.sineInOut});
				if (gf != null)
					FlxTween.tween(gf.colorTransform, {blueOffset: 220, redOffset: 220, greenOffset: 220}, 0.1, {ease: FlxEase.sineInOut});
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				// boyfriend.color = 0xffffffff;
				// gf.color = 0xffffffff;
				// dad.color = 0xffffffff;
			}
			else
			{
				FlxTween.tween(whiteBG, {alpha: 0}, 0.1);
				FlxTween.tween(blackUnderlay, {alpha: 0}, 0.1);
				if (dad2 != null)
					FlxTween.tween(dad2.colorTransform, {blueOffset: 0, redOffset: 0, greenOffset: 0}, 0.1, {ease: FlxEase.sineInOut});
				if (bf2 != null)
					FlxTween.tween(bf2.colorTransform, {blueOffset: 0, redOffset: 0, greenOffset: 0}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(boyfriend.colorTransform, {blueOffset: 0, redOffset: 0, greenOffset: 0}, 0.1, {ease: FlxEase.sineInOut});
				FlxTween.tween(dad.colorTransform, {blueOffset: 0, redOffset: 0, greenOffset: 0}, 0.1, {ease: FlxEase.sineInOut});
				if (gf != null)
					FlxTween.tween(gf.colorTransform, {blueOffset: 0, redOffset: 0, greenOffset: 0}, 0.1, {ease: FlxEase.sineInOut});
				FlxG.camera.zoom += 0.030;
				camHUD.zoom += 0.04;
				// boyfriend.color = FlxColor.WHITE;
				// gf.color = FlxColor.WHITE;
				// dad.color = FlxColor.WHITE;
			}
		}
	}

	function lyricManager(color:String, effect:String) {
		if (color != null) {
			switch (color)
			{
				case 'red':
					lyrics.color = FlxColor.RED;
				case 'blue':
					lyrics.color = FlxColor.BLUE;
				case 'green':
					lyrics.color = FlxColor.GREEN;
				case 'white':
					lyrics.color = FlxColor.WHITE;
				default:
					lyrics.color = FlxColor.fromString(color);
			}
		}
		else lyrics.color = FlxColor.WHITE;

		if (effect != null) {
			switch (effect)
			{
				case 'none':
					lyrics.alpha = 1;
				case 'fadeout':
					FlxTween.tween(lyrics, {alpha: 0}, 1, {ease: FlxEase.expoIn});
				case 'fadein':
					FlxTween.tween(lyrics, {alpha: 1}, 1, {ease: FlxEase.expoIn});
			}
		} else lyrics.alpha = 1;
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			moveCameraToGirlfriend();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		if (dad2 != null && SONG.notes[curSection].exSection && !SONG.notes[curSection].mustHitSection)
		{
			camFollow.setPosition(dad2.getMidpoint().x, dad2.getMidpoint().y);
			camFollow.x += dad2.cameraPosition[0] + opponent2CameraOffset[0];
			camFollow.y += dad2.cameraPosition[1] + opponent2CameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['dad2']);
			return;
		}

		if (bf2 != null && SONG.notes[curSection].exSection && !SONG.notes[curSection].gfSection && SONG.notes[curSection].mustHitSection)
		{
			camFollow.setPosition(bf2.getMidpoint().x, bf2.getMidpoint().y);
			camFollow.x += bf2.cameraPosition[0] + boyfriend2CameraOffset[0];
			camFollow.y += bf2.cameraPosition[1] + boyfriend2CameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['bf2']);
			return;
		}

		var isDad:Bool = (!SONG.notes[curSection].exSection && SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		if (isDad)
			callOnScripts('onMoveCamera', ['dad']);
		else
			callOnScripts('onMoveCamera', ['boyfriend']);
	}
	
	public function moveCameraToGirlfriend()
	{
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		tweenCamIn();
	}

	public function moveCameraToDad2()
	{
		camFollow.setPosition(dad2.getMidpoint().x, dad2.getMidpoint().y);
		camFollow.x += dad2.cameraPosition[0] + opponent2CameraOffset[0];
		camFollow.y += dad2.cameraPosition[1] + opponent2CameraOffset[1];
		tweenCamIn();
	}

	public function moveCameraToBF2()
	{
		camFollow.setPosition(bf2.getMidpoint().x, bf2.getMidpoint().y);
		camFollow.x += bf2.cameraPosition[0] + boyfriend2CameraOffset[0];
		camFollow.y += bf2.cameraPosition[1] + boyfriend2CameraOffset[1];
		tweenCamIn();
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if(dad == null) return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			if(boyfriend == null) return;
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
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

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	// Simple yet convenent functions frim JS-engine my belovid
	public function unpauseVocals()
	{
		for (i in [vocals, opponentVocals, gfVocals])
			if (i != null && i.time <= FlxG.sound.music.length)
				i.resume();
	}

	public function pauseVocals()
	{
		for (i in [vocals, opponentVocals, gfVocals])
			if (i != null && i.time <= FlxG.sound.music.length)
				i.pause();
	}

	public function setVocalsTime(time:Float)
	{
		for (i in [vocals, opponentVocals, gfVocals])
			if (i != null && i.time < vocals.length)
				i.time = time;
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();
		gfVocals.volume = 0;
		gfVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			});
			for (daNote in unspawnNotes)
			{
				if(daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent, songMisses, deathCounter);
			#end
			deathCounter = 0; // set it to 0 AFTER it's been saved
			playbackRate = 1;
			savedTime = 0;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
					gameplayArea = "Story";
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						camHUD.alpha -= 1 / 10;
					}, 10);
					openSubState(new substates.RankingSubstate());
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState(), false, false);
				}
			}
			else
			{
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				if (gameplayArea != "APFreeplay")
					gameplayArea = "Freeplay";
				changedDifficulty = false;
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					camHUD.alpha -= 1 / 10;
				}, 10);
				openSubState(new substates.RankingSubstate());
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes()
	{
		notes.clear();
		allNotes = [];
		unspawnNotes = [];
		for (field in playfields)
		{
			field.clearDeadNotes();
			field.spawnedNotes = [];
			field.noteQueue = [[], [], [], []];
		}

		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	private function cachePopUpScore()
	{
		var uiFolder:String = "";
		if (stageUI != "normal")
			uiFolder = uiPrefix + "UI/";

		for (rating in ratingsData)
			Paths.image(uiFolder + rating.image + uiPostfix);
		for (i in 0...10)
			Paths.image(uiFolder + 'num' + i + uiPostfix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				spr.destroy();
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			note.field.spawnNoteSplashOnNote(note);

		if(!cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/";
			antialias = !isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiFolder + daRating.image + uiPostfix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

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
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function popUpScoreOpp(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				spr.destroy();
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			note.field.spawnNoteSplashOnNote(note);

		if(!cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/";
			antialias = !isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiFolder + daRating.image + uiPostfix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

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
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function strumKeyDown(column:Int, player:Int = -1) {
		if (strumsBlocked[column]) return;
		
		if (callOnScripts("onKeyPress", [column]) == LuaUtils.Function_Stop)
			return;
		
		var hitNotes:Array<Note> = []; // what could scripts possibly do with this information
		var controlledFields:Array<PlayField> = [];
		
		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed) 
				continue;

			controlledFields.push(field);
			field.keysPressed[column] = true;

			if (endingSong) 
				continue;

			var note:Note = {
				var ret:Dynamic = callOnScripts("onFieldInput", [field, column, hitNotes]);
				if (ret == LuaUtils.Function_Stop) null;
				else if (ret is Note) ret;
				else field.input(column);
			}

			if (note == null) {
				var spr:StrumNote = field.strumNotes[column];
				if (spr != null) {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}else {
				hitNotes.push(note);
			}
		}
		
		if (hitNotes.length == 0) {
			for (field in controlledFields) {				
				callOnScripts('onGhostTap', [column, field]);

				if (!ClientPrefs.data.ghostTapping)
					noteMissPress(column, field);
			}
		}

		//trace('strum down: $column');
	}

	private function strumKeyUp(column:Int, player:Int = -1) {
		// doesnt matter if THIS is done while paused
		// only worry would be if we implemented Lifts
		// but afaik we arent doing that
		// (though could be interesting to add)

		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed) 
				continue;

			field.keysPressed[column] = false;
			
			if (!field.isHolding[column]) {
				var spr:StrumNote = field.strumNotes[column];
				if (spr != null){
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
		}

		callOnScripts('onKeyRelease', [column]);
	}

	public var strumsBlocked:Array<Bool> = [];
	var closestNotes:Array<Note> = [];
	var pressed:Array<FlxKey> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		#if debug
		//Prevents crash specifically on debug without needing to try catch shit
		@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
		#end
		if (ClientPrefs.data.inputSystem == "Native-old") {
			if (!controls.controllerMode)
			{
				if (paused || !startedCountdown || inCutscene) return;
				if (pressed.contains(eventKey)) return;
				pressed.push(eventKey);
				if (key != -1) strumKeyDown(key);
			}
		}
		else {
			if (paused || !startedCountdown || inCutscene) return;
			if (pressed.contains(eventKey)) return;
			pressed.push(eventKey);
			if (callOnScripts("onKeyDown", [event]) == LuaUtils.Function_Stop) return;
	
			if (key > -1)
			{
				var hitNotes:Array<Note> = [];
				var controlledFields:Array<PlayField> = [];
	
				if (strumsBlocked[key]) return;
				if (callOnScripts("onKeyPress", [key]) == LuaUtils.Function_Stop) return;	
				for (field in playfields.members)
				{
					if (!field.autoPlayed && field.isPlayer && field.inControl)
					{
						controlledFields.push(field);
						field.keysPressed[key] = true;
						if (generatedMusic && !endingSong)
						{
							var note:Note = null;
							var ret:Dynamic = callOnScripts("onFieldInput", [field, key, hitNotes]);
							if (ret == LuaUtils.Function_Stop) continue;
							else if ((ret.objType == NOTE)) note = ret;
							else note = field.input(key);
	
							if (note == null)
							{
								var spr:StrumNote = field.strumNotes[key];
								if (spr != null && spr.animation.curAnim.name != 'confirm')
								{
									spr.playAnim('pressed');
									spr.resetAnim = 0;
								}
							}
							else hitNotes.push(note);
						}
					}
					if (hitNotes.length == 0 && controlledFields.length > 0)
					{
						callOnScripts('onGhostTap', [key]);
		
						if (!ClientPrefs.data.ghostTapping)
							noteMissPress(key, field);
					}
				}
			}
		}
	}

	private function keyPressed(key:Int, player:Int = -1)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;
		if (strumsBlocked[key]) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var hitNotes:Array<Note> = []; // what could scripts possibly do with this information
		var controlledFields:Array<PlayField> = [];
		
		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed) 
				continue;

			controlledFields.push(field);
			field.keysPressed[key] = true;

			if (endingSong) 
				continue;

			var note:Note = {
				var ret:Dynamic = callOnScripts("onFieldInput", [field, key, hitNotes]);
				if (ret == LuaUtils.Function_Stop) null;
				else if (ret is Note) ret;
				else field.input(key);
			}

			if (note == null) {
				var spr:StrumNote = field.strumNotes[key];
				if (spr != null) {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}else {
				hitNotes.push(note);
			}
		}
		
		if (hitNotes.length == 0) {
			for (field in controlledFields) {				
				callOnScripts('onGhostTap', [key, field]);

				if (!ClientPrefs.data.ghostTapping)
					noteMissPress(key, field);
			}
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
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
		//if(!controls.controllerMode && key > -1) keyReleased(key);
		if (pressed.contains(eventKey))
			pressed.remove(eventKey);

		if (key != -1) strumKeyUp(key);
	}

	private function keyReleased(key:Int, ?player:Int = -1)
	{
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed) 
				continue;

			field.keysPressed[key] = false;
			
			if (!field.isHolding[key]) {
				var spr:StrumNote = field.strumNotes[key];
				if (spr != null){
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
			for (i in 0...keysArray[mania].length)
				for (j in 0...keysArray[mania][i].length)
					if (key == keysArray[mania][i][j])
						return i;
		return -1;
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
	// This is for the old (new) input
	public static var pressedGameplayKeys:Array<Bool> = [];
	private function keysCheck():Void
	{
		if (ClientPrefs.data.inputSystem == 'Native-old') {
			var holdArray:Array<Bool> = [];
			var pressArray:Array<Bool> = [];
			var releaseArray:Array<Bool> = [];
			for (key in keysArray[mania])
			{
				holdArray.push(controls.pressed(key));
				pressArray.push(controls.justPressed(key));
				releaseArray.push(controls.justReleased(key));
			}

			// TO DO: Find a better way to handle controller inputs, this should work for now
			if(controls.controllerMode && pressArray.contains(true))
				for (i in 0...pressArray.length)
					if(pressArray[i] && strumsBlocked[i] != true)
						keyPressed(i);

			

			if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic)
			{
				

				if (!holdArray.contains(true) && !endingSong)
					playerDance();

				#if ACHIEVEMENTS_ALLOWED
				else checkForAchievement(['oversinging']);
				#end
			}

			// TO DO: Find a better way to handle controller inputs, this should work for now
			if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
				for (i in 0...releaseArray.length)
					if(releaseArray[i] || strumsBlocked[i] == true)
						keyReleased(i);
		} else {
			// HOLDING
			var parsedHoldArray:Array<Bool> = parseKeys();
			pressedGameplayKeys = parsedHoldArray;
			// FlxG.watch.addQuick('asdfa', upP);
			if (startedCountdown && !boyfriend.stunned && generatedMusic)
			{
				// rewritten inputs???
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (parsedHoldArray.contains(true) && !endingSong)
					{
						#if ACHIEVEMENTS_ALLOWED
						checkForAchievement(['oversinging']);
						#end
					}
				});

				if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
					boyfriend.dance();

				if (strumsBlocked.contains(true))
				{
					var parsedArray:Array<Bool> = parseKeys('_R');
					if (parsedArray.contains(true))
					{
						for (i in 0...parsedArray.length)
						{
							if (parsedArray[i] || strumsBlocked[i] == true)
								onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[mania][i][0]));
						}
					}
				}
			}
		}
	}

	function noteMiss(daNote:Note, field:PlayField):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1, field:PlayField):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}
	
	public function ogNoteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = pressMissDamage;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			gfVocals.volume = 0;
			die();
			COD.setPresetCOD(note, 'miss');
		}

		COD.setPresetCOD(note, 'miss0');

		bfkilledcheck = true;
		
		var lastCombo:Int = combo;
		combo = 0;

		switch (ClientPrefs.data.healthMode) {
			case "Kade":
				if (note.isParent) {
					health -= 0.15; // give a health punishment for failing a LN
					trace("hold fell over at the start");
				}
				else {
					if (!note.wasGoodHit && !note.isSustainNote)
					{
						health -= 0.15;
					}
				}

			case "Tabi":
				if (!note.isSustainNote) health -= 0.1;
				health -= 0.0475;
				health -= 0.04;
				health -= 0.08;

			case "Mixtape" | "OG":
				health -= subtract * healthLoss;
		}
		songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		if (opponentmode || note.field == dadField)
			char = dad;
		if (note.exNote && note.field == playerField)
			char = bf2;
		if (note.exNote && note.field == dadField)
			char = dad2;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var postfix:String = '';
			if(note != null) postfix = note.animSuffix;

			var animToPlay:String = Note.keysShit.get(mania).get('singAnims')[Std.int(direction)] + 'miss' + postfix;
			char.playAnim(animToPlay, true);

			if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note, field:PlayField):Void
	{
		var result:Dynamic;
		if (opponentmode)
		{
			result = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);
		}
		else
		{
			result = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);
		}

		if(result == LuaUtils.Function_Stop) return;

		if (songName != 'tutorial')
			camZooming = true;

		if (AIPlayer.active && !note.isSustainNote)
		{
			comboOpp += 1;
			popUpScoreOpp(note);
			// if(combo > 9999) combo = 9999;
		}

		if(note.noteType == 'Hey!' && dad.hasAnimation('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if(!note.noAnimation)
		{
			var char:Character = dad;
			var animToPlay:String = Note.keysShit.get(mania).get('singAnims')[note.noteData] + note.animSuffix;
			if(note.gfNote) char = gf;
			if (note.exNote && !note.gfNote) char = dad2;

			if (!note.exNote && !note.gfNote && note.noteType == 'GF Duet') {
				if(gf != null)
				{
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(gf.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(gf.getAnimationName() == holdAnim || gf.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}
	
					if(canPlay) gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}
			}

			if(char != null)
			{
				var canPlay:Bool = true;
				if(note.isSustainNote)
				{
					var holdAnim:String = animToPlay + '-hold';
					if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
					if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
				}

				if(canPlay) char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (ClientPrefs.data.healthMode == "Tabi" && health > 0)
		{
			if (note.isSustainNote)
			{
				health -= 0.0005;
			} else {
				//health -= 0.04;
				health -= 0.03;
			}
		}

		if(opponentVocals.length <= 0) vocals.volume = 1;
		strumPlayAnim(field, note.column % field.keyCount, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
		
		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note, field:PlayField):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		note.wasGoodHit = true;

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(!note.hitCausesMiss) //Common notes
		{
			if(!note.noAnimation)
			{
				var animToPlay:String = Note.keysShit.get(mania).get('singAnims')[note.noteData] + note.animSuffix;

				var char:Character = boyfriend;
				var animCheck:String = 'hey';
				if (note.exNote && !note.gfNote && note.noteType != 'GF Duet') char = bf2;
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}

				if (!note.exNote && !note.gfNote && note.noteType == 'GF Duet') {
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(gf.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(gf.getAnimationName() == holdAnim || gf.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}
	
					if(canPlay) gf.playAnim(animToPlay, true);
					gf.holdTimer = 0;
				}

				if(char != null)
				{
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}
	
					if(canPlay) char.playAnim(animToPlay, true);
					char.holdTimer = 0;

					if(note.noteType == 'Hey!')
					{
						if(char.hasAnimation(animCheck))
						{
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if(!cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false))
			{
				var spr = field.strumNotes[note.column];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(field, note.column % field.keyCount, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}

			if (ClientPrefs.data.inputSystem == "Mic'ed Up Engine")
			{
				if (mashing != 0)
					mashing = 0;

				if (mashViolations >= 1)
					mashViolations--;

				if (mashViolations < 0)
					mashViolations = 0;
			}
			var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
			if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
			if (gainHealth){
				switch (ClientPrefs.data.healthMode) {
					case "Kade":
						var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
						var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);
						switch (daRating.name)
						{
							case 'shit':
								health -= 0.1;
							case 'bad':
								health -= 0.06;
							case 'sick':
								if (health < 2)
									health += 0.04;
							case 'marv':
								if (health < 2)
									health += 0.08;
						}
					case "Tabi":
						if (note.noteData >= 0)
							health += 0.023;
						else
							health += 0.004;
						health += 0.05;
						health += 0.05;
					case "Mixtape" | "OG": 
						health += note.hitHealth * healthGain;
				}
			} 

		}
		else //Notes that count as a miss if you hit them (Hurt notes for example)
		{
			if(!note.noMissAnimation)
			{
				switch(note.noteType)
				{
					case 'Hurt Note':
						if(boyfriend.hasAnimation('hurt'))
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}
			
			noteMiss(note, field);
			if(!note.noteSplashData.disabled && !note.isSustainNote) note.field.spawnNoteSplashOnNote(note);
		}

		bfkilledcheck = false;

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if(!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	override function destroy() {
		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		for (lua in legacyLuaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		legacyLuaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		stagesFunc(function(stage:BaseStage) stage.destroy());

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.setFilters([]);

		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		NoteSplash.configs.clear();
		mania = 3;
		instance = null;
		super.destroy();
		endingSong = true;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	public function lerpSongSpeed(num:Float, time:Float):Void
	{
		FlxTween.num(playbackRate, num, time, {ease: FlxEase.sineInOut}, function(value:Float)
		{
			playbackRate = value * currentRate;
			resyncVocals();
		});

		var staticLinesNum = FlxG.random.int(3, 5);
		for (i in 0...staticLinesNum)
		{
			var startPos = FlxG.random.float(0, FlxG.height);
			var endPos = FlxG.random.float(0, FlxG.height);

			var line:FlxSprite = new FlxSprite().loadGraphic(Paths.image("effects/staticline"));
			line.y = startPos;
			line.updateHitbox();
			line.cameras = [camHUD];
			line.alpha = 0.3;

			line.screenCenter(X);
			add(line);
			FlxTween.tween(line, {y: endPos}, time, {
				ease: FlxEase.circInOut,
				onComplete: function(twn:FlxTween)
				{
					line.destroy();
				}
			});
		}
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (curBeat % 32 == 0 && RandomSpeedChange && !songAboutToLoop)
		{
			// goes up to 3x speed cuz screw you thats why
			var randomShit = FlxMath.roundDecimal(FlxG.random.float(0.45, 2), 2);
			lerpSongSpeed(randomShit, 1);
		}

		switch (ClientPrefs.data.iconBounce) {
			case "Base":
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);

				if (dad2 != null)
					iconP22.scale.set(1.2, 1.2);
				if (iconP12 != null)
					iconP12.scale.set(1.2, 1.2);

			case "Mixtape":
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);

				if (dad2 != null)
					iconP22.scale.set(1.2, 1.2);
				if (iconP12 != null)
					iconP12.scale.set(1.2, 1.2);

				if (curBeat % 2 / gfSpeed == 0)
				{
					iconP1.angle = -15;
					iconP2.angle = -15;
					if (iconP22 != null)
						iconP22.angle = -15;
					if (iconP12 != null)
						iconP12.angle = -15;
				}
				else if (curBeat % 2 / gfSpeed == 1)
				{
					iconP1.angle = 15;
					iconP2.angle = 15;
					if (iconP22 != null)
						iconP22.angle = 15;
					if (iconP12 != null)
						iconP12.angle = 15;
				}
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		if (dad2 != null)
			iconP22.updateHitbox();
		if (iconP12 != null)
			iconP12.updateHitbox();

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();
		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
		if (bf2 != null && beat % bf2.danceEveryNumBeats == 0 && !bf2.getAnimationName().startsWith('sing') && !bf2.stunned)
			bf2.dance();
		if (dad2 != null && beat % dad2.danceEveryNumBeats == 0 && !dad2.getAnimationName().startsWith('sing') && !dad2.stunned)
			dad2.dance();
	}

	public function playerDance():Void
	{
		var anim:String = boyfriend.getAnimationName();
		if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
			boyfriend.dance();
		if (bf2 != null) {
			var anim2:String = bf2.getAnimationName();
			if(bf2.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * bf2.singDuration && anim2.startsWith('sing') && !anim2.endsWith('miss'))
				bf2.dance();
		}
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			(ClientPrefs.getGameplaySetting('legacyMode', false) ? new LegacyFunkinLua(luaToLoad) : new FunkinLua(luaToLoad));
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		// var lua = flixel.util.typeLimit.OneOfTwo;

		var arr:Array<Dynamic> = [];
		for (script in yutautil.CollectionUtils.toIterable(cast(luaArray:Array<Dynamic>).concat(legacyLuaArray)))
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
			(luaArray.contains(script)) ? luaArray.remove(script) : legacyLuaArray.remove(cast(script, LegacyFunkinLua));
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for(script in hscriptArray)
		{
			try {
				@:privateAccess
				if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
					continue;

				var callValue = script.call(funcToCall, args);
				if(callValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;

					if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
			catch(e) {}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note) {
		var spr:StrumNote = field.strumNotes[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			if(!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
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

			if(FileSystem.exists(vert))
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
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end
}
