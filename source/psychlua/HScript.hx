package psychlua;

import flixel.FlxBasic;
import objects.Character;
import psychlua.LuaUtils;
import psychlua.CustomSubstate;
import backend.modchart.SubModifier;
import objects.VideoSprite;
import flixel.addons.display.FlxRuntimeShader;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;

import haxe.ValueException;

import modchart.Manager;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
	#if LUA_ALLOWED
	var ?isLua:Null<Bool>;
	#end
}

class HScript extends Iris
{
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			try {
				parent.hscript = new HScript(parent, code, varsToBring);
			}
			catch(e:IrisError) {
				var pos:HScriptInfos = cast {fileName: parent.scriptName, isLua: true};
				if(parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				Iris.error(Printer.errorToString(e, false), pos);
				parent.hscript = null;
			}
		}
		else
		{
			try
			{
				hs.scriptCode = code;
				hs.varsToBring = varsToBring;
				hs.parse(true);
				var ret:Dynamic = hs.execute();
				hs.returnValue = ret;
			}
			catch(e:IrisError)
			{
				var pos:HScriptInfos = cast hs.interp.posInfos();
				pos.isLua = true;
				if(parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				Iris.error(Printer.errorToString(e, false), pos);
				hs.returnValue = null;
			}
		}
	}
	#end

	public var origin:String;
	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		if (file == null)
			file = '';

