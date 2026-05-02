package states;


/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, you have multiple options:
 * - Create a script file: stages/[stagename].hx (HScript - highest priority)
 * - Create a Lua file: stages/[stagename].lua (Lua - second priority)
 * - Create a YScript file: stages/[stagename].ys (YScript - third priority)
 * - Or add it to VSliceLoader.addstage() for hardcoded stage support (fallback)
 *
 * The engine will only load ONE stage file (the most relevant one found) to avoid conflicts.
 * Priority order: HScript → Lua → YScript → VSliceLoader
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

@:noScripting
class PlayState extends MusicBeatState
{
	public var dad(get, set):Character;
	public var dad2(get, set):Character;
	public var gf(get, set):Character;
	public var boyfriend(get, set):Character;
	public var bf2(get, set):Character;

	private function get_dad():Character {
		return mcm.dad;
	}
	private function get_dad2():Character {
		return mcm.dad2;
	}
	private function get_gf():Character {
		return mcm.gf;
	}
	private function get_boyfriend():Character {
		return mcm.boyfriend;
	}
	private function get_bf2():Character {
		return mcm.bf2;
	}

	private function set_dad(value:Character):Character {
		return mcm.dad = value;
	}
	private function set_dad2(value:Character):Character {
		return mcm.dad2 = value;
	}
	private function set_gf(value:Character):Character {
		return mcm.gf = value;
	}
	private function set_boyfriend(value:Character):Character {
		return mcm.boyfriend = value;
	}
	private function set_bf2(value:Character):Character {
		return mcm.bf2 = value;
	}

	public var boyfriendMap(get, default):Map<String, Character>;
	public var boyfriendMap2(get, default):Map<String, Character> = new Map<String, Character>();
	public var dadMap(get, default):Map<String, Character> = new Map<String, Character>();
	public var dadMap2(get, default):Map<String, Character> = new Map<String, Character>();
	public var gfMap(get, default):Map<String, Character> = new Map<String, Character>();
	private function get_boyfriendMap():Map<String, Character> {
		return mcm.characterMap.get("boyfriendMap");
	}
	private function get_boyfriendMap2():Map<String, Character> {
		return mcm.characterMap.get("boyfriendMap2");
	}
	private function get_dadMap():Map<String, Character> {
		return mcm.characterMap.get("dadMap");
	}
	private function get_dadMap2():Map<String, Character> {
		return mcm.characterMap.get("dadMap2");
	}
	private function get_gfMap():Map<String, Character> {
		return mcm.characterMap.get("gfMap");
	}

	public var boyfriendGroup(get, default):FlxSpriteGroup;
	public var boyfriendGroup2(get, default):FlxSpriteGroup;
	public var dadGroup(get, default):FlxSpriteGroup;
	public var dadGroup2(get, default):FlxSpriteGroup;
	public var gfGroup(get, default):FlxSpriteGroup;
	private function get_boyfriendGroup():FlxSpriteGroup {
		return mcm.characterGroupMap.get("boyfriendMap");
	}
	private function get_boyfriendGroup2():FlxSpriteGroup {
		return mcm.characterGroupMap.get("boyfriendGroup2");
	}
	private function get_dadGroup():FlxSpriteGroup {
		return mcm.characterGroupMap.get("dadGroup");
	}
	private function get_dadGroup2():FlxSpriteGroup {
		return mcm.characterGroupMap.get("dadGroup2");
	}
	private function get_gfGroup():FlxSpriteGroup {
		return mcm.characterGroupMap.get("gfGroup");
	}

	public var BF_X(get, set):Float;
	public var BF_Y(get, set):Float;
	public var BF2_X(get, set):Float;
	public var BF2_Y(get, set):Float;
	public var DAD_X(get, set):Float;
	public var DAD_Y(get, set):Float;
	public var DAD2_X(get, set):Float;
	public var DAD2_Y(get, set):Float;
	public var GF_X(get, set):Float;
	public var GF_Y(get, set):Float;
	private function get_BF_X():Float {
		return mcm.BF_X;
	}
	private function get_BF_Y():Float {
		return mcm.BF_Y;
	}
	private function get_BF2_X():Float {
		return mcm.BF2_X;
	}
	private function get_BF2_Y():Float {
		return mcm.BF2_Y;
	}
	private function get_DAD_X():Float {
		return mcm.DAD_X;
	}
	private function get_DAD_Y():Float {
		return mcm.DAD_Y;
	}
	private function get_DAD2_X():Float {
		return mcm.DAD2_X;
	}
	private function get_DAD2_Y():Float {
		return mcm.DAD2_Y;
	}
	private function get_GF_X():Float {
		return mcm.GF_X;
	}
	private function get_GF_Y():Float {
		return mcm.GF_Y;
	}

	private function set_BF_X(value:Float):Float {
		return mcm.BF_X = value;
	}
	private function set_BF_Y(value:Float):Float {
		return mcm.BF_Y = value;
	}
	private function set_BF2_X(value:Float):Float {
		return mcm.BF2_X = value;
	}
	private function set_BF2_Y(value:Float):Float {
		return mcm.BF2_Y = value;
	}
	private function set_DAD_X(value:Float):Float {
		return mcm.DAD_X = value;
	}
	private function set_DAD_Y(value:Float):Float {
		return mcm.DAD_Y = value;
	}
	private function set_DAD2_X(value:Float):Float {
		return mcm.DAD2_X = value;
	}
	private function set_DAD2_Y(value:Float):Float {
		return mcm.DAD2_Y = value;
	}
	private function set_GF_X(value:Float):Float {
		return mcm.GF_X = value;
	}
	private function set_GF_Y(value:Float):Float {
		return mcm.GF_Y = value;
	}

	// Charts, Playfields, and Notes Manager
	public var SONG(get, never):SwagSong;
	public var mania(get, never):Array<Int>;
	public var notes(get, default):FlxTypedGroup<Note>;
	public var unspawnNotes(get, default):Array<Note>;
	public var eventNotes(get, default):Array<EventNote>;
	public var curEvents(get, default):Array<EventNote>;

	public var strumLineNotes(get, default):FlxTypedGroup<StrumNote>;
	public var opponentStrums(get, default):FlxTypedGroup<StrumNote>;
	public var playerStrums(get, default):FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes(get, default):FlxTypedGroup<NoteSplash>;

	public var modManager(get, never):ModManager;
	public var notefields(get, never):NotefieldRenderer;
	public var playfields(get, never):FlxTypedGroup<PlayField>;
	public var allNotes(get, default):Array<Note>; // all notes
	public var playerField(get, set):PlayField;
	public var dadField(get, set):PlayField;

	public var fmManager(get, set):Manager;

	public var cpuControlled(get, set):Bool;
	public var curSong(get, set):String;
	public var songSpeedType(get, never):String;
	public var songSpeedTween:FlxTween;
	public var songSpeed(get, set):Float;

	public var chartModifier(get, set):String;
	public var convertMania(get, set):Int;
  public var opponentmode(get, set):Bool;
	public var bothMode(get, set):Bool;
  public var RandomSpeedChange(get, set):Bool;
	public var RandomSpeedChangeWild(get, set):Bool;

	private function get_SONG():SwagSong {
		return PlayfieldManager.SONG;
	}
	private function get_mania():Array<Int> {
		return PlayfieldManager.mania;
	}
	private function get_notes():FlxTypedGroup<Note> {
		return playfield.notes;
	}
	private function get_unspawnNotes():Array<Note> {
		return playfield.unspawnNotes;
	}
	private function get_eventNotes():Array<EventNote> {
		return playfield.eventNotes;
	}
	private function get_curEvents():Array<EventNote> {
		return playfield.curEvents;
	}
	private function get_strumLineNotes():FlxTypedGroup<StrumNote> {
		return playfield.strumLineNotes;
	}
	private function get_opponentStrums():FlxTypedGroup<StrumNote> {
		return playfield.opponentStrums;
	}
	private function get_playerStrums():FlxTypedGroup<StrumNote> {
		return playfield.playerStrums;
	}
	private function get_grpNoteSplashes():FlxTypedGroup<NoteSplash> {
		return playfield.grpNoteSplashes;
	}

	private function get_cpuControlled():Bool {
		return playfield.cpuControlled;
	}
	private function set_cpuControlled(value:Bool):Bool {
		playfield.cpuControlled = value;
		return value;
	}
	private function get_curSong():String {
		return playfield.curSong;
	}
	private function set_curSong(value:String):String {
		playfield.curSong = value;
		return value;
	}
	private function get_songSpeedType():String {
		return playfield.songSpeedType;
	}
	private function get_songSpeed():Float {
		return playfield.songSpeed;
	}
	private function set_songSpeed(value:Float):Float {
		playfield.songSpeed = value;
		return value;
	}

	private function get_chartModifier():String {
		return playfield.chartModifier;
	}
	private function set_chartModifier(value:String):String {
		return playfield.chartModifier = value;
	}
	private function get_convertMania():Int {
		return playfield.convertMania;
	}
	private function set_convertMania(value:Int):Int {
		return playfield.convertMania = value;
	}
	private function get_opponentmode():Bool {
		return playfield.opponentmode;
	}
	private function set_opponentmode(value:Bool):Bool {
		return playfield.opponentmode = value;
	}
	private function get_bothMode():Bool {
		return playfield.bothMode;
	}
	private function set_bothMode(value:Bool):Bool {
		return playfield.bothMode = value;
	}
	private function get_RandomSpeedChange():Bool {
		return playfield.RandomSpeedChange;
	}
	private function set_RandomSpeedChange(value:Bool):Bool {
		return playfield.RandomSpeedChange = value;
	}
	private function get_RandomSpeedChangeWild():Bool {
		return playfield.RandomSpeedChangeWild;
	}
	private function set_RandomSpeedChangeWild(value:Bool):Bool {
		return playfield.RandomSpeedChangeWild = value;
	}

	private function get_modManager():ModManager {
		return playfield.modManager;
	}
	private function get_notefields():NotefieldRenderer {
		return playfield.notefields;
	}
	private function get_playfields():FlxTypedGroup<PlayField> {
		return playfield.playfields;
	}
	private function get_allNotes():Array<Note> {
		return playfield.allNotes;
	}
	private function get_playerField():PlayField {
		return playfield.playerField;
	}
	private function set_playerField(value:PlayField):PlayField {
		playfield.playerField = value;
		return value;
	}
	private function get_dadField():PlayField {
		return playfield.dadField;
	}
	private function set_dadField(value:PlayField):PlayField {
		playfield.dadField = value;
		return value;
	}

	private function get_fmManager():Manager {
		return playfield.fmManager;
	}
	private function set_fmManager(value:Manager):Manager {
		playfield.fmManager = value;
		return value;
	}


	//event variables
	public var isCameraOnForcedPos:Bool = false;

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public var yscriptArray:Array<YScript> = [];



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

	public var playbackRate(default, set):Float = 1;
	public var currentRate:Float = 1;

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

	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	//Playlist Stuff
	public static var isWarmUp:Bool = false;
	public static var isPlaylist:Bool = false;
	public var curPlaylist:PlaylistMetadata = null;
	public var curSonglist:Array<PlaylistSongMetadata> = [];

	// ! new shit P-Slice
	public static var storyCampaignTitle = "";
	public static var altInstrumentals:String = null;
	public static var storyDifficultyColor = FlxColor.GRAY;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;
	public var gfVocals:FlxSound;

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingFrequency:Float = 4;
	public var camZoomingDecay:Float = 1;

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
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

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
	private var zoomTween:FlxTween;
	private var camTween:FlxTween;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

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

	// Optimized input tracking
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Script existence flags for performance
	public var hasLuaScripts:Bool = false;
	public var hasHScripts:Bool = false;
	public var hasPyScripts:Bool = false;
	public var hasYScripts:Bool = false;

	// === PERFORMANCE OPTIMIZATION INFRASTRUCTURE ===
	// Cached calculations and frequently accessed values
	private var _cachedPlaybackRate:Float = 1;
	private var _cachedFramerateMultiplier:Float = 1;
	private var _cachedCameraLerp:Float = 0.04;
	private var _cachedIconBounceType:String = "";
	private var _cachedDownScroll:Bool = false;
	private var _cachedMiddleScroll:Bool = false;
	private var _cachedTimeBarType:String = "";
	private var _lastConductorSongPos:Float = -1;
	private var _lastHealthValue:Float = 1;
	private var _lastBotplaySine:Float = 0;

	// Performance flags and counters
	private var _updateFrameCounter:Int = 0;
	private var _batchedUpdateThreshold:Int = 0; // Will be set based on framerate
	private var _needsIconUpdate:Bool = true;
	private var _needsScoreUpdate:Bool = true;
	private var _needsHealthBarUpdate:Bool = true;
	private var _skipRedundantUpdates:Bool = false;

	// Cached math values to reduce redundant calculations
	private var _cachedSinValue:Float = 0;
	private var _cachedExpValue:Float = 1;
	private var _cachedLerpValue:Float = 0;

	// Batched update flags
	private var _batchUIUpdates:Bool = false;
	private var _batchIconUpdates:Bool = false;
	private var _batchCameraUpdates:Bool = false;

	// Performance mode flags
	private var _useOptimizedNoteLoop:Bool = false;
	private var _useCachedStrumPositions:Bool = false;
	private var _reduceQualityMode:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = [];
	public var legacyLuaArray:Array<LegacyFunkinLua> = []; #end

	#if PYTHON_ALLOWED public var pyScriptArray:Array<yutautil.PyScript> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;

	// Start of Mixtape Engine's large amount of bull
	public static var gameplayArea:String = "Story";
	public static var Crashed:Bool = false;
	public static var savedTime:Float = 0;
	public static var playAsGF:Bool = false;
	public static var inSecretSong:Bool = false;
	private var specialOverlays:FlxTypedGroup<FlxSprite>;
	@:allow(managers.PlayfieldManager)
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

	public var ratingsData(get, never):Array<Rating>;
	public var combo(get, set):Int;
	public var maxCombo(get, set):Int;
	public var songScore(get, set):Int;
	public var songHits(get, set):Int;
	public var songMisses(get, set):Int;
	public var comboBreaks(get, set):Int;
	public var ratingName(get, set):String;
	public var ratingPercent(get, set):Float;
	public var ratingFC(get, set):String;
	public var totalPlayed(get, set):Int;
	public var totalNotesHit(get, set):Float;

	private function get_ratingsData():Array<Rating> return comboManager.ratingsData;
	private function get_combo():Int return comboManager.combo;
	private function set_combo(value:Int):Int return comboManager.combo = value;
	private function get_maxCombo():Int return comboManager.maxCombo;
	private function set_maxCombo(value:Int):Int return comboManager.maxCombo = value;
	private function get_songScore():Int return comboManager.songScore;
	private function set_songScore(value:Int):Int return comboManager.songScore = value;
	private function get_songHits():Int return comboManager.songHits;
	private function set_songHits(value:Int):Int return comboManager.songHits = value;
	private function get_songMisses():Int return comboManager.songMisses;
	private function set_songMisses(value:Int):Int return comboManager.songMisses = value;
	private function get_comboBreaks():Int return comboManager.comboBreaks;
	private function set_comboBreaks(value:Int):Int return comboManager.comboBreaks = value;
	private function get_ratingName():String return comboManager.ratingName;
	private function set_ratingName(value:String):String return comboManager.ratingName = value;
	private function get_ratingPercent():Float return comboManager.ratingPercent;
	private function set_ratingPercent(value:Float):Float return comboManager.ratingPercent = value;
	private function get_ratingFC():String return comboManager.ratingFC;
	private function set_ratingFC(value:String):String return comboManager.ratingFC = value;
	private function get_totalPlayed():Int return comboManager.totalPlayed;
	private function set_totalPlayed(value:Int):Int return comboManager.totalPlayed = value;
	private function get_totalNotesHit():Float return comboManager.totalNotesHit;
	private function set_totalNotesHit(value:Float):Float return comboManager.totalNotesHit = value;



