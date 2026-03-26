package yutautil.modules;

import haxe.Timer;
import yutautil.Threader.ThreadQueue;

/**
 * Internal structure for tracking async operation status
 */
typedef ASyncStatus<T> = {
    var status: AsyncState;
    var result: Null<T>;
    var error: Null<Dynamic>;
    var callbacks: Array<T -> Void>;
    var errorCallbacks: Array<Dynamic -> Void>;
    var startTime: Float;
}

/**
 * Status of an asynchronous operation
 */
enum AsyncState {
    Pending;
    Completed;
    Failed;
}

/**
 * AResult represents the result of an asynchronous operation
 * It automatically converts to the expected type when ready, or waits if not ready
 */
abstract AResult<T>(ASyncStatus<T>) {

    public inline function new() {
        this = {
            status: Pending,
            result: null,
            error: null,
            callbacks: [],
            errorCallbacks: [],
            startTime: Timer.stamp()
        };
    }

    /**
     * Check if the result is ready
     */
    public var isReady(get, never):Bool;
    private inline function get_isReady():Bool {
        return this.status == Completed;
    }

    /**
     * Check if the operation failed
     */
    public var isFailed(get, never):Bool;
    private inline function get_isFailed():Bool {
        return this.status == Failed;
    }

    /**
     * Check if still pending
     */
    public var isPending(get, never):Bool;
    private inline function get_isPending():Bool {
        return this.status == Pending;
    }

    /**
     * Get the status
     */
    public var status(get, never):AsyncState;
    private inline function get_status():AsyncState {
        return this.status;
    }

    /**
     * Get how long the operation has been running (in seconds)
     */
    public var elapsedTime(get, never):Float;
    private inline function get_elapsedTime():Float {
        return Timer.stamp() - this.startTime;
    }

    /**
     * Set the result (internal use)
     */
    public inline function _setResult(value:T):Void {
        if (this.status != Pending) return;

        this.result = value;
        this.status = Completed;

        // Execute callbacks
        for (callback in this.callbacks) {
            try {
                callback(value);
            } catch (e:Dynamic) {
                trace("AResult callback error: " + e);
            }
        }
        this.callbacks = [];
    }

    /**
     * Set completion for Void results (internal use)
     */
    public inline function _setVoidResult():Void {
        if (this.status != Pending) return;

        this.status = Completed;
        // For Void, we don't set this.result as it's not meaningful

        // Execute callbacks (they expect void, so we pass a fake value)
        for (callback in this.callbacks) {
            try {
                callback(cast null);
            } catch (e:Dynamic) {
                trace("AResult callback error: " + e);
            }
        }
        this.callbacks = [];
    }

    /**
     * Set an error (internal use)
     */
    public inline function _setError(error:Dynamic):Void {
        if (this.status != Pending) return;

        this.error = error;
        this.status = Failed;

        // Add warning trace with error and stack trace
        var errorMessage = "ASync operation failed: " + Std.string(error);
        var stackTrace = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
        trace("WARNING: " + errorMessage + "\nStack trace:\n" + stackTrace);

        // Execute error callbacks
        for (callback in this.errorCallbacks) {
            try {
                callback(error);
            } catch (e:Dynamic) {
                trace("AResult error callback error: " + e);
            }
        }
        this.errorCallbacks = [];
    }

    /**
     * Add callback for when result is ready
     */
    public inline function onReady(callback:T -> Void):AResult<T> {
        if (this.status == Completed && this.result != null) {
            callback(this.result);
        } else if (this.status == Pending) {
            this.callbacks.push(callback);
        }
        return abstract;
    }

    /**
     * Add callback for when operation fails
     */
    public inline function onError(callback:Dynamic -> Void):AResult<T> {
        if (this.status == Failed && this.error != null) {
            callback(this.error);
        } else if (this.status == Pending) {
            this.errorCallbacks.push(callback);
        }
        return abstract;
    }

    /**
     * Get result - blocks until ready (use carefully!)
     */
    public inline function get():T {
        while (this.status == Pending) {
            Sys.sleep(0.001); // 1ms sleep to prevent busy waiting
        }

        if (this.status == Failed) {
            throw this.error;
        }

        return this.result;
    }

    public inline function getWithDefault(defaultValue:T):T {
        while (this.status == Pending) {
            Sys.sleep(0.001); // 1ms sleep to prevent busy waiting
        }

        if (this.status == Failed) {
            return defaultValue;
        }

        return this.result;
    }

    public inline function getWithFallback(fallback:() -> T):T {
        while (this.status == Pending) {
            Sys.sleep(0.001); // 1ms sleep to prevent busy waiting
        }

        if (this.status == Failed) {
            return fallback();
        }

        return this.result;
    }

    public inline function getWithHandler(handler:Dynamic -> T):T {
        while (this.status == Pending) {
            Sys.sleep(0.001); // 1ms sleep to prevent busy waiting
        }

        if (this.status == Failed) {
            return handler(this.error);
        }

        return this.result;
    }

    public inline function getWithCallback(onError:Dynamic -> T, onSuccess:T -> T):T {
        while (this.status == Pending) {
            Sys.sleep(0.001); // 1ms sleep to prevent busy waiting
        }

        if (this.status == Failed) {
            return onError(this.error);
        }

        return onSuccess(this.result);
    }

    public inline function getWithCallbacks(onError:OneOrMany<Dynamic -> T>, onSuccess:OneOrMany<T -> T>):T {
        while (this.status == Pending) {
            Sys.sleep(0.001); // 1ms sleep to prevent busy waiting
        }

        if (this.status == Failed) {
            var result:Dynamic = this.error;
            for (callback in onError) {
                result = callback(result);
            }
            return result;
        } else {
            var result:T = this.result;
            for (callback in onSuccess) {
                result = callback(result);
            }
            return result;
        }
    }

    /**
     * Try to get result without waiting
     * Returns null if not ready or failed
     */
    public inline function tryGet():Null<T> {
        return (this.status == Completed) ? this.result : null;
    }

    /**
     * Get result with timeout (in seconds)
     * Throws if timeout exceeded
     */
    public inline function getWithTimeout(timeoutSeconds:Float):T {
        var startTime = Timer.stamp();
        while (this.status == Pending && (Timer.stamp() - startTime) < timeoutSeconds) {
            Sys.sleep(0.001);
        }

        if (this.status == Pending) {
            throw "AResult timeout after " + timeoutSeconds + " seconds";
        }

        if (this.status == Failed) {
            throw this.error;
        }

        return this.result;
    }

    @:to public inline function standardAResult():AResult<T> {
        return abstract;
    }


    /**
     * Automatic conversion to target type - waits until ready
     */
    @:to public inline function toValue():T {
        return get();
    }

    /**
     * Implicit conversion from completed value
     */
    @:from public static function fromValue<T>(value:T):AResult<T> {
        var result = new AResult<T>();
        result._setResult(value);
        return result;
    }

    public function toString():String {
        return switch (this.status) {
            case Pending: "AResult<Pending> (${elapsedTime}s)";
            case Completed: "AResult<Completed>(${this.result})";
            case Failed: "AResult<Failed>(${this.error})";
        }
    }
}

