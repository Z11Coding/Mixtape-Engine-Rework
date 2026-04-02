package;

#if android
import android.content.Context;
#end

import backend.Highscore;
import backend.modules.*;
import backend.modules.SSPlugin as ScreenShotPlugin;
import backend.modules.TraceManager;
// import cpp.vm.tracy.TracyProfiler;
import debug.FPSCounter;
import debug.FunkinDebugDisplay;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import games.uno.backend.*;
import games.uno.backend.UnoCPU.UnoDifficulty;
import games.uno.backend.UnoCard.UnoColor;
import games.uno.backend.UnoRules.UnoGameState;
import haxe.Exception;
import haxe.io.Path;
import haxe.ui.Toolkit;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.NativeProcessExitEvent;
import psychlua.LuaUtils;
import states.TitleState;
import yutautil.GenericProgressSubstate;
#if debug
import debug.DebugManager;
import yutautil.StatePick;
#end


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
import haxe.CallStack;
import haxe.io.Path;
import openfl.events.UncaughtErrorEvent;
#end

#if sys
import haxe.io.BytesOutput;
import sys.FileSystem;
import sys.io.Process;
#end


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
@:autoBuild(yutautil.StatePick.addToDatabase(Main))
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
	public static var flxSignalCrash:Bool = false;

	public static var debugDisplay:FunkinDebugDisplay;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{

		flxSignalCrash = false;
		try
		{
			trace(3.forceCast(Type.ValueType.TFloat));
		}
		catch (e:Dynamic)
		{
			trace("Error: " + e);
		}
		trace("Finished testing forceCast.");

		// var r:Random<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
		// trace("Random Test: " + r);

		// trace("Random Test 2: " + new Random<Int>([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));

		// var r2:Random<Int> = [for (i in 1...11) i];
		// trace("Random Test 3: " + r2);


		// var temp:Temp<Int> = 23932;

		// trace("Temp Test 2: " + temp);

		// var temp2:Temp<{value:Int, otherValue:Int}> = {
		// 	value: 123,
		// 	otherValue: 456
		// };

		// var nonTemp:{value:Int, otherValue:Int} = {
		// 	value: 123,
		// 	otherValue: 456
		// };

		// var temp2Address = cpp.Native.addressOf(game);
		// trace("Star test 1: " + temp2Address);
		// var randofdsde:Temp<Int> = 123;
		// trace("Temp Test 3: " + randofdsde);



		// var eeee:Int = 123;

		// var p = cpp.Pointer.addressOf(eeee)[0];
		// trace("Pointer Test: " + p);

		// var funnyDouble = new HaxePointer<Dynamic>(game);
		// trace("Funny Double Test: " + funnyDouble);
		// trace("Funny Double Test: " + new HaxePointer<Dynamic>(game));

		// (new Fields(temp2).printFields());
		// (new Fields(nonTemp).printFields());

		// trace("TestAcc: " + new FieldAccTest({}).eeeee);
		// trace("TestAcc2: " );
		// var testAcc2 = new FieldAccTest({eeeee: 123}).eeeee = 456;

		// var collaped:Collapsed<Int> = [[1], [2], [3], [4], [5]];

		// trace("Collaped Test: " + collaped);

		// var gaming:GlobalPointer<Dynamic> = game;

		// gaming.startFullscreen = true;

		// Pointer of a pointer test (HaxePointer of HaxePointer, stacked 5 times)
		var arr:Array<Int> = [1, 2, 3, 4, 5];


		// var ptr1 = new HaxePointer<Array<Int>>(arr);
		// var ptr2 = new HaxePointer<HaxePointer<Array<Int>>>(ptr1);
		// var ptr3 = new HaxePointer<HaxePointer<HaxePointer<Array<Int>>>>(ptr2);
		// var ptr4 = new HaxePointer<HaxePointer<HaxePointer<HaxePointer<Array<Int>>>>>(ptr3);
		// var ptr5 = new HaxePointer<HaxePointer<HaxePointer<HaxePointer<HaxePointer<Array<Int>>>>>>(ptr4);

		// // Now resolve the pointer all the way down to the array
		// var ptr = ptr5;
		// var resolvedArr:Array<Int> = ptr;


		// trace("Resolved stacked HaxePointer array: " + resolvedArr);

		// // Let's also put the pointer in another array and resolve it
		// var pointerArray:Array<Dynamic> = [ptr];
		// var resolvedFromArray:Array<Int> = pointerArray[0];
		// trace("Resolved from pointerArray: " + resolvedFromArray);


		trace("TypeTools ptrMap: " + TypeTools.ptrMap);

		// YSComp Test - Testing YScript to Haxe compilation
		#if macro
		trace("YSComp test skipped - macro context");
		#else
		try {
			// Test compiled YScript MathHelper class
			var helper = new yutautil.TestMath.MathHelper(2.0);
			trace("YSComp Test - Created MathHelper with multiplier 2.0");

			var result1 = helper.multiply(5.0);
			trace("YSComp Test - 5.0 * 2.0 = " + result1);

			var result2 = helper.add(10.0, 15.0);
			trace("YSComp Test - add(10.0, 15.0) = " + result2);

			var multiplier = helper.getMultiplier();
			trace("YSComp Test - getMultiplier() = " + multiplier);

			// Test module-level function
			var quickResult = yutautil.TestMath.quickAdd(7.5, 2.5);
			trace("YSComp Test - quickAdd(7.5, 2.5) = " + quickResult);

			// Test module-level variable
			var defaultMult = yutautil.TestMath.defaultMultiplier;
			trace("YSComp Test - defaultMultiplier = " + defaultMult);

			trace("YSComp Test - All tests completed successfully!");
		} catch (e:Dynamic) {
			trace("YSComp Test - Error: " + e);
			trace("YSComp Test - This is expected if YSComp macro is not enabled or YScript files are not processed");
		}
		#end

		// ═══════════════════════════════════════════════════════════════
		// TypeHandler & Abstract Type Checking Tests
		// ═══════════════════════════════════════════════════════════════
		// COMMENTED OUT: These tests use TypeHandler which requires BuildDataLoader
		// BuildDataLoader uses async initialization, so commenting out these tests
		// to prevent immediate data access that would freeze the engine startup.
		/*
		trace("=== TypeHandler & Abstract Type Checking Tests ===");
		try {
			// --- TypeHandler.classifyType ---
			trace("TypeHandler Test - classifyType('Int') = " + yutautil.TypeHandler.classifyType("Int"));
			trace("TypeHandler Test - classifyType('Array<Int>') = " + yutautil.TypeHandler.classifyType("Array<Int>"));
			trace("TypeHandler Test - classifyType('{ name:String }') = " + yutautil.TypeHandler.classifyType("{ name:String }"));
			trace("TypeHandler Test - classifyType('(Int) -> Bool') = " + yutautil.TypeHandler.classifyType("(Int) -> Bool"));

			// --- Primitive compatibility ---
			trace("TypeHandler Test - isCompatible('Int', 'Float') = " + yutautil.TypeHandler.isCompatible("Int", "Float"));           // true: Int -> Float promotion
			trace("TypeHandler Test - isCompatible('Float', 'Int') = " + yutautil.TypeHandler.isCompatible("Float", "Int"));             // false: Float -> Int not safe
			trace("TypeHandler Test - isCompatible('Int', 'Dynamic') = " + yutautil.TypeHandler.isCompatible("Int", "Dynamic"));         // true: Dynamic accepts anything
			trace("TypeHandler Test - isCompatible('Bool', 'Int') = " + yutautil.TypeHandler.isCompatible("Bool", "Int"));               // false: Bool not numeric

			// --- Abstract @:from checking (can Int be assigned to Num?) ---
			trace("TypeHandler Test - canAssignToAbstract('Int', 'yutautil.Num') = " + yutautil.TypeHandler.canAssignToAbstract("Int", "yutautil.Num"));
			trace("TypeHandler Test - canAssignToAbstract('Float', 'yutautil.Num') = " + yutautil.TypeHandler.canAssignToAbstract("Float", "yutautil.Num"));
			trace("TypeHandler Test - canAssignToAbstract('String', 'yutautil.Num') = " + yutautil.TypeHandler.canAssignToAbstract("String", "yutautil.Num"));   // likely false

			// --- Abstract @:to checking (can Num output a Float?) ---
			trace("TypeHandler Test - canAbstractOutputType('yutautil.Num', 'Float') = " + yutautil.TypeHandler.canAbstractOutputType("yutautil.Num", "Float"));
			trace("TypeHandler Test - canAbstractOutputType('yutautil.Num', 'Int') = " + yutautil.TypeHandler.canAbstractOutputType("yutautil.Num", "Int"));
			trace("TypeHandler Test - canAbstractOutputType('yutautil.Num', 'String') = " + yutautil.TypeHandler.canAbstractOutputType("yutautil.Num", "String"));

			// --- Structure compatibility ---
			trace("TypeHandler Test - isStructureCompatible('{ name:String, age:Int }', '{ name:String }') = "
				+ yutautil.TypeHandler.isStructureCompatible("{ name:String, age:Int }", "{ name:String }"));                           // true: source has all required target fields
			trace("TypeHandler Test - isStructureCompatible('{ name:String }', '{ name:String, age:Int }') = "
				+ yutautil.TypeHandler.isStructureCompatible("{ name:String }", "{ name:String, age:Int }"));                           // false: source missing 'age'
			trace("TypeHandler Test - isStructureCompatible('{ name:String }', '{ name:String, ?age:Int }') = "
				+ yutautil.TypeHandler.isStructureCompatible("{ name:String }", "{ name:String, ?age:Int }"));                          // true: age is optional

			// --- Array compatibility ---
			trace("TypeHandler Test - areArraysCompatible('Array<Int>', 'Array<Int>') = " + yutautil.TypeHandler.areArraysCompatible("Array<Int>", "Array<Int>"));       // true
			trace("TypeHandler Test - areArraysCompatible('Array<Int>', 'Array<Float>') = " + yutautil.TypeHandler.areArraysCompatible("Array<Int>", "Array<Float>"));   // depends on Int->Float

			// --- TypeRef with Class<Dynamic> ---
			trace("TypeHandler Test - classifyType(String) via TypeRef = " + yutautil.TypeHandler.classifyType(String));      // Should classify String type
			trace("TypeHandler Test - stripGenerics('Map<String, Int>') = " + yutautil.TypeHandler.stripGenerics("Map<String, Int>"));   // "Map"
			trace("TypeHandler Test - getSimpleName('yutautil.Num') = " + yutautil.TypeHandler.getSimpleName("yutautil.Num"));           // "Num"

			// --- Value-based type inference ---
			trace("TypeHandler Test - inferValueType(42) = " + yutautil.TypeHandler.inferValueType(42));
			trace("TypeHandler Test - inferValueType(3.14) = " + yutautil.TypeHandler.inferValueType(3.14));
			trace("TypeHandler Test - inferValueType('hello') = " + yutautil.TypeHandler.inferValueType("hello"));
			trace("TypeHandler Test - inferValueType(true) = " + yutautil.TypeHandler.inferValueType(true));

			// --- isValueCompatible ---
			trace("TypeHandler Test - isValueCompatible(42, 'Int') = " + yutautil.TypeHandler.isValueCompatible(42, "Int"));             // true
			trace("TypeHandler Test - isValueCompatible(42, 'Float') = " + yutautil.TypeHandler.isValueCompatible(42, "Float"));         // true: Int -> Float

			// --- Structure inference from runtime values ---
			var testObj = {name: "Alice", age: 25, active: true};
			trace("TypeHandler Test - inferValueType({name,age,active}) = " + yutautil.TypeHandler.inferValueType(testObj));       // { name:String, age:Int, active:Bool }
			trace("TypeHandler Test - isValueCompatible(testObj, '{ name:String }') = "
				+ yutautil.TypeHandler.isValueCompatible(testObj, "{ name:String }"));                                           // true: has name:String
			trace("TypeHandler Test - isValueCompatible(testObj, '{ name:String, age:Int }') = "
				+ yutautil.TypeHandler.isValueCompatible(testObj, "{ name:String, age:Int }"));                                  // true: has both
			trace("TypeHandler Test - isValueCompatible(testObj, '{ name:String, missing:Float }') = "
				+ yutautil.TypeHandler.isValueCompatible(testObj, "{ name:String, missing:Float }"));                            // false: no 'missing' field

			// Nested structure inference
			var nestedObj = {pos: {x: 10.5, y: 20.3}, label: "point"};
			trace("TypeHandler Test - inferValueType(nested) = " + yutautil.TypeHandler.inferValueType(nestedObj));               // { pos:{ x:Float, y:Float }, label:String }

			// Array element inference
			var typedArr = [1, 2, 3];
			trace("TypeHandler Test - inferValueType([1,2,3]) = " + yutautil.TypeHandler.inferValueType(typedArr));               // Array<Int>

			// --- parseStructureFields ---
			var parsed = yutautil.TypeHandler.parseStructureFields("{ name:String, ?age:Int, active:Bool }");
			trace("TypeHandler Test - parseStructureFields count = " + (parsed != null ? Std.string(parsed.length) : "null"));    // 3
			if (parsed != null && parsed.length >= 2) {
				trace("TypeHandler Test - parseStructureFields [0] name=" + parsed[0].name + " type=" + parsed[0].type + " optional=" + parsed[0].optional); // name, String, false
				trace("TypeHandler Test - parseStructureFields [1] name=" + parsed[1].name + " type=" + parsed[1].type + " optional=" + parsed[1].optional); // age, Int, true
			}

			// --- isFunction ---
			trace("TypeHandler Test - isFunction('(Int) -> Bool') = " + yutautil.TypeHandler.isFunction("(Int) -> Bool"));         // true
			trace("TypeHandler Test - isFunction('String') = " + yutautil.TypeHandler.isFunction("String"));                       // false
			trace("TypeHandler Test - isFunction('() -> Void') = " + yutautil.TypeHandler.isFunction("() -> Void"));               // true

			// --- Structure-to-structure via isCompatible ---
			trace("TypeHandler Test - isCompatible struct superset = "
				+ yutautil.TypeHandler.isCompatible("{ name:String, age:Int }", "{ name:String }"));                              // true: superset
			trace("TypeHandler Test - isCompatible struct missing = "
				+ yutautil.TypeHandler.isCompatible("{ name:String }", "{ name:String, age:Int }"));                              // false: missing required
			trace("TypeHandler Test - isCompatible struct optional = "
				+ yutautil.TypeHandler.isCompatible("{ name:String }", "{ name:String, ?age:Int }"));                             // true: age is optional

			// --- Nested structure compatibility via isValueCompatible ---
			trace("TypeHandler Test - isValueCompatible(nested, '{ pos:{ x:Float }, label:String }') = "
				+ yutautil.TypeHandler.isValueCompatible(nestedObj, "{ pos:{ x:Float }, label:String }"));                        // true: partial nested match

			// --- extractGenericParam / extractMapParams ---
			trace("TypeHandler Test - extractGenericParam('Array<String>') = " + yutautil.TypeHandler.extractGenericParam("Array<String>"));   // String
			var mapParams = yutautil.TypeHandler.extractMapParams("Map<String, Int>");
			trace("TypeHandler Test - extractMapParams('Map<String, Int>') key=" + (mapParams != null ? mapParams.key : "null")
				+ " value=" + (mapParams != null ? mapParams.value : "null"));                                                    // String, Int

			// --- Null handling ---
			trace("TypeHandler Test - inferValueType(null) = " + yutautil.TypeHandler.inferValueType(null));                       // Null
			trace("TypeHandler Test - isValueCompatible(null, 'String') = " + yutautil.TypeHandler.isValueCompatible(null, "String")); // true

			trace("=== TypeHandler Tests Complete ===");
		} catch (e:Dynamic) {
			trace("TypeHandler Test - Error: " + e);
		}
		*/

		// Initialize BuildDataLoader asynchronously (non-blocking)
		// This starts the async loading process in the background without freezing startup
		yutautil.typeregistry.BuildDataLoader.initialize();

		// var fold: yutautil.Fold<{name:String, age:Int}> = {
		// 	name: "John Doe",
		// 	age: 30,
		// 	extraField: "This field is extra and should be allowed"
		// };

		// var fold2: yutautil.Fold<{x:Float, y:Float}> = {
		// 	x: 10.5,
		// 	y: 20.3,
		// 	additionalInfo: "Extra data allowed here"
		// };

		// var fold3: yutautil.Fold<{x:Float}> = {y: 0}; // Missing 'x' field, should cause compile-time error if validated

		// var name: String = fold.name;
		// var age: Int = fold.age;
		// trace("Fold Test: Name = " + name + ", Age = " + age);
		// trace("Fold2 Test: x = " + fold2.x + ", y = " + fold2.y);
		// trace("Fold3 Test: x = " + fold3.x);
		// // trace("Test invalid: " + fold3.y); // Should cause compile-time error if validated

		Lib.current.addChild(new Main());
		//Stolen from Psych Online. Thanks for making the next hour of my life not hell.
		Lib.current.addChild(new archipelago.console.SideUI());
		Lib.current.addChild(new archipelago.console.obj.Alert());
		//Lib.current.addChild(new objects.Nightlight());

		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end

		// trace("Words loaded: " + backend.MusicBeatState.words);
	}

	// Game pre-flixel init code
	// ? This runs before we attempt to precache things
	public static function loadGameEarly()
	{
		#if (linux || mac) // fix the app icon not showing up on the Linux Panel
		var icon = lime.graphics.Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		// This initialises mods
		try
		{
			trace("Pushing global mods");
			#if LUA_ALLOWED
			Mods.pushGlobalMods();
			#end
			trace("Pushing top mod");
			Mods.loadTopMod();
		}
		catch (x:Exception)
			trace("Something went wrong with mod code: " + x.message);

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		if (cmdArgs.indexOf('check') != -1)
		{
			// kill any running instances of the game
			Sys.command("taskkill /f /im MixEngine.exe");
		}

		var commandPrompt = new CommandPrompt();

		trace(commandPrompt.metadata());

		yutautil.Threader.runInThread(commandPrompt.start(), 0, "cmd", true, 0);

		WindowUtils.onClosing = function()
		{
			if (commandPrompt != null)
				commandPrompt.active = false;
			commandPrompt = null;
			handleStateBasedClosing();
		}

		// Override trace function to support enhanced tracing system with frame limiting and threading
			"Overriding haxe.Log.trace to support Console/Game/Both modes with frame-based limiting and threading.".NativeComment();
		var originalTrace = haxe.Log.trace;
		TraceManager.setOriginalTrace(originalTrace);
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			if (backend.ClientPrefs.data.disableHaxeTraces) {
				return; // Traces disabled completely
			}

			if (TraceManager.traceClassesAsObjects) {
				// Check if v is a class instance
				var className = Type.getClassName(Type.getClass(v));
				if (className != null) {
					v = yutautil.save.ObjectSerializer.serialize(v);
				}
			}

			var traceMode = backend.ClientPrefs.data.traceMode;
			switch (traceMode) {
				case "CONSOLE":
					// Use enhanced TraceManager for console output with frame limiting
					TraceManager.addTrace(Std.string(v), infos);
					// Don't call originalTrace directly - let TraceManager handle it
				case "GAME":
					// Only send to in-game viewer
					TraceManager.addTrace(Std.string(v), infos);
				case "BOTH":
					// Send to both console and in-game viewer via TraceManager
					TraceManager.addTrace(Std.string(v), infos);
				default:
					// Fallback to original trace for unknown modes
					originalTrace(v, infos);
			}
		};
		"Trace will now respect the 'Disable Haxe Traces' setting in the options menu, except for when using 'HxTrace.log()' via Yutautil.".log();
		"Warning: Putting a class instance in a trace may serialize a LOT of data, which can impact performance, even in threading mode.".log();
	}

	@:dox(hide)
	public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;
	public function new()
	{

		#if windows
		backend.window.CppAPI.setWindowOpacity(0);
		#end

		super();


		#if (cpp && windows)
		backend.window.Native.fixScaling();
		#end

		// var a:yutautil.Inf.Num = new yutautil.Inf.InfNum(1.0);
		// var b:yutautil.Inf.Num = new yutautil.Inf.InfNum(2.0);
		// var c:yutautil.Inf.Num = a + b;
		// trace("InfNum Test: " + c);
		// trace(c.value);
		// trace(c.floatPoint);
		// trace(c.isNegative);

		// trace("InfNum Test: " + new yutautil.Inf.InfNum(12345678901234567890.0));
		// trace("InfNum Test: " + new yutautil.Inf.InfNum(12345678901234567890.0).toFloat());
		// trace("InfNum Test: " + new yutautil.Inf.InfNum(12345678901234567890.0).toString());
		// trace("InfNum Test: " + new yutautil.Inf.InfNum(12345678901234567890.0).value);
		// trace("InfNum Test: " + new yutautil.Inf.InfNum(12345678901234567890.0).floatPoint);
		// trace("InfNum Test: " + new yutautil.Inf.InfNum(12345678901234567890.0).isNegative);

		// var h:Float = c;
		// trace("InfNum Test: " + h);

		#if windows
		backend.window.CppAPI._setWindowLayered();
		backend.window.CppAPI.darkMode();
		backend.window.CppAPI.allowHighDPI();
		backend.window.CppAPI.setOld();
		#end
		 #if (windows && cpp)
    // Disable the Windows "ghosting" effect that dims unresponsive windows.
    backend.window.base.windows.WinAPI.disableWindowsGhosting();

    // Disable Windows error reporting (avoids sending bug reports to Microsoft).
    backend.window.base.windows.WinAPI.disableErrorReporting();
    #end
		initHaxeUI();
		backend.Cursor.registerHaxeUICursors();

		trace(yutautil.StatePick.getStateNames("MusicBeatState"));

		// yutautil.save.MixSaveWrapperBeta.testFunctionSave();

		FlxG.save.bind('Mixtape', CoolUtil.getSavePath());
		Highscore.load();

		WindowUtils.init();

		//trace(game.metadata());

		//trace("gamedddifsdsf".realSizeOf());

		// var testArray = new yutautil.CollectionUtils.KeyIndexedArray();
		// testArray.set("test", 1);
		// trace(testArray.get("test"));
		// trace(testArray.get("test2"));
		// trace(testArray["test"]);

		trace("PC System Memory: " + backend.util.NativeAPI.getPhysicallyInstalledSystemMemory() + " GB");


		// 'You can\'t put variable expressions in COMMENTS, silly!'.NativeComment(true);
		// 	trace('testArray: $testArray');
		// 'testArray = $testArray'.NativeTrace(true, false);
		// "NativeTrace works with double quotes too!".NativeTrace(true);
		// testArray.NativeTrace(true, false);

		#if windows
		backend.window.CppAPI.setWindowOpacity(1);
		#end


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

		trace(Math.E());

		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		var game:FlxGame = new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen);
		@:privateAccess
		game._customSoundTray = backend.FunkinSoundTray;
		addChild(game);

		// ASync Test - create a slow function and test it
		trace("=== ASync Test Starting ===");

		function slowFunction():String {
			trace("ASync: Starting slow operation...");
			Sys.sleep(FlxG.random.float(0, 8)); // Wait around 8 seconds
			trace("ASync: Slow operation completed!");
			return "Async operation completed successfully!";
		}

		var asyncFunc:ASync<Void -> String> = slowFunction;
		var result = asyncFunc();

		trace("ASync: About to get result (this should block for ~8 seconds)...");
		trace("ASync: Got result: " + result.get());
		var testForString:String = result;
		trace("=== ASync Test Complete ===");

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS && (ClientPrefs.data.performanceCounter == "fps" || ClientPrefs.data.performanceCounter == "fps-mem" || ClientPrefs.data.performanceCounter == "fps-mem-peak");
		}
		#end

		debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);
		addChild(debugDisplay);
		if(debugDisplay != null) {
			debugDisplay.visible = ClientPrefs.data.showFPS && (ClientPrefs.data.performanceCounter == "base" || ClientPrefs.data.performanceCounter == "base-adv");
			debugDisplay.isAdvanced = (ClientPrefs.data.performanceCounter == "base-adv");
			debugDisplay.backgroundOpacity = ClientPrefs.data.performanceBackground;
		}

		#if (!web && flixel < "5.5.0")
		FlxG.plugins.add(new ScreenShotPlugin());
		#elseif (flixel >= "5.6.0")
		FlxG.plugins.addIfUniqueType(new ScreenShotPlugin());
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

		// Clean up any leftover High Quality Trap temp files from previous sessions
		#if ARCHIPELAGO_ALLOWED
		archipelago.HighQualityTrapManager.onEngineExit();
		#end

		Lib.current.loaderInfo.addEventListener(NativeProcessExitEvent.EXIT, onClosing); // help-

		// try { // WHY THE HELL IS THIS CRASHING???????????????????
		// 	trace("Setting up onDropFile handler...");
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

		FlxG.signals.gameResized.add((w, h) -> {
			if (MobileScaleMode.instance != null) {
				@:privateAccess {
					MobileScaleMode.instance.horizontalAlign = MobileScaleMode.active ? LEFT : CENTER;
					MobileScaleMode.instance.verticalAlign = MobileScaleMode.active ? TOP : CENTER;
					MobileScaleMode.instance.onMeasure(w, h);
				}
			}
		});


		// Artificial loop using GoToTag as a label and GoTo as a goto
		/*var counter = 0;
		yutautil.CUMacroTools.GoToTag("loopStart");
			trace('goto test: $counter');
			counter++;
			if (counter >= 5) {
				yutautil.CUMacroTools.GoTo("loopEnd");
			} else {
				yutautil.CUMacroTools.GoTo("loopStart");
			}

		yutautil.CUMacroTools.GoToTag("loopEnd");
		// This is just a test to see if the GoToTag and GoTo macros work correctly.

		// Second test using 'using' import for string extension
		// (Assumes: import using yutautil.CUMacroTools;)
		var counter2 = 0;
		"loopStart2".GoToTag();
			trace('goto test 2: $counter2');
			counter2++;
			if (counter2 >= 5) {
				"loopEnd2".GoTo();
			} else {
				"loopStart2".GoTo();
			}
		"loopEnd2".GoToTag();*/
		// This is a test to see if the GoToTag and GoTo string extensions work correctly.


		#if android
		FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
		#end

		EvacuateDebugPlugin.initialize();
		ForceCrashPlugin.initialize();
		MemoryGCPlugin.initialize();
		FullScreenPlugin.initialize();
		ConsolePlugin.initialize();
		TraceViewerPlugin.initialize();
		new ScreenShotPlugin();

		// trace(3.cubed());

		// var classTest:Class<Dynamic> = states.PlayState;
		// trace("Class Test: " + Type.getClassName(classTest));
		// var mania:Dynamic = classTest.mania;
		// trace("Class Test 2: " + mania);
		// var instanceTest:Dynamic = Type.createInstance(classTest, []);
		// trace("Class Test 3: " + instanceTest);
		// var instance2Test:Dynamic = Type.createInstance(classTest, []);
		// trace("Class Test 4: " + instance2Test);



		// trace("Game Dialog Test 1: " + dialogs.Dialogs.open('Test for Open', [{ext:'txt', desc:'Text files'}]));
		// trace("Game Dialog Test 2: " + dialogs.Dialogs.save('Test for Save', {ext:'txt', desc:'Text files'}));

		// var dummyDate = Date.now();
		// var eDate = yutautil.ExtendedDate.fromDate(dummyDate);
		// trace("Extended Date: " + eDate);
		// trace("Extended Date: " + eDate.asString());
		// trace("Special Date Test: " + yutautil.ExtendedDate.getFullDateObject());
	}

	function initHaxeUI():Void
	{
		#if haxeui_core
		haxe.ui.Toolkit.init();
		haxe.ui.Toolkit.theme = 'dark';
		haxe.ui.Toolkit.autoScale = false;
		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
		#end
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

	private static var gameClosing:Bool = false;

	public static inline function closeGame():Void
	{
		if (gameClosing) return;
		gameClosing = true;

		// Flush all queued traces before exit
		backend.modules.TraceManager.flushAllQueuedTraces();

		// Clean up trace system threading
		#if sys
		backend.modules.TraceManager.stopTraceThread();
		#end

		// Track command exit through CrashReporter
		#if !debug
		try {
			yutautil.CrashReporter.logActivity("Main", "closeGame", "Game is closing...");
		} catch (trackError:Dynamic) {
			trace("Failed to track game exit: " + trackError);
		}
		#end

		// if (Main.commandPrompt != null)
		// 	commandPrompt.remove();

		// Remove terminal output/input so the process will close properly.
			backend.util.NativeAPI.freeConsole();

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
			// Set the closing flag to disable controls

			switch (Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1])
			{
				case "ChartingStateOG":
					// new Prompt("Are you sure you want to exit? Your progress will not be saved.", function (result:Bool) {

				default:
					// Default behavior: close the window
					ClientPrefs.data.warmupCompleted = false;
					ClientPrefs.saveSettings();
					FlxG.autoPause = false;
					backend.MusicBeatState.isClosing = true;

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

	/**
	 * Extract the source expression from a crash location using TypeCollectionMacro data
	 * Attempts to retrieve the exact expression that caused the crash
	 * Only works if the loader is actually initialized - returns null otherwise to avoid delays
	 */
	private static function getCrashExpressionFromLocation(file:String, line:Int, column:Int):String
	{
		try
		{
			// Check if the loader is initialized and has data
			if (!yutautil.typeregistry.BuildDataLoader.isLoaded())
				return null;

			// Normalize file path for consistency
			var normalizedFile = file.replace("\\", "/");

			// Try to load build data and find the function at this location
			var allFunctions:Array<Dynamic> = yutautil.typeregistry.BuildDataLoader.getAllFunctions();

			if (allFunctions == null || allFunctions.length == 0)
				return null;

			// Find function containing this location
			var matchingFunction:Dynamic = null;
			for (func in allFunctions)
			{
				if (func == null) continue;

				var funcFile = Std.string(func.filePath).replace("\\", "/");
				var funcStartLine:Int = func.startLine;
				var funcEndLine:Int = func.endLine;

				// Check if crash is within this function's range
				if (funcFile.indexOf(normalizedFile) != -1 && line >= funcStartLine && line <= funcEndLine)
				{
					matchingFunction = func;
					break;
				}
			}

			if (matchingFunction == null)
				return null;

			// Get the source code for this function
			var sourceCode:String = Std.string(matchingFunction.sourceCode);
			if (sourceCode == null || sourceCode.length == 0)
				return null;

			// Split source into lines
			var sourceLines:Array<String> = sourceCode.split("\n");

			// Calculate relative line within the function (1-indexed in callstack)
			var funcStartLine:Int = Std.parseInt(Std.string(matchingFunction.startLine));
			var relativeLineIndex:Int = (line - funcStartLine);

			if (relativeLineIndex < 0 || relativeLineIndex >= sourceLines.length)
				return null;

			var crashLine:String = sourceLines[relativeLineIndex];
			if (crashLine == null || crashLine.length == 0)
				return null;

			// Extract expression around the crash column
			// Try to find meaningful boundaries (whitespace, operators, brackets)
			var colIndex:Int = column - 1; // Convert to 0-indexed
			if (colIndex < 0) colIndex = 0;
			if (colIndex >= crashLine.length) colIndex = crashLine.length - 1;

			// Find the start of the expression (scan backwards for whitespace or operators)
			var exprStart:Int = colIndex;
			while (exprStart > 0)
			{
				var char = crashLine.charAt(exprStart - 1);
				if (char == " " || char == "\t" || char == "(" || char == "[" || char == "{" ||
				    char == "=" || char == "," || char == ";" || char == ":")
					break;
				exprStart--;
			}

			// Find the end of the expression (scan forwards for whitespace or operators)
			var exprEnd:Int = colIndex + 1;
			while (exprEnd < crashLine.length)
			{
				var char = crashLine.charAt(exprEnd);
				if (char == " " || char == "\t" || char == "(" || char == "[" || char == "{" ||
				    char == "=" || char == "," || char == ";" || char == ")" || char == "]" || char == "}")
					break;
				exprEnd++;
			}

			// Extract the expression
			var expression:String = crashLine.substring(exprStart, exprEnd).trim();

			// If expression is too short or empty, return the whole line trimmed
			if (expression.length == 0 || expression.length == 1)
				expression = crashLine.trim();

			// Limit expression length for readability
			if (expression.length > 200)
				expression = expression.substring(0, 197) + "...";

			return expression;
		}
		catch (e:Dynamic)
		{
			trace("Error extracting crash expression: " + e);
			return null;
		}
	}

	public static function onCrash(e:UncaughtErrorEvent):Void
	{
		"Crash Handler Code for Mixtape Engine Rework.".NativeComment();
		// Prevent further propagation of the error to avoid crashing the application
		e.preventDefault();

		// DANGEROUS DEBUG OPTION: If ignoreThrows is enabled, just prevent crash escalation and return
		if (ClientPrefs.data.ignoreThrows) {
			trace('Crash ignored due to ignoreThrows debug setting: ${e.error}');
			return;
		}



		var errMsg:String = "";
		var errType:String = e.error;
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();
		var crashState:String = (Type.getClassName(Type.getClass(FlxG.state)));

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
						if (file.contains("hscript/Interp.hx"))
						{
							var interpErrorMsg = "(Internal Critical Error) " + e.error;
							trace(interpErrorMsg);
							if (Std.isOfType(FlxG.state, states.PlayState))
							{
								cast(FlxG.state, states.PlayState).addTextToDebug(interpErrorMsg, FlxColor.RED);
							}
							return;
						}
					default:
						trace("Unhandled stack item: " + stackItem);
						dummy();
				}
				}


		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "MixtapeEngine_" + dateNow + ".txt";

		// Check if this is our custom UnexpectedCrashException
		var isUnexpectedCrash = false;
		var unexpectedCrashData:Dynamic = null;

		#if !debug
		try {
			var errorString = Std.string(e.error);
			if (errorString.indexOf("UnexpectedCrashException") != -1) {
				isUnexpectedCrash = true;
				// Try to extract crash data if available
				if (Reflect.hasField(e.error, "previousCrashData")) {
					unexpectedCrashData = Reflect.field(e.error, "previousCrashData");
				}
			}
		} catch (extractError:Dynamic) {
			trace("Could not extract unexpected crash data: " + extractError);
		}
		#end

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";

					// Try to extract and display the crash expression using TypeCollectionMacro data
					var crashExpr = getCrashExpressionFromLocation(file, line, column);
					if (crashExpr != null)
					{
						errMsg += "  Expression: " + crashExpr + "\n";
					}
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		errMsg += "\nError Code: " + new DetailedException(e).errorCode;
		errMsg += "\n(Error Codes in Beta. May be long...)";
		errMsg += "\nIn State: " + crashState;

		// Add special handling for unexpected crashes
		if (isUnexpectedCrash) {
			errMsg += "\n\n*** UNEXPECTED CRASH DETECTED ***";
			errMsg += "\nThis crash was detected from a previous session.";
			if (unexpectedCrashData != null) {
				errMsg += "\nPrevious session info: " + haxe.Json.stringify(unexpectedCrashData, "  ");
			}
			errMsg += "\nCheck the logger folder for detailed crash tracking reports.";
		}

		#if !debug
		// Generate enhanced crash report with tracking data
		try {
			yutautil.CrashReporter.generateEnhancedCrashReport("Uncaught exception: " + e.error);
		} catch (reportError:Dynamic) {
			trace("Failed to generate enhanced crash report: " + reportError);
		}
		#end

		// remove if you're modding and want the crash log message to contain the link
		// please remember to actually modify the link for the github page to report the issues to.
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/Z11Gaming/Mixtape-Engine-Rework";
		errMsg += "\n\n> Crash Handler written by: sqirra-rng";
		errMsg += "\n\n> Modified by: Yutamon";
		errMsg += "\n\n> Enhanced Crash Tracking: Enabled";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		#if !debug
		Sys.println("Enhanced crash report with tracking data saved in ./logger/ folder");
		#end


		if (ClientPrefs.data.showCrash)
		{
			function lineBreaker(msg:String, lineLength:Int = 80):String
			{

			function findBreakPoint(text:String, maxLength:Int):Int
			{
				// Look for good break points: punctuation, camelCase, underscores
				var breakChars = [".", ",", ":", ";", "!", "?", "-", "_", "(", ")", "[", "]", "{", "}"];

				// Search backwards from max length for a good break point
				for (i in 0...Math.floor(maxLength * 0.8))
				{
					var pos = maxLength - i - 1;
					if (pos < 0) break;

					var char = text.charAt(pos);

					// Break after punctuation
					if (breakChars.contains(char))
					{
						return pos + 1;
					}

					// Break at camelCase boundaries (lowercase followed by uppercase)
					if (pos > 0 && pos < text.length - 1)
					{
						var prevChar = text.charAt(pos - 1);
						var nextChar = text.charAt(pos);
						if (prevChar == prevChar.toLowerCase() && nextChar == nextChar.toUpperCase())
						{
							return pos;
						}
					}
				}

				return 0; // No good break point found
			}

				var brokenMsg:String = "";
				var currentLine:String = "";
				var words = msg.split(" ");

				for (word in words)
				{
					// Check if adding this word would exceed the line length
					if (currentLine.length > 0 && (currentLine.length + word.length + 1) > lineLength)
					{
						// Add current line and start new one
						brokenMsg += currentLine.trim() + "\n";
						currentLine = word;
					}
					else
					{
						// Add word to current line
						if (currentLine.length > 0) currentLine += " ";
						currentLine += word;
					}

					// Handle very long words that exceed line length by themselves
					if (currentLine.length > lineLength)
					{
						// Try to break at punctuation or camelCase boundaries
						var breakPoint = findBreakPoint(currentLine, lineLength);
						if (breakPoint > 0)
						{
							brokenMsg += currentLine.substring(0, breakPoint) + "\n";
							currentLine = currentLine.substring(breakPoint);
						}
						else
						{
							// Force break if no good break point found
							brokenMsg += currentLine.substring(0, lineLength) + "\n";
							currentLine = currentLine.substring(lineLength);
						}
					}
				}

				// Add any remaining content
				if (currentLine.length > 0)
				{
					brokenMsg += currentLine;
				}

				return brokenMsg;
			}


			var alertMsg = errMsg;
			if (isUnexpectedCrash) {
				alertMsg = "UNEXPECTED CRASH DETECTED!\n\nThe engine crashed unexpectedly in a previous session.\nDetailed crash tracking reports are available in the logger folder.\n\n" + alertMsg;
			}
			Application.current.window.alert((alertMsg), isUnexpectedCrash ? "Unexpected Crash!" : "Error!");
		}

		if (flxSignalCrash) FlxG.resetGame(); // Don't even bother to try and fix it just restart

		backend.MusicBeatState.playErrorSound = true;
		trace("Crash caused in: " + Type.getClassName(Type.getClass(FlxG.state)));
		// Handle different states

				// Handle different states
				var stateClassName = Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1];
				var stateClass:Class<Dynamic> = Type.getClass(FlxG.state);
				var handled = false;

				if (stateClass == null) {
					trace("State class is null. Either signals broke, or the game is bricked.");
					try {
						var exitStuff:Array<Dynamic> = [];
						exitStuff = exitStuff.concat(states.ExitState.cleanupFunctions).concat(states.ExitState.returnFunctions);
						for (callbacks in exitStuff)
						{ try { callbacks(); } catch (e:Dynamic) { trace("Error in exit callback: " + e); } }
						// do restart process
						var restartProcess = new Process("Mixtape.exe", ["GameBricked", "restart"]);
						Main.closeGame();
					} catch (e:Dynamic) {
						trace("Error occurred while executing exit callbacks: " + e);
						// do restart process
						var restartProcess = new Process("Mixtape.exe", ["GameBricked", "restart"]);
						Main.closeGame();
					}
				}

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
									FreeplayManager.openFreeplay();
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

						case "null", null:
							// This is a null state, which means signals failed, and the game is bricked.
							// We need to restart the game.
							// Kill the game process and restart it.
							var restartProcess = new Process("Mixtape.exe", ["GameBricked", "restart"]);
							Main.closeGame(); // We can't switch to a new state if the game is bricked, so just close it.

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
	private var unoGame:UnoGame;
	private var yscriptTester:yutautil.YScript; // YScript test environment
	public static var instance:CommandPrompt;

	public var active:Boolean = true; // I thought it'd be funny to add this.

	public function new()
	{
		this.state = "default";
		this.variables = new Map();
		// Initialize debug system
		debug.DebugManager.initialize();
		instance = this;
	}

	/**
	 * Get all available state classes using StatePick
	 */
	private function getAllStateClasses():Map<String, Class<Dynamic>> {
		var stateClasses:Map<String, Class<Dynamic>> = new Map();

		try {
			// Get MusicBeatState classes
			var musicBeatStates = yutautil.StatePick.getStateNames("MusicBeatState");
			for (stateName in musicBeatStates.toIterable()) {
				var stateClass = Type.resolveClass(stateName);
				if (stateClass != null) {
					stateClasses.set(stateName, stateClass);
				}
			}

			// Get FlxState classes
			var flxStates = yutautil.StatePick.getStateNames("FlxState");
			for (stateName in flxStates.toIterable()) {
				var stateClass = Type.resolveClass(stateName);
				if (stateClass != null) {
					stateClasses.set(stateName, stateClass);
				}
			}
		} catch (e:Dynamic) {
			trace('Error getting state classes: ${e}');
		}

		return stateClasses;
	}

	/**
	 * Get static properties of a class
	 */
	private function getStaticProperties(stateClass:Class<Dynamic>):Array<String> {
		var properties:Array<String> = [];

		try {
			var staticFields = Type.getClassFields(stateClass);
			for (field in staticFields) {
				var fieldValue = Reflect.field(stateClass, field);
				if (!Reflect.isFunction(fieldValue)) {
					properties.push(field);
				}
			}
		} catch (e:Dynamic) {
			trace('Error getting static properties for ${Type.getClassName(stateClass)}: ${e}');
		}

		return properties;
	}

	/**
	 * Get static property value
	 */
	private function getStaticProperty(stateClass:Class<Dynamic>, propertyName:String):Dynamic {
		try {
			return Reflect.field(stateClass, propertyName);
		} catch (e:Dynamic) {
			trace('Error getting static property ${propertyName}: ${e}');
			return null;
		}
	}

	/**
	 * Set static property value
	 */
	private function setStaticProperty(stateClass:Class<Dynamic>, propertyName:String, value:Dynamic):Bool {
		try {
			Reflect.setField(stateClass, propertyName, value);
			return true;
		} catch (e:Dynamic) {
			trace('Error setting static property ${propertyName}: ${e}');
			return false;
		}
	}

	public function start():Void
	{
		print("Commands activated.");
		print("Warning: Will not accept commands from regular PowerShell. Use Command Prompt, Terminal Command Prompt, or the VSCode terminal.");
		print("When using the runCode command, you can use the 'this' keyword to access certain aspects of the game engine.");
		print("Run the code 'this.help()' to see what you can do with it.");

		while (true)
		{
			// print("\nInput enabled.");
			if (!active)
			{
				print('Commands disabled.\nTO re-enable, restart the game, or restart the command prompt with ${backend.ClientPrefs.keyBinds['console'].toString()}.');
				instance = null;
				break;
			}
			var input:String = Sys.stdin().readLine();

			if (input == "$exit")
			{
				print("Exiting...");
				// Log command exit for crash tracking
				#if !debug
				yutautil.CrashReporter.checkCommandExit();
				#end
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
			case "multi-command":
				if (args.length > 0)
				{
					var commands = args.join(" ").split(";");
					for (cmd in commands)
					{
						if (cmd.trim() != "")
						{
							this.executeCommand(cmd.trim());
						}
					}
				}
				else
				{
					print("Error: multi-command requires at least one command.");
				}

			case "testTrapLink":
				@:privateAccess
				if (archipelago.APEntryState.inArchipelagoMode)
					if (args.length > 0)
						archipelago.APGameState.instance?.doTrapLink({
							source: "apTest",
							trap_name: args.join(" "),
							time: haxe.Timer.stamp()
						});

						if (!archipelago.APEntryState.inArchipelagoMode)
						{
							print("Error: You can only use this command in Archipelago mode.");
						}

			case "runCode":
				if (args.length > 0)
				{
					print("Running code internally...");
					try {
						var value = yutautil.save.FuncEmbed.runFunctionFromString(args.join(" "), {
							cmds: this,
							vars: this.variables,
							executeCommand: this.executeCommand,
							print: print,
							FlxG: FlxG,
							FlxState: FlxState,
							currentState: FlxG.state,
							help: function():Void {
								print("By using the keyword 'this' in the code, you can access certain aspects of the game engine:");
								print(" - 'cmds': Access to the CommandPrompt instance, allowing you to call commands.");
								print(" - 'vars': Access to the variables map, allowing you to get/set variables.");
								print(" - 'executeCommand': A function to execute cmd commands from within the code.");
								print(" - 'print': A function to print messages to the console.");
								print(" - 'FlxG': Access to the FlxG instance, allowing you to use its methods and properties.");
								print(" - 'FlxState': Access to the FlxState class, allowing you to use its methods and properties.");
								print(" - 'currentState': Access to the current game state, allowing you to interact with it.");
								print(" - 'help': A function that prints this help message.");
								print("You can use these to interact with the game engine and perform various actions.");
								print("If you have any questions, ask the developer \"Yutamon\" for more information.");
							}
						}, false, "this");
						print("Code executed. Result: " + value);
					} catch (e:Dynamic) {
						print("Critical Error while executing or parsing code: " + e);
						if (e != null) {
							print("Type: " + Type.getClassName(Type.getClass(e)));
							if (Reflect.hasField(e, "message")) {
								print("Message: " + Reflect.field(e, "message"));
							}
							if (Reflect.hasField(e, "stack")) {
								print("Stack: " + Reflect.field(e, "stack"));
							} else if (e.stack != null) {
								print("Stack: " + e.stack);
							}
							if (Reflect.hasField(e, "toString")) {
								print("toString: " + e.toString());
							}
						}
						print("Full exception: " + Std.string(e));
					}
				}
				else
				{
					print("Error: runCode requires at least one argument.");
				}

			case "yscript":
				if (args.length == 0) {
					print("YScript Test Environment");
					print("Commands:");
					print("  yscript load <file>    - Load script file (from export/ or absolute path)");
					print("  yscript run <code>     - Execute YScript code directly");
					print("  yscript test          - Enter interactive test mode");
					print("  yscript vars          - Show current script variables");
					print("  yscript funcs         - Show available functions");
					print("  yscript inspect [name] - Show all info or inspect specific item");
					print("  yscript info          - Show environment status");
					print("  yscript reset         - Reset script environment");
				} else {
					handleYScriptCommand(args);
				}

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
			case "toggleTraces":
				if (args.length == 0)
				{
					ClientPrefs.data.disableHaxeTraces = !ClientPrefs.data.disableHaxeTraces;
					ClientPrefs.saveSettings();
					print("Disable Haxe Traces is now set to: " + ClientPrefs.data.disableHaxeTraces);
				}
				else
				{
					print("Error: toggleHaxeTraces does not accept any arguments.");
				}
			case "exit":
				this.active = false;
				FlxG.autoPause = false;
				MusicBeatState.isClosing = true;
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
					this.switchState("states.ExitState");
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
			case "sizeState":
				{
					print("Checking State Memory Usage... Warning: This may take a while, or crash the game if the state is too large.");
					var stateClassName = Type.getClassName(Type.getClass(FlxG.state));
					var stateClass:Class<Dynamic> = Type.getClass(FlxG.state);
					var size:Dynamic;
					if (args.length == 0)
					{
						size = FlxG.state.realSizeOf();
						print("State size (bytes): " + size);
					}
					else if (args.length == 1)
					{
						var arg = args[0].toLowerCase();
						var sizeEnum = switch (arg) {
							case "bytes": yutautil.CollectionUtils.Size.B;
							case "kb": yutautil.CollectionUtils.Size.KB;
							case "mb": yutautil.CollectionUtils.Size.MB;
							case "auto": yutautil.CollectionUtils.Size.Auto;
							default: null;
						}
						if (sizeEnum == null)
						{
							print("Error: Invalid argument for sizeState. Use one of: bytes, kb, mb, auto.");
						}
						else
						{
							size = FlxG.state.sizeIn(sizeEnum);
							print("State size (" + arg + "): " + size);
						}
					}
					else
					{
						print("Error: sizeState accepts at most one argument.");
					}
				}

			case "stateInfo":
				if (args.length == 0)
				{
					var stateRep:FieldMap = new Fields(FlxG.state);
					print("State Information:");
					print("--------------------------------");
					print("State as object: " + stateRep.getFields());
					print("Current State: " + Type.getClassName(Type.getClass(FlxG.state)));
					print("State Size (bytes): " + FlxG.state.realSizeOf());
					print("State Size (KB): " + FlxG.state.sizeIn(yutautil.CollectionUtils.Size.KB));
					print("State Size (MB): " + FlxG.state.sizeIn(yutautil.CollectionUtils.Size.MB));
				}
				else
				{
					print("Error: stateInfo does not accept any arguments.");
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
				if (args.length == 0) {
					print("Debug commands:");
					print("  debug toggle - Toggle debug overlay");
					print("  debug states - List all available state classes");
					print("  debug static <stateClass> - View static properties of a state class");
					print("  debug get <stateClass> <property> - Get static property value");
					print("  debug set <stateClass> <property> <value> - Set static property value");
					print("  debug aprilFools - Enable April Fools debug mode");
					print("  debug flip - Toggle APFlip state");
				} else {
					switch (args[0]) {
						case "toggle":
							debug.DebugManager.toggleDebugOverlay();
							print("Debug overlay toggled");
						case "states":
							var states = getAllStateClasses();
							print("Available state classes:");
							for (name in states.keys()) {
								print("  " + name);
							}
						case "static":
							if (args.length >= 2) {
								var stateName = args[1];
								var states = getAllStateClasses();
								var stateClass = states.get(stateName);
								if (stateClass != null) {
									var props = getStaticProperties(stateClass);
									print('Static properties of ${stateName}:');
									for (prop in props) {
										var value = getStaticProperty(stateClass, prop);
										print('  ${prop}: ${Std.string(value)}');
									}
								} else {
									print('State class not found: ${stateName}');
								}
							} else {
								print("Usage: debug static <stateClass>");
							}
						case "get":
							if (args.length >= 3) {
								var stateName = args[1];
								var propName = args[2];
								var states = getAllStateClasses();
								var stateClass = states.get(stateName);
								if (stateClass != null) {
									var value = getStaticProperty(stateClass, propName);
									print('${stateName}.${propName} = ${Std.string(value)}');
								} else {
									print('State class not found: ${stateName}');
								}
							} else {
								print("Usage: debug get <stateClass> <property>");
							}
						case "set":
							if (args.length >= 4) {
								var stateName = args[1];
								var propName = args[2];
								var valueStr = args.slice(3).join(" ");
								var states = getAllStateClasses();
								var stateClass = states.get(stateName);
								if (stateClass != null) {
									// Try to parse the value
									var value:Dynamic = valueStr;
									if (valueStr == "true") value = true;
									else if (valueStr == "false") value = false;
									else {
										var intValue = Std.parseInt(valueStr);
										if (intValue != null) value = intValue;
										else {
											var floatValue = Std.parseFloat(valueStr);
											if (!Math.isNaN(floatValue)) value = floatValue;
										}
									}

									var success = setStaticProperty(stateClass, propName, value);
									if (success) {
										print('Set ${stateName}.${propName} = ${Std.string(value)}');
									} else {
										print('Failed to set ${stateName}.${propName}');
									}
								} else {
									print('State class not found: ${stateName}');
								}
							} else {
								print("Usage: debug set <stateClass> <property> <value>");
							}
						case "aprilFools":
							yutautil.AprilFools.debug = true;
							print("April Fools debug mode enabled.");
						case "flip":
							backend.MusicBeatState.APFlip = !backend.MusicBeatState.APFlip;
							print("APFlip toggled. Current state: " + backend.MusicBeatState.APFlip);
						default:
							print("Unknown debug command. Use 'debug' for help.");
					}
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

			case "saveState":
				if (args.length == 0) {
					// Save with auto-generated filename
					print("Saving current state with auto-generated filename...");
					print("Note: If you want to specify a custom filename, use: saveState 'filename'");
					print("Warning: This may take a while depending on the state size.");
					print("Do not close the game or switch states until the save is complete, or you get notified of success, as this may corrupt the save file.");
					var success = yutautil.save.StateSerializer.saveCurrentState();
					if (success) {
						print("Current state saved successfully with auto-generated filename.");
					} else {
						print("Error: Failed to save current state.");
					}
				} else if (args.length == 1) {
					// Save with custom filename
					var filename = args[0];
					print("Saving current state as: " + filename + ".json");
					print("Warning: This may take a while depending on the state size.");
					print("Do not close the game or switch states until the save is complete, or you get notified of success, as this may corrupt the save file.");
					var success = yutautil.save.StateSerializer.saveCurrentState(filename);
					if (success) {
						print("Current state saved successfully as: " + filename + ".json");
					} else {
						print("Error: Failed to save current state.");
					}
				} else {
					print("Error: saveState accepts 0 or 1 arguments. Usage: saveState [filename]");
				}

			case "loadState":
				if (args.length == 1) {
					var filename = args[0];
					var success = yutautil.save.StateSerializer.loadAndSwitchToState(filename);
					if (success) {
						print("State loaded and switched successfully: " + filename);
					} else {
						print("Error: Failed to load state: " + filename);
					}
				} else {
					print("Error: loadState requires exactly one argument. Usage: loadState <filename>");
				}

			case "listSaves":
				if (args.length == 0) {
					var saves = yutautil.save.StateSerializer.listSaveFiles();
					if (saves.length == 0) {
						print("No save files found.");
					} else {
						print("Available save files:");
						for (i in 0...saves.length) {
							print("  " + (i + 1) + ". " + saves[i]);
						}
					}
				} else {
					print("Error: listSaves does not accept any arguments.");
				}

			case "deleteSave":
				if (args.length == 1) {
					var filename = args[0];
					var success = yutautil.save.StateSerializer.deleteSaveFile(filename);
					if (success) {
						print("Save file deleted successfully: " + filename);
					} else {
						print("Error: Failed to delete save file: " + filename);
					}
				} else {
					print("Error: deleteSave requires exactly one argument. Usage: deleteSave <filename>");
				}

			case "serializeObject":
				if (args.length == 1) {
					var objectPath = args[0];
					try {
						// Parse object path (e.g., "FlxG.state" or "this.currentState")
						var obj:Dynamic = null;
						if (objectPath == "FlxG.state" || objectPath == "this.currentState") {
							obj = FlxG.state;
						} else {
							// Try to resolve from current state
							var parts = objectPath.split('.');
							obj = FlxG.state;
							for (part in parts) {
								if (obj != null) {
									obj = Reflect.field(obj, part);
								}
							}
						}

						if (obj != null) {
							var serialized = yutautil.save.StateSerializer.createSerializableObject(obj);
							print("Object serialized successfully:");
							print("  Class: " + serialized.CLASS);
							print("  Type: " + serialized.TYPE);
							print("  Timestamp: " + serialized.TIMESTAMP);
							print("  Fields: " + Reflect.fields(serialized.FIELDS).length + " field(s)");
						} else {
							print("Error: Object not found at path: " + objectPath);
						}
					} catch (e:Dynamic) {
						print("Error serializing object: " + e);
					}
				} else {
					print("Error: serializeObject requires exactly one argument. Usage: serializeObject <objectPath>");
				}

			case "testSerialization":
				try {
					print("=== Creating Random Complex Object ===");

					// Create a complex test object with nested structures
					var testObj = {
						id: Math.floor(Math.random() * 1000),
						name: "TestObject_" + Date.now().toString(),
						timestamp: Date.now().getTime(),
						settings: {
							enabled: Math.random() > 0.5,
							volume: Math.random(),
							difficulty: Math.floor(Math.random() * 5) + 1,
							options: ["option1", "option2", "option3"]
						},
						data: new Map<String, Dynamic>(),
						history: [],
						metadata: {
							version: "1.0.0",
							creator: "SerializationTest",
							tags: ["test", "random", "complex"]
						}
					};

					// Add some random data to the map
					for (i in 0...5) {
						testObj.data.set("key_" + i, {
							value: Math.random() * 100,
							type: "random_data_" + i,
							active: Math.random() > 0.3
						});
					}

					// Add some history entries
					for (i in 0...3) {
						testObj.history.push({
							action: "action_" + i,
							timestamp: Date.now().getTime() - (i * 1000),
							data: "Some random data: " + Math.random()
						});
					}

					print("Random object created with:");
					print("  ID: " + testObj.id);
					print("  Name: " + testObj.name);
					print("  Settings enabled: " + testObj.settings.enabled);
					print("  Data entries: " + Lambda.count(testObj.data));
					print("  History entries: " + testObj.history.length);

					print("\n=== Testing Serialization ===");

					// Test serialization
					var startTime = haxe.Timer.stamp();
					var serialized = yutautil.save.StateSerializer.createSerializableObject(testObj);
					var serializeTime = haxe.Timer.stamp() - startTime;

					if (serialized != null) {
						print("[OK] Serialization successful!");
						print("  Class: " + serialized.CLASS);
						print("  Type: " + serialized.TYPE);
						print("  Version: " + serialized.VERSION);
						print("  Total Objects: " + serialized.METADATA.totalObjects);
						print("  Max Depth: " + serialized.METADATA.maxDepth);
						print("  Has Circular Refs: " + serialized.METADATA.hasCircularRefs);
						print("  Object Types: " + serialized.METADATA.objectTypes.join(", "));
						print("  Serialization Time: " + Math.round(serializeTime * 1000) + "ms");

						print("\n=== Testing Deserialization ===");

						// Test deserialization
						var deserializeStart = haxe.Timer.stamp();
						var restored = yutautil.save.StateSerializer.restoreFromSerializedObject(serialized);
						var deserializeTime = haxe.Timer.stamp() - deserializeStart;

						if (restored != null) {
							print("[OK] Deserialization successful!");
							print("  Deserialization Time: " + Math.round(deserializeTime * 1000) + "ms");

							// Verify some data integrity
							var restoredObj:Dynamic = restored;
							var dataMatches = (restoredObj.id == testObj.id &&
											  restoredObj.name == testObj.name &&
											  restoredObj.settings.enabled == testObj.settings.enabled);

							print("  Data Integrity Check: " + (dataMatches ? "[PASS] PASSED" : "[FAIL] FAILED"));

							if (restoredObj.history != null) {
								print("  History Restored: " + restoredObj.history.length + " entries");
							}

							var totalTime = Math.round((serializeTime + deserializeTime) * 1000);
							print("  Total Time: " + totalTime + "ms");

						} else {
							print("[FAIL] Deserialization failed!");
						}
					} else {
						print("[FAIL] Serialization failed!");
					}

				} catch (e:Dynamic) {
					print("Error during serialization test: " + e);
				}

			case "uno":
				this.handleUnoCommand(args);

			case "unoSim":
				var maxTurns = args.length > 0 ? Std.parseInt(args[0]) : null;
				this.startUnoSimulation(maxTurns);

			case "traceInfo":
				if (args.length == 0) {
					print(backend.modules.TraceManager.getQueueInfo());
				} else {
					print("Error: traceInfo does not accept any arguments.");
				}

			case "traceLimit":
				if (args.length == 0) {
					print("Trace limiting commands:");
					print("  traceLimit toggle - Toggle frame-based trace limiting");
					print("  traceLimit set <number> - Set max traces per frame");
					print("  traceLimit status - Show current limit settings");
				} else {
					switch (args[0]) {
						case "toggle":
							backend.ClientPrefs.data.enableFrameTraceLimiting = !backend.ClientPrefs.data.enableFrameTraceLimiting;
							backend.ClientPrefs.saveSettings();
							print("Frame trace limiting: " + (backend.ClientPrefs.data.enableFrameTraceLimiting ? "ENABLED" : "DISABLED"));
						case "set":
							if (args.length >= 2) {
								var limit = Std.parseInt(args[1]);
								if (limit != null && limit > 0 && limit <= 50) {
									backend.ClientPrefs.data.maxTracesPerFrame = limit;
									backend.ClientPrefs.saveSettings();
									print("Max traces per frame set to: " + limit);
								} else {
									print("Error: Limit must be a number between 1 and 50.");
								}
							} else {
								print("Usage: traceLimit set <number>");
							}
						case "status":
							print("Frame Trace Limiting Status:");
							print("  Enabled: " + backend.ClientPrefs.data.enableFrameTraceLimiting);
							print("  Max per frame: " + backend.ClientPrefs.data.maxTracesPerFrame);
							print("  Threading: " + backend.ClientPrefs.data.useTraceThreading);
							print("  Trace mode: " + backend.ClientPrefs.data.traceMode);
						default:
							print("Unknown traceLimit command. Use 'traceLimit' for help.");
					}
				}

			#if sys
			case "traceThread":
				if (args.length == 0) {
					print("Trace threading commands:");
					print("  traceThread toggle - Toggle trace threading");
					print("  traceThread status - Show thread status");
					print("  traceThread restart - Restart trace thread");
				} else {
					switch (args[0]) {
						case "toggle":
							backend.ClientPrefs.data.useTraceThreading = !backend.ClientPrefs.data.useTraceThreading;
							backend.ClientPrefs.saveSettings();
							print("Trace threading: " + (backend.ClientPrefs.data.useTraceThreading ? "ENABLED" : "DISABLED"));
							if (!backend.ClientPrefs.data.useTraceThreading) {
								print("Note: Thread will stop on next frame update.");
							}
						case "status":
							print(backend.modules.TraceManager.getQueueInfo());
						case "restart":
							print("Restarting trace thread...");
							backend.modules.TraceManager.stopTraceThread();
							if (backend.ClientPrefs.data.useTraceThreading) {
								print("Thread will restart automatically on next update.");
							} else {
								print("Note: Threading is disabled. Enable it first with 'traceThread toggle'.");
							}
						default:
							print("Unknown traceThread command. Use 'traceThread' for help.");
					}
				}
			#end

			case "stressTrace":
				if (args.length == 0) {
					print("Trace stress testing commands:");
					print("  stressTrace burst <count> - Send burst of traces");
					print("  stressTrace spam <duration> - Spam traces for X seconds");
					print("  stressTrace flood - Continuous trace flood (use with caution!)");
				} else {
					switch (args[0]) {
						case "burst":
							var count = args.length >= 2 ? Std.parseInt(args[1]) : 10;
							if (count == null || count < 1 || count > 1000) {
								print("Error: Count must be between 1 and 1000.");
								return;
							}
							print("Sending " + count + " trace burst...");
							for (i in 0...count) {
								trace("Stress test trace #" + (i + 1) + " - Frame limiting should handle this!");
							}
							print("Burst complete. Check trace info for queue status.");
						case "spam":
							var duration = args.length >= 2 ? Std.parseFloat(args[1]) : 1.0;
							if (Math.isNaN(duration) || duration < 0.1 || duration > 10.0) {
								print("Error: Duration must be between 0.1 and 10.0 seconds.");
								return;
							}
							print("Starting trace spam for " + duration + " seconds...");
							var startTime = haxe.Timer.stamp();
							var counter = 0;
							while ((haxe.Timer.stamp() - startTime) < duration) {
								trace("Spam trace #" + (++counter) + " at " + (haxe.Timer.stamp() - startTime));
								Sys.sleep(0.001); // Small delay to prevent total system lock
							}
							print("Spam complete. Sent " + counter + " traces in " + duration + " seconds.");
						case "flood":
							print("WARNING: Starting continuous trace flood!");
							print("This will spam traces until you restart. Use Ctrl+C to stop.");
							print("Starting in 3 seconds...");
							Sys.sleep(3);
							var counter = 0;
							while (true) {
								trace("FLOOD TRACE #" + (++counter) + " - FRAME LIMITING TEST");
								if (counter % 100 == 0) {
									print("Flood status: " + counter + " traces sent");
								}
							}
						default:
							print("Unknown stressTrace command. Use 'stressTrace' for help.");
					}
				}

			case "flushTraces":
				if (args.length == 0) {
					print("Flushing all queued traces...");
					backend.modules.TraceManager.flushAllQueuedTraces();
					print("Trace flush complete. Check console for output.");
				} else {
					print("Error: flushTraces does not accept any arguments.");
				}

			case "stateEdit":
				if (args.length == 0) {
					print("State editing commands:");
					print("  stateEdit list - List all properties of current state");
					print("  stateEdit get <property> - Get property value");
					print("  stateEdit set <property> <value> - Set property value");
					print("  stateEdit navigate <property> - Navigate into complex object");
				} else {
					switch (args[0]) {
						case "list":
							var fields = Reflect.fields(FlxG.state);
							print("Current state properties:");
							for (field in fields) {
								if (!Reflect.isFunction(Reflect.field(FlxG.state, field))) {
									var value = Reflect.field(FlxG.state, field);
									var typeStr = Type.typeof(value);
									print('  ${field}: ${Std.string(typeStr)}');
								}
							}
						case "get":
							if (args.length >= 2) {
								var propName = args[1];
								var value = Reflect.field(FlxG.state, propName);
								print('${propName} = ${Std.string(value)}');
							} else {
								print("Usage: stateEdit get <property>");
							}
						case "set":
							if (args.length >= 3) {
								var propName = args[1];
								var valueStr = args.slice(2).join(" ");

								// Try to parse the value
								var value:Dynamic = valueStr;
								if (valueStr == "true") value = true;
								else if (valueStr == "false") value = false;
								else {
									var intValue = Std.parseInt(valueStr);
									if (intValue != null) value = intValue;
									else {
										var floatValue = Std.parseFloat(valueStr);
										if (!Math.isNaN(floatValue)) value = floatValue;
									}
								}

								try {
									Reflect.setField(FlxG.state, propName, value);
									print('Set ${propName} = ${Std.string(value)}');
								} catch (e:Dynamic) {
									print('Failed to set ${propName}: ${e}');
								}
							} else {
								print("Usage: stateEdit set <property> <value>");
							}
						default:
							print("Unknown stateEdit command. Use 'stateEdit' for help.");
					}
				}

			case "testTrap":
				#if ARCHIPELAGO_ALLOWED
				// Check if we're in a valid state for testing (not AP mode, not PlayState)
				if (archipelago.APEntryState.inArchipelagoMode) {
					print("Error: Cannot test High Quality Trap while in Archipelago mode.");
					return;
				}

				if (Std.isOfType(FlxG.state, states.PlayState)) {
					print("Error: Cannot test High Quality Trap while in PlayState.");
					return;
				}

				if (args.length == 0) {
					print("High Quality Trap Testing Commands:");
					print("  testTrap start - Download SiivaGunner repo and enter testing mode");
					print("  testTrap exit - Exit testing mode and return to normal engine");
					print("  testTrap status - Show current trap status");
					return;
				}

				switch (args[0].toLowerCase()) {
					case "start":
						print("Starting High Quality Trap testing mode...");

						// Enter testing mode with state restrictions first
						backend.MusicBeatState.enterTrapTestingMode();

						backend.GitHubAPI.setAuthToken("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");

						// Initialize the trap manager (but don't activate yet - let waiting state handle it)
						archipelago.HighQualityTrapManager.initialize();

						// Switch to waiting state which will handle the download
						FlxG.switchState(new states.HighQualityTrapWaitingState());

						print("High Quality Trap testing mode activated!");
						print("Downloading repository... Please wait and do not press any keys.");
						print("The testing interface will appear once download is complete.");
						print("Use 'testTrap exit' to leave testing mode when done.");

					case "exit":
						if (!backend.MusicBeatState.isTrapTestingMode()) {
							print("Error: Not currently in High Quality Trap testing mode.");
							return;
						}

						print("Exiting High Quality Trap testing mode...");

						// Deactivate trap and cleanup
						archipelago.HighQualityTrapManager.deactivateTrap();

						// Exit testing mode
						backend.MusicBeatState.exitTrapTestingMode();

						// Return to main menu
						FlxG.switchState(new states.MainMenuState());
						print("High Quality Trap testing mode exited. Returned to normal engine.");

					case "status":
						print(archipelago.HighQualityTrapManager.getStatusInfo());
						if (backend.MusicBeatState.isTrapTestingMode()) {
							print("Testing Mode: ACTIVE");
							print("Allowed States: HighQualityTrapWaitingState, HighQualityTrapTestState, PlayState");
							if (archipelago.HighQualityTrapManager.needsWaitingState()) {
								print("Status: Downloading repository...");
							} else {
								print("Status: Ready for testing");
							}
						} else {
							print("Testing Mode: INACTIVE");
						}

					default:
						print("Unknown testTrap command. Use 'testTrap' for help.");
				}
				#else
				print("Error: High Quality Trap testing requires ARCHIPELAGO_ALLOWED compilation flag.");
				#end

			case "debugSanity":
				#if ARCHIPELAGO_ALLOWED
				if (archipelago.APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
					archipelago.APEntryState.apGame.debugSanityItems();
				} else {
					print("Error: Not in Archipelago mode or AP game instance not available.");
				}
				#else
				print("Error: Sanity debugging requires ARCHIPELAGO_ALLOWED compilation flag.");
				#end

			case "refreshSanity":
				#if ARCHIPELAGO_ALLOWED
				if (archipelago.APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
					print("Refreshing sanity items...");
					archipelago.APEntryState.apGame.refreshSanityItems();
					print("Sanity item refresh completed.");
				} else {
					print("Error: Not in Archipelago mode or AP game instance not available.");
				}
				#else
				print("Error: Sanity refresh requires ARCHIPELAGO_ALLOWED compilation flag.");
				#end

			case "forceSanitySync":
				#if ARCHIPELAGO_ALLOWED
				if (archipelago.APEntryState.inArchipelagoMode && archipelago.APEntryState.apGame != null) {
					print("Forcing sanity item synchronization with save data...");

					// Get all unlocked sanity items
					var unlockedItems = archipelago.APEntryState.apGame.unlockedSanityItems;
					var count = [for (key in unlockedItems.keys()) key].length;

					if (count > 0) {
						// Force save immediately using the public method
						var success = archipelago.APEntryState.apGame.forceSaveSanityItems();
						if (success) {
							print("Successfully synced " + count + " sanity items to save data.");
						} else {
							print("Error syncing sanity items to save data.");
						}
					} else {
						print("No sanity items to sync.");
					}
				} else {
					print("Error: Not in Archipelago mode or AP game instance not available.");
				}
				#else
				print("Error: Sanity sync requires ARCHIPELAGO_ALLOWED compilation flag.");
				#end

			case "testPriority":
				#if windows
				backend.window.PriorityTest.runBasicTests();
				#else
				print("Priority system is only available on Windows.");
				#end

			case "testMonitoring":
				#if windows
				backend.window.PriorityTest.testMonitoring();
				#else
				print("Priority monitoring is only available on Windows.");
				#end

			case "monitorPriority":
				#if windows
				backend.window.PriorityTest.monitorPriorityChanges();
				#else
				print("Priority monitoring is only available on Windows.");
				#end

			case "setPriority":
				#if windows
				if (args.length == 1) {
					var priority = Std.parseInt(args[0]);
					if (priority != null && priority >= 0 && priority <= 5) {
						var success = backend.window.Priority.setPriority(priority);
						if (success) {
							print('Priority set to ${priority} (${backend.window.Priority.getPriorityString()})');
						} else {
							print('Failed to set priority to ${priority}');
						}
					} else {
						print("Error: Priority must be a number between 0 and 5 (0=Idle, 1=Below Normal, 2=Normal, 3=Above Normal, 4=High, 5=Realtime)");
					}
				} else {
					print("Error: setPriority requires exactly one argument (priority level 0-5)");
				}
				#else
				print("Priority system is only available on Windows.");
				#end

			case "setPriorityString":
				#if windows
				if (args.length == 1) {
					var success = backend.window.Priority.setPriorityString(args[0]);
					if (success) {
						print('Priority set to "${args[0]}" (${backend.window.Priority.getPriorityString()})');
					} else {
						print('Failed to set priority to "${args[0]}". Valid options: Idle, Below Normal, Normal, Above Normal, High, Realtime');
					}
				} else {
					print("Error: setPriorityString requires exactly one argument (priority name)");
				}
				#else
				print("Priority system is only available on Windows.");
				#end

			case "getPriority":
				#if windows
				var priority = backend.window.Priority.getPriority();
				var priorityString = backend.window.Priority.getPriorityString();
				print('Current Priority: ${priority} (${priorityString})');
				#else
				print("Priority system is only available on Windows.");
				#end

			#if EFFICIENCY_MODE_ALLOWED
			case "enableEfficiencyMode":
				#if windows
				if (backend.window.EfficiencyMode.isSupported()) {
					var success = backend.window.EfficiencyMode.setEfficiencyMode(true);
					if (success) {
						print("Efficiency Mode enabled - power saving active");
						print("Status: " + backend.window.EfficiencyMode.getStatusString());
					} else {
						print("Failed to enable Efficiency Mode");
					}
				} else {
					print("Efficiency Mode is not supported on this system (Windows 11 22H2+ required)");
				}
				#else
				print("Efficiency Mode is only available on Windows.");
				#end

			case "disableEfficiencyMode":
				#if windows
				var success = backend.window.EfficiencyMode.setEfficiencyMode(false);
				if (success) {
					print("Efficiency Mode disabled - normal performance restored");
					print("Status: " + backend.window.EfficiencyMode.getStatusString());
				} else {
					print("Failed to disable Efficiency Mode");
				}
				#else
				print("Efficiency Mode is only available on Windows.");
				#end

			case "toggleEfficiencyMode":
				#if windows
				if (backend.window.EfficiencyMode.isSupported()) {
					var success = backend.window.EfficiencyMode.toggle();
					if (success) {
						print("Efficiency Mode toggled");
						print("Status: " + backend.window.EfficiencyMode.getStatusString());
					} else {
						print("Failed to toggle Efficiency Mode");
					}
				} else {
					print("Efficiency Mode is not supported on this system (Windows 11 22H2+ required)");
				}
				#else
				print("Efficiency Mode is only available on Windows.");
				#end

			case "getEfficiencyStatus":
				#if windows
				print("Efficiency Mode Status: " + backend.window.EfficiencyMode.getStatusString());
				print("Supported: " + (backend.window.EfficiencyMode.isSupported() ? "Yes" : "No"));
				print("Active: " + (backend.window.EfficiencyMode.isActive() ? "Yes" : "No"));
				print("Setting: " + (ClientPrefs.data.efficiencyMode ? "Enabled" : "Disabled"));
				#else
				print("Efficiency Mode is only available on Windows.");
				#end
			#end

			case "startPriorityMonitoring":
				#if windows
				var targetPriority = 2; // Default to Normal
				var forceLock = false;
				var interval = 1000.0;

				if (args.length >= 1) {
					var parsedPriority = Std.parseInt(args[0]);
					if (parsedPriority == null || parsedPriority < 0 || parsedPriority > 5) {
						print("Error: Target priority must be 0-5 (0=Idle, 1=Below Normal, 2=Normal, 3=Above Normal, 4=High, 5=Realtime)");
						return;
					}
					targetPriority = parsedPriority;
				}
				if (args.length >= 2) {
					forceLock = args[1].toLowerCase() == "true";
				}
				if (args.length >= 3) {
					var parsedInterval = Std.parseFloat(args[2]).asNullable();
					if (parsedInterval == null || parsedInterval < 100) {
						interval = 1000;
					} else {
						interval = parsedInterval;
					}
				}

				backend.window.Priority.startPriorityMonitoring(targetPriority, forceLock, interval);
				print('Started priority monitoring: Target=${backend.window.Priority.getPriorityStringFromLevel(targetPriority)}, Force-Lock=${forceLock}, Interval=${interval}ms');
				#else
				print("Priority system is only available on Windows.");
				#end

			case "stopPriorityMonitoring":
				#if windows
				backend.window.Priority.stopPriorityMonitoring();
				print("Stopped priority monitoring");
				#else
				print("Priority system is only available on Windows.");
				#end

			case "priorityStatus":
				#if windows
				var isMonitoring = backend.window.Priority.isMonitoring();
				var forceLockEnabled = backend.window.Priority.isForceLockEnabled();
				var targetPriority = backend.window.Priority.getTargetPriority();
				var currentPriority = backend.window.Priority.getPriority();

				print('Priority Status:');
				print('  Current: ${backend.window.Priority.getPriorityStringFromLevel(currentPriority)} (${currentPriority})');
				print('  Monitoring: ${isMonitoring ? "Active" : "Inactive"}');
				if (isMonitoring) {
					print('  Target: ${backend.window.Priority.getPriorityStringFromLevel(targetPriority)} (${targetPriority})');
					print('  Force-Lock: ${forceLockEnabled ? "Enabled" : "Disabled"}');
				}
				#else
				print("Priority system is only available on Windows.");
				#end

			case "setForceLock":
				#if windows
				if (args.length == 1) {
					var enabled = args[0].toLowerCase() == "true";
					backend.window.Priority.setForceLock(enabled);
					print('Force-lock ${enabled ? "enabled" : "disabled"}');
				} else {
					print("Error: setForceLock requires exactly one argument (true/false)");
				}
				#else
				print("Priority system is only available on Windows.");
				#end

			case "decodeError":
				if (args.length == 1) {
					try {
						var errorCode = args[0];
						var decoded = yutautil.TypeUtils.DetailedException.decodeErrorCode(errorCode);
						print("Error Code Decoded Successfully:");
						print("--------------------------------");
						print("Message: " + decoded.message);
						if (decoded.fileName != null) print("File: " + decoded.fileName);
						if (decoded.lineNumber != null) print("Line: " + decoded.lineNumber);
						if (decoded.className != null) print("Class: " + decoded.className);
						if (decoded.methodName != null) print("Method: " + decoded.methodName);
					} catch (e:Dynamic) {
						print("Error decoding error code: " + Std.string(e));
						print("Expected format: Exxx-xxxx-xxxx-... (hex values separated by dashes)");
					}
				} else {
					print("Error: decodeError requires exactly one argument (the error code).");
					print("Usage: decodeError E1A2B-3C4D-5E6F-...");
				}

			case "compile":
				if (args.length == 0) {
					print("YScript Compilation System");
					print("Commands:");
					print("  compile <source.ys> [output.ysc]  - Compile YScript file");
					print("  compile test <code>              - Test compile YScript code");
					print("  compile load <compiled.ysc>      - Load and test compiled script");
					print("  compile info                     - Show compilation system info");
				} else {
					handleCompileCommand(args);
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
		try {
			Sys.stdout().writeString(message + "\n");
		} catch (e:Dynamic) {
			var errStr = Std.string(e);
			if (errStr == "Custom([file_write,stdout])") {
				this.active = false;
				trace("No command interface detected. Disabling command prompt.");
			} else {
				trace("Error writing to stdout: " + errStr);
			}
		}
	}

	// UNO Game Methods
	private function handleUnoCommand(args:Array<String>):Void {
		if (args.length == 0) {
			print("UNO Commands:");
			print("  uno start [players] - Start a new UNO game with specified number of players (2-4)");
			print("  uno custom [players] - Start a UNO game with custom colors (Purple, Orange, Cyan, Pink)");
			print("  uno play <cardIndex> [color] - Play a card by index (use color for wild cards: red/blue/green/yellow)");
			print("  uno draw - Draw a card");
			print("  uno hand - Show your current hand");
			print("  uno top - Show the top card");
			print("  uno status - Show game status");
			print("  uno uno - Call UNO when you have one card left");
			print("  uno quit - End the current game");
			print("  uno help - Show detailed help");
			return;
		}

		var subCommand = args[0].toLowerCase();
		var subArgs = args.slice(1);

		switch (subCommand) {
			case "start":
				this.startUnoGame(subArgs);
			case "custom":
				this.startCustomUnoGame(subArgs);
			case "play":
				this.playUnoCard(subArgs);
			case "draw":
				this.drawUnoCard();
			case "hand":
				this.showUnoHand();
			case "top":
				this.showUnoTopCard();
			case "status":
				this.showUnoStatus();
			case "uno":
				this.callUno();
			case "quit":
				this.quitUnoGame();
			case "help":
				this.showUnoHelp();
			default:
				print("Unknown UNO command. Type 'uno' for available commands.");
		}
	}

	private function startUnoGame(args:Array<String>):Void {
		if (unoGame != null && unoGame.isGameActive) {
			print("A UNO game is already active! Type 'uno quit' to end it first.");
			return;
		}

		var playerCount = 2; // Default
		if (args.length > 0) {
			playerCount = Std.parseInt(args[0]);
			if (!playerCount.isReal(true) || playerCount < 2 || playerCount > 4) {
				print("Error: Player count must be between 2 and 4.");
				return;
			}
		}

		try {
			unoGame = new UnoGame();

			// Set up event handlers
			setupUnoEvents();

			// Add human player
			var humanPlayer = new UnoPlayer("human", "You", true);
			unoGame.addPlayer(humanPlayer);

			// Add CPU players
			var difficulties = [UnoDifficulty.EASY, UnoDifficulty.NORMAL, UnoDifficulty.HARD];
			for (i in 1...playerCount) {
				var difficulty = difficulties[(i - 1) % difficulties.length];
				var diffName = switch (difficulty) {
					case EASY: "Easy";
					case NORMAL: "Normal";
					case HARD: "Hard";
					case EXPERT: "Expert";
				}
				var cpu = new UnoCPU('cpu$i', 'CPU $i ($diffName)', difficulty);
				unoGame.addPlayer(cpu);
			}

			print('Starting UNO game with $playerCount players...');
			unoGame.startGame();

		} catch (e:Dynamic) {
			print("Error starting UNO game: " + e);
			unoGame = null;
		}
	}

	private function startCustomUnoGame(args:Array<String>):Void {
		if (unoGame != null && unoGame.isGameActive) {
			print("A UNO game is already active! Type 'uno quit' to end it first.");
			return;
		}

		var playerCount = 2; // Default
		if (args.length > 0) {
			playerCount = Std.parseInt(args[0]);
			if (!playerCount.isReal(true) || playerCount < 2 || playerCount > 4) {
				print("Error: Player count must be between 2 and 4.");
				return;
			}
		}

		try {
			// Create custom colors
			var customColors = UnoCard.createCustomColors([
				flixel.util.FlxColor.PURPLE,   // Purple replaces Red
				flixel.util.FlxColor.ORANGE,   // Orange replaces Yellow
				flixel.util.FlxColor.CYAN,     // Cyan replaces Blue
				flixel.util.FlxColor.PINK      // Pink replaces Green
			], ["Purple", "Orange", "Cyan", "Pink"]);

			unoGame = new UnoGame(customColors);

			// Set up event handlers
			setupUnoEvents();

			// Add human player
			var humanPlayer = new UnoPlayer("human", "You", true);
			unoGame.addPlayer(humanPlayer);

			// Add CPU players
			var difficulties = [UnoDifficulty.EASY, UnoDifficulty.NORMAL, UnoDifficulty.HARD];
			for (i in 1...playerCount) {
				var difficulty = difficulties[(i - 1) % difficulties.length];
				var diffName = switch (difficulty) {
					case EASY: "Easy";
					case NORMAL: "Normal";
					case HARD: "Hard";
					case EXPERT: "Expert";
				}
				var cpu = new UnoCPU('cpu$i', 'CPU $i ($diffName)', difficulty);
				unoGame.addPlayer(cpu);
			}

			print('Starting CUSTOM COLOR UNO game with $playerCount players...');
			print('Custom Colors: Purple, Orange, Cyan, Pink');
			unoGame.startGame();

		} catch (e:Dynamic) {
			print("Error starting custom UNO game: " + e);
			unoGame = null;
		}
	}

	private function setupUnoEvents():Void {
		unoGame.onGameStart = function() {
			print("UNO Game Started!");
			print("==================");
		};

		unoGame.onRoundStart = function(roundNum:Int) {
			print('\nRound $roundNum started!');
			print('Starting card: ${unoGame.deck.getTopCard().toString()}');
			print('Current color: ${unoGame.currentColor}');
			showUnoStatus();
		};

		unoGame.onCardPlayed = function(player:UnoPlayer, card:UnoCard) {
			var cardStr = card.toString();
			if (player.isHuman) {
				print('You played: $cardStr');
			} else {
				print('${player.name} played: $cardStr');
			}

			// Check for special effects
			switch (card.type) {
				case SKIP:
					print('Next player is skipped!');
				case REVERSE:
					print('Direction reversed!');
				case DRAW_TWO:
					print('Next player draws 2 cards!');
				case WILD_DRAW_FOUR:
					print('Wild Draw Four! Next player draws 4 cards!');
				case WILD:
					print('Wild card played!');
				default:
					// No special message for number cards
			}
		};

		unoGame.onPlayerDraw = function(player:UnoPlayer, count:Int) {
			if (player.isHuman) {
				print('You drew $count card(s)');
			} else {
				print('${player.name} drew $count card(s)');
			}
		};

		unoGame.onUnoCall = function(player:UnoPlayer) {
			if (player.isHuman) {
				print('You called UNO!');
			} else {
				print('${player.name} called UNO!');
			}
		};

		unoGame.onUnoPenalty = function(player:UnoPlayer) {
			if (player.isHuman) {
				print('WARNING: You were penalized for not calling UNO! (+2 cards)');
			} else {
				print('WARNING: ${player.name} was penalized for not calling UNO! (+2 cards)');
			}
		};

		unoGame.onWildColorChosen = function(color:UnoColor) {
			var colorStr = switch (color) {
				case RED: "Red";
				case BLUE: "Blue";
				case GREEN: "Green";
				case YELLOW: "Yellow";
				default: Std.string(color);
			}
			print('Color changed to: $colorStr');
		};

		unoGame.onRoundEnd = function(winner:UnoPlayer, points:Int) {
			print('\n${winner.name} won the round!');
			print('Points earned: $points');
			print('\nCurrent scores:');
			for (player in unoGame.players) {
				var icon = player.isHuman ? "[YOU]" : "[CPU]";
				print('  $icon ${player.name}: ${player.score} points');
			}
		};

		unoGame.onGameEnd = function(winner:UnoPlayer) {
			print('\n*** GAME OVER! ***');
			print('${winner.name} wins with ${winner.score} points!');
			print('\nFinal scores:');
			for (player in unoGame.players) {
				var icon = player.isHuman ? "[YOU]" : "[CPU]";
				print('  $icon ${player.name}: ${player.score} points');
			}
			print('===================================');
			unoGame = null;
		};
	}

	private function playUnoCard(args:Array<String>):Void {
		if (unoGame == null || !unoGame.isRoundActive) {
			print("No active UNO game. Type 'uno start' to begin.");
			return;
		}

		if (args.length == 0) {
			print("Error: Specify card index to play (e.g., 'uno play 0')");
			showUnoHand();
			return;
		}

		var currentPlayer = unoGame.turnManager.getCurrentPlayer();
		if (!currentPlayer.isHuman) {
			print("It's not your turn!");
			return;
		}

		var cardIndex = Std.parseInt(args[0]);
		if (cardIndex == null || cardIndex < 0 || cardIndex >= currentPlayer.hand.getSize()) {
			print("Error: Invalid card index. Must be between 0 and " + (currentPlayer.hand.getSize() - 1));
			showUnoHand();
			return;
		}

		var card = currentPlayer.hand.cards[cardIndex];
		var chosenColor:UnoColor = null;

		// Handle wild cards
		if (card.isWildCard()) {
			if (args.length < 2) {
				print("Error: Wild cards require a color choice (red/blue/green/yellow)");
				return;
			}

			chosenColor = switch (args[1].toLowerCase()) {
				case "red": UnoColor.RED;
				case "blue": UnoColor.BLUE;
				case "green": UnoColor.GREEN;
				case "yellow": UnoColor.YELLOW;
				default: null;
			}

			if (chosenColor == null) {
				print("Error: Invalid color. Use red, blue, green, or yellow.");
				return;
			}
		}

		try {
			var success = unoGame.playCard(currentPlayer, cardIndex, chosenColor);
			if (!success) {
				print("Cannot play that card! It doesn't match the top card or current color.");
				print('Top card: ${unoGame.deck.getTopCard().toString()}');
				print('Current color: ${unoGame.currentColor}');
			} else {
				// Auto-advance through CPU turns
				advanceThroughCPUTurns();
			}
		} catch (e:Dynamic) {
			print("Error playing card: " + e);
		}
	}

	private function drawUnoCard():Void {
		if (unoGame == null || !unoGame.isRoundActive) {
			print("No active UNO game. Type 'uno start' to begin.");
			return;
		}

		var currentPlayer = unoGame.turnManager.getCurrentPlayer();
		if (!currentPlayer.isHuman) {
			print("It's not your turn!");
			return;
		}

		try {
			unoGame.drawCards(currentPlayer, 1);
			// Auto-advance through CPU turns
			advanceThroughCPUTurns();
		} catch (e:Dynamic) {
			print("Error drawing card: " + e);
		}
	}

	private function showUnoHand():Void {
		if (unoGame == null || !unoGame.isRoundActive) {
			print("No active UNO game. Type 'uno start' to begin.");
			return;
		}

		var humanPlayer = null;
		for (player in unoGame.players) {
			if (player.isHuman) {
				humanPlayer = player;
				break;
			}
		}

		if (humanPlayer == null) {
			print("No human player found!");
			return;
		}

		print('\n Your hand (${humanPlayer.hand.getSize()} cards):');
		print('===============');
		for (i in 0...humanPlayer.hand.cards.length) {
			var card = humanPlayer.hand.cards[i];
			var playable = card.canPlayOn(unoGame.deck.getTopCard()) ||
						  (card.color == unoGame.currentColor) ||
						  card.isWildCard();
			var indicator = playable ? "+" : "-";
			print('  [$i] $indicator ${card.toString()}');
		}
		print('===============');
		print('Top card: ${unoGame.deck.getTopCard().toString()}');
		print('Current color: ${unoGame.currentColor}');
	}

	private function showUnoTopCard():Void {
		if (unoGame == null || !unoGame.isRoundActive) {
			print("No active UNO game. Type 'uno start' to begin.");
			return;
		}

		print(' Top card: ${unoGame.deck.getTopCard().toString()}');
		print(' Current color: ${unoGame.currentColor}');
	}

	private function showUnoStatus():Void {
		if (unoGame == null || !unoGame.isRoundActive) {
			print("No active UNO game. Type 'uno start' to begin.");
			return;
		}

		print('\n= Game Status:');
		print('==========');
		print('Round: ${unoGame.roundNumber}');
		print('Current turn: ${unoGame.turnManager.getCurrentPlayer().name}');
		print('Direction: ${unoGame.turnManager.direction == CLOCKWISE ? "Clockwise" : "Counter-clockwise"}');
		print('Cards in deck: ${unoGame.deck.getRemainingCards()}');
		print('');
		print('\n- Players:');
		for (player in unoGame.players) {
			var icon = player.isHuman ? "[YOU]" : "[CPU]";
			var unoStatus = player.hand.isUno() && player.calledUno ? " (UNO!)" : "";
			var currentIndicator = player == unoGame.turnManager.getCurrentPlayer() ? " <--" : "";
			print('  $icon ${player.name}: ${player.hand.getSize()} cards - ${player.score} pts$unoStatus$currentIndicator');
		}
		print('============');
	}

	private function callUno():Void {
		if (unoGame == null || !unoGame.isRoundActive) {
			print("No active UNO game. Type 'uno start' to begin.");
			return;
		}

		var humanPlayer = null;
		for (player in unoGame.players) {
			if (player.isHuman) {
				humanPlayer = player;
				break;
			}
		}

		if (humanPlayer == null) {
			print("No human player found!");
			return;
		}

		var success = unoGame.callUno(humanPlayer);
		if (!success) {
			print("You can only call UNO when you have exactly one card!");
		}
	}

	private function quitUnoGame():Void {
		if (unoGame == null) {
			print("No UNO game is currently active.");
			return;
		}

		print("Ending UNO game...");
		unoGame.forceEndGame();
		unoGame = null;
		print("UNO game ended.");
	}

	private function showUnoHelp():Void {
		print('\nUNO Game Help');
		print('===================================');
		print('');
		print('Objective:');
		print('  Be the first to play all your cards to win the round.');
		print('  First player to reach 500 points wins the game!');
		print('');
		print('Card Types:');
		print('  Number Cards (0-9): Must match color or number');
		print('  Skip: Skip next player\'s turn');
		print('  Reverse: Reverse play direction');
		print('  Draw Two: Next player draws 2 cards');
		print('  Wild: Change color of play');
		print('  Wild Draw Four: Change color, next player draws 4');
		print('');
		print('Commands:');
		print('  uno hand - View your cards');
		print('  uno play <index> [color] - Play card by index');
		print('  uno draw - Draw a card');
		print('  uno uno - Call UNO when you have one card');
		print('  uno status - View game state');
		print('  uno quit - End game');
		print('');
		print('Rules:');
		print('  - Must call UNO when you have one card left');
		print('  - Wild cards require color choice (red/blue/green/yellow)');
		print('  - Can only play cards that match color, number, or type');
		print('  - Draw if you can\'t play');
		print('');
		print('Scoring:');
		print('  - Number cards: Face value');
		print('  - Action cards: 20 points');
		print('  - Wild cards: 50 points');
		print('===================================');
	}

	private function advanceThroughCPUTurns():Void {
		if (unoGame == null || !unoGame.isRoundActive) return;

		var maxTurns = 50; // Prevent infinite loops
		var turnCount = 0;

		while (unoGame.isRoundActive && !unoGame.turnManager.getCurrentPlayer().isHuman && turnCount < maxTurns) {
			turnCount++;
			var currentPlayer = unoGame.turnManager.getCurrentPlayer();

			if (Std.isOfType(currentPlayer, UnoCPU)) {
				var cpu = cast(currentPlayer, UnoCPU);

				// Small delay for CPU thinking (visual feedback)
				Sys.sleep(0.5);

				var playableCards = unoGame.getCurrentPlayerPlayableCards();

				if (playableCards.length > 0) {
					// Create game state for CPU decision
					var gameState = new UnoGameState();
					gameState.update(
						unoGame.players,
						currentPlayer,
						unoGame.turnManager.direction,
						unoGame.deck.getTopCard(),
						unoGame.currentColor,
						unoGame.deck.getRemainingCards(),
						unoGame.deck.getDiscardPileSize()
					);

					var cardIndex = cpu.chooseCard(unoGame.deck.getTopCard(), gameState);

					if (cardIndex >= 0 && cardIndex < currentPlayer.hand.getSize()) {
						var card = currentPlayer.hand.cards[cardIndex];
						var chosenColor:UnoColor = null;

						if (card.isWildCard()) {
							chosenColor = cpu.chooseWildColor();
						}

						// Auto-call UNO for CPU
						if (currentPlayer.hand.getSize() == 2) {
							cpu.autoCallUno();
						}

						// Try to play the card
						var success = unoGame.playCard(currentPlayer, cardIndex, chosenColor);
						if (!success) {
							// Card couldn't be played (probably due to draw stack), must draw instead
							print('${currentPlayer.name} cannot play card due to draw stack, drawing...');
							unoGame.drawCards(currentPlayer, 1);
						}
					} else {
						// CPU has no playable cards, must draw
						print('${currentPlayer.name} draws a card...');
						unoGame.drawCards(currentPlayer, 1);
					}
				} else {
					// Must draw cards
					print('[AI] ${currentPlayer.name} has no playable cards, drawing...');
					unoGame.drawCards(currentPlayer, 1);
				}

				// Check for UNO penalties
				unoGame.checkUnoPenalties();
			}
		}

		if (turnCount >= maxTurns) {
			print("Warning: CPU turn limit reached to prevent infinite loop");
		}

		// Show updated status after CPU turns
		if (unoGame.isRoundActive) {
			print('');
			showUnoStatus();
			if (unoGame.turnManager.getCurrentPlayer().isHuman) {
				print('\nYour turn! Type "uno hand" to see your cards.');
			}
		}
	}

	private function startUnoSimulation(?maxTurns:Int):Void {
		print("Starting UNO Simulation...");
		print("===================================");

		var maxTurns = maxTurns ?? 100;

		try {
			// Run the simulation using the existing UnoExample
			UnoExample.simulateGame(maxTurns);
		} catch (e:Dynamic) {
			print("Error during UNO simulation: " + e);
		}
	}

	// ═══════════════════════════════════════════════════════════════════════════════════════
	// YSCRIPT TEST ENVIRONMENT
	// ═══════════════════════════════════════════════════════════════════════════════════════

	private function handleYScriptCommand(args:Array<String>):Void {
		try {
			switch (args[0]) {
				case "load":
					if (args.length < 2) {
						print("Error: yscript load requires a file path");
						return;
					}
					loadYScriptFile(args[1]);

				case "run":
					if (args.length < 2) {
						print("Error: yscript run requires code to execute");
						return;
					}
					var code = args.slice(1).join(" ");
					runYScriptCode(code);

				case "test":
					enterYScriptTestMode();

				case "vars":
					showYScriptVariables();

				case "funcs":
					showYScriptFunctions();

				case "reset":
					resetYScriptEnvironment();

				case "inspect":
					if (args.length < 2) {
						showYScriptInspection();
					} else {
						inspectYScriptItem(args[1]);
					}

				case "info":
					showYScriptEnvironmentInfo();

				default:
					print("Unknown yscript command: " + args[0]);
					print("Use 'yscript' with no arguments to see available commands");
			}
		} catch (e:Dynamic) {
			print("YScript Error: " + e);
		}
	}

	private function loadYScriptFile(filePath:String):Void {
		resetYScriptEnvironment();

		var fullPath = filePath;

		// Check if it's a relative path, prepend export directory
		if (!haxe.io.Path.isAbsolute(filePath)) {
			fullPath = "./" + filePath;
		}

		if (yscriptTester.loadFromFile(fullPath)) {
			print("[SUCCESS] Successfully loaded YScript file: " + fullPath);
			showYScriptVariables();
		} else {
			print("[ERROR] Failed to load YScript file: " + yscriptTester.lastError);
		}
	}

	private function runYScriptCode(code:String):Void {
		if (yscriptTester == null) {
			resetYScriptEnvironment();
		}

		if (yscriptTester.loadFromSource(code, "<command-line>")) {
			var result = yscriptTester.execute();
			if (result != null) {
				print("[SUCCESS] Result: " + Std.string(result));
			} else {
				print("[SUCCESS] Code executed successfully (no return value)");
			}
		} else {
			print("[ERROR] YScript Error: " + yscriptTester.lastError);
		}
	}

	private function enterYScriptTestMode():Void {
		if (yscriptTester == null) {
			resetYScriptEnvironment();
		}

		print("[TEST] Entering YScript Interactive Test Mode");
		print("Type YScript commands, 'vars' to see variables, 'funcs' for functions, or 'exit' to quit");
		print("-----------------------------------------------");

		while (true) {
			Sys.print("yscript> ");
			var input = Sys.stdin().readLine().trim();

			if (input == "exit" || input == "quit") {
				print("Exiting YScript test mode");
				break;
			}

			if (input == "vars") {
				showYScriptVariables();
				continue;
			}

			if (input == "funcs") {
				showYScriptFunctions();
				continue;
			}

			if (input == "help") {
				print("YScript Test Mode Commands:");
				print("  vars  - Show current variables");
				print("  funcs - Show available functions");
				print("  exit  - Exit test mode");
				print("  Any YScript code to execute");
				continue;
			}

			if (input.length == 0) continue;

			// Execute the YScript code
			try {
				if (yscriptTester.loadFromSource(input, "<interactive>")) {
					var result = yscriptTester.execute();
					if (result != null) {
						print("=> " + Std.string(result));
					}
				} else {
					print("[ERROR] Error: " + yscriptTester.lastError);
					// Don't exit on error, continue interactive mode
				}
			} catch (e:Dynamic) {
				print("[EXCEPTION] Exception: " + Std.string(e));
				break; // Exit on exception as requested
			}
		}
	}

	private function showYScriptVariables():Void {
		if (yscriptTester == null || !yscriptTester.isReady) {
			print("[EMPTY] No YScript environment loaded");
			return;
		}

		var variables = yscriptTester.getVariables();
		if (variables.length == 0) {
			print("[EMPTY] No variables defined yet");
			return;
		}

		print("[VARS] YScript Variables (" + variables.length + "):");
		for (variable in variables) {
			var valueStr = Std.string(variable.value);
			if (valueStr.length > 50) {
				valueStr = valueStr.substr(0, 47) + "...";
			}
			print("   " + variable.name + ":" + variable.type + " = " + valueStr);
		}
	}

	private function showYScriptFunctions():Void {
		if (yscriptTester == null || !yscriptTester.isReady) {
			print("[EMPTY] No YScript environment loaded");
			return;
		}

		var functions = yscriptTester.getFunctions();
		if (functions.length == 0) {
			print("[EMPTY] No functions defined yet");
			print("   Built-in: printLine(), getTime()");
			print("   Registered classes: FlxG, Math, Std");
			return;
		}

		print("[INFO] YScript Functions (" + functions.length + "):");
		for (func in functions) {
			var signature = func.name + "(" + func.parameters.join(", ") + ")";
			if (func.returnType != "Void") {
				signature += ":" + func.returnType;
			}
			print("   " + signature);
		}
		print("   Built-in: printLine(msg:Dynamic), getTime():Float");
		print("   Registered classes: FlxG, Math, Std");
	}

	private function resetYScriptEnvironment():Void {
		if (yscriptTester != null) {
			yscriptTester.destroy();
		}

		yscriptTester = new yutautil.YScript();

		// Register useful Haxe functions for testing
		yscriptTester.registerHaxeFunction("printLine", function(msg:Dynamic) {
			print(Std.string(msg));
		});

		yscriptTester.registerHaxeFunction("getTime", function() {
			return haxe.Timer.stamp();
		});

		yscriptTester.registerHaxeClass("FlxG", flixel.FlxG);
		yscriptTester.registerHaxeClass("Math", Math);
		yscriptTester.registerHaxeClass("Std", Std);

		print("[RESET] YScript environment reset");
	}

	private function showYScriptInspection():Void {
		if (yscriptTester == null || !yscriptTester.isReady) {
			print("[EMPTY] No YScript environment loaded");
			return;
		}

		print("[INSPECT] YScript Environment Inspection");
		print("==================================");
		showYScriptVariables();
		print("");
		showYScriptFunctions();
	}

	private function inspectYScriptItem(name:String):Void {
		if (yscriptTester == null || !yscriptTester.isReady) {
			print("[EMPTY] No YScript environment loaded");
			return;
		}

		// Check if it's a variable first
		var varInfo = yscriptTester.getVariableInfo(name);
		if (varInfo != null) {
			print("[VAR] Variable: " + name);
			print("   Type: " + varInfo.type);
			print("   Value: " + Std.string(varInfo.value));
			return;
		}

		// Check if it's a function
		var funcInfo = yscriptTester.getFunctionInfo(name);
		if (funcInfo != null) {
			print("[FUNC] Function: " + name);
			print("   Parameters: " + funcInfo.parameters.join(", "));
			print("   Return Type: " + funcInfo.returnType);
			return;
		}

		print("[ERROR] Item '" + name + "' not found in YScript environment");
	}

	private function showYScriptEnvironmentInfo():Void {
		print("[STATUS] YScript Environment Status");
		print("===================================");
		print("   Ready: " + (yscriptTester != null ? yscriptTester.isReady : false));
		print("   Has Errors: " + (yscriptTester != null ? yscriptTester.hasErrors : false));
		if (yscriptTester != null && yscriptTester.lastError != null) {
			print("   Last Error: " + yscriptTester.lastError);
		}
		if (yscriptTester != null && yscriptTester.scriptPath != null) {
			print("   Script Path: " + yscriptTester.scriptPath);
		}
		if (yscriptTester != null && yscriptTester.isReady) {
			var varCount = yscriptTester.getVariableNames().length;
			var funcCount = yscriptTester.getFunctionNames().length;
			print("   Variables: " + varCount);
			print("   Functions: " + funcCount);
		}
	}

	// ═══════════════════════════════════════════════════════════════════════════════════════
	// YSCRIPT COMPILATION SYSTEM
	// ═══════════════════════════════════════════════════════════════════════════════════════

	private function handleCompileCommand(args:Array<String>):Void {
		try {
			switch (args[0]) {
				case "test":
					if (args.length < 2) {
						print("Error: compile test requires code to test");
						return;
					}
					var code = args.slice(1).join(" ");
					testCompileYScriptCode(code);

				case "load":
					if (args.length < 2) {
						print("Error: compile load requires a compiled file path");
						return;
					}
					loadCompiledYScript(args[1]);

				case "info":
					showCompilationSystemInfo();

				default:
					// Default: compile file
					if (args.length < 1) {
						print("Error: compile requires a source file path");
						return;
					}

					var sourceFile = args[0];
					var outputFile = args.length > 1 ? args[1] : null;
					compileYScriptFile(sourceFile, outputFile);
			}
		} catch (e:Dynamic) {
			print("Compilation Error: " + e);
		}
	}

	private function compileYScriptFile(sourceFile:String, ?outputFile:String):Void {
		var compiler = new yutautil.YScript();

		var fullSourcePath = sourceFile;
		// Check if it's a relative path, prepend current directory
		if (!haxe.io.Path.isAbsolute(sourceFile)) {
			fullSourcePath = "./" + sourceFile;
		}

		#if sys
		try {
			// Read source file
			var sourceCode = sys.io.File.getContent(fullSourcePath);
			print("[FILE] Reading source file: " + fullSourcePath);

			// Compile the source
			print("[COMPILE] Compiling YScript...");
			var compiled = compiler.compile(sourceCode, fullSourcePath);
			print("[SUCCESS] Compilation successful!");

			// Generate output file name if not provided
			if (outputFile == null) {
				var path = haxe.io.Path.withoutExtension(fullSourcePath);
				outputFile = path + ".ysc";
			}

			// Check if output path is relative
			var fullOutputPath = outputFile;
			if (!haxe.io.Path.isAbsolute(outputFile)) {
				fullOutputPath = "./" + outputFile;
			}

			// Save compiled script
			if (compiler.saveCompiled(compiled, fullOutputPath)) {
				print("[SAVE] Saved compiled script: " + fullOutputPath);

				// Show compilation stats
				var sourceSize = sourceCode.length;
				var compiledSize = sys.io.File.getBytes(fullOutputPath).length;
				print("[STATS] Source size: " + sourceSize + " bytes");
				print("[STATS] Compiled size: " + compiledSize + " bytes");
				print("[STATS] Compression ratio: " + Math.round((compiledSize / sourceSize) * 100) + "%");
				print("[STATS] Source hash: " + compiled.sourceHash);
			} else {
				print("[ERROR] Failed to save compiled script: " + compiler.lastError);
			}

		} catch (e:Dynamic) {
			print("[ERROR] Compilation failed: " + e);
		}
		#else
		print("[ERROR] File system not available on this platform");
		#end
	}

	private function testCompileYScriptCode(code:String):Void {
		var compiler = new yutautil.YScript();

		try {
			print("[COMPILE] Test compiling YScript code...");
			var compiled = compiler.compile(code, "<test>");
			print("[SUCCESS] Test compilation successful!");

			print("[STATS] Compilation info:");
			print("   Version: " + compiled.version);
			print("   Source hash: " + compiled.sourceHash);
			print("   Statements: " + compiled.statements.length);
			print("   Optimized: " + compiled.optimized);

			// Test loading the compiled format
			print("[TEST] Testing compiled format loading...");
			var tester = new yutautil.YScript();
			if (tester.loadFromCompiled(compiled)) {
				print("[SUCCESS] Compiled format loads successfully!");

				// Test execution
				print("[RUN] Testing execution...");
				var result = tester.execute();
				if (result != null) {
					print("[SUCCESS] Execution result: " + Std.string(result));
				} else {
					print("[SUCCESS] Execution completed (no return value)");
				}
			} else {
				print("[ERROR] Failed to load compiled format: " + tester.lastError);
			}

		} catch (e:Dynamic) {
			print("[ERROR] Test compilation failed: " + e);
		}
	}

	private function loadCompiledYScript(filePath:String):Void {
		var fullPath = filePath;
		// Check if it's a relative path
		if (!haxe.io.Path.isAbsolute(filePath)) {
			fullPath = "./" + filePath;
		}

		#if sys
		try {
			resetYScriptEnvironment();

			print("[FILE] Loading compiled YScript: " + fullPath);
			if (yscriptTester.loadCompiledFromFile(fullPath)) {
				print("[SUCCESS] Successfully loaded compiled script!");

				// Show script info
				print("[STATS] Script information:");
				if (yscriptTester.scriptPath != null) {
					print("   Original path: " + yscriptTester.scriptPath);
				}

				var varCount = yscriptTester.getVariableNames().length;
				var funcCount = yscriptTester.getFunctionNames().length;
				print("   Variables: " + varCount);
				print("   Functions: " + funcCount);

				// Execute the script
				print("[RUN] Executing script...");
				var result = yscriptTester.execute();
				if (result != null) {
					print("[SUCCESS] Execution result: " + Std.string(result));
				} else {
					print("[SUCCESS] Script executed successfully");
				}

			} else {
				print("[ERROR] Failed to load compiled script: " + yscriptTester.lastError);
			}
		} catch (e:Dynamic) {
			print("[ERROR] Error loading compiled script: " + e);
		}
		#else
		print("[ERROR] File system not available on this platform");
		#end
	}

	private function showCompilationSystemInfo():Void {
		print("YScript Compilation System Info");
		print("================================");
		print("Compiler version: 1.0.0");
		print("Supported features:");
		print("  - Full AST serialization");
		print("  - Source hash validation");
		print("  - Metadata preservation");
		print("  - Fast loading (.ysc format)");
		print("  - Cross-platform compatibility");
		print("");
		print("File formats:");
		print("  .ys  - YScript source files");
		print("  .ysc - YScript compiled files");
		print("");
		print("Benefits:");
		print("  - Faster script loading");
		print("  - Pre-parsed AST format");
		print("  - Integrity validation");
		print("  - Optimized for production");
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
				WindowUtils.preventClosing = true;
				Main.onCrash(new UncaughtErrorEvent(UncaughtErrorEvent.UNCAUGHT_ERROR, exception));
			}
			else
			{
				throw exception;
			}
		}, 0);
	}
}
