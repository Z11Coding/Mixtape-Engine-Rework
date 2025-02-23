package;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import backend.AudioSwitchFix;
import backend.FunkinRatioScaleMode;
import backend.MemoryCounter;
import haxe.ui.Toolkit;
import openfl.events.NativeProcessExitEvent;
import psychlua.*;
#if linux import lime.graphics.Image; #end
// crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end
// Gamejolt
import backend.gamejolt.GameJolt.GJToastManager;
import backend.debug.FPSCounter;
import backend.window.WindowUtils;

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

typedef Test ={key:String, value:Int};

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: #if UNDERTALE undertale.BATTLEFIELD #else /*backend.TestState*/ states.FirstCheckState #end, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var cmdArgs:Array<String> = Sys.args();
	public static var noTerminalColor:Bool = false;
	public static var playTest:Bool = false;
	public static var forceGPUOnlyBitmapsOff:Bool = #if windows false #else true #end;

	// public var initStuff = game;
	public static var fpsVar:FPSCounter;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		//Stolen from Psych Online. Thanks for making the next hour of my life not hell.
		Lib.current.addChild(new archipelago.console.SideUI());
	}

	public function new()
	{
		super();
		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		if (stage != null)
		{
			yutautil.Threader.runInThread(init(), 'init');
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init();
		#end
	}

	@:dox(hide)
	public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;
	public static var scaleMode:FunkinRatioScaleMode;

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	public static function dumpObject(graphic:FlxGraphic)
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				if (obj == graphic)
				{
					Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					break;
				}
			}
		}
	}

	// Gamejolt
	public static var gjToastManager:GJToastManager;

	// taken from forever engine, cuz optimization very pog.
	// thank you shubs :)
	public static function dumpCache()
	{
		///* SPECIAL THANKS TO HAYA
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
		Assets.cache.clear("songs");
		// */
	}

	private function setupGame():Void
	{
		// trace(StateCollector.collectStates());
		// trace(StateCollector.collectFlxStates());
		if (cmdArgs.indexOf('check') != -1)
		{
			// kill any running instances of the game
			Sys.command("taskkill /f /im MixEngine.exe");
		}
		backend.window.CppAPI._setWindowLayered();
		backend.window.CppAPI.darkMode();
		backend.window.CppAPI.allowHighDPI();
		backend.window.CppAPI.setOld();
		Toolkit.init();
		Toolkit.theme = 'dark'; // don't be cringe
		backend.Cursor.registerHaxeUICursors();

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('Mixtape', CoolUtil.getSavePath());

		Highscore.load();

		MemoryUtil.init();
		WindowUtils.init();
		var commandPrompt = new CommandPrompt();
		yutautil.Threader.runInThread(commandPrompt.start());
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		try
		{
			addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate,
				game.skipSplash, game.startFullscreen));
		}
		catch (e:haxe.Exception)
		{
			addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate,
				game.skipSplash, game.startFullscreen));
		}

		ClientPrefs.loadPrefs();
		AudioSwitchFix.init();
		WindowUtils.onClosing = function()
		{
			if (commandPrompt != null)
				commandPrompt.active = false;
			commandPrompt = null;
			handleStateBasedClosing();
		}
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxGraphic.defaultPersist = false;
		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		// memoryCounter = new MemoryCounter(10, 3, 0xffffff);
		// addChild(memoryCounter);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		/*if (memoryCounter != null)
			{
				memoryCounter.visible = ClientPrefs.data.showFPS;
		}*/
		#end

		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		Lib.current.loaderInfo.addEventListener(NativeProcessExitEvent.EXIT, onClosing); // help-
		stage.window.onDropFile.add(function(path:String)
		{
			trace("user dropped file with path: " + path);
		});

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});

		#if android
		FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
		#end

		gjToastManager = new GJToastManager();
		addChild(gjToastManager);
		backend.modules.EvacuateDebugPlugin.initialize();
		backend.modules.ForceCrashPlugin.initialize();
		backend.modules.MemoryGCPlugin.initialize();
	}

	public static function dummy():Void
	{
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	private static function onStateSwitch()
	{
		scaleMode.resetSize();
	}

	public function getFPS():Float
	{
		return fpsCounter.currentFPS;
	}

	public static var memoryCounter:MemoryCounter;

	public static function toggleMem(memEnabled:Bool):Void
	{
		memoryCounter.visible = memEnabled;
	}

	public static var fpsCounter:FPS;

	public static function onClosing(e:Event):Void
	{
		e.preventDefault();
		trace("Closing...");
	}

	public static inline function closeGame():Void
	{
		// if (Main.commandPrompt != null)
		// 	commandPrompt.remove();

		WindowUtils.preventClosing = false;
		Lib.application.window.close();

		closeGame();
	}

	public static var pressedOnce:Bool = false;

	public static function handleStateBasedClosing()
	{
		if (!pressedOnce || WindowUtils.__triedClosing)
		{
			pressedOnce = true;
			switch (Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1])
			{
				case "ChartingStateOG":
					// new Prompt("Are you sure you want to exit? Your progress will not be saved.", function (result:Bool) {

				default:
					// Default behavior: close the window
					FlxG.autoPause = false;
					TransitionState.transitionState(states.ExitState, {transitionType: "transparent close"});
			}
		}
		else
		{
			Main.closeGame();
		}
		WindowUtils.__triedClosing = false;
		WindowUtils.preventClosing = true;
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	public static function onCrash(e:UncaughtErrorEvent):Void
	{
		// Prevent further propagation of the error to avoid crashing the application
		e.preventDefault();
		var errMsg:String = "";
		var errType:String = e.error;
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();
		var crashState:String = Std.string(FlxG.state);

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "MixtapeEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Z11Coding/Mixtape-Engine\n\n> Crash Handler written by: sqirra-rng\n> Crash prevented!";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		if (ClientPrefs.data.showCrash)
		{
			Application.current.window.alert(errMsg, "Error!");
		}
		trace("Crash caused in: " + Type.getClassName(Type.getClass(FlxG.state)));
		// Handle different states
		switch (Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1])
		{
			case "PlayState":
				PlayState.Crashed = true;
				// Check if it's a Null Object Reference error
				if (errType.contains("Null Object Reference"))
				{
					if (PlayState.isStoryMode)
					{
						FlxG.switchState(new states.StoryMenuState());
					}
					else if (PlayState.CacheMode)
					{
						FlxG.resetState();
					}
					else
					{
						FlxG.switchState(new states.FreeplayState());
					}
					PlayState.Crashed = false;
				}

			case "ChartingState":
				// Check if it's a "Chart doesn't exist" error
				if (e.error.toLowerCase().contains("null object reference"))
				{
					// Show an extra error dialog
					Application.current.window.alert("You tried to load a Chart that doesn't exist!", "Chart Error");
				}

			case "FreeplayState", "StoryModeState":
				// Switch back to MainMenuState
				FlxG.switchState(new states.CategoryState());

			case "MainMenuState":
				// Go back to TitleState
				FlxG.switchState(new states.TitleState());

			case "TitleState":
				// Show an error dialog and close the game
				Application.current.window.alert("Something went extremely wrong... You may want to check some things in the files!\nFailed to load TitleState!",
					"Fatal Error");
				trace("Unable to recover...");
				// var assetWaitState:AssetWaitState = new AssetWaitState(MusicBeatState); // Provide the initial state
				FlxG.switchState(new states.ExitState());

			case "CacheState":
				Application.current.window.alert("Major Error occurred while caching data.\nSkipping Cache Operation.", "Fatal Error");
				FlxG.switchState(new states.What());

			case "What":
				trace("Restarting Game...");
				FlxG.switchState(new states.TitleState());


			case "OptionsState", "GameJoltState":
				// Show an error dialog and restart the game
				if (Sys.args().indexOf("-livereload") != -1)
				{
					Sys.println("Cannot restart from compiled build.");
					Application.current.window.alert("The game encountered a critical error.", "Game Bricked");
					Application.current.window.alert("Unable to restart due to running a Compiled build.", "Error");
				}
				else
				{
					Application.current.window.alert("The game encountered a critical error and will now restart.", "Game Bricked");
					trace("The game was bricked. Restarting...");
					var mainInstance = new Main();
					var mainGame = mainInstance.game;
					var initialState = Type.getClass(mainGame.initialState);
					// var cachedData = new haxe.ds.StringMap<Dynamic>();
					// var cachedData = new haxe.ds.StringMap<Dynamic>();
					// cachedData.set("ImageCache", ImageCache.cache);
					// cachedData.set("JSONCache", JSONCache.cache);
					// var cache = Json.stringify(cachedData);

					var restartProcess = new Process("MixEngine.exe", ["GameJoltBug", "restart"]);
					// FlxG.switchState(restartProcess);
					Sys.exit(1);
				}
				trace("Recommended to recompile the game to fix the issue.");

			case "ExitState":
				{
					// Show an error dialog and close the game
					Application.current.window.alert("Somehow, a crash occurred during the exiting process. Forcing exit.", "???");
					trace("Performing Emergency Exit.");
					Main.closeGame();
				}

			default:
				// For other states, reset to MainMenuState
				var mainInstance = new Main();
				var mainGame = mainInstance.game;
				FlxG.switchState(Type.createInstance(states.TitleState, []));
				trace("Unhandled state: " + (Type.getClassName(Type.getClass(FlxG.state))));
				trace("Restarting Game...");
		}

		// Additional error handling or recovery mechanisms can be added here

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					if (file.contains("FlxTween.hx"))
					{
						FlxTween.globalManager.clear();
						trace("Tween Error occurred. Clearing all tweens.");
					}

				default:
					dummy();
			}
		}
		TransitionState.currenttransition = null;
		if (TransitionState.isTransitioning)
		{
			TransitionState.isTransitioning = false;
		}
		if (TransitionState.requiredTransition != null)
		{
			TransitionState.transitionState(TransitionState.requiredTransition.targetState, TransitionState.requiredTransition.args, true);
		}
	}
	#end

	public static function simulateMemoryLeak():Void
	{
		var list:Array<Dynamic> = [];
		var cycleCount:Int = 0;
		while (cycleCount < 100)
		{
			// Continuously add large objects to the list without ever clearing it
			var array:Array<Int> = [];
			for (i in 0...1000000)
			{
				array.push(i);
			}
			list.push({data: array});
			cycleCount++;
		}
	}

	public static function simulateCrash():Void
	{
		// Simulate a crash by dividing by zero
		var zero:Int = 0;
		var result:Float = 10 / zero;
	}

	public static function simulateSlowdown():Void
	{
		var cycleCount:Int = 0;
		while (cycleCount < 100)
		{
			// Perform a large number of unnecessary calculations in a tight loop
			for (i in 0...1000000)
			{
				Math.sin(Math.random());
			}
			cycleCount++;
		}
	}

	public static function simulateFrequentCalls():Void
	{
		var itemChancesMap:Map<Dynamic, Float> = new Map<Dynamic, Float>();
		itemChancesMap.set("Option1", 0.5);
		itemChancesMap.set("Option2", 0.5);

		for (i in 0...10000)
		{ // Frequent calls
			var selectedOption = ChanceSelector.selectFromMap(itemChancesMap);
		}
		trace("Completed frequent calls to selectFromMap");
	}

	public static function simulateIntenseMaps():Void
	{
		var numMaps:Int = Std.int(Math.random() * 10 + 1); // Random number of maps between 1 and 10
		var maps:Array<Chance> = [];

		for (i in 0...numMaps)
		{
			var chance:Float = Math.random() * 99999999; // Random chance value between 0 and 99999999
			maps.push({item: "Map" + i, chance: chance});
		}

		var selectedMap = ChanceSelector.selectFromOptions(maps);
		trace("Selected map from random maps:", selectedMap);
	}

	public static function simulateLargeOptions():Void
	{
		var largeOptions:Array<Chance> = [];
		for (i in 0...100000)
		{ // Large number of options
			largeOptions.push({item: "Option" + i, chance: Math.random()});
		}
		var selectedOption = ChanceSelector.selectFromOptions(largeOptions);
		trace("Selected option from large options:", selectedOption);
	}

	public static function simulateLargeJSONCache():Void
	{
		var largeJSONCache = new haxe.ds.StringMap<Dynamic>();
		for (i in 0...100000)
		{ // Large number of JSON files
			largeJSONCache.set("file" + i, {data: "Some data for file " + i});
		}
		for (key in largeJSONCache.keys())
		{
			JSONCache.addToCache(largeJSONCache.get(key));
		}
	}
}

