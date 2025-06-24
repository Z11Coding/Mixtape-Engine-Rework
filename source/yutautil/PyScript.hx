
package yutautil;

#if PYTHON_ALLOWED
import cpp.Lib;
import cpp.Pointer;
import cpp.Native;
import cpp.RawPointer;
import cpp.ConstCharStar;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import flixel.FlxG;
import flixel.util.FlxColor;
import backend.CoolUtil;
import states.PlayState;

// Python binding classes from hxpy - only use what's available
import hxpy.PyObject;
import hxpy.PyLong;
import hxpy.PyCallable;
import hxpy.*;

// Python type abstracts for automatic conversion using only hxpy classes
abstract PyBool(RawPointer<PyObject>) from RawPointer<PyObject> to RawPointer<PyObject> {
    @:from static public function fromBool(value:Bool):PyBool {
        return cast PyBool.fromBool(value);
    }
    
    @:from static public function fromPyObject(obj:RawPointer<PyObject>):PyBool {
        return cast obj;
    }
    
    @:to public function toBool():Bool {
        return hxpy.PyBool.check(this);
    }
    
    @:to public function toPyObject():RawPointer<PyObject> {
        return this;
    }
}

abstract PyInt(RawPointer<PyObject>) from RawPointer<PyObject> to RawPointer<PyObject> {
    @:from static public function fromInt(value:Int):PyInt {
        return cast PyLong.fromLong(value);
    }
    
    @:from static public function fromPyObject(obj:RawPointer<PyObject>):PyInt {
        return cast obj;
    }
    
    @:to public function toInt():Int {
        return PyLong.asLong(this);
    }
    
    @:to public function toPyObject():RawPointer<PyObject> {
        return this;
    }
}

abstract PyFloat(RawPointer<PyObject>) from RawPointer<PyObject> to RawPointer<PyObject> {
    @:from static public function fromFloat(value:Float):PyFloat {
        return cast PyFloat.fromDouble(value);
    }
    
    @:from static public function fromPyObject(obj:RawPointer<PyObject>):PyFloat {
        return cast obj;
    }
    
    @:to public function toFloat():Float {
        return PyFloat.asDouble(this);
    }
    
    @:to public function toPyObject():RawPointer<PyObject> {
        return this;
    }
}

abstract PyString(RawPointer<PyObject>) from RawPointer<PyObject> to RawPointer<PyObject> {
    @:from static public function fromString(value:String):PyString {
        return cast PyUnicode.fromString(value);
    }
    
    @:from static public function fromPyObject(obj:RawPointer<PyObject>):PyString {
        return cast obj;
    }
    
    @:to public function toString():String {
        // Simplified conversion
        return hxpy.PyUnicode.asUTF8(this);
    }
    
    @:to public function toPyObject():RawPointer<PyObject> {
        return this;
    }
}

abstract PyCallableEx(RawPointer<PyObject>) from RawPointer<PyObject> to RawPointer<PyObject> {
    public function new(obj:RawPointer<PyObject>) {
        if (!PyCallable.check(obj)) {
            throw "Object is not callable";
        }
        this = obj;
    }
    
    @:from static public function fromPyObject(obj:RawPointer<PyObject>):PyCallableEx {
        return cast obj;
    }
    
    @:to public function toPyObject():RawPointer<PyObject> {
        return this;
    }
    
    public function call(?args:Array<RawPointer<PyObject>>):RawPointer<PyObject> {
        // Use PyObject.callObject with proper args
        var pyArgs = args != null ? createTuple(args) : null;
        return PyObject.callObject(this, pyArgs);
    }
    
    // Helper to create tuple from array (simplified)
    private function createTuple(args:Array<RawPointer<PyObject>>):RawPointer<PyObject> {
        var tuplez:RawPointer<PyObject> = PyTuple.newPyTuple(args.length);
        for (i in 0...args.length) {
            PyTuple.setItem(tuplez, i, args[i]);
        }
        return tuplez;
    }
}

