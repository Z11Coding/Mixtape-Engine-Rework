package states;
import backend.Highscore;
import backend.Achievements;
import backend.util.WindowUtil;
import flixel.input.keyboard.FlxKey;
import states.UpdateState;
import flixel.ui.FlxBar;
import openfl.system.System;
import lime.app.Application;
class FirstCheckState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var gameInitialized = false;
	public static var updateVersion:String = '';

	var updateAlphabet:Alphabet;
	var updateIcon:FlxSprite;
	var updateRibbon:FlxSprite;

	override public function create()
	{
		if (gameInitialized)
		{
			lime.app.Application.current.window.alert("You cannot access this state. It is for initialization only.", "Debug");
			throw new haxe.Exception("Invalid state access!");	
		}
		FlxG.mouse.visible = false;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		WindowUtil.initWindowEvents();
		WindowUtil.disableCrashHandler();
		FlxSprite.defaultAntialiasing = true;

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		ClientPrefs.loadPrefs();
		ClientPrefs.reloadVolumeKeys();

		Language.reloadPhrases();

		COD.initCOD();

		#if sys
		ArtemisIntegration.initialize();
		ArtemisIntegration.setGameState ("title");
		ArtemisIntegration.resetModName ();
		ArtemisIntegration.setFadeColor ("#FF000000");
		ArtemisIntegration.sendProfileRelativePath ("assets/artemis/modpack-mixup.json");
		ArtemisIntegration.resetAllFlags ();
		ArtemisIntegration.autoUpdateControls ();
		Application.current.onExit.add (function (exitCode) {
			ArtemisIntegration.setBackgroundColor ("#00000000");
			ArtemisIntegration.setGameState ("closed");
			ArtemisIntegration.resetModName ();
		});
		#end

		PlayerInfo.loadInfo();

		super.create();

		updateRibbon = new FlxSprite(0, FlxG.height - 75).makeGraphic(FlxG.width, 75, 0x88FFFFFF, true);
		updateRibbon.visible = false;
		updateRibbon.alpha = 0;
		add(updateRibbon);

		updateIcon = new FlxSprite(FlxG.width - 75, FlxG.height - 75);
		updateIcon.frames = Paths.getSparrowAtlas("pauseAlt/bfLol", "shared");
		updateIcon.animation.addByPrefix("dance", "funnyThing instance 1", 20, true);
		updateIcon.animation.play("dance");
		updateIcon.setGraphicSize(65);
		updateIcon.updateHitbox();
		updateIcon.antialiasing = true;
		updateIcon.visible = false;
		add(updateIcon);

		updateAlphabet = new ColoredAlphabet(0, 0, "Checking Your Vibe...", true, FlxColor.WHITE);
		for(c in updateAlphabet.members) {
			c.scale.x /= 2;
			c.scale.y /= 2;
			c.updateHitbox();
			c.x /= 2;
			c.y /= 2;
		}
		updateAlphabet.visible = false;
		updateAlphabet.x = updateIcon.x - updateAlphabet.width - 10;
		updateAlphabet.y = updateIcon.y;
		add(updateAlphabet);
		updateIcon.y += 15;

		var tmr = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/Z11Coding/Vs.-Z11-Mixtape-Madness/refs/heads/main/gitVersion.txt");

			http.onData = function(data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.mixtapeEngineVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if (updateVersion != curVersion && ClientPrefs.data.checkForUpdates)
				{
					trace('versions arent matching!');
					MusicBeatState.switchState(new states.OutdatedState());
				}
				else
				{
					FlxG.switchState(new states.CacheState());
				}
			}

			http.onError = function(error)
			{
				trace('error: $error');
				updateAlphabet.text = 'Failed the vibe check!';
				updateAlphabet.color = FlxColor.RED;
				updateIcon.visible = false;
				FlxTween.tween(updateAlphabet, {alpha: 0}, 2, {ease:FlxEase.sineOut});
				FlxTween.tween(updateIcon, {alpha: 0}, 2, {ease:FlxEase.sineOut});
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					FlxG.switchState(new states.CacheState());
				});
			}

			http.request();
			updateIcon.visible = true;
			updateAlphabet.visible = true;
			updateRibbon.visible = true;
			updateRibbon.alpha = 1;
		});
	}
}