class GlobalResources
{
	public static var jsonFilePaths:Array<String> = [];
}

typedef Boolean = Bool;

class CommandPrompt
{
	private var state:String;
	private var variables:Map<String, Dynamic>;

	public var active:Boolean = true; // I thought it'd be funny to add this.

	public function new()
	{
		this.state = "default";
		this.variables = new Map();
		// yutautil.VariableForCommands.generateVariableMap(true);
	}

	public function start():Void
	{
		print("Commands activated.");
		print("Warning: Will not accept commands from regular PowerShell. Use Command Prompt, Terminal Command Prompt, or the VSCode terminal.");

		while (true)
		{
			// print("\nInput enabled.");
			if (!active)
			{
				print("Commands disabled.\nTO re-enable, restart the game.");
				break;
			}
			var input:String = Sys.stdin().readLine();

			if (input == "$exit")
			{
				print("Exiting...");
				Main.closeGame();
				print("Killing CommandHook...");
				break;
			}

			if (input == "$reset")
			{
				print("Resetting game...");
				var processChecker = new Process("MixEngine.exe", ["check"]);
			}

			this.executeCommand(input);
		}
	}

	// public function remove()
	// {this = null;}

	private function executeCommand(input:String):Void
	{
		var parts = input.split(" ");
		var command = parts[0];
		var args = parts.slice(1);

		var combinedArgs:Array<String> = [];
		var combinedArgsMap:Array<{position:Int, value:String}> = [];
		var i = 0;

		while (i < args.length)
		{
			var arg = args[i];
			if (arg.startsWith("'") || arg.startsWith('"'))
			{
				var combinedArg:String = arg;
				var quote:String = arg.charAt(0);
				var startPos:Int = i;
				i++;
				while (i < args.length && !args[i].endsWith(quote))
				{
					combinedArg += " " + args[i];
					i++;
				}
				if (i < args.length)
				{
					combinedArg += " " + args[i];
				}
				else
				{
					print("Error: Unterminated quotes.");
					return;
				}
				combinedArgsMap.push({position: startPos, value: combinedArg});
			}
			else
			{
				combinedArgs.push(arg);
			}
			i++;
		}

		// Reconstruct the args array using the combinedArgsMap
		var finalArgs:Array<String> = [];
		var mapIndex = 0;
		var doubleQuote = '"';
		var singleQuote = "'";

		for (i in 0...args.length)
		{
			if (mapIndex < combinedArgsMap.length && combinedArgsMap[mapIndex].position == i)
			{
				finalArgs.push(combinedArgsMap[mapIndex].value);
				mapIndex++;
				// Skip the indices that were part of the combined argument
				while (i < args.length && (!args[i].endsWith(singleQuote) && !args[i].endsWith(doubleQuote)))
				{
				}
			}
			else
			{
				finalArgs.push(args[i]);
			}
		}

		function containsTrue(array:Array<Bool>)
		{
			for (i in 0...array.length)
			{
				if (array[i] == true)
				{
					return true;
				}
			}
			return false;
		}

		// Now finalArgs contains the correctly combined arguments
		// You can proceed with using finalArgs as needed

		switch (command)
		{
			case "switchState":
				if (args.length == 1)
				{
					this.switchState(args[0]);
				}
				else
				{
					print("Error: switchState requires exactly one argument.");
				}
			case "varChange":
				if (args.length == 2)
				{
					this.varChange(args[0], args[1]);
				}
				else
				{
					print("Error: varChange requires exactly two arguments.");
				}
			case "secretCode":
				if (args.length == 1)
				{
					this.secretCode(args[0]);
				}
				else
				{
					print("Error: secretCode requires exactly one argument.");
				}
			case "exit":
				this.active = false;
				print("Exiting game...");
				if (args.length == 0)
				{
					this.switchState("states.ExitState");
				}
				else if (args.length == 1 && args[1] == "forced")
				{
					print("Forcing game to close...");
					Main.closeGame();
					print("Game closed.");
				}
				else
				{
					print("Warning: exit command only accepts 'forced' as an argument. Closing game...");
					this.switchState("ExitState");
				}
			case "resetState":
				if (args.length == 0)
				{
					FlxG.resetState();
				}
				else
				{
					print("Error: resetState does not accept any arguments.");
				}
			case "debugMenu":
				if (args.length == 0)
				{
					this.switchState("backend.TestState");
				}
				else
				{
					print("Error: debugMenu does not accept any arguments.");
				}
			case "forceSecret":
				if (args.length == 1)
				{
					states.MainMenuState.secretOverride = args[0];
					this.switchState("states.MainMenuState");
				}
				else
				{
					print("Error: forceSecret requires exactly one argument.");
				}
			// case "stopThread":
			// 	if (args.length == 1) {
			// 		Threader.stopThread(args[0]);
			// 	} else {
			// 		print("Error: stopThread requires exactly one argument.");
			// 	}
			// case "listThreads":
			// 	var threads:Array<String> = Threader.listThreads();
			// 	for (thread in threads) {
			// 		print("Thread: " + thread);
			// 	}

			case "playSong":
				var songName = args[0];
				var song = Paths.formatToSongPath(songName);
				var songChoices:Array<String> = [args[0]];
				var listChoices:Array<String> = [args[0]];
				var difficulties = backend.Paths.crawlMulti([
					'assets/data/$songName',
					'assets/shared/data/$songName',
					'mods/data/$songName'
				].concat(Mods.getModDirectories().map(dir -> '$dir/data/$songName')), 'json', []);
				var filteredDifficulties = [];
				var foundSong:Bool = false;
				var dashCount = songName.split("-").length - 1; // Count dashes in the song name
				for (difficulty in difficulties)
				{
					var fileName = Path.withoutDirectory(difficulty);
					if (fileName.startsWith(songName))
					{
						foundSong = true;
						var parts = fileName.split("-");
						if (parts.length > dashCount + 1)
						{
							filteredDifficulties.push(fileName.replace(".json", ""));
						}
						else if (fileName == songName + ".json")
						{
							filteredDifficulties.push(fileName.replace(".json", ""));
						}
					}
				}
				if (!foundSong)
				{
					GlobalException.throwGlobally("Song not found.", null, true);
				}
				difficulties = filteredDifficulties;
				var temp = [];
				for (difficulty in difficulties)
				{
					difficulty = difficulty.replace(songName, "");
					if (difficulty.startsWith("-"))
					{
						difficulty = difficulty.substr(1);
					}

					if (difficulty == "")
					{
						difficulty = "normal";
					}
					print(difficulty);
					temp.push(difficulty);
				}
				difficulties = temp;
				if (song != null)
				{
					substates.DiffSubState.songChoices = songChoices;
					substates.DiffSubState.listChoices = listChoices;
					backend.Difficulty.list = difficulties;

					// Check if the camera is in the default position
					var defaultCameraPosition = {x: 0, y: 0};
					if (FlxG.camera.scroll.x != defaultCameraPosition.x || FlxG.camera.scroll.y != defaultCameraPosition.y)
					{
						// Tween quickly to the default position
						FlxTween.tween(FlxG.camera.scroll, {x: defaultCameraPosition.x, y: defaultCameraPosition.y}, 0.5, {ease: FlxEase.quadOut});
					}

					FlxG.state.openSubState(new substates.DiffSubState());
				}

			// case "playSongLoose":
			// 	var songName = args[0];
			// 	var song = Paths.formatToSongPath(songName);
			// 	var songChoices:Array<String> = [];
			// 	var listChoices:Array<String> = [];
			// 	var difficulties = backend.Paths.crawlMulti([
			// 		'assets/data/$songName',
			// 		'assets/shared/data/$songName',
			// 		'mods/data/$songName'
			// 	].concat(Mods.getModDirectories().map(dir -> '$dir/data/$songName')), 'json', []);
			// 	var foundSongs:Map<String, Array<String>> = new Map();
			// 	for (difficulty in difficulties)
			// 	{
			// 		var fileName = Path.withoutDirectory(difficulty);
			// 		var baseName = fileName.split("-")[0];
			// 		if (!foundSongs.exists(baseName))
			// 		{
			// 			foundSongs.set(baseName, []);
			// 		}
			// 		foundSongs.get(baseName).push(fileName.replace(".json", ""));
			// 	}
			// 	if (foundSongs.keys().length == 0)
			// 	{
			// 		GlobalException.throwGlobally("No songs found.", null, true);
			// 	}
			// 	for (song in foundSongs.keys())
			// 	{
			// 		songChoices.push(song);
			// 		listChoices.push(song);
			// 		print("Song: " + song);
			// 		for (difficulty in foundSongs.get(song))
			// 		{
			// 			print("  Difficulty: " + difficulty);
			// 		}
			// 	}
			// 	if (song != null)
			// 	{
			// 		substates.DiffSubState.songChoices = songChoices;
			// 		substates.DiffSubState.listChoices = listChoices;
			// 		backend.Difficulty.list = foundSongs.get(songName);

			// 		// Check if the camera is in the default position
			// 		var defaultCameraPosition = {x: 0, y: 0};
			// 		if (FlxG.camera.scroll.x != defaultCameraPosition.x || FlxG.camera.scroll.y != defaultCameraPosition.y)
			// 		{
			// 			// Tween quickly to the default position
			// 			FlxTween.tween(FlxG.camera.scroll, {x: defaultCameraPosition.x, y: defaultCameraPosition.y}, 0.5, {ease: FlxEase.quadOut});
			// 		}

			// 		FlxG.state.openSubState(new substates.DiffSubState());
			// 	}
				// case "do":
				// 	if (args.length >= 2) {
				// 		var subCommand = args[0];
				// 		var code = args.slice(1).join(" ");
						
				// 		switch (subCommand) {
				// 			case "hx", "haxe", "code":
				// 				try {
				// 					haxe.macro.Context.eval(code);
				// 					print("Executed code: " + code);
				// 				} catch (e:haxe.Exception) {
				// 					print("Error executing code: " + e.toString());
				// 				}
								
					// 		case "func":
					// 			var funcName = args[1];
					// 			var funcArgs = args.slice(2);
								
					// 			// Check for different function call formats
					// 			if (funcArgs.length == 1 && funcArgs[0].startsWith("(") && funcArgs[0].endsWith(")")) {
					// 				// Format: func(arg, arg)
					// 				try {
					// 					var func = Reflect.field(this, funcName);
					// 					if (func != null && Reflect.isFunction(func)) {
					// 						var callArgs = funcArgs[0].substring(1, funcArgs[0].length - 1).split(",");
					// 						Reflect.callMethod(this, func, callArgs);
					// 						print("Executed function: " + funcName + " with arguments: " + callArgs.join(", "));
					// 					} else {
					// 						print("Error: Function " + funcName + " not found.");
					// 					}
					// 				} catch (e:haxe.Exception) {
					// 					print("Error executing function: " + e.toString());
					// 				}
					// 			} else if (funcArgs.length > 0 && funcArgs[0] == "()") {
					// 				// Format: func() arg arg
					// 				try {
					// 					var func = Reflect.field(this, funcName);
					// 					if (func != null && Reflect.isFunction(func)) {
					// 						Reflect.callMethod(this, func, funcArgs.slice(1));
					// 						print("Executed function: " + funcName + " with arguments: " + funcArgs.slice(1).join(", "));
					// 					} else {
					// 						print("Error: Function " + funcName + " not found.");
					// 					}
					// 				} catch (e:haxe.Exception) {
					// 					print("Error executing function: " + e.toString());
					// 				}
					// 			} else if (funcArgs.length > 0) {
					// 				// Format: func arg arg
					// 				try {
					// 					var func = Reflect.field(this, funcName);
					// 					if (func != null && Reflect.isFunction(func)) {
					// 						Reflect.callMethod(this, func, funcArgs);
					// 						print("Executed function: " + funcName + " with arguments: " + funcArgs.join(", "));
					// 					} else {
					// 						print("Error: Function " + funcName + " not found.");
					// 					}
					// 				} catch (e:haxe.Exception) {
					// 					print("Error executing function: " + e.toString());
					// 				}
					// 			} else {
					// 				print("Error: Invalid function call format.");
					// 			}
								
					// 		default:
					// 			print("Error: Unknown sub-command for 'do'.");
					// 	}
					// } else {
					// 	print("Error: 'do' requires at least two arguments.");
					// }
					
			default:
				if (args.length == 2 && args[1] == '=')
				{
					varChange(args[0], args[2]);
				}
				else
					print("Error: Unknown command.");
		}
	}