		filePath = file;
		if (filePath != null && filePath.length > 0)
		{
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}
		var scriptThing:String = file;
		var scriptName:String = null;
		if(parent == null && file != null)
		{
			var f:String = file.replace('\\', '/');
			if(f.contains('/') && !f.contains('\n')) {
				scriptThing = File.getContent(f);
				scriptName = f;
			}
		}
		#if LUA_ALLOWED
		if (scriptName == null && parent != null)
			scriptName = parent.scriptName;
		#end
		super(scriptThing, new IrisConfig(scriptName, false, false));
		var customInterp:CustomInterp = new CustomInterp();
		customInterp.parentInstance = FlxG.state;
		customInterp.showPosOnLog = false;
		this.interp = customInterp;
		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null)
		{
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end
		preset();
		
		// Add Archipelago-specific functions if in Archipelago mode
		#if ARCHIPELAGO_ALLOWED
		addArchipelagoSupport();
		#end
		
		this.varsToBring = varsToBring;
		if (!manualRun) {
			try {
				var ret:Dynamic = execute();
				returnValue = ret;
			} catch(e:IrisError) {
				returnValue = null;
				this.destroy();
				throw e;
			}
		}
	}

	var varsToBring(default, set):Any = null;
	override function preset() {
		super.preset();

		// Some very commonly used classes
		set('Type', Type);
		#if sys
		set('File', sys.io.File);
		set('FileSystem', FileSystem);
		#end
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', CustomFlxColor);
		set('Countdown', stages.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		#if VIDEOS_ALLOWED //Compat stuff. you wouldn't get it
		set('PsychVideoSprite', objects.FNFWeeklyVideoSprite);
		set('FNFWeeklyVideoSprite', objects.FNFWeeklyVideoSprite);
		set('VideoSprite', objects.FNFWeeklyVideoSprite);
		#end
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic) {
			MusicBeatState.getVariables().set(name, value);
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			if(MusicBeatState.getVariables().exists(name)) result = MusicBeatState.getVariables().get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});
		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if(modName == null)
			{
				if(this.modFolder == null)
				{
					Iris.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		// For adding your own callbacks
		// not very tested but should work
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			if (name == 'makeVideoSprite') return;
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);

			FunkinLua.customFunctions.set(name, func);
		});

		// this one was tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(funk != null) funk.addLocalCallback(name, func);
			else Iris.error('createCallback ($name): 3rd argument is null', this.interp.posInfos());
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), this.interp.posInfos());
			}
		});
		#if LUA_ALLOWED
		set('parentLua', parentLua);
		#else
		set('parentLua', null);
		#end
		set('this', this);
		set('game', FlxG.state);
		set('controls', Controls.instance);

		set('buildTarget', LuaUtils.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('Function_StopLua', LuaUtils.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);

		
		//Troll Engine Hscript Functions
		set("NoteObject", objects.NoteObject);
		set("PlayField", objects.playfields.PlayField);
		set("NoteField", objects.playfields.NoteField);
		set("ProxyField", objects.proxies.ProxyField);
		set("ProxySprite", objects.proxies.ProxySprite);
		set("Modifier", backend.modchart.Modifier);
		set("SubModifier", backend.modchart.SubModifier);
		set("NoteModifier", backend.modchart.NoteModifier);
		set("EventTimeline", backend.modchart.EventTimeline);
		set("StepCallbackEvent", backend.modchart.events.StepCallbackEvent);
		set("CallbackEvent", backend.modchart.events.CallbackEvent);
		set("ModEvent", backend.modchart.events.ModEvent);
		set("EaseEvent", backend.modchart.events.EaseEvent);
		set("SetEvent", backend.modchart.events.SetEvent);
		set("modManager", PlayState.instance.modManager);

		set("setPercent", function(modName:String, val:Float, player:Int = -1)
		{
			PlayState.instance.modManager.setPercent(modName, val, player);
		});

		set("addBlankMod", function(modName:String, defaultVal:Float = 0, player:Int = -1)
		{
			PlayState.instance.modManager.quickRegister(new SubModifier(modName, PlayState.instance.modManager));
			PlayState.instance.modManager.setValue(modName, defaultVal);
		});

		set("setValue", function(modName:String, val:Float, player:Int = -1)
		{
			PlayState.instance.modManager.setValue(modName, val, player);
		});

		set("getPercent", function(modName:String, player:Int)
		{
			return PlayState.instance.modManager.getPercent(modName, player);
		});

		set("getValue", function(modName:String, player:Int)
		{
			return PlayState.instance.modManager.getValue(modName, player);
		});

		set("queueSet", 
		function(step:Float, modName:String, target:Float, player:Int = -1)
			{
				PlayState.instance.modManager.queueSet(step, modName, target, player);
			}
		);

		set("queueSetP", 
			function(step:Float, modName:String, perc:Float, player:Int = -1)
			{
				PlayState.instance.modManager.queueSetP(step, modName, perc, player);
			}
		);

		set("queueEase",
			function(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) // lua is autistic and can only accept 5 args
			{
				PlayState.instance.modManager.queueEase(step, endStep, modName, percent, style, player, startVal);
			}
		);

		set("queueEaseP",
			function(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) // lua is autistic and can only accept 5 args
			{
				PlayState.instance.modManager.queueEaseP(step, endStep, modName, percent, style, player, startVal);
			}
		);

		//Funkin Modchart things
		set("manager", Manager);

		//Base game things
		set("FlxPoint", {
			get: FlxPoint.get,
			weak: FlxPoint.weak
		});

		// hi its me lethrial adding a new and exciting function to hscript!
		// thank you random guy from fnf weekly
		set('setGameOverVideo', function(name:String = null) {
			if (name != null) substates.GameOverSubstate.instance.setGameOverVideo(name);
			else trace('No argument for game over video!');
		});

		set("newShader", function(fragFile:String = null, vertFile:String = null){ // returns a FlxRuntimeShader but with file names lol
			var runtime:FlxRuntimeShader = null;

			try{				
				runtime = Paths.getShader(fragFile, vertFile);
			}catch(e:Dynamic){
				trace("Shader compilation error:" + e.message);
			}

			return runtime==null ? new FlxRuntimeShader() : runtime;
		});

		set('makeVideoSprite', function(tag:String, videoFile:String, ?x:Float, ?y:Float, ?camera:String = 'game', ?shouldLoop:Bool = false, ?playOnLoad:Bool = true, ?isCutscene:Bool = false, addBehind:String = 'none') {	
			if (MusicBeatState.getVariables().exists(tag + '_video') || MusicBeatState.getVariables().exists(tag))
			{
				PlayState.instance.addTextToDebug('makeVideoSprite: This tag is not available! Use a different tag.', FlxColor.RED);
				return;
			}
			
			if (!FileSystem.exists(Paths.video(videoFile)))
			{
				PlayState.instance.addTextToDebug('makeVideoSprite: The video file "' + videoFile + '" cannot be found!', FlxColor.RED);
				return;
			}
			
			var videoCutscene:VideoSprite = null;
			#if VIDEOS_ALLOWED
			PlayState.instance.inCutscene = isCutscene;
			PlayState.instance.canPause = !isCutscene;

			var foundFile:Bool = false;
			var fileName:String = Paths.video(videoFile);

			#if sys
			if (FileSystem.exists(fileName))
			#else
			if (OpenFlAssets.exists(fileName))
			#end
			foundFile = true;

			if (foundFile)
			{
				videoCutscene = new VideoSprite(fileName, !isCutscene, false, shouldLoop);
				if(!isCutscene) videoCutscene.videoSprite.bitmap.rate = PlayState.instance.playbackRate;

				// Finish callback
				if (isCutscene)
				{
					function onVideoEnd()
					{
						videoCutscene = null;
						PlayState.instance.canPause = true;
						PlayState.instance.inCutscene = false;
					}
					videoCutscene.finishCallback = onVideoEnd;
					videoCutscene.onSkip = onVideoEnd;
				}
				videoCutscene.camera = LuaUtils.cameraFromString(camera); 
				videoCutscene.x = x;
				videoCutscene.y = y;
				if (substates.GameOverSubstate.instance != null && PlayState.instance.isDead) substates.GameOverSubstate.instance.add(videoCutscene);
				else {
					switch(addBehind.toLowerCase()){
						case "bf" | "boyfriend": PlayState.instance.addBehindBF(videoCutscene);
						case "gf" | "girlfriend": PlayState.instance.addBehindGF(videoCutscene);
						case "dad" | "opponent": PlayState.instance.addBehindDad(videoCutscene);
						default: PlayState.instance.add(videoCutscene);
					}
				}

				if (playOnLoad) videoCutscene.play();
			}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			else PlayState.instance.addTextToDebug("Video not found: " + fileName, FlxColor.RED);
			#else
			else FlxG.log.error("Video not found: " + fileName);
			#end
			#else
			FlxG.log.warn('Platform not supported!');
			#end
			MusicBeatState.getVariables().set(tag + '_video', videoCutscene); //For some scripts + makes global pausing easier
			MusicBeatState.getVariables().set(tag, videoCutscene);
		});

		set('pauseVideo', function(tag:String) {	
			if (MusicBeatState.getVariables().exists(tag)) MusicBeatState.getVariables().get(tag).pause();
		});

		set('resumeVideo', function(tag:String) {	
			if (MusicBeatState.getVariables().exists(tag)) MusicBeatState.getVariables().get(tag).resume();
		});

		set('Date', yutautil.ExtendedDate);
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			initHaxeModuleCode(funk, codeToRun, varsToBring);
			if (funk.hscript != null)
			{
				final retVal:IrisCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null)
				{
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				}
				else if (funk.hscript.returnValue != null)
				{
					return funk.hscript.returnValue;
				}
			}
			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.hscript != null)
			{
				final retVal:IrisCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null)
				{
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				}
			}
			else
			{
				var pos:HScriptInfos = cast {fileName: funk.scriptName, showLine: false};
				if (funk.lastCalledFunction != '') pos.funcName = funk.lastCalledFunction;
				Iris.error("runHaxeFunction: HScript has not been initialized yet! Use \"runHaxeCode\" to initialize it", pos);
			}
			return null;
		});
		// This function is unnecessary because import already exists in HScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var c:Dynamic = Type.resolveClass(str + libName);
			if (c == null)
				c = Type.resolveEnum(str + libName);

			if (funk.hscript == null)
				initHaxeModule(funk);

			var pos:HScriptInfos = cast funk.hscript.interp.posInfos();
			pos.showLine = false;
			if (funk.lastCalledFunction != '')
				 pos.funcName = funk.lastCalledFunction;

			try {
				if (c != null)
					funk.hscript.set(libName, c);
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), pos);
			}
			FunkinLua.lastCalledScript = funk;
			if (FunkinLua.getBool('luaDebugMode') && FunkinLua.getBool('luaDeprecatedWarnings'))
				Iris.warn("addHaxeLibrary is deprecated! Import classes through \"import\" in HScript!", pos);
		});
	}
	#end

	override function call(funcToRun:String, ?args:Array<Dynamic>):IrisCall {
		if (funcToRun == null || interp == null) return null;

		if (!exists(funcToRun)) {
			Iris.error('No function named: $funcToRun', this.interp.posInfos());
			return null;
		}

		try {
			var func:Dynamic = interp.variables.get(funcToRun); // function signature
			final ret = Reflect.callMethod(null, func, args ?? []);
			return {funName: funcToRun, signature: func, returnValue: ret};
		}
		catch(e:IrisError) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null)
			{
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			Iris.error(Printer.errorToString(e, false), pos);
		}
		catch (e:ValueException) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null)
			{
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			Iris.error('$e', pos);
		}
		return null;
	}

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end
		super.destroy();
	}

	function set_varsToBring(values:Any) {
		if (varsToBring != null)
			for (key in Reflect.fields(varsToBring))
				if (exists(key.trim()))
					interp.variables.remove(key.trim());

		if (values != null)
		{
			for (key in Reflect.fields(values))
			{
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}

		return varsToBring = values;
	}
}

