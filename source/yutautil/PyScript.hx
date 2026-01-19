package yutautil;

#if (PYTHON_ALLOWED && windows)
import flixel.FlxG;
import haxe.Json;
import hxpy.Py;
import hxpy.PyConfig;
import hxpy.PyRun;
import hxpy.PyStatus;
import states.PlayState;
import sys.FileSystem;
import sys.io.File;

using cpp.RawPointer;

/**
 * Simple Python scripting integration for Mixtape Engine
 * Uses basic hxpy functionality for script execution
 * This is just a test to get basic scripting working; more advanced features may be added later.
 */
class PyScript {
    // Static constants for script control (matching psychlua.FunkinLua)
    public static var Function_Continue:Int = 0;
    public static var Function_Stop:Int = 1;
    public static var Function_StopLua:Int = 2;
    public static var Function_StopHScript:Int = 3;
    public static var Function_StopAll:Int = 4;

    // Static PyConfig and PyStatus for proper pointer management
    private static var config:PyConfig;
    private static var status:PyStatus;

    private var scriptPath:String;
    public var scriptName:String;  // Made public for PlayState access
    private var isInitialized:Bool = false;

    public var scriptExists:Bool = false;
    public var closed:Bool = false;
    public var errorOccurred:Bool = false;

    public function new(scriptPath:String) {
        this.scriptPath = scriptPath;
        this.scriptName = haxe.io.Path.withoutDirectory(scriptPath);

        if (FileSystem.exists(scriptPath)) {
            scriptExists = true;
            initialize();
        }
    }

    private function initialize():Void {
        try {
            // Initialize Python interpreter if not already done
            if (!Py.isInitialized()) {
                initializePythonWithConfig();
            }

            // Set up basic environment
            setupBasicEnvironment();

            // Read and execute the script file
            var scriptContent = File.getContent(scriptPath);
            executeCode(scriptContent);

            isInitialized = true;
            trace('Python script initialized: $scriptName');
        } catch (e:Dynamic) {
            trace('Failed to initialize Python script: $e');
            isInitialized = false;
            scriptExists = false;
            errorOccurred = true;
        }
    }

    private function initializePythonWithConfig():Void {
        try {
            // Initialize Python config using static variables
            PyConfig.initPythonConfig(config.addressOf());

            // Set Python home to our bin/python directory
            var pythonHome = haxe.io.Path.join([Sys.getCwd(), "python"]);
            if (FileSystem.exists(pythonHome)) {
                // Convert to wide string for PyConfig
                status = PyConfig.setBytesString(config.addressOf(), config.home.addressOf(), pythonHome);
                if (Py.exception(status)) {
                    trace('Warning: Could not set Python home to $pythonHome');
                }

                // Also set program name for better path resolution
                status = PyConfig.setBytesString(config.addressOf(), config.program_name.addressOf(), "PyScript");
                if (Py.exception(status)) {
                    trace('Warning: Could not set Python program name');
                }

                trace('Python configured to use home directory: $pythonHome');
            }

            // Initialize Python with our configuration
            status = Py.initializeFromConfig(config.addressOf());
            if (Py.exception(status)) {
                trace('Failed to initialize Python with config, falling back to basic initialization');
                PyConfig.clear(config.addressOf());
                Py.initialize();
                return;
            }

            PyConfig.clear(config.addressOf());
            trace('Python successfully initialized with custom configuration');

        } catch (e:Dynamic) {
            trace('Error during Python config initialization: $e');
            // Clean up and fall back to basic initialization
            try {
                PyConfig.clear(config.addressOf());
            } catch (cleanupError:Dynamic) {
                // Ignore cleanup errors
            }
            Py.initialize();
        }
    }

    private function setupBasicEnvironment():Void {
        // Execute basic setup code
        var setupCode =
"import sys
import math
import time
import json

# Basic constants
Function_Continue = 0
Function_Stop = 1

# Basic utility functions
def debugPrint(text):
    print('[Python]: ' + str(text))

def trace(text, pos=None):
    print('[Python Trace]: ' + str(text))

# Placeholder callback functions
def onCreate(): pass
def onUpdate(elapsed): pass
def onBeatHit(): pass
def onStepHit(): pass
def onNoteHit(note): pass
def onNoteMiss(note): pass
def onSongStart(): pass
def onSongEnd(): pass
def onGameOver(): return Function_Continue
def onPause(): return Function_Continue
def onResume(): pass
def onDestroy(): pass
def onEvent(name, v1, v2): return Function_Continue

# Global variables for game access
game = None
FlxG = None
";

        executeCode(setupCode);
    }

    public function executeCode(code:String):Void {
        if (!scriptExists || !isInitialized) return;

        try {
            PyRun.simpleString(code);
        } catch (e:Dynamic) {
            trace('Python execution error in $scriptName: $e');
            errorOccurred = true;
        }
    }

    public function call(functionName:String, ?args:Array<Dynamic>):Dynamic {
        if (!scriptExists || !isInitialized) return null;

        try {
            // Simple function call without args for now
            var callCode = functionName + "()";
            executeCode(callCode);
            return 0; // Return Function_Continue equivalent
        } catch (e:Dynamic) {
            trace('Error calling Python function $functionName: $e');
            return null;
        }
    }

