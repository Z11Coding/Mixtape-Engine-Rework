package managers;

/*
  SCRIPT MANAGER!

  This bad boy manages the scrips for the WHOLE engine. For example:

  * Handles all the HScripts
  * Handles all the LUA Scripts
  * Handels all the Modchart Variables from 0.6.x and later
  * Handels the V-Slice Scripts
  * Handels the Codename Scripts
  * Hamdels the FPS Plus Scripts (???)
  * Whatever else scripts do idk lol

  TODO: Make Global scripts a thing
*/

class ScriptManager {
  public static var instance:ScriptManager = null;

  #if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end
	public var yscriptArray:Array<YScript> = [];

  #if LUA_ALLOWED public var luaArray:Array<FunkinLua> = [];
	public var legacyLuaArray:Array<LegacyFunkinLua> = []; #end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	#end

  public static var isLegacyLuaTest:Bool = false; // Flag to track if we're testing from Legacy Lua settings

  #if PYTHON_ALLOWED
  public var pyScriptArray:Array<yutautil.PyScript> = [];
  #end
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end

	// Script existence flags for performance
	public var hasLuaScripts:Bool = false;
	public var hasHScripts:Bool = false;
	public var hasPyScripts:Bool = false;
	public var hasYScripts:Bool = false;

  public function new() {
		instance = this;
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		FlxG.state?.add(luaDebugGroup);
	}

	public function addDebugText() {
		FlxG.state?.remove(luaDebugGroup);
		luaDebugGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		FlxG.state?.add(luaDebugGroup);
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		if (!ClientPrefs.data.disableDebugTraces) {
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
		}
	}
	#end

