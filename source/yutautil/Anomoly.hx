package yutautil;

import flixel.FlxG;
import flixel.FlxState;
import haxe.Timer;
import haxe.rtti.Meta;
import haxe.rtti.CType;
// import haxe.rtti.TypeInfo;

class Anomoly {
    private var timer:Timer;
    private var isActive:Bool = false;

    public function new() {}

    public function activate():Void {
        if (!isActive) {
            isActive = true;
            timer = new Timer(1000); // Change every second
            timer.run = function() {
                randomize();
            };
    }
    }

    public function deactivate():Void {
        if (isActive) {
            isActive = false;
            timer.stop();
        }
    }

    public function randomize(traceOutput:Bool = false):Void {
        var currentState:FlxState = FlxG.state;
        randomizeFields(currentState, traceOutput);
    }

    public function randomizeFields(obj:Dynamic, traceOutput:Bool = false):Void {
        var fields = Reflect.fields(obj);
        for (field in fields) {
            var value = Reflect.field(obj, field);
            if (Std.is(value, Int)) {
                var randomInt = Math.random() * 100;
                Reflect.setField(obj, field, randomInt);
                if (traceOutput) {
                    trace("Randomized " + field + " to " + randomInt);
                }
            } else if (Std.is(value, Float)) {
                var randomFloat = Math.random();
                Reflect.setField(obj, field, randomFloat);
                if (traceOutput) {
                    trace("Randomized " + field + " to " + randomFloat);
                }
            } else if (Std.is(value, Bool)) {
                var randomBool = Math.random() > 0.5;
                Reflect.setField(obj, field, randomBool);
                if (traceOutput) {
                    trace("Randomized " + field + " to " + randomBool);
                }
            } else if (Std.is(value, String)) {
                var randomString = randomString(5);
                Reflect.setField(obj, field, randomString);
                if (traceOutput) {
                    trace("Randomized " + field + " to " + randomString);
                }
            } else if (Std.is(value, Array)) {
                for (i in 0...value.length) {
                    randomizeFields(value[i], traceOutput);
                }
            } else if (Reflect.isObject(value)) {
                randomizeFields(value, traceOutput);
            }
        }
    }

    private function randomString(length:Int):String {
        var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        var str = "";
        for (i in 0...length) {
            str += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return str;
    }

    // public static function createRandomizedObject<T>(cls:Class<T>, modifyInternals:Bool = false):T {
    //     var typeInfo = TypeInfo.getType(cls);
    //     var constructor = typeInfo.constructor;
    //     var args = [];
        
    //     if (constructor != null) {
    //         for (param in constructor.params) {
    //             var arg = generateRandomValue(param.type);
    //             args.push(arg);
    //         }
    //     }

    //     var obj:T = Type.createInstance(cls, args);

    //     if (modifyInternals) {
    //         randomizeFields(obj);
    //     }

    //     return obj;
    // }

    // private static function generateRandomValue(type:CType):Dynamic {
    //     switch (type) {
    //         case CTPath("Int"):
    //             return Math.random() * 100;
    //         case CTPath("Float"):
    //             return Math.random();
    //         case CTPath("Bool"):
    //             return Math.random() > 0.5;
    //         case CTPath("String"):
    //             return randomString(5);
    //         case CTPath(path):
    //             // Check if the path corresponds to a class
    //             var cls = Type.resolveClass(path);
    //             if (cls != null) {
    //                 return createRandomizedObject(cls, true);
    //             }
    //             return null;
    //         default:
    //             return null;
    //     }
    // }
}
