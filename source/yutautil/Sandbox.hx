package yutautil;

import haxe.CallStack;

typedef ErrorType = Dynamic;
typedef MethodName = String;
typedef CatchFunction = (ErrorType, MethodName, MethodArgs) -> Void;
typedef MethodArgs = Array<Dynamic>;

/**
 * A generic class representing a sandbox environment.
 * 
 * 
 * 
 * The sandbox will create a proxy object that will call the methods of the instance
 * and catch any errors that may occur. This allows for dealing with less important objects without
 * the potential of crashing the entire application, however it will void the ability to easily use type safety.
 * @param instance The type of elements this sandbox will handle.
 * @param catchFunction A function that will be called when an error occurs. The function will receive the error, the method name and the arguments. If not provided, a default function will be used.
 * @param verboseErrors If true, the stack trace will be printed when an error occurs.
 */
class Sandbox<T> {
    private var instance:T;
    private var proxy:Dynamic;
    private var catchFunction:CatchFunction;
    private var verboseErrors:Bool;

    public function new(instance:T, ?catchFunction:CatchFunction, ?verboseErrors:Bool = false) {
        this.instance = instance;
        this.proxy = createProxy(instance);
        this.catchFunction = catchFunction != null ? catchFunction : defaultCatchFunction;
        this.verboseErrors = verboseErrors;
    }

    public function call(method:MethodName, args:MethodArgs, ?callCatch:CatchFunction):Dynamic {
        return try {
            Reflect.callMethod(instance, Reflect.field(instance, method), args);
        } catch (e:Dynamic) {
            (callCatch != null ? callCatch : catchFunction)(e, method, args);
            null;
        }
    }

    public function pcall():Dynamic {
        return proxy;
    }

    private function defaultCatchFunction(e:ErrorType, method:MethodName, args:MethodArgs):Void {
        trace('Error in sandbox for object: ' + Type.getClassName(Type.getClass(instance)));
        trace('Error in method: ' + method);
        trace('Arguments: ' + args);
        trace('Error: ' + e);
        if (verboseErrors) {
            for (stackItem in CallStack.callStack()) {
                trace('Stack item: ' + CallStack.toString([stackItem]));
            }
        } else {
            trace('Stack trace: ' + CallStack.toString(CallStack.callStack()));
        }
    }

    public function getReadOnlyInstance():T {
        return copyClass(instance);
    }

    private function copyClass<T>(c:T):T {
        var cls:Class<T> = Type.getClass(c);
        var inst:T = Type.createEmptyInstance(cls);
        var fields = Type.getInstanceFields(cls);
        for (field in fields) {
            var val:Dynamic = Reflect.field(c,field);
            if ( ! Reflect.isFunction(val) ) {
                Reflect.setField(inst,field,val);
            }
        }
        return inst;
    }

    public function unsafeCall(method:MethodName, args:MethodArgs):Dynamic {
        return Reflect.callMethod(instance, Reflect.field(instance, method), args);
    }

    public function setCatchFunction(catchFunction:CatchFunction):Void {
        this.catchFunction = catchFunction;
    }

    public function setVerboseErrors(verboseErrors:Bool):Void {
        this.verboseErrors = verboseErrors;
    }

    public function unsafeAccess():Dynamic {
        return instance;
    }

    private function createProxy(instance:T):Dynamic {
        var proxy = {};
        var fields = Type.getInstanceFields(cast instance);
        for (field in fields) {
            var value = Reflect.field(instance, field);
            if (Reflect.isFunction(value)) {
                Reflect.setField(proxy, field, function(...args) {
                    return call(field, args);
                });
            } else {
                Reflect.setField(proxy, field, value);
            }
        }
        return proxy;
    }

    // private function updateProxy(field:Dynamic, value:Dynamic):Void {
    //     Reflect.setField(proxy, field, value);
    // }
}
 