/**
 * Internal structure for ASync function wrapper
 */
typedef ASyncData = {
    var func: Dynamic;
    var isAsync: Bool;
}
/**
 * ASyncF is a typed wrapper around ASync for specifying the return type of the asynchronous function, rather than the parameters. This allows for better type safety and inference when working with ASync functions that have complex parameter types but a known return type.
 * It provides type safety and direct call operator overloading
 */
abstract ASyncF<Return>(ASync<Dynamic->Return>) {
    public inline function new(func:Dynamic->Return) {
        this = new ASync<Dynamic->Return>(func);
    }

    @:op(A())
    public inline function call(...args):AResult<Return> {
        var result:AResult<Return> = this.call(...args);
        // Cast the dynamic result to the expected Return type
        return cast result;
    }

    public inline function callWith(args:OneOrMany<Dynamic>):AResult<Return> {
        var result:AResult<Return> = this.callWith(args);
        return cast result;
    }

    @:from public static inline function fromFunction<Return>(func:Dynamic->Return):ASyncF<Return> {
        return new ASyncF<Return>(func);
    }

    public var isAsync(get, never):Bool;
    private inline function get_isAsync():Bool {
        return this.isAsync;
    }

    public var originalFunction(get, never):Dynamic;
    private inline function get_originalFunction():Dynamic {
        return this.originalFunction;
    }

    public inline function toString():String {
        return this.toString();
    }
}

