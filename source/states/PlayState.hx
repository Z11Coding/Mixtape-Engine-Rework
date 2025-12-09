package states;

import backend.AIPlayer;
import backend.Highscore;
import backend.Rating;
import backend.Song;
import backend.WeekData;
import backend.modchart.ModManager;
import backend.modchart.Modifier;
import backend.pslice.Scoring.ScoringRank;
import backend.pslice.Scoring;
import cutscenes.DialogueBoxPsych;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDirection;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import lime.media.openal.AL;
import lime.media.openal.ALAuxiliaryEffectSlot;
import lime.media.openal.ALEffect;
import lime.utils.Assets;
import managers.DynamicSongManager;
import managers.DynamicSongScripting;
import managers.NotePoolManager;
import metadata.STMetaFile.MetadataFile;
import objects.*;
import objects.Note.EventNote;
import objects.Note.SustainPart;
import objects.NoteObject;
import objects.SyncedVideoSprite;
import objects.VideoSprite;
import objects.playfields.*;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;
import shaders.ErrorHandledShader;
import stages.*;
import stages.StageData;
import states.StoryMenuState;
import states.editors.CharacterEditorState;
import states.editors.ChartingState;
import states.playbits.*; // All the bits
import substates.GameOverSubstate;
import substates.PauseSubState;
import substates.StickerSubState;
import substates.results.Tallies.SaveScoreData;
import yutautil.AprilFools;
import yutautil.ChanceSelector.Chance;
import yutautil.ChanceSelector;
import yutautil.UnoMechanic;

#if MECHANICS_MOD_ALLOWED
import mechanics.MechanicsPlaystate;
import mechanics.objects.Shape;
#end

#if (target.threaded)
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;
#end

#if LUA_ALLOWED
import psychlua.*;

using psychlua.IntegratedScript;
#else
import psychlua.HScript;
import psychlua.LuaUtils;
#end

#if HSCRIPT_ALLOWED
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
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
@:structInit
class SpeedEvent
{
	public var position:Float; // the y position where the change happens (modManager.getVisPos(songTime))
	public var startTime:Float; // the song position (conductor.songTime) where the change starts
	#if EASED_SVs
	public var startSpeed:Float; // the previous event's speed
	public var endTime:Null<Float> = null; // the song position (conductor.songTime) when the change ends
	public var easeFunc:EaseFunction = FlxEase.linear;
	#end
	public var speed:Float; // speed mult after the change
}