class CustomFlxColor {
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var GRAY(default, null):Int = FlxColor.GRAY;

	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var LIME(default, null):Int = FlxColor.LIME;
	public static var YELLOW(default, null):Int = FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = FlxColor.ORANGE;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var PURPLE(default, null):Int = FlxColor.PURPLE;
	public static var BLUE(default, null):Int = FlxColor.BLUE;
	public static var BROWN(default, null):Int = FlxColor.BROWN;
	public static var PINK(default, null):Int = FlxColor.PINK;
	public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = FlxColor.CYAN;

	public static function fromInt(Value:Int):Int 
		return cast FlxColor.fromInt(Value);

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);

	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);

	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);

	public static function fromString(str:String):Int
		return cast FlxColor.fromString(str);
}

class CustomInterp extends crowplexus.hscript.Interp
{
	public var parentInstance(default, set):Dynamic = [];
	private var _instanceFields:Array<String>;
	function set_parentInstance(inst:Dynamic):Dynamic
	{
		parentInstance = inst;
		if(parentInstance == null)
		{
			_instanceFields = [];
			return inst;
		}
		_instanceFields = Type.getInstanceFields(Type.getClass(inst));
		return inst;
	}

	public function new()
	{
		super();
	}

	override function fcall(o:Dynamic, funcToRun:String, args:Array<Dynamic>):Dynamic {
		for (_using in usings) {
			var v = _using.call(o, funcToRun, args);
			if (v != null)
				return v;
		}

		var f = get(o, funcToRun);

		if (f == null) {
			Iris.error('Tried to call null function $funcToRun', posInfos());
			return null;
		}

		return Reflect.callMethod(o, f, args);
	}