	//FNF Weekly
	public var whosTurn:String = '';
	public var ghostsAllowed:Bool = ClientPrefs.data.doubleGhosts;
	public var dadGhostTween:FlxTween = null;
	public var bfGhostTween:FlxTween = null;
	public var dadGhost:FlxSprite = null;
	public var bfGhost:FlxSprite = null;

	// things from trials
	public var bfkilledcheck:Bool = false;
	var justmissed:Bool = false;
	var middlecircle:FlxSprite;
	var hasGlow:Bool = false;
	var strumFocus:Bool = false;
	var daStatic:FlxSprite;
	var thunderON:Bool = false;
	var gfScared:Bool = false;

	// Troll Engine
	public var camCurTarget:Null<Character> = null;
	public var zoomEveryBeat:Int = 1;
	public var holdsGiveHP:Bool = false;
	public var playerScoreTxt:FlxText;
	public var opponentScoreTxt:FlxText;
	var aiText:String;

	public var camGamefilters:Array<BitmapFilter> = [];
	public var camHUDfilters:Array<BitmapFilter> = [];
	public var camVisualfilters:Array<BitmapFilter> = [];
	public var camOtherfilters:Array<BitmapFilter> = [];
	public var camDialoguefilters:Array<BitmapFilter> = [];
	public var delayOffset:Float = 0; // for the delay effect

	var ch = 2 / 1000;
	public var shaderUpdates:Array<Float->Void> = [];

	// UNO color indicator sprite
	var unoColorIndicator:FlxSprite;
	var currentUnoColor:Int = 0xFFFF0000; // Default red

	// Gameplay Mechanics
	public var loopMode:Bool = ClientPrefs.getGameplaySetting('loopMode', false);
	public var loopModeChallenge:Bool = ClientPrefs.getGameplaySetting('loopModeC', false);
	public var loopPlayMult:Float = ClientPrefs.getGameplaySetting('loopPlayMult', 1.05);
	public var maniaMode:Bool = ClientPrefs.getGameplaySetting('maniaMode', false);
	public var gimmicksAllowed:Bool = false;
	public var mixupMode:Bool = false;

	// Archipelago / Streamer Vs. Chat stuff
	public var instVolumeMultiplier:Float = 1;
	public var instVolumeMultiplierHardMode:Float = 1;
	public var vocalVolumeMultiplier:Float = 1;
	public var vocalVolumeMultiplierHardMode:Float = 1;
	var inArchipelagoMode:Bool = false;
	public static var resettingState:Bool = false;

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

	//JS Engine shenanigans
	public var renderedTxt:FlxText;

	static var threadPool:FixedThreadPool = null;
	static var mutex:Mutex;

	//P-Slice

	//Plus Engine
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

	var throatnoteTweens:Array<FlxTween> = [];

	// Modchart warning variables
	var modchartWarningShown:Bool = false;
	var isShowingModchartWarning:Bool = false;
	public var allowModchartCutscene:Bool = true;
	var isNotITG:Bool = false;

	// End of Mixtape Engine's large amount of bull

