package states;
import yutautil.modules.SyncUtils;
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
	public static var relaunch:Bool = false;

	var updateAlphabet:Alphabet;
	var updateIcon:FlxSprite;
	var updateRibbon:FlxSprite;

	public static function checkInternetConnection():Bool {
		var response:Dynamic = null;
		var urls = [
			"https://httpbin.org/get",
			"https://raw.githubusercontent.com/Z11Coding/Mixtape-Engine/refs/heads/main/gitVersion.txt",
			"https://www.google.com"
		];
		for (url in urls) {
			response = SyncUtils.syncHttpRequest(url);
			if (response != null && response != '') {
			return true;
			}
		}
        return response != null || response == '';
    }

	override public function create()
	{ 
		//backend.window.Priority.setPriority(0);
		if (gameInitialized && !relaunch)
		{
			lime.app.Application.current.window.alert("You cannot access this state. It is for initialization only.", "Debug");
			throw new haxe.Exception("Invalid state access!");	
		}
		
		if (!relaunch)
			COD.initCOD();

		super.create();

		if (!relaunch)
		{
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
				if (!checkInternetConnection())
				{
					updateAlphabet.text = 'Failed the vibe check! (No internet connection?)';
					updateAlphabet.color = FlxColor.RED;
					updateIcon.visible = false;
					FlxTween.tween(updateAlphabet, {alpha: 0}, 2, {ease:FlxEase.sineOut});
					FlxTween.tween(updateIcon, {alpha: 0}, 2, {ease:FlxEase.sineOut});
					new FlxTimer().start(2, function(tmr:FlxTimer) {
						trace("Ew, no internet!");
						FlxG.switchState(new states.SplashScreen());
					});
					return;
				}
				var http = new haxe.Http("https://raw.githubusercontent.com/Z11Coding/Mixtape-Engine/refs/heads/main/gitVersion.txt");

				http.onData = function(data:String)
				{
					updateVersion = data.split('\n')[0].trim();
					var curVersion:String = MainMenuState.mixtapeEngineVersion.trim();
					trace('version online: ' + updateVersion + ', your version: ' + curVersion);
					var updateVersionNum = Std.parseFloat(updateVersion.replace(".", ""));
					var curVersionNum = Std.parseFloat(curVersion.replace(".", ""));
					if (curVersionNum < updateVersionNum && ClientPrefs.data.checkForUpdates)
					{
						trace('versions arent matching!');
						MusicBeatState.switchState(new states.OutdatedState());
					}
					else FlxG.switchState(new states.SplashScreen());
				}

				http.onError = function(error)
				{
					trace('error: $error');
					updateAlphabet.text = 'Failed the vibe check!';
					updateAlphabet.color = FlxColor.RED;
					updateIcon.visible = false;
					FlxTween.tween(updateAlphabet, {alpha: 0}, 2, {ease:FlxEase.sineOut});
					FlxTween.tween(updateIcon, {alpha: 0}, 2, {ease:FlxEase.sineOut});
					new FlxTimer().start(2, function(tmr:FlxTimer) {
						FlxG.switchState(new states.SplashScreen());
					});
				}

				http.request();
				updateIcon.visible = true;
				updateAlphabet.visible = true;
				updateRibbon.visible = true;
				updateRibbon.alpha = 1;
			});
		}
		else
		{
			FlxG.switchState(new states.SplashScreen());
		}
	}
}