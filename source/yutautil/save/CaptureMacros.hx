package yutautil.save;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import yutautil.save.FunctionCapture;
#end

/**
 * Macros for capturing constructor arguments and function definitions
 */
class CaptureMacros {

    #if macro

    /**
     * @:constructorCapture - Captures constructor arguments for reconstruction
     * Usage: @:build(yutautil.save.CaptureMacros.constructorCapture())
     */
    public static function constructorCapture():Array<Field> {
        return FunctionCapture.buildConstructorCapture();
    }

    /**
     * @:functionCapture - Captures function definitions for serialization
     * Usage: @:build(yutautil.save.CaptureMacros.functionCapture())
     */
    public static function functionCapture():Array<Field> {
        return FunctionCapture.buildFunctionCapture();
    }

    /**
     * @:fullCapture - Captures both constructors and functions
     * Usage: @:build(yutautil.save.CaptureMacros.fullCapture())
     */
    public static function fullCapture():Array<Field> {
        var fields = FunctionCapture.buildConstructorCapture();
        return FunctionCapture.buildFunctionCapture();
    }

    #end
}

/**
 * Helper class for working with captured functions at runtime
 */
class CaptureHelper {

    /**
     * Execute a function on a specific instance
     * @param instance The instance to execute on
     * @param functionName The name of the function
     * @param args Arguments to pass
     * @return Function result
     */
    public static function executeOnInstance(instance:Dynamic, functionName:String, args:Array<Dynamic>):Dynamic {
        var className = Type.getClassName(Type.getClass(instance));
        var functionId = '${className}.${functionName}.Instance';

        return FunctionCapture.executeFunction(functionId, args, instance);
    }

    /**
     * Execute a static function
     * @param className Full class name
     * @param functionName Function name
     * @param args Arguments to pass
     * @return Function result
     */
    public static function executeStatic(className:String, functionName:String, args:Array<Dynamic>):Dynamic {
        var functionId = '${className}.${functionName}.Static';
        return FunctionCapture.executeFunction(functionId, args);
    }

    /**
     * Create an instance using captured constructor data
     * @param className Full class name
     * @param args Constructor arguments
     * @return New instance
     */
    public static function createInstanceWithCapture(className:String, args:Array<Dynamic>):Dynamic {
        return FunctionCapture.createInstance(className, args);
    }

    /**
     * Check if a function is captured
     * @param className Class name
     * @param functionName Function name
     * @param type Function type (Static, Instance, etc.)
     * @return True if captured
     */
    public static function isFunctionCaptured(className:String, functionName:String, type:FunctionType):Bool {
        var functionId = '${className}.${functionName}.${type.getName()}';
        return FunctionCapture.getFunctionInfo(functionId) != null;
    }

    /**
     * Get all functions for a specific class
     * @param className Class name to filter by
     * @return Array of function IDs
     */
    public static function getFunctionsForClass(className:String):Array<String> {
        var allFunctions = FunctionCapture.listFunctions();
        return allFunctions.filter(function(id) return id.indexOf(className + ".") == 0);
    }

    /**
     * Generate a serializable representation of all captured data
     * @return Object containing all captured functions and constructors
     */
    public static function exportCapturedData():Dynamic {
        var functions:Array<CapturedFunction> = [];
        var constructors:Array<CapturedConstructor> = [];

        for (functionId in FunctionCapture.listFunctions()) {
            var func = FunctionCapture.getFunctionInfo(functionId);
            if (func != null) functions.push(func);
        }

        for (className in FunctionCapture.listConstructors()) {
            // Note: We'd need to expose constructor data in FunctionCapture for this
            // For now, just include the class name
            constructors.push({
                className: className,
                args: [],
                body: ""
            });
        }

        return {
            functions: functions,
            constructors: constructors,
            exportTime: Date.now().getTime(),
            version: "1.0.0"
        };
    }

    /**
     * Import captured data from a serializable format
     * @param data Data exported with exportCapturedData()
     */
    public static function importCapturedData(data:Dynamic):Void {
        if (data.functions != null) {
            var functions:Array<CapturedFunction> = cast data.functions;
            for (func in functions) {
                FunctionCapture.registerFunction(func);
            }
        }

        if (data.constructors != null) {
            var constructors:Array<CapturedConstructor> = cast data.constructors;
            for (constructor in constructors) {
                FunctionCapture.registerConstructor(constructor);
            }
        }

        trace('Imported ${data.functions != null ? data.functions.length : 0} functions and ${data.constructors != null ? data.constructors.length : 0} constructors');
    }
}

/**
 * Runtime storage for constructor arguments used during object creation
 */
class ConstructorArguments {

    private static var _constructorArgs:Map<Dynamic, Array<Dynamic>> = new Map();

    /**
     * Store constructor arguments for an instance
     * @param instance The created instance
     * @param args The arguments used to create it
     */
    public static function storeArgs(instance:Dynamic, args:Array<Dynamic>):Void {
        _constructorArgs.set(instance, args.copy());
    }

    /**
     * Get stored constructor arguments for an instance
     * @param instance The instance to get args for
     * @return Array of constructor arguments, or null if not found
     */
    public static function getArgs(instance:Dynamic):Array<Dynamic> {
        return _constructorArgs.get(instance);
    }

    /**
     * Create a copy of an instance using its stored constructor arguments
     * @param instance The instance to copy
     * @return New instance created with same arguments, or null if args not stored
     */
    public static function recreateInstance(instance:Dynamic):Dynamic {
        var args = getArgs(instance);
        if (args == null) return null;

        var className = Type.getClassName(Type.getClass(instance));
        return CaptureHelper.createInstanceWithCapture(className, args);
    }

    /**
     * Clear stored arguments for an instance (for memory management)
     * @param instance Instance to clear args for
     */
    public static function clearArgs(instance:Dynamic):Void {
        _constructorArgs.remove(instance);
    }

    /**
     * Clear all stored constructor arguments
     */
    public static function clearAllArgs():Void {
        _constructorArgs.clear();
    }

    /**
     * Get all instances that have stored constructor arguments
     * @return Array of instances
     */
    public static function getTrackedInstances():Array<Dynamic> {
        return [for (instance in _constructorArgs.keys()) instance];
    }
}

/**
 * Extension methods for working with captured functions
 */
class CaptureExtensions {

    /**
     * Check if an object has captured functions
     * @param obj Object to check
     * @return True if the object's class has captured functions
     */
    public static function hasCapturedFunctions(obj:Dynamic):Bool {
        var className = Type.getClassName(Type.getClass(obj));
        var functions = CaptureHelper.getFunctionsForClass(className);
        return functions.length > 0;
    }

    /**
     * Execute a method on an object using the capture system
     * @param obj Object instance
     * @param methodName Method name to execute
     * @param args Method arguments
     * @return Method result
     */
    public static function executeCaptured(obj:Dynamic, methodName:String, args:Array<Dynamic>):Dynamic {
        return CaptureHelper.executeOnInstance(obj, methodName, args);
    }

    /**
     * Get information about captured functions for this object
     * @param obj Object instance
     * @return Array of function information
     */
    public static function getCapturedFunctionInfo(obj:Dynamic):Array<CapturedFunction> {
        var className = Type.getClassName(Type.getClass(obj));
        var functionIds = CaptureHelper.getFunctionsForClass(className);
        var infos:Array<CapturedFunction> = [];

        for (id in functionIds) {
            var info = FunctionCapture.getFunctionInfo(id);
            if (info != null) infos.push(info);
        }

        return infos;
    }
}