  public function modchartCheck():Bool {
    var hasModchartFunction:Bool = false;

    #if LUA_ALLOWED
		for (script in luaArray) {
			if (script != null && !script.closed && script.lua != null) {
				Lua.getglobal(script.lua, 'onInitModchart');
				Lua.getglobal(script.lua, 'generateModchart');
				var type:Int = Lua.type(script.lua, -1);
				Lua.pop(script.lua, 1);

				if (type == Lua.LUA_TFUNCTION) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (!hasModchartFunction) {
			for (script in hscriptArray) {
				@:privateAccess
				if (script != null && (script.exists('onInitModchart') || script.exists('generateModchart'))) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		if (!hasModchartFunction) {
			for (script in yscriptArray) {
				@:privateAccess
				if (script != null && (script.hasFunction('onInitModchart') || script.hasFunction('generateModchart'))) {
					hasModchartFunction = true;
					break;
				}
			}
		}

    return hasModchartFunction;
  }

  public function startModcharts():Bool {
    var hasModchartFunction:Bool = false;

    #if LUA_ALLOWED
		for (script in luaArray) {
			if (script != null && !script.closed && script.lua != null) {
				Lua.getglobal(script.lua, 'onInitModchart');
				var type:Int = Lua.type(script.lua, -1);
				Lua.pop(script.lua, 1);

				if (type == Lua.LUA_TFUNCTION) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (!hasModchartFunction) {
			for (script in hscriptArray) {
				@:privateAccess
				if (script != null && script.exists('onInitModchart')) {
					hasModchartFunction = true;
					break;
				}
			}
		}
		#end

		if (!hasModchartFunction) {
			for (script in yscriptArray) {
				@:privateAccess
				if (script != null && script.hasFunction('onInitModchart')) {
					hasModchartFunction = true;
					break;
				}
			}
		}

		return hasModchartFunction;
  }

  public function loadStage(stageName:String):String {
    var stageFileLoaded:String = "";
    var scriptLoaded:Bool = false;
		#if LUA_ALLOWED
		if (!scriptLoaded)
		{
			var doPush:Bool = false;
			var luaFile:String = 'stages/$stageName.lua';
			#if MODS_ALLOWED
			var replacePath:String = Paths.modFolders(luaFile);
			if(FileSystem.exists(replacePath))
			{
				luaFile = replacePath;
				doPush = true;
			}
			else
			{
				luaFile = Paths.getSharedPath(luaFile);
				if(FileSystem.exists(luaFile))
					doPush = true;
			}
			#else
			luaFile = Paths.getSharedPath(luaFile);
			if(Assets.exists(luaFile)) doPush = true;
			#end

			if(doPush)
			{
				for (script in luaArray)
				{
					if(script.scriptName == luaFile)
					{
						doPush = false;
						break;
					}
				}
				if(doPush)
				{
					(shouldUseLegacyLua() ? new LegacyFunkinLua(luaFile) : new FunkinLua(luaFile));
					stageFileLoaded += " + Lua: " + luaFile;
					scriptLoaded = true;
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (!scriptLoaded)
		{
			var doPush:Bool = false;
			var scriptFile:String = 'stages/$stageName.hx';
			#if MODS_ALLOWED
			var replacePath:String = Paths.modFolders(scriptFile);
			if(FileSystem.exists(replacePath))
			{
				scriptFile = replacePath;
				doPush = true;
			}
			else
			#end
			{
				scriptFile = Paths.getSharedPath(scriptFile);
				if(FileSystem.exists(scriptFile))
					doPush = true;
			}

			if(doPush)
			{
				for (script in hscriptArray)
				{
					if(script.origin == scriptFile)
					{
						doPush = false;
						break;
					}
				}
				if(doPush)
				{
					initHScript(scriptFile);
					stageFileLoaded += " + HScript: " + scriptFile;
					scriptLoaded = true;
				}
			}
		}
		#end

		if (!scriptLoaded)
		{
			var doPush:Bool = false;
			var scriptFile:String = 'stages/$stageName.ys';
			#if MODS_ALLOWED
			var replacePath:String = Paths.modFolders(scriptFile);
			if(FileSystem.exists(replacePath))
			{
				scriptFile = replacePath;
				doPush = true;
			}
			else
			#end
			{
				scriptFile = Paths.getSharedPath(scriptFile);
				if(FileSystem.exists(scriptFile))
					doPush = true;
			}

			if(doPush)
			{
				for (script in yscriptArray)
				{
					if(script.scriptPath == scriptFile)
					{
						doPush = false;
						break;
					}
				}
				if(doPush)
				{
					initYScript(scriptFile);
					stageFileLoaded += " + YScript: " + scriptFile;
					scriptLoaded = true;
				}
			}
		}
    return stageFileLoaded;
  }

	public function destroyCurrentScripts() {
		#if LUA_ALLOWED
		if (luaArray != null && luaArray.length > 0) { //if there's nothing, simply dont.
			for (lua in luaArray)
			{
				if (lua != null) {
					lua.call('onDestroy', []);
					lua.stop();
				}
			}
		}

		if (legacyLuaArray != null && legacyLuaArray.length > 0) { //if there's nothing, simply dont.
			for (lua in legacyLuaArray)
			{
				if (lua != null) {
					lua.call('onDestroy', []);
					lua.stop();
				}
			}
		}
		luaArray = [];
		legacyLuaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		if (hscriptArray != null && hscriptArray.length > 0) { //if there's nothing, simply dont.
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}
		}

		hscriptArray = [];
		#end

		if (yscriptArray != null && yscriptArray.length > 0) { //if there's nothing, simply dont.
		for (script in yscriptArray)
			if(script != null)
			{
				if(script.hasFunction('onDestroy')) script.callFunction('onDestroy');
				script.destroy();
			}
		}

		yscriptArray = [];

		// Clear tween managers
		if (modchartTweens != null) {
			for (tween in modchartTweens) {
				if (tween != null) tween.cancel();
			}
			modchartTweens.clear();
			modchartTweens = null;
		}

		if (modchartTimers != null) {
			for (timer in modchartTimers) {
				if (timer != null) timer.cancel();
			}
			modchartTimers.clear();
			modchartTimers = null;
		}
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			(shouldUseLegacyLua() ? new LegacyFunkinLua(luaToLoad) : new FunkinLua(luaToLoad));
			return true;
		}
		return false;
	}
	#end

	#if LUA_ALLOWED
	public function initLuaScript(luaFile:String)
	{
		for (script in luaArray)
			if(script.scriptName == luaFile) return false;

		(shouldUseLegacyLua() ? new LegacyFunkinLua(luaFile) : new FunkinLua(luaFile));
		return true;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) {
				newScript.call('onCreate');
			}
			if (newScript.exists('onLoad')) {
				newScript.call('onLoad');
			}
			//trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
			updateScriptFlags(); // Update script existence flags when adding HScript
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
		updateScriptFlags(); // Update flags regardless of success/failure
	}
	#end

	public function startYScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			initYScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initYScript(file:String)
	{
		var newScript:YScript = null;
		try
		{
			newScript = new YScript();

			// Attach to PlayState for error reporting before onCreate
			newScript.attachToState(MusicBeatState.getState());

			newScript.loadFromFile(file);
			if (newScript.hasFunction('onCreate')) {
				newScript.callFunction('onCreate');
			}
			if (newScript.hasFunction('onLoad')) {
				newScript.callFunction('onLoad');
			}
			trace('initialized yscript interp successfully: $file');
			yscriptArray.push(newScript);
			//updateScriptFlags(); // Update script existence flags when adding YScript
		}
		catch(e:YScriptError)
		{
			addTextToDebug(e.message, FlxColor.RED);
		}
		//updateScriptFlags(); // Update flags regardless of success/failure
	}

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		// Early exit if no scripts exist
		if (!hasLuaScripts && !hasHScripts && !hasPyScripts && !hasYScripts) {
			return LuaUtils.Function_Continue;
		}

		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		// Call scripts in order: Lua -> HScript -> YScript -> Python
		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnYScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnPyScripts(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		// var lua = flixel.util.typeLimit.OneOfTwo;

		var arr:Array<Dynamic> = [];
		if ((luaArray != null || legacyLuaArray != null) && (luaArray.length > 0 || legacyLuaArray.length > 0)) {
			for (script in yutautil.CollectionUtils.toIterable(cast(luaArray:Array<Dynamic>).concat(legacyLuaArray)))
			{
				if(script.closed)
				{
					arr.push(script);
					continue;
				}

				if(exclusions.contains(script.scriptName))
					continue;

				var myValue:Dynamic = script.call(funcToCall, args);
				if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;

				if(script.closed) arr.push(script);
			}
		}

		if(arr.length > 0)
			for (script in arr)
			(luaArray.contains(script)) ? luaArray.remove(script) : legacyLuaArray.remove(cast(script, LegacyFunkinLua));
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray != null ? hscriptArray.length : 0;
		if (len < 1)
			return returnVal;

		try {
			for(script in hscriptArray)
			{
				@:privateAccess
				if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
					continue;

				var callValue = script.call(funcToCall, args);
				if(callValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;

					if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		} catch(e) {trace("One of the scripts wasn't having it apparently");}
		#end

		return returnVal;
	}

	public function callOnYScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = yscriptArray != null ? yscriptArray.length : 0;
		if (len < 1)
			return returnVal;

		var arr:Array<YScript> = [];
		for(script in yscriptArray)
		{
			if(script.hasErrors)
			{
				arr.push(script);
				continue;
			}

			var callValue = script.hasFunction(funcToCall) ? script.callFunction(funcToCall, args) : null;
			if(callValue != null)
			{
				var myValue:Dynamic = callValue; // YScript returns values directly, not wrapped in returnValue

				if((myValue == LuaUtils.Function_StopYScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}

			if(script.hasErrors) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				yscriptArray.remove(script);

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
		setOnYScript(variable, arg, exclusions);
		setOnPyScripts(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if (luaArray != null && luaArray.length > 0) {
			for (script in luaArray) {
				if(exclusions.contains(script.scriptName))
					continue;

				script.set(variable, arg);
			}
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		if (hscriptArray != null && hscriptArray.length > 0) {
			for (script in hscriptArray) {
				if(exclusions.contains(script.origin))
					continue;

				script.set(variable, arg);
			}
		}
		#end
	}

	public function setOnYScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		if (yscriptArray != null && yscriptArray.length > 0) {
			for (script in yscriptArray) {
				if(exclusions.contains(script.scriptPath))
					continue;

				script.setVariable(variable, arg);
			}
		}
	}

	public function callOnPyScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if PYTHON_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<PyScript> = [];
		if (pyScriptArray != null && pyScriptArray.length > 0) {
			for (script in pyScriptArray) {
				if(script.closed || script.errorOccurred) {
					arr.push(script);
					continue;
				}

				if(exclusions.contains(script.scriptName))
					continue;

				var myValue:Dynamic = script.call(funcToCall, args);
				if((myValue == PyScript.Function_Stop || myValue == PyScript.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) {
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;

				if(script.closed || script.errorOccurred) arr.push(script);
			}
		}

		if(arr.length > 0) {
			for (script in arr) {
				pyScriptArray.remove(script);
			}
		}
		#end
		return returnVal;
	}

	public function setOnPyScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if PYTHON_ALLOWED
		if(exclusions == null) exclusions = [];
		if (pyScriptArray != null && pyScriptArray.length > 0) {
			for (script in pyScriptArray) {
				if(exclusions.contains(script.scriptName))
					continue;

				script.setVar(variable, arg);
			}
		}
		#end
	}

  /**
	 * Determines whether Legacy Lua should be used based on settings for current song/mod
	 * Priority: Song Setting > Mod Setting > Player Choice
	 */
	private function shouldUseLegacyLua():Bool {
		var currentSong = PlayfieldManager.SONG .song;
		var currentMod = (backend.WeekData.getCurrentWeek() != null ? backend.WeekData.getCurrentWeek().folder : '');

		var settingsManager = options.legacylua.LegacyLuaSettingsManager.getInstance();
		return settingsManager.shouldUseLegacyLua(currentSong, currentMod);
	}

	// Update script existence flags for performance optimization
	public function updateScriptFlags():Void {
		#if LUA_ALLOWED
		hasLuaScripts = (luaArray != null && luaArray.length > 0) || (legacyLuaArray != null && legacyLuaArray.length > 0);
		#else
		hasLuaScripts = false;
		#end

		#if HSCRIPT_ALLOWED
		hasHScripts = (hscriptArray != null && hscriptArray.length > 0);
		#else
		hasHScripts = false;
		#end

		hasYScripts = (yscriptArray != null && yscriptArray.length > 0);

		#if PYTHON_ALLOWED
		hasPyScripts = (pyScriptArray != null && pyScriptArray.length > 0);
		#else
		hasPyScripts = false;
		#end

		// Optimize script batching based on script count
		var totalScripts = 0;
		#if LUA_ALLOWED
		if (luaArray != null) totalScripts += luaArray.length;
		if (legacyLuaArray != null) totalScripts += legacyLuaArray.length;
		#end
		#if HSCRIPT_ALLOWED
		if (hscriptArray != null) totalScripts += hscriptArray.length;
		#end
		if (yscriptArray != null) totalScripts += yscriptArray.length;
		#if PYTHON_ALLOWED
		if (pyScriptArray != null) totalScripts += pyScriptArray.length;
		#end

		// Enable batched script calls for performance when many scripts are loaded
		//_skipRedundantUpdates = totalScripts > 5;
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (MusicBeatState.getVariables().exists(tag))
			return MusicBeatState.getVariables().get(tag);
		#end
		return null;
	}
}