/**
 * ASync wraps any function and makes it asynchronous
 * Can be called directly using operator overloading and will run in a thread, returning an AResult
 */
abstract ASync<TFunc:haxe.Constraints.Function>(ASyncData) {

    public inline function new(func:TFunc) {
        this = {
            func: func,
            isAsync: true
        };
    }

    /**
     * Create from any function
     */
    @:from public static inline function fromFunction<TFunc:haxe.Constraints.Function>(func:TFunc):ASync<TFunc> {
        return new ASync<TFunc>(func);
    }

    /**
     * Function call operator overloading - captures all arguments dynamically
     * Uses rest parameters to handle any number of arguments
     */
    @:op(A())
    public inline function call(...args):AResult<Dynamic> {
        // Convert rest args to array
        var argsArray:Array<Dynamic> = [];
        for (i in 0...args.length) {
            argsArray.push(args[i]);
        }
        return callWith(argsArray);
    }

    @:op(A())
    public inline function callWithCallbacks(onError:OneOrMany<Dynamic -> Dynamic>, onSuccess:OneOrMany<Dynamic -> Dynamic>, ...args):AResult<Dynamic> {
        var result = call(...args);
        result.onReady(function(value) {
            var finalValue:Dynamic = value;
            for (callback in onSuccess) {
              if (callback == null) continue;
                finalValue = callback(finalValue);
            }
            return finalValue;
        });
        result.onError(function(error) {
            var finalError:Dynamic = error;
            for (callback in onError) {
              if (callback == null) continue;
                finalError = callback(finalError);
            }
            return finalError;
        });
        return result;
    }



    /**
     * Alternative direct call method
     */
    public inline function callWith(args:OneOrMany<Dynamic>):AResult<Dynamic> {
        var result = new AResult<Dynamic>();
        var func = this.func;

        if (func == null) {
            result._setError("Invalid function");
            return result;
        }

        var queue = ThreadQueue.create(1, false);

        queue.add(function() {
            try {
                var returnValue = Reflect.callMethod(null, func, args);
                result._setResult(returnValue);
            } catch (e:Dynamic) {
                result._setError(e);
            }
        });

        return result;
    }

    /**
     * Check if this is an async function wrapper
     */
    public var isAsync(get, never):Bool;
    private inline function get_isAsync():Bool {
        return this.isAsync;
    }

    /**
     * Get the original function
     */
    public var originalFunction(get, never):Dynamic;
    private inline function get_originalFunction():Dynamic {
        return this.func;
    }

    public inline function toString():String {
        var funcName = "unknown";
        if (this.func != null) {
            funcName = Reflect.isFunction(this.func) ? "function" : Std.string(Type.typeof(this.func));
        }
        return "ASync<" + funcName + ">";
    }
}

/**
 * Helper class for creating ASync functions with proper type safety and utilities
 */
class ASyncHelper {

    /**
     * Create async version of function with no parameters
     */
    public static inline function async0<TReturn>(func:Void -> TReturn):ASync<Void -> TReturn> {
        return func;
    }

    /**
     * Create async version of function with 1 parameter
     */
    public static inline function async1<T1, TReturn>(func:T1 -> TReturn):ASync<T1 -> TReturn> {
        return func;
    }

    /**
     * Create async version of function with 2 parameters
     */
    public static inline function async2<T1, T2, TReturn>(func:T1 -> T2 -> TReturn):ASync<T1 -> T2 -> TReturn> {
        return func;
    }

    /**
     * Create async version of function with 3 parameters
     */
    public static inline function async3<T1, T2, T3, TReturn>(func:T1 -> T2 -> T3 -> TReturn):ASync<T1 -> T2 -> T3 -> TReturn> {
        return func;
    }