	private function switchState(newState:String):Void
	{
		var stateType:Class<Dynamic> = Type.resolveClass(newState);
		if (stateType != null)
		{
			FlxG.switchState(Type.createInstance(stateType, []));
			print("State switched to: " + newState);
		}
		else
		{
			print("Error: Invalid state name.");
		}
	}

	private function varChange(varName:String, newValue:String):Void
	{
		var split:Array<String> = varName.split('.');
		if (split.length == 0)
		{
			print("Error: Invalid variable name.");
			return;
		}

		var context:String = split[0];
		var remaining:Array<String> = split.slice(1);

		switch (context)
		{
			case "class":
				if (remaining.length >= 2)
				{
					var className:String = remaining[0];
					var variable:String = remaining.slice(1).join('.');
					this.setPropertyFromClass(className, variable, newValue);
				}
				else
				{
					print("Error: Invalid class variable name.");
				}
			case "group":
				if (remaining.length >= 3)
				{
					var groupName:String = remaining[0];
					var index:Int = Std.parseInt(remaining[1]);
					var variable:String = remaining.slice(2).join('.');
					this.setPropertyFromGroup(groupName, index, variable, newValue);
				}
				else
				{
					print("Error: Invalid group variable name.");
				}
			case "state":
				if (remaining.length >= 1)
				{
					var variable:String = remaining.join('.');
					this.setPropertyFromState(variable, newValue);
				}
				else
				{
					print("Error: Invalid state variable name.");
				}
			default:
				print("Error: Unknown context.");
		}
	}

