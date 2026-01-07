package states;

import archipelago.APEntryState;
import backend.AudioSwitchFix;
import backend.util.NativeAPI;
import flixel.input.keyboard.FlxKey;
import lime.utils.Assets;
import states.MixtapeCrashSplash;
import yutautil.AprilFools;
import yutautil.modules.SyncUtils;

class FirstCheckState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	public static var gameInitialized = false;
	public static var updateVersion:String = '';
	public static var betaVersion:String = '';
	public static var relaunch:Bool = false;
	public static var dropFileSetup:Bool = false;

	var updateAlphabet:Alphabet;
	var updateIcon:FlxSprite;
	var updateRibbon:FlxSprite;
	var allowProgression:Bool = true; //For april fools

	/**
	 * Randomly chooses which splash screen to show
	 * 97% normal splash, 2% What state, 1% rare crash splash
	 */
	public static function goToSplashScreen():Void {
		var randomValue = FlxG.random.int(1, 100);

		if (randomValue <= 97) {
			// 97% chance - Normal splash screen
			FlxG.switchState(new states.SplashScreen());
		} else if (randomValue <= 99) {
			// 2% chance - What state
			FlxG.switchState(new states.What());
		} else {
			// 1% chance - Rare crash splash
			FlxG.switchState(new states.MixtapeCrashSplash());
		}
	}

	public static function checkInternetConnection():Bool {
		var response:Dynamic = null;
		var urls = [
			"https://httpbin.org/get",
			"https://raw.githubusercontent.com/Z11Coding/Mixtape-Engine-Rework/refs/heads/Archipelago/gitVersion.txt",
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

	override function create()
	{
		//backend.window.Priority.setPriority(0);
		if (!Paths.exists(Paths.imagePath('fred'))) {
			NativeAPI.showMessageBox('WHERE IS HE!?!?', "WHERE'S FRED???\nYOU CAN'T COME HERE WITHOUT FRED!", MSG_ERROR);
			Sys.exit(1);
		}

		if (!relaunch) {
			ClientPrefs.loadPrefs();
			COD.initCOD();
			MemoryUtil.init();
			Language.reloadPhrases();
			AudioSwitchFix.init();

			if (ClientPrefs.data.playLists == null) {
				ClientPrefs.loadPrefs();
				//load it again just to be sure
			}

			// Initialize crash tracking system early
			#if !debug
			yutautil.CrashTrackerHelper.initialize();
			yutautil.CrashTrackerHelper.logCriticalActivity("FirstCheckState", "new", "Application starting up");
			#end
		}

		if(Main.fpsVar != null) {
			Main.fpsVar.visible = ClientPrefs.data.showFPS && (ClientPrefs.data.performanceCounter == "fps" || ClientPrefs.data.performanceCounter == "fps-mem" || ClientPrefs.data.performanceCounter == "fps-mem-peak");
		}

		if(Main.debugDisplay != null) {
			Main.debugDisplay.visible = ClientPrefs.data.showFPS && (ClientPrefs.data.performanceCounter == "base" || ClientPrefs.data.performanceCounter == "base-adv");
			Main.debugDisplay.isAdvanced = (ClientPrefs.data.performanceCounter == "base-adv");
		}

		super.create();

		NativeFileSystem.openFlAssets = Assets.list();
		openfl.utils.Assets.cache.enabled = false;

		FlxG.scaleMode = new MobileScaleMode(ClientPrefs.data.wideScreen);

		// // Colored Text Test
		// // var text = new MarkdownFlxText(0, 0, FlxG.width, "This is a **bold** text with _italic_ and {#FF0000}color{#0000FF} formatting.");

		// // Test for combining text with different formats, using normal FlxText.
		// var text2 = new FlxText(0, 0, FlxG.width, "This is a normal text with bold, italic, and color formatting.");
		// text2.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// text2.text += "\n\n";
		// text2.text += "This is a ";
		// text2.text += "<b>bold</b>";
		// text2.text += " text with ";
		// text2.text += "<i>italic</i>";
		// text2.text += " and ";
		// text2.text += "<color=#" + StringTools.hex(FlxColor.RED, 6) + ">color</color>";
		// text2.text += " formatting.";

		// // add(text);
		// add(text2);

		// // Now, to test a second one below that, but with all of the text in separate FlxText objects, then using the combine() function.
		// var text3 = new FlxText(0, 0, FlxG.width, "This is a");
		// text3.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// var text4 = new FlxText(0, 0, FlxG.width, "bold");
		// text4.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// text4.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, true);
		// var text5 = new FlxText(0, 0, FlxG.width, "text with");
		// text5.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// var text6 = new FlxText(0, 0, FlxG.width, "italic");
		// text6.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// text6.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, null, true);
		// var text7 = new FlxText(0, 0, FlxG.width, "and");
		// text7.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// var text8 = new FlxText(0, 0, FlxG.width, "color");
		// text8.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		// text8.color = FlxColor.RED;
		// var text9 = new FlxText(0, 0, FlxG.width, "formatting.");
		// text9.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);

		// var combinedText = yutautil.MarkdownFlxText.combine([text3, text4, text5, text6, text7, text8, text9]);
		// combinedText.y = 200;
		// add(combinedText);

		if (AprilFools.allowAF)
		{
			allowProgression = false;
			var randoTimer:Int = FlxG.random.int(2, 10);
			var aprilFoolsText = new FlxText(0, 0, FlxG.width, "April Fools!");
			aprilFoolsText.setFormat(Paths.font("vcr.ttf"), 128, FlxColor.WHITE, CENTER);
			aprilFoolsText.screenCenter();
			aprilFoolsText.alpha = 0;
			add(aprilFoolsText);
			FlxTween.num(0, 1, randoTimer, {ease: FlxEase.linear,
				onComplete: function(twn:FlxTween) {
					if (!relaunch)
					{
						remove(aprilFoolsText);
						updateRibbon = new FlxSprite(0, FlxG.height - 75).makeGraphic(FlxG.width, 75, 0x88FFFFFF, true);
						updateRibbon.visible = false;
						updateRibbon.alpha = 0;
						add(updateRibbon);

						updateIcon = new FlxSprite(FlxG.width - 75, FlxG.height - 75);
						updateIcon.frames = Paths.getSparrowAtlas("pause/pauseAlt/bfLol");
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
									FirstCheckState.goToSplashScreen();
									//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
									FlxTween.globalManager.clear();
									backend.MusicBeatState.emergencyOpacityFix = true;
								});
								return;
							}
							var http = new haxe.Http("https://raw.githubusercontent.com/Z11Coding/Mixtape-Engine-Rework/refs/heads/Archipelago/gitVersion.txt");

							http.onData = function(data:String)
							{
								updateVersion = data.split(':')[0].trim();
								betaVersion = data.split(':')[1].trim();
								var curVersion:String = MainMenuState.mixtapeEngineVersion.trim();
								trace('version online: ' + updateVersion + ', your version: ' + curVersion);
								var updateVersionNum = Std.parseFloat(updateVersion.replace(".", ""));
								var curVersionNum = Std.parseFloat(curVersion.replace(".", ""));
								if (curVersionNum < updateVersionNum && ClientPrefs.data.checkForUpdates)
								{
									trace('versions arent matching!');
									// Use new release selection system instead of OutdatedState
									MusicBeatState.switchState(new states.ReleaseSelectionState());
									//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
									FlxTween.globalManager.clear();
									backend.MusicBeatState.emergencyOpacityFix = true;
								}
								else {
									// Only check APWorld if setup has been completed and user chose Archipelago mode
									if (ClientPrefs.data.checkAPWorld && ClientPrefs.data.setupCompleted && ClientPrefs.data.setupArchipelagoMode)
										FlxG.switchState(new APCheckState());
									else
										FirstCheckState.goToSplashScreen();
									//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
									FlxTween.globalManager.clear();
									backend.MusicBeatState.emergencyOpacityFix = true;
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
								new FlxTimer().start(2, function(tmr:FlxTimer) {
									FirstCheckState.goToSplashScreen();
									//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
									FlxTween.globalManager.clear();
									backend.MusicBeatState.emergencyOpacityFix = true;
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
						FlxG.switchState(new TitleState());
					}
				}},
				function(num){aprilFoolsText.alpha = num;});
		}
		else {
			ClientPrefs.data.aprilFools = true;
		}

		if (!relaunch && allowProgression)
		{
			updateRibbon = new FlxSprite(0, FlxG.height - 75).makeGraphic(FlxG.width, 75, 0x88FFFFFF, true);
			updateRibbon.visible = false;
			updateRibbon.alpha = 0;
			add(updateRibbon);

			updateIcon = new FlxSprite(FlxG.width - 75, FlxG.height - 75);
			updateIcon.frames = Paths.getSparrowAtlas("pause/pauseAlt/bfLol");
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
						FirstCheckState.goToSplashScreen();
						//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
						FlxTween.globalManager.clear();
						backend.MusicBeatState.emergencyOpacityFix = true;
					});
					return;
				}
				var http = new haxe.Http("https://raw.githubusercontent.com/Z11Coding/Mixtape-Engine-Rework/refs/heads/Archipelago/gitVersion.txt");

				http.onData = function(data:String)
				{
					updateVersion = data.split(':')[0].trim();
					betaVersion = data.split(':')[1].trim();
					var curVersion:String = MainMenuState.mixtapeEngineVersion.trim();
					trace('version online: ' + updateVersion + ', your version: ' + curVersion);
					var updateVersionNum = Std.parseFloat(updateVersion.replace(".", ""));
					var curVersionNum = Std.parseFloat(curVersion.replace(".", ""));
					if (curVersionNum < updateVersionNum && ClientPrefs.data.checkForUpdates)
					{
						trace('versions arent matching!');
						// Use new release selection system instead of OutdatedState
						MusicBeatState.switchState(new states.ReleaseSelectionState());
						//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
						FlxTween.globalManager.clear();
						backend.MusicBeatState.emergencyOpacityFix = true;
					}
					else {
						// Only check APWorld if setup has been completed and user chose Archipelago mode
						if (ClientPrefs.data.checkAPWorld && ClientPrefs.data.setupCompleted && ClientPrefs.data.setupArchipelagoMode)
							FlxG.switchState(new APCheckState());
						else
							FirstCheckState.goToSplashScreen();
						//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
						FlxTween.globalManager.clear();
						backend.MusicBeatState.emergencyOpacityFix = true;
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
					new FlxTimer().start(2, function(tmr:FlxTimer) {
						FirstCheckState.goToSplashScreen();
						//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
						FlxTween.globalManager.clear();
						backend.MusicBeatState.emergencyOpacityFix = true;
					});
				}

				http.request();
				updateIcon.visible = true;
				updateAlphabet.visible = true;
				updateRibbon.visible = true;
				updateRibbon.alpha = 1;
			});
		}
		else if (allowProgression)
		{
			FlxG.switchState(new TitleState());
			//So that no matter what it always fixes itself on launch if for whatever reason it's stil transparent
			FlxTween.globalManager.clear();
			backend.MusicBeatState.emergencyOpacityFix = true;
		}

		Achievements.unlock('start_fnf');
	}
}

class APCheckState extends MusicBeatState
{
	override public function create()
	{
		super.create();
		if (!archipelago.APEntryState.checkAndAlertAPWorld())
		{
			var update = new haxe.ui.containers.dialogs.MessageBox();
			update.title = "Archipelago World";
			update.text = "Would you like to install the version of the APWorld for this version of Mixtape Engine?";
			update.buttons = haxe.ui.containers.dialogs.Dialog.DialogButton.YES | haxe.ui.containers.dialogs.Dialog.DialogButton.NO;

			update.onDialogClosed = function(event:haxe.ui.containers.dialogs.Dialog.DialogEvent)
			{
				if (event.button == haxe.ui.containers.dialogs.Dialog.DialogButton.YES)
				{
					archipelago.APEntryState.installAPWorld();
					FirstCheckState.goToSplashScreen();
				}
				else
				{
					FirstCheckState.goToSplashScreen();
				}
			};

			update.show();
		}
		else FirstCheckState.goToSplashScreen();
	}
}
