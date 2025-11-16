package psychlua;

package psychlua;

#if HSCRIPT_ALLOWED
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
import psychlua.HScript;
#end

#if LUA_ALLOWED
import psychlua.FunkinLua;
import psychlua.LuaUtils;
#end

class StateScriptHandler {
  #if HSCRIPT_ALLOWED
  public static var hscript:HScript;
  public static var instancesExclude:Array<String> = [];
  #end

  #if LUA_ALLOWED
  public static var lua:FunkinLua;
  public static var luaArray:Array<FunkinLua> = []; // If you need multiple Lua scripts
  #end

  public static function setState(nameFile:String, stateInstance:Dynamic) {
    #if HSCRIPT_ALLOWED
    startHScriptNamed('states/$nameFile.hx');
    #end

    #if LUA_ALLOWED
    startLuaNamed('states/$nameFile.lua');
    #end

    setOnScripts("game", stateInstance);
  }

  // HScript Functions
  #if HSCRIPT_ALLOWED
  public static function startHScriptNamed(scriptFile:String):Bool
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
      initHScript(scriptToLoad);
      return true;
    }
    return false;
  }

  public static function initHScript(file:String):Void
  {
    try
    {
      if(hscript != null) {
        hscript.destroy();
        hscript = null;
      }

      hscript = new HScript(null, file);
      if (hscript.exists('onCreate')) hscript.call('onCreate');
      trace('initialized hscript successfully: $file');
    }
    catch(e:IrisError)
    {
      var pos:HScriptInfos = cast {fileName: file, showLine: false};
      Iris.error(Printer.errorToString(e, false), pos);
      if(hscript != null) {
          hscript.destroy();
          hscript = null;
      }
    }
  }
  #end

  // Lua Functions
  #if LUA_ALLOWED
  public static function startLuaNamed(luaFile:String):Bool
  {
    #if MODS_ALLOWED
    var luaToLoad:String = Paths.modFolders(luaFile);
    if(!FileSystem.exists(luaToLoad))
      luaToLoad = Paths.getSharedPath(luaFile);
    #else
    var luaToLoad:String = Paths.getSharedPath(luaFile);
    #end

    if(FileSystem.exists(luaToLoad))
    {
      new FunkinLua(luaToLoad);
      return true;
    }
    return false;
  }

  public static function addLuaScript(scriptPath:String):FunkinLua
  {
    var script:FunkinLua = new FunkinLua(scriptPath);
    luaArray.push(script);
    return script;
  }

  public static function removeLuaScript(script:FunkinLua):Void
  {
    if(script != null)
    {
      script.stop();
      luaArray.remove(script);
    }
  }
  #end

  // Combined Script Functions
  public static function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
    var returnVal:Dynamic = #if LUA_ALLOWED LuaUtils.Function_Continue; #else null; #end
    if(args == null) args = [];
    if(exclusions == null) exclusions = [];
    if(excludeValues == null) excludeValues = [#if LUA_ALLOWED LuaUtils.Function_Continue #else null #end];

    #if LUA_ALLOWED
    var luaResult:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if(luaResult != null && !excludeValues.contains(luaResult))
      returnVal = luaResult;
    #end

    #if HSCRIPT_ALLOWED
    var hscriptResult:Dynamic = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if(hscriptResult != null && !excludeValues.contains(hscriptResult))
      returnVal = hscriptResult;
    #end

    return returnVal;
  }

  #if HSCRIPT_ALLOWED
  public static function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
    var returnVal:Dynamic = LuaUtils.Function_Continue;
    if(exclusions == null) exclusions = new Array();
    if(excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtils.Function_Continue);

    @:privateAccess
    if(hscript != null && hscript.exists(funcToCall)) {
      if(!exclusions.contains(hscript.origin)) {
        var callValue = hscript.call(funcToCall, args);
        if(callValue != null) {
          var myValue:Dynamic = callValue.returnValue;

          if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
              && !excludeValues.contains(myValue)
              && !ignoreStops)
          {
            returnVal = myValue;
          }
          else if(myValue != null && !excludeValues.contains(myValue))
          {
            returnVal = myValue;
          }
        }
      }
    }
    return returnVal;
  }
  #end

  #if LUA_ALLOWED
  public static function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
    var returnVal:Dynamic = LuaUtils.Function_Continue;
    if(args == null) args = [];
    if(exclusions == null) exclusions = [];
    if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    // Call on main lua script
    if(lua != null && !lua.closed && !exclusions.contains(lua.scriptName)) {
      var myValue:Dynamic = lua.call(funcToCall, args);
      if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) {
        returnVal = myValue;
      }
      else if(myValue != null && !excludeValues.contains(myValue)) {
        returnVal = myValue;
      }
    }

    // Call on additional lua scripts if needed
    for (script in luaArray) {
      if(script.closed || exclusions.contains(script.scriptName))
        continue;

      var myValue:Dynamic = script.call(funcToCall, args);
      if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops) {
        returnVal = myValue;
        break;
      }
      else if(myValue != null && !excludeValues.contains(myValue)) {
        returnVal = myValue;
      }
    }

    return returnVal;
  }
  #end

  public static function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void {
    if(exclusions == null) exclusions = [];
    #if HSCRIPT_ALLOWED
    setOnHScript(variable, arg, exclusions);
    #end
    #if LUA_ALLOWED
    setOnLuas(variable, arg, exclusions);
    #end
  }

  #if HSCRIPT_ALLOWED
  public static function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void {
    if(exclusions == null) exclusions = [];
    if(hscript != null && !exclusions.contains(hscript.origin)) {
      if(!instancesExclude.contains(variable))
        instancesExclude.push(variable);
      hscript.set(variable, arg);
    }
  }
  #end

  #if LUA_ALLOWED
  public static function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void {
    if(exclusions == null) exclusions = [];
    if(lua != null && !exclusions.contains(lua.scriptName)) {
      lua.set(variable, arg);
    }

    for (script in luaArray) {
      if(!script.closed && !exclusions.contains(script.scriptName)) {
          script.set(variable, arg);
      }
    }
  }
  #end

  public static function destroy():Void {
    #if HSCRIPT_ALLOWED
    if(hscript != null) {
      hscript.destroy();
      hscript = null;
    }
    instancesExclude = [];
    #end

    #if LUA_ALLOWED
    if(lua != null) {
      lua.stop();
      lua = null;
    }

    for (script in luaArray) {
      script.stop();
    }
    luaArray = [];
    #end
  }
}
