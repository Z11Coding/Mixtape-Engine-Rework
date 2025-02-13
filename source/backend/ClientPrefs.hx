package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import states.TitleState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables {
	//General
	public var complexAccuracy:Bool = false;
	public var controllerMode:Bool = false;
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var ghostTapping:Bool = true;
	public var autoPause:Bool = true;
	public var startingSync:Bool = false;
	public var noPerfectJudge:Bool = false;
	public var noReset:Bool = false;
	public var antiCheatEnable:Bool = false;
	public var instaRestart:Bool = false;
	public var ezSpam:Bool = false;
	public var shitGivesMiss:Bool = false;
	public var ratingIntensity:String = 'Normal';
	public var spaceVPose:Bool = true;
	public var ghostTapAnim:Bool = true;
	public var hitsoundVolume:Float = 0;
	public var hitsoundType:String = 'osu!mania';
	public var voiidTrollMode:Bool = false;
	public var trollMaxSpeed:String = 'Medium';
	public var missSoundShit:Bool = false;

	//Visuals & UI
	public var noteSkin:String = 'Default';
	public var splashType:String = 'Default';
	public var noteSplashes:Bool = true;
	public var oppNoteSplashes:Bool = true;
	public var showNPS:Bool = true;
	public var showComboInfo:Bool = true;
	public var maxSplashLimit:Int = 16;
	public var oppNoteAlpha:Float = 0.65;
	public var hideHud:Bool = false;
	public var tauntOnGo:Bool = true;
	public var oldSusStyle:Bool = false;
	public var showRendered:Bool = false;
	public var showcaseMode:Bool = false;
	public var showcaseST:String = 'JS';
	public var timeBounce:Bool = true;
	public var lengthIntro:Bool = true;
	public var timebarShowSpeed:Bool = false;
	public var botWatermark:Bool = true;
	public var missRating:Bool = false;
	public var scoreTxtSize:Int = 0;
	public var noteColorStyle:String = 'Normal';
	public var enableColorShader:Bool = true;
	public var iconBopWhen:String = 'Every Beat';
	public var cameraPanning:Bool = true;
	public var panIntensity:Float = 1;
	public var rateNameStuff:String = 'Quotes';
	public var timeBarType:String = 'Time Left';
	public var scoreStyle:String = 'Psych Engine';
	public var timeBarStyle:String = 'Vanilla';
	public var healthBarStyle:String = 'Vanilla';
	public var watermarkStyle:String = 'Vanilla';
	public var botTxtStyle:String = 'Vanilla';
	public var ytWatermarkPosition:String = 'Hidden';
	public var strumLitStyle:String = 'Full Anim';
	public var bfIconStyle:String = 'Default';
	public var ratingType:String = 'Base FNF';
	public var simplePopups:Bool = false;
	public var iconBounceType:String = 'Golden Apple';
	public var colorRatingHit:Bool = true;
	public var smoothHealth:Bool = true;
	public var smoothHPBug:Bool = false;
	public var noBopLimit:Bool = false;
	public var ogHPColor:Bool = false;
	public var opponentRateCount:Bool = true;
	public var flashing:Bool = true;
	public var camZooms:Bool = true;
	public var ratingCounter:Bool = false;
	public var showNotes:Bool = true;
	public var scoreZoom:Bool = true;
	public var healthBarAlpha:Float = 1;
	public var laneUnderlay:Bool = false;
	public var laneUnderlayAlpha:Float = 1;
	public var showFPS:Bool = true;
	public var randomBotplayText:Bool = true;
	public var botTxtFade:Bool = true;
	public var pauseMusic:String = 'Tea Time';
	public var daMenuMusic:String = 'Default';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = false;
	public var showRamUsage:Bool = true;
	public var showMaxRamUsage:Bool = true;
	public var debugInfo:Bool = false;
	public var tipTexts:Bool = true;
	public var discordRPC:Bool = true;

	
	//Graphics
	public var lowQuality:Bool = false;
	public var globalAntialiasing:Bool = true;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = true;
	public var dynamicSpawnTime:Bool = false;
	public var noteSpawnTime:Float = 1;
	public var resolution:String = '1280x720';
	public var framerate:Int = 60;

	//Optimization
	public var charsAndBG:Bool = true;
	public var enableGC:Bool = true;
	public var opponentLightStrum:Bool = true;
	public var botLightStrum:Bool = true;
	public var playerLightStrum:Bool = true;
	public var ratingPopups:Bool = true;
	public var comboPopups:Bool = true;
	public var showMS:Bool = false;
	public var noSpawnFunc:Bool = false;
	public var noHitFuncs:Bool = false;
	public var noSkipFuncs:Bool = false;
	public var lessBotLag:Bool = false;
	public var fastNoteSpawn:Bool = false;

	//Secret Debug
	public var noGunsRNG:Bool = false;
	public var pbRControls:Bool = false;
	public var rainbowFPS:Bool = false;
	public var noRenderGC:Bool = false;

	//Unused
	public var cursing:Bool = true;
	public var autosaveCharts:Bool = true;
	public var violence:Bool = true;
	public var crossFadeData:Array<Dynamic> = ['Default', 'Healthbar', [255, 255, 255], 0.3, 0.35];
	public var noPausing:Bool = false;

	//Mixtape Engine Stuff
	public var showCrash:Bool = true;
	public var ignoreTweenErrors:Bool = false;
	public var allowForcedExit:Bool = true;
	public var gamePriority:Int = 2;
	public var silentVol:Bool = false;
	public var noParticles:Bool = false;
	public var modcharts:Bool = true;
	public var loadCustomNoteGraphicschartEditor:Bool = false;
	public var forcePriority:Bool = false;
	public var username:Bool = false;
	public var doubleGhosts:Bool = true;
	public var noAntimash:Bool = false;
	public var gimmicksAllowed:Bool = true;
	public var drawDistanceModifier:Float = 1;
	public var holdSubdivs:Float = 2;
	public var optimizeHolds:Bool = true;
	public var inGameRatings:Bool = false;
	public var enableArtemis:Bool = false;
	public var mixupMode:Bool = false;
	public var aiDifficulty:String = 'Average FNF Player';
	public var loadingThreads:Int = Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")) / 2);
	public var multicoreLoading:Bool = false;
	public var showKeybindsOnStart:Bool = false;
	public var antimash:Bool = false;
	public var uiSkin:String = 'Mixtape Engine';
	public var drain:Bool = true;
	//Compatibility Sake
	public var arrowHSV:Array<Array<Int>> = [
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0],
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0]
	];
	public var pauseBPM:Int = 105;
	public var convertEK:Bool = true;
	public var startHidden:Bool = false;
	public var inputSystem:String = 'Native';
	public var volUp:String = 'Volup';
	public var volDown:String = 'Voldown';
	public var volMax:String = 'VolMAX';
	public var useMarvs:Bool = true;
	public var guitarHeroSustains:Bool = true;
	public var audioBreak:Bool = false;
	public var loadingScreen:Bool = true;
	public var language:String = 'en-US';

	//Arcipelago stuff
	public var notePopup:Bool = true;
	public var deathlink:Bool = true;

	//Note Colors
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];

	public var arrowRGBExtra:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
		[0xFFb6b6b6, 0xFFFFFFFF, 0xFF444444],
		[0xFFffd94a, 0xFFfffff9, 0xFF663500],
		[0xFFB055BC, 0xFFf4f4ff, 0xFF4D0060],
		[0xFFdf3e23, 0xFFffe6e9, 0xFF440000],
		[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D],
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
		[0xFFb6b6b6, 0xFFFFFFFF, 0xFF444444],
		[0xFFffd94a, 0xFFfffff9, 0xFF663500],
		[0xFFB055BC, 0xFFf4f4ff, 0xFF4D0060],
		[0xFFdf3e23, 0xFFffe6e9, 0xFF440000],
		[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D]
	];

	//Pixel
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	public var arrowRGBPixelExtra:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000],
		[0xFFb6b6b6, 0xFFFFFFFF, 0xFF444444],
		[0xFFffd94a, 0xFFfffff9, 0xFF663500],
		[0xFFB055BC, 0xFFf4f4ff, 0xFF4D0060],
		[0xFFdf3e23, 0xFFffe6e9, 0xFF440000],
		[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D],
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000],
		[0xFFb6b6b6, 0xFFFFFFFF, 0xFF444444],
		[0xFFffd94a, 0xFFfffff9, 0xFF663500],
		[0xFFB055BC, 0xFFf4f4ff, 0xFF4D0060],
		[0xFFdf3e23, 0xFFffe6e9, 0xFF440000],
		[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D]
	];

	//Quants
	public var quantRGB:Array<Array<FlxColor>> = [
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038], //4th
		[0xFF3A48F5, 0xFFFFFFFF, 0xFF0C3D60], //8th
		[0xFFB200FF, 0xFFFFFFFF, 0xFF57007F], //12th
		[0xFFFFD800, 0xFFFFFFFF, 0xFF4D4100], //16th
		[0xFFFF00DC, 0xFFFFFFFF, 0xFF740066], //24th
		[0xFFFF6A00, 0xFFFFFFFF, 0xFF652800], //32nd
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF004B5E], //48th
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447], //64th
		[0xFFFF7F7F, 0xFFFFFFFF, 0xFF592C2C], //96th
		[0xFFD67FFF, 0xFFFFFFFF, 0xFF5F3870], //128th
		[0xFF00FF90, 0xFFFFFFFF, 0xFF003921], //192nd
		[0xFF7F3300, 0xFFFFFFFF, 0xFF401800], //256th
		[0xFF007F0E, 0xFFFFFFFF, 0xFF003404], //384th
		[0xFF230093, 0xFFFFFFFF, 0xFF0F0043], //512th
		[0xFFE7E7E7, 0xFFFFFFFF, 0xFF2A2A2A], //768th
		[0xFF00AB64, 0xFFFFFFFF, 0xFF00321E], //1024th
		[0xFF000000, 0xFFFFFFFF, 0xFF000000], //1536th
		[0xFFA69C52, 0xFFFFFFFF, 0xFF2F2D17], //2048th
		[0xFFFFF9AB, 0xFFFFFFFF, 0xFF45442F], //3072nd
		[0xFFFF6A00, 0xFFFFFFFF, 0xFF652800] //6144th
	];

	// Game Renderer
	public var ffmpegMode:Bool = false;
	public var ffmpegInfo:String = 'None';
	public var targetFPS:Float = 60;
	public var unlockFPS:Bool = false;
	public var renderBitrate:Float = 5.0;
	public var vidEncoder:String = 'libx264';
	public var oldFFmpegMode:Bool = false;
	public var lossless:Bool = false;
	public var quality:Int = 50;
	public var renderGCRate:Float = 5.0;
	public var showRemainingTime:Bool = false;

	//Misc
	public var JSEngineRecharts:Bool = false;
	public var alwaysTriggerCutscene:Bool = false;
	public var disableSplash:Bool = false;
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'randomspeedchange' => false,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'chartModifier' => 'Normal',
		'convertMania' => 3,
		'instakill' => false,
		'onlySicks' => false,
		'practice' => false,
		'botplay' => false,
		'randommode' => false,
		'opponentplay' => false,
		'bothSides' => false,
		'opponentdrain' => false,
		'drainlevel' => 1,
		'randomspeed' => false,
		'randomspeedmin' => 0.5,
		'randomspeedmax' => 2,
		'thetrollingever' => false,
		'showcase' => false,
		'gfMode' => false,
		'aiMode' => false,
		'aiDifficulty' => 5,
		'loopMode' => false,
		'loopModeC' => false,
		'loopPlayMult' => 1.05,
		'bothMode' => false,
	];

	//Gameplay Offset and Window stuff
	public var ratingOffset:Int = 0;
	public var perfectWindow:Int = 15;
	public var marvelousWindow:Int = 22;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var noteOffset:Int = 0;

	public function new()
	{
		//Why does haxe needs this again?
	}
}
class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	public static var showKeybindsOnStart:Bool = true;

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;
	public static var defaultArrowRGB:Array<Array<FlxColor>>;
	public static var defaultPixelRGB:Array<Array<FlxColor>>;
	public static var defaultArrowRGBExtra:Array<Array<FlxColor>>;
	public static var defaultPixelRGBExtra:Array<Array<FlxColor>>;
	public static var defaultQuantRGB:Array<Array<FlxColor>>;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_one1' 	=> [SPACE, NONE],
		
		'note_two1' 	=> [D, NONE],
		'note_two2' 	=> [K, NONE],

		'note_three1' 	=> [D, NONE],
		'note_three2' 	=> [SPACE, NONE],
		'note_three3' 	=> [K, NONE],

		'note_left' 	=> [A, LEFT],
		'note_down' 	=> [S, DOWN],
		'note_up' 		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'note_five1' 	=> [D, NONE],
		'note_five2' 	=> [F, NONE],
		'note_five3' 	=> [SPACE, NONE],
		'note_five4' 	=> [J, NONE],
		'note_five5' 	=> [K, NONE],

		'note_six1' 	=> [S, NONE],
		'note_six2' 	=> [D, NONE],
		'note_six3' 	=> [F, NONE],
		'note_six4' 	=> [J, NONE],
		'note_six5' 	=> [K, NONE],
		'note_six6' 	=> [L, NONE],

		'note_seven1' 	=> [S, NONE],
		'note_seven2' 	=> [D, NONE],
		'note_seven3' 	=> [F, NONE],
		'note_seven4' 	=> [SPACE, NONE],
		'note_seven5' 	=> [J, NONE],
		'note_seven6' 	=> [K, NONE],
		'note_seven7' 	=> [L, NONE],

		'note_eight1' 	=> [A, NONE],
		'note_eight2' 	=> [S, NONE],
		'note_eight3' 	=> [D, NONE],
		'note_eight4' 	=> [F, NONE],
		'note_eight5' 	=> [H, NONE],
		'note_eight6' 	=> [J, NONE],
		'note_eight7' 	=> [K, NONE],
		'note_eight8' 	=> [L, NONE],

		'note_nine1' 	=> [A, NONE],
		'note_nine2' 	=> [S, NONE],
		'note_nine3' 	=> [D, NONE],
		'note_nine4' 	=> [F, NONE],
		'note_nine5' 	=> [SPACE, NONE],
		'note_nine6' 	=> [H, NONE],
		'note_nine7' 	=> [J, NONE],
		'note_nine8' 	=> [K, NONE],
		'note_nine9' 	=> [L, NONE],

		'note_ten1' 	=> [A, NONE],
		'note_ten2' 	=> [S, NONE],
		'note_ten3' 	=> [D, NONE],
		'note_ten4' 	=> [F, NONE],
		'note_ten5' 	=> [G, NONE],
		'note_ten6' 	=> [SPACE, NONE],
		'note_ten7' 	=> [H, NONE],
		'note_ten8' 	=> [J, NONE],
		'note_ten9' 	=> [K, NONE],
		'note_ten10' 	=> [L, NONE],

		'note_elev1' 	=> [A, NONE],
		'note_elev2' 	=> [S, NONE],
		'note_elev3' 	=> [D, NONE],
		'note_elev4' 	=> [F, NONE],
		'note_elev5' 	=> [G, NONE],
		'note_elev6' 	=> [SPACE, NONE],
		'note_elev7' 	=> [H, NONE],
		'note_elev8' 	=> [J, NONE],
		'note_elev9' 	=> [K, NONE],
		'note_elev10' 	=> [L, NONE],
		'note_elev11' 	=> [PERIOD, NONE],

		'note_twel1' 	=> [Z, NONE],
		'note_twel2' 	=> [X, NONE],
		'note_twel3' 	=> [N, NONE],
		'note_twel4' 	=> [M, NONE],
		'note_twel5' 	=> [Q, NONE],
		'note_twel6' 	=> [W, NONE],
		'note_twel7' 	=> [O, NONE],
		'note_twel8' 	=> [P, NONE],
		'note_twel9' 	=> [D, NONE],
		'note_twel10' 	=> [F, NONE],
		'note_twel11' 	=> [J, NONE],
		'note_twel12' 	=> [K, NONE],

		'note_thir1' 	=> [A, NONE],
		'note_thir2'	=> [S, NONE],
		'note_thir3'	=> [D, NONE],
		'note_thir4'	=> [F, NONE],
		'note_thir5'	=> [C, NONE],
		'note_thir6'	=> [V, NONE],
		'note_thir7'	=> [SPACE, NONE],
		'note_thir8'	=> [N, NONE],
		'note_thir9'    => [M, NONE],
		'note_thir10'	=> [H, NONE],
		'note_thir11'	=> [J, NONE],
		'note_thir12'	=> [K, NONE],
		'note_thir13'	=> [L, NONE],

		'note_fort1' 	=> [A, NONE],
		'note_fort2' 	=> [S, NONE],
		'note_fort3' 	=> [D, NONE],
		'note_fort4' 	=> [F, NONE],
		'note_fort5' 	=> [SPACE, NONE],
		'note_fort6' 	=> [G, NONE],
		'note_fort7' 	=> [H, NONE],
		'note_fort8' 	=> [J, NONE],
		'note_fort9' 	=> [K, NONE],
		'note_fort10' 	=> [B, NONE],
		'note_fort11' 	=> [Z, NONE],
		'note_fort12' 	=> [X, NONE],
		'note_fort13' 	=> [C, NONE],
		'note_fort14' 	=> [V, NONE],

		'note_fift1'	=> [A, NONE],
		'note_fift2'	=> [S, NONE],
		'note_fift3'	=> [D, NONE],
		'note_fift4'	=> [F, NONE],
		'note_fift5'	=> [C, NONE],
		'note_fift6'	=> [V, NONE],
		'note_fift7'	=> [T, NONE],
		'note_fift8'  	=> [Y, NONE],
		'note_fift9' 	 => [U, NONE],
		'note_fift10'	=> [N, NONE],
		'note_fift11'	=> [M, NONE],
		'note_fift12'	=> [H, NONE],
		'note_fift13'	=> [J, NONE],
		'note_fift14'	=> [K, NONE],
		'note_fift15'	=> [L, NONE],

		'note_sixt1'	=> [A, NONE],
		'note_sixt2'	=> [S, NONE],
		'note_sixt3'	=> [D, NONE],
		'note_sixt4'	=> [F, NONE],
		'note_sixt5'	=> [Q, NONE],
		'note_sixt6'	=> [W, NONE],
		'note_sixt7'	=> [E, NONE],
		'note_sixt8'  	=> [R, NONE],
		'note_sixt9'  	=> [Y, NONE],
		'note_sixt10'	=> [U, NONE],
		'note_sixt11'	=> [I, NONE],
		'note_sixt12'	=> [O, NONE],
		'note_sixt13'	=> [H, NONE],
		'note_sixt14'	=> [J, NONE],
		'note_sixt15'	=> [K, NONE],
		'note_sixt16'	=> [L, NONE],

		'note_sevt1'	=> [A, NONE],
		'note_sevt2'	=> [S, NONE],
		'note_sevt3'	=> [D, NONE],
		'note_sevt4'	=> [F, NONE],
		'note_sevt5'	=> [Q, NONE],
		'note_sevt6'	=> [W, NONE],
		'note_sevt7'	=> [E, NONE],
		'note_sevt8'  	=> [R, NONE],
		'note_sevt9'	=> [SPACE, NONE],
		'note_sevt10' 	=> [Y, NONE],
		'note_sevt11'	=> [U, NONE],
		'note_sevt12'	=> [I, NONE],
		'note_sevt13'	=> [O, NONE],
		'note_sevt14'	=> [H, NONE],
		'note_sevt15'	=> [J, NONE],
		'note_sevt16'	=> [K, NONE],
		'note_sevt17'	=> [L, NONE],

		'note_ate1' 	=> [Q, NONE],
		'note_ate2' 	=> [W, NONE],
		'note_ate3' 	=> [E, NONE],
		'note_ate4' 	=> [R, NONE],
		'note_ate5' 	=> [A, NONE],
		'note_ate6' 	=> [S, NONE],
		'note_ate7' 	=> [D, NONE],
		'note_ate8' 	=> [F, NONE],
		'note_ate9' 	=> [V, NONE],
		'note_ate10' 	=> [B, NONE],
		'note_ate11' 	=> [H, NONE],
		'note_ate12' 	=> [J, NONE],
		'note_ate13' 	=> [K, NONE],
		'note_ate14' 	=> [L, NONE],
		'note_ate15' 	=> [U, NONE],
		'note_ate16' 	=> [I, NONE],
		'note_ate17' 	=> [O, NONE],
		'note_ate18' 	=> [P, NONE],

		'dodge'			=> [SPACE, SPACE],
		'bot_energy'	=> [CONTROL, NONE],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, DELETE],
		
		'volume_mute'	=> [ZERO, NUMPADZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT],
		'qt_taunt'		=> [SPACE, NONE],

		'fullscreen'	=> [F11],
		'sidebar'		=> [GRAVEACCENT],
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK],

		'sidebar'		=> [NONE, NONE],
		'qt_taunt'		=> [NONE, NONE],
	];

	public static function getKeyBindsForKeys(numKeys:Int):Array<Array<FlxKey>> {
		var keyBindsList:Array<Array<FlxKey>> = [];
		switch (numKeys) {
			case 1:
				keyBindsList.push(keyBinds.get('note_one1'));
			case 2:
				keyBindsList.push(keyBinds.get('note_two1'));
				keyBindsList.push(keyBinds.get('note_two2'));
			case 3:
				keyBindsList.push(keyBinds.get('note_three1'));
				keyBindsList.push(keyBinds.get('note_three2'));
				keyBindsList.push(keyBinds.get('note_three3'));
			case 4:
				keyBindsList.push(keyBinds.get('note_left'));
				keyBindsList.push(keyBinds.get('note_down'));
				keyBindsList.push(keyBinds.get('note_up'));
				keyBindsList.push(keyBinds.get('note_right'));
			case 5:
				keyBindsList.push(keyBinds.get('note_five1'));
				keyBindsList.push(keyBinds.get('note_five2'));
				keyBindsList.push(keyBinds.get('note_five3'));
				keyBindsList.push(keyBinds.get('note_five4'));
				keyBindsList.push(keyBinds.get('note_five5'));
			case 6:
				keyBindsList.push(keyBinds.get('note_six1'));
				keyBindsList.push(keyBinds.get('note_six2'));
				keyBindsList.push(keyBinds.get('note_six3'));
				keyBindsList.push(keyBinds.get('note_six4'));
				keyBindsList.push(keyBinds.get('note_six5'));
				keyBindsList.push(keyBinds.get('note_six6'));
			case 7:
				keyBindsList.push(keyBinds.get('note_seven1'));
				keyBindsList.push(keyBinds.get('note_seven2'));
				keyBindsList.push(keyBinds.get('note_seven3'));
				keyBindsList.push(keyBinds.get('note_seven4'));
				keyBindsList.push(keyBinds.get('note_seven5'));
				keyBindsList.push(keyBinds.get('note_seven6'));
				keyBindsList.push(keyBinds.get('note_seven7'));
			case 8:
				keyBindsList.push(keyBinds.get('note_eight1'));
				keyBindsList.push(keyBinds.get('note_eight2'));
				keyBindsList.push(keyBinds.get('note_eight3'));
				keyBindsList.push(keyBinds.get('note_eight4'));
				keyBindsList.push(keyBinds.get('note_eight5'));
				keyBindsList.push(keyBinds.get('note_eight6'));
				keyBindsList.push(keyBinds.get('note_eight7'));
				keyBindsList.push(keyBinds.get('note_eight8'));
			case 9:
				keyBindsList.push(keyBinds.get('note_nine1'));
				keyBindsList.push(keyBinds.get('note_nine2'));
				keyBindsList.push(keyBinds.get('note_nine3'));
				keyBindsList.push(keyBinds.get('note_nine4'));
				keyBindsList.push(keyBinds.get('note_nine5'));
				keyBindsList.push(keyBinds.get('note_nine6'));
				keyBindsList.push(keyBinds.get('note_nine7'));
				keyBindsList.push(keyBinds.get('note_nine8'));
				keyBindsList.push(keyBinds.get('note_nine9'));
			case 10:
				keyBindsList.push(keyBinds.get('note_ten1'));
				keyBindsList.push(keyBinds.get('note_ten2'));
				keyBindsList.push(keyBinds.get('note_ten3'));
				keyBindsList.push(keyBinds.get('note_ten4'));
				keyBindsList.push(keyBinds.get('note_ten5'));
				keyBindsList.push(keyBinds.get('note_ten6'));
				keyBindsList.push(keyBinds.get('note_ten7'));
				keyBindsList.push(keyBinds.get('note_ten8'));
				keyBindsList.push(keyBinds.get('note_ten9'));
				keyBindsList.push(keyBinds.get('note_ten10'));
			case 11:
				keyBindsList.push(keyBinds.get('note_elev1'));
				keyBindsList.push(keyBinds.get('note_elev2'));
				keyBindsList.push(keyBinds.get('note_elev3'));
				keyBindsList.push(keyBinds.get('note_elev4'));
				keyBindsList.push(keyBinds.get('note_elev5'));
				keyBindsList.push(keyBinds.get('note_elev6'));
				keyBindsList.push(keyBinds.get('note_elev7'));
				keyBindsList.push(keyBinds.get('note_elev8'));
				keyBindsList.push(keyBinds.get('note_elev9'));
				keyBindsList.push(keyBinds.get('note_elev10'));
				keyBindsList.push(keyBinds.get('note_elev11'));
			case 12:
				keyBindsList.push(keyBinds.get('note_twel1'));
				keyBindsList.push(keyBinds.get('note_twel2'));
				keyBindsList.push(keyBinds.get('note_twel3'));
				keyBindsList.push(keyBinds.get('note_twel4'));
				keyBindsList.push(keyBinds.get('note_twel5'));
				keyBindsList.push(keyBinds.get('note_twel6'));
				keyBindsList.push(keyBinds.get('note_twel7'));
				keyBindsList.push(keyBinds.get('note_twel8'));
				keyBindsList.push(keyBinds.get('note_twel9'));
				keyBindsList.push(keyBinds.get('note_twel10'));
				keyBindsList.push(keyBinds.get('note_twel11'));
				keyBindsList.push(keyBinds.get('note_twel12'));
			case 13:
				keyBindsList.push(keyBinds.get('note_thir1'));
				keyBindsList.push(keyBinds.get('note_thir2'));
				keyBindsList.push(keyBinds.get('note_thir3'));
				keyBindsList.push(keyBinds.get('note_thir4'));
				keyBindsList.push(keyBinds.get('note_thir5'));
				keyBindsList.push(keyBinds.get('note_thir6'));
				keyBindsList.push(keyBinds.get('note_thir7'));
				keyBindsList.push(keyBinds.get('note_thir8'));
				keyBindsList.push(keyBinds.get('note_thir9'));
				keyBindsList.push(keyBinds.get('note_thir10'));
				keyBindsList.push(keyBinds.get('note_thir11'));
				keyBindsList.push(keyBinds.get('note_thir12'));
				keyBindsList.push(keyBinds.get('note_thir13'));
			case 14:
				keyBindsList.push(keyBinds.get('note_fort1'));
				keyBindsList.push(keyBinds.get('note_fort2'));
				keyBindsList.push(keyBinds.get('note_fort3'));
				keyBindsList.push(keyBinds.get('note_fort4'));
				keyBindsList.push(keyBinds.get('note_fort5'));
				keyBindsList.push(keyBinds.get('note_fort6'));
				keyBindsList.push(keyBinds.get('note_fort7'));
				keyBindsList.push(keyBinds.get('note_fort8'));
				keyBindsList.push(keyBinds.get('note_fort9'));
				keyBindsList.push(keyBinds.get('note_fort10'));
				keyBindsList.push(keyBinds.get('note_fort11'));
				keyBindsList.push(keyBinds.get('note_fort12'));
				keyBindsList.push(keyBinds.get('note_fort13'));
				keyBindsList.push(keyBinds.get('note_fort14'));
			case 15:
				keyBindsList.push(keyBinds.get('note_fift1'));
				keyBindsList.push(keyBinds.get('note_fift2'));
				keyBindsList.push(keyBinds.get('note_fift3'));
				keyBindsList.push(keyBinds.get('note_fift4'));
				keyBindsList.push(keyBinds.get('note_fift5'));
				keyBindsList.push(keyBinds.get('note_fift6'));
				keyBindsList.push(keyBinds.get('note_fift7'));
				keyBindsList.push(keyBinds.get('note_fift8'));
				keyBindsList.push(keyBinds.get('note_fift9'));
				keyBindsList.push(keyBinds.get('note_fift10'));
				keyBindsList.push(keyBinds.get('note_fift11'));
				keyBindsList.push(keyBinds.get('note_fift12'));
				keyBindsList.push(keyBinds.get('note_fift13'));
				keyBindsList.push(keyBinds.get('note_fift14'));
				keyBindsList.push(keyBinds.get('note_fift15'));
			case 16:
				keyBindsList.push(keyBinds.get('note_sixt1'));
				keyBindsList.push(keyBinds.get('note_sixt2'));
				keyBindsList.push(keyBinds.get('note_sixt3'));
				keyBindsList.push(keyBinds.get('note_sixt4'));
				keyBindsList.push(keyBinds.get('note_sixt5'));
				keyBindsList.push(keyBinds.get('note_sixt6'));
				keyBindsList.push(keyBinds.get('note_sixt7'));
				keyBindsList.push(keyBinds.get('note_sixt8'));
				keyBindsList.push(keyBinds.get('note_sixt9'));
				keyBindsList.push(keyBinds.get('note_sixt10'));
				keyBindsList.push(keyBinds.get('note_sixt11'));
				keyBindsList.push(keyBinds.get('note_sixt12'));
				keyBindsList.push(keyBinds.get('note_sixt13'));
				keyBindsList.push(keyBinds.get('note_sixt14'));
				keyBindsList.push(keyBinds.get('note_sixt15'));
				keyBindsList.push(keyBinds.get('note_sixt16'));
			case 17:
				keyBindsList.push(keyBinds.get('note_sevt1'));
				keyBindsList.push(keyBinds.get('note_sevt2'));
				keyBindsList.push(keyBinds.get('note_sevt3'));
				keyBindsList.push(keyBinds.get('note_sevt4'));
				keyBindsList.push(keyBinds.get('note_sevt5'));
				keyBindsList.push(keyBinds.get('note_sevt6'));
				keyBindsList.push(keyBinds.get('note_sevt7'));
				keyBindsList.push(keyBinds.get('note_sevt8'));
				keyBindsList.push(keyBinds.get('note_sevt9'));
				keyBindsList.push(keyBinds.get('note_sevt10'));
				keyBindsList.push(keyBinds.get('note_sevt11'));
				keyBindsList.push(keyBinds.get('note_sevt12'));
				keyBindsList.push(keyBinds.get('note_sevt13'));
				keyBindsList.push(keyBinds.get('note_sevt14'));
				keyBindsList.push(keyBinds.get('note_sevt15'));
				keyBindsList.push(keyBinds.get('note_sevt16'));
				keyBindsList.push(keyBinds.get('note_sevt17'));
			case 18:
				keyBindsList.push(keyBinds.get('note_ate1'));
				keyBindsList.push(keyBinds.get('note_ate2'));
				keyBindsList.push(keyBinds.get('note_ate3'));
				keyBindsList.push(keyBinds.get('note_ate4'));
				keyBindsList.push(keyBinds.get('note_ate5'));
				keyBindsList.push(keyBinds.get('note_ate6'));
				keyBindsList.push(keyBinds.get('note_ate7'));
				keyBindsList.push(keyBinds.get('note_ate8'));
				keyBindsList.push(keyBinds.get('note_ate9'));
				keyBindsList.push(keyBinds.get('note_ate10'));
				keyBindsList.push(keyBinds.get('note_ate11'));
				keyBindsList.push(keyBinds.get('note_ate12'));
				keyBindsList.push(keyBinds.get('note_ate13'));
				keyBindsList.push(keyBinds.get('note_ate14'));
				keyBindsList.push(keyBinds.get('note_ate15'));
				keyBindsList.push(keyBinds.get('note_ate16'));
				keyBindsList.push(keyBinds.get('note_ate17'));
				keyBindsList.push(keyBinds.get('note_ate18'));
			default:
				trace('Invalid number of keys: ' + numKeys);
		}
		return keyBindsList;
	}

	
	//i suck at naming things sorry
	private static var importantMap:Map<String, Array<String>> = [
		"saveBlackList" => ["keyBinds", "defaultKeys"],
		"flixelSound" => ["volume", "sound"],
		"loadBlackList" => ["keyBinds", "defaultKeys"],
	];

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
		{
			for (key in keyBinds.keys())
			{
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());
			}
		}
		if(controller != false)
		{
			for (button in gamepadBinds.keys())
			{
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
			}
		}
	}

	public static function clearInvalidKeys(key:String) {
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function loadDefaultStuff() {
		loadDefaultKeys();
		defaultArrowRGB = defaultData.arrowRGB.copy();
		defaultPixelRGB = defaultData.arrowRGBPixel.copy();
		defaultArrowRGBExtra = defaultData.arrowRGBExtra.copy();
		defaultPixelRGBExtra = defaultData.arrowRGBPixelExtra.copy();
		defaultQuantRGB = defaultData.quantRGB.copy();
	}

	public static function saveSettings() {
		for (field in Reflect.fields(data))
		{
			if (Type.typeof(Reflect.field(data, field)) != TFunction)
			{
				if (!importantMap.get("saveBlackList").contains(field))
					Reflect.setField(FlxG.save.data, field, Reflect.field(data, field));
			}
		}

		for (flixelS in importantMap.get("flixelSound"))
			Reflect.setField(FlxG.save.data, flixelS, Reflect.field(FlxG.sound, flixelS));

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for (field in Reflect.fields(data))
		{
			if (Type.typeof(Reflect.field(data, field)) != TFunction)
			{
				if (!importantMap.get("loadBlackList").contains(field))
				{
					var defaultValue:Dynamic = Reflect.field(data, field);
					var flxProp:Dynamic = Reflect.field(FlxG.save.data, field);
					Reflect.setField(data, field, (flxProp != null ? flxProp : defaultValue));

					if (field == "showFPS" && Main.fpsVar != null)
						Main.fpsVar.visible = data.showFPS;

					if (field == "framerate")
					{
						if (data.framerate > FlxG.drawFramerate)
						{
							FlxG.updateFramerate = data.framerate;
							FlxG.drawFramerate = data.framerate;
						}
						else
						{
							FlxG.drawFramerate = data.framerate;
							FlxG.updateFramerate = data.framerate;
						}
					}
				}
			}
		}

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end

		if(data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else
		{
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED DiscordClient.check(); #end

		if (FlxG.save.data.loadingThreads != null)
		{
			data.loadingThreads = FlxG.save.data.loadingThreads;
			if (data.loadingThreads > Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS"))))
			{
				data.loadingThreads = Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")));
				FlxG.save.data.loadingThreads = data.loadingThreads;
			}
		}

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		if(save != null)
		{
			if(save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
			}
			if(save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys() {
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final emptyArray = [];
		FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : emptyArray;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}