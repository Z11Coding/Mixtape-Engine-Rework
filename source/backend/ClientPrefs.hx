package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.FirstCheckState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables {
	public var showCrash:Bool = true;
	public var downScroll:Bool = false;
	public var silentVol:Bool = false;
	public var noParticles:Bool = false;
	public var modcharts:Bool = true;
	public var loadCustomNoteGraphicschartEditor:Bool = false;
	public var musicPreload2:Bool = false;
	public var graphicsPreload2:Bool = false;
	public var experimentalCaching:Bool = false;
	public var saveCache:Bool = false;
	public var cacheCharts:Bool = false;
	public var shaders:Bool = true;
	public var autoPause:Bool = true;
	public var drain:Bool = true;
	public var username:Bool = false;
	public var beatSky:Bool = false;
	public var middleScroll:Bool = false;
	public var showFPS:Bool = true;
	public var flashing:Bool = true;
	public var globalAntialiasing:Bool = true;
	public var noteSplashes:Bool = true;
	public var lowQuality:Bool = false;
	public var framerate:Int = 60;
	public var cursing:Bool = true;
	public var violence:Bool = true;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var wife3:Bool = true;
	public var cacheOnGPU:Bool = false;
	public var checkForUpdates:Bool = true;
	public var gimmicksAllowed:Bool = true;
	public var opponentStrums:Bool = true;
	public var drawDistanceModifier:Float = 1;
	public var holdSubdivs:Float = 2;
	public var optimizeHolds:Bool = true;
	public var gotit:Bool = false;
	public var inGameRatings:Bool = false;
	public var noteOffset:Int = 0;
	public var progression:Int = 0;
	public var videoPreload2:Bool = false;
	public var enableArtemis:Bool = false;
	public var mixupMode:Bool = false;
	public var aiDifficulty:String = 'Average FNF Player';
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
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]];

	public var arrowRGBExtra:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
		[0xFF999999, 0xFFFFFFFF, 0xFF201E31],
		[0xFFFFFF00, 0xFFFFFFFF, 0xFF993300],
		[0xFF8b4aff, 0xFFFFFFFF, 0xFF3b177d],
		[0xFFFF0000, 0xFFFFFFFF, 0xFF660000],
		[0xFF0033ff, 0xFFFFFFFF, 0xFF000066]];
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
		[0xFF2F69E5, 0xFFf5f5ff, 0xFF000F5D]];
	public var imagesPersist:Bool = false;
	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var controllerMode:Bool = false;
	public var comboStacking:Bool = false;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var uiSkin:String = 'Mixtape Engine';
	public var noteSkin:String = 'Default';
	public var pauseBPM:Int = 105;
	public var antimash:Bool = true;
	public var convertEK:Bool = true;
	public var showKeybindsOnStart:Bool = true;
	public var starHidden:Bool = false;
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
		'practice' => false,
		'botplay' => false,
		'showcase' => false,
		'gfMode' => false,
		'opponentplay' => false,
		'aiMode' => false,
		'aiDifficulty' => 5,
		'loopMode' => false,
		'loopModeC' => false,
		'loopPlayMult' => 1.05,
		'bothMode' => false,
	];
	public var inputSystem:String = 'Native';
	public var volUp:String = 'Volup';
	public var volDown:String = 'Voldown';
	public var volMax:String = 'VolMAX';

	public var comboOffset:Array<Int> = [0, 0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public var marvWindow:Int = 22;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var useMarvs:Bool = true;
	public var guitarHeroSustains:Bool = true;
	public var discordRPC:Bool = true;
	public var audioBreak:Bool = false;
	public var loadingScreen:Bool = true;
	public var language:String = 'en-US';

	//charcter select stuff
	public static var bfMultiUnlock:Bool = false;
	public static var playableGFUnlock:Bool = false;
	public static var playablejellyUnlock:Bool = false;
	public static var playableneoUnlock:Bool = false;
	public static var playablejmaidUnlock:Bool = false;
	public static var playablespoopyUnlock:Bool = false;

	public function new()
	{
		//Why does haxe needs this again?
	}
}
class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

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
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE],

		'fullscreen'	=> [F11, NONE]
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
		'reset'			=> [BACK]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

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

	public static function saveSettings() {
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

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

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
		
		if(Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;

		if(FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
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

	public static function saveCharSlect() {
		FlxG.save.data.bfMultiUnlock = SaveVariables.bfMultiUnlock;
		FlxG.save.data.playableGFUnlock = SaveVariables.playableGFUnlock;
		FlxG.save.data.playablejellyUnlock = SaveVariables.playablejellyUnlock;
		FlxG.save.data.playableneoUnlock = SaveVariables.playableneoUnlock;
		FlxG.save.data.playablejmaidUnlock = SaveVariables.playablejmaidUnlock;
		FlxG.save.data.playablespoopyUnlock = SaveVariables.playablespoopyUnlock;
		FlxG.save.flush();
	}

	public static function loadCharSlect() {
		if(FlxG.save.data.bfMultiUnlock != null) {
			SaveVariables.bfMultiUnlock = FlxG.save.data.bfMultiUnlock;
		}
		if(FlxG.save.data.playableGFUnlock != null) {
			SaveVariables.playableGFUnlock = FlxG.save.data.playableGFUnlock;
		}
		if(FlxG.save.data.playablejellyUnlock != null) {
			SaveVariables.playablejellyUnlock = FlxG.save.data.playablejellyUnlock;
		}
		if(FlxG.save.data.playableneoUnlock != null) {
			SaveVariables.playableneoUnlock = FlxG.save.data.playableneoUnlock;
		}
		if(FlxG.save.data.playablejmaidUnlock != null) {
			SaveVariables.playablejmaidUnlock = FlxG.save.data.playablejmaidUnlock;
		}
		if(FlxG.save.data.playablespoopyUnlock != null) {
			SaveVariables.playablespoopyUnlock = FlxG.save.data.playablespoopyUnlock;
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	// private static function saveOptionsIni() {
	// 	var file:sys.io.FileOutput = sys.io.File.write(data.optionsFilePath);
	// 	if (file != null) {
	// 		file.writeString("[Keyboard]\n");
	// 		for (key in keyBinds.keys()) {
	// 			var keyBind:Array<FlxKey> = keyBinds.get(key);
	// 			file.writeString(key + "=");
	// 			for (i in 0...keyBind.length) {
	// 				file.writeString(keyBind[i].toString());
	// 				if (i < keyBind.length - 1) {
	// 					file.writeString(",");
	// 				}
	// 			}
	// 			file.writeString("\n");
	// 		}

	// 		file.writeString("\n[Gamepad]\n");
	// 		for (button in gamepadBinds.keys()) {
	// 			var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(button);
	// 			file.writeString(button + "=");
	// 			for (i in 0...gamepadBind.length) {
	// 				file.writeString(gamepadBind[i].toString());
	// 				if (i < gamepadBind.length - 1) {
	// 					file.writeString(",");
	// 				}
	// 			}
	// 			file.writeString("\n");
	// 		}

	// 		file.close();
	// 	} else {
	// 		FlxG.log.add("Failed to save options file!");
	// 	}
	// }

	// private static function loadOptionsIni() {
	// 	var file:sys.io.FileInput = sys.io.File.read(data.optionsFilePath);
	// 	if (file != null) {
	// 		var lines:Array<String> = file.readString().split("\n");
	// 		var section:String = "";
	// 		for (line in lines) {
	// 			line = line.trim();
	// 			if (line.length == 0 || line.charAt(0) == ";") {
	// 				continue;
	// 			} else if (line.charAt(0) == "[") {
	// 				section = line.substring(1, line.length - 1);
	// 			} else {
	// 				var parts:Array<String> = line.split("=");
	// 				if (parts.length == 2) {
	// 					var key:String = parts[0].trim();
	// 					var values:Array<String> = parts[1].split(",");
	// 					if (section == "Keyboard") {
	// 						var keyBind:Array<FlxKey> = [];
	// 						for (value in values) {
	// 							keyBind.push(FlxKey.fromString(value.trim()));
	// 						}
	// 						keyBinds.set(key, keyBind);
	// 					} else if (section == "Gamepad") {
	// 						var gamepadBind:Array<FlxGamepadInputID> = [];
	// 						for (value in values) {
	// 							gamepadBind.push(FlxGamepadInputID.fromString(value.trim()));
	// 						}
	// 						gamepadBinds.set(key, gamepadBind);
	// 					}
	// 				}
	// 			}
	// 		}
	// 		file.close();
	// 	} else {
	// 		FlxG.log.add("Failed to load options file!");
	// 	}
	// }

	// private static function saveOptionsJson() {
	// 	var jsonData:String = haxe.Json.stringify({ keyboard: keyBinds, gamepad: gamepadBinds });
	// 	var file:sys.io.FileOutput = sys.io.File.write(data.optionsFilePath);
	// 	if (file != null) {
	// 		file.writeString(jsonData);
	// 		file.close();
	// 	} else {
	// 		FlxG.log.add("Failed to save options file!");
	// 	}
	// }

	// private static function loadOptionsJson() {
	// 	var file:sys.io.FileInput = sys.io.File.read(data.optionsFilePath);
	// 	if (file != null) {
	// 		var jsonData:String = file.readString();
	// 		var json:Dynamic = haxe.Json.parse(jsonData);
	// 		if (json != null) {
	// 			if (json.keyboard != null) {
	// 				keyBinds = json.keyboard;
	// 			}
	// 			if (json.gamepad != null) {
	// 				gamepadBinds = json.gamepad;
	// 			}
	// 		}
	// 		file.close();
	// 	} else {
	// 		FlxG.log.add("Failed to load options file!");
	// 	}
	// }

	public static function reloadVolumeKeys() {
		FirstCheckState.muteKeys = keyBinds.get('volume_mute').copy();
		FirstCheckState.volumeDownKeys = keyBinds.get('volume_down').copy();
		FirstCheckState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final emptyArray = [];
		FlxG.sound.muteKeys = turnOn ? FirstCheckState.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = turnOn ? FirstCheckState.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = turnOn ? FirstCheckState.volumeUpKeys : emptyArray;
	}
}
