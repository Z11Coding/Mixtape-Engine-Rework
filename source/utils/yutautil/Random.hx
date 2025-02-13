package utils;

import haxe.ds.Option;
import haxe.rtti.Meta;

class Union<T1, T2, T3 = Null<Dynamic>, T4 = Null<Dynamic>, T5 = Null<Dynamic>, T6 = Null<Dynamic>> {
    private var value:Dynamic;
    private var typeIndex:Int;

    public function new(value:Dynamic) {
        this.value = value;
        this.typeIndex = getTypeIndex(value);
        if (this.typeIndex == -1) {
            throw "Incompatible type";
        }
    }

    private function getTypeIndex(value:Dynamic):Int {
        if (Std.is(value, T1)) return 1;
        if (Std.is(value, T2)) return 2;
        if (Std.is(value, T3)) return 3;
        if (Std.is(value, T4)) return 4;
        if (Std.is(value, T5)) return 5;
        if (Std.is(value, T6)) return 6;
        return -1;
    }

    public function getValue():Dynamic {
        return value;
    }

    public function getType():Int {
        return typeIndex;
    }

    public static function create(value:Dynamic):Union<T1, T2, T3, T4, T5, T6> {
        return new Union<T1, T2, T3, T4, T5, T6>(value);
    }

    public static function randomize(values:Array<Dynamic>):Union<T1, T2, T3, T4, T5, T6> {
        var validValues:Array<Dynamic> = [];
        for (value in values) {
            if (Std.is(value, T1) || Std.is(value, T2) || Std.is(value, T3) || Std.is(value, T4) || Std.is(value, T5) || Std.is(value, T6)) {
                validValues.push(value);
            } else {
                trace('Warning: Incompatible type ${Type.typeof(value)}');
            }
        }
        if (validValues.length == 0) {
            throw "No compatible types found";
        }
        var randomValue = validValues[Std.random(validValues.length)];
        return new Union<T1, T2, T3, T4, T5, T6>(randomValue);
    }
}

// Example usage
class Main {
    static function main() {
        var x:Union<Int, String> = Union.create("A string");

        switch (x.getType()) {
            case 1: trace('It was an Int: ${x.getValue()}');
            case 2: trace('It was a String: ${(cast x.getValue() : String).toUpperCase()}');
            case 3: case 4: case 5: case 6: trace('It was another type');
            default: trace('It was null');
        }

        var y:Union<Int, String, Float> = Union.randomize([42, "Hello", 3.14]);
        trace('Randomized value: ${y.getValue()}');
    }
}