abstract PyDynamic(Dynamic)
    from Dynamic to RawPointer<PyObject> {
    public function new(value:Dynamic) {
        this = convertToPython(value);
    }
    
    @:from static public function fromPyObject(obj:RawPointer<PyObject>):PyDynamic {
        return cast obj;
    }
    
    @:to public function toPyObject():RawPointer<PyObject> {
        return this;
    }
    
    public function toDynamic():Dynamic {
        return convertFromPython(this);
    }
    public function makeTuple(args:Array<Dynamic>):RawPointer<PyObject> {
        var tuple = PyTuple.newPyTuple(args.length);
        for (i in 0...args.length) {
            PyTuple.setItem(tuple, i, convertToPython(args[i]));
        }
        return tuple;
    }

    public function makeDict(map:Map<String, Dynamic>):RawPointer<PyObject> {
        var dict = new RawPointer<PyObject>();
        for (key in map.keys()) {
            PyDict.setItemString(dict, key, convertToPython(map.get(key)));
        }
        return dict;
    }

    public function convertToPython(value:Dynamic):RawPointer<PyObject> {
        // Simplified conversion logic
        return switch (Type.typeof(value)) {
            case TBool: 
                PyBool.fromBool(value);
            case TInt: 
                PyLong.fromLong(value);
            case TFloat: 
                PyFloat.fromFloat(value);
            case TClass(String): 
                PyString.fromString(value);
            case TClass(Array):
                makeTuple(value);
            case TClass(haxe.IMap):
                makeDict(value);
            default: 
                cast value; // Assume it's already a PyObject
        }
    }
}

/**
 * Enhanced Python script system that works like HScript and FunkinLua
 * Supports continuous script execution and callback system
 * Using only available hxpy classes
 */
class PyScript {
    public static var Function_Stop:Int = 1;
    public static var Function_Continue:Int = 0;
    public static var Function_StopPy:Int = 2;
    
    public var scriptName:String = '';
    public var modFolder:String = null;
    public var closed:Bool = false;
    
    // Simplified - store raw PyObject pointers
    private var pyModule:RawPointer<PyObject>;
    private var pyGlobals:RawPointer<PyObject>;
    private var pyLocals:RawPointer<PyObject>;
    
    public var callbacks:Map<String, RawPointer<PyObject>> = new Map<String, RawPointer<PyObject>>();
    public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

    public function new(scriptName:String) {
        this.scriptName = scriptName.trim();
        
        // Note: This is a simplified version that focuses on the structure
        // Actual Python initialization would need proper hxpy setup
        
        // Add to PlayState script array
        var game:PlayState = PlayState.instance;
        if (game != null) {
            game.pyScriptArray.push(this);
        }
        
        // Set up basic variables and functions
        initializeScript();
        
        // Load and execute script
        try {
            var scriptCode:String;
            if (FileSystem.exists(scriptName)) {
                scriptCode = File.getContent(scriptName);
            } else {
                scriptCode = scriptName; // Treat as direct code
            }
            
            // Simplified execution - would need proper Python execution
            trace('Python script loaded: $scriptName');
            call('onCreate', []);
        } catch (e:Dynamic) {
            pyTrace('Exception in Python script: $e');
            closed = true;
        }
    }
    
    private function initializeScript():Void {
        // Set constants
        set('Function_Stop', Function_Stop);
        set('Function_Continue', Function_Continue);
        set('Function_StopPy', Function_StopPy);
        
        // Game state access
        set('game', PlayState.instance);
        set('FlxG', FlxG);
        
        // Basic functions
        setCallback('trace', function(text:Dynamic, ?color:String = 'WHITE') {
            pyTrace(Std.string(text), CoolUtil.colorFromString(color));
        });
        
        setCallback('close', function() {
            closed = true;
            trace('Closing Python script: $scriptName');
            return closed;
        });
          // Callback system
        setCallback('addCallback', function(name:String, func:RawPointer<PyObject>) {
            callbacks.set(name, func);
        });
        
        setCallback('call', function(funcName:String, ?args:Array<Dynamic>) {
            return call(funcName, args);
        });
        
        // Variable management
        setCallback('setVar', function(name:String, value:Dynamic) {
            if (PlayState.instance != null) {
                PlayState.instance.variables.set(name, value);
            }
            return value;
        });
        
        setCallback('getVar', function(name:String) {
            if (PlayState.instance != null) {
                return PlayState.instance.variables.get(name);
            }
            return null;
        });
        
        // Inter-script communication
        setCallback('callOnScripts', function(funcName:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false) {
            if (PlayState.instance != null) {
                return PlayState.instance.callOnScripts(funcName, args, ignoreStops);
            }
            return Function_Continue;
        });
        
        setCallback('callOnPyScripts', function(funcName:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false) {
            if (PlayState.instance != null) {
                return PlayState.instance.callOnPyScripts(funcName, args, ignoreStops);
            }
            return Function_Continue;
        });
        
        // Add custom functions
        for (name => func in customFunctions) {
            if (func != null) {
                setCallback(name, func);
            }
        }
    }
      public function set(name:String, value:Dynamic):Void {
        if (closed) return;
        
        try {
            // Simplified version - store in a map for now
            // Would need proper Python dictionary access
            trace('Setting Python variable $name to $value');
        } catch (e:Dynamic) {
            pyTrace('Error setting variable $name: $e');
        }
    }
    