@:noScripting
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

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
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	#end

	public var comboOffsetCustom:Null<Array<Int>> = null;

	// override function preloadFunction():Void {
	// 	generateSong();
	// }

	// Save Settings...

	public var clientSaveData = yutautil.save.ObjectSerializer.deepClone(ClientPrefs.data);

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

	// Cached indices for performance optimization
	private var _noteGroupIndex:Int = -1;
	private var _gfGroupIndex:Int = -1;
	private var _dadGroupIndex:Int = -1;
	private var _dadGroup2Index:Int = -1;
	private var _boyfriendGroupIndex:Int = -1;
	private var _boyfriendGroup2Index:Int = -1;
	private var _uiGroupIndex:Int = -1;

	// Cached strings for performance
	private var _cachedSongName:String;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isLegacyLuaTest:Bool = false; // Flag to track if we're testing from Legacy Lua settings
	public static var isPixelStage(get, never):Bool;
	var raveLight:FlxSprite;
	var raveLightsColors:Array<Int>;
	var ravemode:Bool;

	// 	public static function testSpeedEvent(input:Dynamic):Null<SpeedEvent>
	// {
	// 	// Checks if the input is a LuaScript instance.
	// 	return yutautil.CUMacroTools.createNullStruct();
	// }


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

	// ! new shit P-Slice
	public static var storyCampaignTitle = "";
	public static var altInstrumentals:String = null;
	public static var storyDifficultyColor = FlxColor.GRAY;

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
	public static var curChart:Array<Note> = [];
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
	public var camZoomingFrequency:Float = 4;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var minHealth:Float = 0;
	public var MaxHP:Float = 2;
	public var extraHealth:Float = 0;
	public var noHeal:Bool = false;
	public var maxHealthOffset:Float = 0;
	public var minHealthOffset:Float = 0;

	private var healthBarTween:FlxTween;

	private var healthBarShader:ColorSwap;
	public var healthBar:Bar;
	public var healthBarOverflow:Bar;
	public var healthBarBlock:FlxSprite;
	public var minBarBlock:FlxSprite;
	public var timeBar:Bar;
	var songPercent:Float = 0;

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
	public var legacyLuaTestTxt:FlxText; // Text to indicate Legacy Lua testing mode

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP12:HealthIcon;
	public var iconP22:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camCredit:FlxCamera;
	public var camOther:FlxCamera;
	public var camCOD:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var modchartDebugTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	public var defaultCamHudZoom:Float = 0;
	public var defaultStageZoom:Float = 1.05;
	private static var zoomTween:FlxTween;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = Note.keysShit.get(mania).get('singAnims');

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	public var songLength:Float = 0;

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
	// Optimized input tracking
	private static var keysPressedSet:Map<Int, Bool> = new Map();
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Script existence flags for performance
	private var hasLuaScripts:Bool = false;
	private var hasHScripts:Bool = false;

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
	public var lyrics:FlxText;
	public var rainIntensity:Float = 0;
	public var skipTxt:FlxText;
	public var curHealthMode:String = "Mixtape";
	var allowSkip:Bool = false;
	var lastUpdateTime:Float = 0.0;
	var endingTimeLimit:Int = 20;
	var metadata:MetadataFile;
	var hasMetadataFile:Bool = false;
	var Text:Array<String> = [];
	var whiteBG:FlxSprite;
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipTo:Float;
	var blackOverlay:FlxSprite;
	var blackUnderlay:FlxSprite;
	var credText:Array<String> = [];
	var songTxt:FlxText;
	var artistTxt:FlxText;
	var charterTxt:FlxText;
	var modTxt:FlxText;
	var healthmoderandomizer:Array<Chance> = [
		{item: "OG", chance: 14.28},
		{item: "Mixtape", chance: 14.28},
		{item: "Kade", chance: 14.28},
		{item: "Tabi", chance: 14.28},
		{item: "Double", chance: 14.28},
		{item: "Lives", chance: 14.28},
		{item: "Lives + HealthBar", chance: 14.28},
		{item: "Amalgam", chance: 2.5}, /// ooo secret mode ooo
	];
	var rank:RankingManager;

	// Thank you mic'ed up engine, for making my life SO much easier lol
	public var hearts:FlxTypedGroup<FlxSprite>;
	public var lives:Int = 1;

	//THE MANAGERS
	public var comboManager:ComboManager;

	//FNF Weekly
	public var whosTurn:String = '';
	public var ghostsAllowed:Bool = ClientPrefs.data.doubleGhosts;
	public var dadGhostTween:FlxTween = null;
	public var bfGhostTween:FlxTween = null;
	public var dadGhost:FlxSprite = null;
	public var bfGhost:FlxSprite = null;
	var noteRows:Array<Array<Array<Note>>> = [[],[]];

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
	public var zoomEveryBeat:Int = 1;
	public var modManager:ModManager;
	public var notefields = new NotefieldRenderer();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes
	public var playerField:PlayField;
	public var dadField:PlayField;
	public var holdsGiveHP:Bool = false;
	public var playerScoreTxt:FlxText;
	public var opponentScoreTxt:FlxText;
	public var currentSV:SpeedEvent = {position: 0, startTime: 0, speed: 1 #if EASED_SVs , startSpeed: 1 #end};
	var speedChanges:Array<SpeedEvent> = [];
	var aiText:String;

	public var camGamefilters:Array<BitmapFilter> = [];
	public var camHUDfilters:Array<BitmapFilter> = [];
	public var camVisualfilters:Array<BitmapFilter> = [];
	public var camOtherfilters:Array<BitmapFilter> = [];
	public var camDialoguefilters:Array<BitmapFilter> = [];
	public var delayOffset:Float = 0; // for the delay effect

	var ch = 2 / 1000;
	public var shaderUpdates:Array<Float->Void> = [];

	public var chartModifier:String = 'Normal';
	public var convertMania:Int = ClientPrefs.getGameplaySetting('convertMania', 3);

	// UNO mechanic instance for chart modifier
	var unoMechanic:UnoMechanic;

	// UNO color indicator sprite
	var unoColorIndicator:FlxSprite;
	var currentUnoColor:Int = 0xFFFF0000; // Default red

	// Gameplay Mechanics
	public var opponentmode:Bool = ClientPrefs.getGameplaySetting('opponentplay', false);
	public var bothMode:Bool = ClientPrefs.getGameplaySetting('bothMode', false);
	public var loopMode:Bool = ClientPrefs.getGameplaySetting('loopMode', false);
	public var loopModeChallenge:Bool = ClientPrefs.getGameplaySetting('loopModeC', false);
	public var loopPlayMult:Float = ClientPrefs.getGameplaySetting('loopPlayMult', 1.05);
	public var maniaMode:Bool = ClientPrefs.getGameplaySetting('maniaMode', false);
	public var RandomSpeedChange:Bool = ClientPrefs.getGameplaySetting('randomspeedchange', false);
	public var RandomSpeedChangeWild:Bool = false;
	public var gimmicksAllowed:Bool = false;
	public var mixupMode:Bool = false;

	// Archipelago / Streamer Vs. Chat stuff
	public var instVolumeMultiplier:Float = 1;
	public var instVolumeMultiplierHardMode:Float = 1;
	public var vocalVolumeMultiplier:Float = 1;
	public var vocalVolumeMultiplierHardMode:Float = 1;
	var inArchipelagoMode:Bool = false;

	//Various things from other engines
	var visual:AudioDisplay;
	var vocalvisual:AudioDisplay = null;
	var oppvisual:AudioDisplay = null;

	#if MECHANICS_MOD_ALLOWED
	// Mechanics Mod
	public static var mechanicsMod:MechanicsPlaystate;
	public var shapeGroup:FlxTypedGroup<Shape>;

	public static var moveStrumSections:Array<Null<Bool>> = [];
	public var mechanicInfo:Map<String, {description:String, value:Float}> = [];
	public var sleepFog:FlxSprite;
	public var dodgeFog:FlxSprite;
	public var dodgeText:FlxText;
	public var lastKill:Int = -1;
	public var barCursor:FlxSprite;
	public var mouseCursor:FlxSprite;
	var shapeTmr:FlxTimer;
	#end

	// Skydecay Engine (our good friends)
	public var noteManager:NoteManager;

	//JS Engine shenanigans
	public var renderedTxt:FlxText;

	static var threadPool:FixedThreadPool = null;
	static var mutex:Mutex;

	//P-Slice
	// StepMania UI
	var smScoreTxt:FlxText;
	var smAccuracyTxt:FlxText;
	var smRatingTxt:FlxText;
	var smScoreTween:FlxTween;
	var smDisplayedScore:Float = 0; // Score shown (animated)
	var isStepManiaChart:Bool = false;

	// StepMania Judgements
	var smJudgement:FlxSprite;
	var smJudgementTween:FlxTween;
	var judgementCounter:JudCounter;

	// TPS/NPS System
	var notesHitArray:Array<Date> = [];
	public var nps:Int = 0;
	public var maxNPS:Int = 0;
	var npsCheck:Int = 0;

	var lastJudName:String = "None";

	// End of Mixtape Engine's large amount of bull


	override public function create()
	{
		// Cache frequently used values for performance
		_cachedSongName = SONG?.song?.toLowerCase();

		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, LoadingState.getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		#else
		var threadCount:Int = 1;
		#end
		threadPool = new FixedThreadPool(threadCount);
		mutex = new Mutex();

		// if (SONG != null)
		// {
		// 	preloadFunction = generateSong;
		// }

		{
			if (ClientPrefs.data.healthMode == "Random") {
				curHealthMode = ChanceSelector.selectOption(healthmoderandomizer, false, true, true);
			} else curHealthMode = ClientPrefs.data.healthMode;

			if (curHealthMode == "Amalgam")
				Achievements.unlock("freaky_bar");

			setOnScripts("healthMode", curHealthMode);
			callOnScripts("onSetHealthMode", [curHealthMode]);

			if (archipelago.APEntryState.inArchipelagoMode) {
				if (archipelago.APPlayState.livecount > 1)
					curHealthMode = "Lives + Mixtape";
				else
					curHealthMode = "Mixtape";
			}
		}

		if (SONG == null) {
			var songLowercase:String = Paths.formatToSongPath('tutorial');
			var poop:String = Highscore.formatSong(songLowercase, storyDifficulty);
			Song.loadFromJson(poop, songLowercase);
		}
		inArchipelagoMode = archipelago.APEntryState.inArchipelagoMode;
		#if ARCHIPELAGO_ALLOWED
		if (inArchipelagoMode && !(this is archipelago.APPlayState) && !isLegacyLuaTest && !options.legacylua.LegacyLuaFreeplayState.inLegacyLuaMode)
		{
			FlxG.switchState(new archipelago.APPlayState());
		}
		#end
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearUnusedMemory();
		Language.reloadPhrases();
		nextReloadAll = false;

		#if MECHANICS_MOD_ALLOWED
		var fiveMechanicsAtMixtape:Int = 0;
		for (mechanic in MechanicManager.mechanics) {
			if (inArchipelagoMode && APInfo.fivenightsatmechanicsmod) {
				if (FlxG.random.bool(25)) {
					mechanic.points = FlxG.random.int(0, 30);
					fiveMechanicsAtMixtape++;
				}
				if (fiveMechanicsAtMixtape == 4) break; //We only want 5 mechanics max at one time
			} else if (inArchipelagoMode) {
				mechanic.points = 0; //Reset it so that no mechanics are active
			}
		}

		for (mechanic in MechanicManager.mechanics) {
			if (mechanic.points > 0) {
				mechanicsMod = new mechanics.MechanicsPlaystate();
				break;
			}
		}

		if (mechanicsMod != null) {
			mechanicsMod.luckMechanic();

			mechanicsMod.letterMechanicGroup = new FlxTypedGroup<FlxObject>();
			add(mechanicsMod.letterMechanicGroup);

			var cappedPoints:Float = MechanicManager.mechanics['shape_obst'].points;

			if (cappedPoints >= 1000)
				cappedPoints = 1000;

			if (cappedPoints > 0)
			{
				shapeGroup = new FlxTypedGroup<Shape>();
				shapeGroup.memberAdded.add(function(s:Shape) // now we dont gotta manually set the camera
				{
					s.cameras = [camOther];
				});
				add(shapeGroup);

				shapeTmr = new FlxTimer();

				var shapeChance:Array<Float> = [77.35, 44.15, 11.45];
				var shapeNames:Array<String> = ['square', 'triangle', 'pentagon'];
				var directionList:Array<FlxDirection> = [LEFT, DOWN, UP, RIGHT];

				var spawnShapes:FlxTimer->Void = function(tmr:Null<FlxTimer>)
				{
					for (i in 0...Math.floor(FlxG.random.float(FlxMath.remapToRange(cappedPoints, 1, 20, 2, 8),
						FlxMath.remapToRange(cappedPoints, 1, 20, 10, 30)) * FlxG.random.float(1, 4.5)))
					{
						if (FlxG.random.bool(FlxMath.remapToRange(cappedPoints, 0, 20, 30, 70)))
						{
							new FlxTimer().start(FlxG.random.float(0.5, 2), function(shapeTmr:FlxTimer)
							{
								var newShape:Shape = new Shape(directionList[FlxG.random.int(0, directionList.length - 1)],
									shapeNames[FlxG.random.weightedPick(shapeChance)]);
								newShape.scale.set(0.6, 0.6);
								newShape.updateHitbox();
								newShape.antialiasing = ClientPrefs.data.antialiasing;
								shapeGroup.add(newShape);
							});
						}
					}
					if (tmr != null)
						tmr.reset(FlxG.random.float(5, 20));
				};

				spawnShapes(null);

				shapeTmr.start(FlxG.random.float(5, 10), spawnShapes);

				new FlxTimer().start(5, function(tmr:FlxTimer)
				{
					shapeGroup.forEachDead(function(s:Shape)
					{
						s.destroy();
						shapeGroup.remove(s);
					});
				}, 0);
			}

			var sortedMechanics:Array<MechanicManager.MechanicData> = [];

			for (key => mechanic in MechanicManager.mechanics)
			{
				if (mechanic.points > 0)
					sortedMechanics.push(mechanic);
			}

			sortedMechanics.sort(function(_1, _2)
			{
				return FlxSort.byValues(FlxSort.ASCENDING, _1.ID, _2.ID);
			});

			for (mechanic in sortedMechanics)
			{
				if (mechanic.results != null)
					mechanicsResult[mechanic.ID] = {name: mechanic.name, value: 0, text: mechanic.results};
			}
		}
		#end

		startCallback = startCountdown;
		endCallback = endSong;

		modManager = new ModManager(this);
		setOnScripts("modManager", modManager);
		setOnScripts("newPlayField", newPlayfield);
		setOnScripts("initPlayfield", initPlayfield);

		switch(ClientPrefs.data.skipWhen) {
			case "Freeplay": allowSkip = !isStoryMode;
			case "Story": allowSkip = isStoryMode;
			case "Freeplay & Story": allowSkip = true;
			case "None": allowSkip = false;
		}

		// This is the part where I initialize everything
		instance = this;
		comboManager = new ComboManager();

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		if (keysArray == null)
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

		#if EASED_SVs
		resetSVDeltas();
		#end

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
		camCOD = new FlxCamera(); //For gameover COD
		camCredit.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camCOD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camCredit, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camCOD, false);

		if (ClientPrefs.data.startHidden)
			camHUD.alpha = 0;


		try
		{
			metadata = cast Json.parse(File.getContent(Paths.json(Paths.formatToSongPath(_cachedSongName) + '/meta')));
			trace(File.getContent(Paths.json(Paths.formatToSongPath(_cachedSongName) + '/meta')));
			trace(metadata);
			hasMetadataFile = true;
			trace("Found metadata for " + _cachedSongName);
		}
		catch (e)
		{
			try
			{
				trace("No metadata for " + _cachedSongName);
			}
			catch (e)
			{
				trace("No metadata found. No song either apparently.");
			}
		}
		persistentUpdate = true;
		persistentDraw = true;

		convertMania = ClientPrefs.getGameplaySetting('convertMania', 3);

		if (mania > Note.maxMania)
			mania = Note.defaultMania;
		else if (chartModifier == "4K Only")
			mania = 3;
		else if (chartModifier == "ManiaConverter")
			mania = convertMania;
		else if (SONG.mania != null)
			if (SONG.mania >= 3) //Make sure it's even there
				mania = SONG.mania;
			else {
				mania = switch (SONG.mania) { //Convert it to make sure the older versions still work
					case 0: 3;
					case 1: 4;
					default: SONG.mania;
				}
			}
		else mania = 3;

		trace("Mania set: " + mania);

		noteManager = new NoteManager();

		// Initialize experimental NotePool system if enabled
		if (ClientPrefs.data.useExperimentalNotePool) {
			NotePoolManager.updatePoolSettings();
			NotePoolManager.resetDemandTracking(); // Reset for new song
			trace("Experimental NotePool system enabled");
		}

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

		comboOffsetCustom = null;
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		// Detect if it is a StepMania song and use stage NotITG
		//TODO: make it actually do that lol
		//isStepManiaLevel()
		if (maniaMode) {
			SONG.stage = 'notitg';
		}

		curStage = SONG.stage;

		// Flag for NotITG stages (StepMania) where we hide HUD and characters
		var isNotITG:Bool = (curStage == 'notitg');

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;
		defaultStageZoom = defaultCamZoom;
		if (defaultCamHudZoom == 0) defaultCamHudZoom = 1;

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

		if (isPixelStage) introSoundsSuffix = '-pixel';

		var zoomOut = 1 / defaultCamZoom;
		var screenWidth = Std.int(FlxG.width * zoomOut * 2);
		var screenHeight = Std.int(FlxG.height * zoomOut * 2);

		whiteBG = new FlxSprite(-480, -480);
		whiteBG.makeGraphic(screenWidth, screenHeight, FlxColor.WHITE);
		whiteBG.updateHitbox();
		whiteBG.antialiasing = true;
		whiteBG.scrollFactor.set(0, 0);
		whiteBG.active = false;
		whiteBG.alpha = 0.0;
		blackOverlay = new FlxSprite(0, 0);
		blackOverlay.makeGraphic(screenWidth, screenHeight, FlxColor.BLACK);
		blackOverlay.updateHitbox();
		blackOverlay.screenCenter();
		blackOverlay.antialiasing = true;
		blackOverlay.scrollFactor.set(0, 0);
		blackOverlay.alpha = 0;
		blackUnderlay = new FlxSprite(0, 0);
		blackUnderlay.makeGraphic(screenWidth, screenHeight, FlxColor.BLACK);
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

		try {
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
			#end
		} catch (e:Dynamic) {
			trace("Lua debug group had a stroke and dieded");
		}

		if (!isNotITG) {
			if (!stageData.hide_girlfriend)
			{
				if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
				gf = new Character(0, 0, SONG.gfVersion, false, GF);
				startCharacterPos(gf);
				gfGroup.scrollFactor.set(0.95, 0.95);
				gfGroup.add(gf);
			}

			dad = new Character(0, 0, SONG.player2, false, DAD);
			startCharacterPos(dad, true);
			dadGroup.add(dad);

			if (SONG.player4.isNotEmpty())
			{
				dad2 = new Character(0, 0, SONG.player4, false, DAD);
				startCharacterPos(dad2, true);
				dadGroup2.add(dad2);
				//threeLanes = true; later
			}
			else dad2 = null;

			boyfriend = new Character(0, 0, SONG.player1, true, BF);
			startCharacterPos(boyfriend);
			boyfriendGroup.add(boyfriend);

			if (SONG.player5.isNotEmpty())
			{
				bf2 = new Character(0, 0, SONG.player5, true, BF);
				startCharacterPos(bf2, true);
				boyfriendGroup2.add(bf2);
			}
			else bf2 = null;

			dadGhost = new FlxSprite();
			dadGhost.visible = false;
			dadGhost.antialiasing = true;
			dadGhost.alpha = 0.6;
			dadGhost.scale.copyFrom(dad.scale);
			dadGhost.updateHitbox();
			setOnScripts('dadGhost', dadGroup);

			bfGhost = new FlxSprite();
			bfGhost.visible = false;
			bfGhost.antialiasing = true;
			bfGhost.alpha = 0.6;
			bfGhost.scale.copyFrom(boyfriend.scale);
			bfGhost.updateHitbox();
			setOnScripts('bfGhost', bfGhost);
		} else {
			// In NotITG we will not show characters: create instances but hide them to avoid NPEs
			// We use the default versions of character names if they are missing
			var p1 = (SONG.player1 == null || SONG.player1.length == 0) ? 'bf' : SONG.player1;
			var p2 = (SONG.player2 == null || SONG.player2.length == 0) ? 'dad' : SONG.player2;
			var p4 = (SONG.player4 == null || SONG.player4.length == 0) ? 'dad' : SONG.player4;
			var p5 = (SONG.player5 == null || SONG.player5.length == 0) ? 'bf' : SONG.player5;
			var gfver = (SONG.gfVersion == null || SONG.gfVersion.length == 0) ? 'gf' : SONG.gfVersion;

			gf = new Character(0, 0, gfver);
			startCharacterPos(gf);
			gf.visible = false;
			// Do not add to the group to keep the stage clean

			dad = new Character(0, 0, p2, false, DAD);
			startCharacterPos(dad, true);
			dad.visible = false;

			boyfriend = new Character(0, 0, p1, true);
			startCharacterPos(boyfriend);
			boyfriend.visible = false;

			dad2 = new Character(0, 0, p4, false, DAD);
			startCharacterPos(dad2, true);
			dad2.visible = false;

			bf2 = new Character(0, 0, p5, true, BF);
			startCharacterPos(bf2, true);
			bf2.visible = false;
		}

		if (callOnScripts("onAddSpriteGroups", []) != LuaUtils.Function_Stop) {
			if(stageData.objects != null && stageData.objects.length > 0)
			{
				var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, dadGroup2, boyfriendGroup2, this);
				for (key => spr in list)
					if(!StageData.reservedNames.contains(key))
						variables.set(key, spr);
			}
			else
			{
				VSliceLoader.addstage(curStage);
				// Only add groups if not NotITG (keep empty stage for StepMania)
				if (!isNotITG) {
					add(gfGroup);
					add(dadGroup2);
					add(dadGroup);
					add(boyfriendGroup2);
					add(boyfriendGroup);
				}
			}
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					(shouldUseLegacyLua() ? new LegacyFunkinLua(folder + file) : new FunkinLua(folder + file));
				#end

				#if HSCRIPT_ALLOWED
				for (ext in Paths.HSCRIPT_EXTENSIONS)
					if(file.toLowerCase().endsWith('.$ext'))
						initHScript(folder + file);
				#end
			}
		#end

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
		hearts = new FlxTypedGroup<FlxSprite>();
		add(comboGroup);
		add(uiGroup);
		add(hearts);
		add(noteGroup);

		// Counter
		judgementCounter = new JudCounter(10, (FlxG.height / 2) - 100);
		judgementCounter.setCameras([camHUD]);
		add(judgementCounter);

		// Cache group indices for performance
		updateGroupIndices();

		if (curHealthMode == "Lives" || curHealthMode == "Lives + HealthBar" || curHealthMode == "Lives + Mixtape" || curHealthMode == "Amalgam")
			hearts.visible = true;
		else
			hearts.visible = false;

		comboGroup.cameras = [if (ClientPrefs.data.inGameRatings) camGame else camHUD];

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

		//trace("Making New Playfields!");
		modManager.playerAmount = 2;
		for (i in 0...modManager.playerAmount)
			newPlayfield();

		//trace("Making PlayerField!");
		playerField = playfields.members[0];
		if (playerField != null) {
			playerField.noteField.isEditor = false;
			playerField.isPlayer = !opponentmode && !playAsGF || bothMode;
			playerField.autoPlayed = !playerField.isPlayer || opponentmode || cpuControlled || playAsGF;
			playerField.noteHitCallback = goodNoteHit;
		}

		//trace("Making DadField!");
		dadField = playfields.members[1];
		if (dadField != null) {
			dadField.noteField.isEditor = false;
			dadField.isPlayer = opponentmode && !playAsGF || bothMode;
			dadField.autoPlayed = !dadField.isPlayer || (!opponentmode || (opponentmode && cpuControlled) || playAsGF) || (bothMode && cpuControlled);
			dadField.AIPlayer = AIMode;
			dadField.noteHitCallback = opponentNoteHit;
		}

		PlayField.initExtras();

		#if ALLOW_DEPRECATION
		callOnScripts("postPlayfieldCreation"); // backwards compat
		#end
		callOnScripts("onPlayfieldCreationPost");

		//trace("Adding Playfields!");
		add(playfields);
		add(notefields);
		add(PlayField.extraStuff);
		//trace("Playfields Created!");
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

		if (curHealthMode == 'Lives' || curHealthMode == "Amalgam") lives = 10;
		else if (curHealthMode == 'Lives + HealthBar') lives = 3;
		else if (curHealthMode == 'Lives + Mixtape') lives = 1+archipelago.APPlayState.livecount;

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud && !isNotITG; // Hide life bar in NotITG levels (StepMania)
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		if (curHealthMode == "Double" || curHealthMode == "Amalgam") healthBar.bg.visible = false;
		if (!isNotITG) uiGroup.add(healthBar);
		healthBar.visible = (curHealthMode != "Lives");

		if (curHealthMode == "Double" || curHealthMode == "Amalgam") {
			healthBarOverflow = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 2, 4);
			healthBarOverflow.screenCenter(X);
			healthBarOverflow.leftToRight = false;
			healthBarOverflow.scrollFactor.set();
			healthBarOverflow.visible = !ClientPrefs.data.hideHud && !isNotITG;
			healthBarOverflow.alpha = ClientPrefs.data.healthBarAlpha;
			healthBarOverflow.leftBar.visible = false;
			if (!isNotITG) uiGroup.add(healthBarOverflow);
		}
		reloadHealthBarColors();

		barCursor = new FlxSprite(healthBar.x + 4, healthBar.y + 4).makeGraphic(Std.int(healthBar.width - 8), Std.int(healthBar.height - 8), FlxColor.LIME);
		barCursor.scrollFactor.set();
		barCursor.alpha = 0;
		uiGroup.add(barCursor);

		if (opponentmode) healthBar.leftToRight = true;

		// Create UNO color indicator if using UNO chart modifier
		if (chartModifier == "UNO") {
			createUnoColorIndicator();
		}

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud && !isNotITG; // Hide icons in NotITG
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		iconP1.visible = (curHealthMode != "Lives");

		if (bf2 != null)
		{
			iconP12 = new HealthIcon(bf2.healthIcon, true);
			iconP12.y = healthBar.y - 115;
			iconP12.alpha = ClientPrefs.data.healthBarAlpha;
			iconP12.visible = !ClientPrefs.data.hideHud && !isNotITG;
			if (!isNotITG) uiGroup.add(iconP12);
			iconP12.visible = (curHealthMode != "Lives");
		}
		else iconP12 = null;

		if (!isNotITG) uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud && !isNotITG;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		iconP2.visible = (curHealthMode != "Lives");

		if (dad2 != null)
		{
			iconP22 = new HealthIcon(dad2.healthIcon, false);
			iconP22.y = healthBar.y - 115;
			iconP2.visible = !ClientPrefs.data.hideHud && !isNotITG;
			iconP22.alpha = ClientPrefs.data.healthBarAlpha;
			if (!isNotITG) uiGroup.add(iconP22);
			iconP22.visible = (curHealthMode != "Lives");
		} else iconP22 = null;

		if (!isNotITG) uiGroup.add(iconP2);

		healthBarBlock = new FlxSprite(-16, 0).makeGraphic(10, 20, FlxColor.RED);
		healthBarBlock.y = healthBar.bg.getGraphicMidpoint().y - (healthBarBlock.height / 2);
		healthBarBlock.scrollFactor.set();
		healthBarBlock.visible = !ClientPrefs.data.hideHud && !isNotITG;
		healthBarBlock.alpha = MechanicManager.mechanics['limit_health'].points > 0 ? 1 : 0;
		if (!isNotITG) uiGroup.add(healthBarBlock);

		minBarBlock = new FlxSprite(-16, 0).makeGraphic(10, 20, FlxColor.BLUE);
		minBarBlock.y = healthBar.bg.getGraphicMidpoint().y - (minBarBlock.height / 2);
		minBarBlock.scrollFactor.set();
		minBarBlock.visible = !ClientPrefs.data.hideHud && !isNotITG;
		minBarBlock.alpha = MechanicManager.mechanics['minimum_hp'].points > 0 ? 1 : 0;
		if (!isNotITG) uiGroup.add(minBarBlock);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		// Detect if it is a StepMania chart or if it uses the notitg stage
		isStepManiaChart =  ((curStage == 'notitg') || maniaMode); //(customAudioPath != null && (customAudioPath.contains('/sm/') || customAudioPath.contains('sm/'))) || (curStage == 'notitg'); // Create StepMania UI if necessary
		if (isStepManiaChart) {
		// Disguise normal scoreTxt
			scoreTxt.visible = false;			// Calculate centered vertical position
			var centerY:Float = FlxG.height / 2;

			// Large score in the middle right (centered vertically)
			smScoreTxt = new FlxText(FlxG.width - 320, centerY - 60, 300, "00000000", 48);
			smScoreTxt.setFormat(Paths.font("aller.ttf"), 48, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			smScoreTxt.scrollFactor.set();
			smScoreTxt.borderSize = 2;
			smScoreTxt.visible = !ClientPrefs.data.hideHud;
			uiGroup.add(smScoreTxt);

			// Accuracy below the score
			smAccuracyTxt = new FlxText(FlxG.width - 320, centerY, 300, "0.00%", 28);
			smAccuracyTxt.setFormat(Paths.font("aller.ttf"), 28, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			smAccuracyTxt.scrollFactor.set();
			smAccuracyTxt.borderSize = 1.5;
			smAccuracyTxt.visible = !ClientPrefs.data.hideHud;
			uiGroup.add(smAccuracyTxt);

			// Rating name below accuracy
			smRatingTxt = new FlxText(FlxG.width - 320, centerY + 35, 300, "?", 24);
			smRatingTxt.setFormat(Paths.font("aller.ttf"), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			smRatingTxt.scrollFactor.set();
			smRatingTxt.borderSize = 1.5;
			smRatingTxt.visible = !ClientPrefs.data.hideHud;
			uiGroup.add(smRatingTxt);

			// Create judgment sprite (initially invisible)
			smJudgement = new FlxSprite();
			smJudgement.cameras = [camHUD];
			smJudgement.visible = false;
			smJudgement.alpha = 0;
			add(smJudgement);
		}

		// Modchart Debug Info Text (top-right corner)
		modchartDebugTxt = new FlxText(FlxG.width - 300, 10, 290, "", 16);
		modchartDebugTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modchartDebugTxt.scrollFactor.set();
		modchartDebugTxt.borderSize = 1.25;
		modchartDebugTxt.visible = ClientPrefs.data.modchartDebugInfo && !ClientPrefs.data.hideHud;
		uiGroup.add(modchartDebugTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = (cpuControlled || practiceMode || instakillOnMiss || opponentmode || bothMode || playAsGF);
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		if (cpuControlled)
			botplayTxt.text = Language.getPhrase("Botplay").toUpperCase();
		else if (practiceMode)
			botplayTxt.text = "PRACTICE MODE";
		else if (instakillOnMiss)
			botplayTxt.text = "NO-MISS MODE";
		else if (opponentmode)
			botplayTxt.text = "OPPONENT MODE";
		else if (bothMode)
			botplayTxt.text = "BOTH MODE";
		else if (playAsGF) //Unused lmao
			botplayTxt.text = "GF MODE";

		// Legacy Lua Testing Mode text
		legacyLuaTestTxt = new FlxText(400, healthBar.y - 130, FlxG.width - 800, "LEGACY LUA TESTING MODE", 28);
		legacyLuaTestTxt.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.CYAN, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		legacyLuaTestTxt.scrollFactor.set();
		legacyLuaTestTxt.borderSize = 1.25;
		legacyLuaTestTxt.visible = isLegacyLuaTest;
		uiGroup.add(legacyLuaTestTxt);
		if(ClientPrefs.data.downScroll)
			legacyLuaTestTxt.y = healthBar.y + 110;

		renderedTxt = new FlxText(0, healthBar.y - 50, FlxG.width, "", 32);
		renderedTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		renderedTxt.scrollFactor.set();
		renderedTxt.borderSize = 1.25;
		renderedTxt.cameras = [camHUD];
		renderedTxt.visible = ClientPrefs.data.showRenderText && !ClientPrefs.data.hideHud;

		if (ClientPrefs.data.downScroll) renderedTxt.y = healthBar.y + 50;
		if (ClientPrefs.data.showRenderText) uiGroup.add(renderedTxt);

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
				introStageBar = new FlxSprite(daText[i].x, if (i == 2) daText[i].y else daText[i].y - 25);
				introStageBar.loadGraphic('invisabar');
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
		hearts.cameras = [camHUD];
		noteGroup.cameras = [camHUD];

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
					(shouldUseLegacyLua() ? new LegacyFunkinLua(folder + file) : new FunkinLua(folder + file));
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

		// Register dynamic song scripting functions after all scripts are loaded
		//registerDynamicSongScripting();

		startCallback();
		comboManager.RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		for (array in keysArray[mania])
		{
			var daArray:Array<Int> = array;
			for (checkKey in daArray)
			{
				// no im not givin you all duplicate inputs, cuz you suck
				if (checkKey == -4)
				{
					FlxG.stage.addEventListener(MouseEvent.CLICK, leftMousePress);
					FlxG.stage.addEventListener(MouseEvent.MOUSE_UP, leftMouseRelease);
				}
				else if (checkKey == -5)
				{
					FlxG.stage.addEventListener(untyped MouseEvent.RIGHT_CLICK, rightMousePress);
					FlxG.stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, rightMouseRelease);
				}
			}
		}

		if (ClientPrefs.data.showRenderText)
			renderedTxt.text = 'Rendered Notes: ' + notes.length;

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if(!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music('pauseMusic/${PauseSubState.songName}');
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}'));

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

		raveLight = new FlxSprite(0, 0);
		raveLight.makeGraphic(screenWidth, screenHeight, FlxColor.BLACK);
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

		for (i in 1...lives)
		{
			var heartSprite:FlxSprite = new FlxSprite(healthBar.width + 5 + (40 * i), 20);
			heartSprite.frames = Paths.getSparrowAtlas('mechanics/general/heartUI');
			heartSprite.antialiasing = false;
			heartSprite.updateHitbox();
			heartSprite.y = healthBar.y + healthBar.height + 10;
			heartSprite.scrollFactor.set();
			heartSprite.animation.addByPrefix('Idle', "Hearts", 24, true);
			heartSprite.ID = i;
			if (ClientPrefs.data.downScroll)
				heartSprite.y = healthBar.y - heartSprite.height - 10;
			heartSprite.animation.play('Idle');
			hearts.add(heartSprite);
		}

		cacheCountdown();
		cachePopUpScore();

		if(eventNotes.length < 1) checkEventNote();

		switch(curHealthMode) {
			case "Kade":
				pressMissDamage = 0.20; //nah that's cruel
			case "Amalgam":
				pressMissDamage = 0.25; //but I can do worse >:)
			default:
				pressMissDamage = 0.05;
		}

		raveLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		if (!inArchipelagoMode)
		{
			switch (curHealthMode) {
				case "Tabi" | "Double":
					MaxHP = 4;
				case "Amalgam":
					MaxHP = 8;
				default:
					MaxHP = 2;
			}
		}
		initY = healthBar.y;

		rank = new RankingManager('small');
		rank.updateHitbox();
		rank.screenCenter(XY);
		rank.y = 640 - rank.height;
		rank.x = FlxG.width/2 - 590;

		// Apply downscroll positioning for RankingManager
		if (ClientPrefs.data.downScroll) {
			rank.y = 50; // Move to top for downscroll
		}

		uiGroup.add(rank);

		if (mechanicsMod != null) {

			if (MechanicManager.mechanics['limit_health'].points > 0)
			{
				var formerMaxHealth = cast(MaxHP, Float);

				maxHealthOffset = FlxG.random.float(0, FlxMath.remapToRange(MechanicManager.mechanics['limit_health'].points, 0, 20, 0, formerMaxHealth / 2));

				if (maxHealthOffset > 1.9)
					maxHealthOffset = 1.9;
				healthBarBlock.x = healthBar.x + FlxMath.remapToRange(maxHealthOffset, 0, formerMaxHealth, 0, healthBar.width);

				var time:Float = 15;
				var changeTime:Void->Void = function()
				{
					time = 15;
					var chanceBool:Bool = false;
					var chance:Float = FlxMath.remapToRange(MechanicManager.mechanics['limit_health'].points, 1, 20, 90, 10);
					var chanceDecre:Float = cast(chance, Float);

					while (!chanceBool && time >= 3)
					{
						chanceBool = FlxG.random.bool(100 - chance);
						if (chanceBool)
							time -= FlxG.random.float(0.5, 1.5);
						else
						{
							time -= FlxG.random.float(0.5, 1.5);
							chance += chanceDecre / FlxG.random.float(5, 15);
						}
					}
				}

				new FlxTimer().start(20 - time, function(tmr:FlxTimer)
				{
					changeTime();

					maxHealthOffset = FlxG.random.float(0, FlxMath.remapToRange(MechanicManager.mechanics['limit_health'].points, 0, 20, 0, formerMaxHealth / 2));
				}, 0);
			}

			if (MechanicManager.mechanics['minimum_hp'].points > 0)
			{
				var firstNoteTime:Float = 0;

				var idx:Int = 0;
				while (unspawnNotes[idx].noteType != null && !unspawnNotes[idx].mustPress)
				{
					idx++;
				}

				firstNoteTime = unspawnNotes[idx].strumTime;
				new FlxTimer().start((firstNoteTime / 1000) + 7.5, function(tmr:FlxTimer)
				{
					var formerMaxHealth = cast(MaxHP, Float);

					minHealthOffset = FlxG.random.float(0, FlxMath.remapToRange(MechanicManager.mechanics['minimum_hp'].points, 0, 20, 0, formerMaxHealth / 4));

					if (minHealthOffset > 0.9)
						minHealthOffset = 0.9;
					minBarBlock.x = (healthBar.x + healthBar.width) - ((minHealthOffset * healthBar.width) / 2);

					var time:Float = 15;
					var changeTime:Void->Void = function()
					{
						time = 15;
						var chanceBool:Bool = false;
						var chance:Float = FlxMath.remapToRange(MechanicManager.mechanics['minimum_hp'].points, 1, 20, 90, 10);
						var chanceDecre:Float = cast(chance, Float);

						while (!chanceBool && time >= 3)
						{
							chanceBool = FlxG.random.bool(100 - chance);
							if (chanceBool)
								time -= FlxG.random.float(0.5, 1.5);
							else
							{
								time -= FlxG.random.float(0.5, 1.5);
								chance += chanceDecre / FlxG.random.float(5, 15);
							}
						}
					}

					new FlxTimer().start(20 - time, function(tmr:FlxTimer)
					{
						changeTime();

						minHealthOffset = FlxG.random.float(0,
							FlxMath.remapToRange(MechanicManager.mechanics['minimum_hp'].points, 0, 20, 0, formerMaxHealth / 4));
						minHealthOffset /= 3;
					}, 0);
				});
			}

			sleepFog = new FlxSprite().loadGraphic(Paths.image((stageUI == "pixel" ? "pixelUI/" : "mechanics/mechanicsmod/effects/") + "sleepyFog"));
			sleepFog.scrollFactor.set();
			sleepFog.antialiasing = ClientPrefs.data.antialiasing;
			sleepFog.alpha = 0;
			// sleepFog.blend = ADD;
			uiGroup.add(sleepFog);

			dodgeFog = new FlxSprite().loadGraphic(Paths.image('mechanics/mechanicsmod/effects/dodgeVignette'));
			dodgeFog.scrollFactor.set();
			dodgeFog.antialiasing = ClientPrefs.data.antialiasing;
			dodgeFog.alpha = 0;
			uiGroup.add(dodgeFog);

			dodgeText = new FlxText(0, 0, FlxG.width * 0.9, "", 24);
			dodgeText.text = 'Press ${ClientPrefs.keyBinds['dodge'][0].toString()}${(ClientPrefs.keyBinds['dodge'][1] != NONE ? "or" + ClientPrefs.keyBinds['dodge'][1].toString() : "")} to dodge!';
			dodgeText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
			dodgeText.borderSize = 2.5;
			dodgeText.antialiasing = ClientPrefs.data.antialiasing;
			dodgeText.screenCenter(X);
			dodgeText.y = FlxG.height * 0.8;
			dodgeText.alpha = 0;
			uiGroup.add(dodgeText);

			/*if (MechanicManager.mechanics['tictactoe'].points > 0)
			{
					ticTacToeSpr = new TicTacToe(FlxG.width * 0.05, FlxG.height * 0.6);
					ticTacToeSpr.cameras = [camOther];
					add(ticTacToeSpr);
			}*/

			var mouseList:Array<String> = ['mouse_follower', 'click_time'];

			for (listed in mouseList)
			{
				if (MechanicManager.mechanics[listed].points > 0)
				{
					mouseCursor = new FlxSprite().loadGraphic(Paths.image('cursor/cursor-default'));
					mouseCursor.scrollFactor.set();
					mouseCursor.antialiasing = ClientPrefs.data.antialiasing;
					mouseCursor.alpha = 0;
					mouseCursor.cameras = [camOther];
					FlxG.mouse.visible = false;
					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						FlxTween.tween(mouseCursor, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
						uiGroup.add(mouseCursor);
					});
					break;
				}
			}
		}

		// trace size with verbose settings.
		// trace(this.realSizeOf());
	}

	public var mechanicsResult:Array<MechanicResults> = [];

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
		if (!ClientPrefs.data.disableDebugTraces) {
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
	}
	#end

	/**
	 * Determines whether Legacy Lua should be used based on settings for current song/mod
	 * Priority: Song Setting > Mod Setting > Player Choice
	 */
	private function shouldUseLegacyLua():Bool {
		var currentSong = SONG.song;
		var currentMod = (backend.WeekData.getCurrentWeek() != null ? backend.WeekData.getCurrentWeek().folder : '');

		var settingsManager = options.legacylua.LegacyLuaSettingsManager.getInstance();
		return settingsManager.shouldUseLegacyLua(currentSong, currentMod);
	}

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		if (curHealthMode == "Double" || curHealthMode == "Amalgam")
			healthBarOverflow.setColors(FlxColor.TRANSPARENT, FlxColor.fromRGB(0, 255, 0));

			//for later
		var dCol = if (dad2 != null) FlxColor.fromRGB(dad2.healthColorArray[0], dad2.healthColorArray[1],
			dad2.healthColorArray[2]) else FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var bCol = if (bf2 != null) FlxColor.fromRGB(bf2.healthColorArray[0], bf2.healthColorArray[1],
			bf2.healthColorArray[2]) else FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);

	}

	public function createUnoColorIndicator() {
		// Create a circular sprite to show the current UNO color
		unoColorIndicator = new FlxSprite();
		unoColorIndicator.makeGraphic(50, 50, currentUnoColor);

		// Position it to the right of the health bar
		unoColorIndicator.x = healthBar.x + healthBar.width + 20;
		unoColorIndicator.y = healthBar.y + (healthBar.height - unoColorIndicator.height) / 2;

		unoColorIndicator.scrollFactor.set();
		unoColorIndicator.visible = !ClientPrefs.data.hideHud;
		unoColorIndicator.alpha = ClientPrefs.data.healthBarAlpha;

		// Make it circular by drawing a circle
		makeCircularSprite(unoColorIndicator, 25);

		uiGroup.add(unoColorIndicator);
	}

	private function makeCircularSprite(sprite:FlxSprite, radius:Int):Void {
		sprite.makeGraphic(radius * 2, radius * 2, 0x00000000); // Transparent background

		var graphics = sprite.pixels;
		if (graphics != null) {
			graphics.lock();

			var centerX = radius;
			var centerY = radius;

			// Draw filled circle
			for (x in 0...(radius * 2)) {
				for (y in 0...(radius * 2)) {
					var dx = x - centerX;
					var dy = y - centerY;
					var distance = Math.sqrt(dx * dx + dy * dy);

					if (distance <= radius) {
						graphics.setPixel32(x, y, currentUnoColor);
					}
				}
			}

			graphics.unlock();
		}
	}

	public function updateUnoColorIndicator(newColor:Int):Void {
		if (unoColorIndicator != null) {
			currentUnoColor = newColor;
			makeCircularSprite(unoColorIndicator, 25);
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true, BF);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter, false, DAD);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter, false, DAD);
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
					var newDad2:Character = new Character(0, 0, newCharacter, false, DAD);
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
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true, BF);
					boyfriendMap2.set(newCharacter, newBoyfriend);
					boyfriendGroup2.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
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
				(shouldUseLegacyLua() ? new LegacyFunkinLua(luaFile) : new FunkinLua(luaFile));

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
						if (FlxG.camera != null) FlxG.camera.snapToTarget();
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

	// SyncedVideoSprite Management System
	public var syncedVideos:Array<SyncedVideoSprite> = [];
	public var queuedSyncedVideos:Array<{video: SyncedVideoSprite, startTime: Float}> = [];

	public function makeSyncedVideoSprite(name:String, ?x:Float = 0, ?y:Float = 0, ?syncOffset:Float = 0, ?canSkip:Bool = false, ?shouldLoop:Bool = false, ?addBehind:String = 'none'):SyncedVideoSprite
	{
		#if VIDEOS_ALLOWED
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
			var syncedVideo = new SyncedVideoSprite(fileName, false, canSkip, shouldLoop, syncOffset, true);
			syncedVideo.x = x;
			syncedVideo.y = y;

			syncedVideos.push(syncedVideo);

			if (GameOverSubstate.instance != null && isDead)
				GameOverSubstate.instance.add(syncedVideo);
			else {
				switch(addBehind.toLowerCase()){
					case "bf" | "boyfriend": addBehindBF(syncedVideo);
					case "gf" | "girlfriend": addBehindGF(syncedVideo);
					case "dad" | "opponent": addBehindDad(syncedVideo);
					case "hud": addBehindHUD(syncedVideo);
					default: add(syncedVideo);
				}
			}

			return syncedVideo;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Synced Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Synced Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		#end
		return null;
	}

	public function queueSyncedVideoSprite(name:String, startTime:Float, ?x:Float = 0, ?y:Float = 0, ?syncOffset:Float = 0, ?canSkip:Bool = false, ?shouldLoop:Bool = false, ?addBehind:String = 'none'):SyncedVideoSprite
	{
		#if VIDEOS_ALLOWED
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
			var syncedVideo = new SyncedVideoSprite(fileName, false, canSkip, shouldLoop, syncOffset, false);
			syncedVideo.x = x;
			syncedVideo.y = y;
			syncedVideo.queueStart(startTime);

			syncedVideos.push(syncedVideo);
			queuedSyncedVideos.push({video: syncedVideo, startTime: startTime});

			if (GameOverSubstate.instance != null && isDead)
				GameOverSubstate.instance.add(syncedVideo);
			else {
				switch(addBehind.toLowerCase()){
					case "bf" | "boyfriend": addBehindBF(syncedVideo);
					case "gf" | "girlfriend": addBehindGF(syncedVideo);
					case "dad" | "opponent": addBehindDad(syncedVideo);
					case "hud": addBehindHUD(syncedVideo);
					default: add(syncedVideo);
				}
			}

			return syncedVideo;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Queued Synced Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Queued Synced Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		#end
		return null;
	}

	private function updateSyncedVideos():Void
	{
		// Clean up destroyed videos
		syncedVideos = syncedVideos.filter(function(video:SyncedVideoSprite) {
			return video != null && video.exists;
		});

		queuedSyncedVideos = queuedSyncedVideos.filter(function(item) {
			return item.video != null && item.video.exists;
		});
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

			//trace("Starting Countdown!");
			canPause = true;

			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;

			try {generateStrums();}catch(e){trace("Strums are NULL!");}

			#if ALLOW_DEPRECATION
			callOnScripts('preModifierRegister'); // deprecated
			#end

			if (callOnScripts('onModifierRegister') != LuaUtils.Function_Stop) {
				modManager.registerDefaultModifiers();

				if (ClientPrefs.data.middleScroll || isStepManiaChart) {
					var off:Float = Math.min(FlxG.width, 1280) / Note.ammo[mania];
					var opp:Int = opponentmode ? 0 : 1;

					var halfKeys:Int = Math.floor(Note.ammo[mania] / 2);
					if (Note.ammo[mania] % 2 != 0) // middle receptor dissappears, if there is one
						modManager.setValue('alpha${halfKeys + 1}', 1.0, opp);

					for (i in 0...halfKeys)
						modManager.setValue('transform${i}X', -off, opp);
					for (i in Note.ammo[mania]-halfKeys...Note.ammo[mania])
						modManager.setValue('transform${i}X', off, opp);

					modManager.setValue("alpha", isStepManiaChart ? 1 : 0.6, opp);
					modManager.setValue("opponentSwap", 0.5);
				}
			}

			#if ARCHIPELAGO_ALLOWED
			if (inArchipelagoMode && APInfo.inHardMode && !APInfo.hasItem('Strums')) {
				StrumNote.hardAlpha = 0;
				Note.hardAlpha = 0;
			} else {
				StrumNote.hardAlpha = 1;
				Note.hardAlpha = 1;
			}
			#end

			#if ALLOW_DEPRECATION
			callOnScripts('postModifierRegister'); // deprecated
			#end
			callOnScripts('onModifierRegisterPost');

			for (i in 0...Note.ammo[mania]) {
				playerField.baseXPositions[i] = playerField.strumNotes[i].x;
				dadField.baseXPositions[i] = dadField.strumNotes[i].x;
				setOnScripts('defaultPlayerStrumX' + i, playerField.strumNotes[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerField.strumNotes[i].y);
				setOnScripts('defaultOpponentStrumX' + i, dadField.strumNotes[i].x);
				setOnScripts('defaultOpponentStrumY' + i, dadField.strumNotes[i].y);
			}

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

			//trace("Started Countdown!");

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
						introStageStuff.visible = true;
						FlxTween.tween(songTxt, {alpha: 1}, 1, {ease: FlxEase.circOut});
						FlxTween.tween(artistTxt, {alpha: 1}, 1, {ease: FlxEase.circOut});
						FlxTween.tween(charterTxt, {alpha: 1}, 1, {ease: FlxEase.circOut});
						FlxTween.tween(modTxt, {alpha: 1}, 1, {ease: FlxEase.circOut});
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
						if (ClientPrefs.data.startHidden)
							FlxTween.tween(camHUD, {alpha: 1}, 5, {ease: FlxEase.circOut});
						tick = GO;
					case 4:
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							FlxTween.tween(camCredit, {alpha: 0, y: 1000}, 1, {ease: FlxEase.circInOut});
						});
						rank.doTween('in');
						#if ARCHIPELAGO_ALLOWED
						if (archipelago.APPlayState.resisting)
							archipelago.APPlayState.instance?.startResisting();
						#end
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
		var spr:FlxSprite = new FlxSprite();
		spr.loadGraphic(image);
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(_noteGroupIndex, spr);
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

	// public override function add(obj:FlxBasic):FlxBasic
	// {
	// 	if (GameOverSubstate.instance != null && isDead)
	// 		return GameOverSubstate.instance.add(obj);
	// 	return super.add(obj);
	// }

	public function addBehind(obj:FlxBasic, behind:FlxBasic)
	{
		insert(members.indexOf(behind), obj);
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(_gfGroupIndex, obj);
	}

	public function addBehindBF(obj:FlxBasic)
	{
		insert(_boyfriendGroupIndex, obj);
	}

	public function addBehindDad(obj:FlxBasic)
	{
		insert(_dadGroupIndex, obj);
	}

	public function addBehindBF2(obj:FlxBasic)
	{
		insert(_boyfriendGroup2Index, obj);
	}

	public function addBehindDad2(obj:FlxBasic)
	{
		insert(_dadGroup2Index, obj);
	}

	public function addBehindHUD(obj:FlxBasic)
	{
		insert(_uiGroupIndex, obj);
	}

	public function addAbove(obj:FlxBasic, above:FlxBasic):FlxBasic
	{
		insert(members.indexOf(above) + 1, obj);
		return obj;
	}

	public function addAboveGF(obj:FlxBasic)
	{
		insert(_gfGroupIndex + 1, obj);
	}

	public function addAboveBF(obj:FlxBasic)
	{
		insert(_boyfriendGroupIndex + 1, obj);
	}

	public function addAboveDad(obj:FlxBasic)
	{
		insert(_dadGroupIndex + 1, obj);
	}

	public function addAboveBF2(obj:FlxBasic)
	{
		insert(_boyfriendGroup2Index + 1, obj);
	}

	public function addAboveDad2(obj:FlxBasic)
	{
		insert(_dadGroup2Index + 1, obj);
	}

	public function addNoteToField(note:Note, ?field:Int = 0)
	{
		if (field < 0 || field >= playfields.members.length)
			field = if (note.mustPress) 0 else 1;
		playfields.members[field].queue(note);
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
				for (field in playfields.members)
					field.removeNote(daNote);
			}
			--i;
		}
	}

	// I hate this
	var fullClearFormat = new FlxTextFormat(FlxColor.CYAN);
	var sFormat = new FlxTextFormat(FlxColor.MAGENTA);
	var aFormat = new FlxTextFormat(FlxColor.LIME);
	var bFormat = new FlxTextFormat(FlxColor.GREEN);
	var cFormat = new FlxTextFormat(FlxColor.YELLOW);
	var dFormat = new FlxTextFormat(FlxColor.ORANGE);
	var eFormat = new FlxTextFormat(FlxColor.RED);
	var fFormat = new FlxTextFormat(FlxColor.BLACK);

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

	function abbreviateScore(score:Int):String {
		if (score >= 1_000_000)
			return Std.string(Math.round(score / 10000) / 100) + "M";
		else if (score >= 10_000)
			return Std.string(Math.round(score / 10) / 100) + "K";
		else
			return Std.string(score);
	}

	public dynamic function updateScoreText()
	{
		// If it's a StepMania chart, update custom UI
		if (isStepManiaChart) {
			updateStepManiaUI();
			return;
		}

		var col:String = '';
		var str:String = Language.getPhrase('rating_${comboManager.ratingName}', comboManager.ratingName);
		if(comboManager.totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2);
			// TODO: Make this look nicer
			if (percent == 100)
				col = "~";
			else if (percent > 90)
				col = ";";
			else if (percent > 80)
				col = "@";
			else if (percent > 70)
				col = "#";
			else if (percent > 60)
				col = "$";
			else if (percent > 50)
				col = "*";
			else if (percent > 30)
				col = "^";
			else
				col = "&";

			str = '${Language.getPhrase('rating_${comboManager.ratingName}', comboManager.ratingName)} $col(${percent}%) $col - ${Language.getPhrase(comboManager.ratingFC)}';
			rank.updateRank();
		}

		if (health <= 0.0475 && (curHealthMode == "Mixtape" || curHealthMode == "Tabi" || curHealthMode == "Double" || curHealthMode == "Amalgam"))
		{
			scoreTxt.text = "DON'T MISS!";
			scoreTxt.borderColor = FlxColor.fromRGB(255, 0, 0);
		}
		else {
			var tempScore:String;
			if(!instakillOnMiss) {
				var missLabel:String = ClientPrefs.data.badShitBreakCombo ? Language.getPhrase('combo_breaks', 'Combo Breaks') : Language.getPhrase('misses', 'Misses');
				var missCount:Int = ClientPrefs.data.badShitBreakCombo ? comboManager.comboBreaks : comboManager.songMisses;
				tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [comboManager.songScore, comboManager.songMisses, str]);
			}
			else tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [comboManager.songScore, str]);
			var healthTxt:String = '100';
			var hlth = CoolUtil.floorDecimal((health / 2) * 100, 2);
			var col:String = '';
			if (hlth == 100)
				col = "~";
			else if (hlth > 90)
				col = ";";
			else if (hlth > 80)
				col = "@";
			else if (hlth > 70)
				col = "#";
			else if (hlth > 60)
				col = "$";
			else if (hlth > 50)
				col = "*";
			else if (hlth > 20)
				col = "^";
			else
				col = "&";
			healthTxt = '$hlth';
			scoreTxt.applyMarkup('$tempScore | Health: $col$healthTxt% $col' + (MaxHP != 2 ? ' / ${CoolUtil.floorDecimal((MaxHP / 2) * 100, 2)}%' : ''),
			[
				new FlxTextFormatMarkerPair(fullClearFormat, "~"),
				new FlxTextFormatMarkerPair(sFormat, ";"),
				new FlxTextFormatMarkerPair(aFormat, "@"),
				new FlxTextFormatMarkerPair(bFormat, "#"),
				new FlxTextFormatMarkerPair(cFormat, "$"),
				new FlxTextFormatMarkerPair(dFormat, "*"),
				new FlxTextFormatMarkerPair(eFormat, "^"),
				new FlxTextFormatMarkerPair(fFormat, "&")
			]);
			scoreTxt.borderColor = FlxColor.fromRGB(0, 0, 0);
		}
	}

	function updateStepManiaUI()
	{
		if (smScoreTxt == null || smAccuracyTxt == null || smRatingTxt == null)
			return;

		// Do not animate the score: show the current value immediately
		smDisplayedScore = comboManager.songScore;

		// Format score with 8 digits and leading zeros
		var scoreInt:Int = Math.floor(smDisplayedScore);
		var scoreStr:String = Std.string(scoreInt);
		while (scoreStr.length < 8) {
			scoreStr = '0' + scoreStr;
		}
		smScoreTxt.text = scoreStr;

		// Format accuracy with 2 decimal places
		var percent:Float = CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2);
		smAccuracyTxt.text = Std.string(percent) + '%';

		// Show the rating name
		smRatingTxt.text = comboManager.ratingName + ' [' + comboManager.ratingFC + ']';
	}

	function showStepManiaJudgement(ratingName:String)
	{
		if (smJudgement == null || ClientPrefs.data.hideHud)
			return;

		// Mapping FNF ratings to StepMania sprites
		var smSprite:String = switch(ratingName.toLowerCase()) {
			case 'marv': 'fantastic';
			case 'sick': 'excellent';
			case 'good': 'great';
			case 'bad': 'decent';
			case 'shit': 'way-off';
			default: ratingName.toLowerCase();
		}

		// Cancelar tween anterior si existe (esto hace que el anterior desaparezca inmediatamente)
		if (smJudgementTween != null) {
			smJudgementTween.cancel();
			smJudgementTween = null;
		}

		// Load judgment sprite
		smJudgement.loadGraphic(Paths.image('stepmania/' + smSprite));
		smJudgement.setGraphicSize(Std.int(smJudgement.width * 0.7));
		smJudgement.updateHitbox();

		// Center on screen
		smJudgement.screenCenter();

		// Make visible with full alpha and initial scale for bump
		smJudgement.visible = true;
		smJudgement.alpha = 1;
		smJudgement.scale.set(1.3, 1.3);

		// Bump animation: scale from 1.3 to 1.0
		smJudgementTween = FlxTween.tween(smJudgement.scale, {x: 1, y: 1}, 0.2, {
			ease: FlxEase.backOut
		});
	}

	public dynamic function updateModchartDebugText()
	{
		if (modchartDebugTxt == null) return;

		// Update visibility based on settings
		modchartDebugTxt.visible = ClientPrefs.data.modchartDebugInfo && !ClientPrefs.data.hideHud;

		if (!ClientPrefs.data.modchartDebugInfo) return;

		// Get strum positions for player and opponent
		var playerStrumInfo = "";
		var opponentStrumInfo = "";

		if (playfields.members[0] != null && playfields.members[0].strumNotes != null) {
			for (i in 0...playfields.members[0].strumNotes.length) {
				var strum = playfields.members[0].strumNotes[i];
				if (strum != null) {
					opponentStrumInfo += 'O${i}: ${Math.round(strum.x)},${Math.round(strum.y)}\n';
				}
			}
		}

		if (playfields.members[1] != null && playfields.members[1].strumNotes != null) {
			for (i in 0...playfields.members[1].strumNotes.length) {
				var strum = playfields.members[1].strumNotes[i];
				if (strum != null) {
					playerStrumInfo += 'P${i}: ${Math.round(strum.x)},${Math.round(strum.y)}\n';
				}
			}
		}

		var debugInfo = 'MODCHART DEBUG:\n';
		debugInfo += 'Time: ${Math.round(Conductor.songPosition)}ms\n';
		debugInfo += 'Step: ${curStep} (${CoolUtil.floorDecimal(curDecStep, 2)})\n';
		debugInfo += 'Beat: ${curBeat} (${CoolUtil.floorDecimal(curDecBeat, 2)})\n';
		debugInfo += 'Section: ${curSection}\n';
		debugInfo += 'BPM: ${CoolUtil.floorDecimal(Conductor.bpm, 2)}\n\n';
		debugInfo += 'STRUMS:\n';
		debugInfo += opponentStrumInfo;
		debugInfo += playerStrumInfo;

		modchartDebugTxt.text = debugInfo;
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		// For StepMania charts, do not animate the counter (score updates instantly)
		if (isStepManiaChart) {
			return;
		}

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
		@:privateAccess
		dialogueCount = psychDialogue.currentText;
		callOnScripts('onNextDialogue', [dialogueCount]);
		stagesFunc(function(stage:BaseStage) stage.startNextDialogue(dialogueCount));
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
		stagesFunc(function(stage:BaseStage) stage.onSkipDialogue(dialogueCount));
	}
	public var startedSong:Bool = false;

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

		if (ClientPrefs.data.allowVis && ClientPrefs.data.healthVis) {
			visual = new AudioDisplay(FlxG.sound.music, healthBar.x, healthBar.y + 20, Std.int(healthBar.width), Std.int(FlxG.height / 6), 50, 2, FlxColor.WHITE);
			visual.scrollFactor.set(0, 0);
			addBehindHUD(visual);
			visual.cameras = [camHUD];
			visual.alpha = 0.7;

			var generalVocals = Paths.voices(SONG.song);
			var playerVocals = Paths.voices(SONG.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
			if (SONG.needsVoices) {
				if ((generalVocals != null && generalVocals.length > 1) || (playerVocals != null && playerVocals.length > 1)) {
					vocalvisual = new AudioDisplay(vocals, healthBar.x, healthBar.y + 30, Std.int(healthBar.width), Std.int(FlxG.height / 12), 50, 2, FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
					vocalvisual.scrollFactor.set(0, 0);
					vocalvisual.flipY = true;
					addBehindHUD(vocalvisual);
					vocalvisual.cameras = [camHUD];
					vocalvisual.alpha = 0.7;
				}

				if (opponentVocals != null && opponentVocals.length > 1) {
					oppvisual = new AudioDisplay(opponentVocals, healthBar.x, healthBar.y + 30, Std.int(healthBar.width), Std.int(FlxG.height / 12), 50, 2, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
					oppvisual.scrollFactor.set(0, 0);
					oppvisual.flipY = true;
					addBehindHUD(oppvisual);
					oppvisual.cameras = [camHUD];
					oppvisual.alpha = 0.7;
				}

				if (vocalvisual != null && oppvisual == null) {
					vocalvisual.color = FlxColor.WHITE;
					vocalvisual.colorLeft = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
					vocalvisual.colorRight = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
				}
			}
		}

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

			PlayState.storyWeek = FlxG.save.data.storyWeek;
			Mods.currentModDirectory = FlxG.save.data.currentModDirectory;
			Difficulty.list = FlxG.save.data.difficulties; // just in case
			PlayState.SONG = FlxG.save.data.SONG;
			PlayState.storyDifficulty = FlxG.save.data.storyDifficulty;
			FlxG.sound.music.time = FlxG.save.data.songPos;
			comboManager.songScore = FlxG.save.data.score;
			comboManager.ratingPercent = FlxG.save.data.rating;
			comboManager.songMisses = FlxG.save.data.misses;
			health = FlxG.save.data.health;

			FlxG.save.data.storyWeek = null;
			FlxG.save.data.currentModDirectory = null;
			FlxG.save.data.difficulties = null; // just in case
			FlxG.save.data.SONG = null;
			FlxG.save.data.storyDifficulty = null;
			FlxG.save.data.songPos = null;
			FlxG.save.data.score = null;
			FlxG.save.data.rating = null;
			FlxG.save.data.misses = null;
			FlxG.save.data.health = null;

			FlxG.save.flush();

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
			skipTxt = new FlxText(healthBar.x + 80, healthBar.y - 110, 500);
			skipTxt.text = "Press Space to Skip Intro";
			skipTxt.size = 30;
			skipTxt.color = FlxColor.WHITE;
			skipTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
			skipTxt.cameras = [camHUD];
			skipTxt.alpha = 0;
			skipTxt.font = Paths.font('comboFont.ttf');
			FlxTween.tween(skipTxt, {alpha: 1}, 0.2);
			add(skipTxt);
		}
		else
		{
			if (skipTxt != null)
				FlxTween.tween(skipTxt, {alpha: 0}, 0.2);
		}

		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');

		// my latest invention: THE CHAOS BRINGER
		if (AprilFools.allowAF && !inArchipelagoMode) {
			switch (FlxG.random.int(0, 5)) {
				case 0: //Random Speed
					trace("Random Speed");
					playbackRate *= FlxG.random.float(0.1, 2);
				case 1: //Reverse Input
					trace("Reverse Input");
					reverseNoteRules = !inArchipelagoMode  || archipelago.APItem.activeItem?.name == "Input Reversal";
				case 2: //Random Speed Change
					trace("Random Speed Change");
					RandomSpeedChange = true;
				case 3: //Wild Random Speed Change
					trace("Wild Random Speed Change");
					RandomSpeedChange = true;
					RandomSpeedChangeWild = true;
				case 4: //Random Modchart for no reason
					trace("Random Modchart for no reason");
					AprilFools.randomModchartEffect();
				case 5:
					trace("Nothing");
					//Nothing
			}
		}
		if (inArchipelagoMode) reverseNoteRules = APInfo.backwardsSinging;
		startedSong = true;

		if (MechanicManager.mechanics['mouse_follower'].points > 0)
		{
			mechanicsMod.fakeCursor();
		}

		if (MechanicManager.mechanics['click_time'].points > 0)
		{
			mechanicsMod.clickTime();
		}

		if (MechanicManager.mechanics['morale'].points > 0)
		{
			mechanicsMod.activateMorale();
		}

		if (MechanicManager.mechanics['dodging'].points > 0)
		{
			mechanicsMod.dodgeWant = FlxG.random.float(6, 18);
		}
	}


	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns:Int = Note.ammo[SONG?.mania != null ? SONG?.mania : 3];
	var prevNoteData:Int = -1;
	var initialNoteData:Int = -1;
	var caseExecutionCount:Int = FlxG.random.int(-50, 50);
	var currentModifier:Int = -1;
	var stair:Int = 0;


	public static function getNumberFromAnimsSmall(note:Int, mania:Int):Int {
		var anims:Array<String> = Note.keysShit.get(mania).get("anims");
		var animMap:Map<String, Int> = ["LEFT" => 0, "DOWN" => 1, "UP" => 2, "RIGHT" => 3];

		if (mania == 0) {
			// Only one key, everything maps to the same key
			return 0;
		} else if (mania == 1) {
			// Two keys: LEFT and RIGHT
			var anim = anims[note % anims.length];
			if (anim == "DOWN" || anim == "LEFT") return 0; // Map to LEFT
			if (anim == "UP" || anim == "RIGHT") return 1;  // Map to RIGHT
		} else if (mania == 2) {
			// Three keys: LEFT, UP, and RIGHT
			var anim = anims[note % anims.length];
			if (anim == "LEFT") return 0;
			if (anim == "DOWN" || anim == "UP") return 1; // Map DOWN and UP to the middle key
			if (anim == "RIGHT") return 2;
		} else if (mania > 3) {
			// Handle cases where mania > 4
			var anim = anims[note % anims.length];
			var matchingIndices = [];
			for (i in 0...anims.length) {
				if (anims[i] == anim) {
					matchingIndices.push(i);
				}
			}
			return matchingIndices.length > 0 ? matchingIndices[Std.int(Math.random() * matchingIndices.length)] : note % mania;
		}

		// Default case for mania <= 4
		var anim = anims[note % anims.length];
		return animMap.exists(anim) ? animMap.get(anim) : note % mania;
	}

	public static inline function getNumberFromAnims(note:Int, mania:Int):Int
		{
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

			if (mania > 3)
			{
				var anim = animKeys[note];
				var matchingIndices:Array<Int> = [];
				if (note < animKeys.length)
				{
					for (i in 0...anims.length)
					{
						if (anims[i] == anim)
						{
							matchingIndices.push(i);
						}
					}
					if (matchingIndices.length > 0)
					{
						var randomIndex = Std.int(Math.random() * matchingIndices.length);
						result = matchingIndices[randomIndex];
					}
					else
					{
						var randomIndex = Std.int(Math.random() * mania);
						result = randomIndex;
					}
				}
				else
				{
					if (matchingIndices.length > 0)
					{
						var randomIndex = Std.int(Math.random() * matchingIndices.length);
						result = matchingIndices[randomIndex];
					}
					else
					{
						var randomIndex = Std.int(Math.random() * mania);
						result = randomIndex;
					}
				}
			}
			else
			{ // mania == 3
				var anim = anims[note];
				if (note < anims.length)
				{
					if (animMap.exists(anim))
					{
						result = animMap.get(anim);
					}
					else
					{
						throw 'No matching animation found';
					}
				}
				else
				{
					result = animMap.get(anim);
				}
			}

			// Ensure result is within bounds
			if (result < 0 || result > mania)
			{
				trace("OOB NOtE: " + note + " MANIA: " + mania + " RESULT: " + result);
				var foundValidAnimation = false;
				while (!foundValidAnimation)
				{
					var randomIndex = Std.int(Math.random() * anims.length);
					var randomAnim = anims[randomIndex];
					if (animMap.exists(randomAnim))
					{
						result = animMap.get(randomAnim);
						foundValidAnimation = true;
					}
				}
			}

			return result;
		}

				private var preGen:Array<Dynamic> = [];

		private function preGenerateNotes():Void {
		preGen = []; // Clear the array before generating

		var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
		var daBpm:Float = Conductor.bpm;

		for (section in sectionsData) {
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm) {
				daBpm = section.bpm;
			}

			for (i in 0...section.sectionNotes.length) {
				final songNotes: Array<Dynamic> = section.sectionNotes[i];
				var spawnTime:Float = songNotes[0];
				var noteColumn:Int = Std.int(songNotes[1]);
				var holdLength:Float = songNotes[2];
				var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];

				if (Math.isNaN(holdLength)) holdLength = 0.0;


				var gottaHitNote:Bool = (songNotes[1] < (SONG.mania != null ? totalColumns : Note.ammo[3]));

				// Push the anonymous object into the preGen array
				preGen.push({
					spawnTime: spawnTime,
					noteColumn: noteColumn,
					holdLength: holdLength,
					noteType: noteType,
					gottaHitNote: gottaHitNote,
					section: section,
					isSustainNote: false
				});
				if (holdLength > 0)
				{

				}
			}
		}

		trace('Pre-generated ${preGen.length} notes.');
	}


	private function generateSong():Void
	{
		// trace('Generating Song: ${SONG.song}');
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
		var usable = Paths.isAssetInMod;

		// Check if this is a dynamic song and use stitched audio
		if (songData.isDynamic != null && songData.isDynamic && songData.dynamicAudio != null)
		{
			trace('PlayState: Loading dynamic song audio');

			// Use stitched audio from DynamicAudioManager
			var dynamicAudio = songData.dynamicAudio;

			if (dynamicAudio.vocals != null)
				vocals = dynamicAudio.vocals;
			if (dynamicAudio.vocalsPlayer != null)
				vocals = dynamicAudio.vocalsPlayer; // Use player vocals if available
			if (dynamicAudio.vocalsOpponent != null)
				opponentVocals = dynamicAudio.vocalsOpponent;
			if (dynamicAudio.vocalsGF != null)
				gfVocals = dynamicAudio.vocalsGF;

			trace('PlayState: Dynamic audio loaded successfully');
		}
		else
		{
			// Standard audio loading logic
			try
			{
				if (songData.needsVoices)
				{
					var currentMod = "";
					if (backend.WeekData.getCurrentWeek() != null)
						currentMod = backend.WeekData.getCurrentWeek().folder; //istg this is somehow the root cause to all my problems ong
					if (currentMod != null && currentMod != "")
					{
						var generalVocals = Paths.voices(songData.song);
						if (generalVocals != null && generalVocals.length > 0)
						{
							vocals.loadEmbedded(generalVocals);

							// Check for the other vocals as well
							var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
							if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

							var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
							if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
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
						var generalVocals = Paths.voices(songData.song);
						if (generalVocals != null && generalVocals.length > 0)
						{
							vocals.loadEmbedded(generalVocals);

							// Check for the other vocals as well
							var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
							if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

							var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
							if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
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
			}
			catch (e:Dynamic) {trace("Vocals Broke.");}
		}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		gfVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);
		FlxG.sound.list.add(gfVocals);

		inst = new FlxSound();

		// Check if this is a dynamic song and use stitched inst
		if (songData.isDynamic != null && songData.isDynamic && songData.dynamicAudio != null)
		{
			if (songData.dynamicAudio.inst != null)
			{
				inst = songData.dynamicAudio.inst;
				trace('PlayState: Using stitched inst audio from dynamic song');
			}
			else
			{
				// Fallback to standard inst loading
				try
				{
					inst.loadEmbedded(Paths.inst(altInstrumentals ?? songData.song));
				}
				catch (e:Dynamic) {}
			}
		}
		else
		{
			// Standard inst loading logic
			try
			{
				inst.loadEmbedded(Paths.inst(altInstrumentals ?? songData.song));
			}
			catch (e:Dynamic) {}
		}
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

		var ghostNotesCaught:Int = 0;
		if (LoadingState.noteCache.length > 0 && ClientPrefs.data.chartPreload != 'Off') {
			initThreadAlt(() -> {
				for (swagNote in LoadingState.noteCache) {
					callOnScripts("onGeneratedNote", [swagNote]);

					/*if (swagNote.texture != null)
						swagNote.reloadNote(swagNote.texture);
					else
						swagNote.reloadNote();*/

					// UNO Chart Modifier Processing
					if (ClientPrefs.getGameplaySetting('chartModifier', 'Normal') == "UNO") {
						if (unoMechanic == null) {
							unoMechanic = new UnoMechanic();
						}
						unoMechanic.processNote(swagNote, PlayState.mania, spawnTime, swagNote.mustPress);
					}

					var rowArray = noteRows[swagNote.mustPress?0:1];
					if(rowArray[swagNote.row]==null)
						rowArray[swagNote.row]=[];
					rowArray[swagNote.row].push(swagNote);

					var playfield:PlayField = swagNote.field;
					if (playfield == null && playfields.length > 0) {
						if (playfields.members[swagNote.fieldIndex] != null) {
							playfield = playfields.members[swagNote.fieldIndex];
							swagNote.field = playfield;
						}
					}

					// Generate special UNO notes (skip, wrong, +2, +4)
					if (ClientPrefs.getGameplaySetting('chartModifier', 'Normal') == "UNO" && unoMechanic != null) {
						var specialNotes = unoMechanic.generateSpecialNotes(swagNote, PlayState.mania, allNotes);
						for (specialNote in specialNotes) {
							if (playfield != null) {
								specialNote.field = playfield;
								specialNote.fieldIndex = swagNote.fieldIndex;
								playfield.queue(specialNote);
								allNotes.push(specialNote);
							}
						}
					}

					if(!noteTypes.contains(swagNote.noteType))
							noteTypes.push(swagNote.noteType);

					if (playfield != null)
					{
						playfield.queue(swagNote); // queues the note to be spawned
						allNotes.push(swagNote); // just for the sake of convenience
					}
				}
				trace("Preloaded Chart Loaded!");
			}, 'chart');
		} else {
			var AIPlayMap:Array<Array<Float>> = AIPlayer.active ? AIPlayer.GeneratePlayMap(SONG, AIPlayer.diff) : null;

			var oldNote:Note = null;
			var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
			var daBpm:Float = Conductor.bpm;

			var sectionLoopCount:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

			for (section in sectionsData)
			{
				if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
					daBpm = section.bpm;

				for (i in 0...section.sectionNotes.length)
				{
					final songNotes: Array<Dynamic> = section.sectionNotes[i];
					var spawnTime:Float = songNotes[0];
					var noteColumn:Int = Std.int(songNotes[1]);
					var noteStartColumn:Int = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
					var holdLength:Float = songNotes[2];
					var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
					if (Math.isNaN(holdLength)) holdLength = 0.0;

					var gottaHitNote:Bool;
					noteColumn = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
					gottaHitNote = (songNotes[1] < (SONG.mania != null ? totalColumns : Note.ammo[SONG.mania != null ? SONG.mania : 3]));

					//if (songData.format.contains("mixtape_v1")) gottaHitNote = section.mustHitSection;

					if (i != 0) {
						// CLEAR ANY POSSIBLE GHOST NOTES
						for (evilNote in allNotes) {
							var matches:Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
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
							//trace("4K Only: " + noteColumn);
							noteColumn = getNumberFromAnimsSmall(noteColumn, 3);
							//trace("Note: " + noteColumn + " Mania: " + mania + " GottaHit: " + gottaHitNote);
						case "ManiaConverter":
							//trace("ManiaConverter: " + noteColumn);
							noteColumn = getNumberFromAnims(noteColumn, mania);
							//trace("Note: " + noteColumn + " Mania: " + mania + " GottaHit: " + gottaHitNote);
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

					var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
					holdLength = Math.round(songNotes[2] / curStepCrochet) - 1;
					if (allNotes.length > 0)
						oldNote = allNotes[Std.int(allNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = ClientPrefs.data.useExperimentalNotePool ?
					NotePoolManager.createNote(spawnTime, noteColumn, oldNote, false, false, this) :
					noteManager.getNote(spawnTime, noteColumn, oldNote, false);

					swagNote.noteIndex = Std.int(allNotes.length);
					swagNote.formerPress = swagNote.mustPress = gottaHitNote;

					// UNO Chart Modifier Processing
					if (chartModifier == "UNO") {
						if (unoMechanic == null) {
							unoMechanic = new UnoMechanic();
						}
						unoMechanic.processNote(swagNote, mania, spawnTime, gottaHitNote);
					}

					swagNote.row = Conductor.secsToRow(spawnTime);
					var rowArray = noteRows[gottaHitNote?0:1];
					if(rowArray[swagNote.row]==null)
						rowArray[swagNote.row]=[];
					rowArray[swagNote.row].push(swagNote);
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
					swagNote.ID = allNotes.length;
					swagNote.holdType = swagNote.sustainLength > 0 ? HEAD : TAP;
					swagNote.isParent = swagNote.sustainLength > 0;
					swagNote.scrollFactor.set();
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

					if (chartModifier == 'Amalgam' && currentModifier == 11)
					{
						swagNote.multSpeed = FlxG.random.float(0.1, 2);
					}

					////

					callOnScripts("onGeneratedNote", [swagNote, section]);

					var playfield:PlayField = swagNote.field;

					if (playfield == null && playfields.length > 0) {
						if (swagNote.fieldIndex == -1)
							swagNote.fieldIndex = swagNote.mustPress ? 0 : 1;

						if (playfields.members[swagNote.fieldIndex] != null) {
							playfield = playfields.members[swagNote.fieldIndex];
							swagNote.field = playfield;
						}
					}
					//notes.insert(swagNote.ID, swagNote); // just for the sake of convenience

					if (playfield != null)
					{
						playfield.queue(swagNote); // queues the note to be spawned
						allNotes.push(swagNote); // just for the sake of convenience
					}

					// Generate special UNO notes (skip, wrong, +2, +4)
					if (chartModifier == "UNO" && unoMechanic != null) {
						var specialNotes = unoMechanic.generateSpecialNotes(swagNote, mania, allNotes);
						for (specialNote in specialNotes) {
							if (playfield != null) {
								specialNote.field = playfield;
								specialNote.fieldIndex = swagNote.fieldIndex;
								playfield.queue(specialNote);
								allNotes.push(specialNote);
							}
						}
					}

					var spot = 0;
					final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet) -1;
					if (roundSus > 0)
					{
						// Cache properties to avoid repeated property access
						final stepCrochet = Conductor.stepCrochet;
						final parentMustPress = swagNote.mustPress;
						final parentGfNote = swagNote.gfNote;
						final parentExNote = swagNote.exNote;
						final parentAnimSuffix = swagNote.animSuffix;
						final parentNoteType = swagNote.noteType;
						final parentNoteIndex = swagNote.noteIndex;
						final parentMultSpeed = (chartModifier == 'Amalgam' && currentModifier == 11) ? swagNote.multSpeed : 0;
						final parentFieldIndex = swagNote.fieldIndex;
						final parentField = swagNote.field;
						final usePool = ClientPrefs.data.useExperimentalNotePool;

						for (susNote in 0...roundSus)
						{
							oldNote = allNotes[Std.int(allNotes.length - 1)];

							var sustainNote:Note = usePool ?
								NotePoolManager.createNote(spawnTime + (stepCrochet * susNote) + stepCrochet, noteColumn, oldNote, true, false, this) :
								new Note(spawnTime + (stepCrochet * susNote) + stepCrochet, noteColumn, oldNote, true, false, null, false);

							// Set properties using cached values
							sustainNote.mustPress = parentMustPress;
							sustainNote.gfNote = parentGfNote;
							sustainNote.exNote = parentExNote;
							sustainNote.animSuffix = parentAnimSuffix;
							sustainNote.noteType = parentNoteType;
							sustainNote.noteIndex = parentNoteIndex;
							if (chartModifier == 'Amalgam' && currentModifier == 11)
							{
								sustainNote.multSpeed = parentMultSpeed;
							}
							if (sustainNote == null || !sustainNote.alive)
								break;
							sustainNote.ID = allNotes.length;
							sustainNote.scrollFactor.set();
							sustainNote.holdType = roundSus > 0 ? PART : END;
							sustainNote.parent = swagNote;
							sustainNote.fieldIndex = parentFieldIndex;
							sustainNote.field = parentField;
							swagNote.tail.push(sustainNote);
							swagNote.unhitTail.push(sustainNote);
							playfield.queue(sustainNote);
							allNotes.push(sustainNote);
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
							swagNote.childs.push(sustainNote);
							sustainNote.spotInLine = spot;
							spot++;
						}
					}

					if(!noteTypes.contains(swagNote.noteType))
						noteTypes.push(swagNote.noteType);

					if (mechanicsMod != null) {
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
								Math.min(MechanicManager.mechanics['hurt_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
									1),
								0.5,
								1
							],
							[
								'kill_note',
								'Kill Note',
								Math.min(MechanicManager.mechanics['kill_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
									1),
								0.2,
								0.5
							],
							[
								'burst_note',
								'Burst Note',
								Math.min(MechanicManager.mechanics['burst_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
									1),
								0.35,
								0.9
							],
							[
								'sleep_note',
								'Sleep Note',
								Math.min(MechanicManager.mechanics['sleep_note'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
									1),
								0.35,
								0.75
							],
							[
								'fake_note',
								'Fake Note',
								Math.min((MechanicManager.mechanics['fake_note'].points / 2) * FlxMath.remapToRange(sectionLength, 0, 16, 1,
									6) / songData.notes.length * 0.2, 1),
								0.5,
								0.9
							],
							[
								'note_random',
								'No Animation',
								Math.min(MechanicManager.mechanics['note_random'].points * FlxMath.remapToRange(sectionLength, 0, 16, 1, 6) / songData.notes.length * 0.2,
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
									else if (generatedTypes[jj][0] == 'restore_note' && (!j && !bothMode))
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
									var placePlayfield:PlayField = placeNote.field;

									if (placePlayfield == null && playfields.length > 0) {
										if (placeNote.fieldIndex == -1)
											placeNote.fieldIndex = placeNote.mustPress ? 0 : 1;

										if (playfields.members[placeNote.fieldIndex] != null) {
											placePlayfield = playfields.members[placeNote.fieldIndex];
											placeNote.field = placePlayfield;
										}
									}
									if (placePlayfield != null)
									{
										placePlayfield.queue(placeNote); // queues the note to be spawned
										allNotes.push(placeNote); // just for the sake of convenience
									}
									weightedChances[jj] = 0;
								}
							}
						}
						var strumSwapPoints:Int = MechanicManager.mechanics['strum_swap'].points;

						if (FlxG.random.bool(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 8) + getChance(7)))
						{
							moveStrumSections[sectionLoopCount] = true;
							weightedChances[7] = 0;
						}
						else
						{
							moveStrumSections[sectionLoopCount] = false;
							weightedChances[7] += FlxG.random.float(FlxMath.remapToRange(strumSwapPoints, 0, 20, 0, 0.4));
						}

						if (archipelago.APInfo.soreThroat) {
							for (j in [false, true])
							{
								var hitSectionMulti:Float = 1;

								if (section.mustHitSection != j)
								{
									hitSectionMulti = 0.2;
								}
								if (section.sectionNotes.length < 8)
									hitSectionMulti = 0.04;

								for (i in 0...16)
								{
									var throatNote:Note = placeNote(10, "Throat Note", [
										sectionStartTime + (Conductor.stepCrochet * i),
										FlxG.random.int(0, 3),
										j,
										hitSectionMulti
									]);

									if (throatNote == null)
										continue;

									var placePlayfield:PlayField = throatNote.field;
									if (placePlayfield == null && playfields.length > 0) {
										if (throatNote.fieldIndex == -1) throatNote.fieldIndex = throatNote.mustPress ? 0 : 1;

										if (playfields.members[throatNote.fieldIndex] != null) {
											placePlayfield = playfields.members[throatNote.fieldIndex];
											throatNote.field = placePlayfield;
										}
									}

									if (placePlayfield != null)
									{
										placePlayfield.queue(throatNote);
										allNotes.push(throatNote);
									}
								}
							}
						}
						sectionLoopCount += 1;
					}
				}

				if (mechanicsMod != null) {
					if (MechanicManager.mechanics["note_speed"].points > 0)
					{
						for (note in allNotes)
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
			}
		}


		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		allNotes.sort(sortByTime);

		for (fuck in allNotes) {
			unspawnNotes.push(fuck);
			curChart.push(fuck);
		}

		// curChart = cast (curChart:objects.NotePool.NoteArray);

		for (field in playfields.members)
			field.clearStackedNotes();

		if (mechanicsMod != null) {

			if (MechanicManager.mechanics['drain_hp'].points > 0)
			{
				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					if (!paused && !startingSong && !endingSong && health > minHealth + minHealthOffset + 0.1)
					{
						if (MechanicManager.mechanics['drain_hp'].points > 0)
						{
							if (FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['drain_hp'].points, 0, 20, 0, 75)))
							{
								noTriggerKarma = true;
								var loss:Float = FlxMath.remapToRange(0.1, 0, 100, 0, 2);
								if (mechanicsMod.restoreActivated)
									lastHealth -= loss;
								else
									health -= loss;

								if (mechanicsResult[8] != null)
									mechanicsResult[8].value += loss * 10;

								noTriggerKarma = false;
							}
						}
						else
						{
							tmr.cancel();
						}
					}
				}, 0);
			}
		}
		generatedMusic = true;
	}

	private function placeNote(chance:Float, noteType:String, attributes:Array<Dynamic>):Note
	{
		if (FlxG.random.bool(chance))
		{
			var dataNote:Note = ClientPrefs.data.useExperimentalNotePool ?
				NotePoolManager.createNote(attributes[0], attributes[1], null, false, false, this) :
				new Note(attributes[0], attributes[1], null, false);
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

	private function regenNotes():Void
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
				var noteColumn:Int = Std.int(songNotes[1]);
				var noteStartColumn:Int = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
				var holdLength:Float = songNotes[2];
				var noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				if (Math.isNaN(holdLength)) holdLength = 0.0;

				var gottaHitNote:Bool;
				noteColumn = Std.int(songNotes[1] % Note.ammo[SONG.mania != null ? SONG.mania : 3]);
				gottaHitNote = (songNotes[1] < (SONG.mania != null ? totalColumns : Note.ammo[3]));

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in allNotes) {
						var matches:Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
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
						//trace("4K Only: " + noteColumn);
						noteColumn = getNumberFromAnimsSmall(noteColumn, 3);
						//trace("Note: " + noteColumn + " Mania: " + mania + " GottaHit: " + gottaHitNote);
					case "ManiaConverter":
						//trace("ManiaConverter: " + noteColumn);
						noteColumn = getNumberFromAnims(noteColumn, mania);
						//trace("Note: " + noteColumn + " Mania: " + mania + " GottaHit: " + gottaHitNote);
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

				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
				holdLength = Math.round(songNotes[2] / curStepCrochet) - 1;
				if (allNotes.length > 0)
					oldNote = allNotes[Std.int(allNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = ClientPrefs.data.useExperimentalNotePool ?
					NotePoolManager.createNote(spawnTime, noteColumn, oldNote, false, false, this) :
					new Note(spawnTime, noteColumn, oldNote);
				swagNote.noteIndex = Std.int(allNotes.length);
				swagNote.mustPress = gottaHitNote;

				swagNote.row = Conductor.secsToRow(spawnTime);
				var rowArray = noteRows[gottaHitNote?0:1];
				if(rowArray[swagNote.row]==null)
					rowArray[swagNote.row]=[];
				rowArray[swagNote.row].push(swagNote);
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

				var playfield:PlayField = swagNote.field;

				if (playfield == null && playfields.length > 0) {
					if (swagNote.fieldIndex == -1)
						swagNote.fieldIndex = swagNote.mustPress ? 0 : 1;

					if (playfields.members[swagNote.fieldIndex] != null) {
						playfield = playfields.members[swagNote.fieldIndex];
						swagNote.field = playfield;
					}
				}

				playfield = swagNote.field;
				swagNote.fieldIndex = playfield.modNumber;
				//notes.insert(swagNote.ID, swagNote); // just for the sake of convenience

				if (playfield != null)
				{
					playfield.queue(swagNote); // queues the note to be spawned
					allNotes.push(swagNote); // just for the sake of convenience
				}

				var spot = 0;
				final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet) -1;
				if (roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = allNotes[Std.int(allNotes.length - 1)];

						var sustainNote:Note = ClientPrefs.data.useExperimentalNotePool ?
							NotePoolManager.createNote(spawnTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), noteColumn, oldNote, true, false, this) :
							new Note(spawnTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet), noteColumn, oldNote, true);
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
						sustainNote.field = swagNote.field;
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

			note.defaultRGB();

			// Like set_noteType()
		}
	}

	public function changeMania(newValue:Int, skipStrumFadeOut:Bool = false)
	{
		callOnScripts('preChangeMania', [mania, newValue, skipStrumFadeOut]);
		var daOldMania = mania;

		mania = newValue;

		playerField.strumNotes = [];
		dadField.strumNotes = [];

		callOnScripts('onChangeMania', [mania, daOldMania]);


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

		callOnScripts('preReceptorGeneration'); // backwards compat, deprecated
		callOnScripts('onReceptorGeneration');

		for (field in playfields.members)
		{
			field.keyCount = Note.ammo[mania];
			field.generateStrums();
		}

		callOnScripts('postReceptorGeneration'); // deprecated
		callOnScripts('onReceptorGenerationPost');

		callOnScripts('onChangeMania', [mania, newValue, skipStrumFadeOut]);

		for (field in playfields.members)
			field.fadeIn(skipStrumFadeOut); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode

		singAnimations = Note.keysShit.get(mania).get('singAnims');

		callOnScripts('postChangeMania', [mania, newValue, skipStrumFadeOut]);
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		if (eventsPushed != null) {
			eventPushedUnique(event);
			if(eventsPushed.contains(event.event)) {
				return;
			}

			stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
			eventsPushed.push(event.event);
		}
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
				var easeFunc:EaseFunction = FlxEase.linear;

				var tweenOptions = event.value2.split("/");
				if(tweenOptions.length >= 1){
					easeFunc = FlxEase.linear;
					var parsed:Float = Std.parseFloat(tweenOptions[0]);
					if(!Math.isNaN(parsed))
						endTime = event.strumTime + (parsed * 1000);

					if(tweenOptions.length > 1){
						var f:EaseFunction = LuaUtils.getTweenEaseByString(tweenOptions[1]);
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
		//trace('GENERATING STRUMS!');
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
		var field = new PlayField(modManager);
		field.modNumber = playfields.members.length;
		field.playerId = field.modNumber;
		field.cameras = playfields.cameras;
		initPlayfield(field);
		playfields.add(field);
		return field;
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
			notes.remove(note, true);
		});
		field.noteMissed.add((daNote:Note, field:PlayField) -> {
			//trace("Missed!");
			if (field.isPlayer && !field.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
				noteMiss(daNote, field);

		});

		field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
			callOnScripts('onSpawnNote', [dunceNote.noteReflection]);
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

			callOnScripts('onSpawnNotePost', [dunceNote.noteReflection]);
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
			if (holdsGiveHP #if MECHANICS_MOD_ALLOWED && (mechanicsMod != null && !mechanicsMod.restoreActivated) #end){
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
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset + delayOffset;

		var checkVocals = [vocals, opponentVocals, gfVocals];
		for (voc in checkVocals)
		{
			if (FlxG.sound.music.time < vocals.length)
			{
				voc.time = FlxG.sound.music.time - (delayOffset * 1.5);
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
	public var canPauseHardMode:Bool = true;
	var freezeCamera:Bool = false;
	public var allowDebugKeys:Bool = true;

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

	public static function getNoteInitialTime(time:Float)
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

	public static function getTimeFromSV(time:Float, event:SpeedEvent):Float {
		#if EASED_SVs
		var func:EaseFunction = event?.easeFunc;
		if (event?.endTime != null) {
			var timeElapsed:Float = FlxMath.remapToRange(time, event.startTime, event.endTime, 0, 1);
			if(timeElapsed > 1)timeElapsed = 1;
			if(timeElapsed < 0)timeElapsed = 0;
			var currentSpeed = FlxMath.lerp(event.startSpeed, event.speed, func(PlayState.instance?.lastSVElapsed));

			var toAdd:Float = time - PlayState.instance?.lastSVTime;
			var finalPosition:Float = PlayState.instance?.lastSVPos + toAdd * currentSpeed;

			if (PlayState.instance != null) PlayState.instance.lastSVPos = finalPosition;
			if (PlayState.instance != null) PlayState.instance.lastSVTime = time;
			if (PlayState.instance != null) PlayState.instance.lastSVElapsed = timeElapsed;
			return finalPosition;
		}
		#end

		return event?.position + ((time - event?.startTime) * 0.45 * event?.speed);
	}

	public static function getSV(time:Float){
		var svIndex:Int = 0;

		var event:SpeedEvent = PlayState.instance?.speedChanges[svIndex];
		if (svIndex < PlayState.instance?.speedChanges.length - 1) {
			while (PlayState.instance?.speedChanges[svIndex + 1] != null && PlayState.instance?.speedChanges[svIndex + 1].startTime <= time) {
				event = PlayState.instance?.speedChanges[svIndex + 1];
				svIndex++;
			}
		}

		return event;
	}

	public function die(?trueKill:Bool = false, ?cod:String):Void
	{
		'COD = $cod. backend.COD.COD.COD = ${backend.COD.COD.COD}'.log();
			if (cod != null && cod.trim() != "") {
				backend.COD.COD.COD = cod;
			}
		if (trueKill)
			doDeathCheck(true);
		else {
			bfkilledcheck = true;
			health = 0;
			noteMissPress(3, opponentmode ? dadField : playerField); // just to make sure you actually die
			doDeathCheck();
		}
	}

	// the void varient of the function above with trueKill set to true
	/*public function killhimtodeath():Void
	{
		bfkilledcheck = true;
		health = 0;
		lives = 0;
		noteMissPress(3, opponentmode ? dadField : playerField); // just to make sure you actually die
		doDeathCheck(true);
	}*/

	function updateVisPos() { //Literaly so it doesn't look weird in the update function
		try {
			if (visual != null) {
				visual.x = healthBar.x;
				visual.y = healthBar.y;
				visual.alpha = ClientPrefs.data.visOpacity;
			}

			if (vocalvisual != null) {
				vocalvisual.x = healthBar.x;
				vocalvisual.y = healthBar.y + healthBar.height;
				vocalvisual.alpha = ClientPrefs.data.visOpacity;
				for (line in vocalvisual.members)
					line.color = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
			}

			if (oppvisual != null) {
				oppvisual.x = healthBar.x;
				oppvisual.y = healthBar.y + healthBar.height;
				oppvisual.alpha = ClientPrefs.data.visOpacity;
				for (line in vocalvisual.members)
					line.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			}
		} catch(e){}
	}

	public var initY:Float;
	var lastHealth:Float = -1;
	override public function update(elapsed:Float)
	{
		// If Legacy Lua settings are being edited and we're not in test mode, don't allow regular PlayState
		// The Legacy Lua system should handle PlayState switching through its own mechanisms
		if (options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode && !isLegacyLuaTest) {
			// Don't auto-switch PlayState when in Legacy Lua settings mode - let the Legacy Lua system handle it
			// This prevents conflicts between the systems
		}

		// Update dynamic song system
		updateDynamicSong();

		if(!inCutscene && !paused && !freezeCamera) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
			var idleAnim:Bool = (boyfriend?.getAnimationName().startsWith('idle') || boyfriend?.getAnimationName().startsWith('danceLeft') || boyfriend?.getAnimationName().startsWith('danceRight'));
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

		if (FlxG.animationTimeScale != playbackRate) {
			FlxG.animationTimeScale = playbackRate;
		}

		//So that the health text works
		if (health != lastHealth) {
			updateScoreText();
			lastHealth = health;
		}

		// Update modchart debug info every frame
		updateModchartDebugText();

		if (inArchipelagoMode && APInfo.inHardMode)
		{
			vocalVolumeMultiplierHardMode = (APInfo.hasItem("BF's Mic") ? 1 : 0);

			gfGroup.visible = APInfo.hasItem("GF");

			instVolumeMultiplierHardMode = (APInfo.hasItem("Speakers") ? 1 : 0);

			camHUD.visible = !APInfo.hasItem("HUD");

			canPauseHardMode = APInfo.hasItem("Pause Menu");

		}

		callOnScripts('onUpdate', [elapsed]);

		updateVisPos();

		if (curHealthMode == "Tabi" || curHealthMode == "Amalgam")
		{
			if (health > 0)
			{
				health -= 0.001 / (ClientPrefs.data.framerate / 60);
			}
		}

		super.update(elapsed);
		vocals.volume *= vocalVolumeMultiplier * vocalVolumeMultiplierHardMode;
		FlxG.sound.music.volume = 1 * instVolumeMultiplier * instVolumeMultiplierHardMode;
		updateVisualPosition();
		modManager.update(elapsed, curDecBeat, curDecStep);
		updateSyncedVideos(); // Update synced video system

		//Band-Aid patch but HEY IT WORKS SO I AM NOT COMPLAINING LMAO
		if (!startingSong && ClientPrefs.data.modcharts)
			modchartSync(false);

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

		if (allowSkip)
		{
			if (ClientPrefs.data.skipMode == 'First Note') {
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
			else if (ClientPrefs.data.skipMode == 'First BF Note') {
				if (allNotes.length > 0) {
					for (note in allNotes) {
						if (note != null && note.mustPress && note.strumTime > 100)
						{
							needSkip = true;
							skipTo = note.strumTime - 500;
							break;
						}
						else
						{
							needSkip = false;
						}
					}
				}
			}
		}

		for (playfield in playfields.members)
		{
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || (archipelago.APItem.activeItem?.name == 'Tutorial Trap' && _cachedSongName != 'tutorial');

			playfield.noteField.songSpeed = songSpeed;
		}

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		// Legacy Lua test text animation
		if(legacyLuaTestTxt != null) {
			legacyLuaTestTxt.visible = isLegacyLuaTest; // Update visibility in case flag changes
			if(legacyLuaTestTxt.visible) {
				legacyLuaTestTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180); // Sync with botplay animation
			}
		}

		if (controls.PAUSE && startedCountdown && canPause && canPauseHardMode && !endingSong)
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

		hearts.forEachAlive(function(heart:FlxSprite)
		{
			heart.angle = FlxMath.lerp(heart.angle, 30, cameraSpeed * 2 / (240 / 60));
			if (curHealthMode == "Lives")
			{
				heart.y = healthBar.y;
				heart.x = (healthBar.x*1.3) + (40 * heart.ID);
			}
			else
			{
				heart.y = healthBar.y - healthBar.height + 10;
				heart.x = (healthBar.x*2.6) + 60 + (40 * heart.ID);
			}
			if (heart.ID > (lives-1))
				heart.visible = false;
			else
				heart.visible = true;
		});

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

		if (judgementCounter != null)
			judgementCounter.updateCounter(comboManager.ratingsData, comboManager.songMisses, comboManager.combo, comboManager.maxCombo);

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
				timeTxt.text = convertTime(secondsTotal, false);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			archipelago.APPlayState.deathByLink = true; //To prevent self-made deaths (People would hate you for this)
			health = 0;
			lives = 0;
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

				amountOfRenderedNotes = 0;
				notes.forEach(function(daNote)
				{
					updateLiveNote(daNote);
				});

				if (mechanicsMod != null) {
					if (MechanicManager.mechanics['burst_note'].points > 0 && mechanicsMod.burstTime != null)
					{
						if (mechanicsMod.burstTime.value > mechanicsMod.burstTime.min)
						{
							mechanicsMod.burstTime.value = CoolUtil.boundTo(mechanicsMod.burstTime.value - elapsed, mechanicsMod.burstTime.min - 0.1, mechanicsMod.burstTime.max);
							if (mechanicsMod.allowBurstTween)
							{
								mechanicsMod.allowBurstTween = false;
								if (healthBarTween != null)
									healthBarTween.cancel();

								healthBarTween = FlxTween.tween(healthBarShader, {brightness: 0, hue: 0.5}, 1, {ease: FlxEase.cubeOut});
							}
						}
						else
						{
							mechanicsMod.allowBurstTween = true;
							if (healthBarTween != null)
								healthBarTween.cancel();

							healthBarTween = FlxTween.tween(healthBarShader, {brightness: -1, hue: 0}, 1, {ease: FlxEase.cubeOut});
						}
					}

					if (MechanicManager.mechanics['sleep_note'].points > 0)
					{
						if (mechanicsMod.sleepTime != null)
						{
							mechanicsMod.sleepTime.lerpValue = FlxMath.lerp(mechanicsMod.sleepTime.lerpValue, mechanicsMod.sleepTime.value, CoolUtil.boundTo(elapsed * 3, 0, 1));
							sleepFog.alpha = FlxMath.remapToRange(mechanicsMod.sleepTime.lerpValue, 0, mechanicsMod.sleepTime.max, 0, 1);
							modManager.setValue('drunk-a', FlxMath.remapToRange(mechanicsMod.sleepTime.lerpValue, 0, mechanicsMod.sleepTime.max, 0, 1), 0);
							modManager.setValue('wave-a', FlxMath.remapToRange(mechanicsMod.sleepTime.lerpValue, 0, mechanicsMod.sleepTime.max, 0, 1), 0);
						}
					}

					if (MechanicManager.mechanics['dodging'].points > 0)
					{
						if (mechanicsMod.dodgeInput)
						{
							if (cpuControlled || controls.justPressed('dodge'))
							{
								mechanicsMod.dodged = true;
								for (tmr in mechanicsMod.dodgeTimers)
								{
									tmr.onComplete(tmr);
								}
								dodgeFog.alpha = 0;
							}
						}
						else
						{
							mechanicsMod.dodgeTimer += elapsed;
							if (Conductor.songPosition >= 0 && (mechanicsMod.canDodge = (mechanicsMod.dodgeTimer >= mechanicsMod.dodgeWant)))
							{
								mechanicsMod.doDodge();
							}
						}
					}

					if (MechanicManager.mechanics['limit_health'].points > 0)
					{
						healthBarBlock.x = FlxMath.lerp(healthBarBlock.x, healthBar.x + FlxMath.remapToRange(maxHealthOffset, 0, MaxHP, 0, healthBar.width),
							CoolUtil.boundTo(elapsed * 3.7, 0, 1));
					}

					if (MechanicManager.mechanics['minimum_hp'].points > 0)
					{
						minBarBlock.x = FlxMath.lerp(minBarBlock.x, (healthBar.x + healthBar.width) - ((minHealthOffset * healthBar.width) / 2),
							CoolUtil.boundTo(elapsed * 3.7, 0, 1));
					}

					if (MechanicManager.mechanics['mouse_follower'].points > 0)
					{
						if (mouseCursor != null)
						{
							if (cpuControlled)
							{
								mouseCursor.x = FlxMath.lerp(mouseCursor.x, mechanicsMod.cpuPos.x, CoolUtil.boundTo(elapsed * 4.65, 0, 1));
								mouseCursor.y = FlxMath.lerp(mouseCursor.y, mechanicsMod.cpuPos.y, CoolUtil.boundTo(elapsed * 4.65, 0, 1));
							}
							else
							{
								mouseCursor.x = FlxG.mouse.getScreenPosition(camOther).x;
								mouseCursor.y = FlxG.mouse.getScreenPosition(camOther).y;
							}
						}

						if (mouseCursor != null && mechanicsMod.ghostCursor != null)
						{
							if (FlxG.overlap(mouseCursor, mechanicsMod.ghostCursor))
							{
								if (cpuControlled)
								{
									mechanicsMod.cpuPos.x = FlxG.random.float(0, FlxG.width);
									mechanicsMod.cpuPos.y = FlxG.random.float(0, FlxG.height);
								}
								mechanicsMod.cursorValue += elapsed;
							}
							else
								mechanicsMod.cursorValue -= elapsed;
						}

						mechanicsMod.cursorValue = FlxMath.bound(mechanicsMod.cursorValue, 0, 3);

						noTriggerKarma = true;
						if (mechanicsMod.cursorValue >= 2.75)
							die();
						noTriggerKarma = false;

						barCursor.alpha = FlxMath.remapToRange(mechanicsMod.cursorValue, 0, 2, 0, 1);
					}
					else
					{
						if (mouseCursor != null)
						{
							mouseCursor.x = FlxG.mouse.getScreenPosition(camOther).x;
							mouseCursor.y = FlxG.mouse.getScreenPosition(camOther).y;
						}
					}

					if (MechanicManager.mechanics['click_time'].points > 0)
					{
						mechanicsMod.updateTimeMechanic();
					}

					if (mechanicsMod.moraleActivated)
					{
						if (mechanicsMod.moraleActivated)
							mechanicsMod.updateMorale();
					}

					if (MechanicManager.mechanics['letter_placement'].points > 0)
					{
						mechanicsMod.updateLetterMechanic();
					}
				}
			}

			if (mechanicsMod != null) {
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				// dunno how to make it say its actually used
				var invertStrumGroup:FlxTypedGroup<StrumNote>->FlxTypedGroup<StrumNote> = function(strum:FlxTypedGroup<StrumNote>)
				{
					if (strum == playerStrums)
						return opponentStrums;
					else if (strum == opponentStrums)
						return playerStrums;
					return strumLineNotes;
				}

				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if ((!daNote.formerPress && bothMode) || (!daNote.mustPress && !bothMode))
						strumGroup = opponentStrums;

					var strumY:Float = strumGroup.members[daNote.noteData].y;

					// Cache flashlight mechanics to avoid repeated calculations
					var noteType = daNote.noteType;
					if (noteType != 'Fake Note' && noteType != 'Swap Note')
					{
						var points:Int = MechanicManager.mechanics['flashlight'].points;
						if (points > 0)
						{
							modManager.setValue('sudden-a', FlxMath.remapToRange(points, 0, 20, 0.1, 1));

							// Consolidate flashlight alpha calculation
							var centerPoint:Float = FlxG.height;
							var multi:Float = switch (ClientPrefs.data.downScroll)
							{
								case true:
									FlxMath.remapToRange(points, 0, 20, 0.4, 0.2);
								case false:
									FlxMath.remapToRange(points, 0, 20, 0.2, 0.4);
							}
							var notePos:Null<Float> = daNote.y;
							var curAlpha:Float = FlxMath.remapToRange(notePos, centerPoint * multi,
								ClientPrefs.data.downScroll ? strumY - (7.5 * points) : strumY + (7.5 * points), daNote.alphaLimit, 0.2);
							daNote.alpha = daNote.isSustainNote && curAlpha > 0.6 ? 0.6 : curAlpha;

							/* wanted it to have the same alpha as its parent but it got a bit janky
							for (sustain in daNote.tail)
							{
								if (Math.isNaN(notePos) || notePos == null)
								{
									sustain.alpha = FlxMath.remapToRange(sustain.y, centerPoint * multi,
										ClientPrefs.downScroll ? strumY - (7.5 * points) : strumY + (7.5 * points), sustain.alphaLimit, 0);
								}
							}*/
						}
					}

					var lastCopyX:Bool = cast daNote.copyX;
					if (daNote.expectedData != -1 && Math.abs(daNote.strumTime - Conductor.songPosition) < 500)
					{
						var gottenStrum = strumGroup;

						if (daNote.noteType == 'Swap Note')
							gottenStrum = invertStrumGroup(gottenStrum);

						FlxTween.tween(daNote, {x: daNote.field.baseXPositions[daNote.expectedData] - 100}, 1, {
							ease: FlxEase.quadOut,
							onStart: function(twn:FlxTween)
							{
								daNote.noteData = daNote.expectedData;
							},
							onComplete: function(twn:FlxTween)
							{
								daNote.copyX = lastCopyX;
							}
						});
						if (daNote.tail.length > 0)
						{
							for (sustain in daNote.tail)
							{
								lastCopyX = cast sustain.copyX;
								sustain.copyX = false;
								FlxTween.tween(sustain, {x: (daNote.field.baseXPositions[sustain.expectedData] + (Note.swagWidth / 2) - 100)}, 1, {
									ease: FlxEase.quadOut,
									onStart: function(twn:FlxTween)
									{
										sustain.noteData = sustain.expectedData;
									},
									onComplete: function(twn:FlxTween)
									{
										sustain.copyX = lastCopyX;
									}
								});
							}
						}
					}
				});
			}
			checkEventNote();
		}

		if (health < 0) health = 0;
		if (health > MaxHP) health = MaxHP;

		if (!inArchipelagoMode && curHealthMode == "Tabi") {
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

		if (!inArchipelagoMode && curHealthMode == "Amalgam") {
			healthBar.x = FlxG.width / 2 - healthBar.width / 2;
			healthBar.y = initY;
			healthBarOverflow.x = FlxG.width / 2 - healthBarOverflow.width / 2;
			healthBarOverflow.y = initY;
			if (health >= 4) {
				var amount = (health - 4) * 100;
				var rX = FlxG.random.float(-2, 2);
				var rY = FlxG.random.float(-2, 2);

				for (spr in [healthBar, healthBarOverflow, iconP1, iconP2]) {
					spr.x -= amount;
					spr.x += rX;
					spr.y += rY;
				}
			}

			for (icon in [iconP1, iconP2])
				icon.y = healthBar.y - (icon.height / 2);
		}


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


		if ((loopMode || loopModeChallenge/* || curSong == "Small Argument" && !inArchipelagoMode*/)
			&& startedCountdown
			&& !endingSong)
		{
			if (FlxG.sound.music.length - Conductor.songPosition <= endingTimeLimit)
			{
				songAboutToLoop = true;
				if (comboManager.AIScore >= comboManager.songScore && AIMode)
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
			remove(skipTxt);
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
			FlxTween.tween(skipTxt, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipTxt);
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

		for (i in shaderUpdates)
		{
			i(elapsed);
		}

		noTriggerKarma = true;
		if (health > MaxHP - maxHealthOffset)
			health = MaxHP - maxHealthOffset;
		noTriggerKarma = false;

		if (ClientPrefs.data.showRenderText)
			renderedTxt.text = 'Rendered Notes: ${formatNumber(amountOfRenderedNotes)}/${formatNumber(maxRenderedNotes)}/${formatNumber(notes.members.length)}';

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	public static function formatNumber(number:Float, ?decimals:Bool = false):String //simplified number formatting
	{
		return (number < 10e11 ? FlxStringUtil.formatMoney(number, false) : formatCompactNumber(number));
	}

	static function formatCompactNumber(number:Float):String
	{
		var suffixes1:Array<String> = ['ni', 'mi', 'bi', 'tri', 'quadri', 'quinti', 'sexti', 'septi', 'octi', 'noni'];
		var tenSuffixes:Array<String> = ['', 'deci', 'viginti', 'triginti', 'quadraginti', 'quinquaginti', 'sexaginti', 'septuaginti', 'octoginti', 'nonaginti', 'centi'];
		var decSuffixes:Array<String> = ['', 'un', 'duo', 'tre', 'quattuor', 'quin', 'sex', 'septe', 'octo', 'nove'];
		var centiSuffixes:Array<String> = ['centi', 'ducenti', 'trecenti', 'quadringenti', 'quingenti', 'sescenti', 'septingenti', 'octingenti', 'nongenti'];

		var magnitude:Int = 0;
		var num:Float = number;
		var tenIndex:Int = 0;

		while (num >= 1000.0)
		{
			num /= 1000.0;

			if (magnitude == suffixes1.length - 1) {
				tenIndex++;
			}

			magnitude++;

			if (magnitude == 21) {
				tenIndex++;
				magnitude = 11;
			}
		}

		// Determine which set of suffixes to use
		var suffixSet:Array<String> = (magnitude <= suffixes1.length) ? suffixes1 : ((magnitude <= suffixes1.length + decSuffixes.length) ? decSuffixes : centiSuffixes);

		// Use the appropriate suffix based on magnitude
		var suffix:String = (magnitude <= suffixes1.length) ? suffixSet[magnitude - 1] : suffixSet[magnitude - 1 - suffixes1.length];
		var tenSuffix:String = (tenIndex <= 10) ? tenSuffixes[tenIndex] : centiSuffixes[tenIndex - 11];

		// Use the floor value for the compact representation
		var compactValue:Float = Math.floor(num * 100) / 100;

		if (compactValue <= 0.001) {
			return "0"; // Return 0 if compactValue = null
		} else {
			var illionRepresentation:String = "";

			if (magnitude > 0) {
				illionRepresentation += suffix + tenSuffix;
			}

				if (magnitude > 1) illionRepresentation += "llion";

			return compactValue + (magnitude == 0 ? "" : " ") + (magnitude == 1 ? 'thousand' : illionRepresentation);
		}
	}

	function convertTime(seconds:Float, ?showMS:Bool = false):String {
		if (seconds < 3600)
			return FlxStringUtil.formatTime(seconds, showMS);
		else {
			var omegaFormat:String = '';
			if (Std.int(DateTools.days(seconds)) > 0)
				omegaFormat += '${DateTools.days(seconds)}:';
			if (Std.int(DateTools.hours(seconds)) > 0)
				omegaFormat += '${DateTools.hours(seconds)}:';
			omegaFormat += FlxStringUtil.formatTime(seconds, showMS);
			return omegaFormat;
		}
	}

	public var amountOfRenderedNotes:Float = 0;
	public var maxRenderedNotes:Float = 0;

	function updateLiveNote(daNote:Note):Void
	{
		if (daNote != null && daNote.exists)
		{
			//first, process whether or not the note should be hit. this prevents pointless strum following
			if (!daNote.exists) return;

			amountOfRenderedNotes += 1;
			if (maxRenderedNotes < amountOfRenderedNotes) maxRenderedNotes = amountOfRenderedNotes;

		}
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		switch (ClientPrefs.data.iconBounce) {
			case "Base" | "VS Steve":
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

			case 'Old Psych':
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))),
					Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))),
					Std.int(FlxMath.lerp(iconP2.frameHeight, iconP2.height, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));

				if (iconP12 != null) {
					iconP12.setGraphicSize(Std.int(FlxMath.lerp(iconP12.frameWidth, iconP12.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))),
						Std.int(FlxMath.lerp(iconP12.frameHeight, iconP12.height, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
				}

				if (iconP22 != null) {
					iconP22.setGraphicSize(Std.int(FlxMath.lerp(iconP22.frameWidth, iconP22.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))),
						Std.int(FlxMath.lerp(iconP22.frameHeight, iconP22.height, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
				}

			case 'Strident Crisis':
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, 0.50 / playbackRate)),
					Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, 0.50 / playbackRate)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, 0.50 / playbackRate)),
					Std.int(FlxMath.lerp(iconP2.frameHeight, iconP1.height, 0.50 / playbackRate)));
				iconP1.updateHitbox();
				iconP2.updateHitbox();

				if (iconP12 != null) {
					iconP12.setGraphicSize(Std.int(FlxMath.lerp(iconP12.frameWidth, iconP12.width, 0.50 / playbackRate)),
						Std.int(FlxMath.lerp(iconP12.frameHeight, iconP12.height, 0.50 / playbackRate)));
					iconP12.updateHitbox();
				}

				if (iconP22 != null) {
					iconP22.setGraphicSize(Std.int(FlxMath.lerp(iconP22.frameWidth, iconP22.width, 0.50 / playbackRate)),
						Std.int(FlxMath.lerp(iconP22.frameHeight, iconP22.height, 0.50 / playbackRate)));
					iconP22.updateHitbox();
				}

			case 'Dave and Bambi':
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, 0.8 / playbackRate)),
					Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, 0.8 / playbackRate)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, 0.8 / playbackRate)),
					Std.int(FlxMath.lerp(iconP2.frameHeight, iconP2.height, 0.8 / playbackRate)));

				if (iconP12 != null) {
					iconP12.setGraphicSize(Std.int(FlxMath.lerp(iconP12.frameWidth, iconP12.width, 0.8 / playbackRate)),
						Std.int(FlxMath.lerp(iconP12.frameHeight, iconP12.height, 0.8 / playbackRate)));
				}

				if (iconP22 != null) {
					iconP22.setGraphicSize(Std.int(FlxMath.lerp(iconP22.frameWidth, iconP22.width, 0.8 / playbackRate)),
						Std.int(FlxMath.lerp(iconP22.frameHeight, iconP22.height, 0.8 / playbackRate)));
				}

			case 'Plank Engine':
				final funnyBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);

				iconP1.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
				iconP2.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
				if (iconP12 != null) iconP12.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
				if (iconP22 != null) iconP22.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;

			case 'Golden Apple':
				iconP1.centerOffsets();
				iconP2.centerOffsets();
				if (iconP12 != null) iconP12.centerOffsets();
				if (iconP22 != null) iconP22.centerOffsets();

		}
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		if (iconP12 != null) iconP12.updateHitbox();
		if (iconP22 != null) iconP22.updateHitbox();
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		var healthRatio:Float = health / MaxHP;
		switch (curHealthMode) {
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
	public var karmaTmr:FlxTimer;
	public var karmaBarTmr:FlxTimer;
	public var karmaActive:Bool = false;
	public var noTriggerKarma:Bool = false; // helper variable to prevent other mechanics
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		#if MECHANICS_MOD_ALLOWED
		if (MechanicManager.mechanics['karma'].points > 0
			&& !noTriggerKarma
			&& value < health
			&& (value != MaxHP)
			&& !karmaActive)
		{
			if (karmaTmr != null)
			{
				karmaTmr.update(10e9 * 1000); // update by a billion seconds
				karmaTmr.cancel();
				karmaTmr = null;
			}

			if (karmaBarTmr != null)
			{
				karmaBarTmr.update(10e9 * 1000);
				karmaBarTmr.cancel();
				karmaBarTmr = null;
			}

			karmaActive = true;

			if (health - value <= 0)
			{
				return (health = value);
			}

			var difference:Float = Math.min(health - value, 0.07) / FlxMath.remapToRange(MechanicManager.mechanics['karma'].points, 0, 20, 10, 2.225);

			var min:Int = Math.floor(FlxMath.remapToRange(MechanicManager.mechanics['karma'].points, 0, 20, 5, 13));
			var max:Int = Math.floor(FlxMath.remapToRange(MechanicManager.mechanics['karma'].points, 0, 20, 11, 30));

			if (MechanicManager.mechanics['karma'].points >= 10)
			{
				if (min <= 3)
					min = 3;
			}

			healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), 0xFFFF00EA);
			healthBar.updateBar();

			var loop:Int = FlxG.random.int(min, max);
			karmaTmr = new FlxTimer().start(0.1, function(tmr:FlxTimer)
			{
				health -= difference;
				if (mechanicsResult[23] != null)
					mechanicsResult[23].value += difference * 10;
			}, loop);

			karmaBarTmr = new FlxTimer().start(0.1 * loop, function(tmr:FlxTimer)
			{
				reloadHealthBarColors();
				karmaActive = false;
			});
		}
		else
		{
			health = value;
		}
		#else
		health = value;
		#end

		// update health bar
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
				case ANIMSINGLE:
					iconP1.animation.play('idle', true);
				case ANIMDEFAULT:
					iconP1.animation.play((healthBar.percent < 20 ? 'normal' : 'losing'), true);
				case ANIMWINNING:
					iconP1.animation.play((healthBar.percent < 20 ? 'winning' : (healthBar.percent > 80 ? 'losing' : 'normal')), true);
				default:
					iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 0 : 1);
			}

			switch (iconP2.type)
			{
				case SINGLE:
					iconP2.animation.curAnim.curFrame = 0;
				case WINNING:
					iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 2 : (healthBar.percent < 20 ? 1 : 0));
				case ANIMSINGLE:
					iconP2.animation.play('idle', true);
				case ANIMDEFAULT:
					iconP2.animation.play((healthBar.percent > 80 ? 'normal' : 'losing'), true);
				case ANIMWINNING:
					iconP2.animation.play((healthBar.percent > 80 ? 'losing' : (healthBar.percent < 20 ? 'winning' : 'normal')), true);
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
					case ANIMSINGLE:
						iconP22.animation.play('idle', true);
					case ANIMDEFAULT:
						iconP22.animation.play((healthBar.percent > 80 ? 'normal' : 'losing'), true);
					case ANIMWINNING:
						iconP22.animation.play((healthBar.percent > 80 ? 'losing' : (healthBar.percent < 20 ? 'winning' : 'normal')), true);
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
					case ANIMSINGLE:
						iconP12.animation.play('idle', true);
					case ANIMDEFAULT:
						iconP12.animation.play((healthBar.percent < 20 ? 'normal' : 'losing'), true);
					case ANIMWINNING:
						iconP12.animation.play((healthBar.percent < 20 ? 'winning' : (healthBar.percent > 80 ? 'losing' : 'normal')), true);
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
					iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 2 : (healthBar.percent > 80 ? 0 : 1));
				case ANIMSINGLE:
					iconP1.animation.play('idle', true);
				case ANIMDEFAULT:
					iconP1.animation.play((healthBar.percent < 20 ? 'losing' : 'normal'), true);
				case ANIMWINNING:
					iconP1.animation.play((healthBar.percent < 20 ? 'losing' : (healthBar.percent > 80 ? 'winning' : 'normal')), true);
				default:
					iconP1.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
			}

			switch (iconP2.type)
			{
				case SINGLE:
					iconP2.animation.curAnim.curFrame = 0;
				case WINNING:
					iconP2.animation.curAnim.curFrame = (healthBar.percent > 80 ? 1 : (healthBar.percent < 20 ? 2 : 0));
				case ANIMSINGLE:
					iconP2.animation.play('idle', true);
				case ANIMDEFAULT:
					iconP2.animation.play((healthBar.percent > 80 ? 'losing' : 'normal'), true);
				case ANIMWINNING:
					iconP2.animation.play((healthBar.percent > 80 ? 'losing' : (healthBar.percent < 20 ? 'winning' : 'normal')), true);
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
					case ANIMSINGLE:
						iconP22.animation.play('idle', true);
					case ANIMDEFAULT:
						iconP22.animation.play((healthBar.percent < 20 ? 'losing' : 'normal'), true);
					case ANIMWINNING:
						iconP22.animation.play((healthBar.percent < 20 ? 'losing' : (healthBar.percent > 80 ? 'winning' : 'normal')), true);
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
					case ANIMSINGLE:
						iconP12.animation.play('idle', true);
					case ANIMDEFAULT:
						iconP12.animation.play((healthBar.percent > 80 ? 'losing' : 'normal'), true);
					case ANIMWINNING:
						iconP12.animation.play((healthBar.percent > 80 ? 'winning' : (healthBar.percent < 20 ? 'losing' : 'normal')), true);
					default:
						iconP12.animation.curAnim.curFrame = (healthBar.percent < 20 ? 1 : 0);
				}
			}
		}

		doDeathCheck();

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

	public function pausePlayState()
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

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
		FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);

		for (tag in MusicBeatState.getVariables().keys())
			if (tag.contains("_video")) MusicBeatState.getVariables().get(tag).pause();
	}

	public function resumePlayState()
	{
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

		LoadingState.noteCache = [];
		curChart = [];

		ClientPrefs.openChartEditor();
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
			comboManager.songScore = 0;
			comboManager.songMisses = 0;
			comboManager.songHits = 0;
			comboManager.combo = 0;
			comboManager.ratingPercent = 0;
			comboManager.ratingName = "";
			comboManager.ratingFC = "";
			comboManager.RecalculateRating();

			AIPlayMap = AIPlayer.GeneratePlayMap(SONG, AIPlayer.diff);
			comboManager.comboOpp = 0;
			comboManager.AIScore = 0;
			comboManager.AIMisses = 0;
			comboManager.AITotalNotesHit = 0;
			comboManager.AITotalPlayed = 0;
			comboManager.ratingFCAI = "";
			comboManager.ratingNameAI = "";
			comboManager.ratingPercentAI = 0;
			comboManager.RecalculateRatingAI();
		}

		// backend.Threader.runInThread(regenerateNotes(SONG, AIPlayMap), 0, "generateNotes");
		initThreadAlt(regenNotes, 'Regen');
		allNotes = curChart.copy();
		unspawnNotes = curChart.copy();
		eventNotes = curEvents.copy();
		if (loopModeChallenge)
		{
			playbackRate *= loopPlayMult;
			currentRate *= loopPlayMult;
		}

		if (allowSkip)
		{
			if (ClientPrefs.data.skipMode == 'First Note') {
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
			else if (ClientPrefs.data.skipMode == 'First BF Note') {
				if (allNotes.length > 0) {
					for (note in allNotes) {
						if (note != null && note.mustPress && note.strumTime > 100)
						{
							needSkip = true;
							skipTo = note.strumTime - 500;
							break;
						}
						else
						{
							needSkip = false;
						}
					}
				}
			}
		}
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	var killPlayer:Bool;
	public function doDeathCheck(?skipHealthCheck:Bool = false) {
		switch (curHealthMode) {
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

			case "Double":
				killPlayer = health <= 0
				&& !practiceMode
				&& !isDead
				&& gameOverTimer == null;

			case "Lives":
				killPlayer = lives == 0
				&& !practiceMode
				&& !isDead
				&& gameOverTimer == null;

			case "Lives + HealthBar":
				if (lives == 0
				&& !practiceMode
				&& !isDead
				&& gameOverTimer == null) {killPlayer = true; skipHealthCheck = true;}
				if (inArchipelagoMode && archipelago.APPlayState.livecount > 0) archipelago.APPlayState.livecount -= 1;
				else if (lives > 0 && health <= 0 )
				{
					lives -= 1;
					if (ClientPrefs.data.flashing)
					{
						FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100);
					}
					new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
					{
						if (gf != null) gf.playAnim('sad', true);
					});
					FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
					health = 1 / lives * lives;
				}

			case "Lives + Mixtape":
				if (lives == 0
				&& !practiceMode
				&& !isDead
				&& bfkilledcheck
				&& gameOverTimer == null) {killPlayer = true; skipHealthCheck = true;}
				if (inArchipelagoMode && archipelago.APPlayState.livecount > 0) archipelago.APPlayState.livecount -= 1;
				else if (lives > 0 && health <= 0 )
				{
					lives -= 1;
					if (ClientPrefs.data.flashing)
					{
						FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100);
					}
					new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
					{
						if (gf != null) gf.playAnim('sad', true);
					});
					FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
					health = 1 / lives * lives;
				}

			case "Amalgam":
				if (lives == 0
				&& !practiceMode
				&& !isDead
				&& bfkilledcheck
				&& gameOverTimer == null) {killPlayer = true; skipHealthCheck = true;}
				else if (lives > 0 && health <= 0 && bfkilledcheck)
				{
					lives -= 1;
					if (ClientPrefs.data.flashing)
					{
						FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100);
					}
					new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
					{
						if (gf != null) gf.playAnim('sad', true);
					});
					FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
					health = 1 / lives * lives;
				}

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
					Highscore.saveEndlessScore(_cachedSongName, comboManager.songScore);
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

				stagesFunc(function(stage:BaseStage) stage.gameOver());

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

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		triggerEvent(eventName, value1, value2, strumTime);
		//Backwards Compatibilty
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
							boyfriend.shader = null;
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
							dad.shader = null;
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
								gf.shader = null;
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
								dad2.shader = null;
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
								bf2.shader = null;
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

			case 'SetCameraBop': //P-slice event notes
				var val1 = Std.parseFloat(value1);
				var val2 = Std.parseFloat(value2);
				camZoomingMult = !Math.isNaN(val2) ? val2 : 1;
				camZoomingFrequency = !Math.isNaN(val1) ? val1 : 4;

			case 'ZoomCamera': //defaultCamZoom
				var keyValues = value1.split(",");
				if(keyValues.length != 2) {
					trace("INVALID EVENT VALUE");
					return;
				}
				var floaties = keyValues.map(s -> Std.parseFloat(s));
				if(backend.util.ArrayTools.findIndex(floaties,s -> Math.isNaN(s)) != -1) {
					trace("INVALID FLOATIES");
					return;
				}
				var easeFunc = LuaUtils.getTweenEaseByString(value2);
				if(zoomTween != null) zoomTween.cancel();
				var targetZoom = floaties[1]*defaultStageZoom;
				zoomTween = FlxTween.tween(this,{ defaultCamZoom:targetZoom},(Conductor.stepCrochet/1000)*floaties[0],{
					onStart: (x) ->{
						//camZooming = false;
						camZoomingDecay = 7;
					},
					ease: easeFunc,
					onComplete: (x) ->{
						defaultCamZoom = targetZoom;
						camZoomingDecay = 1;
						//camZooming = true;
						zoomTween = null;
					}
				});

			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;

				newMania = Std.parseInt(value1);
				if (Math.isNaN(newMania) && newMania < Note.minMania && newMania > Note.maxMania)
					newMania = 0;
				changeMania(newMania, skipTween);

			case 'Change Mania (Special)':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;
				var prevNote1:Note = null;
				var prevNote2:Note = null;

				// playfields.forEach(function(daPlayfield:PlayField)
				// {
				// 	for (note in allNotes)
				// 		daPlayfield.unqueue(note);
				// });

				if (value1.toLowerCase().trim() == "random")
				{
					newMania = FlxG.random.int(0, 8);
				}
				else
				{
					newMania = Std.parseInt(value1);
				}
				if (Math.isNaN(newMania) && newMania < 0 && newMania > 9)
					newMania = 3;
				notes.forEach(function(daNote:Note)
				{
					daNote.noteData = getNumberFromAnims(daNote.noteData, newMania);
				});
				for (i in 0...allNotes.length)
				{
					if (allNotes[i].mustPress)
					{
						if (!allNotes[i].isSustainNote)
						{
							allNotes[i].noteData = getNumberFromAnims(allNotes[i].noteData, newMania);
							prevNote1 = allNotes[i];
						}
						else if (prevNote1 != null && allNotes[i].isSustainNote)
							allNotes[i].noteData = prevNote1.noteData;
					}
					if (!allNotes[i].mustPress)
					{
						if (!allNotes[i].isSustainNote)
						{
							allNotes[i].noteData = getNumberFromAnims(allNotes[i].noteData, newMania);
							prevNote2 = allNotes[i];
						}
						else if (prevNote2 != null && allNotes[i].isSustainNote)
							allNotes[i].noteData = prevNote2.noteData;
					}
				}
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
				FlxG.save.data.storyWeek = PlayState.storyWeek;
				FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
				FlxG.save.data.difficulties = Difficulty.list; // just in case
				FlxG.save.data.SONG = PlayState.SONG;
				FlxG.save.data.storyDifficulty = PlayState.storyDifficulty;
				FlxG.save.data.songPos = FlxG.sound.music.time;
				FlxG.save.data.score = comboManager.songScore;
				FlxG.save.data.rating = comboManager.ratingPercent;
				FlxG.save.data.misses = comboManager.songMisses;
				FlxG.save.data.health = health;
				FlxG.save.flush();

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
			whosTurn = 'gf';
			callOnScripts('onMoveCamera', ['gf']);
			setOnScripts('whosTurn', whosTurn);
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
			whosTurn = 'dad';
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
			whosTurn = 'dad';
		}
		setOnScripts('whosTurn', whosTurn);
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

	function snapCamFollowToPos(x:Float, y:Float) { // Compat
		camFollow.setPosition(x, y);
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
		var week:String = WeekData.getWeekFileName();
		checkForAchievement([weekNoMiss, week, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'potato', 'debugger', 'play_fnf', 'pico_mixed', 'pico_stressed', 'l', 'a_freaky', 'freaky', 'true_funker', 'nice', 'mfc', 'sfc', 'gfc', 'afc', 'fc', 'sdcb', 'clear', 'erect', 'nightmare']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			LoadingState.noteCache = [];
			curChart = [];
			deathCounter = 0; // set it to 0 AFTER it's been saved
			playbackRate = 1;
			savedTime = 0;

			var accPts = comboManager.ratingPercent * comboManager.totalPlayed;
			var tempActiveTallises = {
				score: comboManager.songScore,
				accPoints: accPts,

				marv: comboManager.ratingsData[0].hits,
				sick: comboManager.ratingsData[1].hits,
				good: comboManager.ratingsData[2].hits,
				bad: comboManager.ratingsData[3].hits,
				shit: comboManager.ratingsData[4].hits,
				missed: comboManager.songMisses,
				combo: comboManager.combo,
				maxCombo: comboManager.combo,
				totalNotesHit: comboManager.totalPlayed,
				totalNotes: 69,
			};

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += comboManager.songScore;
				campaignMisses += comboManager.songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					MusicManager.playMenuMusic();
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

					#if !switch
					var percent:Float = comboManager.ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					Highscore.saveScore(Song.loadedSongName, comboManager.songScore, storyDifficulty, percent, comboManager.songMisses, deathCounter);
					#end
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
					#if !switch
					var percent:Float = comboManager.ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					Highscore.saveScore(Song.loadedSongName, comboManager.songScore, storyDifficulty, percent, comboManager.songMisses, deathCounter);
					#end
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

				if (ClientPrefs.data.ranking == "Mixtape") {
					openSubState(new substates.RankingSubstate());
					#if !switch
					var percent:Float = comboManager.ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					Highscore.saveScore(Song.loadedSongName, comboManager.songScore, storyDifficulty, percent, comboManager.songMisses, deathCounter);
					#end
				} else if (ClientPrefs.data.ranking == "V-Slice") {
					var wasFC = Highscore.getFCState(curSong, PlayState.storyDifficulty);
					var prevScore = Highscore.getScore(curSong, PlayState.storyDifficulty);
					var prevAcc = Highscore.getRating(curSong, PlayState.storyDifficulty);

					var prevRank = Scoring.calculateRankFromData(prevScore, prevAcc, wasFC);

					zoomIntoResultsScreen(prevScore < tempActiveTallises.score, tempActiveTallises, prevRank);

					#if !switch
					var percent:Float = comboManager.ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					Highscore.saveScore(Song.loadedSongName, comboManager.songScore, storyDifficulty, percent, comboManager.songMisses, deathCounter);
					#end
				}
			}
			transitioning = true;
		}
		return true;
	}
	/**
	 * Play the camera zoom animation and then move to the results screen once it's done.
	 */
	function zoomIntoResultsScreen(isNewHighscore:Bool, scoreData:SaveScoreData, prevScoreRank:ScoringRank):Void
	{
		var botplay = ClientPrefs.getGameplaySetting('botplay');
		if (botplay)
		{
			var resultingAccuracy = Math.min(1, scoreData.accPoints / scoreData.totalNotesHit);
			var fpRank:ScoringRank = Scoring.calculateRankFromData(scoreData.score, resultingAccuracy, scoreData.missed == 0) ?? SHIT;
			if (isNewHighscore && !isStoryMode)
			{
				camOther.fade(FlxColor.BLACK, 0.6, false, () ->
				{
					FlxTransitionableState.skipNextTransOut = true;
					states.CategoryState.instaFreeplay = true;
          states.CategoryState.freeplayStuff.fromResults = {
            oldRank: prevScoreRank,
						newRank: fpRank,
						songId: curSong,
						difficultyId: Difficulty.getString(),
						playRankAnim: !botplay
          };
					FlxG.switchState(() -> states.freeplay.VSliceFreeplayState.build());
				});
			}
			else if (!isStoryMode)
			{
				states.CategoryState.instaFreeplay = true;
				states.CategoryState.freeplayStuff.fromResults = {
					oldRank: null,
					playRankAnim: false,
					newRank: fpRank,
					songId: curSong,
					difficultyId: Difficulty.getString()
				};
				openSubState(new StickerSubState(null, (sticker) -> states.freeplay.VSliceFreeplayState.build(null, sticker)));
			}
			else
			{
				openSubState(new StickerSubState(null, (sticker) -> new states.StoryMenuState()));
			}
			return;
		}
		trace('WENT TO RESULTS SCREEN!');

		// If the opponent is GF, zoom in on the opponent.
		// Else, if there is no GF, zoom in on BF.
		// Else, zoom in on GF.
		var targetDad:Bool = dad != null && dad.curCharacter == 'gf';
		var targetBF:Bool = gf == null && !targetDad;

		if (targetBF)
		{
			FlxG.camera.follow(boyfriend, null, 0.05);
		}
		else if (targetDad)
		{
			FlxG.camera.follow(dad, null, 0.05);
		}
		else
		{
			FlxG.camera.follow(gf, null, 0.05);
		}

		// TODO: Make target offset configurable.
		// In the meantime, we have to replace the zoom animation with a fade out.
		FlxG.camera.targetOffset.y -= 350;
		FlxG.camera.targetOffset.x += 20;

		// Replace zoom animation with a fade out for now.
		FlxG.camera.fade(FlxColor.BLACK, 0.6);

		FlxTween.tween(camHUD, {alpha: 0}, 0.6, {
			onComplete: function(_)
			{
				moveToResultsScreen(isNewHighscore, scoreData, prevScoreRank);
			}
		});

		// Zoom in on Girlfriend (or BF if no GF)
		new FlxTimer().start(0.8, function(_)
		{
			if (targetBF)
			{
				boyfriend.animation.play('hey');
			}
			else if (targetDad)
			{
				dad.animation.play('cheer');
			}
			else
			{
				gf.animation.play('cheer');
			}

			// Zoom over to the Results screen.
			// TODO: Re-enable this.
			/*
								FlxTween.tween(FlxG.camera, {zoom: 1200}, 1.1,
					{
						ease: FlxEase.expoIn,
					});
				*/
		});
	}

	/**
		 * Move to the results screen right goddamn now.
		 */
	function moveToResultsScreen(isNewHighscore:Bool, scoreData:SaveScoreData, prevScoreRank:ScoringRank):Void
	{
		persistentUpdate = false;

		var modManifest = Mods.getPack();
		var fpText = modManifest != null ? '${curSong} from ${modManifest.name}' : curSong;
		// Mods.loadTopMod();

		vocals.stop();
		camHUD.alpha = 1;

		var res:substates.ResultState = new substates.ResultState({
			storyMode: isStoryMode,
			songId: curSong,
			difficultyId: Difficulty.getString(),
			title: isStoryMode ? ('${storyCampaignTitle}') : fpText,
			scoreData: scoreData,
			prevScoreRank: prevScoreRank,
			isNewHighscore: isNewHighscore,
			characterId: SONG.player1
		});
		this.persistentDraw = false;
		//FreeplayManager.openFreeplay();
		openSubState(res);
	}

	public function KillNotes()
	{
		notes.clear();
		allNotes = [];
		unspawnNotes = [];
		noteManager.clearAllNotes();
		for (field in playfields)
		{
			field.clearDeadNotes();
			field.spawnedNotes = [];
			field.noteQueue = [[], [], [], []];
		}

		eventNotes = [];
	}

	public var showCombo:Bool = true;
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

		for (rating in comboManager.ratingsData)
			Paths.image(uiFolder + rating.image + uiPostfix);
		for (i in 0...10)
			Paths.image(uiFolder + 'num' + i + uiPostfix);

		// Cache miss sprites and broken combo (wont work if you dont have one though, obviously)
		Paths.image(uiFolder + 'miss' + uiPostfix);
		Paths.image(uiFolder + 'comboBroken' + uiPostfix);
	}

	private function calculateWife3Score(timingError:Float):Float
	{
		var normalizedError:Float = Math.abs(timingError) / comboManager.wife3_maxms;
		var wife3Score:Float = 2.0 * (1.0 - Math.pow(normalizedError, 2));

		return Math.max(0, Math.min(2.0, wife3Score));
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1 * vocalVolumeMultiplier * vocalVolumeMultiplierHardMode;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0 || comboGroup.members.length > 1000)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				spr.destroy();
			}
		}
		if (comboGroup.members.length > 200) comboGroup.clear();

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(comboManager.ratingsData, noteDiff / playbackRate);
		lastJudName = daRating.name;

		// === ACCURACY SYSTEMS ===

		// 1. Wife3 Accuracy System STANDARD (StepMania)
		var noteDiff_ms:Float = Math.abs(noteDiff / playbackRate);
		var noteWifeScore:Float = calculateWife3Score(noteDiff_ms);
		comboManager.wife3Scores.push(noteWifeScore);

		// 2. Psych Engine Accuracy System (Original)
		comboManager.totalNotesHit += daRating.ratingMod;

		// 3. Simple Accuracy System
		if (daRating.name == 'marv' || daRating.name == 'sick' || daRating.name == 'good') {
			comboManager.notesHitSimple++;
		}

		// 4. osu!mania Accuracy System
		switch(daRating.name) {
			case 'marv' | 'sick': comboManager.osuMania_n300++;
			case 'good': comboManager.osuMania_n200++;
			case 'bad': comboManager.osuMania_n100++;
			case 'shit': comboManager.osuMania_n50++;
		}

		// 5. DJMAX Accuracy System
		switch(daRating.name) {
			case 'marv': comboManager.djmax_maxPerfect++;
			case 'sick': comboManager.djmax_perfect++;
			case 'good': comboManager.djmax_great++;
			case 'bad': comboManager.djmax_good++;
			case 'shit': comboManager.djmax_bad++;
		}

		// 6. ITG (Dance Points) System
		// Mapeo de ratings a ventanas ITG
		switch(daRating.name) {
			case 'marv':
				comboManager.itg_FantasticPlus++; // W0
				comboManager.itg_DP += 10; // Máximo score
			case 'sick':
				comboManager.itg_Fantastic++; // W1
				comboManager.itg_DP += 10;
			case 'good':
				comboManager.itg_Excellent++; // W2
				comboManager.itg_DP += 9;
			case 'bad':
				comboManager.itg_Great++; // W3
				comboManager.itg_DP += 5;
			case 'shit':
				comboManager.itg_Decent++; // W4
				comboManager.itg_DP += 2;
		}

		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled && !note.isSustainNote)
			note.field.spawnNoteSplashOnNote(note);

		if (judgementCounter != null) {
			// Determine rating index based on name
			var ratingIndex = -1;
			for (i in 0...comboManager.ratingsData.length) {
				if (comboManager.ratingsData[i] == daRating) {
					ratingIndex = i;
					break;
				}
			}

			if (ratingIndex >= 0) {
				judgementCounter.doBump(ratingIndex);
			}
		}

		if(!cpuControlled) {
			comboManager.songScore += Math.ceil(score * MechanicManager.multiplier);
			if(!note.ratingDisabled)
			{
				comboManager.songHits++;
				comboManager.totalPlayed++;
				comboManager.RecalculateRating(false);
			}
		}

		if (mechanicsMod != null) {
			if (note.mustPress)
				mechanicsMod.changeMorale(daRating.moraleFactor);
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

		// In StepMania charts, make the rating invisible by default
		if (isStepManiaChart) {
			showCombo = false;
			rating.visible = false;
			// Show StepMania judgment instead
			showStepManiaJudgement(daRating.name);
		} else {
			rating.visible = (!ClientPrefs.data.hideHud && showRating);
		}

		if (comboOffsetCustom != null) {
			rating.x = comboOffsetCustom[0];
			rating.y = comboOffsetCustom[1];
		}
		else {
			rating.x += ClientPrefs.data.comboOffset[0];
			rating.y -= ClientPrefs.data.comboOffset[1];
		}
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite();
		comboSpr.loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (comboOffsetCustom != null) {
			comboSpr.x = comboOffsetCustom[4];
			comboSpr.y = comboOffsetCustom[5];
		}
		else {
			comboSpr.x += ClientPrefs.data.comboOffset[4];
			comboSpr.y -= ClientPrefs.data.comboOffset[5];
		}

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

		var separatedScore:String = Std.string(comboManager.combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite();
			numScore.loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90;
			numScore.y += 80;
			if (comboOffsetCustom != null) {
				numScore.x = comboOffsetCustom[2] + (43 * daLoop);
				numScore.y = comboOffsetCustom[3];
			}
			else {
				numScore.x += ClientPrefs.data.comboOffset[2];
				numScore.y -= ClientPrefs.data.comboOffset[3];
			}

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

			FlxTween.tween(numScore, {alpha: 0, angle: FlxG.random.int(-25, 25)}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					if (numScore != null) {
						comboGroup.remove(numScore);
						numScore.destroy();
					}
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		//comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0, angle: FlxG.random.int(-25, 25)}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				if (rating != null) {
					comboGroup.remove(rating);
					rating.destroy();
				}
			},
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0, angle: FlxG.random.int(-25, 25)}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				if (comboSpr != null) {
					comboGroup.remove(comboSpr);
					comboSpr.destroy();
				}
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
		var daRating:Rating = Conductor.judgeNote(comboManager.ratingsData, noteDiff / playbackRate);

		comboManager.totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled && !note.isSustainNote)
			note.field.spawnNoteSplashOnNote(note);

		if(!cpuControlled) {
			comboManager.songScore += score;
			if(!note.ratingDisabled)
			{
				comboManager.songHits++;
				comboManager.totalPlayed++;
				comboManager.RecalculateRating(false);
			}
		}

		// Check Bad and Shit if they break the combo
		if (ClientPrefs.data.badShitBreakCombo && (daRating.name == 'bad' || daRating.name == 'shit'))
		{
			comboManager.combo = 0;
			comboManager.comboBreaks++; // Increase combo breaks counter
			showComboBreak(); // Show broken combo sprite
		}

		if (judgementCounter != null) {
			judgementCounter.doComboBump();

			// If it is a new maximum combo
			if (comboManager.combo > comboManager.maxCombo) {
				judgementCounter.doMaxComboBump();
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

		var comboSpr:FlxSprite = new FlxSprite();
		comboSpr.loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
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

		var separatedScore:String = Std.string(comboManager.combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite();
			numScore.loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
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

	private function showComboBreak():Void
	{
		// If it is StepMania chart, use the SM system for the miss
		if (isStepManiaChart) {
			showStepManiaJudgement('miss');
			return;
		}

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/";
			antialias = !isPixelStage;
		}

		var placement:Float = FlxG.width * 0.35;
		var breakSprite:FlxSprite = new FlxSprite();

		// Determine which image to use
		var imageName:String = ClientPrefs.data.badShitBreakCombo ? 'comboBroken' : 'miss';
		breakSprite.loadGraphic(Paths.image(uiFolder + imageName + uiPostfix));

		breakSprite.screenCenter();
		breakSprite.x = placement - 40;
		breakSprite.y -= 60;
		breakSprite.acceleration.y = 550 * playbackRate * playbackRate;
		breakSprite.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		breakSprite.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		breakSprite.visible = !ClientPrefs.data.hideHud;
		breakSprite.x += ClientPrefs.data.comboOffset[0];
		breakSprite.y -= ClientPrefs.data.comboOffset[1];
		breakSprite.antialiasing = antialias;

		if (!PlayState.isPixelStage)
		{
			breakSprite.setGraphicSize(Std.int(breakSprite.width * 0.7));
		}
		else
		{
			breakSprite.setGraphicSize(Std.int(breakSprite.width * daPixelZoom * 0.85));
		}

		breakSprite.updateHitbox();

		if (!PlayState.isPixelStage)
		{
			breakSprite.scale.set(0.3, 0.3);
			FlxTween.tween(breakSprite.scale, {x: 0.7, y: 0.7}, 0.08, {
				ease: FlxEase.circOut
			});
		}
		else
		{
			breakSprite.scale.set(1, 1);
			FlxTween.tween(breakSprite.scale, {x: 4.5, y: 4.5}, 0.08, {
				ease: FlxEase.circOut
			});
		}

		comboGroup.add(breakSprite);

		FlxTween.tween(breakSprite, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				breakSprite.destroy();
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
	var reverseNoteRules:Bool = false;
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (reverseNoteRules) {
			if (pressed.contains(eventKey))
				pressed.remove(eventKey);

			if (key != -1) strumKeyUp(key);
		} else {
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
	}

	// Update script existence flags for performance optimization
	private function updateScriptFlags():Void {
		#if LUA_ALLOWED
		hasLuaScripts = (luaArray != null && luaArray.length > 0) || (legacyLuaArray != null && legacyLuaArray.length > 0);
		#else
		hasLuaScripts = false;
		#end

		#if HSCRIPT_ALLOWED
		hasHScripts = (hscriptArray != null && hscriptArray.length > 0);
		#else
		hasHScripts = false;
		#end
	}

	private function updateGroupIndices():Void {
		_noteGroupIndex = members.indexOf(noteGroup);
		_gfGroupIndex = members.indexOf(gfGroup);
		_dadGroupIndex = members.indexOf(dadGroup);
		_dadGroup2Index = members.indexOf(dadGroup2);
		_boyfriendGroupIndex = members.indexOf(boyfriendGroup);
		_boyfriendGroup2Index = members.indexOf(boyfriendGroup2);
		_uiGroupIndex = members.indexOf(uiGroup);
	}

	private function keyPressed(key:Int, player:Int = -1)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;
		if (strumsBlocked[key]) return;

		// Early script callback optimization - only call if scripts exist
		if (hasLuaScripts || hasHScripts) {
			var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
			if(ret == LuaUtils.Function_Stop) return;
		}

		// Store original conductor position ONCE
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var hitNotes:Array<Note> = [];
		var controlledFields:Array<PlayField> = [];

		// Pre-filter controlled fields to avoid repeated checks
		for (field in playfields.members) {
			if ((player != -1 && field.playerId != player) || !field.isPlayer || !field.inControl || field.autoPlayed)
				continue;
			controlledFields.push(field);
		}

		// Process all controlled fields
		for (field in controlledFields) {
			field.keysPressed[key] = true;

			if (endingSong) continue;

			var note:Note = null;

			// Optimize script callback - only call if scripts exist and return early if stopped
			if (hasLuaScripts || hasHScripts) {
				var ret:Dynamic = callOnScripts("onFieldInput", [field, key, hitNotes]);
				if (ret == LuaUtils.Function_Stop) {
					note = null;
				} else if (ret is Note) {
					note = ret;
				} else {
					note = field.input(key);
				}
			} else {
				note = field.input(key);
			}

			if (note == null) {
				var spr:StrumNote = field.strumNotes[key];
				if (spr != null) {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			} else {
				hitNotes.push(note);
			}
		}

		// Handle ghost tapping
		if (hitNotes.length == 0) {
			for (field in controlledFields) {
				if (hasLuaScripts || hasHScripts) {
					callOnScripts('onGhostTap', [key, field]);
				}

				if (!ClientPrefs.data.ghostTapping)
					noteMissPress(key, field);
			}
		}

		// Optimize keysPressed tracking with Map
		keysPressedSet[key] = true;
		if(!keysPressed.contains(key)) keysPressed.push(key);

		// Restore conductor position ONCE
		Conductor.songPosition = lastTime;

		// Final script callback - only if scripts exist
		if (hasLuaScripts || hasHScripts) {
			callOnScripts('onKeyPress', [key]);
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	// very innovative?
	private function leftMousePress(event:MouseEvent):Void
	{
		onMousePress(-4);
	}

	private function rightMousePress(event:MouseEvent):Void
	{
		onMousePress(-5);
	}

	private function leftMouseRelease(event:MouseEvent):Void
	{
		onMouseRelease(-4);
	}

	private function rightMouseRelease(event:MouseEvent):Void
	{
		onMouseRelease(-5);
	}

	private function onMousePress(key:Int):Void {
		var keyDirection:Int = getMouseFromEvent(key);

		if (reverseNoteRules) {
			if (keyDirection != -1) strumKeyUp(keyDirection);
		} else {
			if (ClientPrefs.data.inputSystem == "Native-old") {
				if (!controls.controllerMode)
				{
					if (paused || !startedCountdown || inCutscene) return;
					if (keyDirection != -1) strumKeyDown(keyDirection);
				}
			}
			else {
				if (paused || !startedCountdown || inCutscene) return;
				if (callOnScripts("onKeyDown", [keyDirection]) == LuaUtils.Function_Stop) return;

				if (keyDirection > -1)
				{
					var hitNotes:Array<Note> = [];
					var controlledFields:Array<PlayField> = [];

					if (strumsBlocked[keyDirection]) return;
					if (callOnScripts("onKeyPress", [keyDirection]) == LuaUtils.Function_Stop) return;
					for (field in playfields)
					{
						if (!field.autoPlayed && field.isPlayer && field.inControl)
						{
							controlledFields.push(field);
							field.keysPressed[keyDirection] = true;
							if (generatedMusic && !endingSong)
							{
								var note:Note = null;
								var ret:Dynamic = callOnScripts("onFieldInput", [field, keyDirection, hitNotes]);
								if (ret == LuaUtils.Function_Stop) continue;
								else if ((ret.objType == NOTE)) note = ret;
								else note = field.input(key);

								if (note == null)
								{
									var spr:StrumNote = field.strumNotes[keyDirection];
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
							callOnScripts('onGhostTap', [keyDirection]);

							if (!ClientPrefs.data.ghostTapping)
								noteMissPress(keyDirection, field);
						}
					}
				}
			}
		}
	}

	private function onMouseRelease(key:Int):Void
	{
		var direction:Int = getMouseFromEvent(key);
		if (reverseNoteRules) {
			if (paused || !startedCountdown || inCutscene) return;
			if (callOnScripts("onKeyDown", [direction]) == LuaUtils.Function_Stop) return;

			if (direction > -1)
			{
				var hitNotes:Array<Note> = [];
				var controlledFields:Array<PlayField> = [];

				if (strumsBlocked[direction]) return;
				if (callOnScripts("onKeyPress", [direction]) == LuaUtils.Function_Stop) return;
				for (field in playfields.members)
				{
					if (!field.autoPlayed && field.isPlayer && field.inControl)
					{
						controlledFields.push(field);
						field.keysPressed[direction] = true;
						if (generatedMusic && !endingSong)
						{
							var note:Note = null;
							var ret:Dynamic = callOnScripts("onFieldInput", [field, direction, hitNotes]);
							if (ret == LuaUtils.Function_Stop) continue;
							else if ((ret.objType == NOTE)) note = ret;
							else note = field.input(key);

							if (note == null)
							{
								var spr:StrumNote = field.strumNotes[direction];
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
						callOnScripts('onGhostTap', [direction]);

						if (!ClientPrefs.data.ghostTapping)
							noteMissPress(direction, field);
					}
				}
			}
		} else {
			if (direction != -1) strumKeyUp(direction);
		}
		// trace('released: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//if(!controls.controllerMode && key > -1) keyReleased(key);
		if (reverseNoteRules) {
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
		} else {
			if (pressed.contains(eventKey))
				pressed.remove(eventKey);

			if (key != -1) strumKeyUp(key);
		}
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

	public static function getMouseFromEvent(pressed:Int):Int
	{
		if (pressed != -1)
			for (i in 0...keysArray[mania].length)
				for (j in 0...keysArray[mania][i].length)
					if (pressed == keysArray[mania][i][j])
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

	// Cache the parsed arrays to avoid recreating them every frame
	private static var _cachedHoldArray:Array<Bool> = [];
	private static var _cachedPressArray:Array<Bool> = [];
	private static var _cachedReleaseArray:Array<Bool> = [];

	private function keysCheck():Void
	{
		if (ClientPrefs.data.inputSystem == 'Native-old') {
			// Reuse arrays instead of creating new ones
			var holdArray = _cachedHoldArray;
			var pressArray = _cachedPressArray;
			var releaseArray = _cachedReleaseArray;

			// Clear and resize arrays efficiently
			holdArray.splice(0, holdArray.length);
			pressArray.splice(0, pressArray.length);
			releaseArray.splice(0, releaseArray.length);

			var keyArrayLength = keysArray[mania].length;
			holdArray.resize(keyArrayLength);
			pressArray.resize(keyArrayLength);
			releaseArray.resize(keyArrayLength);

			// Use direct indexing instead of push
			for (i in 0...keyArrayLength) {
				var key = keysArray[mania][i];
				holdArray[i] = controls.pressed(key);
				pressArray[i] = controls.justPressed(key);
				releaseArray[i] = controls.justReleased(key);
			}

			// Optimize controller input handling
			if(controls.controllerMode) {
				for (i in 0...pressArray.length) {
					if(pressArray[i] && strumsBlocked[i] != true) {
						keyPressed(i);
					}
				}
			}

			// Optimize hold checking
			if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic) {
				var hasHoldInput = false;
				for (hold in holdArray) {
					if (hold) {
						hasHoldInput = true;
						break;
					}
				}

				if (!hasHoldInput && !endingSong) {
					playerDance();
				}
				#if ACHIEVEMENTS_ALLOWED
				else if (hasHoldInput) {
					checkForAchievement(['oversinging']);
				}
				#end
			}

			// Optimize release handling
			if((controls.controllerMode || strumsBlocked.contains(true))) {
				for (i in 0...releaseArray.length) {
					if(releaseArray[i] || strumsBlocked[i] == true) {
						keyReleased(i);
					}
				}
			}
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

				if (bf2 != null && bf2.holdTimer > Conductor.stepCrochet * 0.001 * bf2.singDuration
					&& bf2.animation.curAnim.name.startsWith('sing')
					&& !bf2.animation.curAnim.name.endsWith('miss'))
					bf2.dance();

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

		switch (note.noteType)
		{
			case 'Kill Note':
				noTriggerKarma = true;
				die();
				COD.setCOD(null, 'Hit a Kill Note.');
				noTriggerKarma = false;
				FlxG.sound.play(Paths.sound('explosion'));

				if (mechanicsResult[1] != null)
					mechanicsResult[1].value += 20;

			case 'Swap Note':
				COD.setCOD(null, 'Failed to tell the difference between your notes and you opponents.');

			case 'Throat Note':
				FlxTween.tween(note.field.strumNotes[note.column], {multAlpha: 0.3}, 1, {
					onComplete: function(n) {
						for (curNote in allNotes) {
							if (curNote.column == note.column)
								note.blockHit = true;
						}

						new FlxTimer().start(FlxG.random.float(3, 10), function(tmr:FlxTimer)
						{
							FlxTween.tween(note.field.strumNotes[note.column], {alpha: 1}, 1);
							for (curNote in allNotes) {
								if (curNote.column == note.column)
									note.blockHit = false;
							}
						});
					}
				});
				COD.setCOD(null, "Couldn't Clear your throat. (Have you tried Throat Medicine?)");
		}

		bfkilledcheck = true;

		var lastCombo:Int = comboManager.combo;
		comboManager.combo = 0;

		switch (curHealthMode) {
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

			case "Amalgam":
				//Basically, don't miss lol
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
				if (!note.isSustainNote) health -= 0.1;
				health -= 0.0475;
				health -= 0.04;
				health -= 0.08;
				health -= subtract * healthLoss;

			default:
				health -= subtract * healthLoss;
		}

		var lastCombo:Int = comboManager.combo;
		comboManager.combo = 0;
		comboManager.comboBreaks++; // Increase combo breaks counter
		showComboBreak(); // Show broken miss/combo sprite

		comboManager.songScore -= 10;
		if(!endingSong) comboManager.songMisses++;
		comboManager.totalPlayed++;

		// Record miss in all accuracy systems

		// Wife3 - Standard FIXED penalty for miss
		// StepMania Wife3 uses -8.0 points for each miss
		var missPenalty:Float = -8.0;
		comboManager.wife3Scores.push(missPenalty);

		// osu!mania - Registrar miss
		comboManager.osuMania_nMiss++;

		// DJMAX - Record miss and reset combo
		comboManager.djmax_miss++;
		comboManager.djmax_combo = 0;

		// ITG - Penalty for miss (-12 DP)
		comboManager.itg_Miss++;
		comboManager.itg_DP -= 12;

		comboManager.RecalculateRating(true);
		if (judgementCounter != null) {
			judgementCounter.doMissBump();
		}

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		if (note != null) {
			if (opponentmode || note.field == dadField)
				char = dad;
			if (note.exNote && note.field == playerField)
				char = bf2;
			if (note.exNote && note.field == dadField)
				char = dad2;
		}

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
		vocals.volume = 0 * vocalVolumeMultiplier * vocalVolumeMultiplierHardMode;

		if (curHealthMode == "Lives" && lives > 0)
		{
			lives -= 1;
			if (ClientPrefs.data.flashing)
			{
				FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100);
			}
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				if (gf != null) gf.playAnim('sad', true);
			});
			FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
			health = 1 / lives * lives;
		}
	}

	public function opponentNoteHit(note:Note, field:PlayField):Void
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
			comboManager.comboOpp += 1;
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
			var char:Character = (opponentmode ? boyfriend : dad);
			var animToPlay:String = Note.keysShit.get(mania).get('singAnims')[note.noteData] + note.animSuffix;
			if(note.gfNote) char = gf;
			if (note.exNote && !note.gfNote) char = (opponentmode ? bf2 : dad2);

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

				if(canPlay) playAnim(note, char, animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if ((curHealthMode == "Tabi" || curHealthMode == "Amalgam") && health > 0)
		{
			health -= 0.04;
			health -= 0.03;
		}

		if (!note.autoGenerated)
		{
			if (MechanicManager.mechanics["hit_hp"].points > 0)
			{
				var lossHealth:Float = FlxMath.remapToRange(MechanicManager.mechanics["hit_hp"].points, 0, 20, note.hitHealth / 4.5, note.hitHealth / 1.5);
				if (note.isSustainNote)
					lossHealth /= 5;
				noTriggerKarma = true;
				if (mechanicsMod != null && mechanicsMod.restoreActivated)
					lastHealth = Math.max(health - lossHealth, minHealth + minHealthOffset + 0.1);
				else
					health = Math.max(health - lossHealth, minHealth + minHealthOffset + 0.1);
				if (mechanicsResult[9] != null)
					mechanicsResult[9].value += lossHealth * 10;
				noTriggerKarma = false;
			}
		}

		if(opponentVocals.length <= 0) vocals.volume = 1 * vocalVolumeMultiplier * vocalVolumeMultiplierHardMode;
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
		if (cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		if (note.expectedData != -1)
			FlxTween.cancelTweensOf(note);

		note.wasGoodHit = true;

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(!note.hitCausesMiss) //Common notes
		{
			if(!note.noAnimation)
			{
				var animToPlay:String = Note.keysShit.get(mania).get('singAnims')[note.noteData] + note.animSuffix;

				var char:Character = (opponentmode ? dad : boyfriend);
				var animCheck:String = 'hey';
				if (note.exNote && !note.gfNote && note.noteType != 'GF Duet') char = (opponentmode ? dad2 : bf2);
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

					if(canPlay) playAnim(note, char, animToPlay, true);
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

			if(!cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false) && !note.botNote)
			{
				var spr = field.strumNotes[note.column];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(field, note.column % field.keyCount, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			vocals.volume = 1 * vocalVolumeMultiplier * vocalVolumeMultiplierHardMode;

			if (!note.isSustainNote)
			{
				comboManager.combo++;
				if(comboManager.combo > comboManager.maxCombo) comboManager.maxCombo = comboManager.combo;

				// DJMAX combo tracking
				comboManager.djmax_combo++;
				if(comboManager.djmax_combo > comboManager.djmax_maxCombo) comboManager.djmax_maxCombo = comboManager.djmax_combo;

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
			if (guitarHeroSustains && note.isSustainNote || (mechanicsMod != null && mechanicsMod.restoreActivated)) gainHealth = false;
			if (gainHealth){
				switch (curHealthMode) {
					case "Kade":
						var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
						var daRating:Rating = Conductor.judgeNote(comboManager.ratingsData, noteDiff / playbackRate);
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

					case "Amalgam":
						var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
						var daRating:Rating = Conductor.judgeNote(comboManager.ratingsData, noteDiff / playbackRate);
						switch (daRating.name)
						{
							case 'shit':
								health -= 0.1;
							case 'bad':
								health -= 0.06;
							case 'sick':
								health += note.hitHealth * healthGain;
							case 'marv':
								if (note.noteData >= 0)
									health += 0.023;
								else
									health += 0.004;
								health += 0.05;
								health += 0.05;
						}
					default:
						health += note.hitHealth * healthGain;
				}
			}

			if (mechanicsMod != null) {
				switch (note.noteType)
				{
					case 'Kill Note':
						noTriggerKarma = true;
						die();
						COD.setCOD(null, 'Hit a Kill Note.');
						noTriggerKarma = false;
						FlxG.sound.play(Paths.sound('explosion'));

						if (mechanicsResult[1] != null)
							mechanicsResult[1].value += 20;
					case 'Restore Note':
						if (mechanicsMod.restoreActivated)
							mechanicsMod.restoreNoteHit();
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
						if (mechanicsResult[0] != null)
							mechanicsResult[0].value += note.missHealth * 10;
						lastKill = 0;
					case 'Kill Note':
						lastKill = 1;
						FlxG.sound.play(Paths.sound('explosion'));
						COD.setCOD(null, 'Hit a Kill Note.');
					case 'Burst Note':
						mechanicsMod.burstNote();
						lastKill = 2;
						COD.setCOD(null, 'Sufficated under pressure.');
					case 'Sleep Note':
						mechanicsMod.sleepNote();
						lastKill = 5;
						COD.setCOD(null, 'Fell asleep and died.');
					case 'Swap Note':
						if (mechanicsResult[6] != null)
							mechanicsResult[6].value += note.missHealth * 10;
						COD.setCOD(null, 'Couldn\'t keep up with the notes.');
					case 'No Animation':
						if (note.autoGenerated && mechanicsResult[7] != null)
							mechanicsResult[7].value += note.missHealth * 10;
						lastKill = 7;
				}
			}

			noteMiss(note, field);
			//if(!note.noteSplashData.disabled && !note.isSustainNote) note.field.spawnNoteSplashOnNote(note);
		}

		if (mechanicsMod != null) {

			if (MechanicManager.mechanics['burst_note'].points == 0 || (mechanicsMod.burstTime == null || mechanicsMod.burstTime.value < mechanicsMod.burstTime.min))
			{
				if (!mechanicsMod.restoreActivated)
					health += note.hitHealth * healthGain;
				else
					lastHealth += note.hitHealth * healthGain;
			}
		}

		bfkilledcheck = false;

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if(!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		if (ClientPrefs.data.useExperimentalNotePool) {
			// Use experimental note pool - DON'T kill the note, just reset and return it
			if (note.field != null)
				note.field.removeNote(note);
			notes.remove(note, true);
			NotePoolManager.returnNote(note); // Note is reset in returnNote
		} else {
			// Use standard note manager
			noteManager.recycleNote(note);
			if (note.field != null)
				note.field.removeNote(note);
			// if its there, remove it
			unspawnNotes.remove(note);
			allNotes.remove(note);

			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function playAnim(note:Note, char:Character, animToPlay:String, ?forceAnim:Bool = false) {
		if(char != null)
		{
			char.holdTimer = 0;
			if (!note.isSustainNote
				&& noteRows[note.mustPress ? 0 : 1][note.row] != null
				&& noteRows[note.mustPress ? 0 : 1][note.row].length > 1
				&& note.noteType != "Ghost Note" && ghostsAllowed) {
				// potentially have jump anims?
				var chord = noteRows[note.mustPress ? 0 : 1][note.row];
				var animNote = chord[0];
				var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + note.animSuffix;
				if (char.mostRecentRow != note.row)
					char.playAnim(realAnim, true);

				if(note.nextNote != null && note.prevNote != null){
					if (note != animNote && !note.nextNote.isSustainNote /* && !note.prevNote.isSustainNote */ && callOnScripts('onGhostAnim', [animToPlay, note]) != LuaUtils.Function_Stop) {
						char.playGhostAnim(chord.indexOf(note), animToPlay, true);
					}else if(note.nextNote.isSustainNote){
						char.playAnim(realAnim, true);
						char.playGhostAnim(chord.indexOf(note), animToPlay, true);

					}
				}
				char.mostRecentRow = note.row;
			}
			else{
				if(note.noteType != "Ghost Note")
					char.playAnim(animToPlay, true);
				else
					char.playGhostAnim(note.noteData, animToPlay, true);
			}
		}
	}

	override function destroy() {
		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		// Clear input optimization variables
		if (keysPressedSet != null) {
			keysPressedSet.clear();
			keysPressedSet = null;
		}
		_cachedHoldArray = null;
		_cachedPressArray = null;
		_cachedReleaseArray = null;

		#if LUA_ALLOWED
		if (luaArray != null && luaArray.length > 0) { //if there's nothing, simply dont.
			for (lua in luaArray)
			{
				if (lua != null) {
					lua.call('onDestroy', []);
					lua.stop();
				}
			}
		}

		if (legacyLuaArray != null && legacyLuaArray.length > 0) { //if there's nothing, simply dont.
			for (lua in legacyLuaArray)
			{
				if (lua != null) {
					lua.call('onDestroy', []);
					lua.stop();
				}
			}
		}
		luaArray = null;
		legacyLuaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		if (hscriptArray != null && hscriptArray.length > 0) { //if there's nothing, simply dont.
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}
		}

		hscriptArray = null;
		#end
		stagesFunc(function(stage:BaseStage) stage.destroy());

		// Clear all note groups and references
		if (unspawnNotes != null) {
			for (note in unspawnNotes) {
				if (note != null) note.destroy();
			}
			unspawnNotes.splice(0, unspawnNotes.length);
			unspawnNotes = null;
		}

		if (notes != null) {
			try {
				notes.forEachAlive(function(note:Note) {
					if (note != null) note.destroy();
				});
				notes.clear();
				notes = null;
			} catch(e) {} //Assume the notes are already destroyed if you can't destroy them
		}

		// Clear strum note references
		if (playerStrums != null) {
			playerStrums.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			playerStrums.clear();
			playerStrums = null;
		}

		if (opponentStrums != null) {
			opponentStrums.forEachAlive(function(strum:StrumNote) {
				if (strum != null) strum.destroy();
			});
			opponentStrums.clear();
			opponentStrums = null;
		}

		if (strumLineNotes != null) {
			strumLineNotes.clear();
			strumLineNotes = null;
		}

		// Clear character references
		if (boyfriend != null) {
			boyfriend.destroy();
			boyfriend = null;
		}
		if (gf != null) {
			gf.destroy();
			gf = null;
		}
		if (dad != null) {
			dad.destroy();
			dad = null;
		}

		// Clear event and callback references
		if (eventNotes != null) {
			eventNotes.splice(0, eventNotes.length);
			eventNotes = null;
		}

		// Clear tween managers
		if (modchartTweens != null) {
			for (tween in modchartTweens) {
				if (tween != null) tween.cancel();
			}
			modchartTweens.clear();
			modchartTweens = null;
		}

		if (modchartTimers != null) {
			for (timer in modchartTimers) {
				if (timer != null) timer.cancel();
			}
			modchartTimers.clear();
			modchartTimers = null;
		}

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}

		// Cleanup synced videos
		for (video in syncedVideos) {
			if (video != null) {
				video.destroy();
			}
		}
		syncedVideos = [];
		queuedSyncedVideos = [];
		#end

		if (mechanicsMod != null) mechanicsMod.luckMechanicDestroy();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.setFilters([]);


		#if FLX_PITCH if (FlxG.sound.music != null) FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		if (threadPool != null) threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;

		NoteSplash.configs.clear();
		mania = 3;

		// Cleanup experimental NotePool system if it was enabled
		if (ClientPrefs.data.useExperimentalNotePool) {
			NotePoolManager.forceCleanup(); // Aggressive cleanup on exit
			trace("Experimental NotePool system cleaned up aggressively");
		}

		// yutautil.MemoryHelper.freeMemory(this);
		mechanicsMod = null;
		moveStrumSections = [];
		instance = null;
		variables = null;
		keysArray = null;

		super.destroy();
		endingSong = true;
		//Paths.clearStoredWithoutStickers();

		// Reload the save data as proper.
		if (clientSaveData != null) {
			ClientPrefs.data = clientSaveData;
			clientSaveData = null;
		}
		trace("Done destroy.");
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

	var ssLerpTween:FlxTween = null;
	public function lerpSongSpeed(num:Float, time:Float, ?staticLines:Bool = true):Void
	{
		if (ssLerpTween != null) {
			ssLerpTween.cancel();
			ssLerpTween.destroy();
		}

		ssLerpTween = FlxTween.num(playbackRate, num, time, {ease: FlxEase.sineInOut}, function(value:Float)
		{
			playbackRate = value * currentRate;
			resyncVocals();
			ssLerpTween.destroy();
		});

		if (staticLines) {
			var staticLinesNum = FlxG.random.int(3, 5);
			for (i in 0...staticLinesNum)
			{
				var startPos = FlxG.random.float(0, FlxG.height);
				var endPos = FlxG.random.float(0, FlxG.height);

				var line:FlxSprite = new FlxSprite();
				line.loadGraphic("effects/staticline");
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
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if ((curBeat % 32 == 0 && RandomSpeedChange || curBeat % 8 == 0 && RandomSpeedChange && RandomSpeedChangeWild) && !songAboutToLoop)
		{
			// goes up to 3x speed cuz screw you thats why
			var randomSpeed = RandomSpeedChangeWild ? FlxG.random.float(0.2, 10) * (FlxG.random.bool(10) ? FlxG.random.float(2, 10) : 1) : FlxG.random.float(0.45, 2);
			var randomShit = FlxMath.roundDecimal(randomSpeed, 2);
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

			case 'Dave and Bambi':
				final funny:Float = Math.max(Math.min(healthBar.percent,(MaxHP/0.95)),0.1);

				//health icon bounce but epic
				if (!opponentmode)
				{
					iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + 0.1))),Std.int(iconP1.height - (25 * funny)));
					if (iconP12 != null) iconP12.setGraphicSize(Std.int(iconP12.width + (50 * (funny + 0.1))),Std.int(iconP12.height - (25 * funny)));
					iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP2.height - (25 * ((2 - funny) + 0.1))));
					if (iconP22 != null) iconP22.setGraphicSize(Std.int(iconP22.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP22.height - (25 * ((2 - funny) + 0.1))));
				} else {
					iconP2.setGraphicSize(Std.int(iconP2.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
					if (iconP22 != null) iconP22.setGraphicSize(Std.int(iconP22.width + (50 * funny)),Std.int(iconP22.height - (25 * funny)));
					iconP1.setGraphicSize(Std.int(iconP1.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP1.height - (25 * ((2 - funny) + 0.1))));
					if (iconP12 != null) iconP12.setGraphicSize(Std.int(iconP12.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP12.height - (25 * ((2 - funny) + 0.1))));
				}

			case 'Old Psych':
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				if (iconP12 != null) iconP1.setGraphicSize(Std.int(iconP12.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
				if (iconP22 != null) iconP22.setGraphicSize(Std.int(iconP22.width + 30));

			case 'Strident Crisis':
				final funny:Float = (healthBar.percent * 0.01) + 0.01;

				//health icon bounce but epic
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (2 + funny))),Std.int(iconP2.height - (25 * (2 + funny))));
				if (iconP12 != null) iconP12.setGraphicSize(Std.int(iconP12.width + (50 * (2 + funny))),Std.int(iconP12.height - (25 * (2 + funny))));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));
				if (iconP22 != null) iconP22.setGraphicSize(Std.int(iconP22.width + (50 * (2 - funny))),Std.int(iconP22.height - (25 * (2 - funny))));

				iconP1.scale.set(1.1, 0.8);
				if (iconP12 != null) iconP12.scale.set(1.1, 0.8);
				iconP2.scale.set(1.1, 0.8);
				if (iconP22 != null) iconP22.scale.set(1.1, 0.8);

				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				if (iconP12 != null) FlxTween.angle(iconP12, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				if (iconP22 != null) FlxTween.angle(iconP22, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});

				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				if (iconP12 != null) FlxTween.tween(iconP12, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				if (iconP22 != null) FlxTween.tween(iconP22, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});

			case 'Plank Engine':
				iconP1.scale.x = 1.3;
				iconP1.scale.y = 0.75;
				if (iconP12 != null) iconP12.scale.x = 1.3;
				if (iconP12 != null) iconP12.scale.y = 0.75;
				iconP2.scale.x = 1.3;
				iconP2.scale.y = 0.75;
				if (iconP22 != null) iconP22.scale.x = 1.3;
				if (iconP22 != null) iconP22.scale.y = 0.75;
				FlxTween.cancelTweensOf(iconP1);
				FlxTween.cancelTweensOf(iconP2);
				if (iconP12 != null) FlxTween.cancelTweensOf(iconP12);
				if (iconP22 != null) FlxTween.cancelTweensOf(iconP22);
				FlxTween.tween(iconP1, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				FlxTween.tween(iconP2, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				if (iconP12 != null) FlxTween.tween(iconP12, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				if (iconP22 != null) FlxTween.tween(iconP22, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				if (curBeat % 4 == 0) {
					iconP1.offset.x = 10;
					iconP2.offset.x = -10;
					if (iconP12 != null) iconP12.offset.x = 10;
					if (iconP22 != null) iconP22.offset.x = -10;
					iconP1.angle = -15;
					iconP2.angle = 15;
					if (iconP12 != null) iconP12.angle = -15;
					if (iconP22 != null) iconP22.angle = 15;
					FlxTween.tween(iconP1, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
					FlxTween.tween(iconP2, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
					if (iconP12 != null) FlxTween.tween(iconP12, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
					if (iconP22 != null) FlxTween.tween(iconP22, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
				}

			case 'Golden Apple':
				if (curBeat % gfSpeed == 0) {
					curBeat % (gfSpeed * 2) == 0 * playbackRate ? {
					iconP1.scale.set(1.1, 0.8);
					iconP2.scale.set(1.1, 1.3);
					if (iconP12 != null) iconP12.scale.set(1.1, 0.8);
					if (iconP22 != null) iconP22.scale.set(1.1, 1.3);

					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					if (iconP12 != null) FlxTween.angle(iconP12, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					if (iconP22 != null) FlxTween.angle(iconP22, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						if (iconP12 != null) iconP12.scale.set(1.1, 1.3);
						if (iconP22 != null) iconP22.scale.set(1.1, 0.8);

						FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
						if (iconP22 != null) FlxTween.angle(iconP22, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
						if (iconP12 != null) FlxTween.angle(iconP12, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					}

					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					if (iconP12 != null) FlxTween.tween(iconP12, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					if (iconP22 != null) FlxTween.tween(iconP22, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				}

			case 'VS Steve':
				if (curBeat % gfSpeed == 0)
				{
					curBeat % (gfSpeed * 2) == 0 ?
					{
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
						if (iconP12 != null) iconP12.scale.set(1.1, 0.8);
						if (iconP22 != null) iconP22.scale.set(1.1, 1.3);
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						if (iconP12 != null) iconP12.scale.set(1.1, 1.3);
						if (iconP22 != null) iconP22.scale.set(1.1, 0.8);
						FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
						if (iconP12 != null) FlxTween.angle(iconP12, -15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
						if (iconP22 != null) FlxTween.angle(iconP22, 15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
					}

					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
					if (iconP12 != null) FlxTween.tween(iconP12, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
					if (iconP22 != null) FlxTween.tween(iconP22, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				}
		}

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		if (dad2 != null)
			iconP22.updateHitbox();
		if (iconP12 != null)
			iconP12.updateHitbox();

		characterBopper(curBeat);

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms && (curBeat % camZoomingFrequency) == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}

		super.beatHit();
		lastBeatHit = curBeat;

		#if MECHANICS_MOD_ALLOWED
		if (mechanicsMod != null) {
			if (curBeat % 4 == 0)
			{
				if (generatedMusic && PlayState.SONG.notes[Std.int(curBeat / 4)] != null && !endingSong)
				{
					if (MechanicManager.mechanics['restore_note'].points > 0)
					{
						if (FlxG.random.bool(FlxMath.remapToRange(MechanicManager.mechanics['restore_note'].points, 0, 20, 0, 10)))
						{
							mechanicsMod.restoreNote();
							// trace('we\'re gonna check donations to see who activated the great reset');
						}
					}

					mechanicsMod.letterMechanic();
				}
			}


			if (MechanicManager.mechanics['strum_swap'].points > 0)
			{
				if (generatedMusic && PlayState.SONG.notes[Math.floor(curBeat / 4)] != null && !endingSong)
				{
					if (mechanicsMod.wasSwapped && curBeat % 4 == 0)
					{
						mechanicsMod.swapCooldown--;
						if (mechanicsMod.swapCooldown < 0)
							mechanicsMod.swapCooldown = 0;
					}

					if (moveStrumSections[Math.floor(curBeat / 4)] != null && curBeat % 4 == 0)
					{
						if (moveStrumSections[Math.floor(curBeat / 4)] == true)
						{
							mechanicsMod.swapStrums();
						}
						else if (mechanicsMod.swapCooldown == 0 && mechanicsMod.wasSwapped)
						{
							mechanicsMod.swapStrums();
						}
					}
				}
			}
		}
		#end

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
			if(bf2.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * bf2.singDuration && anim2.startsWith('sing') && !anim2.endsWith('miss')) {
				bf2.dance();
			}
		}
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

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

			(shouldUseLegacyLua() ? new LegacyFunkinLua(luaToLoad) : new FunkinLua(luaToLoad));
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
			if (newScript.exists('onCreate')) {
				newScript.call('onCreate');
			}
			if (newScript.exists('onLoad')) {
				newScript.call('onLoad');
			}
			//trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
			updateScriptFlags(); // Update script existence flags when adding HScript
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
		updateScriptFlags(); // Update flags regardless of success/failure
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		// Early exit if no scripts exist
		if (!hasLuaScripts && !hasHScripts) {
			return LuaUtils.Function_Continue;
		}

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
		if ((luaArray != null || legacyLuaArray != null) && (luaArray.length > 0 || legacyLuaArray.length > 0)) {
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
		if (luaArray != null && luaArray.length > 0) {
			for (script in luaArray) {
				if(exclusions.contains(script.scriptName))
					continue;

				script.set(variable, arg);
			}
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		if (hscriptArray != null && hscriptArray.length > 0) {
			for (script in hscriptArray) {
				if(exclusions.contains(script.origin))
					continue;

				script.set(variable, arg);
			}
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

	// gonna keep these two just in case i still need em but i dont think i do anymore
	public var strumOffsetbcauseitsstupid:Float = 0;
	public var strumOffsetspacebcauseitsstupid:Float = 0;

	public var altNoteMove:Bool = false;
	public var ModchartScrollType:Int = 0; // 0 = none, 1 = Downscroll, 3 = Rotate.
	public var curDownscroll:Bool = ClientPrefs.data.downScroll; // Used to check if the downscroll has changed.
	public function modchartSync(directChange:Bool = false):Void {
		for (strumNote in strumLineNotes.members) {
			if (strumNote != null) {
				for (field in playfields.members) {
					if (field.strumNotes.contains(strumNote)) {
						var i = field.strumNotes.indexOf(strumNote);
						if (i != -1) {
							if (directChange) {
								// Directly change the x, y, angle, and alpha of the strumNote in the field
								strumNote.x = field.baseXPositions[i];
								strumNote.y = field.getBaseY(i);
								strumNote.angle = modManager.getValue('localRotate${i}', field.playerId);
								// strumNote.alpha = modManager.getValue('alpha${i}', field.playerId);
							} else {
								// Sync X position
								var offsetX = strumNote.x - field.getBaseX(i);
								modManager.setValue('transform${i}X', (altNoteMove ? strumNote.x : offsetX) - (strumOffsetspacebcauseitsstupid * i) - strumOffsetbcauseitsstupid, field.playerId);
								//strumNote.x = strumNote.x;

								// Sync Y position
								var baseY = field.getBaseY(i);
								var offsetY = strumNote.y - baseY;

								// Only sync if the strum is close to its expected position
								// This prevents overriding custom positions set by scripts
								if (Math.abs(offsetY) < 100) { // Allow some tolerance for modchart transforms
									modManager.setValue('transform${i}Y', offsetY, field.playerId);
								} else {
									// If the strum has been moved significantly, update the base position
									//trace('ModchartSync: Strum ${i} moved significantly (${Math.abs(offsetY)}px), updating base Y from ${baseY} to ${strumNote.y}');
									field.updateBaseYPosition(i, strumNote.y);
								}
								//strumNote.y = strumNote.y;

								// Sync angle
								//modManager.setValue('note${i}Angle', strumNote.angle, field.playerId);
								//strumNote.angle = strumNote.angle;

								// Downscroll.
								if (ModchartScrollType == 1) {
									modManager.setValue('reverse${i}', strumNote.downScroll ? 1 : 0, field.playerId);
								} else if (ModchartScrollType == 2 && curDownscroll != ClientPrefs.data.downScroll) {
									// Invert the direction of strumNote by adding 180 degrees to its current direction
									modManager.setValue('local${i}rotateX', (strumNote.direction + 180) % 360, field.playerId);
									curDownscroll = ClientPrefs.data.downScroll;
								} else {
									// Nothing.
								}

								// // Sync alpha
								// modManager.setValue('alpha${i}', strumNote.alpha, field.playerId);
								// strumNote.alpha = strumNote.alpha;
							}
						}
					}
				}
			}
		}
	}


	public function applyModchartTransform(property:String, value:Float, noteData:Int, player:Int, field:PlayField):Void {
		// Calculate offsets based on property
		switch (property.toLowerCase()) {
			case "x":
				var baseX:Float = field.baseXPositions[noteData];
				var offsetX = value - baseX;

				// Apply the transform while preserving any alternate (-a) transforms
				var currentAltValue = modManager.getValue('transform${noteData}X-a', player);
				modManager.setValue('transform${noteData}X', offsetX - currentAltValue, player);

				trace('Legacy Script -> Modchart: Strum ${noteData} X changed: base=${baseX}, new=${value}, transform=${offsetX - currentAltValue}');

			case "y":
				var baseY:Float = field.getBaseY(noteData);
				var offsetY = value - baseY;

				var currentAltValue = modManager.getValue('transform${noteData}Y-a', player);
				modManager.setValue('transform${noteData}Y', offsetY - currentAltValue, player);

				trace('Legacy Script -> Modchart: Strum ${noteData} Y changed: base=${baseY}, new=${value}, transform=${offsetY - currentAltValue}');

			case "angle":
				// For angles, we can use the builtin localRotate modifier
				modManager.setValue('localRotate${noteData}', value, player);

				trace('Legacy Script -> Modchart: Strum ${noteData} angle changed: new=${value}');

			case "alpha":
				// For alpha, use the alpha modifier while preserving alternate values
				var currentAltValue = modManager.getValue('alpha${noteData}-a', player);
				modManager.setValue('alpha${noteData}', value - currentAltValue, player);

				trace('Legacy Script -> Modchart: Strum ${noteData} alpha changed: new=${value}');

			default:
				trace('Unsupported property for modchart propagation: ${property}');
		}
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
						unlock = (comboManager.ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (comboManager.ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing && ClientPrefs.data.framerate == 30);

						// The ultimate potato gamer
					case 'potato':
						unlock = (!ClientPrefs.data.shaders
							&& ClientPrefs.data.lowQuality
							&& ClientPrefs.data.trashMode
							&& !ClientPrefs.data.antialiasing
							&& ClientPrefs.data.framerate <= 30
							&& !ClientPrefs.data.unlockFramerate
							&& !ClientPrefs.data.comboStacking
							&& !ClientPrefs.data.opponentStrums
							&& !ClientPrefs.data.gimmicksAllowed
							&& !ClientPrefs.data.modcharts
							&& ClientPrefs.data.hitsoundVolume == 0
							&& !ClientPrefs.data.doubleGhosts
							&& !ClientPrefs.data.stageGimmick
							&& ClientPrefs.data.optimizeHolds
							&& ClientPrefs.data.holdSubdivs == 1
							&& ClientPrefs.data.drawDistanceModifier == 0.8
							&& !ClientPrefs.data.allowVis
							&& !ClientPrefs.data.allowEvents);

					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);

					case 'play_fnf':
						unlock = !usedPractice;

					case 'pico_mixed':
						unlock = (!usedPractice && songName.contains("(pico-mix)"));

					case 'pico_stressed':
						unlock = (!usedPractice && songName == "stress-(pico-mix)");

					case 'l':
						unlock = (!usedPractice && (deathCounter >= 30 || CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) == 0));

					case 'a_freaky':
						unlock = (!usedPractice && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) >= 96.50);

					case 'freaky':
						unlock = (!usedPractice && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) >= 99.70);

					case 'true_funker':
						unlock = (!usedPractice && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) >= 99.9935);

					case 'nice':
						unlock = (!usedPractice && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) == 69);

					case 'mfc':
						unlock = (!usedPractice && comboManager.ratingFC == "[Marvioulus Full Combo]");

					case 'sfc':
						unlock = (!usedPractice && comboManager.ratingFC == "[Sick Full Combo]");

					case 'gfc':
						unlock = (!usedPractice && comboManager.ratingFC == "[Good Full Combo]");

					case 'afc':
						unlock = (!usedPractice && comboManager.ratingFC == "[Accurate Full Combo]");

					case 'fc':
						unlock = (!usedPractice && comboManager.ratingFC == "[Full Combo]");

					case 'sdcb':
						unlock = (!usedPractice && comboManager.ratingFC == "[Single Digit Combo Break]");

					case 'clear':
						unlock = (!usedPractice && comboManager.ratingFC == "[Ok I guess...]");

					case 'erect':
						unlock = (!usedPractice && (Difficulty.getString(storyDifficulty).toLowerCase() == 'erect' || Difficulty.getString(storyDifficulty).toLowerCase() == 'nightmare'));

					case 'nightmare':
						unlock = (!usedPractice && Difficulty.getString(storyDifficulty).toLowerCase() == 'nightmare' && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) >= 100);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + comboManager.songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			// Beating the week achievements
			if (name == WeekData.getWeekFileName()) {
				if(isStoryMode && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
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
		});
	}

	/**
	 * Register dynamic song scripting functions with loaded scripts
	 */
	function registerDynamicSongScripting():Void
	{
		#if LUA_ALLOWED
		// Register functions with all Lua scripts
		for (script in luaArray)
		{
			DynamicSongScripting.registerLuaFunctions(script);
		}
		for (script in legacyLuaArray)
		{
			// For legacy scripts, we'll need to manually add the functions
			// This is a simplified approach
			script.set("isDynamicSong", function():Bool {
				return DynamicSongManager.instance != null && DynamicSongManager.instance.isActive;
			});
		}
		#end

		#if HSCRIPT_ALLOWED
		// Register functions with all HScript scripts
		for (script in hscriptArray)
		{
			DynamicSongScripting.registerHScriptFunctions(script);
		}
		#end

		trace('PlayState: Registered dynamic song scripting functions with ${luaArray != null ? luaArray.length : 0} Lua scripts and ${hscriptArray != null ? hscriptArray.length : 0} HScript scripts');
	}

	/**
	 * Update dynamic song manager if active
	 */
	function updateDynamicSong():Void
	{
		if (DynamicSongManager.instance != null && DynamicSongManager.instance.isActive)
		{
			DynamicSongManager.instance.update(Conductor.songPosition);
		}
	}
} //
typedef MechanicResults =
{
	var value:Float;
	var text:String;
	var name:String;
}
