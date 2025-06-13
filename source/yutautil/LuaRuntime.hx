package yutautil;

import lua.Lua;
import lua.LuaTable;

class LuaRuntime {
    public var luaFile:String;
    public var luaEnv:LuaTable;

    public function new(luaFile:String) {
        this.luaFile = luaFile;
        this.luaEnv = Lua.table();
        loadScript();
    }

    private function loadScript():Void {
        var code = sys.io.File.getContent(luaFile);
        Lua.doString(code, luaEnv);
    }

    public function callFunc(funcName:String, args:Array<Dynamic> = null):Dynamic {
        var func = luaEnv[funcName];
        if (func != null && Lua.isFunction(func)) {
            return Reflect.callMethod(luaEnv, func, args != null ? args : []);
        }
        return null;
    }

    public function getVar(varName:String):Dynamic {
        return luaEnv[varName];
    }

    public function setVar(varName:String, value:Dynamic):Void {
        luaEnv[varName] = value;
    }
}
