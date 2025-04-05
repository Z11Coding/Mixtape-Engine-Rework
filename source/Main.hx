package;

#if android
import android.content.Context;
#end

import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;
import psychlua.LuaUtils;
import haxe.ui.Toolkit;
import openfl.events.NativeProcessExitEvent;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

#if sys
import sys.FileSystem;
import sys.io.Process;
import haxe.io.BytesOutput;
#end

import backend.Highscore;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

#if windows
@:buildXml('
<target id="haxe">
	<lib name="wininet.lib" if="windows" />
	<lib name="dwmapi.lib" if="windows" />
</target>
')
@:cppFileCode('
#include <windows.h>
#include <winuser.h>
#pragma comment(lib, "Shell32.lib")
extern "C" HRESULT WINAPI SetCurrentProcessExplicitAppUserModelID(PCWSTR AppID);
')
#end
// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: states.FirstCheckState, // initial game state
		framerate: 60, // default framerate
		skipSplash: FlxG.random.bool(99), // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var cmdArgs:Array<String> = Sys.args();

	public static var fpsVar:FPSCounter;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		//Stolen from Psych Online. Thanks for making the next hour of my life not hell.
		Lib.current.addChild(new archipelago.console.SideUI());
	}

	@:dox(hide)
	public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;
	public function new()
	{
		super();
		#if (cpp && windows)
		backend.window.Native.fixScaling();
		#end

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if windows
		backend.window.CppAPI._setWindowLayered();
		backend.window.CppAPI.darkMode();
		backend.window.CppAPI.allowHighDPI();
		backend.window.CppAPI.setOld();
		#end
		Toolkit.init();
		Toolkit.theme = 'dark'; // don't be cringe
		backend.Cursor.registerHaxeUICursors();

		if (cmdArgs.indexOf('check') != -1)
		{
			// kill any running instances of the game
			Sys.command("taskkill /f /im MixEngine.exe");
		}

		// yutautil.save.MixSaveWrapperBeta.testFunctionSave();

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
		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCrash);
		#end
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		Lib.current.loaderInfo.addEventListener(NativeProcessExitEvent.EXIT, onClosing); // help-

		// try { // WHY THE HELL IS THIS CRASHING???????????????????
		// 	stage.window.onDropFile.add(function(path:String)
		// 	{
		// 		trace("user dropped file with path: " + path);
		// 		try {
		// 			if (Std.is(FlxG.state, backend.MusicBeatState))
		// 				(cast FlxG.state : backend.MusicBeatState).handleFileDrop(path);
		// 		} catch (e:Dynamic) {
		// 			trace("Error: This state didn't handle the file properly: " + e + " ... " + e.getStack());
		// 			trace("Current state: " + Type.getClassName(Type.getClass(FlxG.state)));
		// 		}
		// 	});
		// } catch (e:Dynamic) {
		// 	trace("Error setting up onDropFile handler: " + e + " ... " + e.getStack());
		// }

		// shader coords fix
		FlxG.signals.gameResized.add((w, h) -> resetSpriteCaches());
		FlxG.signals.focusGained.add(resetSpriteCaches);

		#if android
		FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
		#end

		WindowUtils.onClosing = function()
		{
			if (commandPrompt != null)
				commandPrompt.active = false;
			commandPrompt = null;
			handleStateBasedClosing();
		}

		backend.modules.EvacuateDebugPlugin.initialize();
		backend.modules.ForceCrashPlugin.initialize();
		backend.modules.MemoryGCPlugin.initialize();

		// var dummyDate = Date.now();
		// var eDate = yutautil.ExtendedDate.fromDate(dummyDate);
		// trace("Extended Date: " + eDate);
		// trace("Extended Date: " + eDate.asString());
		// trace("Special Date Test: " + yutautil.ExtendedDate.getFullDateObject());
	}

	// shader coords fix
	function resetSpriteCaches() {
		for (cam in FlxG.cameras.list) {
			if (cam != null && cam.filters != null)
				resetSpriteCache(cam.flashSprite);
		}
		if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

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
		// remove if you're modding and want the crash log message to contain the link
		// please remember to actually modify the link for the github page to report the issues to.
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Z11Gaming/Mixtape-Engine-Rework";
		errMsg += "\n\n> Crash Handler written by: sqirra-rng";
		errMsg += "\n\n> Modified by: Yutamon";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case FilePos(s, file, line, column):
						if (file.contains("FlxTween.hx"))
						{
							FlxTween.globalManager.clear();
							trace("Tween Error occurred. Clearing all tweens.");
							if (ClientPrefs.data.ignoreTweenErrors)
								return;
						}
					default:
						trace("Unhandled stack item: " + stackItem);
						dummy();
				}
				}

		if (ClientPrefs.data.showCrash)
		{
			Application.current.window.alert(errMsg, "Error!");
		}
		trace("Crash caused in: " + Type.getClassName(Type.getClass(FlxG.state)));
		// Handle different states

				// Handle different states
				var stateClassName = Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1];
				var stateClass:Class<Dynamic> = Type.getClass(FlxG.state);
				var handled = false;
		
				while (stateClass != null && !handled) {
					switch (stateClassName) {
						case "PlayState":
							PlayState.Crashed = true;
							if (errType.contains("Null Object Reference")) {
								FlxG.sound.music != null ? FlxG.sound.music.stop() : null;
								FlxG.sound.play(Paths.sound("metal_pipe"));
								if (PlayState.isStoryMode) {
									FlxG.switchState(new states.StoryMenuState());
								} else {
									FlxG.switchState(new states.FreeplayState());
								}
								PlayState.Crashed = false;
							}
							handled = true;
		
						case "ChartingState":
							if (e.error.toLowerCase().contains("null object reference")) {
								Application.current.window.alert("You tried to load a Chart that doesn't exist!", "Chart Error");
							}
							handled = true;
		
						case "FreeplayState", "StoryModeState":
							FlxG.switchState(new states.CategoryState());
							handled = true;
		
						case "MainMenuState":
							FlxG.switchState(new states.TitleState());
							handled = true;
		
						case "TitleState":
							Application.current.window.alert("Something went extremely wrong... You may want to check some things in the files!\nFailed to load TitleState!",
								"Fatal Error");
							trace("Unable to recover...");
							FlxG.switchState(new states.ExitState());
							handled = true;
		
						case "CacheState":
							Application.current.window.alert("Major Error occurred while caching data.\nSkipping Cache Operation.", "Fatal Error");
							FlxG.switchState(new states.What());
							handled = true;
		
						case "What":
							trace("Restarting Game...");
							FlxG.switchState(new states.TitleState());
							handled = true;
		
						case "OptionsState", "GameJoltState":
							if (Sys.args().indexOf("-livereload") != -1) {
								Sys.println("Cannot restart from compiled build.");
								Application.current.window.alert("The game encountered a critical error.", "Game Bricked");
								Application.current.window.alert("Unable to restart due to running a Compiled build.", "Error");
							} else {
								Application.current.window.alert("The game encountered a critical error and will now restart.", "Game Bricked");
								trace("The game was bricked. Restarting...");
								var mainGame = Main.game;
								var initialState = Type.getClass(mainGame.initialState);
								var restartProcess = new Process("Mixtape.exe", ["GameJoltBug", "restart"]);
								FlxG.switchState(new states.ExitState());
							}
							trace("Recommended to recompile the game to fix the issue.");
							handled = true;

						case "APDisconnectSubstate":
							Application.current.window.alert("The game encountered a critical error and will now restart.", "AP Disconnect Error");
							trace("AP Disconnect Error. Restarting...");
							var mainGame = Main.game;
							var initialState = Type.getClass(mainGame.initialState);
							var restartProcess = new Process("Mixtape.exe", ["APDisconnectError", "restart"]);
							// FlxG.switchState(new states.ExitState());
							Main.closeGame();
							handled = true;
						case "ExitState":
							Application.current.window.alert("Somehow, a crash occurred during the exiting process. Forcing exit.", "???");
							trace("Performing Emergency Exit.");
							Main.closeGame();
							handled = true;
		
						default:
							stateClass = Type.getSuperClass(stateClass);
							stateClassName = stateClass != null ? Type.getClassName(stateClass).split(".")[Lambda.count(Type.getClassName(stateClass).split(".")) - 1] : null;
					}
				}
		
				if (!handled) {
					var mainGame = Main.game;
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
					if (file.contains("FlxSound.hx"))
					{
						FlxG.sound.music != null ? FlxG.sound.music.stop() : null;
						trace("Music Error occurred. Stopping music.");
					}
					if (file.contains("flixel/FlxG.hx"))
					{
						trace("Critical FLXG Error occurred. Restarting game...");
						new Process("Mixtape.exe", ["CriticalError", "restart"]);
						Main.closeGame();
					}


				default:
					dummy();
			}
		}
		//FlxG.switchState(TransitionState.requiredTransition.targetState);
	}
	#end

	public static function dummy():Void
	{
	}

	#if sys
	// https://github.com/openfl/hxp/blob/master/src/hxp/System.hx
	public static function runProcess(command:String, ?args:Array<String>):Null<String> {
		var process = new Process(command, args);
		var buffer = new BytesOutput();
		var waiting = true;

		while (waiting) {
			try {
				var current = process.stdout.readAll(1024);
				buffer.write(current);

				if (current.length == 0)
					waiting = false;
			} catch (e) {
				waiting = false;
			}
		}

		var result = process.exitCode();
		var output = buffer.getBytes().toString();
		var retVal:Null<String> = output;

		if (output == "") {
			var error = process.stderr.readAll().toString();
			process.close();

			if (result != 0 || error != "")
				retVal = null;
		} else {
			process.close();
		}
		
		return retVal;
	}
	#end
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

			case "debug":
				if (args.length == 1)
				{
					switch (args[0])
					{
						case "aprilFools":
							yutautil.AprilFools.debug = true;
							print("April Fools debug mode enabled.");
						default:
							print("Error: Unknown debug argument.");
					}
				}
				else
				{
					print("Error: debug requires exactly one argument.");
				}

			case "var":
				if (args.length == 2) {
					var variableName = args[0];
					var newValue = args[1];
					var currentState = FlxG.state;

					if (currentState != null) {
						var split:Array<String> = variableName.split('.');
						var obj:Dynamic = currentState;

						for (i in 0...split.length - 1) {
							obj = Reflect.field(obj, split[i]);
							if (obj == null) {
								print("Error: Unable to access variable " + split[i]);
								return;
							}
						}

						var fieldName = split[split.length - 1];
						var currentValue = Reflect.field(obj, fieldName);

						try {
							var typedValue:Dynamic;
							switch (Type.typeof(currentValue)) {
								case TBool:
									typedValue = (newValue.toLowerCase() == "true");
								case TInt:
									typedValue = Std.parseInt(newValue);
								case TFloat:
									typedValue = Std.parseFloat(newValue);
								default:
									typedValue = newValue;

							}

							Reflect.setProperty(obj, fieldName, typedValue);
							print("Variable: " + variableName + ", Type: " + Type.typeof(currentValue) + ", New Value: " + typedValue);
						} catch (e:Dynamic) {
							print("Error: Unable to set variable properly.");
						}
					} else {
						print("Error: No active state.");
					}
				} else {
					print("Error: var requires exactly two arguments.");
				}

			case "globalVar":
				if (args.length == 2) {
					var className = args[0].split('.')[0];
					var variablePath = args[0].split('.').slice(1).join('.');
					var newValue = args[1];

					var targetClass:Dynamic = Type.resolveClass(className);
					if (targetClass == null) {
						print("Error: Class " + className + " not found.");
						return;
					}

					var split:Array<String> = variablePath.split('.');
					var obj:Dynamic = targetClass;

					for (i in 0...split.length - 1) {
						obj = Reflect.field(obj, split[i]);
						if (obj == null) {
							print("Error: Unable to access variable " + split[i]);
							return;
						}
					}

					var fieldName = split[split.length - 1];
					var currentValue = Reflect.field(obj, fieldName);

					try {
						var typedValue:Dynamic;
						switch (Type.typeof(currentValue)) {
							case TBool:
								typedValue = (newValue.toLowerCase() == "true");
							case TInt:
								typedValue = Std.parseInt(newValue);
							case TFloat:
								typedValue = Std.parseFloat(newValue);
							default:
								typedValue = newValue;

							Reflect.setProperty(obj, fieldName, typedValue);
							print("Global Variable: " + args[0] + ", Type: " + Type.typeof(currentValue) + ", New Value: " + typedValue);
						}}catch (e:Dynamic) {
							print("Error: Unable to set variable properly.");
						}
				} else {
					print("Error: globalVar requires exactly two arguments.");
				}

					
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