package psychlua;

import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;
import haxe.io.Path;

typedef IntegratedLua = {
    name: String,
    scriptText: String
};

typedef IntegratedHS = {
    name: String,
    scriptText: String
};

enum IntegratedScriptType {
    LUA;
    HSCRIPT;
}

class IntegratedLuaScript {
    public var name:String;
    public var scriptText:String;

    public function new(name:String, scriptText:String) {
        this.name = name;
        this.scriptText = scriptText;
        run();
    }

    public function run():Void {
        if (!isPlayState()) {
            throw "Script can only be run in PlayState or its extensions.";
        }

        var tempFilePath = Path.join([Sys.getCwd(), "__" + name + ".lua"]);
        var file = File.write(tempFilePath, true);
        file.writeString(scriptText);
        file.close();

        // Run the script through FunkinLua
        new FunkinLua(tempFilePath);
        // trace("Internal Lua script loaded successfully: " + name);

        // Delete the temporary file
        FileSystem.deleteFile(tempFilePath);
    }

    public static function runScript(script:IntegratedLua):Void {
        new IntegratedLuaScript(script.name, script.scriptText);
    }

    public static function runInVar(script:IntegratedLua, ?runCreatePost:Bool):FunkinLua {
        if (!isPlayState()) {
            throw "Script can only be run in PlayState or its extensions.";
        }

        var tempFilePath = Path.join([Sys.getCwd(), "__" + script.name + ".lua"]);
        var file = File.write(tempFilePath, true);
        file.writeString(script.scriptText);
        file.close();

        // Run the script through FunkinLua
        var fl = new FunkinLua(tempFilePath);
        if (runCreatePost) {
            fl.call("onCreatePost", []);
        }
        // trace("Internal Lua script loaded successfully: " + script.name);

        // Delete the temporary file
        FileSystem.deleteFile(tempFilePath);
        return fl;
    }

    private static function isPlayState():Bool {
        // Replace this with the actual check for PlayState
        return Std.is(FlxG.state, PlayState);
    }
}

class IntegratedHScript {
    public var name:String;
    public var scriptText:String;

    public function new(name:String, scriptText:String) {
        this.name = name;
        this.scriptText = scriptText;
        run();
    }

    public function run():Void {
        if (!isPlayState()) {
            throw "Script can only be run in PlayState or its extensions.";
        }

        var tempFilePath = Path.join([Sys.getCwd(), "__" + name + ".hx"]);
        var file = File.write(tempFilePath, true);
        file.writeString(scriptText);
        file.close();

        new HScript(null, tempFilePath);
        // trace("Internal HScript loaded successfully: " + name);

        // Delete the temporary file
        FileSystem.deleteFile(tempFilePath);
    }

    public static function runScript(script:IntegratedHS):Void {
        new IntegratedHScript(script.name, script.scriptText);
    }

    public static function runInVar(script:IntegratedHS, ?runCreatePost:Bool):HScript {
        if (!isPlayState()) {
            throw "Script can only be run in PlayState or its extensions.";
        }

        var tempFilePath = Path.join([Sys.getCwd(), "__" + script.name + ".hx"]);
        var file = File.write(tempFilePath, true);
        file.writeString(script.scriptText);
        file.close();

        var hs = new HScript(null, tempFilePath);
        if (runCreatePost) {
            hs.executeFunction("onCreatePost", []);
        }
        // trace("Internal HScript loaded successfully: " + script.name);

        // Delete the temporary file
        FileSystem.deleteFile(tempFilePath);
        return hs;
    }

    private static function isPlayState():Bool {
        return Std.is(FlxG.state, PlayState);
    }
}

class IntegratedScript {
    public static function runLScript(script:IntegratedLua):Void {
        IntegratedLuaScript.runScript(script);
    }

    public static function runHScript(script:IntegratedHS):Void {
        IntegratedHScript.runScript(script);
    }

    public static function runFromLuaMap(scripts:Map<String, String>):Void {
        for (key in scripts.keys()) {
            new IntegratedLuaScript(key, scripts.get(key));
        }
    }

    public static function runFromHScriptMap(scripts:Map<String, String>):Void {
        for (key in scripts.keys()) {
            new IntegratedHScript(key, scripts.get(key));
        }
    }

    public static function runFromMixedMap(scripts:Map<String, Map<IntegratedScriptType, String>>):Void {
        for (key in scripts.keys()) {
            var script = scripts.get(key);
            if (script.exists(IntegratedScriptType.LUA)) {
                new IntegratedLuaScript(key, script.get(IntegratedScriptType.LUA));
            }
            if (script.exists(IntegratedScriptType.HSCRIPT)) {
                new IntegratedHScript(key, script.get(IntegratedScriptType.HSCRIPT));
            }
        } }

    public static function runNamelessScript(type:IntegratedScriptType, scriptText:String):Void {
        switch (type) {
            case IntegratedScriptType.LUA:
                new IntegratedLuaScript(randomString(Std.int(Math.random() * 20)) + "__lua__", scriptText);
            case IntegratedScriptType.HSCRIPT:
                new IntegratedHScript(randomString(Std.int(Math.random() * 20)) + "__hx__", scriptText);
            }
    }

    public static function runAsVar(type:IntegratedScriptType, scriptText:String, ?runCreatePost:Bool):Dynamic {
        switch (type) {
            case IntegratedScriptType.LUA:
                return IntegratedLuaScript.runInVar({name: randomString(Std.int(Math.random() * 20)) + "__lua__", scriptText: scriptText}, runCreatePost);
            case IntegratedScriptType.HSCRIPT:
                return IntegratedHScript.runInVar({name: randomString(Std.int(Math.random() * 20)) + "__hx__", scriptText: scriptText}, runCreatePost);
        }
    }

    public static function runNamelessLuaScript(scriptText:String):Void {
        runNamelessScript(IntegratedScriptType.LUA, scriptText);
    }

    public static function runNamelessHScript(scriptText:String):Void {
        runNamelessScript(IntegratedScriptType.HSCRIPT, scriptText);
    }

    public static function runLuaFunction(func:String):Void {
        var script = "function onCreate()\n" + func + "\n close() \nend";
        runNamelessLuaScript(script);
        // new FunkinLua("__temp__");
    }

    public static function runHSFunction(func:String):Void {
        var script = "function onCreate() {\n" + func + "\n}";
        runNamelessHScript(script);
        // new HScript(null, "__temp__");
    }

    private static function randomString(length:Int):String {
        var chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        var result = "";
        for (i in 0...length) {
            result += chars.charAt(Std.random(chars.length));
        }
        return result;
    }
}