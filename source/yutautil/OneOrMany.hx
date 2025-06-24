package yutautil;

typedef OneOrMore<T> = OneOrMany<T>;

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
    public static inline function fromArray<T>(arr:Array<T>):OneOrMany<T> {
        return cast arr;
    }

    // Construct from a single value (implicit)
    @:from
    public static inline function fromSingle<T>(value:T):OneOrMany<T> {
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