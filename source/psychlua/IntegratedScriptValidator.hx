package psychlua;

import haxe.macro.Context;
import haxe.macro.Expr;
import llua.State;
import sys.FileSystem; 


class ScriptValidator {
    public static macro function validateScripts():Expr {
        var fields = Context.getBuildFields();
        for (field in fields) {
            switch (field) {
                case TFunction(func):
                    for (arg in func.args) {
                        switch (arg.type) {
                            case TPath({pack: ["IntegratedLua"], name: "IntegratedLuaScript"}):
                                // Add validation logic for IntegratedLuaScript
                                if (!isValidLuaScript(arg.name)) {
                                    Context.error("Invalid IntegratedLuaScript: " + arg.name, arg.pos);
                                }
                            case TPath({pack: ["IntegratedHS"], name: "IntegratedHScript"}):
                                // Add validation logic for IntegratedHScript
                                if (!isValidHScript(arg.name)) {
                                    Context.error("Invalid IntegratedHScript: " + arg.name, arg.pos);
                                }
                            default:
                        }
                    }
                default:
            }
        }
        return macro null;
    }

    static function isValidLuaScript(script:String):Bool {
		var lua = LuaL.newstate();
		LuaL.openlibs(lua);
		try{
			var isString:Bool = !FileSystem.exists(scriptName);
			var result:Dynamic = null;
			if(!isString)
				result = LuaL.dofile(lua, scriptName);
			else
				result = LuaL.dostring(lua, scriptName);

			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace(resultStr);
                // Context.error('Script error: $resultStr', arg.pos);
				lua = null;
				return false;
			}
		} catch(e:Dynamic) {
			trace(e);
			return false;
		}
        return true;
    }

    static function isValidHScript(scriptName:String):Bool {
        Context.warning("HScript validation not implemented yet. Good luck!", Context.currentPos());
        return true;
    }
}