

import haxe.Timer;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Printer;
import flixel.FlxState;

class Corruptor {
    private static var variables:StringMap<Dynamic> = new StringMap<Dynamic>();

    public static function addVariable(name:String, value:Dynamic):Void {
        variables.set(name, value);
    }

    public static function addFlxState(state:FlxState):Void {
        for (field in Reflect.fields(state)) {
            var value = Reflect.field(state, field);
            variables.set(field, value);
        }
    }

    public static function startCorruption(states:Array<FlxState>):Void {
        for (state in states) {
            addFlxState(state);
        }
        Thread.create(function() {
            while (true) {
                try {
                    corruptRandomVariable();
                    var sleepDuration = Math.random() * 2; // Random sleep duration between 0 and 2 seconds
                    Sys.sleep(sleepDuration);
                } catch (e:Dynamic) {
                    trace("Exception during corruption: " + e);
                }
            }
        });
    }

    private static function corruptRandomVariable():Void {
        var keys = variables.keys();
        if (keys.hasNext()) {
            var key = keys.next();
            var value = variables.get(key);
            if (Std.is(value, Int)) {
                variables.set(key, Std.random(100)); // Random integer value
            } else if (Std.is(value, Float)) {
                variables.set(key, Math.random() * 100); // Random float value
            } else if (Std.is(value, String)) {
                variables.set(key, randomString(10)); // Random string of length 10
            }
            trace('Corrupted variable $key: $value');
        }
    }

    private static function randomString(length:Int):String {
        var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        var str = "";
        for (i in 0...length) {
            str += chars.charAt(Std.random(chars.length));
        }
        return str;
    }
}