

import haxe.Timer;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Printer;
import flixel.FlxState;

class Corruptor {
    private static var variables:StringMap<HaxePointer<Dynamic>> = new StringMap<HaxePointer<Dynamic>>();

    public static var isEnabled(get, set):Bool;
    private static var _isEnabled:Bool = false;

    private static function get_isEnabled():Bool {
        return _isEnabled;
    }

    private static function set_isEnabled(value:Bool):Void {
        _isEnabled = value;
    }

    public static function addVariable(name:String, value:HaxePointer<Dynamic>):Void {
        variables.set(name, value);
    }

    public static function addFlxState(state:FlxState):Void {
        var stateClass = Type.getClass(state);
        for (field in Reflect.fields(state).concat(Type.getInstanceFields(stateClass))) {
            var value = Reflect.getProperty(state, field);
            variables.set(field, value);
        }
    }

    public static function startCorruption(states:Array<FlxState>):Void {
        for (state in states) {
            addFlxState(state);
        }
        sys.thread.Thread.create(function() {
            trace("Corruption thread started.");
            isEnabled = true;
            while (isEnabled) {
                try {
                    corruptRandomVariable(); 
                    var sleepDuration = Math.random() * 20; // Random sleep duration between 0 and 20 seconds
                    Sys.sleep(sleepDuration);
                } catch (e:Dynamic) {
                    trace("Exception during corruption: " + e);
                    for (v in variables) {
                        if (v(Direct) == null) {
                            trace("Variable is null, removing it.");
                            variables.remove(v);
                        }
                    }
                }
            }
        });
    }


    private static function corruptRandomVariable():Void {
        var keys = variables.keys();
        if (!keys.hasNext()) return;
        var key = keys.next();
        var value = variables.get(key);

        if (value == null) return;

        if (Std.is(value, Array)) {
            corruptArray(cast value);
        } else if (Std.is(value, String)) {
            variables.set(key, corruptString(cast value));
        } else if (Std.is(value, Int)) {
            variables.set(key, corruptInt(cast value));
        } else if (Std.is(value, Float)) {
            variables.set(key, corruptFloat(cast value));
        } else if (Std.is(value, Bool)) {
            variables.set(key, corruptBool(cast value));
        } else if (isMap(value)) {
            corruptMap(cast value);
        }

        trace('Corrupted variable $key: $value');
    }

    private static function corruptInt(v:Int):Int {
        return Std.random(100);
    }

    private static function corruptFloat(v:Float):Float {
        return Math.random() * 100;
    }

    private static function corruptString(v:String):String {
        return randomString(v.length);
    }

    private static function corruptBool(v:Bool):Bool {
        return Std.random(2) == 0;
    }

    private static function corruptArray(arr:Array<Dynamic>):Void {
        for (i in 0...arr.length) {
            var v = arr[i];
            if (Std.is(v, Int)) arr[i] = corruptInt(v);
            else if (Std.is(v, Float)) arr[i] = corruptFloat(v);
            else if (Std.is(v, String)) arr[i] = corruptString(v);
            else if (Std.is(v, Bool)) arr[i] = corruptBool(v);
            else if (Std.is(v, Array)) corruptArray(cast v);
            else if (isMap(v)) corruptMap(cast v);
        }
    }

    private static function corruptMap(map:Dynamic):Void {
        for (k in Reflect.fields(map)) {
            var v = Reflect.field(map, k);
            if (Std.is(v, Int)) Reflect.setField(map, k, corruptInt(v));
            else if (Std.is(v, Float)) Reflect.setField(map, k, corruptFloat(v));
            else if (Std.is(v, String)) Reflect.setField(map, k, corruptString(v));
            else if (Std.is(v, Bool)) Reflect.setField(map, k, corruptBool(v));
            else if (Std.is(v, Array)) corruptArray(cast v);
            else if (isMap(v)) corruptMap(cast v);
        }
    }

    private static function isMap(v:Dynamic):Bool {
        // Checks for anonymous objects (maps)
        return v.isMap();
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