	public function new(?playlist:PlaylistMetadata, ?songlist:Array<PlaylistSongMetadata>)
	{

		curPlaylist = playlist;
		if (songlist != null)
			curSonglist = songlist;
		else if (playlist != null)
			curSonglist = playlist.songList;
		super();

	}

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
			LoadingState.loadAndSwitchState(new archipelago.APPlayState(curPlaylist, curSonglist));
		}
		#end
		if (isWarmUp || isPlaylist) {
			allowDebugKeys = false;
			if (storyWeek != -1 && !inArchipelagoMode) {
				storyWeek = curSonglist[0].week;
				Difficulty.loadFromWeek();
				storyDifficulty = Difficulty.list.indexOf(curSonglist[0].difficulty);
			}
		}
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
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
		endCallback = endSong;

		playfield.setModMan(this);
		setOnScripts("modManager", playfield.modManager);
		setOnScripts("newPlayField", playfield.newPlayfield);
		setOnScripts("initPlayfield", playfield.initPlayfield);

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

		// Because some things do actually use these lol
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// Initialize TPS/NPS system
		notesHitArray = [];
		nps = 0;
		maxNPS = 0;
		npsCheck = 0;

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
		mixupMode = (ClientPrefs.getGameplaySetting('mixMode', false) || SONG.song == "Small Argument" && inSecretSong && !inArchipelagoMode) && !bothMode;
		opponentmode = ClientPrefs.getGameplaySetting('opponentplay', false) && !bothMode;
		playAsGF = ClientPrefs.getGameplaySetting('gfMode', false) && !bothMode && !opponentmode; // dont do it to yourself its not worth it
		holdsGiveHP = ClientPrefs.getGameplaySetting('holdsgivehp', holdsGiveHP);
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		playfield.oppDifficulty = (SONG.song == "Small Argument" && inSecretSong && !inArchipelagoMode) ? "Baby Mode" : ClientPrefs.getGameplaySetting('oppDifficulty', 'Average FNF Player');
		gimmicksAllowed = ClientPrefs.data.gimmicksAllowed;
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		AIPlayer.active = mixupMode && !bothMode;
		switch (playfield.oppDifficulty)
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

		playfield.fixMania();

		// Initialize experimental NotePool system if enabled
		if (ClientPrefs.data.useExperimentalNotePool) {
			NotePoolManager.updatePoolSettings();
			NotePoolManager.resetDemandTracking(); // Reset for new song
			trace("Experimental NotePool system enabled");
		}

		// === INITIALIZE PERFORMANCE OPTIMIZATIONS ===
		initializeOptimizations();
		updateScriptFlags();

		var sn = (altInstrumentals ?? SONG.song);
		conductor.setupSong('$sn/$sn-${Difficulty.getFilePath()}', SONG);
		conductor.musicPositionOffset = ClientPrefs.data.noteOffset;

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
		isNotITG = (curStage == 'notitg');

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;
		defaultStageZoom = defaultCamZoom;
		if (defaultCamHudZoom == 0) defaultCamHudZoom = 1;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		FlxG.game.stage.quality = isPixelStage ? StageQuality.LOW : ClientPrefs.getQuality();
		camGame.pixelPerfectRender = isPixelStage;
		camGame.antialiasing = isPixelStage ? false : ClientPrefs.data.antialiasing;

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
				gf = mcm.makeNewCharacter(0, 0, SONG.gfVersion, false, GF, GF);
				gfGroup.scrollFactor.set(0.95, 0.95);
			}
			dad = mcm.makeNewCharacter(0, 0, SONG.player2, false, DAD, DAD);
			if (SONG.player4.isNotEmpty()) dad2 = mcm.makeNewCharacter(0, 0, SONG.player4, false, DAD, DAD2);
			boyfriend = mcm.makeNewCharacter(0, 0, SONG.player1, true, BF, BF);
			if (SONG.player5.isNotEmpty()) bf2 = mcm.makeNewCharacter(0, 0, SONG.player5, true, BF, BF2);
		} else {
			// In NotITG we will not show characters: create instances but hide them to avoid NPEs
			// We use the default versions of character names if they are missing
			var p1 = (SONG.player1 == null || SONG.player1.length == 0) ? 'bf' : SONG.player1;
			var p2 = (SONG.player2 == null || SONG.player2.length == 0) ? 'dad' : SONG.player2;
			var p4 = (SONG.player4 == null || SONG.player4.length == 0) ? 'dad' : SONG.player4;
			var p5 = (SONG.player5 == null || SONG.player5.length == 0) ? 'bf' : SONG.player5;
			var gfver = (SONG.gfVersion == null || SONG.gfVersion.length == 0) ? 'gf' : SONG.gfVersion;

			gf = mcm.makeNewCharacter(0, 0, gfver, false, GF, GF);
			gf.visible = false;
			// Do not add to the group to keep the stage clean

			dad = mcm.makeNewCharacter(0, 0, p2, false, DAD, DAD);
			dad.visible = false;

			boyfriend = mcm.makeNewCharacter(0, 0, p1, true, BF, BF);
			boyfriend.visible = false;

			dad2 = mcm.makeNewCharacter(0, 0, p4, false, DAD, DAD2);
			dad2.visible = false;

			bf2 = mcm.makeNewCharacter(0, 0, p5, true, BF, BF2);
			bf2.visible = false;
		}

		updateGroupIndices();

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

				for (ext in Paths.YSCRIPT_EXTENSIONS)
					if(file.toLowerCase().endsWith('.$ext'))
						initYScript(folder + file);

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
		// STAGE LOADING - Load only ONE stage file (most relevant)
		loadSingleStageFile(curStage);

		// CHARACTER SCRIPTS
		mcm.startCharListFromScripts([gf, dad, boyfriend, bf2, dad2]);
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

		if (curHealthMode == "Lives" || curHealthMode == "Lives + HealthBar" || curHealthMode == "Lives + Mixtape" || curHealthMode == "Amalgam")
			hearts.visible = true;
		else
			hearts.visible = false;

		comboGroup.cameras = [if (ClientPrefs.data.inGameRatings) camGame else camHUD];

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(PlayfieldManager.STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
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
			playfield.newPlayfield();

		//trace("Making PlayerField!");
		playerField = playfields.members[0];
		if (playerField != null) {
			playerField.noteField.isEditor = false;
			playerField.isPlayer = !opponentmode && !playAsGF || bothMode;
			playerField.autoPlayed = !playerField.isPlayer || opponentmode || cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || playAsGF;
			playerField.noteHitCallback.add(goodNoteHit);
			playerField.owner = boyfriend;
			playerField.owners = [];
		}

		//trace("Making DadField!");
		dadField = playfields.members[1];
		if (dadField != null) {
			dadField.noteField.isEditor = false;
			dadField.isPlayer = opponentmode && !playAsGF || bothMode;
			dadField.autoPlayed = !dadField.isPlayer || (!opponentmode || (opponentmode && cpuControlled) || (opponentmode && ClientPrefs.getGameplaySetting('showcase', false)) || playAsGF) || (bothMode && cpuControlled) || (bothMode && ClientPrefs.getGameplaySetting('showcase', false));
			dadField.AIPlayer = mixupMode;
			dadField.noteHitCallback.add(opponentNoteHit);
			dadField.owner = dad;
			dadField.owners = [];
		}

		PlayField.initExtras();

		playfield.addNoteMissCalbackToField((daNote:Note, field:PlayField) -> {
			if (MusicBeatState.getState() == PlayState.instance) {
        if (!field.autoPlayed && !daNote.ignoreNote && !PlayState.instance?.endingSong && (daNote.tooLate || !daNote.wasGoodHit))
          PlayState.instance?.noteMiss(daNote, field);
      }
		}, playerField);

		playfield.addNoteMissCalbackToField((daNote:Note, field:PlayField) -> {
			if (MusicBeatState.getState() == PlayState.instance) {
        if (!field.autoPlayed && !daNote.ignoreNote && !PlayState.instance?.endingSong && (daNote.tooLate || !daNote.wasGoodHit))
          PlayState.instance?.noteMiss(daNote, field);
      }
		}, dadField);

		playfield.manualInputChecks = true;

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
		playfield.loadChart(Paths.formatToSongPath(_cachedSongName)+Difficulty.getFilePath(), Paths.formatToSongPath(_cachedSongName));
		postGen();
		trace('Chart Generation took ${Sys.time() - prevTime} seconds');

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

		if (mechanicsMod != null) {
			healthBarShader = new ColorSwap();
			healthBar.shader = healthBarShader.shader;
			healthBarShader.brightness = -1;
		}

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
				metadata.song?.name ?? curSong,
				metadata.song?.artist ?? '???',
				metadata.song?.charter ?? '???',
				metadata.song?.mod ?? 'Unknown'
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
			songTxt.text = metadata.song?.name ?? curSong;
			if (metadata.song?.artist != null && metadata.song.artist.length > 0)
				artistTxt.text = 'Composed by: ' + metadata.song.artist;
			if (metadata.song?.charter != null && metadata.song.charter.length > 0)
				charterTxt.text = 'Charted by: ' + metadata.song.charter;
			if (metadata.song?.mod != null && metadata.song.mod.length > 0)
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
		for (notetype in playfield.noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in playfield.eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in playfield.noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in playfield.eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end

		for (notetype in playfield.noteTypes)
			startYScriptsNamed('custom_notetypes/' + notetype + '.ys');
		for (event in playfield.eventsPushed)
			startYScriptsNamed('custom_events/' + event + '.ys');
		playfield.noteTypes = null;
		playfield.eventsPushed = null;

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
				for (ext in Paths.HSCRIPT_EXTENSIONS)
					if(file.toLowerCase().endsWith('.$ext'))
						initHScript(folder + file);
				#end

				for (ext in Paths.YSCRIPT_EXTENSIONS)
					if(file.toLowerCase().endsWith('.$ext'))
						initYScript(folder + file);
			}
		#end

		playfield.triggerEarlyEvents();

		// Register dynamic song scripting functions after all scripts are loaded
		//registerDynamicSongScripting();
		comboManager.RecalculateRating(false, false);

		playfield.addInput();

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

		// if none of the loaded scripts/stages changed it, use the default
		if (startCallback == null) startCallback = (hasModchart() && allowModchartCutscene ? showModchartWarning : startCountdown);

		super.create();

		startCallback();

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

		resettingState = false;

		// trace size with verbose settings.
		// trace(this.realSizeOf());
		// Paths.nukeMemory(true); // LIGHTLY nuke everything

		doMegaManagerStuff(); // do it at the END
	}

	public function doMegaManagerStuff() {
		// Add all manager-related stuff here
		conductor.addSectionCallback((curSec:Int, backward:Bool) ->
		{
			if (SONG.notes[curSec] != null)
			{
				if (generatedMusic && !endingSong && !isCameraOnForcedPos)
					moveCameraSection();

				if (SONG.notes[curSec].changeBPM)
				{
					Conductor.bpm = SONG.notes[curSec].bpm;
					setOnScripts('curBpm', Conductor.bpm);
					setOnScripts('crochet', Conductor.crochet);
					setOnScripts('stepCrochet', Conductor.stepCrochet);
				}
				setOnScripts('mustHitSection', SONG.notes[curSec].mustHitSection);
				setOnScripts('altAnim', SONG.notes[curSec].altAnim);
				setOnScripts('gfSection', SONG.notes[curSec].gfSection);
			}

			setOnScripts('curSection', curSec);
			callOnScripts('onSectionHit');
		});

		conductor.addBeatCallback((curBeat:Int, backward:Bool) ->
		{
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

			if (camZooming && ClientPrefs.data.camZooms && (curBeat % camZoomingFrequency) == 0)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			#if MECHANICS_MOD_ALLOWED
			if (mechanicsMod != null) {
				if (curBeat % 4 == 0)
				{
					if (generatedMusic && PlayfieldManager.SONG.notes[Std.int(curBeat / 4)] != null && !endingSong)
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
					if (generatedMusic && PlayfieldManager.SONG.notes[Math.floor(curBeat / 4)] != null && !endingSong)
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
		});

		conductor.addStepCallback((curStep:Int, backward:Bool) ->
		{
			setOnScripts('curStep', curStep);
			callOnScripts('onStepHit');
		});
	}

	// Some small stuff from PlusEngine
	function hasModchart():Bool
	{
		#if MODCHARTS_NOTITG_ALLOWED
		var hasModchartFunction:Bool = false;

		#if LUA_ALLOWED
		for (script in luaArray) {
			if (script != null && !script.closed && script.lua != null) {
				Lua.getglobal(script.lua, 'onInitModchart');
				Lua.getglobal(script.lua, 'generateModchart');
				var type:Int = Lua.type(script.lua, -1);
				Lua.pop(script.lua, 1);

				if (type == Lua.LUA_TFUNCTION) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (!hasModchartFunction) {
			for (script in hscriptArray) {
				@:privateAccess
				if (script != null && (script.exists('onInitModchart') || script.exists('generateModchart'))) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		if (!hasModchartFunction) {
			for (script in yscriptArray) {
				@:privateAccess
				if (script != null && (script.hasFunction('onInitModchart') || script.hasFunction('generateModchart'))) {
					hasModchartFunction = true;
					break;
				}
			}
		}

		return hasModchartFunction;
		#else
		return false;
		#end
	}

	function showModchartWarning():Void
	{
		isShowingModchartWarning = true;

		// black background
		var blackBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBG.scrollFactor.set();
		blackBG.cameras = [camHUD];
		add(blackBG);

		// NotITG style "EVENT MODE" text
		var warningText:FlxText = new FlxText(0, 0, FlxG.width, "EVENTS MODE!");
		warningText.setFormat(Paths.font("aller.ttf"), 72, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.borderSize = 4;
		warningText.screenCenter();
		warningText.y -= 100;
		warningText.scrollFactor.set();
		warningText.cameras = [camHUD];
		warningText.alpha = 0;
		add(warningText);

		// Secondary text
		var subText:FlxText = new FlxText(0, 0, FlxG.width, "Modcharts Enabled");
		subText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		subText.borderSize = 2;
		subText.screenCenter();
		subText.y += 50;
		subText.scrollFactor.set();
		subText.cameras = [camHUD];
		subText.alpha = 0;
		add(subText);

		// Entry animation
		FlxTween.tween(warningText, {alpha: 1}, 0.3, {ease: FlxEase.cubeOut});

		FlxTween.tween(subText, {alpha: 1}, 0.4, {
			ease: FlxEase.cubeOut,
			startDelay: 0.2,
			onComplete: function(twn:FlxTween) {
				// Wait a bit and do the confirmation effect
				new FlxTimer().start(0.3, function(tmr:FlxTimer) {
					// Confirmation sound
					FlxG.sound.play(Paths.sound('confirmMenu'));

					// Change texts to green
					warningText.color = FlxColor.LIME;
					subText.color = FlxColor.LIME;

					// Create explosion particles from the center
					var centerX:Float = FlxG.width / 2;
					var centerY:Float = FlxG.height / 2;

					for (i in 0...16) {
						var angle:Float = (360 / 16) * i;
						var particle:FlxSprite = new FlxSprite(centerX, centerY);
						particle.makeGraphic(10, 10, FlxColor.LIME);
						particle.scrollFactor.set();
						particle.cameras = [camHUD];
						add(particle);

						var targetX:Float = particle.x + Math.cos(angle * Math.PI / 180) * 200;
						var targetY:Float = particle.y + Math.sin(angle * Math.PI / 180) * 200;

						FlxTween.tween(particle, {x: targetX, y: targetY, alpha: 0}, 0.8, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween) {
								particle.destroy();
							}
						});
					}
				});
			}
		});

		// After 2 seconds, disappear instantly and continue
		new FlxTimer().start(2.0, function(tmr:FlxTimer) {
			blackBG.destroy();
			warningText.destroy();
			subText.destroy();
			isShowingModchartWarning = false;
			modchartWarningShown = true;

			// Start countdown now
			startCountdown();
		});
	}

	function initModchart()
	{
		#if MODCHARTS_NOTITG_ALLOWED
		// Check if any script has the onInitModchart function
		var hasModchartFunction:Bool = false;

		#if LUA_ALLOWED
		for (script in luaArray) {
			if (script != null && !script.closed && script.lua != null) {
				Lua.getglobal(script.lua, 'onInitModchart');
				var type:Int = Lua.type(script.lua, -1);
				Lua.pop(script.lua, 1);

				if (type == Lua.LUA_TFUNCTION) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (!hasModchartFunction) {
			for (script in hscriptArray) {
				@:privateAccess
				if (script != null && script.exists('onInitModchart')) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		if (!hasModchartFunction) {
			for (script in yscriptArray) {
				@:privateAccess
				if (script != null && script.hasFunction('onInitModchart')) {
					hasModchartFunction = true;
					break;
				}
			}
		}

		// If there is no onInitModchart function, do not initialize the manager
		if (!hasModchartFunction) {
			//trace("No onInitModchart function found - modchart manager not initialized");
			return;
		}

		// If there is an onInitModchart function, automatically activate modcharting
		//trace("onInitModchart function detected - initializing modchart manager");

		try {
			if (fmManager == null) {
				fmManager = new Manager();
				add(fmManager);
				trace("Modchart Manager initialized successfully");
			}
		} catch (e:Dynamic) {
			trace("Error initializing modcharts: " + e);
		}
		#end
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
		Conductor.offset = Reflect.hasField(PlayfieldManager.SONG, 'offset') ? (PlayfieldManager.SONG.offset / value) : 0;
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
				var newBoyfriend:Character = mcm.preloadCharacter(newCharacter, true, BF, BF);
				newBoyfriend.alpha = 0.00001;
			case 1:
				var newDad:Character = mcm.preloadCharacter(newCharacter, false, DAD, DAD);
				newDad.alpha = 0.00001;
			case 2:
				var newGf:Character = mcm.preloadCharacter(newCharacter, false, GF, GF);
				newGf.alpha = 0.00001;
			case 3:
				var newDad2:Character = mcm.preloadCharacter(newCharacter, false, DAD, DAD2);
				newDad2.alpha = 0.00001;
			case 4:
				var newBoyfriend:Character = mcm.preloadCharacter(newCharacter, true, BF, BF2);
				newBoyfriend.alpha = 0.00001;
		}
	}

	function startCharacterScripts(name:String)
		mcm.startCharacterScripts(name);


	function loadSingleStageFile(stageName:String, reloadStageData:Bool = false)
	{
		var stageData:StageFile = null;

		// When called during a stage change event, handle group removal, stage data reload, and group re-add
		if (reloadStageData) {
			// Remove character groups before switching (skip if NotITG since they weren't added)
			if (!isNotITG) {
				remove(gfGroup);
				remove(dadGroup2);
				remove(dadGroup);
				remove(boyfriendGroup2);
				remove(boyfriendGroup);
			}

			curStage = stageName;
			isNotITG = (curStage == 'notitg');
			stageData = StageData.getStageFile(curStage);
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
			if(boyfriendCameraOffset == null)
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

			boyfriendGroup.setPosition(BF_X, BF_Y);
			boyfriendGroup2.setPosition(BF2_X, BF2_Y);
			dadGroup.setPosition(DAD_X, DAD_Y);
			dadGroup2.setPosition(DAD2_X, DAD2_Y);
			gfGroup.setPosition(GF_X, GF_Y);

			Paths.setCurrentLevel(stageData.directory);
			Paths.setCurrentLevel('shared');
		}

		// Get stageData for initial load case (non-reload)
		if (stageData == null) {
			stageData = StageData.getStageFile(stageName);
		}

		var stageFileLoaded:String = "";

		// Check if any modded stage script exists FIRST (before calling VSliceLoader)
		var hasModdedStageScript:Bool = false;

		#if MODS_ALLOWED
		#if LUA_ALLOWED
		var luaFile:String = 'stages/$stageName.lua';
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath)) hasModdedStageScript = true;
		#end

		#if HSCRIPT_ALLOWED
		if (!hasModdedStageScript) {
			var scriptFile:String = 'stages/$stageName.hx';
			var replacePath:String = Paths.modFolders(scriptFile);
			if(FileSystem.exists(replacePath)) hasModdedStageScript = true;
		}
		#end

		if (!hasModdedStageScript) {
			var scriptFile:String = 'stages/$stageName.ys';
			var replacePath:String = Paths.modFolders(scriptFile);
			if(FileSystem.exists(replacePath)) hasModdedStageScript = true;
		}
		#end

		// STEP 1: Run VSliceLoader ONLY if no modded stage script exists and stageData has no objects
		// VSliceLoader's add() calls put stage background sprites into the state's members list.
		// These must go in BEFORE character groups so groups render ON TOP of stage backgrounds.
		if ((stageData.objects == null || stageData.objects.length <= 0) && !hasModdedStageScript) {
			VSliceLoader.addstage(stageName);
			stageFileLoaded = "VSliceLoader: " + stageName;
		}

		// STEP 2: Add character groups AFTER VSliceLoader (so they render on top of stage sprites)
		// but BEFORE scripts (so scripts' onCreate can use addLuaSprite(tag, false) / addBehindGF etc.,
		// which need members.indexOf(getLowestCharacterGroup()) to return a valid index).
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

		// STEP 3: Load stage scripts AFTER groups are in state and VSliceLoader has run.
		// Scripts' onCreate callbacks can now safely use addLuaSprite(tag, false), addBehindGF, etc.
		// Only ONE script type loads per stage (priority: Lua -> HScript -> YScript).
		var scriptLoaded:Bool = false;
		#if LUA_ALLOWED
		if (!scriptLoaded)
		{
			var doPush:Bool = false;
			var luaFile:String = 'stages/$stageName.lua';
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
				{
					(shouldUseLegacyLua() ? new LegacyFunkinLua(luaFile) : new FunkinLua(luaFile));
					stageFileLoaded += " + Lua: " + luaFile;
					scriptLoaded = true;
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (!scriptLoaded)
		{
			var doPush:Bool = false;
			var scriptFile:String = 'stages/$stageName.hx';
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
				for (script in hscriptArray)
				{
					if(script.origin == scriptFile)
					{
						doPush = false;
						break;
					}
				}
				if(doPush)
				{
					initHScript(scriptFile);
					stageFileLoaded += " + HScript: " + scriptFile;
					scriptLoaded = true;
				}
			}
		}
		#end

		if (!scriptLoaded)
		{
			var doPush:Bool = false;
			var scriptFile:String = 'stages/$stageName.ys';
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
				for (script in yscriptArray)
				{
					if(script.scriptPath == scriptFile)
					{
						doPush = false;
						break;
					}
				}
				if(doPush)
				{
					initYScript(scriptFile);
					stageFileLoaded += " + YScript: " + scriptFile;
					scriptLoaded = true;
				}
			}
		}

		// Cache group indices for performance
		updateGroupIndices();

		// Debug info about which stage file was loaded
		if (ClientPrefs.data.developerMode && stageFileLoaded.length > 0) {
			trace('Loaded stage: $stageFileLoaded');
		}
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

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
		mcm.startCharacterPos(char, gfCheck);

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
					if (!isDead && generatedMusic && PlayfieldManager.SONG.notes[Std.int(conductor.currentStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
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

			if (skipCountdown || startOnTime > 0) playfield.skipArrowStartTween = true;

			//trace("Starting Countdown!");
			canPause = true;

			if (skipCountdown || startOnTime > 0)
				playfield.skipArrowStartTween = true;

			try {playfield.generateStrums();}catch(e){trace("Strums are NULL!");}

			#if ALLOW_DEPRECATION
			callOnScripts('preModifierRegister'); // deprecated
			#end

			if (callOnScripts('onModifierRegister') != LuaUtils.Function_Stop) {
				modManager.registerDefaultModifiers();

				if (ClientPrefs.data.middleScroll || isStepManiaChart) {
					var opp:Int = opponentmode ? 0 : 1;
					for (field in playfields.members) {
						var off:Float = Math.min(FlxG.width, 1280) / Note.ammo[mania[field.modNumber]];
						if (field.modNumber == opp) {
							var halfKeys:Int = Math.floor(Note.ammo[mania[field.modNumber]] / 2);
							if (Note.ammo[mania[field.modNumber]] % 2 != 0) // middle receptor dissappears, if there is one
								modManager.setValue('alpha${halfKeys + 1}', 1.0, opp);

							for (i in 0...halfKeys)
								modManager.setValue('transform${i}X', -off, opp);
							for (i in Note.ammo[mania[field.modNumber]]-halfKeys...Note.ammo[mania[field.modNumber]])
								modManager.setValue('transform${i}X', off, opp);

							modManager.setValue("alpha", isStepManiaChart ? 1 : 0.6, opp);
						}
					}
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

			for (field in playfield.playfields.members) {
				for (i in 0...Note.ammo[mania[field.modNumber]]) {
					//field.baseXPositions[i] = field.strumNotes[i].x;
					/*if (field.modNumber == 1) {
						setOnScripts('defaultPlayerStrumX' + i, field.strumNotes[i].x);
						setOnScripts('defaultPlayerStrumY' + i, field.strumNotes[i].y);
					} else if (field.modNumber == 0) {
						setOnScripts('defaultOpponentStrumX' + i, field.strumNotes[i].x);
						setOnScripts('defaultOpponentStrumY' + i, field.strumNotes[i].y);
					}*/
				}
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');
			for (field in playfields.members) {
				if (SONG.startMania != null && SONG.startMania != mania[field.modNumber]) {
					trace("Fixing Mania");
					//playfield.changeMania(chartModifier != 'ManiaConverter' ? SONG.startMania : convertMania, field, isStoryMode || playfield.skipArrowStartTween);
				}
				else if (chartModifier == "ManiaConverter") {
					trace("Setting the mania");
					//playfield.changeMania(convertMania, field, isStoryMode || playfield.skipArrowStartTween);
				}
			}

			// Initialize any Funkin Modchart modcharts after all scripts and strums are loaded
			initModchart();

			callOnScripts("generateModchart"); // this is where scripts should generate modcharts from here on out lol

			// if there's a Funkin Modchart present, Load that too
			if (hasModchart())
				callOnScripts('onInitModchart');

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

				if(!playfield.skipArrowStartTween)
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
				callOnYScript('onCountdownTick', [tick, swagCounter]);

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

	public function addBehindHUD(obj:FlxBasic)
	{
		insert(members.indexOf(uiGroup), obj);
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
		insert(members.indexOf(dadGroup) + 1, obj);
	}

	public function addAboveBF2(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup2) + 1, obj);
	}

	public function addAboveDad2(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup2) + 1, obj);
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

		if (!resettingState && ClientPrefs.data.showScoreText) { // to prevernt a very stupid crash for songswitching
			var col:String = '';
			var str:String = Language.getPhrase('rating_${comboManager.ratingName}', comboManager.ratingName);
			if(comboManager.totalPlayed != 0)
			{
				var percent:Float = CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2);
				// TODO: Make this look nicer
				if (percent >= 100)
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
					tempScore = '${if (ClientPrefs.data.showScore) 'Score: ${comboManager.songScore} | ' else ""}${if (ClientPrefs.data.showMisses) 'Misses: ${comboManager.songMisses} | ' else ""}${if (ClientPrefs.data.showRating) 'Rating: ${str} | ' else ""}${if (ClientPrefs.data.showNPS) 'NPS: ${nps}/${maxNPS}' else ""}';
				}
				else {
					tempScore = Language.getPhrase('score_text_instakill', '${if (ClientPrefs.data.showScore) 'Score: {1} | ' else ""}${if (ClientPrefs.data.showRating) 'Rating: {2} | ' else ""}${if (ClientPrefs.data.showNPS) 'NPS: {3}/{4}' else ""}', [comboManager.songScore, str, nps, maxNPS]);
					scoreTxt.borderColor = FlxColor.fromRGB(255, 0, 0);
				}
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

				var hString:String = ' | Health: $col$healthTxt% $col' + (MaxHP != 2 ? ' / ${CoolUtil.floorDecimal((MaxHP / 2) * 100, 2)}%' : '');
				var finalText:String = '$tempScore${if (ClientPrefs.data.showHealth) (instakillOnMiss ? "DON'T MISS!" : hString) else ""}';
				scoreTxt.applyMarkup(finalText,
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
		} else if (!resettingState) {
			scoreTxt.visible = false;
			scoreTxt.alpha = 0;
			scoreTxt.y = 1000000;
			scoreTxt.x = 1000000;
			//Keep it alive so script calls still work, but hide it completely
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
		debugInfo += 'Step: ${conductor.currentStep} (${CoolUtil.floorDecimal(conductor.stepLengthMs, 2)})\n';
		debugInfo += 'Beat: ${conductor.currentBeat} (${CoolUtil.floorDecimal(conductor.beatLengthMs, 2)})\n';
		debugInfo += 'Section: ${conductor.currentMeasure}\n';
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
			PlayfieldManager.SONG = FlxG.save.data.SONG;
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
					playfield.reverseNoteRules = !inArchipelagoMode  || archipelago.APItem.activeItem?.name == "Input Reversal";
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
		if (inArchipelagoMode) playfield.reverseNoteRules = APInfo.backwardsSinging;
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

	function postGen() {
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
									mechanicsMod.lastHealth -= loss;
								else {
									backend.COD.COD.COD = (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + "couldn't keep up.";
									health -= loss;
								}

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
	}

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

	public function die(?trueKill:Bool = false, ?cod:String):Void
	{
		'COD = $cod. backend.COD.COD.COD = ${backend.COD.COD.COD}'.log();
			if (cod != null && cod.trim() != "") {
				backend.COD.COD.COD = cod;
			}
		if (trueKill)
			doDeathCheck(true);
		else {
			health = 0;
			bfkilledcheck = true;
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
				visual.visible = healthBar.visible;
				visual.angle = healthBar.angle;
				visual.colorLeft = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
				visual.colorRight = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			}

			if (vocalvisual != null) {
				vocalvisual.x = healthBar.x;
				vocalvisual.y = healthBar.y + healthBar.height;
				vocalvisual.alpha = ClientPrefs.data.visOpacity;
				vocalvisual.visible = healthBar.visible;
				vocalvisual.angle = healthBar.angle;
				for (line in vocalvisual.members)
					line.color = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
			}

			if (oppvisual != null) {
				oppvisual.x = healthBar.x;
				oppvisual.y = healthBar.y + healthBar.height;
				oppvisual.alpha = ClientPrefs.data.visOpacity;
				oppvisual.visible = healthBar.visible;
				oppvisual.angle = healthBar.angle;
				for (line in oppvisual.members)
					line.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			}
		} catch(e){}
	}

	public var initY:Float;
	var lastHealth:Float = -1;
	public var forceModSyncOff:Bool = false;
	override public function update(elapsed:Float)
	{
		// === PERFORMANCE OPTIMIZATION: Frame counter and batching ===
		_updateFrameCounter++;
		var shouldBatchUpdate = _batchUIUpdates && (_updateFrameCounter % _batchedUpdateThreshold != 0);

		// Refresh cached values periodically (every 30 frames)
		if (_updateFrameCounter % 30 == 0) {
			refreshCachedValues();
		}

		// If Legacy Lua settings are being edited and we're not in test mode, don't allow regular PlayState
		// The Legacy Lua system should handle PlayState switching through its own mechanisms
		if (options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode && !isLegacyLuaTest) {
			// Don't auto-switch PlayState when in Legacy Lua settings mode - let the Legacy Lua system handle it
			// This prevents conflicts between the systems
		}

		// Update dynamic song system
		updateDynamicSong();

		if(!inCutscene && !paused && !freezeCamera) {
			// Use cached camera lerp value for performance
			FlxG.camera.followLerp = _cachedCameraLerp;
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

		if (FlxG.animationTimeScale != _cachedPlaybackRate) {
			FlxG.animationTimeScale = _cachedPlaybackRate;
		}

		//So that the health text works - optimized with caching
		if (health != _lastHealthValue) {
			_needsScoreUpdate = true;
			_lastHealthValue = health;
		}

		// Batch score updates to reduce UI thrashing
		if (_needsScoreUpdate && !shouldBatchUpdate) {
			updateScoreText();
			_needsScoreUpdate = false;
		}

		// Update modchart debug info every frame
		updateModchartDebugText();

		if (inArchipelagoMode && APInfo.inHardMode)
		{
			vocalVolumeMultiplierHardMode = (APInfo.hasItem("BF's Mic") ? 1 : 0);
			instVolumeMultiplierHardMode = (APInfo.hasItem("Speakers") ? 1 : 0);

			gfGroup.visible = APInfo.hasItem("GF");
			camHUD.visible = APInfo.hasItem("HUD");
			canPauseHardMode = APInfo.hasItem("Pause Menu");
		}

		// TPS/NPS System Update
		{
			var i = notesHitArray.length - 1;
			while (i >= 0)
			{
				var time:Date = notesHitArray[i];
				if (time != null && time.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(time);
				else
					i = -1; // break the loop
				i--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;

			setOnScripts('nps', nps);
			setOnScripts('maxNPS', maxNPS);

			if (npsCheck != nps)
			{
				npsCheck = nps;
				updateScoreText();
			}
		}

		// Optimize script calls - only call if scripts exist
		if (hasLuaScripts || hasHScripts || hasPyScripts || hasYScripts) {
			callOnScripts('onUpdate', [elapsed]);
		}

		updateVisPos();

		if (curHealthMode == "Tabi" || curHealthMode == "Amalgam")
		{
			if (health > 0)
			{
				backend.COD.COD.COD = (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + "succumbed to the sheer might of the opponent.";
				health -= 0.001 * _cachedFramerateMultiplier;
			}
		}

		super.update(elapsed);
		if (vocals != null) vocals.volume *= (vocalVolumeMultiplier * vocalVolumeMultiplierHardMode);
		FlxG.sound.music.volume = 1 * (instVolumeMultiplier * instVolumeMultiplierHardMode);
		updateSyncedVideos(); // Update synced video system

		//Band-Aid patch but HEY IT WORKS SO I AM NOT COMPLAINING LMAO
		//This has no right to work as well as it does lmao
		if (!startingSong && ClientPrefs.data.modcharts && !forceModSyncOff)
			modchartSync(false);

		// Optimize script calls - only set if scripts exist
		if (hasLuaScripts || hasHScripts || hasPyScripts || hasYScripts) {
			setOnScripts('curDecStep', conductor.stepLengthMs);
			setOnScripts('curDecBeat', conductor.beatLengthMs);
		}

		if (strumFocus)
		{
			if (SONG.notes[conductor.currentMeasure].mustHitSection && !SONG.notes[conductor.currentMeasure].exSection)
			{
				modManager.queueEase(conductor.currentStep, conductor.currentStep + 4, 'alpha', 0.8, 'sineInOut', 1);
				modManager.queueEase(conductor.currentStep, conductor.currentStep + 4, 'alpha', 0, 'sineInOut', 0);
			}
			else if (!SONG.notes[conductor.currentMeasure].mustHitSection && !SONG.notes[conductor.currentMeasure].exSection)
			{
				modManager.queueEase(conductor.currentStep, conductor.currentStep + 4, 'alpha', 0.8, 'sineInOut', 0);
				modManager.queueEase(conductor.currentStep, conductor.currentStep + 4, 'alpha', 0, 'sineInOut', 1);
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

		// === OPTIMIZED BOTPLAY TEXT ANIMATION ===
		if(botplayTxt != null && botplayTxt.visible) {
			// Cache sine calculation for better performance
			botplaySine += 180 * elapsed;
			if (botplaySine != _lastBotplaySine || shouldBatchUpdate) {
				_cachedSinValue = getCachedSinValue(botplaySine);
				botplayTxt.alpha = 1 - _cachedSinValue;
				_lastBotplaySine = botplaySine;
			}
		}

		// Legacy Lua test text animation - sync with botplay for efficiency
		if(legacyLuaTestTxt != null) {
			legacyLuaTestTxt.visible = isLegacyLuaTest; // Update visibility in case flag changes
			if(legacyLuaTestTxt.visible) {
				legacyLuaTestTxt.alpha = 1 - _cachedSinValue; // Reuse cached sine calculation
			}
		}

		// Optimize pause check - only check scripts if they exist
		if (controls.PAUSE && startedCountdown && canPause && canPauseHardMode && !endingSong)
		{
			var ret:Dynamic = null;
			if (hasLuaScripts || hasHScripts || hasPyScripts || hasYScripts) {
				ret = callOnScripts('onPause', null, true);
			}
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

		// === BATCHED ICON UPDATES ===
		// Only update icons when needed or not batching
		if (!_batchIconUpdates || !shouldBatchUpdate) {
			updateIconsScale(elapsed);
			updateIconsPosition();
			_needsIconUpdate = false;
		}

		hearts.forEachAlive(function(heart:FlxSprite)
		{
			// Cache camera speed calculation
			var heartAngleLerp = cameraSpeed * 2 * (_cachedFramerateMultiplier/2);
			heart.angle = FlxMath.lerp(heart.angle, 30, heartAngleLerp);
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

		if (judgementCounter != null)
			judgementCounter.updateCounter(comboManager.ratingsData, comboManager.songMisses, comboManager.combo, comboManager.maxCombo);

		if (startingSong)
		{
			if (startedCountdown && conductor.musicPosition >= conductor.musicPositionOffset)
				startSong();
		}
		else if (!paused && updateTime)
		{
			if (conductor.musicPosition - lastUpdateTime >= 1.0)
				lastUpdateTime = conductor.musicPosition;

			// Cache time bar type to avoid repeated property access
			var timeBarType:String = _cachedTimeBarType;
			var curTime:Float = Math.max(0, conductor.musicPosition - ClientPrefs.data.noteOffset);
			var lengthUsing:Float = (maskedSongLength > 0) ? maskedSongLength : songLength;
			songPercent = (curTime / lengthUsing);

			var songCalc:Float = (lengthUsing - curTime);
			if(timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(timeBarType != 'Song Name')
				timeTxt.text = convertTime(secondsTotal, false);
		}

		// === OPTIMIZED CAMERA ZOOM ===
		if (camZooming)
		{
			// Cache expensive exponential calculations
			_cachedExpValue = getCachedExpLerp(elapsed, 3.125 * camZoomingDecay);
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, _cachedExpValue);
			camHUD.zoom = FlxMath.lerp(defaultCamHudZoom, camHUD.zoom, _cachedExpValue);
		}

		FlxG.watch.addQuick("secShit", conductor.currentMeasure);
		FlxG.watch.addQuick("beatShit", conductor.currentBeat);
		FlxG.watch.addQuick("stepShit", conductor.currentStep);

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
				@:privateAccess
				if(!cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false)) playfield.keysCheck();
				else playerDance();

				// === OPTIMIZED NOTE PROCESSING ===
				amountOfRenderedNotes = 0;

				// Use optimized note iteration for better performance
				if (_useOptimizedNoteLoop) {
					// Cache notes length to avoid repeated property access
					var notesLength = notes.length;
					for (i in 0...notesLength) {
						var daNote = notes.members[i];
						if (daNote != null && daNote.exists) {
							updateLiveNote(daNote);
						}
					}
				} else {
					// Fallback to standard forEach for compatibility
					notes.forEach(function(daNote) {
						updateLiveNote(daNote);
					});
				}

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

								try {
									healthBarTween = FlxTween.tween(healthBarShader, {brightness: 0, hue: 0.5}, 1, {ease: FlxEase.cubeOut});
								} catch(e) {}
							}
						}
						else
						{
							mechanicsMod.allowBurstTween = true;
							if (healthBarTween != null)
								healthBarTween.cancel();
							try {
								healthBarTween = FlxTween.tween(healthBarShader, {brightness: -1, hue: 0}, 1, {ease: FlxEase.cubeOut});
							} catch(e) {}
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
							if (cpuControlled || ClientPrefs.getGameplaySetting('showcase', false) || controls.justPressed('dodge'))
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
							if (cpuControlled || ClientPrefs.getGameplaySetting('showcase', false))
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
								if (cpuControlled || ClientPrefs.getGameplaySetting('showcase', false))
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

				// === OPTIMIZED MECHANICS NOTE PROCESSING ===
				// Cache frequently used values
				var flashlightPoints:Int = MechanicManager.mechanics['flashlight'].points;
				var hasFlashlight:Bool = flashlightPoints > 0;
				var cachedDownScroll:Bool = _cachedDownScroll;
				var cachedConductorPos:Float = Conductor.songPosition;

				// Pre-calculate flashlight values if needed
				var centerPoint:Float = 0;
				var multi:Float = 0;
				if (hasFlashlight) {
					centerPoint = FlxG.height;
					multi = cachedDownScroll ?
						FlxMath.remapToRange(flashlightPoints, 0, 20, 0.4, 0.2) :
						FlxMath.remapToRange(flashlightPoints, 0, 20, 0.2, 0.4);
					modManager.setValue('sudden-a', FlxMath.remapToRange(flashlightPoints, 0, 20, 0.1, 1));
				}

				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if ((!daNote.formerPress && bothMode) || (!daNote.mustPress && !bothMode))
						strumGroup = opponentStrums;

					var strumY:Float = strumGroup.members[daNote.noteData].y;

					// Optimized flashlight mechanics with cached values
					var noteType = daNote.noteType;
					if (hasFlashlight && noteType != 'Fake Note' && noteType != 'Swap Note')
					{
						var notePos:Float = daNote.y;
						var targetY:Float = cachedDownScroll ? strumY - (7.5 * flashlightPoints) : strumY + (7.5 * flashlightPoints);
						var curAlpha:Float = FlxMath.remapToRange(notePos, centerPoint * multi, targetY, daNote.alphaLimit, 0.2);
						daNote.alpha = daNote.isSustainNote && curAlpha > 0.6 ? 0.6 : curAlpha;
					}

					// Optimize swap note processing with cached conductor position
					var lastCopyX:Bool = cast daNote.copyX;
					if (daNote.expectedData != -1 && Math.abs(daNote.strumTime - cachedConductorPos) < 500)
					{
						var gottenStrum = strumGroup;

						if (noteType == 'Swap Note')
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


		if ((loopMode || loopModeChallenge || curSong == "Small Argument" && inSecretSong && !inArchipelagoMode)
			&& startedCountdown
			&& !endingSong)
		{
			if (FlxG.sound.music.length - Conductor.songPosition <= endingTimeLimit)
			{
				songAboutToLoop = true;
				if (comboManager.AIScore >= comboManager.songScore && mixupMode)
				{
					if (FlxG.sound.music.time < 0 || Conductor.songPosition < 0)
					{
						FlxG.sound.music.time = 0;
						resyncVocals();
					}
					loopCallback(0);
					endingSong = false;
					backend.COD.COD.COD = (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + "couldn't keep up with the opponent.";
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

		if (FlxG.keys.justPressed.SPACE && skipActive && (videoCutscene == null && !inCutscene))
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
			FlxTween.tween(skipTxt, {alpha: 0}, 0.2/playbackRate, {
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

			// === OPTIMIZE NOTE POOLING INTEGRATION ===
			// If experimental note pool is enabled, optimize note lifecycle
			if (ClientPrefs.data.useExperimentalNotePool) {
				// Cache note position for performance
				var noteY = daNote.y;
				var noteStrum = daNote.strumTime;
				var conductorPos = Conductor.songPosition;

				// Early exit for notes that are far off-screen to reduce processing
				if (noteY > FlxG.height + 500 || noteY < -500) {
					// Note is way off screen, skip further processing for performance
					if (noteStrum < conductorPos - 2000) { // Note is 2 seconds old
						// This note is old and off-screen, could be optimized further
						return;
					}
				}
			}
		}
	}

	// Health icon updaters - OPTIMIZED VERSION
	public dynamic function updateIconsScale(elapsed:Float)
	{
		// Use cached icon bounce type to avoid repeated property access
		var bounceType = _cachedIconBounceType;

		// Pre-calculate common values to reduce redundancy
		var elapsedPlayback = elapsed * _cachedPlaybackRate;
		var expValue9 = Math.exp(-elapsedPlayback * 9);
		var expValue30 = Math.exp(-elapsedPlayback * 30);

		switch (bounceType) {
			case "Base" | "VS Steve":
				// Cache scale calculations for both icons
				var mult1:Float = FlxMath.lerp(1, iconP1.scale.x, expValue9);
				var mult2:Float = FlxMath.lerp(1, iconP2.scale.x, expValue9);

				iconP1.scale.set(mult1, mult1);
				iconP1.updateHitbox();
				iconP2.scale.set(mult2, mult2);
				iconP2.updateHitbox();

			case "Mixtape":
				// Cache scale and angle calculations
				var mult1:Float = FlxMath.lerp(1, iconP1.scale.x, expValue9);
				var mult2:Float = FlxMath.lerp(1, iconP2.scale.x, expValue9);
				var angleLerpValue = CoolUtil.boundTo(1 - elapsedPlayback * 9, 0, 1);

				iconP1.scale.set(mult1, mult1);
				iconP1.updateHitbox();
				iconP1.angle = FlxMath.lerp(1, iconP1.angle, angleLerpValue);

				iconP2.scale.set(mult2, mult2);
				iconP2.updateHitbox();
				iconP2.angle = FlxMath.lerp(1, iconP2.angle, angleLerpValue);

				if (iconP22 != null)
				{
					var mult22:Float = FlxMath.lerp(1, iconP22.scale.x, expValue9);
					iconP22.angle = FlxMath.lerp(1, iconP22.angle, angleLerpValue);
					iconP22.scale.set(mult22, mult22);
					iconP22.updateHitbox();
				}

				if (iconP12 != null)
				{
					var mult12:Float = FlxMath.lerp(1, iconP12.scale.x, expValue9);
					iconP12.angle = FlxMath.lerp(1, iconP12.angle, angleLerpValue);
					iconP12.scale.set(mult12, mult12);
					iconP12.updateHitbox();
				}

			case 'Old Psych':
				// Cache lerp value for all icons
				var lerpValue = CoolUtil.boundTo(1 - elapsedPlayback * 30, 0, 1);

				iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, lerpValue)),
					Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, lerpValue)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, lerpValue)),
					Std.int(FlxMath.lerp(iconP2.frameHeight, iconP2.height, lerpValue)));

				if (iconP12 != null) {
					iconP12.setGraphicSize(Std.int(FlxMath.lerp(iconP12.frameWidth, iconP12.width, lerpValue)),
						Std.int(FlxMath.lerp(iconP12.frameHeight, iconP12.height, lerpValue)));
				}

				if (iconP22 != null) {
					iconP22.setGraphicSize(Std.int(FlxMath.lerp(iconP22.frameWidth, iconP22.width, lerpValue)),
						Std.int(FlxMath.lerp(iconP22.frameHeight, iconP22.height, lerpValue)));
				}

			case 'Strident Crisis':
				// Cache rate value
				var rateValue = 0.50 / _cachedPlaybackRate;

				iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, rateValue)),
					Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, rateValue)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, rateValue)),
					Std.int(FlxMath.lerp(iconP2.frameHeight, iconP1.height, rateValue)));
				iconP1.updateHitbox();
				iconP2.updateHitbox();

				if (iconP12 != null) {
					iconP12.setGraphicSize(Std.int(FlxMath.lerp(iconP12.frameWidth, iconP12.width, rateValue)),
						Std.int(FlxMath.lerp(iconP12.frameHeight, iconP12.height, rateValue)));
					iconP12.updateHitbox();
				}

				if (iconP22 != null) {
					iconP22.setGraphicSize(Std.int(FlxMath.lerp(iconP22.frameWidth, iconP22.width, rateValue)),
						Std.int(FlxMath.lerp(iconP22.frameHeight, iconP22.height, rateValue)));
					iconP22.updateHitbox();
				}

			case 'Dave and Bambi':
				// Cache rate value
				var rateValue = 0.8 / _cachedPlaybackRate;

				iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, rateValue)),
					Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, rateValue)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, rateValue)),
					Std.int(FlxMath.lerp(iconP2.frameHeight, iconP2.height, rateValue)));

				if (iconP12 != null) {
					iconP12.setGraphicSize(Std.int(FlxMath.lerp(iconP12.frameWidth, iconP12.width, rateValue)),
						Std.int(FlxMath.lerp(iconP12.frameHeight, iconP12.height, rateValue)));
				}

				if (iconP22 != null) {
					iconP22.setGraphicSize(Std.int(FlxMath.lerp(iconP22.frameWidth, iconP22.width, rateValue)),
						Std.int(FlxMath.lerp(iconP22.frameHeight, iconP22.height, rateValue)));
				}

			case 'Plank Engine':
				// Cache beat calculation once
				final funnyBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);
				final offsetY = Math.abs(Math.sin(funnyBeat * Math.PI)) * 16 - 4;

				iconP1.offset.y = offsetY;
				iconP2.offset.y = offsetY;
				if (iconP12 != null) iconP12.offset.y = offsetY;
				if (iconP22 != null) iconP22.offset.y = offsetY;

			case 'Golden Apple':
				iconP1.centerOffsets();
				iconP2.centerOffsets();
				if (iconP12 != null) iconP12.centerOffsets();
				if (iconP22 != null) iconP22.centerOffsets();

		}

		// Update hitboxes only if not using Plank Engine or Golden Apple
		if (bounceType != 'Plank Engine' && bounceType != 'Golden Apple') {
			iconP1.updateHitbox();
			iconP2.updateHitbox();
			if (iconP12 != null) iconP12.updateHitbox();
			if (iconP22 != null) iconP22.updateHitbox();
		}
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
				backend.COD.COD.COD = (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName}\'s ' : '') + "karma cought up.";
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

		if(!cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false))
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

		if(!cpuControlled && !ClientPrefs.getGameplaySetting('showcase', false))
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

		PlayfieldManager.curChart = [];

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
		conductor.target.time = startingPoint;
		if (SONG.needsVoices) setVocalsTime(startingPoint);
		lastUpdateTime = startingPoint;
		RConductor.visualPosition = startingPoint;
		RConductor.mapBPMChanges(SONG);

		//reGenerating = true;
		endingSong = false;
		songAboutToLoop = false;

		if ((curSong == "Small Argument" && inSecretSong && !inArchipelagoMode)
			&& AIPlayer.diff != 6
			&& comboManager.AIScore != comboManager.songScore) // Six is the highest there is. It's literally botplay at that point.
			AIPlayer.diff += 1;

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
		//initThreadAlt(regenNotes, 'Regen');
		var difficulty:String = Difficulty.getFilePath();
		playfield.loadChart(Paths.formatToSongPath(curSong)+difficulty, Paths.formatToSongPath(curSong));
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
						FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100, true);
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
						FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100, true);
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
						FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100, true);
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


	var overriddenEventNames:Array<String> = [];  // Events scripts are using.
	public function triggerEvent(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		var isEventOverridden:Bool = overriddenEventNames.contains(eventName)
			|| [for (lua in luaArray) if (lua != null) lua.scriptName.split('/').pop().split('.')[0]].concat(
				[for (hscript in hscriptArray) if (hscript != null) hscript.origin.split('/').pop().split('.')[0]]).concat(
				[for (yscript in yscriptArray) if (yscript != null) yscript.scriptPath.split('/').pop().split('.')[0]]).contains(eventName);

		if (!isEventOverridden)
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
							addCharacterToList(value2, charType);

							var oldChar = boyfriend;
							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend.shader = null;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
							for (field in playfields.members) {
								if (field.owner == oldChar) field.owner = boyfriend;
								if (field.owners.contains(oldChar)) field.owners.map(function(curChar) return curChar == oldChar ? boyfriend : curChar);
							}
							setOnScripts('boyfriendName', boyfriend.curCharacter);
						}

					case 1:
						if(dad.curCharacter != value2) {
							addCharacterToList(value2, charType);

							var oldChar = dad;
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
							for (field in playfields.members) {
								if (field.owner == oldChar) field.owner = dad;
								if (field.owners.contains(oldChar)) field.owners.map(function(curChar) return curChar == oldChar ? dad : curChar);
							}
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								addCharacterToList(value2, charType);

								var oldChar = gf;
								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf.shader = null;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
								for (field in playfields.members) {
									if (field.owner == oldChar) field.owner = gf;
									if (field.owners.contains(oldChar)) field.owners.map(function(curChar) return curChar == oldChar ? gf : curChar);
								}
							}
							setOnScripts('gfName', gf.curCharacter);
						}
					case 3:
						if (dad2 != null)
						{
							if (dad2.curCharacter != value2)
							{
								addCharacterToList(value2, charType);

								var oldChar = dad2;
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
								for (field in playfields.members) {
									if (field.owner == oldChar) field.owner = dad2;
									if (field.owners.contains(oldChar)) field.owners.map(function(curChar) return curChar == oldChar ? dad2 : curChar);
								}
							}
							setOnScripts('dad2Name', dad2.curCharacter);
						}
					case 4:
						if (bf2 != null)
						{
							if (bf2.curCharacter != value2)
							{
								addCharacterToList(value2, charType);

								var oldChar = bf2;
								var lastAlpha:Float = bf2.alpha;
								bf2.alpha = 0.00001;
								bf2.shader = null;
								bf2 = boyfriendMap2.get(value2);
								bf2.alpha = lastAlpha;
								iconP12.changeIcon(bf2.healthIcon);
								for (field in playfields.members) {
									if (field.owner == oldChar) field.owner = bf2;
									if (field.owners.contains(oldChar)) field.owners.map(function(curChar) return curChar == oldChar ? bf2 : curChar);
								}
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

			case 'SetCameraBop' | 'Set Camera Bopping': //P-slice event notes
				var val1 = Std.parseFloat(value1);
				var val2 = Std.parseFloat(value2);
				camZoomingMult = flValue2;
				camZoomingFrequency = flValue1;
				camZooming = true;

			case 'SetCameraBopBase': //V-slice event notes
				var val1 = Std.parseFloat(value1);
				var val2 = Std.parseFloat(value2);
				camZoomingMult = !Math.isNaN(val2) && val2>=1 ? val2 : 1;
				camZoomingFrequency = !Math.isNaN(val1) ? val1 : 4;

			case 'ZoomCamera' | 'Zoom Camera': //defaultCamZoom
				var keyValues = value1.split(",");
				var trueValues:Array<String> = [];
				if(keyValues.length != 2) {
					trace("INVALID EVENT VALUE! Attempting to salvage... Invalid: " + value1);
					if (keyValues.length > 2) {
						trueValues = [keyValues[0], keyValues[1]]; //default values
					} else if (keyValues.length == 1) {
						trueValues = ["0.5", keyValues[0]];
					} else {
						trace("Could not salvage Zoom Camera event!");
						return;
					}
				} else trueValues = keyValues;
				var floaties = trueValues.map(s -> Std.parseFloat(s));
				if(backend.util.ArrayTools.findIndex(floaties,s -> Math.isNaN(s)) != -1) {
					trace("INVALID FLOATIES");
					return;
				}
				var easeFunc = LuaUtils.getTweenEaseByString(value2);
				if(zoomTween != null) zoomTween.cancel();
				var targetZoom = floaties[1]*(defaultStageZoom*1.3);
				if(value2.toLowerCase() == "classic"){
					camZooming = true;
					defaultCamZoom = targetZoom;
				} else if(value2.toLowerCase() == "instant") {
					camZooming = true;
					defaultCamZoom = targetZoom;
					camGame.zoom = targetZoom;
				}
				else{
					zoomTween = FlxTween.tween(camGame, {zoom: targetZoom}, Conductor.stepCrochet*0.001*floaties[0]/playbackRate, {
						onStart: (x) ->{
							camZooming = false;
							camZoomingDecay = 7;
						},
						ease: easeFunc,
						onComplete: (x) ->{
							defaultCamZoom = targetZoom;
							camZoomingDecay = 1;
							camZooming = true;
							zoomTween = null;
						}
					});
				}

			case 'FocusCamera' | 'Target Camera': //V-slice event notes val1: char val2: x,y,dur,ease
				var keyValues = value2.trim().split(",");
				if(keyValues.length != 4 && value1.length <= 0) {
					trace("INVALID EVENT VALUE");
					isCameraOnForcedPos = false;
					return;
				}
				var ease = keyValues.pop().trim().toLowerCase();
				var floaties = keyValues.map(s -> Std.parseFloat(s));
				if(floaties.length != 4 && backend.util.ArrayTools.findIndex(floaties,s -> Math.isNaN(s)) != -1) {
					trace("INVALID FLOATIES: " + value2);
					return;
				}
				isCameraOnForcedPos = true;

				var targetx = floaties[0];
				var targety = floaties[1];
				var dur = Conductor.stepCrochet*0.001*floaties[2];
				switch (value1){
					case "bf"|"0":{
						targetx += boyfriend.getMidpoint().x -100 - boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
						targety += boyfriend.getMidpoint().y -100 + boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
					}
					case "dad"|"1":{
						targetx += dad.getMidpoint().x +150 + dad.cameraPosition[0] + opponentCameraOffset[0];
						targety += dad.getMidpoint().y -100 + dad.cameraPosition[1] + opponentCameraOffset[1];
					}
					case "gf"|"2":{
						targetx += gf.getMidpoint().x + gf.cameraPosition[0] - girlfriendCameraOffset[0];
						targety += gf.getMidpoint().y + gf.cameraPosition[1] - girlfriendCameraOffset[1];
					}
				}

				if(ease == "classic"){
					FlxG.camera.followLerp = _cachedCameraLerp;
					camFollow.x = targetx;
					camFollow.y = targety;
					//trace("RUNNING CLASSIC CAM MOVEMENT!");
				} else if(ease == "instant") {
					FlxG.camera.followLerp = 1000000000000;
					camGame.followLerp = 1000000000000;
					camFollow.x = targetx;
					camFollow.y = targety;
					try { if (FlxG.camera != null) FlxG.camera.snapToTarget(); } catch (e) { trace('snapToTarget error: $e'); }
					//trace("RUNNING INSTANT CAM MOVEMENT!");
				} else {
					FlxG.camera.followLerp = _cachedCameraLerp;
					//trace('RUNNING ${ease.toUpperCase()} CAM MOVEMENT!');
					var easeFunc = psychlua.LuaUtils.getTweenEaseByString(ease);
					camTween?.cancel();
					camTween = FlxTween.tween(camFollow,{x:targetx,y:targety},dur/playbackRate,{
							ease: easeFunc,
							onComplete: s -> {
									camTween = null;
							}
					});
				}

			case 'Change Mania':
				var newMania:Int = 0;
				var skipTween:Bool = value2 == "true" ? true : false;

				newMania = Std.parseInt(value1);
				if (Math.isNaN(newMania) && newMania < Note.minMania && newMania > Note.maxMania)
					newMania = 0;
				playfield.changeMania(newMania, skipTween);

			case 'Change Mania (Special)':
				/*var newMania:Int = 0;
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
				changeMania(newMania, skipTween);*/

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
				modManager.queueEase(conductor.currentStep, conductor.currentStep + 4, 'alpha', 0, 'sineInOut', 0);
				modManager.queueEase(conductor.currentStep, conductor.currentStep + 4, 'alpha', 0, 'sineInOut', 1);

			case 'Fade Out':
				FlxTween.tween(blackOverlay, {alpha: 1}, Std.parseFloat(value1)/playbackRate);
				FlxTween.tween(camHUD, {alpha: 0}, Std.parseFloat(value1)/playbackRate);

			case 'Fade In':
				FlxTween.tween(blackOverlay, {alpha: 0}, Std.parseFloat(value1)/playbackRate);
				FlxTween.tween(camHUD, {alpha: 1}, Std.parseFloat(value1)/playbackRate);

			case 'Silhouette':
				theShadow(value1);

			case 'Save Song Posititon':
				trace(Conductor.songPosition);
				savedTime = Conductor.songPosition;
				FlxG.save.data.storyWeek = PlayState.storyWeek;
				FlxG.save.data.currentModDirectory = Mods.currentModDirectory;
				FlxG.save.data.difficulties = Difficulty.list; // just in case
				FlxG.save.data.SONG = PlayfieldManager.SONG;
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

				for (yscript in yscriptArray)
				{
					if (yscript.scriptPath == 'stages/' + stageName + '.ys')
					{
						return;
					}
					else if (yscript.scriptPath == 'stages/' + curStage + '.ys')
					{
						if(yscript != null)
						{
							if(yscript.hasFunction('onDestroy')) yscript.callFunction('onDestroy');
							yscript.destroy();
						}
					}
				}

				for (stage in stages)
				{
					if (stage is BaseStage)
					{
						stages.remove(stage);
						stage.destroy();
					}
				}

				stagesFunc(function(stage:BaseStage) stage.destroy());

				// Load stage with full data reload
				loadSingleStageFile(stageName, true);
				var scripts:Array<Array<Dynamic>> = [luaArray, hscriptArray, yscriptArray];
				stagesFunc(function(stage:BaseStage) stage.createPost());
				for (stuff in scripts)
				{
					for (script in stuff)
					{
						if (script is HScript)
						{
							var script:HScript = cast(script);
							if (script.origin == 'stages/' + curStage + '.hx' || script.origin == 'stages/' + stageName + '.lua')
							{
								script.call('onCreatePost', []);
							}
						}
						else if (script is FunkinLua)
						{
							var script:FunkinLua = cast(script);
							if (script.scriptName == 'stages/' + curStage + '.lua')
							{
								script.call('onCreatePost', []);
							}
						} else if (script is YScript)
						{
							var script:YScript = cast(script);
							if (script.scriptPath == 'stages/' + curStage + '.ys' || script.scriptPath == 'stages/' + stageName + '.yscript')
							{
								script.callFunction('onCreatePost', []);
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
					playfield.freezeNotes = true;
					playfield.localFreezeNotes = true;
				}
				else
				{
					playfield.freezeNotes = false;
					playfield.localFreezeNotes = false;
				}
		}
		else {overriddenEventNames.push(eventName); trace('Event ' + eventName + ' was overridden by a script!');}

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
		if(sec == null) sec = conductor.currentMeasure;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			callOnScripts('onMoveCamera', ['gf']);
			setOnScripts('whosTurn', 'gf');
			whosTurn = 'gf';
			return;
		}

		if (dad2 != null && SONG.notes[conductor.currentMeasure].exSection && !SONG.notes[conductor.currentMeasure].mustHitSection)
		{
			camFollow.setPosition(dad2.getMidpoint().x, dad2.getMidpoint().y);
			camFollow.x += dad2.cameraPosition[0] + opponent2CameraOffset[0];
			camFollow.y += dad2.cameraPosition[1] + opponent2CameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['dad2']);
			setOnScripts('whosTurn', 'dad2');
			whosTurn = 'dad';
			return;
		}

		if (bf2 != null && SONG.notes[conductor.currentMeasure].exSection && !SONG.notes[conductor.currentMeasure].gfSection && SONG.notes[conductor.currentMeasure].mustHitSection)
		{
			camFollow.setPosition(bf2.getMidpoint().x, bf2.getMidpoint().y);
			camFollow.x += bf2.cameraPosition[0] + boyfriend2CameraOffset[0];
			camFollow.y += bf2.cameraPosition[1] + boyfriend2CameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['bf2']);
			setOnScripts('whosTurn', 'bf2');
			whosTurn = 'bf2';
			return;
		}

		var isDad:Bool = (!SONG.notes[conductor.currentMeasure].exSection && SONG.notes[sec].mustHitSection != true);
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
		var desiredPos:Null<FlxPoint> = null;
		var curCharacter:Null<Character> = null;

		if (dadField != null && playerField != null) curCharacter = isDad ? dadField.owner : playerField.owner;
		else curCharacter = isDad ? dad : boyfriend;

		if (camCurTarget != null) curCharacter = camCurTarget;

		desiredPos = getCharacterCameraPos(curCharacter);

		camFollow.x = desiredPos.x;
		camFollow.y = desiredPos.y;

		desiredPos.put();
		setOnScripts('whosTurn', isDad ? 'dad' : 'boyfriend');
		whosTurn = (isDad ? 'dad' : 'boyfriend');
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
	public function getCharacterCameraPos(char:Null<Character>):FlxPoint
	{
		if (char == null) return FlxPoint.weak();

		final desiredPos = char.getMidpoint();

		final offsets = char.isPlayer ? boyfriendCameraOffset : opponentCameraOffset;

		desiredPos.y += -100 + char.cameraPosition[1] + offsets[1];

		if (char.isPlayer)
		{
			desiredPos.x -= 100 + char.cameraPosition[0];
		}
		else
		{
			desiredPos.x += 100 + char.cameraPosition[0];
		}

		desiredPos.x += offsets[0];

		return desiredPos;
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
		// DEBUG: Comprehensive playlist tracking
		trace('=== PlayState.endSong() CALLED ===');
		trace('isPlaylist: ${PlayState.isPlaylist}');
		trace('isWarmUp: ${isWarmUp}');
		trace('curSonglist: ${curSonglist}');
		if (curSonglist != null) trace('curSonglist length: ${curSonglist.length}');
		trace('inArchipelagoMode: ${archipelago.APEntryState.inArchipelagoMode}');
		trace('=============================');

		//Should kill you if you tried to cheat
		trace('About to check startingSong: ${startingSong}');
		if(!startingSong)
		{
			trace('startingSong is false, calling doDeathCheck()');
			if(doDeathCheck()) {
				trace('doDeathCheck returned true, returning false from endSong');
				return false;
			}
			trace('doDeathCheck returned false, continuing');
		}
		trace('Passed doDeathCheck, continuing...');

		timeBar.visible = false;
		trace('SET timeBar.visible = false');
		timeTxt.visible = false;
		trace('SET timeTxt.visible = false');
		canPause = false;
		trace('SET canPause = false');
		endingSong = true;
		trace('SET endingSong = true');
		camZooming = false;
		trace('SET camZooming = false');
		inCutscene = false;
		trace('SET inCutscene = false');
		updateTime = false;
		trace('SET updateTime = false');
		seenCutscene = false;
		trace('SET seenCutscene = false');
		inSecretSong = false;
		trace('SET inSecretSong = false');

		#if ACHIEVEMENTS_ALLOWED
		trace('=== ENTERING ACHIEVEMENTS CHECK ===');
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		var week:String = WeekData.getWeekFileName();
		trace('Calling checkForAchievement...');
		checkForAchievement([weekNoMiss, week, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'potato', 'debugger', 'play_fnf', 'pico_mixed', 'pico_stressed', 'l', 'a_freaky', 'freaky', 'true_funker', 'nice', 'mfc', 'sfc', 'gfc', 'afc', 'fc', 'sdcb', 'clear', 'erect', 'nightmare', 'challenger', 'hardcore', 'demon', 'persistent', 'resilient', 'truepotatogaming', 'mattdestroyer', 'matteleminator', 'mattgod', 'matt', 'mattbeyond']);
		trace('=== COMPLETED ACHIEVEMENTS CHECK ===');
		#end

		trace('=== ABOUT TO CALL callOnScripts ===');
		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		trace('=== callOnScripts returned ===');
		trace('ret value: ${ret}');
		trace('LuaUtils.Function_Stop: ${LuaUtils.Function_Stop}');
		trace('ret != LuaUtils.Function_Stop: ${ret != LuaUtils.Function_Stop}');
		trace('transitioning: ${transitioning}');
		trace('Condition result: ${ret != LuaUtils.Function_Stop && !transitioning}');

		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			PlayfieldManager.curChart = [];
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

			trace('=== CHECKING PLAYLIST/WARMUP LOGIC ===');
			trace('About to check: isWarmUp (${isWarmUp}) || isPlaylist (${PlayState.isPlaylist})');

			if (isWarmUp || isPlaylist)
			{
				trace('ENTERED playlist/warmup block');
				campaignScore += comboManager.songScore;
				campaignMisses += comboManager.songMisses;

				var lastSong = curSonglist[0];
				trace('lastSong: ${lastSong}');
				curSonglist.shift();
				trace('After remove, curSonglist.length: ${curSonglist.length}');

				if (curSonglist.length <= 0)
				{
					if (isWarmUp) {
						ClientPrefs.data.warmupCompleted = true;
						isWarmUp = false;
					}
					canResync = false;
					gameplayArea = isPlaylist ? "Playlist" : "Warmup";
					changedDifficulty = false;
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						camHUD.alpha -= 1 / 10;
					}, 10);

					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay') && !ClientPrefs.getGameplaySetting('showcase', false) && !archipelago.APEntryState.inArchipelagoMode) {
						Highscore.savePlaylistScore(curPlaylist.playlistName, campaignScore);
						FlxG.save.flush();
					}

					#if ARCHIPELAGO_ALLOWED
					if (archipelago.APEntryState.inArchipelagoMode && Std.isOfType(this, archipelago.APPlayState)) {
						var apPlayState = cast(this, archipelago.APPlayState);

						// Collect all checks to send
						var allNoteChecks = apPlayState.instanceDeferredNoteChecks.copy();
						var allLocationChecks = apPlayState.instanceDeferredLocationChecks.copy();

						// Add final song's checks
						if (apPlayState.checkedNotes != null && apPlayState.checkedNotes.length > 0) {
							for (note in apPlayState.checkedNotes) {
								@:privateAccess {
									allNoteChecks.push(note.checkInfo.loc);
								}
							}
						}

						// Add final song location checks
						if (archipelago.APInfo.unlockMethod != "Note Checks") {
							var songLocationIds = archipelago.APEntryState.apGame.locationData(archipelago.APPlayState.currentSong.trim(), archipelago.APPlayState.currentMod.trim());
							if (songLocationIds != null) {
								for (locId in songLocationIds) {
									if (locId != 0) {
										allLocationChecks.push(locId);
									}
								}
							}
						}

						// Send all checks at once
						if (allNoteChecks.length > 0) {
							trace('Sending ${allNoteChecks.length} accumulated note checks');
							archipelago.APPlayState.apGame.info().LocationChecks(allNoteChecks);
						}
						if (allLocationChecks.length > 0) {
							trace('Sending ${allLocationChecks.length} accumulated location checks');
							archipelago.APPlayState.apGame.info().LocationChecks(allLocationChecks);
						}

						// Return to playlist
						openSubState(new StickerSubState(function(s) {
							return new archipelago.APPlaylistState();
						}));
					} else if (archipelago.APEntryState.inArchipelagoMode) {
						openSubState(new StickerSubState(function(s) {
							return new archipelago.APPlaylistState();
						}));
					} else {
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
						}
					}
				#else
				{
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
					}
				}
				#end
				}
				else
				{
					trace('=== MORE SONGS REMAIN IN PLAYLIST ===');
					// More songs remain in playlist
					// For AP mode: transfer checks from this song to next instance
					#if ARCHIPELAGO_ALLOWED
					if (archipelago.APEntryState.inArchipelagoMode && Std.isOfType(this, archipelago.APPlayState)) {
						var apPlayState = cast(this, archipelago.APPlayState);

						// Will be transferred via funcAndReturn below
					}
					#end

					// Update to next song
					Mods.loadTopMod();
					WeekData.reloadWeekFiles();
					storyWeek = curSonglist[0].week;
					Difficulty.loadFromWeek();
					Mods.currentModDirectory = curSonglist[0].folder ?? '';
					storyDifficulty = Difficulty.list.indexOf(curSonglist[0].difficulty);
					var difficulty:String = Difficulty.getFilePath();
					APPlayState.currentSong = curSonglist[0].songName;
					APPlayState.currentMod = curSonglist[0].folder ?? '';

					trace('LOADING NEXT SONG');
					trace(curSonglist[0]);
					trace(Paths.formatToSongPath(curSonglist[0].songName) + difficulty);
					trace(Paths.formatToSongPath(curSonglist[0].songName) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					// Set AP variables for next song if in AP mode
					#if ARCHIPELAGO_ALLOWED
					var nextState:archipelago.APPlayState = null;
					if (archipelago.APEntryState.inArchipelagoMode && Std.isOfType(this, archipelago.APPlayState)) {
						var apPlayState = cast(this, archipelago.APPlayState);
						archipelago.APPlayState.currentSong = curSonglist[0].songName;
						archipelago.APPlayState.currentMod = curSonglist[0].folder != null ? curSonglist[0].folder : '';

						// Create next APPlayState with deferred checks transferred via funcAndReturn
						// Only pass songlist for progression (like normal PlayState), no playlist
						nextState = new archipelago.APPlayState(null, curSonglist).funcAndReturn((state) -> {
							// Transfer accumulated checks from current instance
							state.instanceDeferredLocationChecks = apPlayState.instanceDeferredLocationChecks.copy();
							state.instanceDeferredNoteChecks = apPlayState.instanceDeferredNoteChecks.copy();

							// Add note checks from this song
							if (apPlayState.checkedNotes != null && apPlayState.checkedNotes.length > 0) {
								trace('Adding ${apPlayState.checkedNotes.length} note checks to deferred');
								for (note in apPlayState.checkedNotes) {
									@:privateAccess {
										state.instanceDeferredNoteChecks.push(note.checkInfo.loc);
									}
								}
							}

							// Add song location checks based on unlock method
							if (archipelago.APInfo.unlockMethod != "Note Checks") {
								var songLocationIds = archipelago.APEntryState.apGame.locationData(archipelago.APPlayState.currentSong.trim(), archipelago.APPlayState.currentMod.trim());
								if (songLocationIds != null && songLocationIds.length > 0) {
									trace('Adding ${songLocationIds.length} location checks to deferred');
									for (locId in songLocationIds) {
										if (locId != 0) {
											state.instanceDeferredLocationChecks.push(locId);
										}
									}
								}
							}
						});
					}
					#end
					#if !switch
					var percent:Float = comboManager.ratingPercent;
					if(Math.isNaN(percent)) percent = 0;
					// Don't save scores in AP mode
					#if ARCHIPELAGO_ALLOWED
					if (!archipelago.APEntryState.inArchipelagoMode) {
						Highscore.saveScore(Song.loadedSongName, comboManager.songScore, storyDifficulty, percent, comboManager.songMisses, deathCounter);
					}
					#else
					Highscore.saveScore(Song.loadedSongName, comboManager.songScore, storyDifficulty, percent, comboManager.songMisses, deathCounter);
					#end
					#end
					canResync = false;

					// Load the next song chart
					trace(curSonglist[0].folder);
					trace(Mods.currentModDirectory);
					Song.loadFromJson(Paths.formatToSongPath(curSonglist[0].songName) + difficulty, curSonglist[0].songName);

					//LoadingState.prepareToSong();

					#if ARCHIPELAGO_ALLOWED
					if (archipelago.APEntryState.inArchipelagoMode && nextState != null) {
						LoadingState.loadAndSwitchState(nextState);
					} else if (archipelago.APEntryState.inArchipelagoMode) {
						LoadingState.loadAndSwitchState(new archipelago.APPlayState(null, curSonglist));
					} else {
						LoadingState.loadAndSwitchState(new PlayState(curPlaylist, curSonglist));
					}
					#else
					LoadingState.loadAndSwitchState(new PlayState(curPlaylist, curSonglist));
					#end
				}
			}
			else if (isStoryMode)
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
					if (ClientPrefs.data.freeplayMenu == "Base Game") {
						states.CategoryState.instaFreeplay = true;
						states.CategoryState.freeplayStuff.fromResults = {
							oldRank: prevScoreRank,
							newRank: fpRank,
							songId: curSong,
							difficultyId: Difficulty.getString(),
							playRankAnim: !botplay
						};
						FlxG.switchState(() -> states.freeplay.VSliceFreeplayState.build());
					} else {
						TransitionState.transitionState(FreeplayManager.getFreeplayState(), {transitionType: "stickers"});
					}
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
			FlxG.camera.follow(boyfriend, null, 0.04);
		}
		else if (targetDad)
		{
			FlxG.camera.follow(dad, null, 0.04);
		}
		else
		{
			FlxG.camera.follow(gf, null, 0.04);
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

		var isPlaylist:Bool = (gameplayArea == "Playlist" || gameplayArea == "Warmup");

		var res:substates.ResultState = new substates.ResultState({
			storyMode: isStoryMode,
			playlistMode: isPlaylist,
			songId: curSong,
			difficultyId: Difficulty.getString(),
			title: isPlaylist ? '${curPlaylist.playlistName} complete!' : (isStoryMode ? ('${storyCampaignTitle}') : fpText),
			scoreData: scoreData,
			prevScoreRank: prevScoreRank,
			isNewHighscore: isNewHighscore,
			characterId: SONG.player1
		});
		this.persistentDraw = false;
		//FreeplayManager.openFreeplay();
		openSubState(res);
		// curPlaylist = null;
		// curSonglist = null;
	}

	public function KillNotes()
	{
		notes.clear();
		allNotes = [];
		unspawnNotes = [];
		playfield.noteManager.clearAllNotes();
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
		vocals.volume = 1 * (vocalVolumeMultiplier * vocalVolumeMultiplierHardMode);

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

	// === PERFORMANCE OPTIMIZATION FUNCTIONS ===
	/**
	 * Initialize all performance optimization settings and cached values
	 * This is called once during PlayState creation to set up optimization infrastructure
	 */
	private function initializeOptimizations():Void {
		// Cache frequently accessed ClientPrefs values
		_cachedDownScroll = ClientPrefs.data.downScroll;
		_cachedMiddleScroll = ClientPrefs.data.middleScroll;
		_cachedIconBounceType = ClientPrefs.data.iconBounce;
		_cachedTimeBarType = ClientPrefs.data.timeBarType;
		_cachedPlaybackRate = playbackRate;
		_cachedFramerateMultiplier = ClientPrefs.data.framerate / 60.0;

		// Calculate optimal batching threshold based on target framerate
		_batchedUpdateThreshold = Std.int(Math.max(1, ClientPrefs.data.framerate / 60));

		// Enable performance optimizations based on client settings
		_useOptimizedNoteLoop = true; // Always use optimized loop
		_useCachedStrumPositions = ClientPrefs.data.framerate >= 120; // Cache positions for high framerate
		_reduceQualityMode = ClientPrefs.data.framerate >= 240; // Reduce quality for very high framerate

		// Pre-calculate common math values
		_cachedCameraLerp = 0.04 * cameraSpeed * playbackRate;

		// Initialize cached arrays with appropriate size
		if (_useCachedStrumPositions) {
			playfield._cachedStrumPositions = [];
			playfield._cachedNotePositions = [];
			for (i in 0...Note.ammo[mania[1]]) {
				playfield._cachedStrumPositions.push(0);
				playfield._cachedNotePositions.push(0);
			}
		}

		// Enable batched updates for high performance scenarios
		_batchUIUpdates = _reduceQualityMode;
		_batchIconUpdates = ClientPrefs.data.framerate >= 120;
		_batchCameraUpdates = ClientPrefs.data.framerate >= 240;

		// Performance logging
		trace('Performance optimizations initialized:');
		trace('  - Batched updates: ${_batchUIUpdates}');
		trace('  - Cached strums: ${_useCachedStrumPositions}');
		trace('  - Reduce quality: ${_reduceQualityMode}');
		trace('  - Batch threshold: ${_batchedUpdateThreshold}');
	}

	/**
	 * Update cached values that may change during gameplay
	 * This should be called less frequently than every frame
	 */
	private function refreshCachedValues():Void {
		if (_cachedPlaybackRate != playbackRate) {
			_cachedPlaybackRate = playbackRate;
			_cachedCameraLerp = 0.04 * cameraSpeed * playbackRate;
		}

		// Update frame-dependent calculations
		var currentFrameMultiplier = ClientPrefs.data.framerate / 60.0;
		if (_cachedFramerateMultiplier != currentFrameMultiplier) {
			_cachedFramerateMultiplier = currentFrameMultiplier;
			_batchedUpdateThreshold = Std.int(Math.max(1, ClientPrefs.data.framerate / 60));
		}
	}

	/**
	 * Optimized sine wave calculation with caching for UI animations
	 */
	private inline function getCachedSinValue(input:Float):Float {
		// Cache sine calculation for commonly used values
		return Math.sin((Math.PI * input) / 180);
	}

	/**
	 * Optimized exponential lerp calculation with caching
	 */
	private inline function getCachedExpLerp(elapsed:Float, speed:Float):Float {
		// Pre-calculate expensive exponential operations
		return Math.exp(-elapsed * speed * _cachedPlaybackRate);
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

		hasYScripts = (yscriptArray != null && yscriptArray.length > 0);

		#if PYTHON_ALLOWED
		hasPyScripts = (pyScriptArray != null && pyScriptArray.length > 0);
		#else
		hasPyScripts = false;
		#end

		// Optimize script batching based on script count
		var totalScripts = 0;
		#if LUA_ALLOWED
		if (luaArray != null) totalScripts += luaArray.length;
		if (legacyLuaArray != null) totalScripts += legacyLuaArray.length;
		#end
		#if HSCRIPT_ALLOWED
		if (hscriptArray != null) totalScripts += hscriptArray.length;
		#end
		if (yscriptArray != null) totalScripts += yscriptArray.length;
		#if PYTHON_ALLOWED
		if (pyScriptArray != null) totalScripts += pyScriptArray.length;
		#end

		// Enable batched script calls for performance when many scripts are loaded
		_skipRedundantUpdates = totalScripts > 5;
	}

	private function updateGroupIndices():Void {
		// Only update indices when necessary to avoid repeated indexOf calls
		if (_noteGroupIndex == -1) {
			_noteGroupIndex = members.indexOf(noteGroup);
			_gfGroupIndex = members.indexOf(gfGroup);
			_dadGroupIndex = members.indexOf(dadGroup);
			_dadGroup2Index = members.indexOf(dadGroup2);
			_boyfriendGroupIndex = members.indexOf(boyfriendGroup);
			_boyfriendGroup2Index = members.indexOf(boyfriendGroup2);
			_uiGroupIndex = members.indexOf(uiGroup);
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

	function noteMiss(daNote:Note, field:PlayField):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		var result:Dynamic = callOnLuas('preNoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) result = callOnHScript('preNoteMiss', [daNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('preNoteMiss', [daNote]);
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) result = callOnHScript('noteMiss', [daNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('noteMiss', [daNote]);
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



		if(instakillOnMiss && note.field.isPlayer)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			gfVocals.volume = 0;
			die();
			COD.setPresetCOD(note, 'miss');
		}

		COD.setPresetCOD(note, 'miss0');

		try {
			if (note != null) {
				switch (note.noteType)
				{
					case 'Kill Note':
						noTriggerKarma = true;
						die();
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Hit a Kill Note.');
						noTriggerKarma = false;
						FlxG.sound.play(Paths.sound('explosion'));

						if (mechanicsResult[1] != null)
							mechanicsResult[1].value += 20;

					case 'Swap Note':
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Failed to tell the difference between your notes and your opponents.');

					case 'Throat Note':
						throatnoteTweens[note.column] = FlxTween.tween(note.field.strumNotes[note.column], {multAlpha: 0.3}, 1, {
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
						COD.setCOD(null, (boyfriend.charName != null && (boyfriend.charName != '???' && boyfriend.charName != '') ? '${boyfriend.charName} ' : '') + "Couldn't clear their throat. (Have you tried Throat Medicine?)");
				}
			}
		} catch(e) {trace("NoteType Broke!");}

		if (note?.field.isPlayer)
			bfkilledcheck = true;

		var lastCombo:Int = comboManager.combo;
		comboManager.combo = 0;

		if (note?.field.isPlayer) {
			switch (curHealthMode) {
				case "Kade":
					if (note != null) {
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
					}

				case "Tabi":
					if (note != null && !note.isSustainNote) health -= 0.1;
					health -= 0.0475;
					health -= 0.04;
					health -= 0.08;

				case "Amalgam":
					//Basically, don't miss lol
					if (note != null) {
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
					}
					health -= 0.0475;
					health -= 0.04;
					health -= 0.08;
					health -= subtract * healthLoss;

				default:
					health -= subtract * healthLoss;
			}
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
		if((note != null && note.gfNote) || (SONG.notes[conductor.currentMeasure] != null && SONG.notes[conductor.currentMeasure].gfSection)) char = gf;
		if (note != null) {
			if (opponentmode || note.field == dadField)
				char = dad;
			if (note.exNote && note.field == playerField)
				char = bf2;
			if (note.exNote && note.field == dadField)
				char = dad2;
		}
		if (note != null) {
			if (note.field.owners != null && note.field.owners.length != 0) {
				for (owner in note.field.owners) {
					if(owner != null && (note == null || !note.noMissAnimation) && owner.hasMissAnimations)
					{
						var postfix:String = '';
						if(note != null) postfix = note.animSuffix;

						var animToPlay:String = Note.keysShit.get(mania[note.fieldIndex]).get('singAnims')[Std.int(direction)] + 'miss' + postfix;
						owner.playAnim(animToPlay, true);

						if(owner != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
						{
							if (note?.field.isPlayer) {
								gf.playAnim('sad');
								gf.specialAnim = true;
							}
						}
					}
				}
			} else if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations) {
				var postfix:String = '';
				if(note != null) postfix = note.animSuffix;

				var animToPlay:String = Note.keysShit.get(mania[note.fieldIndex]).get('singAnims')[Std.int(direction)] + 'miss' + postfix;
				char.playAnim(animToPlay, true);

				if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
				{
					if (note?.field.isPlayer) {
						gf.playAnim('sad');
						gf.specialAnim = true;
					}
				}
			}
		} else {
			if(char != null && (note == null || note != null && !note.noMissAnimation) && char.hasMissAnimations) {
				var postfix:String = '';
				if(note != null) postfix = note.animSuffix;

				var animToPlay:String = Note.keysShit.get(mania[note.fieldIndex]).get('singAnims')[Std.int(direction)] + 'miss' + postfix;
				char.playAnim(animToPlay, true);

				if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
				{
					if (note?.field.isPlayer) {
						gf.playAnim('sad');
						gf.specialAnim = true;
					}
				}
			}
		}

		if (note?.field.isPlayer)
			vocals.volume = 0 * (vocalVolumeMultiplier * vocalVolumeMultiplierHardMode);
		else
			if(opponentVocals?.length > 0)
				opponentVocals.volume = 1 * (vocalVolumeMultiplier * vocalVolumeMultiplierHardMode);

		if (curHealthMode == "Lives" && lives > 0)
		{
			lives -= 1;
			if (ClientPrefs.data.flashing)
			{
				FlxG.camera.flash(0xFFFF0000, 0.3 * SONG.bpm / 100, true);
			}
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				if (gf != null) gf.playAnim('sad', true);
			});
			FlxG.sound.play(Paths.sound('fnf_loss_sfx'));
			health = 1 / lives * lives;
		}
			if (note.cod != null && note.cod.trim() != '') {
			COD.setCOD(note.cod);
		}
	}

	public function opponentNoteHit(note:Note, field:PlayField):Void
	{
		var result:Dynamic;
		if (opponentmode)
		{
			result = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);
			if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('goodNoteHitPre', [note]);
		}
		else
		{
			result = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
			if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);
			if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('opponentNoteHitPre', [note]);
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
			var char:Character = field.owner;
			var animToPlay:String = Note.keysShit.get(mania[note.fieldIndex]).get('singAnims')[note.noteData] + note.animSuffix;
			if(note.gfNote) char = gf;
			if (note.exNote && !note.gfNote) char = (opponentmode ? bf2 : dad2);
			if (note.owner != null) char = note.owner;

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

			if (field.owners != null && field.owners.length != 0) {
				for (owner in field.owners) {
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(owner.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(owner.getAnimationName() == holdAnim || owner.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}

					if(canPlay) playAnim(note, owner, animToPlay, true);
					owner.holdTimer = 0;
				}
			}
			else if(char != null)
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
			backend.COD.COD.COD = (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + "couldn't handle the opponent's sheer skill.";
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
					mechanicsMod.lastHealth = Math.max(health - lossHealth, minHealth + minHealthOffset + 0.1);
				else
					health = Math.max(health - lossHealth, minHealth + minHealthOffset + 0.1);
				if (mechanicsResult[9] != null)
					mechanicsResult[9].value += lossHealth * 10;
				noTriggerKarma = false;
			}
		}

		if(opponentVocals.length <= 0) vocals.volume = 1 * (vocalVolumeMultiplier * vocalVolumeMultiplierHardMode);
		strumPlayAnim(field, note.column % field.keyCount, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('opponentNoteHit', [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note, field:PlayField):Void
	{
		if(note.wasGoodHit) return;
		if ((cpuControlled || ClientPrefs.getGameplaySetting('showcase', false)) && (note.ignoreNote || note.hitCausesMiss)) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		if (note.expectedData != -1)
			FlxTween.cancelTweensOf(note);

		note.wasGoodHit = true;

		if (songName != 'tutorial')
			camZooming = true;

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(!note.hitCausesMiss) //Common notes
		{
			// Register note hit for TPS/NPS calculation
			if (!note.isSustainNote) notesHitArray.unshift(Date.now());

			if(!note.noAnimation)
			{
				var animToPlay:String = Note.keysShit.get(mania[note.fieldIndex]).get('singAnims')[note.noteData] + note.animSuffix;

				var char:Character = field.owner;
				var animCheck:String = 'hey';
				if (note.exNote && !note.gfNote && note.noteType != 'GF Duet') char = (opponentmode ? dad2 : bf2);
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}
				if (note.owner != null) char = note.owner;

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

				if (field.owners != null && field.owners.length != 0) {
					for (owner in field.owners) {
						var canPlay:Bool = true;
						if(note.isSustainNote)
						{
							var holdAnim:String = animToPlay + '-hold';
							if(owner.animation.exists(holdAnim)) animToPlay = holdAnim;
							if(owner.getAnimationName() == holdAnim || owner.getAnimationName() == holdAnim + '-loop') canPlay = false;
						}

						var specialAnim:String = animToPlay;
						// Band-Aid fix but I don't care LMAO
						if (owner.curCharacter == "sserafim-sakura" && note.noteType == "sakura-joint")
							specialAnim = animToPlay + '-both';

						if(canPlay) playAnim(note, owner, specialAnim, true);
						owner.holdTimer = 0;

						if(note.noteType == 'Hey!')
						{
							if(owner.hasAnimation(animCheck))
							{
								owner.playAnim(animCheck, true);
								owner.specialAnim = true;
								owner.heyTimer = 0.6;
							}
						}
					}
				}
				else if(char != null)
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
			vocals.volume = 1 * (vocalVolumeMultiplier * vocalVolumeMultiplierHardMode);

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
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Hit a Kill Note.');
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
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Hit a Kill Note.');
					case 'Burst Note':
						mechanicsMod.burstNote();
						lastKill = 2;
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Sufficated under pressure.');
					case 'Sleep Note':
						mechanicsMod.sleepNote();
						lastKill = 5;
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Fell asleep and died.');
					case 'Swap Note':
						if (mechanicsResult[6] != null)
							mechanicsResult[6].value += note.missHealth * 10;
						COD.setCOD(null, (boyfriend.charName != null && boyfriend.charName != '???' && boyfriend.charName != '' ? '${boyfriend.charName} ' : '') + 'Couldn\'t keep up with the notes.');
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
					mechanicsMod.lastHealth += note.hitHealth * healthGain;
			}
		}

		bfkilledcheck = false;

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHit', [note]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopYScript && result != LuaUtils.Function_StopAll) callOnYScript('goodNoteHit', [note]);
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
			playfield.noteManager.recycleNote(note);
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

	public function playAnim(note:Note, char:Character, animToPlay:String, ?forceAnim:Bool = false) {
		if(char != null)
		{
			char.holdTimer = 0;
			if (!note.isSustainNote
				&& playfield.noteRows[note.mustPress ? 0 : 1][note.row] != null
				&& playfield.noteRows[note.mustPress ? 0 : 1][note.row].length > 1
				&& note.noteType != "Ghost Note" && ghostsAllowed) {
				// potentially have jump anims?
				var chord = playfield.noteRows[note.mustPress ? 0 : 1][note.row];
				var animNote = chord[0];
				var realAnim = note.field.singAnimations[Std.int(Math.abs(animNote.noteData))] + note.animSuffix;
				if (char.mostRecentRow != note.row)
					char.playAnim(realAnim, true);

				if(note.nextNote != null && note.prevNote != null){
					if (note != animNote && !note.nextNote.isSustainNote /* && !note.prevNote.isSustainNote */ && callOnScripts('onGhostAnim', [animToPlay, note]) != LuaUtils.Function_Stop) {
						char.playGhostAnim(chord.indexOf(note), animToPlay, true);
					}else if(note.nextNote.isSustainNote || note.isSustainNote){
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
		FlxG.camera.bgColor = 0xFF000000; // to fix mods that like to change its color (looking at you, 17bucks)

		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

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

		if (yscriptArray != null && yscriptArray.length > 0) { //if there's nothing, simply dont.
		for (script in yscriptArray)
			if(script != null)
			{
				if(script.hasFunction('onDestroy')) script.callFunction('onDestroy');
				script.destroy();
			}
		}

		yscriptArray = null;
		stagesFunc(function(stage:BaseStage) stage.destroy());

		// Clear character references
		mcm.destroyAll();

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

		if (mechanicsMod != null) {
			mechanicsMod.luckMechanicDestroy();
			mechanicsMod = null;
		}

		playfield.removeInput();

		FlxG.camera.setFilters([]);

		#if FLX_PITCH if (FlxG.sound.music != null) FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		if (threadPool != null) threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;

		NoteSplash.configs.clear();
		playfield.resetFields();

		// Clean modchart Managers
		#if LUA_ALLOWED
		if (backend.funkinmodchart.Manager.instance != null) {
			backend.funkinmodchart.Manager.instance = null;
		}
		#end

		if (fmManager != null) {
			fmManager = null;
		}

		// Cleanup experimental NotePool system if it was enabled
		if (ClientPrefs.data.useExperimentalNotePool) {
			NotePoolManager.forceCleanup(); // Aggressive cleanup on exit
			trace("Experimental NotePool system cleaned up aggressively");
		}

		// yutautil.MemoryHelper.freeMemory(this);
		moveStrumSections = [];
		instance = null;
		variables = null;
		endingSong = true;
		Paths.clearStoredWithoutStickers();

		super.destroy();

		// Reload the save data as proper.
		if (clientSaveData != null) {
			ClientPrefs.data = clientSaveData;
			clientSaveData = null;
		}
		trace("Done destroy.");
		//Paths.nukeMemory(true); // LIGHTLY nuke everything
	}

	var ssLerpTween:FlxTween = null;
	public function lerpSongSpeed(num:Float, time:Float, ?staticLines:Bool = true):Void
	{
		if (ssLerpTween != null) {
			ssLerpTween.cancel();
			ssLerpTween.destroy();
		}

		ssLerpTween = FlxTween.num(playbackRate, num, time, {ease: FlxEase.sineInOut, onComplete: function(tween) {ssLerpTween.destroy();}}, function(value:Float)
		{
			playbackRate = value * currentRate;
			resyncVocals();
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

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();
		if (boyfriend != null && beat % Math.round(gfSpeed * boyfriend.danceEveryNumBeats) == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % Math.round(gfSpeed * dad.danceEveryNumBeats) == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
		if (bf2 != null && beat % Math.round(gfSpeed * bf2.danceEveryNumBeats) == 0 && !bf2.getAnimationName().startsWith('sing') && !bf2.stunned)
			bf2.dance();
		if (dad2 != null && beat % Math.round(gfSpeed * dad2.danceEveryNumBeats) == 0 && !dad2.getAnimationName().startsWith('sing') && !dad2.stunned)
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

	public function startYScriptsNamed(scriptFile:String)
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
			initYScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initYScript(file:String)
	{
		var newScript:YScript = null;
		try
		{
			newScript = new YScript();

			// Attach to PlayState for error reporting before onCreate
			newScript.attachToPlayState(this);

			newScript.loadFromFile(file);
			if (newScript.hasFunction('onCreate')) {
				newScript.callFunction('onCreate');
			}
			if (newScript.hasFunction('onLoad')) {
				newScript.callFunction('onLoad');
			}
			trace('initialized yscript interp successfully: $file');
			yscriptArray.push(newScript);
			//updateScriptFlags(); // Update script existence flags when adding YScript
		}
		catch(e:YScriptError)
		{
			addTextToDebug(e.message, FlxColor.RED);
		}
		//updateScriptFlags(); // Update flags regardless of success/failure
	}

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		// Early exit if no scripts exist
		if (!hasLuaScripts && !hasHScripts && !hasPyScripts && !hasYScripts) {
			return LuaUtils.Function_Continue;
		}

		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		// Call scripts in order: Lua -> HScript -> YScript -> Python
		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnYScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnPyScripts(funcToCall, args, ignoreStops, exclusions, excludeValues);
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

		var len:Int = hscriptArray != null ? hscriptArray.length : 0;
		if (len < 1)
			return returnVal;

		try {
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
		} catch(e) {trace("One of the scripts wasn't having it apparently");}
		#end

		return returnVal;
	}

	public function callOnYScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = yscriptArray != null ? yscriptArray.length : 0;
		if (len < 1)
			return returnVal;

		var arr:Array<YScript> = [];
		for(script in yscriptArray)
		{
			if(script.hasErrors)
			{
				arr.push(script);
				continue;
			}

			var callValue = script.hasFunction(funcToCall) ? script.callFunction(funcToCall, args) : null;
			if(callValue != null)
			{
				var myValue:Dynamic = callValue; // YScript returns values directly, not wrapped in returnValue

				if((myValue == LuaUtils.Function_StopYScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}

			if(script.hasErrors) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				yscriptArray.remove(script);

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
		setOnYScript(variable, arg, exclusions);
		setOnPyScripts(variable, arg, exclusions);
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

	public function setOnYScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		if (yscriptArray != null && yscriptArray.length > 0) {
			for (script in yscriptArray) {
				if(exclusions.contains(script.scriptPath))
					continue;

				script.setVariable(variable, arg);
			}
		}
	}

	public function callOnPyScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if PYTHON_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<yutautil.PyScript> = [];
		if (pyScriptArray != null && pyScriptArray.length > 0) {
			for (script in pyScriptArray) {
				if(script.closed || script.errorOccurred) {
					arr.push(script);
					continue;
				}

				if(exclusions.contains(script.scriptName))
					continue;

				var myValue:Dynamic = script.call(funcToCall, args);
				if((myValue == yutautil.PyScript.Function_Stop || myValue == yutautil.PyScript.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) {
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;

				if(script.closed || script.errorOccurred) arr.push(script);
			}
		}

		if(arr.length > 0) {
			for (script in arr) {
				pyScriptArray.remove(script);
			}
		}
		#end
		return returnVal;
	}

	public function setOnPyScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if PYTHON_ALLOWED
		if(exclusions == null) exclusions = [];
		if (pyScriptArray != null && pyScriptArray.length > 0) {
			for (script in pyScriptArray) {
				if(exclusions.contains(script.scriptName))
					continue;

				script.setVar(variable, arg);
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
								var baseX = field.getBaseX(i);
								var offsetX = strumNote.x - baseX;
								modManager.setValue('transform${i}X-a', offsetX, field.playerId);

								// Sync Y position
								var baseY = field.getBaseY(i);
								var offsetY = strumNote.y - baseY;

								// Only sync if the strum is close to its expected position
								// This prevents overriding custom positions set by scripts
								// Allow some tolerance for modchart transforms
								if (Math.abs(offsetY) < 200 && Math.abs(offsetY) > -200) { //Give it a zone to work in so that if it steps outside that zone it updates it instead of whatever it was doing before
									modManager.setValue('transform${i}Y-a', offsetY, field.playerId);
								} else {
									// If the strum has been moved significantly, update the base position
									//trace('ModchartSync: Strum ${i} moved significantly (${Math.abs(offsetY)}px), updating base Y from ${baseY} to ${strumNote.y}');
									field.updateBaseYPosition(i, strumNote.y);
								}
								//strumNote.y = strumNote.y;

								// Sync angle
								//modManager.setValue('note${i}Angle', strumNote.angle, field.playerId);
								//strumNote.angle = strumNote.angle;

								modManager.setValue('noteTweenDirection', strumNote.direction, field.playerId);

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

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled || ClientPrefs.getGameplaySetting('showcase', false)) return;

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
						unlock = (!usedPractice && playfield.keysPressed.length <= 2);

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
							&& !ClientPrefs.data.allowVis);

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

					case 'challenger':
						unlock = (!usedPractice && ClientPrefs.data.safeFrames == 2);

					case 'hardcore':
						var failCheck:Bool = false;
						for (mechanic in MechanicManager.mechanics) {
							if (mechanic.points < 20) {
								failCheck = true;
								break;
							}
						}
						unlock = (!usedPractice && !failCheck && comboManager.songMisses == 0);

					case 'demon':
						var failCheck:Bool = false;
						for (mechanic in MechanicManager.mechanics) {
							if (mechanic.points < 20) {
								failCheck = true;
								break;
							}
						}
						unlock = (!usedPractice && !failCheck && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) >= 100);

					case 'persistent':
						var failCheck:Bool = false;
						for (mechanic in MechanicManager.mechanics) {
							if (mechanic.points < 20) {
								failCheck = true;
								break;
							}
						}
						unlock = (!usedPractice && !failCheck && isStoryMode && (campaignMisses + comboManager.songMisses) == 0 && storyPlaylist.length <= 1);

					case 'resilient':
						var failCheck:Bool = false;
						for (mechanic in MechanicManager.mechanics) {
							if (mechanic.points < 20) {
								failCheck = true;
								break;
							}
						}
						unlock = (!usedPractice && !failCheck && isStoryMode && storyPlaylist.length <= 1 && CoolUtil.floorDecimal(comboManager.ratingPercent * 100, 2) >= 100);

					case 'truepotatogaming':
						unlock = (!usedPractice && ClientPrefs.data.framerate == 1);

					case 'mattdestroyer':
						unlock = (!usedPractice && playbackRate >= 2);

					case 'matteleminator':
						unlock = (!usedPractice && playbackRate >= 5);

					case 'mattgod':
						unlock = (!usedPractice && playbackRate >= 10);

					case 'matt':
						unlock = (!usedPractice && playbackRate >= 15);

					case 'mattbeyond':
						unlock = (!usedPractice && playbackRate >= 20);

					case 'lessismore':
						unlock = (!usedPractice && mania[1] <= 2);

					case 'toomanynotes':
						unlock = (!usedPractice && mania[1] <= 4);
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

	/**
	 * Load song audio (vocals, inst) - separated from chart generation for preload mode
	 */
	private function loadSongAudio():Void {
		var songData = SONG;

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
							if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
							if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

							var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
							if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
							if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
						}
						else
						{
							var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
							if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song, 'Player');
							if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song);
							vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));

							var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
							if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
							if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

							var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
							if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
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
							if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
							if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

							var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
							if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
							if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
						}
						else
						{
							var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
							if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song, 'Player');
							if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song);
							vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));

							var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
							if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
							if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

							var gfVocal = Paths.voices(songData.song, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
							if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
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

		trace('PlayState: Song audio loaded successfully');
	}
} //
typedef MechanicResults =
{
	var value:Float;
	var text:String;
	var name:String;
}
