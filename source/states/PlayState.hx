package states;

import music.Section.SwagSection;
import music.Song.SwagSong;
import music.Song;
import flixel.FlxObject;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import lime.utils.Assets;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import states.editors.charting.JSChartingState;
import states.editors.CharacterEditorState;
import flixel.input.keyboard.FlxKey;
import objects.notes.Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import backend.Achievements;
import backend.StageData;
import psychlua.FunkinLua;
import cutscenes.DialogueBoxPsych;
import backend.Rating;
import objects.Character.Boyfriend;
import shaders.Shaders;
import objects.notes.Note.PreloadedChartNote;
import objects.notes.NoteGroup;
import objects.notes.StrumNote;
import objects.notes.SustainSplash;
import objects.notes.NoteSplash;
import cutscenes.DialogueBox;
import backend.Screenshot;
import psychlua.*;
import utils.*;
import backend.ClientPrefs;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

import stages.*;
import objects.notes.Note;
import objects.*;
import music.Conductor;
import objects.playfields.PlayField;
import backend.STMetaFile.MetadataFile;
import flixel.addons.effects.FlxTrail;
import backend.modchart.ModManager;
import flixel.addons.effects.FlxTrailArea;
import openfl.Lib;
import shaders.ShadersHandler;
import utils.window.CppAPI;
import shaders.Shaders.ShaderEffect;
import openfl.media.Sound;
import crowplexus.iris.Iris;
import backend.BaseStage;
import utils.yutautil.MemoryHelper;
import backend.DiscordClient;
import substates.PauseSubState;
import backend.Difficulty;
import states.menus.MenuTracker;
import substates.GameOverSubstate;
import backend.WeekData;
import backend.Highscore;

typedef SpeedEvent =
{
	position:Float, // the y position where the change happens (modManager.getVisPos(songTime))
	startTime:Float, // the song position (conductor.songTime) where the change starts
	songTime:Float, // the song position (conductor.songTime) when the change ends
	?startSpeed:Float, // the starting speed
	speed:Float // speed mult after the change
}

typedef LuaScript = flixel.util.typeLimit.OneOfTwo<FunkinLua, LegacyFunkinLua>;

class PlayState extends MusicBeatState
{
	public var modManager:ModManager;


	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var instance:PlayState;
	public static var STRUM_X = 48.5;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var middleScroll:Bool = false;

	public static var ratingStuff:Array<Dynamic> = [];