	private function setPropertyFromClass(className:String, variable:String, value:Dynamic):Void
	{
		var myClass:Dynamic = Type.resolveClass(className);
		if (myClass == null)
		{
			print("Error: Class " + className + " not found.");
			return;
		}

		var split:Array<String> = variable.split('.');
		if (split.length > 1)
		{
			var obj:Dynamic = Reflect.field(myClass, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.field(obj, split[i]);

			Reflect.setProperty(obj, split[split.length - 1], value);
		}
		else
		{
			Reflect.setProperty(myClass, variable, value);
		}
		print("Variable " + variable + " in class " + className + " changed to: " + value);
	}

	private function setPropertyFromGroup(groupName:String, index:Int, variable:String, value:Dynamic):Void
	{
		var realObject:Dynamic = Reflect.field(LuaUtils.getTargetInstance(), groupName);

		if (Std.isOfType(realObject, FlxTypedGroup))
		{
			LuaUtils.setGroupStuff(realObject.members[index], variable, value);
			print("Variable " + variable + " in group " + groupName + " at index " + index + " changed to: " + value);
		}
		else
		{
			var leArray:Dynamic = realObject[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == Type.ValueType.TInt)
				{
					leArray = value;
				}
				else
				{
					LuaUtils.setGroupStuff(leArray, variable, value);
				}
				print("Variable " + variable + " in group " + groupName + " at index " + index + " changed to: " + value);
			}
			else
			{
				print("Error: Object #" + index + " from group " + groupName + " doesn't exist!");
			}
		}
	}