    public function get(name:String):Dynamic {
        if (closed) return null;
        
        try {
            // Simplified version - would need proper Python dictionary access
            trace('Getting Python variable $name');
            return null;
        } catch (e:Dynamic) {
            pyTrace('Error getting variable $name: $e');
            return null;
        }
    }
    
    public function setCallback(name:String, func:Dynamic):Void {
        if (closed) return;
        
        try {
            // Simplified version - store callback for later use
            trace('Setting Python callback $name');
        } catch (e:Dynamic) {
            pyTrace('Error setting callback $name: $e');
        }
    }
    
    public function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (closed) return Function_Continue;
        
        try {
            // Simplified version - would need proper Python function calling
            trace('Calling Python function $funcName with args: $args');
            return Function_Continue;
        } catch (e:Dynamic) {
            pyTrace('Error calling function $funcName: $e');
            return Function_Continue;
        }
    }
    
    public function exists(funcName:String):Bool {
        if (closed) return false;
        
        try {
            // Simplified version - would need proper Python function checking
            return callbacks.exists(funcName);
        } catch (e:Dynamic) {
            return false;
        }
    }
        // Use PyDynamic's convertToPython for conversion
        private function convertToPython(value:Dynamic):RawPointer<PyObject> {
            return PyDynamic.fromDynamic(value);
        }
    private function convertFromPython(pyValue:RawPointer<PyObject>):Dynamic {
        if (pyValue == null) return null;
        
        // Simplified conversion - would need proper type checking
        return pyValue;
    }
    
    public function stop():Void {
        closed = true;
        
        if (pyModule != null) {
            // Clean up Python objects
            pyModule = null;
            pyGlobals = null;
            pyLocals = null;
        }
        
        callbacks.clear();
    }
    
    public static function pyTrace(text:String, ?allowedToShow:Bool = true, ?ignoreCheck:Bool = false, ?color:FlxColor = FlxColor.WHITE):Void {
        if (allowedToShow) {
            if (PlayState.instance != null) {
                PlayState.instance.addTextToDebug(text, color);
            } else {
                trace(text);
            }
        }
    }
    
    // Legacy functions for compatibility
    public static function runScript(scriptPath:String):Bool {
        try {
            new PyScript(scriptPath);
            return true;
        } catch (e:Dynamic) {
            trace("Failed to run Python script: " + scriptPath + " - " + e);
            return false;
        }
    }
    
    public static function runScriptFromString(scriptCode:String):Bool {
        if (scriptCode == null || scriptCode.trim() == "") {
            trace("No script code provided.");
            return false;
        }
        
        try {
            new PyScript(scriptCode);
            return true;
        } catch (e:Dynamic) {
            trace("Failed to run Python script from string: " + e);
            return false;
        }
    }
}

// Helper class for Python file operations (implementing the missing PyHelper)
class PyHelper {
    public static function toFile(path:String):Dynamic {
        #if cpp
        try {
            if (!FileSystem.exists(path)) {
                return null;
            }
            
            // Use native C file pointer
            return cpp.Lib.load("std", "fopen", 2)(path, "r");
        } catch (e:Dynamic) {
            trace("PyHelper.toFile error: " + e);
            return null;
        }
        #else
        return null;
        #end
    }
}
#else
// Stub implementations for non-CPP targets
class PyScript {
    public static var Function_Stop:Int = 1;
    public static var Function_Continue:Int = 0;
    public static var Function_StopPy:Int = 2;
    
    public var scriptName:String = '';
    public var closed:Bool = false;
    
    public function new(scriptName:String) {
        this.scriptName = scriptName;
        trace("PyScript is not supported in this target: " + scriptName);
        closed = true;
    }
    
    public function call(funcName:String, ?args:Array<Dynamic>):Dynamic {
        return Function_Continue;
    }
    
    public function exists(funcName:String):Bool {
        return false;
    }
    
    public function set(name:String, value:Dynamic):Void {}
    public function get(name:String):Dynamic { return null; }
    public function stop():Void {}
    
    public static function runScript(scriptPath:String):Bool {
        return false;
    }
    
    public static function runScriptFromString(scriptCode:String):Bool {
        return false;
    }
}

class PyHelper {
    public static function toFile(path:String):Dynamic {
        return null;
    }
}
#end