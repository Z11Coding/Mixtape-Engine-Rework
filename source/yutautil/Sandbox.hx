package yutautil;

import haxe.CallStack;

typedef ErrorType = Dynamic;
typedef MethodName = String;
typedef CatchFunction = (ErrorType, MethodName, MethodArgs) -> Void;
typedef MethodArgs = Array<Dynamic>;

class Sandbox<T> {
    private var instance:T;
    private var catchFunction:CatchFunction;
    private var verboseErrors:Bool;

    public function new(instance:T, ?catchFunction:CatchFunction, ?verboseErrors:Bool = false) {
        this.instance = instance;
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

    private function defaultCatchFunction(e:ErrorType, method:MethodName, args:MethodArgs):Void {
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
}