	private function setPropertyFromState(variable:String, value:Dynamic):Void
	{
		var currentState = FlxG.state;
		if (currentState != null)
		{
			var split:Array<String> = variable.split('.');
			if (split.length > 1)
			{
				var obj:Dynamic = Reflect.field(currentState, split[0]);
				for (i in 1...split.length - 1)
					obj = Reflect.field(obj, split[i]);

				Reflect.setProperty(obj, split[split.length - 1], value);
			}
			else
			{
				Reflect.setProperty(currentState, variable, value);
			}
			print("Variable " + variable + " in state changed to: " + value);
		}
		else
		{
			print("Error: No active state.");
		}
	}

	private function secretCode(code:String):Void
	{
		print("Secret code entered: " + code);
		print("Not yet implemented.");
	}

	private function print(message:String):Void
	{
		Sys.stdout().writeString(message + "\n");
	}
}

class GlobalException extends haxe.Exception
{
	public function new(message:String, ?previous:haxe.Exception)
	{
		super(message, previous);
	}

	public static function throwGlobally(message:String, ?previous:haxe.Exception, ?allowHandle):Void
	{
		WindowUtils.preventClosing = false;
		var exception = new GlobalException(message, previous);
		// Use a mechanism to throw the exception globally
		haxe.Timer.delay(function()
		{
			if (allowHandle)
			{
				// Handle the exception
				Main.onCrash(new UncaughtErrorEvent(UncaughtErrorEvent.UNCAUGHT_ERROR, exception));
			}
			else
			{
				throw exception;
			}
		}, 0);
	}
}