    public function set(varName:String, value:Dynamic):Void {
        if (!scriptExists || !isInitialized) return;

        try {
            var valueStr = "";
            if (Std.isOfType(value, String)) {
                valueStr = '"' + Std.string(value) + '"';
            } else if (Std.isOfType(value, Float) || Std.isOfType(value, Int)) {
                valueStr = Std.string(value);
            } else if (Std.isOfType(value, Bool)) {
                valueStr = value ? "True" : "False";
            } else {
                valueStr = "None";
            }

            var code = varName + " = " + valueStr;
            executeCode(code);
        } catch (e:Dynamic) {
            trace('Error setting Python variable $varName: $e');
            errorOccurred = true;
        }
    }

    public function get(varName:String):Dynamic {
        // Basic implementation - getting variables back is complex with simple hxpy
        return null;
    }

    public function setVar(varName:String, value:Dynamic):Void {
        // Alias for set() method to match expected API
        set(varName, value);
    }

    public function exists(functionName:String):Bool {
        // For now, assume common callback functions exist
        return ["onCreate", "onUpdate", "onBeatHit", "onStepHit", "onNoteHit",
                "onNoteMiss", "onSongStart", "onSongEnd", "onGameOver",
                "onPause", "onResume", "onDestroy", "onEvent"].contains(functionName);
    }

    public function existsVar(varName:String):Bool {
        return false; // Simple implementation
    }

    public function destroy():Void {
        if (isInitialized) {
            try {
                this.call("onDestroy");
            } catch (e:Dynamic) {
                trace('Error in Python onDestroy: $e');
                errorOccurred = true;
            }
        }
        isInitialized = false;
        scriptExists = false;
        closed = true;
    }
}

/**
 * Manager for multiple Python scripts
 */
class PyScriptManager {
    public static var scripts:Array<PyScript> = [];

    public static function loadScript(path:String):PyScript {
        var script = new PyScript(path);
        if (script.scriptExists) {
            scripts.push(script);
        }
        return script;
    }

    public static function loadScriptsFromDirectory(directory:String):Void {
        if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;

        for (file in FileSystem.readDirectory(directory)) {
            if (file.endsWith(".py")) {
                var fullPath = haxe.io.Path.join([directory, file]);
                loadScript(fullPath);
            }
        }
    }

    public static function callOnAll(functionName:String, ?args:Array<Dynamic>):Dynamic {
        var result = 0; // Function_Continue

        for (script in scripts) {
            try {
                var scriptResult = script.call(functionName, args);
                if (scriptResult != null && scriptResult != 0) {
                    result = scriptResult;
                    if (scriptResult == 1) { // Function_Stop
                        break;
                    }
                }
            } catch (e:Dynamic) {
                trace('Error calling $functionName on Python script: $e');
            }
        }

        return result;
    }

    public static function setOnAll(varName:String, value:Dynamic):Void {
        for (script in scripts) {
            script.set(varName, value);
        }
    }

    public static function destroyAll():Void {
        for (script in scripts) {
            script.destroy();
        }
        scripts = [];
    }

    public static function getScriptCount():Int {
        return scripts.length;
    }

    public static function hasAnyScript():Bool {
        for (script in scripts) {
            if (script.scriptExists) return true;
        }
        return false;
    }
}

#else

// Stub implementation when Python is not allowed
class PyScript {
    // Static constants for script control (matching psychlua.FunkinLua)
    public static var Function_Continue:Int = 0;
    public static var Function_Stop:Int = 1;
    public static var Function_StopLua:Int = 2;
    public static var Function_StopHScript:Int = 3;
    public static var Function_StopAll:Int = 4;

    public var scriptName:String;
    public var scriptExists:Bool = false;
    public var closed:Bool = false;
    public var errorOccurred:Bool = false;

    public function new(scriptPath:String) {
        this.scriptName = haxe.io.Path.withoutDirectory(scriptPath);
        this.scriptExists = false;
        this.closed = true;
        this.errorOccurred = false;
    }

    public function executeCode(code:String):Void {}
    public function call(func:String, ?args:Array<Dynamic>):Dynamic { return 0; }
    public function set(varName:String, value:Dynamic):Void {}
    public function get(varName:String):Dynamic { return null; }
    public function setVar(varName:String, value:Dynamic):Void {}
    public function exists(functionName:String):Bool { return false; }
    public function existsVar(varName:String):Bool { return false; }
    public function destroy():Void {
        scriptExists = false;
        closed = true;
    }
}

class PyScriptManager {
    public static var scripts:Array<PyScript> = [];

    public static function loadScript(path:String):PyScript {
        var script = new PyScript(path);
        scripts.push(script);
        return script;
    }

    public static function loadScriptsFromDirectory(directory:String):Void {}
    public static function callOnAll(functionName:String, ?args:Array<Dynamic>):Dynamic { return 0; }
    public static function setOnAll(varName:String, value:Dynamic):Void {}
    public static function destroyAll():Void {
        for (script in scripts) {
            script.destroy();
        }
        scripts = [];
    }
    public static function getScriptCount():Int { return scripts.length; }
    public static function hasAnyScript():Bool { return false; }
}

#end