	override function resolve(id: String): Dynamic {
		if (locals.exists(id)) {
			var l = locals.get(id);
			return l.r;
		}

		if (variables.exists(id)) {
			var v = variables.get(id);
			return v;
		}

		if (imports.exists(id)) {
			var v = imports.get(id);
			return v;
		}

		if(parentInstance != null && _instanceFields.contains(id)) {
			var v = Reflect.getProperty(parentInstance, id);
			return v;
		}

		error(EUnknownVariable(id));

		return null;
	}
}
#else
class HScript
{
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}

	#if ARCHIPELAGO_ALLOWED
	private function addArchipelagoSupport():Void {
		// Add Archipelago classes
		set('APScriptingSupport', archipelago.APScriptingSupport);
		set('APGameState', archipelago.APGameState);
		
		// Register callback for item received
		set('registerItemReceivedCallback', function(callback:String->Void) {
			if (!archipelago.APEntryState.inArchipelagoMode) {
				trace('registerItemReceivedCallback: Archipelago mode is not enabled!');
				return false;
			}
			
			archipelago.APScriptingSupport.registerItemReceivedCallback(callback);
			return true;
		});
		
		// Register callback for custom item received
		set('registerCustomItemReceivedCallback', function(callback:String->Void) {
			if (!archipelago.APEntryState.inArchipelagoMode) {
				trace('registerCustomItemReceivedCallback: Archipelago mode is not enabled!');
				return false;
			}
			
			archipelago.APScriptingSupport.registerCustomItemReceivedCallback(callback);
			return true;
		});
		
		// Register callback for item sent
		set('registerItemSentCallback', function(callback:String->Void) {
			if (!archipelago.APEntryState.inArchipelagoMode) {
				trace('registerItemSentCallback: Archipelago mode is not enabled!');
				return false;
			}
			
			archipelago.APScriptingSupport.registerItemSentCallback(callback);
			return true;
		});
		
		// Register callback for location sent
		set('registerLocationSentCallback', function(callback:String->Int->Void) {
			if (!archipelago.APEntryState.inArchipelagoMode) {
				trace('registerLocationSentCallback: Archipelago mode is not enabled!');
				return false;
			}
			
			archipelago.APScriptingSupport.registerLocationSentCallback(callback);
			return true;
		});
		
		// Send location function
		set('sendArchipelagoLocation', function(locationName:String) {
			if (!archipelago.APEntryState.inArchipelagoMode) {
				trace('sendArchipelagoLocation: Archipelago mode is not enabled!');
				return false;
			}
			
			return archipelago.APScriptingSupport.sendLocation(locationName);
		});
		
		// Check if item exists
		set('hasArchipelagoItem', function(itemName:String) {
			if (!archipelago.APEntryState.inArchipelagoMode) return false;
			return archipelago.APScriptingSupport.hasItem(itemName);
		});
		
		// Get item count
		set('getArchipelagoItemCount', function(itemName:String) {
			if (!archipelago.APEntryState.inArchipelagoMode) return 0;
			return archipelago.APScriptingSupport.getItemCount(itemName);
		});
		
		// Check connection status
		set('isConnectedToArchipelago', function() {
			return archipelago.APScriptingSupport.isConnected();
		});
		
		// Get player name
		set('getArchipelagoPlayerName', function() {
			if (!archipelago.APEntryState.inArchipelagoMode) return "";
			return archipelago.APScriptingSupport.getPlayerName();
		});
		
		// Get slot data field from APInfo
		set('getArchipelagoSlotData', function(fieldName:String) {
			if (!archipelago.APEntryState.inArchipelagoMode) return null;
			return archipelago.APScriptingSupport.getSlotDataField(fieldName);
		});
		
		// Get available songs from slot data
		set('getArchipelagoAvailableSongs', function() {
			if (!archipelago.APEntryState.inArchipelagoMode) return [];
			return archipelago.APScriptingSupport.getAvailableSongs();
		});
		
		// Get song data for a specific song
		set('getArchipelagoSongData', function(songName:String) {
			if (!archipelago.APEntryState.inArchipelagoMode) return null;
			return archipelago.APScriptingSupport.getSongData(songName);
		});
		
		// Archipelago status variables
		set('archipelagoEnabled', archipelago.APEntryState.inArchipelagoMode);
		set('connectedToArchipelago', archipelago.APScriptingSupport.isConnected());
	}
	#end
	#end
}
#end