	private var tauntKey:Array<FlxKey>;

	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];

	var lastUpdateTime:Float = 0.0;

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	public var hitSoundString:String = ClientPrefs.data.hitsoundType;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	var randomBotplayText:String;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";

	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var npsSpeedMult:Float = 1;

	public var frameCaptured:Int = 0;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var shaderUpdates:Array<Float->Void> = [];
	var botplayUsed:Bool = false;

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var wasOriginallyFreeplay:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public var firstNoteStrumTime:Float = 0;
	var winning:Bool = false;
	var losing:Bool = false;

	var curTime:Float = 0;
	var songCalc:Float = 0;

	public var healthDrainAmount:Float = 0.023;
	public var healthDrainFloor:Float = 0.1;

	var strumsHit:Array<Bool> = [false, false, false, false, false, false, false, false];
	public var splashesPerFrame:Array<Int> = [0, 0, 0, 0];

	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;
	public var gfVocals:FlxSound;
	var intro3:FlxSound;
	var intro2:FlxSound;
	var intro1:FlxSound;
	var introGo:FlxSound;
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;
	public var bfNoteskin:String = null;
	public var dadNoteskin:String = null;
	public static var death:FlxSprite;
	public static var deathanim:Bool = false;
	public static var dead:Bool = false;

	public static var iconOffset:Int = 26;

	var tankmanAscend:Bool = false; // funni (2021 nostalgia oh my god)

	public var notes:NoteGroup;
	public var sustainNotes:NoteGroup;
	public var unspawnNotes:Array<PreloadedChartNote> = [];
	public var unspawnNotesCopy:Array<PreloadedChartNote> = [];
	public var eventNotes:Array<EventNote> = [];
	public var eventNotesCopy:Array<EventNote> = [];

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpHoldSplashes:FlxTypedGroup<SustainSplash>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var laneunderlay:FlxSprite;
	public var laneunderlayOpponent:FlxSprite;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float;
	private var displayedHealth:Float;
	public var maxHealth:Float = 2;

	public var botEnergy:Float = 1;

	public var totalNotesPlayed:Float = 0;
	public var combo:Float = 0;
	public var maxCombo:Float = 0;
	public var missCombo:Int = 0;

	var notesAddedCount:Int = 0;
	var notesToRemoveCount:Int = 0;
	var oppNotesToRemoveCount:Int = 0;
	public var iconBopsThisFrame:Int = 0;
	public var iconBopsTotal:Int = 0;

	var endingTimeLimit:Int = 20;

	var camBopInterval:Float = 4;
	var camBopIntensity:Float = 1;

	var twistShit:Float = 1;
	var twistAmount:Float = 1;
	var camTwistIntensity:Float = 0;
	var camTwistIntensity2:Float = 3;
	var camTwist:Bool = false;

	private var healthBarBG:AttachedSprite; //The image used for the health bar.
	public var healthBar:FlxBar;
	var songPercent:Float = 0;
	var playbackRateDecimal:Float = 0;

	public var timeBar:Bar;

	public var energyBar:Bar;
	public var energyTxt:FlxText;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var perfects:Int = 0;
	public var marvs:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var nps:Float = 0;
	public var maxNPS:Float = 0;
	public var oppNPS:Float = 0;
	public var maxOppNPS:Float = 0;
	public var enemyHits:Float = 0;
	public var opponentNoteTotal:Float = 0;
	public var polyphonyOppo:Float = 1;
	public var polyphonyBF:Float = 1;

	var pixelShitPart1:String = "";
	var pixelShitPart2:String = '';

	public var oldNPS:Float = 0;
	public var oldOppNPS:Float = 0;

	private var lerpingScore:Bool = false;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var playerIsCheating:Bool = false; //Whether the player is cheating. Enables if you change BOTPLAY or Practice Mode in the Pause menu

	public static var disableBotWatermark:Bool = false;

	public var shownScore:Float = 0;

	public var fcStrings:Array<String> = ['No Play', 'PFC', 'SFC', 'GFC', 'BFC', 'FC', 'SDCB', 'Clear', 'TDCB', 'QDCB'];
	public var hitStrings:Array<String> = ['Perfect!!!', 'Sick!!', 'Good!', 'Bad.', 'Shit.', 'Miss..'];
	public var judgeCountStrings:Array<String> = ['Perfects', 'Sicks', 'Goods', 'Bads', 'Shits', 'Misses'];

	var charChangeTimes:Array<Float> = [];
	var charChangeNames:Array<String> = [];
	var charChangeTypes:Array<Int> = [];

	var multiChangeEvents:Array<Array<Float>> = [[], []];

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var hpDrainLevel:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var sickOnly:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	inline function set_cpuControlled(value:Bool){
		cpuControlled = value;
		setOnScripts('botPlay', value);
		if (botplayTxt != null && !ClientPrefs.data.showcaseMode) // this assures it'll always show up
			botplayTxt.visible = (!ClientPrefs.data.hideHud && ClientPrefs.data.botTxtStyle != 'Hide') ? cpuControlled : false;
		/// oughhh
		for (playfield in playfields.members)
		{
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled;
		}

		return cpuControlled;
	}
	public var practiceMode:Bool = false;
	public var opponentDrain:Bool = false;
	public static var opponentChart:Bool = false;
	public static var bothSides:Bool = false;
	var randomMode:Bool = false;
	var flip:Bool = false;
	var stairs:Bool = false;
	var waves:Bool = false;
	var oneK:Bool = false;
	var randomSpeedThing:Bool = false;
	public var trollingMode:Bool = false;
	public var jackingtime:Float = 0;
	public var minSpeed:Float = 0.1;
	public var maxSpeed:Float = 10;

	private var npsIncreased:Bool = false;
	private var npsDecreased:Bool = false;

	private var oppNpsIncreased:Bool = false;
	private var oppNpsDecreased:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	public var renderedTxt:FlxText;
	public var ytWatermark:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;
	var secretsong:FlxSprite;
	var hitsoundImage:FlxSprite;
	var hitsoundImageToLoad:String;

	//ok moxie this doesn't cause memory leaks
	public var scoreTxtUpdateFrame:Int = 0;
	public var judgeCountUpdateFrame:Int = 0;
	public var popUpsFrame:Int = 0;
	public var missRecalcsPerFrame:Int = 0;
	public var hitImagesFrame:Int = 0;

	var notesHitArray:Array<Float> = [];
	var oppNotesHitArray:Array<Float> = [];
	var notesHitDateArray:Array<Float> = [];
	var oppNotesHitDateArray:Array<Float> = [];

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var EngineWatermark:FlxText;

	public static var screenshader:shaders.Shaders.PulseEffectAlt = new PulseEffectAlt();

	var disableTheTripper:Bool = false;
	var disableTheTripperAt:Int;

	var heyTimer:Float;

	public var singDurMult:Int = 1;

	//ms timing popup shit
	public var msTxt:FlxText;
	public var msTimer:FlxTimer = null;
	public var restartTimer:FlxTimer = null;

	//ms timing popup shit except for simplified ratings
	public var judgeTxt:FlxText;
	public var judgeTxtTimer:FlxTimer = null;

	public var oppScore:Float = 0;
	public var songScore:Float = 0;
	public var songHits:Int = 0;
	public var songMisses:Float = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;

	var hitTxt:FlxText;

	var scoreTxtTween:FlxTween;
	var timeTxtTween:FlxTween;
	var judgementCounter:FlxText;

	public static var campaignScore:Float = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public static var shouldDrainHealth:Bool = false;

	public var defaultCamZoom:Float = 1.05;

	public var ogCamZoom:Float = 1.05;

	var ogBotTxt:String = '';

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public static var sectionsLoaded:Int = 0;
	public var notesLoadedRN:Int = 0;

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var heyStopTrying:Bool = false;

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
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	public var keysArray:Array<Dynamic>;
	public var controlArray:Array<String>;

	public var songName:String;

	//cam panning
	var moveCamTo:HaxeVector<Float> = new HaxeVector(2);

	var getTheBotplayText:Int = 0;

	var theListBotplay:Array<String> = [];

	var formattedScore:String;
	var formattedSongMisses:String;
	var formattedCombo:String;
	var formattedMaxCombo:String;
	var formattedNPS:String;
	var formattedMaxNPS:String;
	var formattedOppNPS:String;
	var formattedMaxOppNPS:String;
	var formattedEnemyHits:String;
	var npsString:String;
	var accuracy:String;
	var fcString:String;
	var hitsound:FlxSound;

	var botText:String;
	var tempScore:String;

	var startingTime:Float = haxe.Timer.stamp();
	var endingTime:Float = haxe.Timer.stamp();

	// FFMpeg values :)
	var ffmpegMode = ClientPrefs.data.ffmpegMode;
	var ffmpegInfo = ClientPrefs.data.ffmpegInfo;
	var targetFPS = ClientPrefs.data.targetFPS;
	var unlockFPS = ClientPrefs.data.unlockFPS;
	var renderGCRate = ClientPrefs.data.renderGCRate;
	static var capture:Screenshot = new Screenshot();

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	//Mixtape Engine Stuff
	public static var gameplayArea:String = "Story";
	public static var mania:Int = -1;

	public var instVolumeMultiplier:Float = 1;
	public var vocalVolumeMultiplier:Float = 1;

	public var bf2:Character = null;
	public var boyfriendGroup2:FlxSpriteGroup;
	public var boyfriend2CameraOffset:Array<Float> = null;
	public var dad2:Character = null;
	public var dadGroup2:FlxSpriteGroup;
	public var opponent2CameraOffset:Array<Float> = null;

	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel"))
				uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public var MaxHP:Float = 2;
	public var extraHealth:Float = 0;
	public var noHeal:Bool = false;

	// Anticheat
	var hadBotplayOn:Bool = false;

	// The modifier that allows sperate saves depending how how you want to play the game
	public var saveMod:String = "";

	// aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
	public var bfkilledcheck = false;
	// things from trials
	var justmissed:Bool = false;

	public var camGamefilters:Array<BitmapFilter> = [];
	public var camHUDfilters:Array<BitmapFilter> = [];
	public var camVisualfilters:Array<BitmapFilter> = [];
	public var camOtherfilters:Array<BitmapFilter> = [];
	public var camDialoguefilters:Array<BitmapFilter> = [];
	var ch = 2 / 1000;

	var metadata:MetadataFile;
	var hasMetadataFile:Bool = false;
	var Text:Array<String> = [];
	var whiteBG:FlxSprite;
	var blackOverlay:FlxSprite;
	var blackUnderlay:FlxSprite;

	public var freezeNotes:Bool = false;
	public var localFreezeNotes:Bool = false;
	public var sh_r:Float = 600;

	var rotRate:Float;
	var rotRateSh:Float;
	var derp = 20;
	var fly:Bool = false;
	var stageData:StageFile;
	var winX = Lib.application.window.x;
	var winY = Lib.application.window.y;
	var charFade:FlxTween;
	var charFade2:FlxTween;
	var chromCheck:Int = 0;
	var dadT:FlxTrail;
	var bfT:FlxTrail;
	var gfT:FlxTrail;
	var burst:FlxSprite;
	var cutTime = 0;

	var hasGlow:Bool = false;
	var strumFocus:Bool = false;

	public static var playAsGF:Bool = false; //For later

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

	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText;
	var skipTo:Float;

	public var playerField:PlayField;
	public var dadField:PlayField;

	public var notefields = new objects.playfields.NotefieldManager();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes

	public var noteHits:Array<Float> = [];

	var speedChanges:Array<SpeedEvent> = [];

	public var currentSV:SpeedEvent = {
		position: 0,
		startTime: 0,
		songTime: 0,
		speed: 1,
		startSpeed: 1
	};

	public var halloweenWhite:BGSprite;
	public var blammedLightsBlack:FlxSprite;
	private var timerExtensions:Array<Float>;
	public var maskedSongLength:Float = -1;

	// AI things. You wouldn't get it.
	var AIMode:Bool = false;
	var AIDifficulty:String = 'Average FNF Player';

	// WeedEnd My Beloved
	public var rainIntensity:Float = 0;

	// Song Credits
	public var introStageBar:FlxSprite;
	public var introStageText:FlxTypedGroup<FlxText>;
	public var introStageStuff:FlxTypedGroup<Dynamic>;
	var credText:Array<String> = [];
	var songTxt:FlxText;
	var artistTxt:FlxText;
	var charterTxt:FlxText;
	var modTxt:FlxText;

	public var mashViolations:Int = 0;
	public var mashing:Int = 0;

	public var RandomSpeedChange:Bool = ClientPrefs.getGameplaySetting('randomspeedchange', false);

	var resistanceBar:IntegratedScript;

	override public function create()
	{
		//Stops playing on a height that isn't divisible by 2
		if (ClientPrefs.data.ffmpegMode && ClientPrefs.data.resolution != null) {
			var resolutionValue = cast(ClientPrefs.data.resolution, String);

			if (resolutionValue != null) {
				var parts = resolutionValue.split('x');

				if (parts.length == 2) {
					var width = Std.parseInt(parts[0]);
					var height = Std.parseInt(parts[1]);

					if (width != null && height != null) {
						CoolUtil.resetResScale(width, height);
						FlxG.resizeGame(width, height);
						lime.app.Application.current.window.width = width;
						lime.app.Application.current.window.height = height;
					}
				}
			}
		}
		if (ffmpegMode) {
			if (unlockFPS)
			{
				FlxG.updateFramerate = 1000;
				FlxG.drawFramerate = 1000;
			}
			FlxG.fixedTimestep = true;
			FlxG.animationTimeScale = ClientPrefs.data.framerate / targetFPS;
			if (!ClientPrefs.data.oldFFmpegMode) initRender();
		}
		theListBotplay = CoolUtil.coolTextFile(Paths.txt('botplayText'));

		if (FileSystem.exists(Paths.getSharedPath('sounds/hitsounds/' + ClientPrefs.data.hitsoundType.toLowerCase() + '.txt'))) 
			hitsoundImageToLoad = File.getContent(Paths.getSharedPath('sounds/hitsounds/' + ClientPrefs.data.hitsoundType.toLowerCase() + '.txt'));
		else if (FileSystem.exists(Paths.modFolders('sounds/hitsounds/' + ClientPrefs.data.hitsoundType.toLowerCase() + '.txt')))
			hitsoundImageToLoad = File.getContent(Paths.modFolders('sounds/hitsounds/' + ClientPrefs.data.hitsoundType.toLowerCase() + '.txt'));

		randomBotplayText = theListBotplay[FlxG.random.int(0, theListBotplay.length - 1)];

		inline cpp.vm.Gc.enable(ClientPrefs.data.enableGC || ffmpegMode && !ClientPrefs.data.noRenderGC); //lagspike prevention
		inline Paths.clearStoredMemory();

		#if sys
		openfl.system.System.gc();
		#end

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		tauntKey = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('qt_taunt'));

		keysArray = backend.Keybinds.fill();

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray[mania].length)
		{
			keysPressed.push(false);
		}

		screenshader.waveAmplitude = 1;
		screenshader.waveFrequency = 2;
		screenshader.waveSpeed = 1;
		screenshader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-100000, 100000);
		screenshader.shader.uampmul.value[0] = 0;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		hpDrainLevel = ClientPrefs.getGameplaySetting('drainlevel', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		sickOnly = ClientPrefs.getGameplaySetting('onlySicks', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		opponentChart = ClientPrefs.getGameplaySetting('opponentplay', false);
		bothSides = ClientPrefs.getGameplaySetting('bothsides', false);
		trollingMode = ClientPrefs.getGameplaySetting('thetrollingever', false);
		opponentDrain = ClientPrefs.getGameplaySetting('opponentdrain', false);
		randomMode = ClientPrefs.getGameplaySetting('randommode', false);
		flip = ClientPrefs.getGameplaySetting('flip', false);
		stairs = ClientPrefs.getGameplaySetting('stairmode', false);
		waves = ClientPrefs.getGameplaySetting('wavemode', false);
		oneK = ClientPrefs.getGameplaySetting('onekey', false);
		randomSpeedThing = ClientPrefs.getGameplaySetting('randomspeed', false);
		jackingtime = ClientPrefs.getGameplaySetting('jacks', 0);
		minSpeed = ClientPrefs.getGameplaySetting('randomspeedmin', 0.1);
		maxSpeed = ClientPrefs.getGameplaySetting('randomspeedmax', 10);

		middleScroll = ClientPrefs.data.middleScroll || bothSides;
		if (bothSides) opponentChart = false;

		if (ClientPrefs.data.showcaseMode || ffmpegMode)
			cpuControlled = true;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpHoldSplashes = new FlxTypedGroup<SustainSplash>((ClientPrefs.data.maxSplashLimit != 0 ? ClientPrefs.data.maxSplashLimit : 10000));
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>((ClientPrefs.data.maxSplashLimit != 0 ? ClientPrefs.data.maxSplashLimit : 10000));

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;
		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		if (!chartingMode) Difficulty.currentDifficulty = Difficulty.difficultyString();

		#if desktop
		if (WeekData.getCurrentWeek() != null)
		{
			// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
			storyDifficultyText = Difficulty.getString();

			if (isStoryMode)
				try
				{
					detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
				}
				catch (e)
				{
					detailsText = "Story Mode: ???";
				}
			else
				detailsText = "Freeplay";
			// String for when the game is paused
			detailsPausedText = "Paused - " + detailsText;
		}
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		curStage = (!ClientPrefs.data.charsAndBG ? "" : SONG.stage);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ 
			// Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		defaultCamZoom = ogCamZoom = stageData.defaultZoom;
		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) // Backward compatibility
			stageUI = "pixel";
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

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

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		startCallback = startCountdown;
		endCallback = endSong;

		switch (curStage)
		{
			case 'stage': new StageWeek1(); 					 // Week 1
			case 'spooky': new Spooky(); 						 // Week 2
			case 'philly': new Philly(); 						 // Week 3
			case 'limo': new Limo(); 							 // Week 4
			case 'mall': new Mall(); 							 // Week 5 - Cocoa, Eggnog
			case 'mallEvil': new MallEvil(); 					 // Week 5 - Winter Horrorland
			case 'school': new School(); 						 // Week 6 - Senpai, Roses
			case 'schoolEvil': new SchoolEvil(); 				 // Week 6 - Thorns
			case 'tank': new Tank(); 							 // Week 7 - Ugh, Guns, Stress
			case 'phillyStreets': new PhillyStreets(); 			 // Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin': new PhillyBlazin(); 			 // Weekend 1 - Blazin
			case 'mainStageErect': new MainStageErect(); 		 // Week 1 Special
			case 'spookyMansionErect': new SpookyMansionErect(); // Week 2 Special
			case 'phillyTrainErect': new PhillyTrainErect(); 	 // Week 3 Special
			case 'limoRideErect': new LimoRideErect(); 			 // Week 4 Special
			case 'mallXmasErect': new MallXmasErect(); 			 // Week 5 Special
			case 'phillyStreetsErect': new PhillyStreetsErect(); // Weekend 1 Special
			case 'desktop': new Desktop(); 						 // Literally your desktop as a stage lmao
		}

		if (Paths.formatToSongPath(SONG.song) == 'stress')
			GameOverSubstate.characterName = 'bf-holding-gf-dead';

		if (Note.globalRgbShaders.length > 0) Note.globalRgbShaders = [];
		Paths.initDefaultSkin(SONG.arrowSkin);
		Paths.initNote(4, SONG.arrowSkin);

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}
		add(gfGroup); //Needed for blammed lights

		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end
				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
			//later
			/*if (Std.is(this, APPlayState))
			{
				for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'SvC/'))
					for (file in FileSystem.readDirectory(folder))
					{
						#if LUA_ALLOWED
						if (file.toLowerCase().endsWith('.lua'))
							new FunkinLua(folder + file).call("registerSvCEffect", [this]);
						#end
						#if HSCRIPT_ALLOWED
						if (file.toLowerCase().endsWith('.hx'))
							initHScript(folder + file, true); // Not sure what to do with this yet...
						#end
					}
			}*/
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (ClientPrefs.data.doubleGhosts)
		{
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

		var gfVersion:String = SONG.gfVersion;

		if(gfVersion == null || gfVersion.length < 1)
		{
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
		health = maxHealth / 2;
		displayedHealth = maxHealth / 2;

		if (!stageData.hide_girlfriend && ClientPrefs.data.charsAndBG)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		var ratingQuoteStuff:Array<Dynamic> = Paths.mergeAllTextsNamed('data/ratingQuotes/${ClientPrefs.data.rateNameStuff}.txt', '', true);
		if (ratingQuoteStuff == null || ratingQuoteStuff.indexOf(null) != -1){
			trace('Failed to find quotes for ratings!');
			// this should help fix a crash
			ratingQuoteStuff = [
				['How are you this bad?', 0.1],
				['You Suck!', 0.2],
				['Horribly Shit', 0.3],
				['Shit', 0.4],
				['Bad', 0.5],
				['Bruh', 0.6],
				['Meh', 0.69],
				['Nice', 0.7],
				['Good', 0.8],
				['Great', 0.9],
				['Sick!', 1],
				['Perfect!!', 1]
			];
			ratingStuff = ratingQuoteStuff.copy();
		}
		else
		{
			for (i in 0...ratingQuoteStuff.length)
			{
				var quotes:Array<Dynamic> = ratingQuoteStuff[i].split(',');
				if (quotes.length > 2) //In case your quote has more than 1 comma
				{
					var quotesToRemove:Int = 0;
					for (i in 1...quotes.length-1)
					{
						quotesToRemove++;
						quotes[0] += ',' + quotes[i];
					}
					if (quotesToRemove > 0)
						quotes.splice(1, quotesToRemove);
		
				}
				ratingStuff.push(quotes);
			}
		}

		if (!ClientPrefs.data.charsAndBG)
		{
			dad = new Character(0, 0, "");
			dadGroup.add(dad);

			boyfriend = new Boyfriend(0, 0, "");
			boyfriendGroup.add(boyfriend);
		} else {
			dad = new Character(0, 0, SONG.player2);
			startCharacterPos(dad, true);
			dadGroup.add(dad);
			startCharacterScripts(dad.curCharacter);
			dadNoteskin = dad.noteskin;

			boyfriend = new Boyfriend(0, 0, SONG.player1);
			startCharacterPos(boyfriend);
			boyfriendGroup.add(boyfriend);
			startCharacterScripts(boyfriend.curCharacter);
			bfNoteskin = boyfriend.noteskin;
		}

		popUpGroup = new FlxTypedSpriteGroup<Popup>();
		add(popUpGroup);

		shouldDrainHealth = (opponentDrain || (opponentChart ? boyfriend.healthDrain : dad.healthDrain));
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainAmount) && (opponentChart ? boyfriend : dad).drainFloor != 0) healthDrainAmount = opponentChart ? boyfriend.drainAmount : dad.drainAmount;
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainFloor) && (opponentChart ? boyfriend : dad).drainFloor != 0) healthDrainFloor = opponentChart ? boyfriend.drainFloor : dad.drainFloor;

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

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;

		laneunderlayOpponent = new FlxSprite(70, 0).makeGraphic(500, FlxG.height * 2, FlxColor.BLACK);
		laneunderlayOpponent.alpha = ClientPrefs.data.laneUnderlayAlpha;
		laneunderlayOpponent.scrollFactor.set();
		laneunderlayOpponent.screenCenter(Y);
		laneunderlayOpponent.visible = ClientPrefs.data.laneUnderlay;

		laneunderlay = new FlxSprite(70 + (FlxG.width / 2), 0).makeGraphic(500, FlxG.height * 2, FlxColor.BLACK);
		laneunderlay.alpha = ClientPrefs.data.laneUnderlayAlpha;
		laneunderlay.scrollFactor.set();
		laneunderlay.screenCenter(Y);
		laneunderlay.visible = ClientPrefs.data.laneUnderlay;

		if (ClientPrefs.data.laneUnderlay)
		{
			add(laneunderlayOpponent);
			add(laneunderlay);
		}

		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		switch (ClientPrefs.data.timeBarStyle)
		{
			case 'Vanilla':
				timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 2;

			case 'Leather Engine':
				timeTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 2;

			case 'JS Engine':
				timeTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 3;

			case 'TGT V4':
				timeTxt.setFormat(Paths.font("calibri.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 2;

			case 'Kade Engine':
				timeTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 1;

			case 'Dave Engine':
				timeTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 2;

			case 'Doki Doki+':
				timeTxt.setFormat(Paths.font("Aller_rg.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 2;

			case 'VS Impostor':
				timeTxt.x = STRUM_X + (FlxG.width / 2) - 585;
				timeTxt.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
				timeTxt.borderSize = 1;
		}


		if(ClientPrefs.data.timeBarType == 'Song Name' && !ClientPrefs.data.timebarShowSpeed)
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
		if (ClientPrefs.data.timeBarStyle != 'Dave Engine') add(timeBar);

		switch (ClientPrefs.data.timeBarStyle) {
			case 'VS Impostor':
				timeBar.bg.loadGraphic(Paths.image('impostorTimeBar'));
				timeBar.setColors(0xFF2e412e, 0xFF44d844);
				timeTxt.x += 10;
				timeTxt.y += 4;

			case 'Vanilla', 'TGT V4':
				timeBar.bg.loadGraphic(Paths.image('timeBar'));
				timeBar.setColors(FlxColor.BLACK, FlxColor.WHITE);
				timeBar.bg.color = FlxColor.BLACK;

			case 'Leather Engine':
				timeBar.bg.loadGraphic(Paths.image('editorHealthBar'));
				timeBar.bg.alpha = 0;
				timeBar.bg.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
				timeBar.bg.color = FlxColor.BLACK;
				timeBar.setColors(FlxColor.BLACK, FlxColor.WHITE);
				timeBar.alpha = 0;
				timeBar.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');

			case 'Kade Engine':
				timeBar.bg.loadGraphic(Paths.image('editorHealthBar'));
				timeBar.bg.alpha = 0;
				timeBar.bg.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
				timeBar.bg.color = FlxColor.BLACK;
				timeBar.setColors(FlxColor.GRAY, FlxColor.LIME);
				timeBar.alpha = 0;
				timeBar.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');

			case 'Dave Engine':
				timeBar.bg.loadGraphic(Paths.image('DnBTimeBar'));
				timeBar.bg.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
				timeBar.alpha = 0;
				timeBar.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
				timeBar.setColors(FlxColor.GRAY, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));

			case 'Doki Doki+':
				timeBar.bg.loadGraphic(Paths.image("dokiTimeBar"));
				timeBar.bg.screenCenter(X);
				timeBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

			case 'JS Engine':
				timeBar.bg.alpha = 0;
				timeBar.bg.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
				timeBar.bg.color = FlxColor.BLACK;
				timeBar.alpha = 0;
				timeBar.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');
				timeBar.setColors(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]), FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
		}
		add(timeBar);
		add(timeTxt);

		timeBar.bg.visible = showTime && !ClientPrefs.data.timeBarType.contains('(No Bar)');

		energyBar = new Bar(FlxG.width * 0.81, FlxG.height / 2, 'timeBar', function() return botEnergy, 0, 2);
		energyBar.bg.scrollFactor.set();
		energyBar.bg.alpha = 0;
		energyBar.bg.visible = false;
		energyBar.bg.angle = 90;
		energyBar.alpha = 0;
		energyBar.visible = false;
		energyBar.angle = 90;
		energyBar.setColors(FlxColor.BLACK, FlxColor.WHITE);
		add(energyBar);

		energyTxt = new FlxText(FlxG.width * 0.81, FlxG.height / 2, 400, "", 20);
		energyTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE,FlxColor.BLACK);
		energyTxt.scrollFactor.set();
		energyTxt.alpha = 0;
		energyTxt.borderSize = 1.25;
		energyTxt.visible = false;
		add(energyTxt);

		energyBar.cameras = energyTxt.cameras = [camHUD];

		sustainNotes = new NoteGroup();
		add(sustainNotes);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		notes = new NoteGroup();
		add(notes);
		notes.visible = sustainNotes.visible = ClientPrefs.data.showNotes; //that was easier than expected

		add(grpNoteSplashes);
		add(grpHoldSplashes);


		if(ClientPrefs.data.timeBarType == 'Song Name' && ClientPrefs.data.timeBarStyle == 'VS Impostor')
		{
			timeTxt.size = 14;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0001;

		SustainSplash.startCrochet = Conductor.stepCrochet;
		SustainSplash.frameRate = Math.floor(24 / 100 * SONG.bpm);
		var splash:SustainSplash = new SustainSplash();
		grpHoldSplashes.add(splash);
		splash.visible = true;
		splash.alpha = 0.0001;

		playerStrums = new FlxTypedGroup<StrumNote>();
		opponentStrums = new FlxTypedGroup<StrumNote>();

		trace ('Loading chart...');
		generateSong(SONG.song, startOnTime);

		if (SONG.event7 == null || SONG.event7 == '') SONG.event7 == 'None';

		if (curSong.toLowerCase() == "guns") // added this to bring back the old 2021 fnf vibes, i wish the fnf fandom revives one day :(
		{
			var randomVar:Int = 0;
			if (!ClientPrefs.data.noGunsRNG) randomVar = Std.random(15);
			if (ClientPrefs.data.noGunsRNG) randomVar = 8;
			trace(randomVar);
			if (randomVar == 8)
			{
				trace('AWW YEAH, ITS ASCENDING TIME');
				tankmanAscend = true;
			}
		}

		if (notes.members[0] != null) firstNoteStrumTime = notes.members[0].strumTime;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);
		if (!ClientPrefs.data.charsAndBG) FlxG.camera.zoom = 100; //zoom it in very big to avoid high RAM usage!!
		if (ClientPrefs.data.charsAndBG)
		{
			FlxG.camera.follow(camFollow, LOCKON, 1);
			FlxG.camera.zoom = defaultCamZoom;

			FlxG.camera.snapToTarget();
			FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
			FlxG.fixedTimestep = false;
		}
		moveCameraSection();

		msTxt = new FlxText(0, 0, 0, "");
		msTxt.cameras = [camHUD];
		msTxt.scrollFactor.set();
		msTxt.setFormat("vcr.ttf", 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.data.scoreStyle == 'Tails Gets Trolled V4') msTxt.setFormat("calibri.ttf", 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.data.scoreStyle == 'TGT V4') msTxt.setFormat("comic.ttf", 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.data.scoreStyle == 'Doki Doki+') msTxt.setFormat("Aller_rg.ttf", 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		msTxt.x = 408 + 250;
		msTxt.y = 290 - 25;
		if (PlayState.isPixelStage) {
			msTxt.x = 408 + 260;
			msTxt.y = 290 + 20;
		}
		msTxt.x += ClientPrefs.data.comboOffset[0];
		msTxt.y -= ClientPrefs.data.comboOffset[1];
		msTxt.active = false;
		msTxt.visible = false;
		insert(members.indexOf(strumLineNotes), msTxt);

		judgeTxt = new FlxText(400, timeBar.y + 120, FlxG.width - 800, "");
		judgeTxt.cameras = [camHUD];
		judgeTxt.scrollFactor.set();
		judgeTxt.setFormat("vcr.ttf", 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.data.scoreStyle == 'Tails Gets Trolled V4') judgeTxt.setFormat("calibri.ttf", 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.data.scoreStyle == 'Dave and Bambi') judgeTxt.setFormat("comic.ttf", 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		if (ClientPrefs.data.scoreStyle == 'Doki Doki+') judgeTxt.setFormat("Aller_rg.ttf", 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		judgeTxt.active = false;
		judgeTxt.size = 32;
		judgeTxt.visible = false;
		add(judgeTxt);
		switch(ClientPrefs.data.healthBarStyle)
		{
			case 'Dave Engine':
				healthBarBG = new AttachedSprite('DnBHealthBar');
			
			case 'Doki Doki+':
				healthBarBG = new AttachedSprite('dokiHealthBar');
			
			default:
				healthBarBG = new AttachedSprite('healthBar');
		}

		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.data.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.data.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'displayedHealth', 0, maxHealth);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		insert(members.indexOf(healthBarBG), healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors(dad.healthColorArray, boyfriend.healthColorArray);

		if (ClientPrefs.data.smoothHealth) healthBar.numDivisions = Std.int(healthBar.width);

		if (SONG.player1.startsWith('bf') || SONG.player1.startsWith('boyfriend')) {
			final iconToChange:String = switch (ClientPrefs.data.bfIconStyle){
				case 'VS Nonsense V2': 'bfnonsense';
				case 'Doki Doki+': 'bfdoki';
				case 'Leather Engine': 'bfleather';
				case "Mic'd Up": 'bfmup';
				case "FPS Plus": 'bffps';
				case "OS 'Engine'": 'bfos';
				default: 'bf';
			}
			if (iconToChange != 'bf')
				iconP1.changeIcon(iconToChange);
		}

		if (ClientPrefs.data.timeBarType == 'Disabled') {
			timeBar.destroy();
		}

		//figured i'd optimize the code for the enginewatermark creation. after all a lot of lines here were mostly the same

		EngineWatermark = new FlxText(4,FlxG.height * 0.9 + 50,0,"", 16);
		EngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, OUTLINE,FlxColor.BLACK);
		EngineWatermark.scrollFactor.set();
		EngineWatermark.text = SONG.song;
		add(EngineWatermark);

		switch(ClientPrefs.data.watermarkStyle)
		{
			case 'Vanilla': EngineWatermark.text = SONG.song + " " + Difficulty.difficultyString() + " | Mixtape " + MenuTracker.psychEngineVersion;
			case 'Forever Engine': 
				EngineWatermark.text = "Mixtape Engine v" + MenuTracker.psychEngineJSVersion;
				EngineWatermark.x = FlxG.width - EngineWatermark.width - 5;
				/*if (ClientPrefs.data.downScroll) EngineWatermark.y = healthBar.y + 50;
				else {
					return; // replace if wrong
				}*/
			case 'JS Engine': 
				if (!ClientPrefs.data.downScroll) EngineWatermark.y = FlxG.height * 0.1 - 70;
				EngineWatermark.text = "Playing " + SONG.song + " on " + Difficulty.difficultyString() + " - Mixtape v" + MenuTracker.psychEngineJSVersion;
				/*if (ClientPrefs.data.downScroll) EngineWatermark.y = healthBar.y + 50;
				else {
					return; // replace if wrong
				}*/
			case 'Dave Engine':
				EngineWatermark.setFormat(Paths.font("comic.ttf"), 16, FlxColor.WHITE, RIGHT, OUTLINE,FlxColor.BLACK);
				EngineWatermark.text = SONG.song;
				if (ClientPrefs.data.downScroll) EngineWatermark.y = healthBar.y + 50;

			default: 
		}

		if (ClientPrefs.data.watermarkStyle == 'Hide' && EngineWatermark != null) EngineWatermark.visible = false;

		if (ClientPrefs.data.showcaseMode && !ClientPrefs.data.charsAndBG) {
			hitTxt = new FlxText(0, 20, 10000, "test", 42);
			hitTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			hitTxt.scrollFactor.set();
			hitTxt.borderSize = 2;
			hitTxt.visible = true;
			hitTxt.cameras = [camHUD];
			hitTxt.screenCenter(Y);
			add(hitTxt);
			var chromaScreen = new FlxSprite(-5000, -2000).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.GREEN);
			chromaScreen.scrollFactor.set(0, 0);
			chromaScreen.scale.set(3, 3);
			chromaScreen.updateHitbox();
			add(chromaScreen);
		}

		// TODO: cleanup playstate, by moving most of this and other duplicate functions like healthbop, etc
		scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE,FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		var style:String = ClientPrefs.data.scoreStyle;
		var dadColors:Array<Int> = CoolUtil.getHealthColors(dad);

		switch(style)
		{
			case 'Kade Engine', 'Leather Engine': //do nothing lmao
			case 'JS Engine':
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.fromRGB(dadColors[0], dadColors[1], dadColors[2]), CENTER, OUTLINE, FlxColor.BLACK);
				scoreTxt.borderSize = 2;

			case 'Dave Engine', 'Psych Engine', 'VS Impostor': 
				scoreTxt.y = healthBarBG.y + (style == 'Dave Engine' ? 40 : 36);
				scoreTxt.setFormat(Paths.font((style == 'Dave Engine' ? "comic.ttf" : "vcr.ttf")), 20, (style != 'VS Impostor' ? FlxColor.WHITE : FlxColor.fromRGB(dadColors[0], dadColors[1], dadColors[2])), CENTER, OUTLINE, FlxColor.BLACK);
				scoreTxt.borderSize = 1.25;

			case 'Doki Doki+', 'TGT V4': 
				scoreTxt.y = healthBarBG.y + 48;
				scoreTxt.setFormat(Paths.font((ClientPrefs.data.scoreStyle == 'TGT V4' ? "calibri.ttf" : "Aller_rg.ttf")), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				scoreTxt.borderSize = 1.25;

			case 'Forever Engine', 'Vanilla':
				if (style == 'Vanilla') scoreTxt.x = 200;
				scoreTxt.y = healthBarBG.y + (style == 'Forever Engine' ? 40 : 30);
				scoreTxt.setFormat(Paths.font("vcr.ttf"), (style == 'Vanilla' ? 16 : 18), FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				scoreTxt.borderSize = 1.25;
				updateScore();
		}
		style = null;
		if (ClientPrefs.data.showcaseMode) {
			var items = [scoreTxt, botplayTxt, healthBarBG, healthBar, iconP1, iconP2];
			if (ClientPrefs.data.showcaseST == 'AMZ')
				items = [scoreTxt, botplayTxt, timeBar, timeTxt];
			for (i in items)
				if (i != null) i.visible = false;
		}
		if (ClientPrefs.data.hideHud) {
			final daArray:Array<Dynamic> = [scoreTxt, botplayTxt, healthBarBG, healthBar, iconP2, iconP1, timeBar, timeTxt];
			for (i in daArray){
				if (i != null)
					i.visible = false;
			}
		}
		if (!ClientPrefs.data.charsAndBG) {
			remove(dadGroup);
			remove(boyfriendGroup);
			remove(gfGroup);
			gfGroup.destroy();
			dadGroup.destroy();
			boyfriendGroup.destroy();
		}
		if (ClientPrefs.data.scoreTxtSize > 0 && scoreTxt != null && !ClientPrefs.data.showcaseMode && !ClientPrefs.data.hideHud) scoreTxt.size = ClientPrefs.data.scoreTxtSize;

		final ytWMPosition = switch(ClientPrefs.data.ytWatermarkPosition)
		{
			case 'Top': FlxG.height * 0.2;
			case 'Middle': FlxG.height / 2;
			case 'Bottom': FlxG.height * 0.8;
			default: FlxG.height / 2;
		}

		final path:String = Paths.txt("ytWatermarkInfo");
		final ytWatermarkText:String = Assets.exists(path) ? Assets.getText(path) : '';
		ytWatermark = new FlxText(0, ytWMPosition, FlxG.width, ytWatermarkText, 40);
		ytWatermark.setFormat(Paths.font("vcr.ttf"), 25, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		ytWatermark.scrollFactor.set();
		ytWatermark.borderSize = 1.25;
		ytWatermark.alpha = 0.5;
		ytWatermark.cameras = [camOther];
		ytWatermark.visible = ClientPrefs.data.ytWatermarkPosition != 'Hidden';
		add(ytWatermark);

		renderedTxt = new FlxText(0, healthBarBG.y - 50, FlxG.width, "", 32);
		renderedTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		renderedTxt.scrollFactor.set();
		renderedTxt.borderSize = 1.25;
		renderedTxt.cameras = [camHUD];
		renderedTxt.visible = ClientPrefs.data.showRendered;

		if (ClientPrefs.data.downScroll) renderedTxt.y = healthBar.y + 50;
		if (ClientPrefs.data.scoreStyle == 'VS Impostor') renderedTxt.y = healthBar.y + (ClientPrefs.data.downScroll ? 100 : -100);
		add(renderedTxt);

		judgementCounter = new FlxText(0, FlxG.height / 2 - 80, 0, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.visible = ClientPrefs.data.ratingCounter && !ClientPrefs.data.showcaseMode;
		add(judgementCounter);
		if (ClientPrefs.data.ratingCounter) updateRatingCounter();

		//create default botplay text
		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled && !ClientPrefs.data.showcaseMode;
		add(botplayTxt);
		if (ClientPrefs.data.downScroll)
			botplayTxt.y = timeBar.y - 78;

		// just because, people keep making issues about it
		try{
			var botStyle = ClientPrefs.data.botTxtStyle;
			switch(botStyle)
			{
				case 'Vanilla': //Do nothing.
				case 'JS Engine': 
					botplayTxt.text = 'Botplay Mode';
					botplayTxt.borderSize = 1.5;

				case 'Doki Doki+':
					botplayTxt.setFormat(Paths.font("Aller_rg.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				case 'TGT V4':
					botplayTxt.setFormat(Paths.font("calibri.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				case 'Dave Engine':
					botplayTxt.setFormat(Paths.font("comic.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
				case 'VS Impostor':
					botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.fromRGB(dadColors[0], dadColors[1], dadColors[2]), CENTER, OUTLINE, FlxColor.BLACK);
			}
		}
		catch(e){
			trace("Failed to display/create botplayTxt: " + e);
		}
		if (botplayTxt != null){
			if (!cpuControlled && practiceMode) {
				botplayTxt.text = 'Practice Mode';
				botplayTxt.visible = true;
			}
				if (ClientPrefs.data.showcaseMode && ClientPrefs.data.showcaseST != 'AMZ') {
				botplayTxt.y += (!ClientPrefs.data.downScroll ? 60 : -60);
				botplayTxt.text = 'NPS: $nps/$maxNPS\nOpp NPS: $oppNPS/$maxOppNPS';
				botplayTxt.visible = true;
			}
		}
		if (ClientPrefs.data.showRendered)
			renderedTxt.text = 'Rendered Notes: ' + formatNumber(notes.length);

		laneunderlayOpponent.cameras = [camHUD];
		laneunderlay.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpHoldSplashes.cameras = [camHUD];
		sustainNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		if (EngineWatermark != null) EngineWatermark.cameras = [camHUD];
		judgementCounter.cameras = [camHUD];
		if (scoreTxt != null) scoreTxt.cameras = [camHUD];
		if (botplayTxt != null) botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		popUpGroup.cameras = [camHUD];

		startingSong = true;
		MusicBeatState.windowNameSuffix = " - " + SONG.song + " " + (isStoryMode ? "(Story Mode)" : "(Freeplay)");

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventPushedMap.keys())
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypeMap.keys())
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventPushedMap.keys())
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if (file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end
				#if HSCRIPT_ALLOWED
				if (file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		startCallback();
		RecalculateRating();

		if(!ClientPrefs.data.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if (hitSoundString != "none")
			hitsound = FlxG.sound.load(Paths.sound("hitsounds/" + Std.string(hitSoundString).toLowerCase()));
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		hitsound.volume = ClientPrefs.data.hitsoundVolume;
		hitsound.pitch = playbackRate;
		for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(ClientPrefs.data.pauseMusic != 'None')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		if(cpuControlled && ClientPrefs.data.randomBotplayText && ClientPrefs.data.botTxtStyle != 'Hide' && botplayTxt != null && ffmpegInfo != 'Frame Time')
			botplayTxt.text = theListBotplay[FlxG.random.int(0, theListBotplay.length - 1)];

		if (botplayTxt != null) ogBotTxt = botplayTxt.text;
		
		resetRPC();
		callOnScripts('onCreatePost');
		stagesFunc(function(stage:BaseStage) stage.createPost());

		cacheCountdown();
		cachePopUpScore();

		super.create();
		Paths.clearUnusedMemory();

		startingTime = haxe.Timer.stamp();
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

	public function initLuaShader(name:String)
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

	inline function set_songSpeed(value:Float):Float
	{
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	inline function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = opponentVocals.pitch = gfVocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		trace('Anim speed: ' + FlxG.animationTimeScale);
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0;
		#end
		return playbackRate;
	}

	inline function set_polyphony(value:Float, which:Int):Float
	{
		switch (which) {
		    case 0:
		        polyphonyOppo = value;
		        polyphonyBF = value;
		    case 1:
		        polyphonyOppo = value;
		    case 2:
		        polyphonyBF = value;
		    // just in case, as an anti-crash prevention maybe?
		    default:
			polyphonyOppo = value;
		        polyphonyBF = value;
		}
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
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
		#end
	}

	public function reloadHealthBarColors(leftColorArray:Array<Int>, rightColorArray:Array<Int>) {
		if (!ClientPrefs.data.ogHPColor) {
				healthBar.createFilledBar(FlxColor.fromRGB(leftColorArray[0], leftColorArray[1], leftColorArray[2]),
				FlxColor.fromRGB(rightColorArray[0], rightColorArray[1], rightColorArray[2]));
		} else if (ClientPrefs.data.ogHPColor) {
				healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		}

		healthBar.updateBar();
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
		if (FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaFile))
			doPush = true;
		#end

		if (doPush)
		{
			for (script in luaArray)
			{  var script:Dynamic = cast(script);
				if (script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if (doPush)
				new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if (FileSystem.exists(scriptFile))
				doPush = true;
		}

		if (doPush)
		{
			if (Iris.instances.exists(scriptFile))
				doPush = false;

			if (doPush)
				initHScript(scriptFile);
		}
		#end
	}

	public function addShaderToCamera(cam:String,effect:Dynamic){//STOLE FROM ANDROMEDA	// actually i got it from old psych engine
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
				camHUDShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camHUDShaders){
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.filters = newCamEffects;
			case 'camother' | 'other':
				camOtherShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camOtherShaders){
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.filters = newCamEffects;
			case 'camgame' | 'game':
				camGameShaders.push(effect);
				var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for(i in camGameShaders){
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.filters = newCamEffects;
			default:
				if(modchartSprites.exists(cam)) {
					Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
				} else if(modchartTexts.exists(cam)) {
					Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
				} else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", effect.shader);
				}
		}
  }

  public function removeShaderFromCamera(cam:String,effect:ShaderEffect){
	switch(cam.toLowerCase()) {
		case 'camhud' | 'hud':
			camHUDShaders.remove(effect);
			var newCamEffects:Array<BitmapFilter>=[];
			for(i in camHUDShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
			}
			camHUD.filters = newCamEffects;
		case 'camother' | 'other':
			camOtherShaders.remove(effect);
			var newCamEffects:Array<BitmapFilter>=[];
			for(i in camOtherShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
			}
			camOther.filters = newCamEffects;
		default:
			if(modchartSprites.exists(cam)) {
				Reflect.setProperty(modchartSprites.get(cam),"shader",null);
			} else if(modchartTexts.exists(cam)) {
				Reflect.setProperty(modchartTexts.get(cam),"shader",null);
			} else {
				var OBJ = Reflect.getProperty(PlayState.instance,cam);
				Reflect.setProperty(OBJ,"shader", null);
			}
		}
  }
  public function clearShaderFromCamera(cam:String){
	switch(cam.toLowerCase()) {
		case 'camhud' | 'hud':
			camHUDShaders = [];
			var newCamEffects:Array<BitmapFilter>=[];
			camHUD.filters = newCamEffects;
		case 'camother' | 'other':
			camOtherShaders = [];
			var newCamEffects:Array<BitmapFilter>=[];
			camOther.filters = newCamEffects;
		case 'camgame' | 'game':
			camGameShaders = [];
			var newCamEffects:Array<BitmapFilter>=[];
			camGame.filters = newCamEffects;
		default:
			camGameShaders = [];
			var newCamEffects:Array<BitmapFilter>=[];
			camGame.filters = newCamEffects;
	}
  }

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
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

	/***************/
    /*    VIDEO    */
	/***************/
	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, ?library:String = null, ?callback:Void->Void = null, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;
		canPause = false;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name, library);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = false;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = (callback != null) ? callback.bind() : onVideoEnd;
				videoCutscene.onSkip = (callback != null) ? callback.bind() : onVideoEnd;
			}
			add(videoCutscene);

			if (playOnLoad)
				videoCutscene.videoSprite.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED)
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

	public function startAndEnd()
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

	public function changeTheSettingsBitch() {
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		hpDrainLevel = ClientPrefs.getGameplaySetting('drainlevel', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		sickOnly = ClientPrefs.getGameplaySetting('onlySicks', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		opponentChart = ClientPrefs.getGameplaySetting('opponentplay', false);
		trollingMode = ClientPrefs.getGameplaySetting('thetrollingever', false);
		opponentDrain = ClientPrefs.getGameplaySetting('opponentdrain', false);
		randomMode = ClientPrefs.getGameplaySetting('randommode', false);
		flip = ClientPrefs.getGameplaySetting('flip', false);
		stairs = ClientPrefs.getGameplaySetting('stairmode', false);
		waves = ClientPrefs.getGameplaySetting('wavemode', false);
		oneK = ClientPrefs.getGameplaySetting('onekey', false);
		randomSpeedThing = ClientPrefs.getGameplaySetting('randomspeed', false);
		jackingtime = ClientPrefs.getGameplaySetting('jacks', 0);
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		ogSongSpeed = songSpeed;

		shouldDrainHealth = (opponentDrain || (opponentChart ? boyfriend.healthDrain : dad.healthDrain));
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainAmount)) healthDrainAmount = opponentChart ? boyfriend.drainAmount : dad.drainAmount;
		if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainFloor)) healthDrainFloor = opponentChart ? boyfriend.drainFloor : dad.drainFloor;
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		if (dialogueBox == null){
			startCountdown();
			return;
		} // don't load any of this, since there's not even any dialog

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
				remove(black);
			}
		});
	}

	var fps:Float = 60;
	var bfCanPan:Bool = false;
	var dadCanPan:Bool = false;
	var doPan:Bool = false;
	function camPanRoutine(anim:String = 'singUP', who:String = 'bf'):Void {
		if (SONG.notes[curSection] != null)
		{
			fps = FlxG.updateFramerate;
			bfCanPan = SONG.notes[curSection].mustHitSection;
			dadCanPan = !SONG.notes[curSection].mustHitSection;
			switch (who) {
				case 'bf' | 'boyfriend': doPan = bfCanPan;
				case 'oppt' | 'dad': doPan = dadCanPan;
			}
			//FlxG.elapsed is stinky poo poo for this, it just makes it look jank as fuck
			if (doPan) {
				if (fps == 0) fps = 1;
				switch (anim.split('-')[0])
				{
					case 'singUP': moveCamTo[1] = -40*ClientPrefs.data.panIntensity*240*playbackRate/fps;
					case 'singDOWN': moveCamTo[1] = 40*ClientPrefs.data.panIntensity*240*playbackRate/fps;
					case 'singLEFT': moveCamTo[0] = -40*ClientPrefs.data.panIntensity*240*playbackRate/fps;
					case 'singRIGHT': moveCamTo[0] = 40*ClientPrefs.data.panIntensity*240*playbackRate/fps;
				}
			}
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
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		intro3 = new FlxSound().loadEmbedded(Paths.sound('intro3' + introSoundsSuffix));
		intro2 = new FlxSound().loadEmbedded(Paths.sound('intro2' + introSoundsSuffix));
		intro1 = new FlxSound().loadEmbedded(Paths.sound('intro1' + introSoundsSuffix));
		introGo = new FlxSound().loadEmbedded(Paths.sound('introGo' + introSoundsSuffix));
	}

	public static function formatCompactNumber(number:Float):String
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

	public static function formatNumber(number:Float, ?decimals:Bool = false):String //simplified number formatting
	{
		return (number < 10e11 ? FlxStringUtil.formatMoney(number, false) : formatCompactNumber(number));
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown');

		if (SONG.song.toLowerCase() == 'anti-cheat-song')
		{
			secretsong = new FlxSprite().loadGraphic(Paths.image('secretSong'));
			secretsong.antialiasing = ClientPrefs.data.globalAntialiasing;
			secretsong.scrollFactor.set();
			secretsong.setGraphicSize(Std.int(secretsong.width / FlxG.camera.zoom));
			secretsong.updateHitbox();
			secretsong.screenCenter();
			secretsong.cameras = [camGame];
			add(secretsong);
		}
		if (middleScroll)
		{
			laneunderlayOpponent.alpha = 0;
			laneunderlay.screenCenter(X);
		}

		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			callOnScripts('preReceptorGeneration'); // backwards compat, deprecated
			callOnScripts('onReceptorGeneration');
			generateStaticArrows(0);
			generateStaticArrows(1);
			callOnScripts('postReceptorGeneration'); // deprecated
			callOnScripts('onReceptorGenerationPost');

			callOnScripts('preModifierRegister'); // deprecated
			callOnScripts('onModifierRegister');
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if(bothSides) opponentStrums.members[i].visible = false;
			}
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			callOnScripts('postModifierRegister'); // deprecated
			callOnScripts('onModifierRegisterPost');

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

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
				if (ClientPrefs.data.charsAndBG) characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = ClientPrefs.data.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				var tick:Countdown = THREE;

				if (swagCounter > 0 && swagCounter < 4) createCountdownSprite(introAlts[swagCounter-1], antialias);

				switch (swagCounter)
				{
					case 0:
						intro3.volume = FlxG.sound.volume;
						intro3.play();
						tick = THREE;
					case 1:
						intro2.volume = FlxG.sound.volume;
						intro2.play();
						tick = TWO;
					case 2:
						intro1.volume = FlxG.sound.volume;
						intro1.play();
						tick = ONE;
					case 3:
						introGo.volume = FlxG.sound.volume;
						introGo.play();
						tick = GO;
						if (ClientPrefs.data.tauntOnGo && ClientPrefs.data.charsAndBG)
						{
							final charsToHey = [dad, boyfriend, gf];
							for (char in charsToHey)
							{
								if(char != null)
								{
									if (char.animOffsets.exists('hey') || char.animOffsets.exists('cheer'))
									{
										char.playAnim(char.animOffsets.exists('hey') ? 'hey' : 'cheer', true);
										char.specialAnim = true;
										char.heyTimer = 0.6;
									} else if (char.animOffsets.exists('singUP') && (!char.animOffsets.exists('hey') || !char.animOffsets.exists('cheer')))
									{
										char.playAnim('singUP', true);
										char.specialAnim = true;
										char.heyTimer = 0.6;
									}
								}
							}
						}
					case 4:
					tick = START;
					if (SONG.songCredit != null && SONG.songCredit.length > 0)
					{
						var creditsPopup:CreditsPopUp = new CreditsPopUp(FlxG.width, 200, SONG.song, SONG.songCredit);
						creditsPopup.cameras = [camHUD];
						creditsPopup.scrollFactor.set();
						creditsPopup.x = creditsPopup.width * -1;
						add(creditsPopup);

						FlxTween.tween(creditsPopup, {x: 0}, 0.5, {ease: FlxEase.backOut, onComplete: function(tweeen:FlxTween)
						{
							FlxTween.tween(creditsPopup, {x: creditsPopup.width * -1} , 1, {ease: FlxEase.backIn, onComplete: function(tween:FlxTween)
							{
								creditsPopup.destroy();
							}, startDelay: 3});
						}});
					}
				}

				for (group in [notes, sustainNotes]) group.forEachAlive(function(note:Note) {
					if(ClientPrefs.data.opponentStrums || !ClientPrefs.data.opponentStrums || middleScroll || !note.mustPress)
					{
						note.alpha *= 0.35;
					}
					if(ClientPrefs.data.opponentStrums || !ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});
				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnScripts('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
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
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {"scale.x": 0, "scale.y": 0, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
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

	public function clearNotesBefore(time:Float)
	{
		for (group in [notes, sustainNotes])
		{
			var i:Int = group.length - 1;
			while (i >= 0) {
				var daNote:Note = group.members[i];
				if(daNote.strumTime - 350 < time)
				{
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;
					group.remove(daNote, true);
				}
				--i;
			}
		}
	}

	var comboInfo = ClientPrefs.data.showComboInfo;
	var showNPS = ClientPrefs.data.showNPS;
	var missString:String = '';
	public function updateScore(miss:Bool = false)
	{
		scoreTxtUpdateFrame++;
		if (!scoreTxt.visible || scoreTxt == null)
			return;
		//GAH DAYUM THIS IS MORE OPTIMIZED THAN BEFORE
		var divider = switch (ClientPrefs.data.scoreStyle)
		{
			case 'Leather Engine': '~';
			case 'Forever Engine': '•';
			default: '|';
		}
		formattedScore = formatNumber(songScore);
		if (ClientPrefs.data.scoreStyle == 'JS Engine') formattedScore = formatNumber(shownScore);
		formattedSongMisses = formatNumber(songMisses);
		formattedCombo = formatNumber(combo);
		formattedNPS = formatNumber(nps);
		formattedMaxNPS = formatNumber(maxNPS);
		npsString = showNPS ? ' $divider ' + (cpuControlled && ClientPrefs.data.botWatermark ? 'Bot ' : '') + 'NPS/Max: ' + formattedNPS + '/' + formattedMaxNPS : '';
		accuracy = Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
		fcString = ratingFC;
		missString = (!instakillOnMiss ? switch(ClientPrefs.data.scoreStyle)
		{
			case 'Kade Engine', 'VS Impostor': ' $divider Combo Breaks: ' + formattedSongMisses;
			case 'Doki Doki+': ' $divider Breaks: ' + formattedSongMisses;
			default: 
				' $divider Misses: ' + formattedSongMisses;
		} : '');

		botText = cpuControlled && ClientPrefs.data.botWatermark ? ' $divider Botplay Mode' : '';

		if (cpuControlled && ClientPrefs.data.botWatermark)
			tempScore = 'Bot Score: ' + formattedScore + (comboInfo ? ' $divider Bot Combo: ' + formattedCombo : '') + npsString + botText;

		else switch (ClientPrefs.data.scoreStyle)
		{
			case 'Kade Engine', 'Doki Doki+':
				tempScore = 'Score: ' + formattedScore + missString + (comboInfo ? ' $divider Combo: ' + formattedCombo : '') + npsString + ' $divider Accuracy: ' + accuracy + ' $divider (' + fcString + ') ' + ratingName;

			case "Dave Engine":
				tempScore = 'Score: ' + formattedScore + missString + (comboInfo ? ' $divider Combo: ' + formattedCombo : '') + npsString + ' $divider Accuracy: ' + accuracy + ' $divider ' + fcString;

			case "Forever Engine":
				tempScore = 'Score: ' + formattedScore + ' $divider Accuracy: $accuracy ['  + fcString + ']' + missString + (comboInfo ? ' $divider Combo: ' + formattedCombo : '') + npsString + ' $divider Rank: ' + ratingName;

			case "Psych Engine", "JS Engine", "TGT V4":
				tempScore = 'Score: ' + formattedScore + missString + (comboInfo ? ' $divider Combo: ' + formattedCombo : '') + npsString + ' $divider Rating: ' + ratingName + (ratingName != '?' ? ' (${accuracy}) - $fcString' : '');

			case "Leather Engine":
				tempScore = '< Score: ' + formattedScore + missString + (comboInfo ? ' $divider Combo: ' + formattedCombo : '') + npsString + ' $divider Rating: ' + ratingName + (ratingName != '?' ? ' (${accuracy}) - $fcString' : '');

			case 'VS Impostor':
				tempScore = 'Score: ' + formattedScore + missString + (comboInfo ? ' $divider Combo: ' + formattedCombo : '') + npsString + ' $divider Accuracy: $accuracy ['  + fcString + ']';

			case 'Vanilla':
				tempScore = 'Score: ' + formattedScore;
		}

		scoreTxt.text = '${tempScore}\n';

		callOnScripts('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		pauseVocals();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		if (ffmpegMode) FlxG.sound.music.volume = 0;

		if (Conductor.songPosition <= vocals.length)
		{
			setVocalsTime(time);
			#if FLX_PITCH
			vocals.pitch = playbackRate;
			opponentVocals.pitch = playbackRate;
			gfVocals.pitch = playbackRate;
			#end
		}
		vocals.play();
		opponentVocals.play();
		gfVocals.play();
		if (ffmpegMode) vocals.volume = opponentVocals.volume = gfVocals.volume = 0;
		Conductor.songPosition = time;
		songTime = time;
		clearNotesBefore(time);
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		var diff:String = (SONG.specialAudioName.length > 1 ? SONG.specialAudioName : Difficulty.difficultyString()).toLowerCase();
		@:privateAccess
		if (!ffmpegMode) {
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, diff), 1, false);
			FlxG.sound.music.onComplete = finishSong.bind();
		} else {
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, diff), 0, false);
			vocals.volume = 0;
			opponentVocals.play();
			gfVocals.play();
		}
		if (!ffmpegMode && (!trollingMode || SONG.song.toLowerCase() != 'anti-cheat-song'))
			FlxG.sound.music.onComplete = finishSong.bind();
			FlxG.sound.music.pitch = playbackRate;
		vocals.play();
		opponentVocals.play();
		gfVocals.play();
		vocals.pitch = opponentVocals.pitch = gfVocals.pitch = playbackRate;

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			pauseVocals();
		}
		curTime = Conductor.songPosition - ClientPrefs.data.noteOffset;
		songPercent = (curTime / songLength);

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		if (ClientPrefs.data.lengthIntro) FlxTween.tween(this, {songLength: FlxG.sound.music.length}, 1, {ease: FlxEase.expoOut});
		if (!ClientPrefs.data.lengthIntro) songLength = FlxG.sound.music.length; //so that the timer won't just appear as 0
		if (ClientPrefs.data.timeBarType != 'Disabled') {
		timeBar.scale.x = 0.01;
		FlxTween.tween(timeBar, {alpha: 1, "scale.x": 1}, 1, {ease: FlxEase.expoOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4 && judgementCounter != null) updateRatingCounter();
		if (scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();

		// TODO: Lock other note inputs
		if (oneK)
		{
			playerStrums.forEachAlive(function(daNote:FlxSprite)
			{
				if (daNote != playerStrums.members[firstNoteData]) 
				{
					FlxTween.cancelTweensOf(daNote);
					FlxTween.tween(daNote, {alpha: 0}, 0.7, {ease: FlxEase.expoOut});
				}
			});
			opponentStrums.forEachAlive(function(daNote:FlxSprite)
			{
				if (daNote != opponentStrums.members[firstNoteData]) 
				{
					FlxTween.cancelTweensOf(daNote);
					FlxTween.tween(daNote, {alpha: 0}, 0.7, {ease: FlxEase.expoOut});
				}
			});
			FlxG.sound.play(Paths.sound('FunnyVanish'));
		}

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) {
			if (cpuControlled) detailsText = detailsText + ' (using a bot)';
			// Updating Discord Rich Presence (with Time Left)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		}
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var ogSongSpeed:Float = 0;
	public function lerpSongSpeed(num:Float, time:Float):Void
	{
		FlxTween.num(playbackRate, num, time, {onUpdate: function(tween:FlxTween){
			var ting = FlxMath.lerp(playbackRate, num, tween.percent);
			var ting2 = FlxMath.lerp(songSpeed, ogSongSpeed / playbackRate, tween.percent);
			if (ting != 0) //divide by 0 is a verry bad
				playbackRate = ting; //why cant i just tween a variable

			if (ting2 != 0)
				songSpeed = ogSongSpeed / playbackRate;

			setVocalsTime(Conductor.songPosition);
			if (!ffmpegMode) resyncVocals();
		}});
	}

	var debugNum:Int = 0;
	var stair:Int = 0;
	var firstNoteData:Int = 0;
	var assignedFirstData:Bool = false;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String, ?startingPoint:Float = 0):Void
	{
		var offsetStart = (startingPoint > 0 ? 500 : 0);
	   	final startTime = haxe.Timer.stamp();

		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		ogSongSpeed = songSpeed;

		Conductor.changeBPM(SONG.bpm);

		curSong = SONG.song;

		var diff:String = (SONG.specialAudioName.length > 1 ? SONG.specialAudioName : Difficulty.difficultyString()).toLowerCase();

		if (SONG.windowName != null && SONG.windowName != '')
			MusicBeatState.windowNamePrefix = SONG.windowName;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		gfVocals = new FlxSound();
		try
		{
			if (SONG.needsVoices)
			{
				var playerVocals = Paths.voices(curSong, diff, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(curSong, diff));
				
				var oppVocals = Paths.voices(curSong, diff, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
				
				var gfVocal = Paths.voices(curSong, diff, (gf.vocalsFile == null || gf.vocalsFile.length < 1) ? 'GF' : gf.vocalsFile);
				if(gfVocal != null) gfVocals.loadEmbedded(gfVocal);
			}
		}
		catch(e) {}

		vocals.pitch = opponentVocals.pitch = gfVocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);
		FlxG.sound.list.add(gfVocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song, diff)));

		final noteData:Array<SwagSection> = SONG.notes;

		var eventsToLoad:String = (SONG.specialEventsName.length > 1 ? SONG.specialEventsName : Difficulty.difficultyString()).toLowerCase();

		final songName:String = Paths.formatToSongPath(SONG.song);
		final file:String = Paths.songEvents(songName, eventsToLoad);
		try
		{
			var eventsChart:SwagSong = Song.getChart(Paths.songEvents(songName, eventsToLoad, true), songName);
			if (eventsChart != null)
				for (event in eventsChart.events) // Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch (e:Dynamic)
		{
		}
		var stepCrochet:Float = 0.0;
		var currentBPMLol:Float = Conductor.bpm;
		var currentMultiplier:Float = 1;
		var gottaHitNote:Bool = false;
		var swagNote:PreloadedChartNote;
		for (section in noteData) {
			if (section.changeBPM) currentBPMLol = section.bpm;

			for (songNotes in section.sectionNotes) {
				if (songNotes[0] >= startingPoint + offsetStart) {
					final daStrumTime:Float = songNotes[0];
					var daNoteData:Int = 0;
					if (!assignedFirstData && oneK)
					{
						firstNoteData = Std.int(songNotes[1] % 4);
						assignedFirstData = true;
					}
					if (!randomMode && !flip && !stairs && !waves) daNoteData = Std.int(songNotes[1] % 4);

					if (oneK) daNoteData = firstNoteData;

					if (randomMode) daNoteData = FlxG.random.int(0, 3);

					if (flip) daNoteData = Std.int(Math.abs((songNotes[1] % 4) - 3));

					if (stairs && !waves) {
						daNoteData = stair % 4;
						stair++;
					}

					if (waves) {
						switch (stair % 6) {
							case 0 | 1 | 2 | 3:
								daNoteData = stair % 6;
							case 4:
								daNoteData = 2;
							case 5:
								daNoteData = 1;
						}
						stair++;
					}
					
					gottaHitNote = ((songNotes[1] < 4 && !opponentChart)
						|| (songNotes[1] > 3 && opponentChart) ? section.mustHitSection : !section.mustHitSection);

					if ((bothSides || gottaHitNote) && songNotes[3] != 'Hurt Note') {
						totalNotes += 1;
					}
					if (!bothSides && !gottaHitNote) {
						opponentNoteTotal += 1;
					}

					if (daStrumTime >= charChangeTimes[0])
					{
						switch (charChangeTypes[0])
						{
							case 0:
								var boyfriendToGrab:Boyfriend = boyfriendMap.get(charChangeNames[0]);
								if (boyfriendToGrab != null) bfNoteskin = boyfriendToGrab.noteskin;
							case 1:
								var dadToGrab:Character = dadMap.get(charChangeNames[0]);
								if (dadToGrab != null) dadNoteskin = dadToGrab.noteskin;
						}
						charChangeTimes.shift();
						charChangeNames.shift();
						charChangeTypes.shift();
					}

					if (multiChangeEvents[0].length > 0 && daStrumTime >= multiChangeEvents[0][0])
					{
						currentMultiplier = multiChangeEvents[1][0];
						multiChangeEvents[0].shift();
						multiChangeEvents[1].shift();
					}
		
					swagNote = cast {
						strumTime: daStrumTime,
						noteData: daNoteData,
						mustPress: bothSides || gottaHitNote,
						oppNote: (opponentChart ? gottaHitNote : !gottaHitNote),
						noteType: songNotes[3],
						animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
						noteskin: (gottaHitNote ? bfNoteskin : dadNoteskin),
						gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < 4),
						noAnimation: songNotes[3] == 'No Animation',
						noMissAnimation: songNotes[3] == 'No Animation',
						sustainLength: songNotes[2],
						hitHealth: 0.023,
						missHealth: songNotes[3] != 'Hurt Note' ? 0.0475 : 0.3,
						wasHit: false,
						hitCausesMiss: songNotes[3] == 'Hurt Note',
						multSpeed: 1,
						noteDensity: currentMultiplier,
						ignoreNote: songNotes[3] == 'Hurt Note' && gottaHitNote
					};
					if (swagNote.noteskin.length > 0 && !Paths.noteSkinFramesMap.exists(swagNote.noteskin)) inline Paths.initNote(4, swagNote.noteskin);

					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = states.editors.charting.JSChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

					if(Std.isOfType(songNotes[3], Bool)) swagNote.animSuffix = (songNotes[3] || section.altAnim ? '-alt' : ''); //Compatibility with charts made by SNIFF
		
					if (!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
		
					unspawnNotes.push(swagNote);

					if (jackingtime > 0) {
						for (i in 0...Std.int(jackingtime)) {
							final jackNote:PreloadedChartNote = cast {
								strumTime: swagNote.strumTime + (15000 / SONG.bpm) * (i + 1),
								noteData: swagNote.noteData,
								mustPress: swagNote.mustPress,
								oppNote: swagNote.oppNote,
								noteType: swagNote.noteType,
								animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
								noteskin: (gottaHitNote ? bfNoteskin : dadNoteskin),
								gfNote: swagNote.gfNote,
								isSustainNote: false,
								isSustainEnd: false,
								parentST: 0,
								hitHealth: swagNote.hitHealth,
								missHealth: swagNote.missHealth,
								wasHit: false,
								multSpeed: 1,
								noteDensity: currentMultiplier,
								hitCausesMiss: swagNote.hitCausesMiss,
								ignoreNote: swagNote.ignoreNote
							};
							unspawnNotes.push(jackNote);
						}
					}

					if (swagNote.sustainLength < 1) continue;

					stepCrochet = 15000 / currentBPMLol;
		
					final roundSus:Int = Math.round(swagNote.sustainLength / stepCrochet);
					if (roundSus > 0) {
						for (susNote in 0...roundSus + 1) {

							final sustainNote:PreloadedChartNote = cast {
								strumTime: daStrumTime + (stepCrochet * susNote),
								noteData: daNoteData,
								mustPress: bothSides || gottaHitNote,
								oppNote: (opponentChart ? gottaHitNote : !gottaHitNote),
								noteType: songNotes[3],
								animSuffix: (songNotes[3] == 'Alt Animation' || section.altAnim ? '-alt' : ''),
								noteskin: (gottaHitNote ? bfNoteskin : dadNoteskin),
								gfNote: songNotes[3] == 'GF Sing' || (section.gfSection && songNotes[1] < 4),
								noAnimation: songNotes[3] == 'No Animation',
								isSustainNote: true,
								isSustainEnd: susNote == roundSus,
								parentST: swagNote.strumTime,
								parentSL: swagNote.sustainLength,
								hitHealth: 0.023,
								missHealth: songNotes[3] != 'Hurt Note' ? 0.0475 : 0.1,
								wasHit: false,
								multSpeed: 1,
								noteDensity: currentMultiplier,
								hitCausesMiss: songNotes[3] == 'Hurt Note',
								ignoreNote: songNotes[3] == 'Hurt Note' && swagNote.mustPress
							};
							unspawnNotes.push(sustainNote);
						}
					}
				} else {
					final gottaHitNote:Bool = ((songNotes[1] < 4 && !opponentChart)
						|| (songNotes[1] > 3 && opponentChart) ? section.mustHitSection : !section.mustHitSection);
					if ((bothSides || gottaHitNote) && !songNotes.hitCausesMiss) {
						totalNotes += 1;
						combo += 1;
						totalNotesPlayed += 1;
					}
					if (!bothSides && !gottaHitNote) {
						opponentNoteTotal += 1;
						enemyHits += 1;
					}
				}
			}
			sectionsLoaded += 1;
			notesLoadedRN += section.sectionNotes.length;
			Sys.print('\rSection $sectionsLoaded loaded! (' + notesLoadedRN + ' notes)');
		}

		bfNoteskin = boyfriend.noteskin;
		dadNoteskin = dad.noteskin;

		if (ClientPrefs.data.noteColorStyle == 'Char-Based')
		{
			for (group in [notes, sustainNotes])
				for (note in group){
					if (note == null)
						continue;
					if (ClientPrefs.data.enableColorShader) note.updateRGBColors();
				}
		}

		unspawnNotes.sort(sortByTime);
		eventNotes.sort(sortByTime);
		unspawnNotesCopy = unspawnNotes.copy();
		eventNotesCopy = eventNotes.copy();
		generatedMusic = true;

		sectionsLoaded = 0;

		final endTime = haxe.Timer.stamp();

		openfl.system.System.gc();

		final elapsedTime = endTime - startTime;

		trace('\nDone! \n\nTime taken: ' + CoolUtil.formatTime(elapsedTime * 1000) + "\nAverage NPS while loading: " + Math.floor(notesLoadedRN / elapsedTime));
		notesLoadedRN = 0;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}
				charChangeTimes.push(event.strumTime);
				charChangeNames.push(event.value2);
				charChangeTypes.push(charType);
			case 'Change Note Multiplier':
				var noteMultiplier:Float = Std.parseFloat(event.value1);
				if (Math.isNaN(noteMultiplier))
					noteMultiplier = 1;

				multiChangeEvents[0].push(event.strumTime);
				multiChangeEvents[1].push(noteMultiplier);
		}
		eventPushedUnique(event);
		if(eventPushedMap.exists(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
			if (ClientPrefs.data.charsAndBG)
			{
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			}
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}

	public inline function getTimeFromSV(time:Float, event:SpeedEvent)
		return event.position + (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);

	public function getSV(time:Float)
	{
		var event:SpeedEvent = {
			position: 0,
			songTime: 0,
			startTime: 0,
			startSpeed: 1,
			speed: 1
		};
		for (shit in speedChanges)
		{
			if (shit.startTime <= time && shit.startTime >= event.startTime)
			{
				if (shit.startSpeed == null)
					shit.startSpeed = event.speed;
				event = shit;
			}
		}

		return event;
	}

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [
			subEvent.event,
			subEvent.value1 != null ? subEvent.value1 : '',
			subEvent.value2 != null ? subEvent.value2 : '',
			subEvent.strumTime
		]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		final strumLine:FlxPoint = FlxPoint.get(middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, (ClientPrefs.data.downScroll) ? FlxG.height - 150 : 50);
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(middleScroll) targetAlpha = ClientPrefs.data.oppNoteAlpha;
			}

			final noteSkinExists:Bool = Paths.fileExists("images/noteskins/" + (player == 0 ? dadNoteskin : bfNoteskin) + '.png', IMAGE);

			var babyArrow:StrumNote = new StrumNote(middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (noteSkinExists) 
			{
				babyArrow.texture = "noteskins/" + (player == 0 ? dad.noteskin : boyfriend.noteskin);
				babyArrow.useRGBShader = false;
			}
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1/(Conductor.bpm/240) / playbackRate, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i) / (Conductor.bpm/240) / playbackRate});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				if (!opponentChart || opponentChart && middleScroll) playerStrums.add(babyArrow);
				else opponentStrums.add(babyArrow);
			}
			else
			{
				if(middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				if (!opponentChart || opponentChart && middleScroll) opponentStrums.add(babyArrow);
				else playerStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
			/*
			if (ClientPrefs.data.noteColorStyle != 'Normal' !PlayState.isPixelStage) 
			{
				var arrowAngle = switch(i)
				{
					case 0: 180;
					case 1: 90;
					case 2: 270;
					default: 0;
				}
				babyArrow.noteData = 3;
				babyArrow.angle += arrowAngle;
				babyArrow.reloadNote();
			}
			*/
		}
		strumLine.put();
	}

	override function openSubState(SubState:flixel.FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				pauseVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && !ffmpegMode)
			{
				resyncVocals();
			}

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);
			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		try {if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);}
		catch(e) {};
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		try {if (health > 0 && !paused && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());}
		catch(e) {};
		#end

		super.onFocusLost();
	}

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
		if(finishTimer != null || paused) return;

		FlxG.sound.music.pitch = playbackRate;
		vocals.pitch = opponentVocals.pitch = gfVocals.pitch = playbackRate;
		if(!(Conductor.songPosition > 20 && FlxG.sound.music.time < 20))
		{
			pauseVocals();
			FlxG.sound.music.pause();

			if(FlxG.sound.music.time >= FlxG.sound.music.length)
				Conductor.songPosition = FlxG.sound.music.length;
			else
				Conductor.songPosition = FlxG.sound.music.time;

			setVocalsTime(Conductor.songPosition);

			FlxG.sound.music.play();
			for (i in [vocals, opponentVocals, gfVocals])
				if (i != null && i.time <= i.length) i.play();
		}
		else
		{
			while(Conductor.songPosition > 20 && FlxG.sound.music.time < 20)
			{
				FlxG.sound.music.time = Conductor.songPosition;
				setVocalsTime(Conductor.songPosition);

				FlxG.sound.music.play();
				for (i in [vocals, opponentVocals, gfVocals])
					if (i != null && i.time <= i.length) i.play();
			}
		}
	}

	public function die():Void
	{
		bfkilledcheck = true;
		doDeathCheck(true);
		health = 0;
		noteMissPress(3); // just to make sure you actually die
	}	

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var pbRM:Float = 2.0;

	public var takenTime:Float = haxe.Timer.stamp();
	public var totalRenderTime:Float = 0;

	public var amountOfRenderedNotes:Float = 0;
	public var maxRenderedNotes:Float = 0;
	public var skippedCount:Float = 0;
	public var maxSkipped:Float = 0;

	var canUseBotEnergy:Bool = false;
	var usingBotEnergy:Bool = false;
	var noEnergy:Bool = false;
	var holdingBotEnergyBind:Bool = false;
	var strumsHeld:Array<Bool> = [false, false, false, false];
	var strumHeldAmount:Int = 0;
	var notesBeingHit:Bool = false;
	var notesBeingMissed:Bool = false;
	var hitResetTimer:Float = 0;
	var missResetTimer:Float = 0;
	var botEnergyCooldown:Float = 0;
	var energyDrainSpeed:Float = 1;
	var energyRefillSpeed:Float = 1;
	var NOTE_SPAWN_TIME:Float = 0;

	var spawnedNote:Note = new Note();

	override public function update(elapsed:Float)
	{
		if (ffmpegMode) elapsed = 1 / ClientPrefs.data.targetFPS;
		
		callOnScripts('onUpdate', [elapsed]);
		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);
		
		if (screenshader.Enabled)
		{
			if(disableTheTripperAt == curStep)
			{
				disableTheTripper = true;
			}
			if(isDead)
			{
				disableTheTripper = true;
			}

			FlxG.camera.filters = [new ShaderFilter(screenshader.shader)];
			screenshader.update(elapsed);
			if(disableTheTripper)
			{
				screenshader.shader.uampmul.value[0] -= (elapsed / 2);
			}
		}
		if (ClientPrefs.data.pbRControls)
		{
			if (FlxG.keys.pressed.SHIFT) {
				if (pbRM != 4.0) pbRM = 4.0;
			} else {
				if (pbRM != 2.0) pbRM = 2.0;
			}
	   			if (FlxG.keys.justPressed.SLASH)
						playbackRate /= pbRM;

				if (FlxG.keys.justPressed.PERIOD)
		   			playbackRate *= pbRM;
		}
		if (!cpuControlled && canUseBotEnergy) 
		{
			if (controls.BOT_ENERGY_P && !noEnergy)
			{
				usingBotEnergy = true;
			}
			else
			{
				usingBotEnergy = false;
			}
			if (notesBeingHit && hitResetTimer >= 0)
			{
				health += elapsed / 2;
				hitResetTimer -= elapsed * playbackRate;
				if (hitResetTimer <= 0) notesBeingHit = false;
				if (missResetTimer > 0) missResetTimer -= 0.01 / (ClientPrefs.data.framerate / 60) * playbackRate;
			}
			if (notesBeingMissed && missResetTimer >= 0)
			{
				if (missResetTimer > 0.1) missResetTimer = 0.1;
				health -= missResetTimer / (ClientPrefs.data.framerate / 60) * playbackRate;
				missResetTimer -= elapsed * playbackRate;
				if (missResetTimer <= 0) notesBeingMissed = false;
			}
			if (usingBotEnergy)
				botEnergy -= (elapsed / 5) * strumHeldAmount * energyDrainSpeed * playbackRate;
			else
				botEnergy += (elapsed / 5) * energyRefillSpeed * playbackRate;

			if (botEnergy > 2) botEnergy = 2;

			if (botEnergy <= 0 && !noEnergy)
			{
				botEnergyCooldown = 1;
				noEnergy = true;
			}

			if (noEnergy)
			{
				botEnergyCooldown -= elapsed;
				if (botEnergyCooldown <= 0)
				{
					if (!FlxG.keys.pressed.CONTROL)
						noEnergy = false;
				}
			}
		}

		if (botEnergy > 0.2 && botEnergy < 1.8) energyBar.color = energyTxt.color = 0xFF0094FF;
		if (botEnergy < 0.2) energyBar.color = energyTxt.color = 0xFFC60000;
		if (botEnergy > 1.8) energyBar.color = energyTxt.color = 0xFF00BC12;

		energyTxt.text = (botEnergy < 2 ? FlxMath.roundDecimal(botEnergy * 50, 0) + '%' : 'Full');
		energyTxt.y = (FlxG.height / 1.3) - (botEnergy * 50 * 4);

		if (ClientPrefs.data.showcaseMode && botplayTxt != null)
		{
			botplayTxt.text = '${formatNumber(Math.abs(enemyHits))}/${formatNumber(Math.abs(totalNotesPlayed))}\nNPS: ${formatNumber(nps)}/${formatNumber(maxNPS)}\nOpp NPS: ${formatNumber(oppNPS)}/${formatNumber(maxOppNPS)}';
			if (polyphonyOppo != 1 || polyphonyBF != 1)
			{
				var set:String = formatNumber(polyphonyBF);
				if (formatNumber(polyphonyOppo) != formatNumber(polyphonyBF))
					set = formatNumber(polyphonyOppo) + "/" + formatNumber(polyphonyBF);
				botplayTxt.text += '\nNote Multiplier: ' + set;
			}
		}

		super.update(elapsed);

		if (tankmanAscend && curStep > 895 && curStep < 1151)
		{
			camGame.zoom = 0.8;
		}
		if (healthBar.percent >= 80 && !winning)
		{
			winning = true;
			reloadHealthBarColors(dad.losingColorArray, boyfriend.winningColorArray);
		}
		if (healthBar.percent <= 20 && !losing)
		{
			losing = true;
			reloadHealthBarColors(dad.winningColorArray, boyfriend.losingColorArray);
		}
		if (healthBar.percent >= 20 && losing || healthBar.percent <= 80 && winning)
		{
			losing = false;
			winning = false;
			reloadHealthBarColors(dad.healthColorArray, boyfriend.healthColorArray);
		}

		if(!inCutscene && ClientPrefs.data.charsAndBG) {
			final lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollow.setPosition(FlxMath.lerp(camFollow.x + moveCamTo[0]/102, camFollow.x + moveCamTo[0]/102, lerpVal), FlxMath.lerp(camFollow.y + moveCamTo[1]/102, camFollow.y + moveCamTo[1]/102, lerpVal));
			if (ClientPrefs.data.charsAndBG && !boyfriendIdled) {
				if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
					boyfriendIdleTime += elapsed;
					if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
						boyfriendIdled = true;
					}
				} else {
					boyfriendIdleTime = 0;
				}
			}
			final panLerpVal:Float = CoolUtil.clamp(elapsed * 4.4 * cameraSpeed, 0, 1);
			moveCamTo[0] = FlxMath.lerp(moveCamTo[0], 0, panLerpVal);
			moveCamTo[1] = FlxMath.lerp(moveCamTo[1], 0, panLerpVal);
		}
		if (ClientPrefs.data.showNPS && (notesHitDateArray.length > 0 || oppNotesHitDateArray.length > 0)) {
			notesToRemoveCount = 0;

			for (i in 0...notesHitDateArray.length) {
				if (!Math.isNaN(notesHitDateArray[i]) && (notesHitDateArray[i] + 1000 * npsSpeedMult < Conductor.songPosition)) {
					notesToRemoveCount++;
				}
			}

			if (notesToRemoveCount > 0) {
				notesHitDateArray.splice(0, notesToRemoveCount);
				notesHitArray.splice(0, notesToRemoveCount);
				if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4 && judgementCounter != null) updateRatingCounter();
				if (scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
			}

			nps = 0;
			for (value in notesHitArray) {
				nps += value;
			}
			
			oppNotesToRemoveCount = 0;

			for (i in 0...oppNotesHitDateArray.length) {
				if (!Math.isNaN(notesHitDateArray[i]) && (oppNotesHitDateArray[i] + 1000 * npsSpeedMult < Conductor.songPosition)) {
					oppNotesToRemoveCount++;
				}
			}

			if (oppNotesToRemoveCount > 0) {
				oppNotesHitDateArray.splice(0, oppNotesToRemoveCount);
				oppNotesHitArray.splice(0, oppNotesToRemoveCount);
				if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4 && judgementCounter != null) updateRatingCounter();
			}

			oppNPS = 0;
			for (value in oppNotesHitArray) {
				oppNPS += value;
			}

			if (oppNPS > maxOppNPS) {
				maxOppNPS = oppNPS;
			}
			if (nps > maxNPS) {
				maxNPS = nps;
			}
			if (nps > oldNPS)
				npsIncreased = true;

			if (nps < oldNPS)
				npsDecreased = true;

			if (oppNPS > oldOppNPS)
				oppNpsIncreased = true;

			if (oppNPS < oldOppNPS)
				oppNpsDecreased = true;

			if (npsIncreased || npsDecreased || oppNpsIncreased || oppNpsDecreased) {
				if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 8 && judgementCounter != null) updateRatingCounter();
				if (scoreTxtUpdateFrame <= 8 && scoreTxt != null) updateScore();
				if (npsIncreased) npsIncreased = false;
				if (npsDecreased) npsDecreased = false;
				if (oppNpsIncreased) oppNpsIncreased = false;
				if (oppNpsDecreased) oppNpsDecreased = false;
				oldNPS = nps;
				oldOppNPS = oppNPS;
			}
		}

		if (ClientPrefs.data.showcaseMode && !ClientPrefs.data.charsAndBG) {
		hitTxt.text = 'Notes Hit: ' + formatNumber(totalNotesPlayed) + ' / ' + formatNumber(totalNotes)
		+ '\nNPS: ' + formatNumber(nps) + '/' + formatNumber(maxNPS)
		+ '\nOpponent Notes Hit: ' + formatNumber(enemyHits) + ' / ' + formatNumber(opponentNoteTotal)
		+ '\nOpponent NPS: ' + formatNumber(oppNPS) + '/' + formatNumber(maxOppNPS)
		+ '\nTotal Note Hits: ' + formatNumber(Math.abs(totalNotesPlayed + enemyHits))
		+ '\nVideo Speedup: ' + Math.abs(playbackRate / playbackRate / playbackRate) + 'x';
		}

		if (judgeCountUpdateFrame > 0) judgeCountUpdateFrame = 0;
		if (scoreTxtUpdateFrame > 0) scoreTxtUpdateFrame = 0;
		if (iconBopsThisFrame > 0) iconBopsThisFrame = 0;
		if (popUpsFrame > 0) popUpsFrame = 0;
		if (missRecalcsPerFrame > 0) missRecalcsPerFrame = 0;
		strumsHit = [false, false, false, false, false, false, false, false];
		for (i in 0...splashesPerFrame.length)
			if (splashesPerFrame[i] > 0) splashesPerFrame[i] = 0;

		if (hitImagesFrame > 0) hitImagesFrame = 0;

		if (lerpingScore) updateScore();
		if (shownScore != songScore && ClientPrefs.data.scoreStyle == 'JS Engine' && Math.abs(shownScore - songScore) >= 10) {
			shownScore = FlxMath.lerp(shownScore, songScore, 0.2 / ((!ffmpegMode ? ClientPrefs.data.framerate : targetFPS) / 60));
				lerpingScore = true; // Indicate that lerping is in progress
		} else {
			shownScore = songScore;
			lerpingScore = false;
			updateScore(); //Update scoreTxt one last time
		}

			if (!opponentChart) displayedHealth = ClientPrefs.data.smoothHealth ? FlxMath.lerp(displayedHealth, health, 0.1 / ((!ffmpegMode ? ClientPrefs.data.framerate : targetFPS) / 60)) : health;
			else displayedHealth = ClientPrefs.data.smoothHealth ? FlxMath.lerp(displayedHealth, maxHealth - health, 0.1 / ((!ffmpegMode ? ClientPrefs.data.framerate : targetFPS) / 60)) : maxHealth - health;
		
		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible && ClientPrefs.data.botTxtFade) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180 * playbackRate);
		}
		if((botplayTxt != null && cpuControlled && !ClientPrefs.data.showcaseMode && !botplayUsed) && ClientPrefs.data.randomBotplayText) {
			botplayUsed = true;
			if(botplayTxt.text == "this text is gonna kick you out of botplay in 10 seconds" || botplayTxt.text == "Your Botplay Free Trial will end in 10 seconds.")
				{
					new FlxTimer().start(10, function(tmr:FlxTimer)
						{
							cpuControlled = false;
							botplayUsed = false;
							botplayTxt.visible = false;
						});
				}
			if(botplayTxt.text == "You use botplay? In 10 seconds I knock your botplay thing and text so you'll never use it >:)")
				{
					new FlxTimer().start(10, function(tmr:FlxTimer)
						{
							cpuControlled = false;
							botplayUsed = false;
							FlxG.sound.play(Paths.sound('pipe'), 10);
							botplayTxt.visible = false;
							PauseSubState.botplayLockout = true;
						});
				}
			if(botplayTxt.text == "you have 10 seconds to run.")
				{
					new FlxTimer().start(10, function(tmr:FlxTimer)
						{
							#if VIDEOS_ALLOWED
							startVideo('scary', function() Sys.exit(0));
							#else
							throw 'You should RUN, any minute now.'; // thought this'd be cooler
							// Sys.exit(0);
							#end
						});
				}
			if(botplayTxt.text == "you're about to die in 30 seconds")
				{
					new FlxTimer().start(30, function(tmr:FlxTimer)
						{
							health = 0;
						});
				}
			if(botplayTxt.text == "3 minutes until Boyfriend steals your liver.")
				{
				var title:String = 'Incoming Alert from Boyfriend';
				var message:String = '3 minutes until Boyfriend steals your liver!';
				FlxG.sound.music.pause();
				pauseVocals();

				lime.app.Application.current.window.alert(message, title);
				FlxG.sound.music.resume();
				unpauseVocals();
					new FlxTimer().start(180, function(tmr:FlxTimer)
						{
							Sys.exit(0);
						});
				}
			if(botplayTxt.text == "[DATA EXPUNGED]")
				{
				new FlxTimer().start(5, function(tmr:FlxTimer)
					{
						PlatformUtil.sendWindowsNotification('[DATA EXPUNGED]', 'Nice try...');
						for (i in 0...5) trace('[DATA EXPUNGED]'); // he is taking over >:)
						Sys.exit(0);
					});
				}
			
			if(botplayTxt.text == "3 minutes until I steal your liver.")
				{
				var title:String = 'Incoming Alert from Jordan';
				var message:String = '3 minutes until I steal your liver.';
				FlxG.sound.music.pause();
				pauseVocals();

				lime.app.Application.current.window.alert(message, title);
				unpauseVocals();
					new FlxTimer().start(180, function(tmr:FlxTimer)
						{
							Sys.exit(0);
						});
				}
		}

		if (controls.PAUSE && startedCountdown && canPause && !heyStopTrying)
		{
			final ret:Dynamic = callOnScripts('onPause', [], false);
			if(ret != LuaUtils.Function_Stop)
				openPauseMenu();
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			if (SONG.event7 != null && SONG.event7 != "---" && SONG.event7 != '' && SONG.event7 != 'None')
			switch(SONG.event7)
			{
				case "---" | null | '' | 'None':
					if (!ClientPrefs.data.antiCheatEnable)
					{
						openChartEditor();
					}
					else
					{
						PlayState.SONG = Song.loadFromJson('Anti-cheat-song', 'Anti-cheat-song');
						LoadingState.loadAndSwitchState(PlayState.new);
					}
				case "Game Over":
					health = 0;
				case "Go to Song":
					PlayState.SONG = Song.loadFromJson(SONG.event7Value + (Difficulty.difficultyString() == 'NORMAL' ? '' : '-' + Difficulty.list[storyDifficulty]), SONG.event7Value);
					LoadingState.loadAndSwitchState(PlayState.new);
				case "Close Game":
					openfl.system.System.exit(0);
				case "Play Video":
					updateTime = false;
					FlxG.sound.music.volume = 0;
					vocals.volume = opponentVocals.volume = gfVocals.volume = 0;
					vocals.stop();
					opponentVocals.stop();
					gfVocals.stop();
					FlxG.sound.music.stop();
					KillNotes();
					heyStopTrying = true;

					var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					add(bg);
					bg.cameras = [camHUD];
					startVideo(SONG.event7Value, function() Sys.exit(0));
			}
			else if (!ClientPrefs.data.antiCheatEnable)
			{
				openChartEditor();
			}
			else
			{
				PlayState.SONG = Song.loadFromJson('Anti-cheat-song', 'Anti-cheat-song');
				LoadingState.loadAndSwitchState(PlayState.new);
			}
		}


		if (iconP1.animation.numFrames == 3) {
			if (healthBar.percent < 20)
				iconP1.animation.curAnim.curFrame = 1;
			else if (healthBar.percent > 80)
				iconP1.animation.curAnim.curFrame = 2;
			else
				iconP1.animation.curAnim.curFrame = 0;
		}
		else {
			if (healthBar.percent < 20)
				iconP1.animation.curAnim.curFrame = 1;
			else
				iconP1.animation.curAnim.curFrame = 0;
		}
		if (iconP2.animation.numFrames == 3) {
			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else if (healthBar.percent < 20)
				iconP2.animation.curAnim.curFrame = 2;
			else
				iconP2.animation.curAnim.curFrame = 0;
		} else {
			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else
				iconP2.animation.curAnim.curFrame = 0;
		}

		if (health > maxHealth)
			health = maxHealth;

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			if(FlxG.sound.music != null) FlxG.sound.music.stop();
			if (vocals != null) vocals.stop();
			if (opponentVocals != null) opponentVocals.stop();
			if (gfVocals != null) gfVocals.stop();
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
			FlxG.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			for (i in [vocals, opponentVocals, gfVocals])
				if (i != null && i.time >= i.length && i.playing) i.pause();
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
				if(updateTime && FlxG.game.ticks % (Std.int(ClientPrefs.data.framerate / 60) > 0 ? Std.int(ClientPrefs.data.framerate / 60) : 1) == 0) {
					if (timeBar.visible) {
						songPercent = Conductor.songPosition / songLength;
					}
					if (Conductor.songPosition - lastUpdateTime >= 1.0)
					{
						lastUpdateTime = Conductor.songPosition;
						if (ClientPrefs.data.timeBarType != 'Song Name')
						{
							timeTxt.text = ClientPrefs.data.timeBarType.contains('Time Left') ? CoolUtil.getSongDuration(Conductor.songPosition, songLength) : CoolUtil.formatTime(Conductor.songPosition)
							+ (ClientPrefs.data.timeBarType.contains('Modern Time') ? ' / ' + CoolUtil.formatTime(songLength) : '');

							if (ClientPrefs.data.timeBarType == 'Song Name + Time')
								timeTxt.text = SONG.song + ' (' + CoolUtil.formatTime(Conductor.songPosition) + ' / ' + CoolUtil.formatTime(songLength) + ')';
						}

						if(ClientPrefs.data.timebarShowSpeed)
						{
							playbackRateDecimal = FlxMath.roundDecimal(playbackRate, 2);
							if (ClientPrefs.data.timeBarType != 'Song Name')
								timeTxt.text += ' (' + (!ffmpegMode ? playbackRateDecimal + 'x)' : 'Rendering)');
							else timeTxt.text = SONG.song + ' (' + (!ffmpegMode ? playbackRateDecimal + 'x)' : 'Rendering)');
						}
						if (cpuControlled && ClientPrefs.data.timeBarType != 'Song Name' && ClientPrefs.data.botWatermark) timeTxt.text += ' (Bot)';
						if(ClientPrefs.data.timebarShowSpeed && cpuControlled && ClientPrefs.data.timeBarType == 'Song Name' && ClientPrefs.data.botWatermark) timeTxt.text = SONG.song + ' (' + (!ffmpegMode ? FlxMath.roundDecimal(playbackRate, 2) + 'x)' : 'Rendering)') + ' (Bot)';
					}
				}
				if(ffmpegMode) {
					if(!endingSong && Conductor.songPosition >= FlxG.sound.music.length - 20) {
						finishSong();
						endSong();
					}
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong && !heyStopTrying)
		{
			health = 0;
			trace("RESET = True");
		}
		if (health <= 0) doDeathCheck();

		skippedCount = 0;

		if (unspawnNotes.length > 0 && unspawnNotes[0] != null)
		{
			NOTE_SPAWN_TIME = (ClientPrefs.data.dynamicSpawnTime ? (1600 / songSpeed) : 1600 * ClientPrefs.data.noteSpawnTime);
			if (notesAddedCount != 0) notesAddedCount = 0;

			if (notesAddedCount > unspawnNotes.length)
				notesAddedCount -= (notesAddedCount - unspawnNotes.length);

			if (!unspawnNotes[notesAddedCount].wasHit)
			{
				while (unspawnNotes[notesAddedCount] != null && unspawnNotes[notesAddedCount].strumTime <= Conductor.songPosition) {
					unspawnNotes[notesAddedCount].wasHit = true;
					unspawnNotes[notesAddedCount].mustPress ? goodNoteHit(null, unspawnNotes[notesAddedCount]): opponentNoteHit(null, unspawnNotes[notesAddedCount]);
					notesAddedCount++;
					skippedCount++;
					if (skippedCount > maxSkipped) maxSkipped = skippedCount;
				}
			}
			if (ClientPrefs.data.showNotes || !ClientPrefs.data.showNotes && !cpuControlled)
			{
				while (unspawnNotes[notesAddedCount] != null && unspawnNotes[notesAddedCount].strumTime - Conductor.songPosition < (NOTE_SPAWN_TIME / unspawnNotes[notesAddedCount].multSpeed)) {
					if (ClientPrefs.data.fastNoteSpawn) (unspawnNotes[notesAddedCount].isSustainNote ? sustainNotes : notes).spawnNote(unspawnNotes[notesAddedCount]);
					else
					{
						spawnedNote = (unspawnNotes[notesAddedCount].isSustainNote ? sustainNotes : notes).recycle(Note);
						spawnedNote.setupNoteData(unspawnNotes[notesAddedCount]);
					}

					if (!ClientPrefs.data.noSpawnFunc) callOnScripts('onSpawnNote', [(!unspawnNotes[notesAddedCount].isSustainNote ? notes.members.indexOf(notes.members[0]) : sustainNotes.members.indexOf(sustainNotes.members[0])), unspawnNotes[notesAddedCount].noteData, unspawnNotes[notesAddedCount].noteType, unspawnNotes[notesAddedCount].isSustainNote]);
					notesAddedCount++;
				}
			}
			if (notesAddedCount > 0)
				unspawnNotes.splice(0, notesAddedCount);
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) {
					keyShit();
				}
				else if (ClientPrefs.data.charsAndBG) {
					playerDance();
				}
				amountOfRenderedNotes = 0;
				for (group in [notes, sustainNotes])
				{
					group.forEach(function(daNote)
					{
						updateNote(daNote);
					});
					group.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				}
			}

			while(eventNotes.length > 0 && Conductor.songPosition > eventNotes[0].strumTime) {

				var value1:String = '';
				if(eventNotes[0].value1 != null)
					value1 = eventNotes[0].value1;
	
				var value2:String = '';
				if(eventNotes[0].value2 != null)
					value2 = eventNotes[0].value2;
	
				triggerEvent(eventNotes[0].event, value1, value2, eventNotes[0].strumTime);
				eventNotes.shift();
			}
		}

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
			if(FlxG.keys.justPressed.THREE) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition - 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if ((trollingMode || SONG.song.toLowerCase() == 'anti-cheat-song') && startedCountdown && canPause && !endingSong) {
			if (FlxG.sound.music.length - Conductor.songPosition <= endingTimeLimit) {
				KillNotes(); //kill any existing notes
				FlxG.sound.music.time = 0;
				if (SONG.needsVoices) setVocalsTime(0);
				lastUpdateTime = 0.0;
				Conductor.songPosition = 0;

				if (SONG.song.toLowerCase() != 'anti-cheat-song')
				{
					unspawnNotes = unspawnNotesCopy.copy();
					eventNotes = eventNotesCopy.copy();
						var noteIndex:Int = 0;
						while (unspawnNotes.length > 0 && unspawnNotes[noteIndex] != null)
						{
							unspawnNotes[noteIndex].wasHit = false;
							noteIndex++;
						}
				}
				if (FlxG.sound.music.time < 0 || Conductor.songPosition < 0)
				{
					FlxG.sound.music.time = 0;
					resyncVocals();
				}
				SONG.song.toLowerCase() != 'anti-cheat-song' ? loopSongLol() : loopCallback(0);
			}
		}

		if (ClientPrefs.data.showRendered) 
		{
			if (!ffmpegMode) renderedTxt.text = 'Rendered/Skipped: ${formatNumber(amountOfRenderedNotes)}/${formatNumber(skippedCount)}/${formatNumber(notes.members.length + sustainNotes.members.length)}/${formatNumber(maxSkipped)}';
			else renderedTxt.text = 'Rendered Notes: ${formatNumber(amountOfRenderedNotes)}/${formatNumber(maxRenderedNotes)}/${formatNumber(notes.members.length + sustainNotes.members.length)}';
		}

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);

		if (shaderUpdates.length > 0)
			for (i in shaderUpdates){
				i(elapsed);
			}

		if (ffmpegMode)
		{
			if (!ClientPrefs.data.oldFFmpegMode) pipeFrame();
			else
			{
				var filename = CoolUtil.zeroFill(frameCaptured, 7);
				try {
					capture.save(Paths.formatToSongPath(SONG.song) + #if linux '/' #else '\\' #end, filename);
				}
				catch (e) //If it catches an error, try capturing the frame again. If it still catches an error, skip the frame
				{
					try {
						capture.save(Paths.formatToSongPath(SONG.song) + #if linux '/' #else '\\' #end, filename);
					}
					catch (e) {}
				}
			}
			if (ClientPrefs.data.renderGCRate > 0 && (frameCaptured / targetFPS) % ClientPrefs.data.renderGCRate == 0) openfl.system.System.gc();
			frameCaptured++;
		}

		if(botplayTxt != null && botplayTxt.visible) {
			switch (ffmpegInfo)
			{
				case 'Frame Time': botplayTxt.text = CoolUtil.floatToStringPrecision(haxe.Timer.stamp() - takenTime, 3) + 's';
				case 'Time Remaining':
					var timeETA:String = CoolUtil.formatTime((FlxG.sound.music.length - Conductor.songPosition) * (60 / Main.fpsVar.currentFPS), 2);
					if (ClientPrefs.data.showcaseMode) botplayTxt.text += '\nTime Remaining: ' + timeETA;
					else botplayTxt.text = ogBotTxt + '\nTime Remaining: ' + timeETA;
				case 'Rendering Time':
					totalRenderTime = haxe.Timer.stamp() - startingTime;
					if (ClientPrefs.data.showcaseMode) botplayTxt.text += '\nTime Taken: ' + CoolUtil.formatTime(totalRenderTime * 1000, 2);
					else botplayTxt.text = ogBotTxt + '\nTime Taken: ' + CoolUtil.formatTime(totalRenderTime * 1000, 2);

				default: 
			}
		}

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);

		takenTime = haxe.Timer.stamp();
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		if (ClientPrefs.data.iconBounceType == 'Old Psych') {
			iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))),
				Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
			iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))),
				Std.int(FlxMath.lerp(iconP2.frameHeight, iconP2.height, CoolUtil.boundTo(1 - (elapsed * 30 * playbackRate), 0, 1))));
		}
		if (ClientPrefs.data.iconBounceType == 'Strident Crisis') {
			iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, 0.50 / playbackRate)),
				Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, 0.50 / playbackRate)));
			iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, 0.50 / playbackRate)),
				Std.int(FlxMath.lerp(iconP2.frameHeight, iconP1.height, 0.50 / playbackRate)));
			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
		if (ClientPrefs.data.iconBounceType == 'Dave and Bambi') {
			iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.frameWidth, iconP1.width, 0.8 / playbackRate)),
				Std.int(FlxMath.lerp(iconP1.frameHeight, iconP1.height, 0.8 / playbackRate)));
			iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.frameWidth, iconP2.width, 0.8 / playbackRate)),
				Std.int(FlxMath.lerp(iconP2.frameHeight, iconP2.height, 0.8 / playbackRate)));
		}
		if (ClientPrefs.data.iconBounceType == 'Plank Engine') {
			final funnyBeat = (Conductor.songPosition / 1000) * (Conductor.bpm / 60);

			iconP1.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
			iconP2.offset.y = Math.abs(Math.sin(funnyBeat * Math.PI))  * 16 - 4;
		}
		if (ClientPrefs.data.iconBounceType == 'New Psych' || ClientPrefs.data.iconBounceType == 'VS Steve') {
			final mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();

			final mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();
		}

		if (ClientPrefs.data.iconBounceType == 'Golden Apple') {
			iconP1.centerOffsets();
			iconP2.centerOffsets();
		}
		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}

	var percent:Float = 0;
	var center:Float = 0;
	public dynamic function updateIconsPosition()
	{
		if (ClientPrefs.data.smoothHealth)
		{
			percent = 1 - (ClientPrefs.data.smoothHPBug ? (displayedHealth / maxHealth) : (FlxMath.bound(displayedHealth, 0, maxHealth) / maxHealth));

			iconP1.x = 0 + healthBar.x + (healthBar.width * percent) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = 0 + healthBar.x + (healthBar.width * percent) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		else //mb forgot to include this
		{
			center = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01));
			iconP1.x = center + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = center - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			pauseVocals();
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		if(FlxG.sound.music != null) FlxG.sound.music.stop();
		chartingMode = true;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		FlxG.switchState(new states.editors.charting.JSChartingState());
	}

	public function loopCallback(startingPoint:Float = 0)
	{
		var notesToKill:Int = 0;
		var eventsToRemove:Int = 0;
		KillNotes(); //kill any existing notes
		FlxG.sound.music.time = startingPoint;
		if (SONG.needsVoices) setVocalsTime(startingPoint);
		lastUpdateTime = startingPoint;
		Conductor.songPosition = startingPoint;

		unspawnNotes = unspawnNotesCopy.copy();
		eventNotes = eventNotesCopy.copy();
		for (n in unspawnNotes)
			if (n.strumTime <= startingPoint)
				notesToKill++;

		for (e in eventNotes)
			if (e.strumTime <= startingPoint)
				eventsToRemove++;

		if (notesToKill > 0)
			unspawnNotes.splice(0, notesToKill);

		if (eventsToRemove > 0)
			eventNotes.splice(0, eventsToRemove);

		if (!ClientPrefs.data.showNotes)
		{
			var noteIndex:Int = 0;
			while (unspawnNotes.length > 0 && unspawnNotes[noteIndex] != null)
			{
				unspawnNotes[noteIndex].wasHit = false;
				noteIndex++;
			}
		}
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			if (ClientPrefs.data.instaRestart)
			{
				restartSong(true);
			}
			var ret:Dynamic = callOnScripts('onGameOver', [], false);
			stagesFunc(function(stage:BaseStage) stage.onGameOver());
			if(ret != LuaUtils.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				opponentVocals.stop();
				gfVocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				#if LUA_ALLOWED
				modchartTimers.clear();
				modchartTweens.clear();
				#end
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

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, ?strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		if(Math.isNaN(strumTime)) strumTime = -1;

		switch(eventName) {
			case 'Hey!':
				if (ClientPrefs.data.charsAndBG) {
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
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
				if (Conductor.bpm >= 500) singDurMult = value;

			case 'Enable Camera Bop':
				camZooming = true;

			case 'Disable Camera Bop':
				camZooming = false;
				FlxG.camera.zoom = defaultCamZoom;
				camHUD.zoom = 1;

			case 'Enable Bot Energy':
				if (!cpuControlled)
				{
					canUseBotEnergy = true;
					energyBar.visible = energyTxt.visible = true;
					var varsFadeIn:Array<Dynamic> = [energyBar, energyTxt];
					for (i in 0...varsFadeIn.length) FlxTween.tween(varsFadeIn[i], {alpha: 1}, 0.75, {ease: FlxEase.expoOut});
				}

			case 'Disable Bot Energy':
				if (!cpuControlled)
				{
					canUseBotEnergy = false;
					if (usingBotEnergy) usingBotEnergy = false;
					var varsFadeIn:Array<Dynamic> = [energyBar, energyTxt];
					for (i in 0...varsFadeIn.length)
						FlxTween.tween(varsFadeIn[i], {alpha: 0}, 0.75, {
							ease: FlxEase.expoOut, 
								onComplete: function(_){
									varsFadeIn[i].visible = false;
								}});
				}

			case 'Set Bot Energy Speeds':
				var drainSpeed:Float = Std.parseFloat(value1);
				if (Math.isNaN(drainSpeed)) drainSpeed = 1;
				energyDrainSpeed = drainSpeed;

				var refillSpeed:Float = Std.parseFloat(value2);
				if (Math.isNaN(refillSpeed)) refillSpeed = 1;
				energyRefillSpeed = refillSpeed;

			case 'Credits Popup':
			{
				var string1:String = value1;
				if (value1.length < 1) string1 = SONG.song;
				var string2:String = value2;
				if (value2.length < 1) string2 = SONG.songCredit;
				var creditsPopup:CreditsPopUp = new CreditsPopUp(FlxG.width, 200, string1, string2);
				creditsPopup.camera = camHUD;
				creditsPopup.scrollFactor.set();
				creditsPopup.x = creditsPopup.width * -1;
				add(creditsPopup);

				FlxTween.tween(creditsPopup, {x: 0}, 0.5, {ease: FlxEase.backOut, onComplete: function(tweeen:FlxTween)
				{
					FlxTween.tween(creditsPopup, {x: creditsPopup.width * -1} , 1, {ease: FlxEase.backIn, onComplete: function(tween:FlxTween)
					{
						creditsPopup.destroy();
							}, startDelay: 3});
						}});
			}
			case 'Camera Bopping':
				var _interval:Int = Std.parseInt(value1);
				if (Math.isNaN(_interval))
					_interval = 4;
				var _intensity:Float = Std.parseFloat(value2);
				if (Math.isNaN(_intensity))
					_intensity = 1;

				camBopIntensity = _intensity;
				camBopInterval = _interval;
				if (_interval != 4) usingBopIntervalEvent = true;
					else usingBopIntervalEvent = false;

			case 'Camera Twist':
				camTwist = true;
				var _intensity:Float = Std.parseFloat(value1);
				if (Math.isNaN(_intensity))
					_intensity = 0;
				var _intensity2:Float = Std.parseFloat(value2);
				if (Math.isNaN(_intensity2))
					_intensity2 = 0;
				camTwistIntensity = _intensity;
				camTwistIntensity2 = _intensity2;
				if (_intensity2 == 0)
				{
					camTwist = false;
					for (i in [camHUD, camGame])
					{
						FlxTween.cancelTweensOf(i);
						FlxTween.tween(i, {angle: 0, x: 0, y: 0}, 1, {ease: FlxEase.sineOut});
					}
				}
			case 'Change Note Multiplier':
				var noteMultiplier:Float = Std.parseFloat(value1);
				if (Math.isNaN(noteMultiplier))
					noteMultiplier = 1;

				if (value2 == "") {
					polyphonyOppo = noteMultiplier;
					polyphonyBF = noteMultiplier;
				} else {
					switch(value2) {
						case "1": polyphonyOppo = noteMultiplier;
						case "2": polyphonyBF = noteMultiplier;
					}
				}
				//trace(value2 + " | " + polyphonyBF + ", " + polyphonyOppo);

			case 'Set Camera Zoom':
				var newZoom:Float = Std.parseFloat(value1);
				if (Math.isNaN(newZoom))
					newZoom = ogCamZoom;
				defaultCamZoom = newZoom;

			case 'Fake Song Length':
				var fakelength:Float = Std.parseFloat(value1);
				fakelength *= (Math.isNaN(fakelength) ? 1 : 1000); //don't multiply if value1 is null, but do if value1 is not null
				var doTween:Bool = value2 == "true" ? true : false;
				if (Math.isNaN(fakelength))
					fakelength = FlxG.sound.music.length;
				if (doTween = true) FlxTween.tween(this, {songLength: fakelength}, 1, {ease: FlxEase.expoOut});
				if (doTween = true && (Math.isNaN(fakelength))) FlxTween.tween(this, {songLength: FlxG.sound.music.length}, 1, {ease: FlxEase.expoOut});
				songLength = fakelength;

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
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

				if (char != null && ClientPrefs.data.charsAndBG)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			// Evil
			case 'Windows Notification':
				{
					PlatformUtil.sendWindowsNotification(value1, value2);

					#if linux
					addTextToDebug('Windows Notifications are not currently supported on Linux!', FlxColor.RED);
					return;
					#else
					trace('Windows Notifications are not currently supported on this platform!');
					return;
					#end
				}

			case 'Camera Follow Pos':
				if (camFollow != null)
				{
					isCameraOnForcedPos = false;
					if (flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if (flValue1 == null)
							flValue1 = 0;
						if (flValue2 == null)
							flValue2 = 0;
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
			if (ClientPrefs.data.charsAndBG)
			{
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
							if (!value2.startsWith('bf') && !value2.startsWith('boyfriend')) iconP1.changeIcon(boyfriend.healthIcon);
							else {
								if (ClientPrefs.data.bfIconStyle == 'VS Nonsense V2') iconP1.changeIcon('bfnonsense');
								if (ClientPrefs.data.bfIconStyle == 'Doki Doki+') iconP1.changeIcon('bfdoki');
								if (ClientPrefs.data.bfIconStyle == 'Leather Engine') iconP1.changeIcon('bfleather');
								if (ClientPrefs.data.bfIconStyle == "Mic'd Up") iconP1.changeIcon('bfmup');
								if (ClientPrefs.data.bfIconStyle == "FPS Plus") iconP1.changeIcon('bffps');
								if (ClientPrefs.data.bfIconStyle == "OS 'Engine'") iconP1.changeIcon('bfos');
							}
							if (boyfriend.noteskin != null) bfNoteskin = boyfriend.noteskin;
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var dadAnim:String = (dad.animation.curAnim != null && dad.animation.curAnim.name.startsWith('sing') ? dad.animation.curAnim.name : '');
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
							if (ClientPrefs.data.botTxtStyle == 'VS Impostor') {
								if (botplayTxt != null) FlxTween.color(botplayTxt, 1, botplayTxt.color, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
								
								if (scoreTxt != null && !ClientPrefs.data.hideHud) FlxTween.color(scoreTxt, 1, scoreTxt.color, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
							}
							if (ClientPrefs.data.scoreStyle == 'JS Engine' && !ClientPrefs.data.hideHud)
								if (scoreTxt != null) FlxTween.color(scoreTxt, 1, scoreTxt.color, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));

							if (dadAnim != '') dad.playAnim(dadAnim, true);
						}
						if (dad.noteskin != null) dadNoteskin = dad.noteskin;
						setOnScripts('dadName', dad.curCharacter);

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
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				shouldDrainHealth = (opponentDrain || (opponentChart ? boyfriend.healthDrain : dad.healthDrain));
				if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainAmount)) healthDrainAmount = opponentChart ? boyfriend.drainAmount : dad.drainAmount;
				if (!opponentDrain && !Math.isNaN((opponentChart ? boyfriend : dad).drainFloor)) healthDrainFloor = opponentChart ? boyfriend.drainFloor : dad.drainFloor;
				if (!ClientPrefs.data.ogHPColor) reloadHealthBarColors(dad.healthColorArray, boyfriend.healthColorArray);
				if (ClientPrefs.data.showNotes)
				{
					for (i in strumLineNotes.members)
						if ((i.player == 0 ? dadNoteskin : bfNoteskin) != null) 
						{
							i.updateNoteSkin(i.player == 0 ? dadNoteskin : bfNoteskin);
							i.useRGBShader = (i.player == 0 ? dadNoteskin : bfNoteskin).length < 1;
						}
				}
				if (ClientPrefs.data.noteColorStyle == 'Char-Based')
				{
					for (group in [notes, sustainNotes])
						for (note in group){
							if (note == null)
								continue;
							if (ClientPrefs.data.enableColorShader) note.updateRGBColors();
						}
				}
			}

			case 'Rainbow Eyesore':
				#if linux
				#if LUA_ALLOWED
				addTextToDebug('Rainbow shader does not work on Linux right now!', FlxColor.RED);
				#else
				trace('Rainbow shader does not work on Linux right now!');
				#end
				return;
				#end
				if(ClientPrefs.data.flashing && ClientPrefs.data.shaders) {
					var timeRainbow:Int = Std.parseInt(value1);
					var speedRainbow:Float = Std.parseFloat(value2);
					disableTheTripper = false;
					disableTheTripperAt = timeRainbow;
					FlxG.camera.filters = [new ShaderFilter(screenshader.shader)];
					screenshader.waveAmplitude = 1;
					screenshader.waveFrequency = 2;
					screenshader.waveSpeed = speedRainbow * playbackRate;
					screenshader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-100000, 100000);
					screenshader.shader.uampmul.value[0] = 1;
					screenshader.Enabled = true;
				}
			case 'Popup':
				var title:String = (value1);
				var message:String = (value2);
				FlxG.sound.music.pause();
				pauseVocals();

				lime.app.Application.current.window.alert(message, title);
				FlxG.sound.music.resume();
				unpauseVocals();
			case 'Popup (No Pause)':
				var title:String = (value1);
				var message:String = (value2);

				lime.app.Application.current.window.alert(message, title);

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

			case 'Change Song Name':
				if(ClientPrefs.data.timeBarType == 'Song Name' && !ClientPrefs.data.timebarShowSpeed)
				{
					if (value1.length > 1)
						timeTxt.text = value1;
					else timeTxt.text = curSong;
				}

			case 'Set Property':
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false')
						trueValue = trueValue == 'true';
					else if (flValue2 != null)
						trueValue = flValue2;
					else
						trueValue = value2;

					var split:Array<String> = value1.split('.');
					if (split.length > 1)
					{
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], trueValue);
					}
					else
					{
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch (e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if (len <= 0)
						len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}
		}
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	public function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			moveCameraToGirlfriend();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnScripts('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnScripts('onMoveCamera', ['boyfriend']);
		}
	}

	public function moveCameraToGirlfriend()
	{
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
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
		if (!trollingMode && SONG.song.toLowerCase() != 'anti-cheat-song') {
			updateTime = false;
			FlxG.sound.music.volume = 0;
			vocals.volume = opponentVocals.volume = gfVocals.volume = 0;
			FlxG.mouse.unload(); // just in case you changed it beforehand
			pauseVocals();
			if(!ffmpegMode){
				if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
					endCallback();
				} else {
					finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
						endCallback();
					});
				}
			} else endCallback();
		}
	}

	public function loopSongLol()
	{
		stepsToDo = /* You need stepsToDo to change, otherwise the sections break. */ curStep = curBeat = curSection = 0; // Wow.
		oldStep  = -1;

		// And now it's time for the actual troll mode stuff
		var TROLL_MAX_SPEED:Float = 2048; // Default is medium max speed
		switch(ClientPrefs.data.trollMaxSpeed) {
			case 'Lowest':
				TROLL_MAX_SPEED = 256;
			case 'Lower':
				TROLL_MAX_SPEED = 512;
			case 'Low':
				TROLL_MAX_SPEED = 1024;
			case 'Medium':
				TROLL_MAX_SPEED = 2048;
			case 'High':
				TROLL_MAX_SPEED = 5120;
			case 'Highest':
				TROLL_MAX_SPEED = 10000;
			default:
				TROLL_MAX_SPEED = 1.79e+308; //no limit (until you eventually suffer the fate of crashing :trollface:)
		}

		if (ClientPrefs.data.voiidTrollMode) {
			playbackRate *= 1.05;
		} else {
			playbackRate += calculateTrollModeStuff(playbackRate);
		}

		if (playbackRate >= TROLL_MAX_SPEED && ClientPrefs.data.trollMaxSpeed != 'Disabled') { // Limit playback rate to the troll mode max speed
			playbackRate = TROLL_MAX_SPEED;
		}
	}

	function calculateTrollModeStuff(pb:Float):Float {
		// Peak Code 2
		if (pb >= 2 && pb < 4) return 0.1;
		if (pb >= 4 && pb < 8) return 0.2;
		if (pb >= 8 && pb < 16) return 0.4;
		if (pb >= 16 && pb < 32) return 0.8;
		if (pb >= 32 && pb < 64) return 1.6;
		if (pb >= 64 && pb < 128) return 3.2;
		if (pb >= 128 && pb < 256) return 6.4;
		if (pb >= 256 && pb < 512) return 12.8;
		if (pb >= 512 && pb < 1024) return 25.6;
		return 0.05;
	}

	function calculateResetTime():Float {
		if (ClientPrefs.data.strumLitStyle == 'BPM Based') return (Conductor.stepCrochet * 1.5 / 1000) / playbackRate;
		return 0.15 / playbackRate;
	}

	public var transitioning = false;
	public function endSong():Void
	{
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		startedCountdown = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', [], true);
		if(ret != LuaUtils.Function_Stop && !transitioning) {
			if (!cpuControlled && !playerIsCheating && ClientPrefs.data.safeFrames <= 10)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, Std.int(songScore), storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				if (!ffmpegMode) openChartEditor();
				else 
				{
					endingTime = haxe.Timer.stamp();
					FlxG.switchState(new substates.RenderingDoneSubState(endingTime - startingTime));
					chartingMode = true;
				}
				return;
			}

			if (isStoryMode && !wasOriginallyFreeplay)
			{
				campaignScore += songScore;
				campaignMisses += Std.int(songMisses);

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					gameplayArea = "Story";
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.data.daMenuMusic));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					FlxG.switchState(new StoryMenuState());

					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), Std.int(campaignScore), storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					gameplayArea = "Story";
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					
					FlxG.sound.music.stop();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				gameplayArea = "Freeplay";
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				if (!ffmpegMode) FlxG.switchState(new FreeplayState());
				else 
				{
					endingTime = haxe.Timer.stamp();
					FlxG.switchState(new substates.RenderingDoneSubState(endingTime - startingTime));
				}
				FlxG.sound.playMusic(Paths.music('freakyMenu-' + ClientPrefs.data.daMenuMusic));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	public function KillNotes() {
		for (group in [notes, sustainNotes])
		while (group.length > 0) {
			group.remove(group.members[0], true);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public function restartSong(noTrans:Bool = true)
	{
		if (process != null) stopRender();
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		vocals.volume = opponentVocals.volume = gfVocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			FlxG.resetState();
		}
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var totalNotes:Float = 0;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var popUpGroup:FlxTypedSpriteGroup<Popup>;

	private function cachePopUpScore()
	{
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		var normalRating:String = 'ratings/' + ClientPrefs.data.ratingType.toLowerCase().replace(' ', '-').trim() + '/';

		pixelShitPart1 += normalRating;

		Paths.image(pixelShitPart1 + "perfect" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "miss" + pixelShitPart2);

		for (i in 0...10) Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		if (Paths.fileExists('images/${normalRating}' + 'hitStrings.txt', TEXT))
			hitStrings = Paths.mergeAllTextsNamed('images/${normalRating}' + 'hitStrings.txt', null, false);

		if (Paths.fileExists('images/${normalRating}' + 'fcStrings.txt', TEXT))
			fcStrings = Paths.mergeAllTextsNamed('images/${normalRating}' + 'fcStrings.txt', null, false);

		if (Paths.fileExists('images/${normalRating}' + 'judgeCountStrings.txt', TEXT))
			judgeCountStrings = Paths.mergeAllTextsNamed('images/${normalRating}' + 'judgeCountStrings.txt', null, false);
	}

	var rating:Popup = null;
	var numScore:Popup = null;
	var daRating:Rating = null;
	var noteDiff = 0.0;

	function judgeNote(note:Note = null, ?miss:Bool = false)
	{
		if (note == null) return;
		if (daRating == null) daRating = ratingsData[0]; //because it likes being stupid
		if (!cpuControlled)
		{
			noteDiff = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset) / playbackRate;
			final wife:Float = backend.EtternaFunctions.wife3(noteDiff, Conductor.timeScale);

			daRating = Conductor.judgeNote(note, noteDiff, cpuControlled, miss);
			if (sickOnly && (noteDiff > ClientPrefs.data.sickWindow || noteDiff < -ClientPrefs.data.sickWindow))
				doDeathCheck(true);

			if (miss) daRating.image = 'miss';
				else if (ratingsData[0].image == 'miss') ratingsData[0].image = !ClientPrefs.data.noPerfectJudge ? 'perfect' : 'sick';

			if (!miss)
			{
				if (!ClientPrefs.data.complexAccuracy) totalNotesHit += daRating.ratingMod;
				if (ClientPrefs.data.complexAccuracy) totalNotesHit += wife;
				note.ratingMod = daRating.ratingMod;
				if(!note.ratingDisabled) daRating.increase();
			}
			note.rating = daRating.name;
		}

		if(daRating.noteSplash && !note.noteSplashDisabled && !miss && splashesPerFrame[1] <= 4)
			spawnNoteSplashOnNote(false, note);

		if(!practiceMode && !miss) {
			songScore += daRating.score * (opponentChart ? polyphonyOppo : polyphonyBF);
			if(!cpuControlled && !note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				if(!cpuControlled || cpuControlled) {
					RecalculateRating(false);
				}
			}
		}

		if (daRating.name == 'shit' && ClientPrefs.data.shitGivesMiss && ClientPrefs.data.ratingIntensity == 'Normal') noteMiss(note);
		if (noteDiff > ClientPrefs.data.goodWindow && ClientPrefs.data.shitGivesMiss && ClientPrefs.data.ratingIntensity == 'Harsh') noteMiss(note);
		if (noteDiff > ClientPrefs.data.sickWindow && ClientPrefs.data.shitGivesMiss && ClientPrefs.data.ratingIntensity == 'Very Harsh')noteMiss(note);
	}

	var separatedScore:Array<Dynamic> = [];
	private function popUpScore(note:Note = null, ?miss:Bool = false):Void
	{
		popUpsFrame += 1;

		if(ClientPrefs.data.scoreZoom && scoreTxt != null && !cpuControlled && !miss)
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

		if (!miss && !ffmpegMode) (opponentChart ? opponentVocals : vocals).volume = 1;
		
		judgeNote(note, miss);

		if (popUpsFrame <= 3)
		{
			if (!ClientPrefs.data.comboStacking) while (popUpGroup.members.length > 0)
			{
				var spr = popUpGroup.members[0];
				if (spr == null) continue;

				FlxTween.cancelTweensOf(spr);
				popUpGroup.remove(spr, true);
				spr.kill();
			}

			if (showRating && ClientPrefs.data.ratingPopups && !ClientPrefs.data.simplePopups) {
				rating = popUpGroup.recycle(Popup);
				rating.setupRating(pixelShitPart1 + daRating.image + pixelShitPart2);
				if (!miss && ClientPrefs.data.colorRatingHit)
				{
					switch (daRating.name) //This is so stupid, but it works
					{
						case 'sick':  rating.color = FlxColor.CYAN;
						case 'good': rating.color = FlxColor.LIME;
						case 'bad': rating.color = FlxColor.ORANGE;
						case 'shit': rating.color = FlxColor.RED;
						default: rating.color = FlxColor.WHITE;
					}
				}
				rating.alphaTween();
				popUpGroup.insert(0, rating);
			}

			if (showComboNum && ClientPrefs.data.comboPopups && !ClientPrefs.data.simplePopups)
			{
				var tempCombo:Float = (combo > 0 ? combo : -combo);
				var tempComboAlt:Float = tempCombo;
				
				separatedScore = [];
				while(tempCombo >= 10)
				{
					separatedScore.unshift(Math.ffloor(tempCombo / 10) % 10);
					tempCombo = Math.ffloor(tempCombo / 10);
				}
				separatedScore.push(tempComboAlt % 10);

				if (combo < 0) separatedScore.unshift("neg");

				for (daLoop=>i in separatedScore)
				{
					numScore = popUpGroup.recycle(Popup);
					numScore.setupNumber(pixelShitPart1 + 'num' + i + pixelShitPart2, daLoop, tempComboAlt);
					if (miss) numScore.color = FlxColor.fromRGB(204, 66, 66);
					numScore.alphaTween(true);

					if (ClientPrefs.data.colorRatingHit && !miss)
					{
						switch (daRating.name) //This is so stupid, but it works
						{
							case 'sick':  numScore.color = FlxColor.CYAN;
							case 'good': numScore.color = FlxColor.LIME;
							case 'bad': numScore.color = FlxColor.ORANGE;
							case 'shit': numScore.color = FlxColor.RED;
							default: numScore.color = FlxColor.WHITE;
						}
					}
					popUpGroup.insert(0, numScore);
				}
			}

			if (ClientPrefs.data.showMS && !ClientPrefs.data.hideHud) {
				FlxTween.cancelTweensOf(msTxt);
				msTxt.cameras = [camHUD];
				msTxt.visible = true;
				msTxt.screenCenter();
				msTxt.x = (FlxG.width * 0.35) + 80;
				msTxt.alpha = 1;
				msTxt.text = FlxMath.roundDecimal(-noteDiff, 3) + " MS";
				if (cpuControlled) msTxt.text = "0 MS (Bot)";
				msTxt.x += ClientPrefs.data.comboOffset[0];
				msTxt.y -= ClientPrefs.data.comboOffset[1];
				if (combo >= 10000) msTxt.x += 30 * (Std.string(combo).length - 4);
				FlxTween.tween(msTxt,
					{y: msTxt.y + 8},
					0.1 / playbackRate,
					{onComplete: function(_){

							FlxTween.tween(msTxt, {alpha: 0}, 0.2 / playbackRate, {
								// ease: FlxEase.circOut,
								onComplete: function(_){msTxt.visible = false;},
								startDelay: 1.4 / playbackRate
							});
						}
					});
				switch (daRating.name) //This is so stupid, but it works
				{
					case 'perfect': msTxt.color = FlxColor.YELLOW;
					case 'sick':  msTxt.color = FlxColor.CYAN;
					case 'good': msTxt.color = FlxColor.LIME;
					case 'bad': msTxt.color = FlxColor.ORANGE;
					case 'shit': msTxt.color = FlxColor.RED;
					default: msTxt.color = FlxColor.WHITE;
				}
				if (miss) msTxt.color = FlxColor.fromRGB(204, 66, 66);
			}

			if (ClientPrefs.data.ratingPopups && ClientPrefs.data.simplePopups && !ClientPrefs.data.hideHud) {
				FlxTween.cancelTweensOf(judgeTxt);
				FlxTween.cancelTweensOf(judgeTxt.scale);
				judgeTxt.cameras = [camHUD];
				judgeTxt.visible = true;
				judgeTxt.screenCenter(X);
				if (botplayTxt != null) judgeTxt.y = !ClientPrefs.data.downScroll ? botplayTxt.y + 60 : botplayTxt.y - 60;
				judgeTxt.alpha = 1;
				if (!miss) switch (daRating.name)
				{
				case 'perfect':
					judgeTxt.color = FlxColor.YELLOW;
					judgeTxt.text = hitStrings[0] + '\n' + formatNumber(combo);
				case 'sick':
					judgeTxt.color = FlxColor.CYAN;
					judgeTxt.text = hitStrings[1] + '\n' + formatNumber(combo);
				case 'good':
					judgeTxt.color = FlxColor.LIME;
					judgeTxt.text = hitStrings[2] + '\n' + formatNumber(combo);
				case 'bad':
					judgeTxt.color = FlxColor.ORANGE;
					judgeTxt.text = hitStrings[3] + '\n' + formatNumber(combo);
				case 'shit':
					judgeTxt.color = FlxColor.RED;
					judgeTxt.text = hitStrings[4] + '\n' + formatNumber(combo);
				default: judgeTxt.color = FlxColor.WHITE;
				}
				else
				{
					judgeTxt.color = FlxColor.fromRGB(204, 66, 66);
					judgeTxt.text = hitStrings[5] + '\n' + formatNumber(combo);
				}
				judgeTxt.scale.x = 1.075;
				judgeTxt.scale.y = 1.075;
				FlxTween.tween(judgeTxt.scale,
					{x: 1, y: 1},
				0.1 / playbackRate,
					{onComplete: function(_){
							FlxTween.tween(judgeTxt.scale, {x: 0, y: 0}, 0.1 / playbackRate, {
								onComplete: function(_){judgeTxt.visible = false;},
								startDelay: 1.0 / playbackRate
							});
						}
					});
			}
			if (ClientPrefs.data.ratingPopups && !ClientPrefs.data.simplePopups) popUpGroup.sort((o, a, b) ->
				{
					return FlxSort.byValues(FlxSort.ASCENDING, a.popTime, b.popTime);
				}
			);
		}
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.data.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				// obtain notes that the player can hit
				var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
					var canHit:Bool = !usingBotEnergy && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
					return n != null && canHit && !n.isSustainNote && n.noteData == key;
				});
				plrInputNotes.sort(sortHitNotes);

				if (plrInputNotes.length != 0) {
					var funnyNote:Note = plrInputNotes[0]; // front note

					if (plrInputNotes.length > 1) {
						var doubleNote:Note = plrInputNotes[1];

						//if the note has the same notedata and doOppStuff indicator as funnynote, then do the check
						if (doubleNote.noteData == funnyNote.noteData && doubleNote.doOppStuff == funnyNote.doOppStuff) {
							// if the note has a 0ms distance (is on top of the current note), kill it
							if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
								invalidateNote(doubleNote);
							else if (doubleNote.strumTime < funnyNote.strumTime)
							{
								// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
								funnyNote = doubleNote;
							}
						}
						else goodNoteHit(doubleNote); //otherwise, hit doubleNote instead of killing it
					}
					goodNoteHit(funnyNote);
					if (plrInputNotes.length > 2 && ClientPrefs.data.ezSpam) //literally all you need to allow you to spam though impossibly hard jacks
					{
						var notesThatCanBeHit = plrInputNotes.length;
						for (i in 1...Std.int(notesThatCanBeHit)) //i may consider making this hit half the notes instead
						{
							goodNoteHit(plrInputNotes[i]);
						}
					}
				}
				else {
					callOnScripts('onGhostTap', [key]);
					if (!opponentChart && ClientPrefs.data.ghostTapAnim && ClientPrefs.data.charsAndBG)
					{
						boyfriend.playAnim(singAnimations[Std.int(Math.abs(key))], true);
						if (ClientPrefs.data.cameraPanning) camPanRoutine(singAnimations[Std.int(Math.abs(key))], 'bf');
						boyfriend.holdTimer = 0;
					}
					if (opponentChart && ClientPrefs.data.ghostTapAnim && ClientPrefs.data.charsAndBG)
					{
						dad.playAnim(singAnimations[Std.int(Math.abs(key))], true);
						if (ClientPrefs.data.cameraPanning) camPanRoutine(singAnimations[Std.int(Math.abs(key))], 'dad');
						dad.holdTimer = 0;
					}
					if (canMiss) {
						noteMissPress(key);
					}
				}

				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyPress', [key]);
		}
	}

	function sortHitNotes(a:Dynamic, b:Dynamic):Int
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
		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
				spr.resetRGB();
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}

	public function getKeyFromEvent(key:FlxKey):Int
	{
		// var tempKeys:Array<Dynamic> = backend.Keybinds.fill();
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

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();
		strumsHeld = parsedHoldArray;
		strumHeldAmount = strumsHeld.filter(function(value) return value).length;

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.data.controllerMode)
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

		var char:Character = boyfriend;
		if (opponentChart) char = dad;
		if (startedCountdown && !char.stunned && generatedMusic)
		{
			// rewritten inputs???
			for (group in [notes, sustainNotes]) group.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (!usingBotEnergy && strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if(ClientPrefs.data.charsAndBG && FlxG.keys.anyJustPressed(tauntKey) && !char.animation.curAnim.name.endsWith('miss') && char.specialAnim == false && ClientPrefs.data.spaceVPose){
				char.playAnim('hey', true);
				char.specialAnim = true;
				char.heyTimer = 0.59;
				FlxG.sound.play(Paths.sound('hey'));
				trace("HEY!!");
				}

			if (!parsedHoldArray.contains(true) || endingSong) {
				if (ClientPrefs.data.charsAndBG) playerDance();
			}

			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.data.controllerMode || strumsBlocked.contains(true))
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

	public function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note = null, daNoteAlt:PreloadedChartNote = null):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if (daNote != null)
		{
			if (combo > 0)
				combo = 0;
			else combo -= 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
			if (health > 0 && !usingBotEnergy)
			{
				health -= daNote.missHealth * healthLoss;
			}

			if(instakillOnMiss || sickOnly)
			{
				vocals.volume = opponentVocals.volume = gfVocals.volume = 0;
				doDeathCheck(true);
			}

			songMisses += 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
			if (SONG.needsVoices && !ffmpegMode)
				if (opponentChart && opponentVocals != null && opponentVocals.volume != 0) opponentVocals.volume = 0;
				else if (!opponentChart && vocals.volume != 0 || vocals.volume != 0) vocals.volume = 0;
			if (!practiceMode)
				songScore -= 10 * Std.int((opponentChart ? polyphonyOppo : polyphonyBF));

			totalPlayed++;
			if (missRecalcsPerFrame <= 3) RecalculateRating(true);

			final char:Character = !daNote.gfNote ? !opponentChart ? boyfriend : dad : gf;

			if(char != null && !daNote.noMissAnimation && char.hasMissAnimations && ClientPrefs.data.charsAndBG)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
				char.playAnim(animToPlay, true);
			}
			if (scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
			if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();

			daNote.tooLate = true;

			if (usingBotEnergy)
			{
				if (missResetTimer <= 0.1)
				{
					if (!notesBeingMissed) notesBeingMissed = true;
					missResetTimer += 0.01 / playbackRate;
				}
			}

			if (daNote.noteHoldSplash != null) {
				daNote.noteHoldSplash.kill();
			}

			stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
			callOnScripts('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
			if (ClientPrefs.data.missRating && ClientPrefs.data.ratingPopups) popUpScore(daNote, true);
		}
		if (daNoteAlt != null)
		{
			if (combo > 0)
				combo = 0;
			else combo -= 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
			if (health > 0)
			{
				health -= daNoteAlt.missHealth * healthLoss;
			}

			if(instakillOnMiss)
			{
				(opponentChart ? opponentVocals : vocals).volume = 0;
				doDeathCheck(true);
			}

			songMisses += 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
			(opponentChart ? opponentVocals : vocals).volume = 0;
			if (!practiceMode)
				songScore -= 10 * Std.int((opponentChart ? polyphonyOppo : polyphonyBF));

			totalPlayed++;
			if (missRecalcsPerFrame <= 3) RecalculateRating(true);

			final char:Character = !daNoteAlt.gfNote ? !opponentChart ? boyfriend : dad : gf;

			if(char != null && !daNoteAlt.noMissAnimation && char.hasMissAnimations && ClientPrefs.data.charsAndBG)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(daNoteAlt.noteData))] + 'miss' + daNoteAlt.animSuffix;
				char.playAnim(animToPlay, true);
			}
			if (scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
			if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();

			callOnScripts('noteMiss', [null, daNoteAlt.noteData, daNoteAlt.noteType, daNoteAlt.isSustainNote]);
		}
	}

	public function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				(opponentChart ? opponentVocals : vocals).volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			var char:Character = boyfriend;
			if (opponentChart) char = dad;
			if(char.hasMissAnimations) {
				char.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			(opponentChart ? opponentVocals : vocals).volume = 0;
		}
		if (scoreTxtUpdateFrame <= 4 && scoreTxt != null) updateScore();
		if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
		
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function updateNote(daNote:Note):Void
	{
		if (daNote != null && daNote.exists)
		{
			//first, process whether or not the note should be hit. this prevents pointless strum following
			if (!daNote.mustPress && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.strumTime <= Conductor.songPosition)
				opponentNoteHit(daNote);

			if(daNote.mustPress) {
				if((cpuControlled || usingBotEnergy && strumsHeld[daNote.noteData]) && !daNote.wasGoodHit && daNote.strumTime <= Conductor.songPosition && !daNote.ignoreNote)
					goodNoteHit(daNote);
			}
			if (!daNote.exists) return;

			amountOfRenderedNotes += daNote.noteDensity;
			if (maxRenderedNotes < amountOfRenderedNotes) maxRenderedNotes = amountOfRenderedNotes;
			daNote.followStrum((daNote.mustPress ? playerStrums : opponentStrums).members[daNote.noteData], songSpeed);
			if (daNote.isSustainNote)
			{
				final strum = (daNote.mustPress ? playerStrums : opponentStrums).members[daNote.noteData];
				if (strum != null && strum.sustainReduce) daNote.clipToStrumNote(strum);
			}

			if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
			{
				if (daNote.mustPress && (!(cpuControlled || usingBotEnergy && strumsHeld[daNote.noteData]) || cpuControlled) && !daNote.ignoreNote && !endingSong && !daNote.wasGoodHit) {
					noteMiss(daNote);
					if (ClientPrefs.data.missSoundShit)
					{
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
					}
				}
				invalidateNote(daNote);
			}
		}
	}

	var oppTrigger:Bool = false;
	var doGf:Bool = false;
	var playerChar = null;
	var canPlay = true;
	var holdAnim:String = '';
	var animToPlay:String = 'singLEFT';
	var animCheck:String = 'hey';
	function goodNoteHit(note:Note, noteAlt:PreloadedChartNote = null):Void
	{
		if (note != null)
		{
			if (opponentChart || bothSides && note.doOppStuff) {
				if (songName != 'tutorial' && !camZooming)
					camZooming = true;
			}
			if(!ffmpegMode && (note.wasGoodHit || cpuControlled && note.ignoreNote)) return;

			if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled && !note.isSustainNote)
			{
				hitsound.play(true);
				hitsound.pitch = playbackRate;
				if (FileSystem.exists('assets/shared/images/' + hitsoundImageToLoad + '.png') || FileSystem.exists(Paths.modFolders('images/' + hitsoundImageToLoad + '.png')) && hitImagesFrame < 4)
				{
					hitImagesFrame++;
					hitsoundImage = new FlxSprite().loadGraphic(Paths.image(hitsoundImageToLoad));
					hitsoundImage.antialiasing = ClientPrefs.data.globalAntialiasing;
					hitsoundImage.scrollFactor.set();
					hitsoundImage.setGraphicSize(Std.int(hitsoundImage.width / FlxG.camera.zoom));
					hitsoundImage.updateHitbox();
					hitsoundImage.screenCenter();
					hitsoundImage.alpha = 1;
					hitsoundImage.cameras = [camGame];
					add(hitsoundImage);
					FlxTween.tween(hitsoundImage, {alpha: 0}, 1 / (SONG.bpm/100) / playbackRate, {
						onComplete: function(tween:FlxTween)
						{
							hitsoundImage.destroy();
						}
					});
				}
			}

			if(!note.hitCausesMiss) {
				if (!note.isSustainNote)
				{
					if (combo < 0) combo = 0;
					if ((opponentChart ? polyphonyOppo : polyphonyBF) > 1 && !note.isSustainNote) totalNotes += polyphonyBF - 1;
					missCombo = 0;
					combo += 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
					totalNotesPlayed += 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
					if (ClientPrefs.data.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
						notesHitArray.push(1 * (opponentChart ? polyphonyOppo : polyphonyBF));
						notesHitDateArray.push(Conductor.songPosition);
					}
					if (!ClientPrefs.data.lessBotLag) popUpScore(note);
					else judgeNote(note);
					maxCombo = Math.max(maxCombo, combo);
				}

				if (!usingBotEnergy) health += note.hitHealth * healthGain * (opponentChart ? polyphonyOppo : polyphonyBF);

				if (bothSides) oppTrigger = bothSides && note.doOppStuff;
				else if (opponentChart && !oppTrigger) oppTrigger = true;
				doGf = note.gfNote;

				if(!note.noAnimation && ClientPrefs.data.charsAndBG) {
					animToPlay = singAnimations[Std.int(Math.abs(note.noteData))];

					playerChar = (doGf ? gf : (!oppTrigger ? boyfriend : dad));
					animCheck = (playerChar != gf ? 'hey' : 'cheer');
					if (note.animSuffix.length > 0 && playerChar.hasAnimation(animToPlay + note.animSuffix))
						animToPlay = singAnimations[Std.int(Math.abs(note.noteData))] + note.animSuffix;

					if (ClientPrefs.data.cameraPanning) camPanRoutine(animToPlay, (!oppTrigger ? 'bf' : 'oppt'));
					if (playerChar != null)
					{
						canPlay = (!note.isSustainNote || ClientPrefs.data.oldSusStyle && note.isSustainNote);
						if(note.isSustainNote)
						{
							holdAnim = animToPlay + '-hold';
							if(playerChar.animation.exists(holdAnim)) animToPlay = holdAnim;
							if(playerChar.getAnimationName() == holdAnim || playerChar.getAnimationName() == holdAnim + '-loop')
								canPlay = false;
						}

						if(canPlay) playerChar.playAnim(animToPlay, true);
						playerChar.holdTimer = 0;

						if(note.noteType == 'Hey!')
						{
							if(playerChar.hasAnimation(animCheck))
							{
								playerChar.playAnim(animCheck, true);
								playerChar.specialAnim = true;
								playerChar.heyTimer = 0.6;
							}
						}
					}
				}

				if((cpuControlled || usingBotEnergy && strumsHeld[note.noteData]) && ClientPrefs.data.botLightStrum && !strumsHit[(note.noteData % 4) + 4]) {
					strumsHit[(note.noteData % 4) + 4] = true;

					if(playerStrums.members[note.noteData] != null) {
						if (ClientPrefs.data.noteColorStyle != 'Normal' && ClientPrefs.data.showNotes && ClientPrefs.data.enableColorShader)
							playerStrums.members[note.noteData].playAnim('confirm', true, note.rgbShader.r, note.rgbShader.g, note.rgbShader.b);
						else
							playerStrums.members[note.noteData].playAnim('confirm', true);

						playerStrums.members[note.noteData].resetAnim = calculateResetTime();
					}
				} else if (ClientPrefs.data.playerLightStrum && !cpuControlled) {
					final spr = playerStrums.members[note.noteData];
					if(spr != null)
					{
						if (ClientPrefs.data.noteColorStyle != 'Normal' && ClientPrefs.data.showNotes && ClientPrefs.data.enableColorShader)
							spr.playAnim('confirm', true, note.rgbShader.r, note.rgbShader.g, note.rgbShader.b);
						else
							spr.playAnim('confirm', true);
					}
				}
			}
			else
			{
				if(!note.noMissAnimation)
				{
					playerChar = boyfriend;
					switch(note.noteType)
					{
						case 'Hurt Note':
							if(playerChar.hasAnimation('hurt'))
							{
								playerChar.playAnim('hurt', true);
								playerChar.specialAnim = true;
							}
					}
				}

				noteMiss(note);
				if(!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(false, note);
			}

			if (playerChar != null && playerChar.shakeScreen)
			{
				camGame.shake(playerChar.shakeIntensity, playerChar.shakeDuration / playbackRate);
				camHUD.shake(playerChar.shakeIntensity / 2, playerChar.shakeDuration / playbackRate);
			}
			note.wasGoodHit = true;
			if (!ClientPrefs.data.lessBotLag && ClientPrefs.data.noteSplashes && note.isSustainNote && splashesPerFrame[3] <= 4) spawnHoldSplashOnNote(note);
			if (SONG.needsVoices && !ffmpegMode)
				if (opponentChart && opponentVocals != null && opponentVocals.volume != 1) opponentVocals.volume = 1;
				else if (!opponentChart && vocals.volume != 1 || vocals.volume != 1) vocals.volume = 1;

			if (!notesBeingHit && usingBotEnergy)
			{
				notesBeingHit = true;
				hitResetTimer = 0.3 / playbackRate;
			}

			if (!ClientPrefs.data.noHitFuncs) 
			{
				callOnScripts((oppTrigger ? 'opponentNoteHit' : 'goodNoteHit'), [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
				stagesFunc(function(stage:BaseStage) (oppTrigger ? stage.opponentNoteHit(note) : stage.goodNoteHit(note)));
			}

			if (!note.isSustainNote) invalidateNote(note);

			if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
			if (scoreTxtUpdateFrame <= 4) updateScore();
			if (ClientPrefs.data.iconBopWhen == 'Every Note Hit' && (iconBopsThisFrame <= 2 || ClientPrefs.data.noBopLimit) && !note.isSustainNote && iconP1.visible) bopIcons(!oppTrigger);
			return;
		}
		if (noteAlt != null)
		{
			oppTrigger = opponentChart || bothSides && noteAlt.oppNote;
			if(noteAlt.noteType == 'Hey!')
			{
				playerChar = !noteAlt.gfNote ? oppTrigger ? dad : boyfriend : gf;
				if (playerChar.hasAnimation('hey')) {
					playerChar.playAnim('hey', true);
					playerChar.specialAnim = true;
					playerChar.heyTimer = 0.6;
				}
			}
			if(!noteAlt.noAnimation && ClientPrefs.data.charsAndBG) {
				playerChar = !noteAlt.gfNote ? oppTrigger ? dad : boyfriend : gf;
				if (playerChar != null)
				{
					playerChar.playAnim(singAnimations[(noteAlt.noteData)] + noteAlt.animSuffix, true);
					playerChar.holdTimer = 0;
				}
			}
			if(cpuControlled && !ClientPrefs.data.showNotes) {
				if (ClientPrefs.data.botLightStrum && !strumsHit[(noteAlt.noteData % 4) + 4])
				{
					strumsHit[(noteAlt.noteData % 4) + 4] = true;
					playerStrums.members[noteAlt.noteData].playAnim('confirm', true);
					playerStrums.members[noteAlt.noteData].resetAnim = calculateResetTime();
				}
			}
			if (!noteAlt.isSustainNote && cpuControlled)
			{
				combo += 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
				songScore += (ClientPrefs.data.noPerfectJudge ? 350 : 500) * (opponentChart ? polyphonyOppo : polyphonyBF);
				totalNotesPlayed += 1 * (opponentChart ? polyphonyOppo : polyphonyBF);
				if (ClientPrefs.data.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					notesHitArray.push(1 * (opponentChart ? polyphonyOppo : polyphonyBF));
					notesHitDateArray.push(Conductor.songPosition);
				}
				if ((opponentChart ? polyphonyOppo : polyphonyBF) > 1) totalNotes += (opponentChart ? polyphonyOppo : polyphonyBF) - 1;
			}
			if (!ClientPrefs.data.noSkipFuncs) callOnScripts((oppTrigger ? 'opponentNoteSkip' : 'goodNoteSkip'), [null, Math.abs(noteAlt.noteData), noteAlt.noteType, noteAlt.isSustainNote]);
			health += noteAlt.hitHealth * healthGain * (opponentChart ? polyphonyOppo : polyphonyBF);
			if (!ffmpegMode) (opponentChart ? opponentVocals : vocals).volume = 1;
		}
		return;
	}

	var oppChar = null;
	var gfTrigger:Bool = false;
	function opponentNoteHit(daNote:Note, noteAlt:PreloadedChartNote = null):Void
	{
		if (daNote != null)
		{
			if (!opponentChart && songName != 'tutorial' && !camZooming)
				camZooming = true;

			if(daNote.noteType == 'Hey!')
			{
				oppChar = !daNote.gfNote ? !opponentChart ? dad : boyfriend : gf;
				if (oppChar.hasAnimation('hey')) {
					oppChar.playAnim('hey', true);
					oppChar.specialAnim = true;
					oppChar.heyTimer = 0.6;
				}
			} else if(!daNote.noAnimation && ClientPrefs.data.charsAndBG) {
				oppChar = !daNote.gfNote ? !opponentChart ? dad : boyfriend : gf;
				animToPlay = singAnimations[Std.int(Math.abs(daNote.noteData))];

				if (daNote.animSuffix.length > 0 && oppChar.hasAnimation(animToPlay + daNote.animSuffix))
					animToPlay = singAnimations[Std.int(Math.abs(daNote.noteData))] + daNote.animSuffix;

				if (ClientPrefs.data.cameraPanning) camPanRoutine(animToPlay, (!opponentChart ? 'dad' : 'bf'));

				if (oppChar != null)
				{
					canPlay = (!daNote.isSustainNote || ClientPrefs.data.oldSusStyle && daNote.isSustainNote);
					if(daNote.isSustainNote)
					{
						holdAnim = animToPlay + '-hold';
						if(oppChar.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(oppChar.getAnimationName() == holdAnim || oppChar.getAnimationName() == holdAnim + '-loop')
							canPlay = false;
					}

					if(canPlay) oppChar.playAnim(animToPlay, true);
					oppChar.holdTimer = 0;
				}
			}

			if (!daNote.isSustainNote)
			{
				if (ClientPrefs.data.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					oppNotesHitArray.push(1 * polyphonyOppo);
					oppNotesHitDateArray.push(Conductor.songPosition);
				}
				enemyHits += 1 * polyphonyOppo;
				invalidateNote(daNote);
			}

			if(ClientPrefs.data.oppNoteSplashes && !daNote.isSustainNote && splashesPerFrame[0] <= 4)
				spawnNoteSplashOnNote(true, daNote);

			if (SONG.needsVoices && !ffmpegMode)
				if (!opponentChart && opponentVocals != null && opponentVocals.volume != 1) opponentVocals.volume = 1;
				else if (opponentChart && vocals.volume != 1 || vocals.volume != 1) vocals.volume = 1;
				else if (gfVocals.volume != 1) gfVocals.volume = 1;

			if (polyphonyOppo > 1 && !daNote.isSustainNote) opponentNoteTotal += polyphonyOppo - 1;

			if (ClientPrefs.data.opponentLightStrum && !strumsHit[daNote.noteData % 4])
			{
				strumsHit[daNote.noteData % 4] = true;

				if (ClientPrefs.data.noteColorStyle != 'Normal' && ClientPrefs.data.showNotes && ClientPrefs.data.enableColorShader)
					opponentStrums.members[daNote.noteData].playAnim('confirm', true, daNote.rgbShader.r, daNote.rgbShader.g, daNote.rgbShader.b);
				else
					opponentStrums.members[daNote.noteData].playAnim('confirm', true);

				opponentStrums.members[daNote.noteData].resetAnim = calculateResetTime();
			}
			daNote.hitByOpponent = true;

			if (ClientPrefs.data.oppNoteSplashes && daNote.isSustainNote && splashesPerFrame[2] <= 4) spawnHoldSplashOnNote(daNote, true);

			if (!ClientPrefs.data.noHitFuncs) 
			{
				callOnScripts((!opponentChart ? 'opponentNoteHit' : 'goodNoteHit'), [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);
				stagesFunc(function(stage:BaseStage) (!opponentChart ? stage.opponentNoteHit(daNote) : stage.goodNoteHit(daNote)));
			}

			if (shouldDrainHealth && health > (healthDrainFloor * polyphonyOppo) && !practiceMode || opponentDrain && practiceMode)
				health -= (opponentDrain ? daNote.hitHealth : healthDrainAmount) * hpDrainLevel * polyphonyOppo;

			if (oppChar != null && oppChar.shakeScreen)
			{
				camGame.shake(oppChar.shakeIntensity, oppChar.shakeDuration / playbackRate);
				camHUD.shake(oppChar.shakeIntensity / 2, oppChar.shakeDuration / playbackRate);
			}
			if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
			if (scoreTxtUpdateFrame <= 4) updateScore();
			if (ClientPrefs.data.iconBopWhen == 'Every Note Hit' && (iconBopsThisFrame <= 2 || ClientPrefs.data.noBopLimit) && !daNote.isSustainNote && iconP2.visible) bopIcons(opponentChart);
			return;
		}
		if (noteAlt != null)
		{
			if(noteAlt.noteType == 'Hey!')
			{
				oppChar = !noteAlt.gfNote ? !opponentChart ? dad : boyfriend : gf;
				if (oppChar.animOffsets.exists('hey')) {
					oppChar.playAnim('hey', true);
					oppChar.specialAnim = true;
					oppChar.heyTimer = 0.6;
				}
			}
			if(!noteAlt.noAnimation && ClientPrefs.data.charsAndBG) {
				oppChar = !noteAlt.gfNote ? !opponentChart ? dad : boyfriend : gf;
				animToPlay = singAnimations[Std.int(Math.abs(noteAlt.noteData))] + noteAlt.animSuffix;
				if (oppChar != null)
				{
					oppChar.playAnim(animToPlay, true);
					oppChar.holdTimer = 0;
				}
			}
			if (ClientPrefs.data.opponentLightStrum && !strumsHit[noteAlt.noteData % 4] && !ClientPrefs.data.showNotes)
			{
				strumsHit[noteAlt.noteData % 4] = true;
				opponentStrums.members[noteAlt.noteData].playAnim('confirm', true);
				opponentStrums.members[noteAlt.noteData].resetAnim = calculateResetTime();
			}
			if (!noteAlt.isSustainNote)
			{
				if (ClientPrefs.data.showNPS) { //i dont think we should be pushing to 2 arrays at the same time but oh well
					oppNotesHitArray.push(1 * polyphonyOppo);
					oppNotesHitDateArray.push(Conductor.songPosition);
				}
				enemyHits += 1 * polyphonyOppo;

				if (ClientPrefs.data.ratingCounter && judgeCountUpdateFrame <= 4) updateRatingCounter();
				if (scoreTxtUpdateFrame <= 4) updateScore();

				if (shouldDrainHealth && health > healthDrainFloor && !practiceMode || opponentDrain && practiceMode)
					health -= (opponentDrain ? noteAlt.hitHealth : healthDrainAmount) * hpDrainLevel * polyphonyOppo;
			}
			if ((!noteAlt.gfNote ? !opponentChart ? dad : boyfriend : gf) != null && (!noteAlt.gfNote ? !opponentChart ? dad : boyfriend : gf).shakeScreen)
			{
				oppChar = !noteAlt.gfNote ? !opponentChart ? dad : boyfriend : gf;
				camGame.shake(oppChar.shakeIntensity, oppChar.shakeDuration / playbackRate);
				camHUD.shake(oppChar.shakeIntensity / 2, oppChar.shakeDuration / playbackRate);
			}
			if (!ClientPrefs.data.noSkipFuncs) callOnScripts((!opponentChart ? 'opponentNoteSkip' : 'goodNoteSkip'), [null, Math.abs(noteAlt.noteData), noteAlt.noteType, noteAlt.isSustainNote]);
			if (SONG.needsVoices && !ffmpegMode)
				if (!opponentChart && opponentVocals != null && opponentVocals.volume != 1) opponentVocals.volume = 1;
				else if (opponentChart && vocals.volume != 1 || vocals.volume != 1) vocals.volume = 1;
				else if (gfVocals.volume != 1) gfVocals.volume = 1;
		}
		return;
	}

	public function invalidateNote(note:Note):Void {
		note.exists = note.wasGoodHit = note.hitByOpponent = note.tooLate = note.canBeHit = false;
		if (ClientPrefs.data.fastNoteSpawn) (note.isSustainNote ? sustainNotes : notes).pushToPool(note);
	}

	public function spawnHoldSplashOnNote(note:Note, ?isDad:Bool = false) {
		if (!ClientPrefs.data.noteSplashes || note == null)
			return;

		splashesPerFrame[(isDad ? 2 : 3)] += 1;

		if (note != null) {
			var strum:StrumNote = (isDad ? playerStrums : opponentStrums).members[note.noteData];
			final susLength:Float = (!note.isSustainNote ? note.sustainLength : note.parentSL);
			final tailLength:Int = Math.floor(susLength / Conductor.stepCrochet);

			if(strum != null && tailLength != 0)
				spawnHoldSplash(note);
		}
	}

	public function spawnHoldSplash(note:Note) {
		var end:Note = note;
		var splash:SustainSplash = grpHoldSplashes.recycle(SustainSplash);
		splash.setupSusSplash((note.mustPress ? playerStrums : opponentStrums).members[note.noteData], note, playbackRate);
		grpHoldSplashes.add(end.noteHoldSplash = splash);
	}

	public function spawnNoteSplashOnNote(isDad:Bool, note:Note) {
		if(ClientPrefs.data.noteSplashes && note != null) {
			splashesPerFrame[(isDad ? 0 : 1)] += 1;
			final strum:StrumNote = !isDad ? playerStrums.members[note.noteData] : opponentStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		utils.window.WindowUtils.resetTitle();
		utils.window.Window.reset();

		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if LUA_ALLOWED
		try {
		for (lua in luaArray)
		{ var lua:Dynamic = cast(lua);
			lua.call('onDestroy', []);
			lua.stop();
		} } catch(P) {trace("Ew. Can't destroy Lua.");}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		#end
		
		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if (script != null)
			{
				script.executeFunction('onDestroy');
				script.destroy();
			}
		hscriptArray = null;
		#end

		stagesFunc(function(stage:BaseStage) stage.destroy());

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.camera.setFilters([]);
		FlxG.animationTimeScale = 1;
		FlxG.sound.music.pitch = 1;
		cpp.vm.Gc.enable(true);
		KillNotes();
		MusicBeatState.windowNamePrefix = Assets.getText(Paths.txt("windowTitleBase"));
		if(ffmpegMode) {
			if (FlxG.fixedTimestep) {
				FlxG.fixedTimestep = false;
				FlxG.animationTimeScale = 1;
			}
			if(unlockFPS) {
				FlxG.drawFramerate = ClientPrefs.data.framerate;
				FlxG.updateFramerate = ClientPrefs.data.framerate;
			}
		}

		Paths.noteSkinFramesMap.clear();
		Paths.noteSkinAnimsMap.clear();
		Paths.splashSkinFramesMap.clear();
		Paths.splashSkinAnimsMap.clear();
		Paths.splashConfigs.clear();
		Paths.splashAnimCountMap.clear();
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		var clearfuck:MemoryHelper = new MemoryHelper();
		var oldMania = mania;

		var protected:Array<String> = ['mania', 'SONG', 'E'];
		for (stuff in protected)
			clearfuck.addProtectedField(Type.getClass(this), stuff);
		clearfuck.clearClassObject(Type.getClass(this));
		for (stuff in instance) // Clear all variables
			clearfuck.clearObject(stuff);

		instance = null;
		mania = oldMania;

		super.destroy();
	}

	override function stepHit()
	{
		if (curStep == 0) moveCameraSection();
		super.stepHit();

		if (tankmanAscend)
		{
			if (curStep >= 896 && curStep <= 1152) moveCameraSection();
			switch (curStep)
			{
				case 896:
					{
						if (!opponentChart) {
						opponentStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
						if (EngineWatermark != null) FlxTween.tween(EngineWatermark, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeBar, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(judgementCounter, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(scoreTxt, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBar, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBarBG, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP1, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP2, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeTxt, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						dad.velocity.y = -35;
					}
				case 906:
					{
						if (!opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						} else {
						opponentStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					}
				case 1020:
					{
						if (!opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					}
				case 1024:
						if (opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 0}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					dad.velocity.y = 0;
					boyfriend.velocity.y = -33.5;
				case 1148:
					{
						if (opponentChart) {
						playerStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						});
						}
					}
				case 1151:
					cameraSpeed = 100;
				case 1152:
					{
						FlxG.camera.flash(FlxColor.WHITE, 1);
						opponentStrums.forEachAlive(function(daNote:FlxSprite)
						{
							FlxTween.tween(daNote, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						});
						if (EngineWatermark != null) FlxTween.tween(EngineWatermark, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(judgementCounter, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBar, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(healthBarBG, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(scoreTxt, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP1, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(iconP2, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.expoOut,});
						dad.x = 100;
						dad.y = 280;
						boyfriend.x = 810;
						boyfriend.y = 450;
						dad.velocity.y = 0;
						boyfriend.velocity.y = 0;
					}
				case 1153:
					cameraSpeed = 1;
			}
		}
		if (!ffmpegMode && playbackRate < 256) //much better resync code, doesn't just resync every step!!
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * Math.max(playbackRate, 1);
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime ||
			(vocals.length > 0 && vocals.time < vocals.length && Math.abs(vocals.time - timeSub) > syncTime) ||
			(opponentVocals.length > 0 && opponentVocals.time < opponentVocals.length && Math.abs(opponentVocals.time - timeSub) > syncTime) ||
			(gfVocals.length > 0 && gfVocals.time < gfVocals.length && Math.abs(gfVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}
		
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit == curBeat) return;

		if(ClientPrefs.data.timeBounce)
		{
			if(timeTxtTween != null) {
				timeTxtTween.cancel();
			}
			timeTxt.scale.x = 1.075;
			timeTxt.scale.y = 1.075;
			timeTxtTween = FlxTween.tween(timeTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					timeTxtTween = null;
				}
			});
		}

		if (curBeat % 32 == 0 && randomSpeedThing)
		{
			var randomShit = FlxMath.roundDecimal(FlxG.random.float(minSpeed, maxSpeed), 2);
			lerpSongSpeed(randomShit, 1);
		}
		if (camZooming && !endingSong && !startingSong && FlxG.camera.zoom < 1.35 && usingBopIntervalEvent && ClientPrefs.data.camZooms && (curBeat % camBopInterval == 0))
		{
			FlxG.camera.zoom += 0.015 * camBopIntensity;
			camHUD.zoom += 0.03 * camBopIntensity;
		} /// WOOO YOU CAN NOW MAKE IT AWESOME

		if (camTwist && curBeat % gfSpeed == 0)
		{
			if (curBeat % (gfSpeed * 2) == 0)
				twistShit = twistAmount * camTwistIntensity;

			if (curBeat % (gfSpeed * 2) == gfSpeed)
				twistShit = -twistAmount * camTwistIntensity2;
				
			for (i in [camHUD, camGame])
			{
				FlxTween.cancelTweensOf(i);
				i.angle = twistShit;
				FlxTween.tween(i, {angle: 0}, 45 / Conductor.bpm * gfSpeed / playbackRate, {ease: FlxEase.circOut});
			}
		}

		if (ClientPrefs.data.iconBopWhen == 'Every Beat' && (iconP1.visible || iconP2.visible)) 
			bopIcons();

		if (ClientPrefs.data.charsAndBG) characterBopper(curBeat);
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat); //DAWGG?????
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
	}

	public function playerDance():Void
	{
		var char = (opponentChart ? dad : boyfriend);
		var anim:String = char.getAnimationName();
		if(char.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * char.singDuration * singDurMult && anim.startsWith('sing') && !anim.endsWith('miss'))
			char.dance();
	}

	var usingBopIntervalEvent = false;
	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (ClientPrefs.data.timeBarStyle == 'Leather Engine') timeBar.color = SONG.notes[curSection].mustHitSection ? FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]) : FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				SustainSplash.startCrochet = Conductor.stepCrochet;
				SustainSplash.frameRate = Math.floor(24 / 100 * Conductor.bpm);
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
				if (Conductor.bpm >= 500) singDurMult = gfSpeed;
				else singDurMult = 1;
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
			if (camZooming && !endingSong && !startingSong && FlxG.camera.zoom < 1.35 && !usingBopIntervalEvent && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camBopIntensity;
				camHUD.zoom += 0.03 * camBopIntensity;
			}
		}

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	public function bopIcons(?bopBF:Bool = false)
	{
		iconBopsThisFrame++;
		if (ClientPrefs.data.iconBopWhen == 'Every Beat')
		{
			if (ClientPrefs.data.iconBounceType == 'Dave and Bambi') {
				final funny:Float = Math.max(Math.min(healthBar.value,(maxHealth/0.95)),0.1);

				//health icon bounce but epic
				if (!opponentChart)
				{
					iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + 0.1))),Std.int(iconP1.height - (25 * funny)));
					iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP2.height - (25 * ((2 - funny) + 0.1))));
				} else {
					iconP2.setGraphicSize(Std.int(iconP2.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
					iconP1.setGraphicSize(Std.int(iconP1.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP1.height - (25 * ((2 - funny) + 0.1))));
				}
			}
			if (ClientPrefs.data.iconBounceType == 'Old Psych') {
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
			}
			if (ClientPrefs.data.iconBounceType == 'Strident Crisis') {
				final funny:Float = (healthBar.percent * 0.01) + 0.01;

				//health icon bounce but epic
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (2 + funny))),Std.int(iconP2.height - (25 * (2 + funny))));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));

				iconP1.scale.set(1.1, 0.8);
				iconP2.scale.set(1.1, 0.8);

				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});

				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
			}
			if (ClientPrefs.data.iconBounceType == 'Plank Engine') {
				iconP1.scale.x = 1.3;
				iconP1.scale.y = 0.75;
				iconP2.scale.x = 1.3;
				iconP2.scale.y = 0.75;
				FlxTween.cancelTweensOf(iconP1);
				FlxTween.cancelTweensOf(iconP2);
				FlxTween.tween(iconP1, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				FlxTween.tween(iconP2, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				if (curBeat % 4 == 0) {
					iconP1.offset.x = 10;
					iconP2.offset.x = -10;
					iconP1.angle = -15;
					iconP2.angle = 15;
					FlxTween.tween(iconP1, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
					FlxTween.tween(iconP2, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
				}
			}
			if (ClientPrefs.data.iconBounceType == 'New Psych') {
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
			}

			if (curBeat % gfSpeed == 0 && ClientPrefs.data.iconBounceType == 'Golden Apple') {
				curBeat % (gfSpeed * 2) == 0 * playbackRate ? {
				iconP1.scale.set(1.1, 0.8);
				iconP2.scale.set(1.1, 1.3);

				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				} : {
					iconP1.scale.set(1.1, 1.3);
					iconP2.scale.set(1.1, 0.8);

					FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				}

				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
			}
			if (ClientPrefs.data.iconBounceType == 'VS Steve') {
				if (curBeat % gfSpeed == 0)
				{
					curBeat % (gfSpeed * 2) == 0 ?
					{
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});

					}

					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				}
			}
		}
		else if (ClientPrefs.data.iconBopWhen == 'Every Note Hit')
		{
			iconBopsTotal++;
			if (ClientPrefs.data.iconBounceType == 'Dave and Bambi') {
				final funny:Float = Math.max(Math.min(healthBar.value,(maxHealth/0.95)),0.1);

				//health icon bounce but epic
				if (!opponentChart)
				{
					if (bopBF) iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (funny + 0.1))),Std.int(iconP1.height - (25 * funny)));
					iconP2.setGraphicSize(Std.int(iconP2.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP2.height - (25 * ((2 - funny) + 0.1))));
				} else {
					if (!bopBF) iconP2.setGraphicSize(Std.int(iconP2.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
					else iconP1.setGraphicSize(Std.int(iconP1.width + (50 * ((2 - funny) + 0.1))),Std.int(iconP1.height - (25 * ((2 - funny) + 0.1))));
				}
			}
			if (ClientPrefs.data.iconBounceType == 'Old Psych') {
				if (bopBF) iconP1.setGraphicSize(Std.int(iconP1.width + 30), Std.int(iconP1.height + 30));
				else iconP2.setGraphicSize(Std.int(iconP2.width + 30), Std.int(iconP2.height + 30));
			}
			if (ClientPrefs.data.iconBounceType == 'Strident Crisis') {
				final funny:Float = (healthBar.percent * 0.01) + 0.01;

				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * (2 + funny))),Std.int(iconP2.height - (25 * (2 + funny))));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));

				FlxTween.cancelTweensOf(iconP1);
				FlxTween.cancelTweensOf(iconP2);

				FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});

				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
			}
			if (ClientPrefs.data.iconBounceType == 'Plank Engine') {
				iconP1.scale.x = 1.3;
				iconP1.scale.y = 0.75;
				FlxTween.cancelTweensOf(iconP1);
				FlxTween.tween(iconP1, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				iconP2.scale.x = 1.3;
				iconP2.scale.y = 0.75;
				FlxTween.cancelTweensOf(iconP2);
				FlxTween.tween(iconP2, {"scale.x": 1, "scale.y": 1}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.backOut});
				if (iconBopsTotal % 4 == 0) {
					iconP1.offset.x = 10;
					iconP1.angle = -15;
					FlxTween.tween(iconP1, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
					iconP2.offset.x = -10;
					iconP2.angle = 15;
					FlxTween.tween(iconP2, {"offset.x": 0, angle: 0}, Conductor.crochet / 1000 / playbackRate, {ease: FlxEase.expoOut});
				}
			}
			if (ClientPrefs.data.iconBounceType == 'New Psych') {
				if (bopBF) iconP1.scale.set(1.2, 1.2);
				else iconP2.scale.set(1.2, 1.2);
			}
			if (ClientPrefs.data.iconBounceType == 'Golden Apple') {
				FlxTween.cancelTweensOf(iconP1);
				FlxTween.cancelTweensOf(iconP2);
				iconBopsTotal % 2 == 0 * playbackRate ? {
					iconP1.scale.set(1.1, 0.8);
					iconP2.scale.set(1.1, 1.3);

					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				} : {
					iconP1.scale.set(1.1, 1.3);
					iconP2.scale.set(1.1, 0.8);

					FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				}

				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
			}
			if (ClientPrefs.data.iconBounceType == 'VS Steve') {
				FlxTween.cancelTweensOf(iconP1);
				FlxTween.cancelTweensOf(iconP2);
				if (iconBopsTotal % 2 == 0)
					{
					iconBopsTotal % 2 == 0 ?
					{
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});

					}

					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed / playbackRate, {ease: FlxEase.quadOut});
				}
			}
		}
		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if (OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray){ var script:Dynamic = cast(script);
				if (script.scriptName == luaToLoad)
					return false;}

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String, ?SvC = false)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if (FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad))
				return false;

			initHScript(scriptToLoad, SvC);
			return true;
		}
		return false;
	}

	public function initHScript(file:String, SvC = false)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			newScript.executeFunction('onCreate');
			if (SvC)
				newScript.executeFunction('registerSvCEffect');

			trace('initialized hscript interp successfully: $file');
			if (SvC)
				addTextToDebug('Initialized HScript as SVC Script: $file', FlxColor.GREEN);
			hscriptArray.push(newScript);
		}
		catch (e:Dynamic)
		{
			addTextToDebug('ERROR ON LOADING ($file) - $e', FlxColor.RED);
			var newScript:HScript = cast(Iris.instances.get(file), HScript);
			if (newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result))
			result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{ var script:Dynamic = cast(script);
			if (script.closed)
			{
				arr.push(script);
				continue;
			}

			if (exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if (script.closed)
				arr.push(script);
		}

		if (arr.length > 0)
			for (script in arr){ var script:Dynamic = cast(script);
				luaArray.remove(script);}
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:String = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = new Array();
		if (excludeValues == null)
			excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for (script in hscriptArray)
		{
			@:privateAccess
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			try
			{
				var callValue = script.call(funcToCall, args);
				var myValue:Dynamic = callValue.returnValue;

				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
					&& !excludeValues.contains(myValue)
					&& !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if (myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
			catch (e:Dynamic)
			{
				addTextToDebug('ERROR (${script.origin}: $funcToCall) - $e', FlxColor.RED);
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null)
			exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{ var script:Dynamic = cast(script);
			if (exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin))
				continue;

			if (!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = isDad ? opponentStrums.members[id] : playerStrums.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public function updateRatingCounter() {
		judgeCountUpdateFrame++;
		if (!judgementCounter.visible) return;

		formattedSongMisses = formatNumber(songMisses);
		formattedCombo = formatNumber(combo);
		formattedMaxCombo = formatNumber(maxCombo);
		formattedNPS = formatNumber(nps);
		formattedMaxNPS = formatNumber(maxNPS);
		formattedOppNPS = formatNumber(oppNPS);
		formattedMaxOppNPS = formatNumber(maxOppNPS);
		formattedEnemyHits = formatNumber(enemyHits);

		final hittingStuff = (!ClientPrefs.data.lessBotLag && ClientPrefs.data.showComboInfo && !cpuControlled ? 'Combo: $formattedCombo/${formattedMaxCombo}\n' : '') + 'Hits: ' + formatNumber(totalNotesPlayed) + ' / ' + formatNumber(totalNotes) + ' (' + FlxMath.roundDecimal((totalNotesPlayed/totalNotes) * 100, 2) + '%)';
		final ratingCountString = (!cpuControlled || cpuControlled && !ClientPrefs.data.lessBotLag ? '\n' + (!ClientPrefs.data.noPerfectJudge ? judgeCountStrings[0] + ': $perfects \n' : '') + judgeCountStrings[1] + ': $sicks \n' + judgeCountStrings[2] + ': $goods \n' + judgeCountStrings[3] + ': $bads \n' + judgeCountStrings[4] + ': $shits \n' + judgeCountStrings[5] + ': $formattedSongMisses ' : '');
		judgementCounter.text = hittingStuff + ratingCountString;
		judgementCounter.text += (ClientPrefs.data.showNPS ? '\nNPS: ' + formattedNPS + '/' + formattedMaxNPS : '');
		if (ClientPrefs.data.opponentRateCount) judgementCounter.text += '\n\nOpponent Hits: ' + formattedEnemyHits + ' / ' + formatNumber(opponentNoteTotal) + ' (' + FlxMath.roundDecimal((enemyHits / opponentNoteTotal) * 100, 2) + '%)'
		+ (ClientPrefs.data.showNPS ? '\nOpponent NPS: ' + formattedOppNPS + '/' + formattedMaxOppNPS : '');
	}

	public var ratingName:String = '?';
	public var ratingString:String;
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);
		if (badHit) missRecalcsPerFrame += 1;

		var ret:Dynamic = callOnScripts('onRecalculateRating');
		if(ret != LuaUtils.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

			if (Math.isNaN(ratingPercent))
				ratingString = '?';

				// Rating Name
				
				if (ratingStuff.length <= 0) // NOW it should fall back to this as a safe guard
				{
					ratingName = 'Error!';
					return;
				}
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

			/**
			 * - Rating FC and other stuff -
			 *
			 * > Now with better evaluation instead of using regular spaghetti code
			 *
			 * # @Equinoxtic was here, hi :3
			 */

			final fcConditions:Array<Bool> = [
				(totalPlayed == 0), // 'No Play'
				(perfects > 0), // 'PFC'
				(sicks > 0), // 'SFC'
				(goods > 0), // 'GFC'
				(bads > 0), // 'BFC'
				(shits > 0), // 'FC'
				(songMisses > 0 && songMisses < 10), // 'SDCB'
				(songMisses >= 10), // 'Clear'
				(songMisses >= 100), // 'TDCB'
				(songMisses >= 1000) // 'QDCB'
			];
			
			var cond:Int = fcConditions.length - 1;
			ratingFC = "";
			while (cond >= 0)
			{
				if (fcConditions[cond]) {
					ratingFC = fcStrings[cond];
					break;
				}
				cond--;
			}

			// basically same stuff, doesn't update every frame but it also means no memory leaks during botplay
			if (ClientPrefs.data.ratingCounter && judgementCounter != null)
				updateRatingCounter();
			if (scoreTxt != null)
				updateScore(badHit);
		}

		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode || trollingMode) return;

		var usedPractice:Bool = (practiceMode || cpuControlled);
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
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.globalAntialiasing);

					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.currentDifficulty.toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	var curLight:Int = -1;
	var curLightEvent:Int = -1;

	// Render mode stuff.. If SGWLC isn't ok with this I will remove it :thumbsup:

	public static var process:Process;
	var ffmpegExists:Bool = false;

	private function initRender():Void
	{
		if (!FileSystem.exists(#if linux 'ffmpeg' #else 'ffmpeg.exe' #end))
		{
			trace("\"FFmpeg\" not found! (Is it in the same folder as JSEngine?)");
			return;
		}

		if(!FileSystem.exists('assets/gameRenders/')) { //In case you delete the gameRenders folder
			trace ('gameRenders folder not found! Creating the gameRenders folder...');
            FileSystem.createDirectory('assets/gameRenders');
        }
		else
		if(!FileSystem.isDirectory('assets/gameRenders/')) {
			FileSystem.deleteFile('assets/gameRenders/');
			FileSystem.createDirectory('assets/gameRenders/');
		} 

		ffmpegExists = true;

		process = new Process('ffmpeg', ['-v', 'quiet', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', lime.app.Application.current.window.width + 'x' + lime.app.Application.current.window.height, '-r', Std.string(targetFPS), '-i', '-', '-c:v', ClientPrefs.data.vidEncoder, '-b', Std.string(ClientPrefs.data.renderBitrate * 1000000),  'assets/gameRenders/' + Paths.formatToSongPath(SONG.song) + '.mp4']);
		FlxG.autoPause = false;
	}

	private function pipeFrame():Void
	{
		if (!ffmpegExists || process == null)
		return;

		var img = lime.app.Application.current.window.readPixels(new lime.math.Rectangle(FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
		var bytes = img.getPixels(new lime.math.Rectangle(0, 0, img.width, img.height));
		process.stdin.writeBytes(bytes, 0, bytes.length);
	}

	public static function stopRender():Void
	{
		if (!ClientPrefs.data.ffmpegMode)
			return;

		if (process != null){
			if (process.stdin != null)
				process.stdin.close();

			process.close();
			process.kill();
		}

		FlxG.autoPause = ClientPrefs.data.autoPause;
	}
}
