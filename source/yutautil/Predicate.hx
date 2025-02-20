package yutautil;

typedef Predicate<T> = T -> Bool;

class PredicateUtils {
    public static function alwaysTrue<T>():Predicate<T> {
        return function(_:T):Bool {
            return true;
        };
    }

    public static function alwaysFalse<T>():Predicate<T> {
        return function(_:T):Bool {
            return false;
        };
    }

    public static function not<T>(predicate:Predicate<T>):Predicate<T> {
        return function(value:T):Bool {
            return !predicate(value);
        };
    }

    public static function and<T>(predicate1:Predicate<T>, predicate2:Predicate<T>):Predicate<T> {
        return function(value:T):Bool {
            return predicate1(value) && predicate2(value);
        };
    }

    public static function or<T>(predicate1:Predicate<T>, predicate2:Predicate<T>):Predicate<T> {
        return function(value:T):Bool {
            return predicate1(value) || predicate2(value);
        };
    }
}