    /**
     * Create async version of function with 4 parameters
     */
    public static inline function async4<T1, T2, T3, T4, TReturn>(func:T1 -> T2 -> T3 -> T4 -> TReturn):ASync<T1 -> T2 -> T3 -> T4 -> TReturn> {
        return func;
    }

    /**
     * Create async version of function with 5 parameters
     */
    public static inline function async5<T1, T2, T3, T4, T5, TReturn>(func:T1 -> T2 -> T3 -> T4 -> T5 -> TReturn):ASync<T1 -> T2 -> T3 -> T4 -> T5 -> TReturn> {
        return func;
    }

    public static inline function asyncAny<TReturn>(func:haxe.Constraints.Function):ASync<haxe.Constraints.Function> {
        return func;
    }

    /**
     * Run multiple async operations in parallel and wait for all to complete
     * Takes ASync functions, calls them, and waits for all results
     */
    public static inline function all<T>(asyncFunctions:Array<ASync<Void -> T>>):AResult<Array<T>> {
        var finalResult = new AResult<Array<T>>();

        var queue = ThreadQueue.create(1, false);
        queue.add(function() {
            // Start all async operations
            var results:Array<AResult<Dynamic>> = [];
            for (asyncFunc in asyncFunctions) {
                results.push(asyncFunc());
            }

            // Wait for all to complete
            var values = new Array<T>();
            var hasError = false;
            var errorValue:Dynamic = null;

            for (result in results) {
                try {
                    values.push(result.get());
                } catch (e:Dynamic) {
                    hasError = true;
                    errorValue = e;
                    break;
                }
            }

            if (hasError) {
                finalResult._setError(errorValue);
            } else {
                finalResult._setResult(values);
            }
        });

        return finalResult;
    }

    /**
     * Alternative all function that takes already-started results (legacy compatibility)
     */
    public static inline function allResults<T>(results:Array<AResult<T>>):AResult<Array<T>> {
        var finalResult = new AResult<Array<T>>();

        var queue = ThreadQueue.create(1, false);
        queue.add(function() {
            var values = new Array<T>();
            var hasError = false;
            var errorValue:Dynamic = null;

            for (result in results) {
                try {
                    values.push(result.get());
                } catch (e:Dynamic) {
                    hasError = true;
                    errorValue = e;
                    break;
                }
            }

            if (hasError) {
                finalResult._setError(errorValue);
            } else {
                finalResult._setResult(values);
            }
        });

        return finalResult;
    }

    /**
     * Run multiple async operations and return the first one that completes
     * Takes ASync functions, calls them, and returns the first result
     */
    public static inline function race<T>(asyncFunctions:Array<ASync<Void -> T>>):AResult<T> {
        var finalResult = new AResult<T>();
        var completed = false;

        // Start all async operations
        var results:Array<AResult<Dynamic>> = [];
        for (asyncFunc in asyncFunctions) {
            results.push(asyncFunc());
        }

        // Set up callbacks for the first to complete
        for (result in results) {
            result.onReady(function(value) {
                if (!completed) {
                    completed = true;
                    finalResult._setResult(value);
                }
            });

            result.onError(function(error) {
                if (!completed) {
                    completed = true;
                    finalResult._setError(error);
                }
            });
        }

        return finalResult;
    }

    /**
     * Alternative race function that takes already-started results (legacy compatibility)
     */
    public static inline function raceResults<T>(results:Array<AResult<T>>):AResult<T> {
        var finalResult = new AResult<T>();
        var completed = false;

        for (result in results) {
            result.onReady(function(value) {
                if (!completed) {
                    completed = true;
                    finalResult._setResult(value);
                }
            });

            result.onError(function(error) {
                if (!completed) {
                    completed = true;
                    finalResult._setError(error);
                }
            });
        }

        return finalResult;
    }

    /**
     * Create a delay that resolves after specified seconds
     */
    public static function delay(seconds:Float):Float {
        var result = new AResult<Float>();

        Timer.delay(function() {
            result._setResult(seconds);
        }, Math.round(seconds * 1000));

        return result;
    }
}
