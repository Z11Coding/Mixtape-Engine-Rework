package yutautil;

/**
 * OneOrMore is an alias for OneOrMany<T> where T is the type of the items.
 * It allows a variable to take either a single item of type T or an array of items of type T.
 * This is useful for functions that can accept either a single item or multiple items of the same type.
 */
typedef OneOrMore<T> = OneOrMany<T>;

/**
 * FlexibleNum is an abstract type that can represent either an Int or a Float.
 * It provides methods to convert between these types and to create instances from them.
 * This is useful for cases where you want to handle both Int and Float values uniformly.
 */
abstract FlexibleNum(Float) from Int from Float to Float {
    public inline function new(value:Float) {
        this = value;
    }

    @:to
    public inline function toFloat():Float {
        return this;
    }

    @:to
    public inline function toInt():Int {
        return Std.int(this);
    }

    @:from
    public static inline function fromInt(value:Int):FlexibleNum {
        return new FlexibleNum(value);
    }

    @:from
    public static inline function fromFloat(value:Float):FlexibleNum {
        return new FlexibleNum(value);
    }
}

/**
* Suggestion is a wrapper which allows for suggesting a type for a Dynamic value.
* It is used to provide type hints for Dynamic values, allowing them to be treated as a specific type.
 */
abstract Suggestion<T> (Dynamic) from Dynamic to Dynamic {
    public function new(value:Dynamic) {
        this = value;
    }
}

private enum BasicTypesValue {
    TInt(v:Int);
    TFloat(v:Float);
    TString(v:String);
    TBool(v:Bool);
}

/**
 * BasicTypes is an abstract type that can hold a value of Int, Float, String, or Bool.
 * It provides methods to convert between these types and to create instances from them.
 */
abstract BasicTypes(BasicTypesValue) {
    public function new(value:Dynamic) {
        if (value == null) {
            throw 'BasicTypes cannot be constructed with null value';
        }
        if (Std.isOfType(value, Int)) {
            this = TInt(value);
        } else if (Std.isOfType(value, Float)) {
            this = TFloat(value);
        } else if (Std.isOfType(value, String)) {
            this = TString(value);
        } else if (Std.isOfType(value, Bool)) {
            this = TBool(value);
        } else {
            throw 'BasicTypes can only be constructed with Int, Float, String, or Bool';
        }
    }

    @:from
    public static inline function fromInt(value:Int):BasicTypes {
        return new BasicTypes(value);
    }

    @:from
    public static inline function fromFloat(value:Float):BasicTypes {
        return new BasicTypes(value);
    }

    @:from
    public static inline function fromString(value:String):BasicTypes {
        return new BasicTypes(value);
    }

    @:from
    public static inline function fromBool(value:Bool):BasicTypes {
        return new BasicTypes(value);
    }

    @:to
    public inline function toInt():Int {
        return switch (this) {
            case TInt(v): v;
            case TFloat(v): Std.int(v);
            case TString(v): Std.parseInt(v);
            case TBool(v): v ? 1 : 0;
        }
    }
    @:to
    public inline function toFloat():Float {
        return switch (this) {
            case TInt(v): v;
            case TFloat(v): v;
            case TString(v): Std.parseFloat(v);
            case TBool(v): v ? 1.0 : 0.0;
        }
    }
    @:to
    public inline function toString():String {
        return switch (this) {
            case TInt(v): Std.string(v);
            case TFloat(v): Std.string(v);
            case TString(v): v;
            case TBool(v): Std.string(v);
        }
    }
    @:to
    public inline function toBool():Bool {
        return switch (this) {
            case TInt(v): v != 0;
            case TFloat(v): v != 0.0;
            case TString(v): v != "" && v != "0" && v != "false";
            case TBool(v): v;
        }
    }
}

/* * SuggestionArray is an alias for SuggestionArray<T> where T is the type of
 * the suggestions. It allows for a more concise syntax when working with
 * arrays of suggestions.
 */
typedef ArraySuggestion<T> = SuggestionArray<T>;

/*
 * SuggestionArray is an abstract type that wraps an Array<Suggestion<T>>.
 * It provides methods to convert from/to Array<Suggestion<T>> and to handle
 * single or multiple suggestions.
 */
abstract SuggestionArray<T>(Array<Suggestion<T>>) to Array<Suggestion<T>> {
    public function new(value:Array<Suggestion<T>>) {
        this = value;
    }

    @:from
    public static inline function fromArray<T>(arr:Array<T>):SuggestionArray<T> {
        return cast arr;
    }

    @:to
    public inline function toArray():Array<Suggestion<T>> {
        return this;
    }
}

/**
 * OneOrMany is an abstract type that can represent either a single value or an array of values.
 * It provides methods to convert between a single value and an array, and to check if it contains
 * a single value or multiple values.
 * It is useful for cases where you want to handle both single and multiple items uniformly, especially in functions
 * that can accept either a single item or an array of items.
 */
abstract OneOrMany<T>(Array<T>) to Array<T> {
    // Construct from a single value
    public function new(value:T) {
        if (value is Array) {
            // If value is already an array, just cast it
            this = cast value;
        } else {
            // Otherwise, create a new array with the single value
            this = [value];
        }
    }

    // Construct from an array
    @:from
    public static inline function asMore<T>(arr:Array<T>):OneOrMany<T> {
        return cast arr;
    }

    // Construct from a single value (implicit)
    @:from
    public static inline function actAsArray<T>(value:T):OneOrMany<T> {
        return new OneOrMany(value);
    }

    // Convert to array
    @:to
    public inline function toArray():Array<T> {
        return this;
    }

    // Get as single value (first element)
    public inline function getSingle():T {
        return this[0];
    }

    @:to
    public inline function toSingle():T {
        if (this.length != 1) {
            throw 'Cannot convert OneOrMany to single value, length is ' + this.length;
        }
        return this[0];
    }

    // Check if it's a single value
    public inline function isSingle():Bool {
        return this.length == 1;
    }

    // Iterator support
    public inline function iterator() {
        return this.iterator();
    }
}