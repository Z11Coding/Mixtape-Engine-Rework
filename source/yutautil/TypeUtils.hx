package yutautil;

/**
 * OneOrMore is an alias for OneOrMany<T> where T is the type of the items.
 * It allows a variable to take either a single item of type T or an array of items of type T.
 * This is useful for functions that can accept either a single item or multiple items of the same type.
 */
typedef OneOrMore<T> = OneOrMany<T>;

/**
 * PointerAccess is an enum that specifies how to access the pointer:
 * - Direct: returns the value of the pointer (ptr.ref)
 * - Method(name, args): calls a method on the pointer's value with the given name and arguments
 * - Raw: returns the cpp.Pointer<T> itself
 */
enum PointerAccess {
    Direct;
    PointerHandle; // Access to cpp.Pointer<T>, rather than the raw pointer.
    Method(name:String, args:OneOrMore<Dynamic>);
    Call(args:OneOrMore<Dynamic>);
    Mem; Memory; // Memory access, equivalent to a HaxeAddress.
    Raw;
}
#if cpp
class TypeTools {
    public static final ptrMap:Map<PtrAddress, GlobalPointer<Dynamic>> = new Map<PtrAddress, GlobalPointer<Dynamic>>();
    public static final runtimeClassMap:Map<String, Dynamic> = new Map<String, Dynamic>();

    /**
     * getGlobalPointer retrieves a GlobalPointer for the given PtrAddress.
     * If the pointer does not exist in the map, it creates a new GlobalPointer and adds it to the map.
     * This ensures that each PtrAddress is associated with a single GlobalPointer instance.
     */
    public static function getGlobalPointer<T>(ptr:HaxePointer<T>):Dynamic {
        trace('TypeTools.getGlobalPointer called with ptr: ' + Std.string(ptr));
        if (!ptrMap.exists(ptr)) {
            trace('Pointer not found in ptrMap, creating new GlobalPointer.');
            ptrMap.set(ptr, new GlobalPointer<T>(ptr));
        } else {
            trace('Pointer found in ptrMap, returning existing GlobalPointer.');
        }
        var result = cast ptrMap.get(ptr);
        trace('Returning GlobalPointer: ' + Std.string(result));
        return result;
    }
}
#end


/**
 * RadioBool acts like a radio button group.
 * The value is the number of buttons, and only one can be true at a time (the "pressed" one).
 * By default, the first button (index 0) is pressed (true), others are false.
 * You can set the pressed index via the constructor or setPressed().
 */
abstract RadioBool(Array<Bool>) to Array<Bool> {
    public function new(count:Int, ?pressed:Int = 0) {
        if (count <= 0) throw 'RadioBool: count must be > 0';
        var arr = [for (i in 0...count) i == pressed];
        this = arr;
    }

    @:from
    public static inline function fromCount(count:Int):RadioBool {
        return new RadioBool(count);
    }

    @:from
    public static inline function fromTuple(tuple:{count:Int, pressed:Int}):RadioBool {
        return new RadioBool(tuple.count, tuple.pressed);
    }

    @:to
    public inline function toArray():Array<Bool> {
        return this;
    }

    @:to
    public inline function toTuple():{count:Int, pressed:Int} {
        return { count: this.length, pressed: getPressed() };
    }

    @:to
    public inline function toPressed():Int {
        return getPressed();
    }

    /**
     * Returns the index of the pressed (true) button, or -1 if none.
     */
    public function getPressed():Int {
        for (i in 0...this.length)
            if (this[i]) return i;
        return -1;
    }

    /**
     * Sets which button is pressed (true), all others become false.
     */
    public inline function setPressed(idx:Int):Void {
        if (idx < 0 || idx >= this.length) throw 'RadioBool: pressed index out of bounds';
        for (i in 0...this.length)
            this[i] = (i == idx);
    }

    /**
     * Returns the number of buttons.
     */
    public inline function count():Int {
        return this.length;
    }
}

/**
 * QuantomBool is a boolean that you don't know the value of until it is observed.
 * (Schrödinger's Bool)
 */
abstract QuantomBool(Bool) from Bool to Bool {
    public inline function new(value:Null<Bool>) {
        this = value;
    }

    @:to
    public inline function toBool():Bool {
        return Std.random(2) == 0;
    }

    @:from
    public static inline function fromBool(value:Bool):QuantomBool {
        return new QuantomBool(value);
    }
}

// /**
//  * Generator<T> simulates a Python-like generator in Haxe.
//  * It takes an iterable (Array, Iterator, Iterable, or function) and yields the next value on each call to next().
//  * When exhausted, next() returns null.
//  */
// abstract Generator<T>(Dynamic) {
//     public function new(value:Dynamic) {
//         var _iterator:Iterator<T> = null;
//         var _current:T = null;
//         if (Reflect.hasField(value, "hasNext") && Reflect.hasField(value, "next")) {
//             _iterator = value;
//         } else if (Std.is(value, Array)) {
//             _iterator = (cast value:Array<T>).iterator();
//         } else if (Std.isOfType(value, Iterable)) {
//             _iterator = (cast value:Iterable<T>).iterator();
//         } else if (Std.isOfType(value, Function)) {
//             var fn = value;
//             var exhausted = false;
//             _iterator = {
//                 next: function() {
//                     if (exhausted) return null;
//                     var result = fn();
//                     if (result == null) exhausted = true;
//                     return result;
//                 },
//                 hasNext: function() return !exhausted
//             };
//         } else {
//             throw 'Generator: value must be Array, Iterator, Iterable, or Function';
//         }
//         this = {
//             _iterator: _iterator,
//             _current: _current
//         };
//     }    /**
//      * Returns the next value, or null if exhausted.
//      */
//     public function next():Null<T> {
//         var it = this._iterator;
//         if (it != null && it.hasNext()) {
//             return it.next();
//         }
//         return null;
//     }

//     /**
//      * Returns true if there are more values to generate.
//      */
//     public function hasNext():Bool {
//         var it = this._iterator;
//         return it != null && it.hasNext();
//     }

//     @:to
//     public inline function toValue():T {
//         return this.next();
//     }

//     @:from
//     public static inline function fromValue<T>(value:T):Generator<T> {
//         return new Generator(value);
//     }

//     public static inline function fromIterable<T>(iterable:Iterable<T>):Generator<T> {
//         return new Generator(iterable);
//     }

//     public static inline function fromArray<T>(arr:Array<T>):Generator<T> {
//         return new Generator(arr);
//     }

//     public static inline function fromIterator<T>(it:Iterator<T>):Generator<T> {
//         return new Generator(it);
//     }

//     public static inline function fromFunction<T>(fn:Void->T):Generator<T> {
//         return new Generator(fn);
//     }

//     /**
//      * Returns an iterator for the generator.
//      * This allows using the generator in a for loop or with other iterator functions.
//      */
//     public inline function iterator():Iterator<T> {
//         return {
//             next: function() return this.next(),
//             hasNext: function() return this.hasNext()
//         };

//         return this;
//     }


//     public static inline function yield<T>(value:T):Generator<T> {
//         return new Generator(function() return value);
//     }
// }

// abstract Truthy(Dynamic) from Dynamic to Bool {
//     public inline function new(value:Dynamic) {
//         this = value;
//     }

//     @:to
//     public inline function toBool():Bool {
//         var v = this;
//         // Python's truthy logic:
//         if (v == null) return false;
//         if (Std.isOfType(v, Bool)) return v;
//         if (Std.isOfType(v, Int)) return v != 0;
//         if (Std.isOfType(v, Float)) return v != 0.0;
//         if (Std.isOfType(v, String)) return v != "" && v != "0" && v != "false";
//         if (Std.isOfType(v, Array)) return (cast v:Array<Dynamic>).length > 0;
//         if (Reflect.isObject(v)) {
//             // Empty anonymous object is falsy, otherwise truthy
//             return Reflect.fields(v).length > 0;
//         }
//         return true;
//     }

//     @:from
//     public static inline function fromDynamic(value:Dynamic):Truthy {
//         return new Truthy(value);
//     }
// }

	// abstract Traced<T>(T)
	// {
	// 	public inline function new(value:T) {
	// 		this = value;
	// 		trace("Traced: new value = " + Std.string(value));
	// 	}

	// 	@:op(A.B)
	// 	public inline function get():T {
	// 		trace("Traced: get value = " + Std.string(this));
	// 		return this;
	// 	}

	// 	@:op(A.B)
	// 	public inline function set(value:T):T {
	// 		trace("Traced: set value = " + Std.string(value));
	// 		this = value;
	// 		return this;
	// 	}

	// 	@:to
	// 	public inline function toValue():T {
	// 		trace("Traced: toValue = " + Std.string(this));
	// 		return this;
	// 	}

	// 	@:from
	// 	public static inline function fromValue<T>(value:T):Traced<T> {
	// 		trace("Traced: fromValue = " + Std.string(value));
	// 		return new Traced<T>(value);
	// 	}

	// 	public inline function toString():String {
	// 		trace("Traced: toString = " + Std.string(this));
	// 		return Std.string(this);
	// 	}

	// 	// Overload operators for common interactions
	// 	@:op(A + B)
	// 	public inline function add(b:T):Traced<T> {
	// 		trace("Traced: add " + Std.string(this) + " + " + Std.string(b));
	// 		return new Traced<T>(cast (cast this + b));
	// 	}

	// 	@:op(A - B)
	// 	public inline function sub(b:T):Traced<T> {
	// 		trace("Traced: sub " + Std.string(this) + " - " + Std.string(b));
	// 		return new Traced<T>(cast (cast this - b));
	// 	}

	// 	@:op(A * B)
	// 	public inline function mul(b:T):Traced<T> {
	// 		trace("Traced: mul " + Std.string(this) + " * " + Std.string(b));
	// 		return new Traced<T>(cast (cast this * b));
	// 	}

	// 	@:op(A / B)
	// 	public inline function div(b:T):Traced<T> {
	// 		trace("Traced: div " + Std.string(this) + " / " + Std.string(b));
	// 		return new Traced<T>(cast (cast this / b));
	// 	}

	// 	@:op(A == B)
	// 	public inline function eq(b:T):Bool {
	// 		trace("Traced: eq " + Std.string(this) + " == " + Std.string(b));
	// 		return this == b;
	// 	}

	// 	@:op(A != B)
	// 	public inline function neq(b:T):Bool {
	// 		trace("Traced: neq " + Std.string(this) + " != " + Std.string(b));
	// 		return this != b;
	// 	}

	// 	@:op(A > B)
	// 	public inline function gt(b:T):Bool {
	// 		trace("Traced: gt " + Std.string(this) + " > " + Std.string(b));
	// 		return this > b;
	// 	}

	// 	@:op(A < B)
	// 	public inline function lt(b:T):Bool {
	// 		trace("Traced: lt " + Std.string(this) + " < " + Std.string(b));
	// 		return this < b;
	// 	}

	// 	@:op(A >= B)
	// 	public inline function gte(b:T):Bool {
	// 		trace("Traced: gte " + Std.string(this) + " >= " + Std.string(b));
	// 		return this >= b;
	// 	}

	// 	@:op(A <= B)
	// 	public inline function lte(b:T):Bool {
	// 		trace("Traced: lte " + Std.string(this) + " <= " + Std.string(b));
	// 		return this <= b;
	// 	}
	// }






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

// abstract Upgradable<T>(Dynamic) {
//     public function new(value:Dynamic) {
//         this = upgrade(value);
//     }

//     /**
//      * Checks if the stored value is of type T or a subclass.
//      */
//     public inline function isOfType():Bool {
//         return Std.isOfType(this, T);
//     }

//     /**
//      * Attempts to upgrade the value to type T if possible.
//      * If value is not of type T but is upcastable (i.e., value is a superclass of T),
//      * it tries to cast it to T. Otherwise, throws an error.
//      */
//     private static function upgrade<T>(value:Dynamic):Dynamic {
//         if (Std.isOfType(value, T)) {
//             return value;
//         }
//         // Try to upgrade: if value is a superclass of T, try to cast
//         var tCls = Type.getClass(Type.createEmptyInstance(T));
//         var vCls = Type.getClass(value);
//         // If value is a superclass of T, allow upcast
//         if (tCls != null && vCls != null) {
//             var cur = tCls;
//             while (cur != null) {
//                 if (cur == vCls) {
//                     // Upcast: create a new T from value if possible
//                     try {
//                         var inst = Type.createEmptyInstance(tCls);
//                         // Copy properties from value to inst
//                         for (field in Reflect.fields(value).concat(Type.getInstanceFields(tCls))) {
//                             Reflect.setProperty(inst, field, function() {
//                                 var v = Reflect.field(value, field);
//                                 if (v == null) v = Reflect.getProperty(value, field);
//                                 return v;
//                             }());
//                         }
//                         return inst;
//                     } catch (e) {
//                         throw 'Upgradable<T>: Cannot upgrade value to type ' + Type.getClassName(tCls) + ': ' + e;
//                     }
//                 }
//                 cur = Type.getSuperClass(cur);
//             }
//         }
//         throw 'Upgradable<T>: value is not of type ' + Type.getClassName(tCls) + ' or upgradable from ' + Type.getClassName(vCls);
//     }

//     @:to
//     public inline function toValue():T {
//         return cast this;
//     }

//     @:from
//     public static inline function fromValue<T>(value:T):Upgradable<T> {
//         return new Upgradable(value);
//     }
// }

// abstract Lazy<T>(Dynamic) {
//     public function new(value:Dynamic) {
//         if (!Std.isOfType(value, T)) {
//             // Check superclasses/interfaces
//             var found = false;
//             var cls:Dynamic = Type.getClass(value);
//             var tCls:Dynamic = Type.resolveClass(Type.getClassName(Type.getClassFromName(Type.getClassName(Type.getClass(new T())))));
//             while (cls != null) {
//                 if (cls == tCls) {
//                     found = true;
//                     break;
//                 }
//                 cls = Type.getSuperClass(cls);
//             }
//             if (!found) {
//                 throw 'Lazy<T>: value is not of type ' + Type.getClassName(tCls) + ' or its superclasses';
//             }
//         }
//         this = value;
//     }

//     @:to
//     public inline function toValue():T {
//         return cast this;
//     }

//     @:from
//     public static inline function fromValue<T>(value:T):Lazy<T> {
//         return new Lazy(value);
//     }
// }

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

    @:from
    public static inline function fromSingle<T>(value:T):OneOrMany<T> {
        return new OneOrMany(value);
    }

    @:from
    public static inline function fromArray<T>(arr:Array<T>):OneOrMany<T> {
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

    @:to
        public inline function toOneOrMany():OneOrMany<T> {
            return this;
        }

        public inline function forceArray():Array<T> {
            return this;
        }

        // Force return as single value (first element)
        public inline function toSingleForced():T {
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

private class TempIMPL<T> {
    public function new(value:T) {
        this._value = value;
    }

    public var value(get, never):T;
    private var _value:T;
    private var _isNull:Bool = false;
    private function get_value<Ref>():T {
        if (_isNull) {
            throw 'TempIMPL: value was already accessed, cannot access again.';
        }
        var v:T = _value;
        trace('TempIMPL: Accessing value: ' + Std.string(v));
        trace(("TempIMPL: Value type: " + Type.getClassName(Type.getClass(v))));
        // Try to recover the value from cpp.Pointer.fromRaw in a loop until Type.getClass(v) != null or an exception occurs
        #if cpp
        var attempts = 0;
        while (Type.getClassName(Type.getClass(v)) == null ||
               Type.getClassName(Type.getClass(v)) == "Null") {
            try {
            var ptr = cpp.Pointer.fromRaw(cast (new HaxePointer<T>(v)));
            if (ptr != null && ptr.ref != null) {
                v = ptr.ref;
                if( Std.string(v).trim() == "true".trim() && !(ptr is Bool)) {
                v = cast (ptr).ref;
                } else if (v is Bool) {
                    trace("TempIMPL: Value is a Bool, casting to HaxePointer<T>.");
                }
                trace("TempIMPL: Value recovered from cpp.Pointer.fromRaw: " + Std.string(v));
            } else {
                trace("TempIMPL: cpp.Pointer.fromRaw failed or ref is null.");
                break;
            }
            } catch (e:Dynamic) {
            trace("TempIMPL: Exception during pointer recovery: " + Std.string(e));
            break;
            }
            attempts++;
            if (attempts > 10) {
            trace("TempIMPL: Too many pointer recovery attempts, aborting.");
            var ref:Ref = cast v;
            v = cast ref;
            trace("TempIMPL: Final value: " + Std.string(v));
            break;
            }
        }
        #end
        _value = null; // Null the value after access
        _isNull = true;
        return cast (v:HaxePointer<T>);
    }
}

/**
 * Dead is an alias for Temp<T> where T is the type of the value.
 * It allows for temporary storage of a value that is intended to be discarded after use.
 * This is useful for cases where you want to ensure that a value is only accessed once and then discarded.
 */
typedef Dead<T> = Temp<T>;
/**
 * SelfDestruct is an alias for Temp<T> where T is the type of the value.
 * It allows for temporary storage of a value that is intended to be discarded after use.
 * This is useful for cases where you want to ensure that a value is only accessed once and then discarded.
 */
typedef SelfDestruct<T> = Temp<T>;

/**
 * Temp is an abstract type that allows for temporary storage of a value.
 * It provides methods to access the value, convert it to a specific type, and perform various operations.
 * After accessing the value, it nulls itself to prevent further access.
 * This is useful for cases where you want to ensure that a value is only accessed once and then discarded.
 */
abstract Temp<T>(TempIMPL<T>) {
    public inline function new(value:Dynamic) {
        this = new TempIMPL(value);
    }

    @:to
    public inline function toValue():T {
        var v:T = cast this.value;
        this = null; // Null the value after access
        return v;
    }

    @:to
    public inline function toDynamic():Dynamic {
        var v:Dynamic = cast this.value;
        this = null; // Null the value after access
        return v;
    }

    @:from
    public static inline function fromValue<T>(value:T):Temp<T> {
        return new Temp(value);
    }
    // Field access (get)
    @:op(a.b)
    public inline function opFieldAccessGet(field:String):Dynamic {
        var v = this.value;
        this = null;
        return new Fields(v)[field];
    }

    // Field access (set)
    @:op(a.b)
    public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
        var v = this.value;
        var fields:Fields = new Fields(v);
        this = null;
        fields[field] = value;
        return fields;
    }

    // Call
    @:op(a())
    public inline function opCall(args:haxe.extern.Rest<Dynamic>):Dynamic {
        var fn:Dynamic = this.value;
        this = null;
        try {
            return Reflect.callMethod(null, fn, args);
        } catch (e:Dynamic) {
            return fn;
        }
    }

    // Less than
    @:op(a < b)
    public inline function opLt(b:Dynamic):Bool {
        var v:Float = cast this.value;
        this = null;
        try {
            return untyped v < (b:Float);
        } catch (e:Dynamic) {
            return false;
        }
    }

    // Greater than
    @:op(a > b)
    public inline function opGt(b:Dynamic):Bool {
        var v:Float = cast this.value;
        this = null;
        try {
            return untyped v > (b:Float);
        } catch (e:Dynamic) {
            return false;
        }
    }

    // Less than or equal
    @:op(a <= b)
    public inline function opLte(b:Dynamic):Bool {
        var v:Float = cast this.value;
        this = null;
        try {
            return untyped v <= (b:Float);
        } catch (e:Dynamic) {
            return false;
        }
    }

    // Greater than or equal
    @:op(a >= b)
    public inline function opGte(b:Dynamic):Bool {
        var v:Float = cast this.value;
        this = null;
        try {
            return untyped v >= (b:Float);
        } catch (e:Dynamic) {
            return false;
        }
    }

    @:op(a == b)
    public inline function opEq(b:Dynamic):Bool {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v == b;
        } catch (e:Dynamic) {
            return false;
        }
    }

    @:op(a != b)
    public inline function opNeq(b:Dynamic):Bool {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v != b;
        } catch (e:Dynamic) {
            return true; // If an error occurs, consider it not equal
        }
    }

    @:op(a + b)
    public inline function opAdd(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v + b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }

    @:op(a - b)
    public inline function opSub(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v - b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a * b)
    public inline function opMul(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v * b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a / b)
    public inline function opDiv(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v / b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a % b)
    public inline function opMod(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v % b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }

    @:op(a & b)
    public inline function opAnd(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v & b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a | b)
    public inline function opOr(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v | b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a ^ b)
    public inline function opXor(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v ^ b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(~a)
    public inline function opNot():Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped ~v;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a << b)
    public inline function opShl(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v << b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a >> b)
    public inline function opShr(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v >> b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a >>> b)
    public inline function opUShr(b:Dynamic):Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v >>> b;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a++)
    public inline function opInc():Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v++;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a--)
    public inline function opDec():Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v--;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(--a)
    public inline function opPreDec():Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped --v;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(++a)
    public inline function opPreInc():Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped ++v;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }
    @:op(a)
    public inline function opRef():Dynamic {
        var v:Dynamic = this.value;
        this = null;
        try {
            return untyped v;
        } catch (e:Dynamic) {
            return null; // If an error occurs, return null
        }
    }

    @:to
    public inline function toItself():Temp<T> {
        // Return itself as a Temp<T>
        "This only happens if you try to do something like var e = this, as Haxe will try to convert it to a Temp<T>.".NativeComment();
        return cast this.value;
    }
    @:from
    public static inline function fromItself<T>(value:Temp<T>):Temp<T> {
        // Create a new Temp<T> from itself
        "This only happens if you try to do something like var e = this, as Haxe will try to convert it to a Temp<T>.".NativeComment();
        return new Temp(value);
    }

    // @:from
    // public static inline function fromDynamic(value:Dynamic):Dynamic{
    //     // Create a new Temp<Dynamic> from a Dynamic value
    //     "This only happens if you try to do something like var e = this, as Haxe will try to convert it to a Temp<Dynamic>.".NativeComment();
    //     return new Temp(value).toValue();
    // }

    // Array access (get)
    @:arrayAccess
    public inline function arrayRead(idx:Dynamic):Dynamic {
        var arr:Dynamic = this.value;
        var v = arr[idx];
        this = null;
        return v;
    }

    // Array access (set)
    @:arrayAccess
    public inline function arrayWrite(idx:Dynamic, value:Dynamic):Dynamic {
        var arr:Dynamic = this.value;
        arr[idx] = value;
        this = null;
        return value;
    }
}
#if cpp


 @:genericBuild(yutautil.TypeValidator.check())
class HXPointerCheck<T> {
    public function new(value:T) {
        // This class is used to ensure that the type T is valid for HaxePointer
        // It does not need to do anything, just exists to enforce the type constraint
    }
}

// abstract ByteString(Bytes)


typedef ExceptionDetails = {
    errorCode:String,
    message:String,
    details:String,
    stackTrace:String,
    pos:Null<haxe.PosInfos>
};

abstract DetailedException(ExceptionDetails) {
    public inline function new(value:Dynamic, ?pos:haxe.PosInfos) {
        this = DetailedException.buildDetailsObject(value, pos);
    }

    public var errorCode(get, never):String;
    inline function get_errorCode():String return this.errorCode;

    public var message(get, never):String;
    inline function get_message():String return this.message;

    public var details(get, never):String;
    inline function get_details():String return this.details;

    public var stackTrace(get, never):String;
    inline function get_stackTrace():String return this.stackTrace;

    public var pos(get, never):Null<haxe.PosInfos>;
    inline function get_pos():Null<haxe.PosInfos> return this.pos;

    @:from
    public static inline function fromString(value:String):DetailedException {
        return new DetailedException(value);
    }

    @:from
    public static inline function fromException(e:haxe.Exception):DetailedException {
        return new DetailedException(e);
    }

    @:to
    public inline function toException():haxe.Exception {
        return new haxe.Exception(this.details, this.pos);
    }

    @:to
    public inline function toString():String {
        return this.details;
    }

    @:to
    public inline function toExceptionDetails():ExceptionDetails {
        return this;
    }

    static function extractMessage(value:Dynamic):String {
        if (Std.isOfType(value, haxe.Exception)) {
            return cast(value, haxe.Exception).message;
        }
        if (Std.isOfType(value, String)) return value;

        // Extract from common error patterns
        if (value != null) {
            var str = Std.string(value);
            // Extract error type from UncaughtErrorEvent
            if (str.contains("error=")) {
                var errorMatch = ~/error="([^"]+)"/;
                if (errorMatch.match(str)) {
                    return errorMatch.matched(1);
                }
            }
            // Extract from other common patterns
            if (str.contains("Error:")) {
                var parts = str.split("Error:");
                if (parts.length > 1) {
                    return "Error:" + parts[1].split("\n")[0].trim();
                }
            }
            return str.length > 50 ? str.substr(0, 47) + "..." : str;
        }

        return "<unknown>";
    }

    static function generateErrorCode(message:String, pos:Null<haxe.PosInfos>):String {
        // Extract location info from current stack trace instead of pos parameter
        var fileName:Null<String> = null;
        var lineNumber:Null<Int> = null;
        var className:Null<String> = null;
        var methodName:Null<String> = null;

        try {
            var stack = haxe.CallStack.exceptionStack();
            if (stack != null && stack.length > 0) {
                // Look for the first stack frame that's not in TypeUtils or DetailedException
                for (frame in stack) {
                    switch (frame) {
                        case FilePos(s, file, line):
                            // Skip frames from TypeUtils and DetailedException to find the real error location
                            if (!file.contains("TypeUtils") && !file.contains("DetailedException")) {
                                fileName = file;
                                lineNumber = line;
                                break;
                            }
                        case Method(classPath, method):
                            if (!classPath.contains("TypeUtils") && !classPath.contains("DetailedException")) {
                                className = classPath;
                                methodName = method;
                                if (fileName == null) break; // We want both if possible
                            }
                        case _:
                    }
                }
            }
        } catch (e:Dynamic) {
            // Fallback to pos if stack trace fails
            if (pos != null) {
                fileName = pos.fileName;
                lineNumber = pos.lineNumber;
                className = pos.className;
                methodName = pos.methodName;
            }
        }

        var shortFileName = fileName != null ? fileName.split("/").pop().split("\\").pop() : null;

        // Abbreviate common error messages
        var shortMessage = message;
        if (message.length > 30) {
            // Common abbreviations
            shortMessage = shortMessage.replace("Null Object Reference", "NullRef");
            shortMessage = shortMessage.replace("Null Pointer Exception", "NullPtr");
            shortMessage = shortMessage.replace("Null Function Pointer", "NullFuncPtr");
            shortMessage = shortMessage.replace("UncaughtErrorEvent", "UncErr");
            shortMessage = shortMessage.replace("type=", "t=");
            shortMessage = shortMessage.replace("bubbles=true", "b=1");
            shortMessage = shortMessage.replace("cancelable=true", "c=1");
            shortMessage = shortMessage.replace("error=", "e=");

            // If still too long, truncate
            if (shortMessage.length > 20) {
                shortMessage = shortMessage.substr(0, 17) + "...";
            }
        }

        // Use very compact JSON with single-letter keys
        var data = {
            m: shortMessage,  // message
            f: shortFileName, // fileName (short)
            l: lineNumber,    // lineNumber from stack trace
            c: className,     // className from stack trace
            t: methodName     // methodName from stack trace
        };

        var jsonStr = haxe.Json.stringify(data);

        // Use the new StringCompressor for advanced compression
        // var compressedStr = yutautil.StringCompressor.compress(jsonStr);
        var bytes = haxe.io.Bytes.ofString(jsonStr);
        var hex = bytes.toHex().toUpperCase();

        // Split into groups of 4 characters for readability
        var groups = [];
        var i = 0;
        while (i < hex.length) {
            groups.push(hex.substr(i, 4));
            i += 4;
        }

        return "E" + groups.join("-");
    }

    public static function decodeErrorCode(errorCode:String):{message:String, fileName:Null<String>, lineNumber:Null<Int>, className:Null<String>, methodName:Null<String>} {
        if (!errorCode.startsWith("E")) {
            throw 'Invalid error code format: must start with "E"';
        }
        try {
            // Remove "E" prefix and dashes, then convert hex back to bytes
            var hexStr = errorCode.substring(1).split("-").join("");
            var bytes = haxe.io.Bytes.ofHex(hexStr);
            var compressedStr = bytes.toString();

            // Use StringCompressor for decompression
            // var jsonStr = yutautil.StringCompressor.decompress(compressedStr);
            var jsonStr = compressedStr;
            var data = haxe.Json.parse(jsonStr);
            return {
                message: data.m,     // message
                fileName: data.f,    // fileName
                lineNumber: data.l,  // lineNumber
                className: data.c,   // className
                methodName: data.t   // methodName
            };
        } catch (e:Dynamic) {
            throw 'Failed to decode error code: ' + Std.string(e);
        }
    }

    static function getStackTrace(?exception:Dynamic):String {
        // First, try to get the stack trace from the exception object itself
        if (exception != null) {
            if (Std.isOfType(exception, haxe.Exception)) {
                var haxeException:haxe.Exception = cast exception;
                if (haxeException.stack != null && haxeException.stack.length > 0) {
                    return haxe.CallStack.toString(haxeException.stack);
                }
            }
            // Try to get stack property from any exception object
            if (Reflect.hasField(exception, "stack")) {
                var stack = Reflect.field(exception, "stack");
                if (stack != null) {
                    if (Std.isOfType(stack, Array)) {
                        return haxe.CallStack.toString(cast stack);
                    } else if (Std.isOfType(stack, String)) {
                        return cast stack;
                    }
                }
            }
        }

        // Second, try to get the exception stack trace
        var exceptionStack = haxe.CallStack.exceptionStack();
        if (exceptionStack != null && exceptionStack.length > 0) {
            return haxe.CallStack.toString(exceptionStack);
        }

        // Finally, try the regular call stack
        try {
            var callStack = haxe.CallStack.callStack();
            if (callStack != null && callStack.length > 0) {
                return haxe.CallStack.toString(callStack);
            }
        } catch (e:Dynamic) {
            // If call stack fails, just return empty string
        }

        return "";
    }

    static function buildDetailsObject(value:Dynamic, ?pos:haxe.PosInfos):ExceptionDetails {
        var message = extractMessage(value);
        var code = generateErrorCode(message, pos);
        var stack = getStackTrace(value);
        var sb = [];
        sb.push("DetailedException:");
        sb.push("  ErrorCode: " + code);
        sb.push("  Message: " + message);
        if (pos != null) {
            sb.push('  Position: ${pos.fileName}:${pos.lineNumber} (${pos.className}.${pos.methodName})');
        }
        if (value != null && !Std.isOfType(value, String) && !Std.isOfType(value, haxe.Exception)) {
            try sb.push("  Value: " + haxe.Json.stringify(value)) catch (_:Dynamic) {};
        }
        if (stack != "") {
            sb.push("  StackTrace:\n" + stack);
        }
        return {
            errorCode: code,
            message: message,
            details: sb.join("\n"),
            stackTrace: stack,
            pos: pos
        };
    }
}

abstract HxVector<T>(haxe.ds.Vector<T>) {
    public inline function new(value:Dynamic) {
        if (value == null) throw 'HxVector cannot be constructed with null value';
        if (Std.isOfType(value, Array)) {
            var arr:Array<T> = cast value;
            var vec = new haxe.ds.Vector<T>(arr.length);
            for (i in 0...arr.length) vec[i] = arr[i];
            this = vec;
        } else {
            this = cast value;
        }
    }

    @:to
    public inline function toVector():haxe.ds.Vector<T> {
        return this;
    }

    @:to
    public inline function toArray():Array<T> {
        var arr = [];
        for (i in 0...this.length) arr.push(this[i]);
        return arr;
    }

    @:from
    public static inline function fromVector<T>(value:haxe.ds.Vector<T>):HxVector<T> {
        return new HxVector(value);
    }

    @:from
    public static inline function fromArray<T>(value:Array<T>):HxVector<T> {
        return new HxVector(value);
    }

    @:arrayAccess
    public inline function arrayRead(idx:Int):T {
        return this[idx];
    }

    @:arrayAccess
    public inline function arrayWrite(idx:Int, value:T):T {
        this[idx] = value;
        return value;
    }

    public inline function iterator():Iterator<T> {
        var i = 0;
        var len = this.length;
        return {
            hasNext: function() return i < len,
            next: function() return this[i++]
        };
    }
}

abstract ForceCasted<T>(Dynamic) {
    public inline function new(value:Dynamic) {
        this = value;
    }

    @:to
    public inline function toValue():T {
        return cast this.forceCast();
    }

    @:to
    public inline function toDynamic():Dynamic {
        return cast this.forceCast();
    }

    // field stuff
    @:op(a.b) public inline function opFieldAccessGet(field:String):Dynamic {
        trace('opFieldAccess get: ' + field);
        return new Fields(this.forceCast())[field];
    }
    @:op(a.b) public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
        trace('opFieldAccess set: ' + field + ' = ' + value);
        var fields:Fields = new Fields(this.forceCast());
        fields[field] = value;
        return value;
    }

    @:from
    public static inline function fromValue<T>(value:T):ForceCasted<T> {
        return new ForceCasted(value);
    }

    @:from
    public static inline function fromDynamic<T>(value:Dynamic):ForceCasted<T> {
        return new ForceCasted(value);
    }
}

/**
 * PtrAddress is an alias for HaxeAddress, which represents a pointer address in Haxe.
 * It provides methods to convert from/to cpp.Pointer<T> and to handle field access.
 * It is useful for cases where you want to work with pointers in Haxe, especially when interfacing with C++ code.
 */
typedef PtrAddress = HaxeAddress;

/**
 * HaxeAddress is an abstract type that represents a pointer address in Haxe.
 * It provides methods to convert from/to cpp.Pointer<T> and to handle field access.
 * It is useful for cases where you want to work with pointers in Haxe, especially when interfacing with C++ code.
 */
abstract HaxeAddress(String) {
    public inline function new(value:Dynamic) {
        if (value == null) throw 'HaxeAddress cannot be constructed with null value';
        var addrStr:String = "(unknown)";
        try {
            // Method 1: All in one go
            var allInOne = Std.string(cpp.Pointer.fromStar(cpp.Native.addressOf(cast value)));
            var re = ~/^Pointer\((.+)\)$/;
            if (re.match(allInOne)) {
                addrStr = re.matched(1);
            } else {
                // Method 2: Store pointer in variable, then stringify
                var ptr = cpp.Pointer.fromStar(cpp.Native.addressOf(cast value));
                var ptrStr = Std.string(ptr);
                if (re.match(ptrStr)) {
                    addrStr = re.matched(1);
                } else {
                    // Method 3: Store all in variables, then process
                    var nativeAddr = cpp.Native.addressOf(cast value);
                    var ptr2 = cpp.Pointer.fromStar(nativeAddr);
                    var ptr2Str = Std.string(ptr2);
                    if (re.match(ptr2Str)) {
                        addrStr = re.matched(1);
                    } else {
                        // Fallback: just use Std.string of pointer
                        addrStr = Std.string(ptr2);
                    }
                }
            }
        } catch (e:Dynamic) {
            // Fallback: just use Std.string of pointer if all else fails
            try {
                var fallbackPtr = cpp.Pointer.fromStar(cpp.Native.addressOf(cast value));
                addrStr = Std.string(fallbackPtr);
            } catch (e2:Dynamic) {
                addrStr = "(unknown)";
            }
        }
        this = addrStr;
    }

    @:from
    public static inline function fromPointer<T>(value:HaxePointer<T>):HaxeAddress {
        if (value == null) throw 'HaxeAddress cannot be constructed with null value';
        return cast value;
    }

    // @:from
    // public static inline function fromDynamic<T>(value:Dynamic):HaxeAddress {
    //     if (value == null) throw 'HaxeAddress cannot be constructed with null value';
    //     return cast value;
    // }
}

// private class AntiStackPointer<T> {
//     public var value:T;

//     public function new(ptr:HaxePointer<T>) {
//         if (ptr == null) {
//             throw 'AntiStackPointer cannot be constructed with null pointer';
//         }
//         var cppPtr = cpp.Pointer.fromRaw(ptr);
//         this.value = cppPtr.ref;
//     }
// }

/**
 * Variant is an abstract type that can hold either a value of type A or B.
 * It provides methods to check which type is stored and to access the value accordingly.
 */
// private enum HandlerOf<A, B> {
//     IsA(value:A);
//     IsB(value:B);
// }

// abstract Handler<A, B>(HandlerOf<A, B>) {
//     public function new(value:Dynamic) {
//         if (Std.isOfType(value, A)) {
//             this = IsA(value);
//         } else if (Std.isOfType(value, B)) {
//             this = IsB(value);
//         } else {
//             throw 'Variant: value must be of type A or B';
//         }
//     }

//     @:from
//     public static inline function fromA<A, B>(value:A):Variant<A, B> {
//         return new Variant<A, B>(value);
//     }

//     @:from
//     public static inline function fromB<A, B>(value:B):Variant<A, B> {
//         return new Variant<A, B>(value);
//     }

//     public inline function isA():Bool {
//         return switch (this) {
//             case IsA(_): true;
//             case _: false;
//         }
//     }

//     public inline function isB():Bool {
//         return switch (this) {
//             case IsB(_): true;
//             case _: false;
//         }
//     }

//     public inline function getA():Null<A> {
//         return switch (this) {
//             case IsA(v): v;
//             case _: null;
//         }
//     }

//     public inline function getB():Null<B> {
//         return switch (this) {
//             case IsB(v): v;
//             case _: null;
//         }
//     }

//     public inline function doSomething():Dynamic {
//         return switch (this) {
//             case IsA(v): "Handled A: " + Std.string(v);
//             case IsB(v): "Handled B: " + Std.string(v);
//         }
//     }
// }





/**
 * HaxePointer is an abstract type that wraps a cpp.RawPointer<T>.
 * It provides methods to convert from/to cpp.Pointer<T>, cpp.RawPointer<T>, and Dynamic,
 * as well as to handle field access and pointer operations.
 * This is useful for working with pointers in Haxe, especially when interfacing with C++ code.
 *
 * Note: Do not stack this type (do not wrap a HaxePointer inside another HaxePointer).
 */
abstract HaxePointer<T>(cpp.RawPointer<T>) {
    public inline function new(value:Dynamic) {
        if (value == null) {
            throw 'HaxePointer cannot be constructed with null value';
        }
        this = cpp.RawPointer.addressOf(cast (cast (value:T)));
    }

    @:to
    public inline function toPointer():cpp.Pointer<T> {
        return cpp.Pointer.fromRaw(this);
    }

    @:to
    public inline function toRawPointer():cpp.RawPointer<T> {
        return this;
    }

    @:to
    public inline function toDynamic():Dynamic {
        return cast cpp.Pointer.fromRaw(this).ref;
    }

    @:from
    public static inline function copyPointer<T>(value:HaxePointer<Dynamic>):HaxePointer<T> {
        if (value == null) {
            throw 'HaxePointer cannot be constructed with null value';
        }
        "A HaxePointer shouldn't stack, so this is to make sure it doesn't.".NativeComment();
        // Create a new HaxePointer from the existing one
        return cast value;
    }

    @:from
    public static inline function fromHXPointer<T>(value:HaxePointer<T>):HaxePointer<T> {
        if (value == null) {
            throw 'HaxePointer cannot be constructed with null value';
        }
        "A HaxePointer shouldn't stack, so this is to make sure it doesn't.".NativeComment();
        return new HaxePointer(value);
    }

    // @:arrayAccess
    // public inline function arrayRead(idx:Dynamic):Dynamic {
    //     trace('HaxePointer: arrayRead called with idx = ' + idx);
    //     var ptr:cpp.Pointer<T> = cast this;
    //     if (ptr == null) {
    //         trace('HaxePointer: arrayRead - ptr is null');
    //         throw 'HaxePointer: Cannot read from null pointer';
    //     }
    //     if (ptr.ref == null) {
    //         trace('HaxePointer: arrayRead - ptr.ref is null');
    //         throw 'HaxePointer: Cannot read from null pointer';
    //     }
    //     var result = ptr[idx];
    //     trace('HaxePointer: arrayRead - result = ' + Std.string(result));
    //     return result;
    // }

    // @:arrayAccess
    // public inline function arrayWrite(idx:Dynamic, value:Dynamic):Dynamic {
    //     trace('HaxePointer: arrayWrite called with idx = ' + idx + ', value = ' + Std.string(value));
    //     var ptr:cpp.Pointer<T> = cast this;
    //     if (ptr == null) {
    //         trace('HaxePointer: arrayWrite - ptr is null');
    //         throw 'HaxePointer: Cannot write to null pointer';
    //     }
    //     if (ptr.ref == null) {
    //         trace('HaxePointer: arrayWrite - ptr.ref is null');
    //         throw 'HaxePointer: Cannot write to null pointer';
    //     }
    //     ptr[idx] = value;
    //     trace('HaxePointer: arrayWrite - value written');
    //     return value;
    // }



    /**
     * Special pointer access function.
     * Usage:
     *   ptr.pointerAccess(PointerAccess.Direct) // returns ptr.ref
     *   ptr.pointerAccess(PointerAccess.Method("foo", [1,2])) // calls ptr.ref.foo(1,2)
     *   ptr.pointerAccess(PointerAccess.Raw) // returns cpp.Pointer<T>
     */
    @:op(a())
    public inline function pointerAccess(access:PointerAccess):Dynamic {
        var ptr:cpp.Pointer<T> = cast this;
        if (ptr == null) {
            trace('HaxePointer: pointerAccess - ptr is null');
            throw 'HaxePointer: Cannot access null pointer';
        }
        switch (access) {
            case Direct:
                if (ptr.ref == null) {
                    trace('HaxePointer: pointerAccess - ptr.ref is null');
                    throw 'HaxePointer: Cannot access null pointer value';
                }
                return ptr.ref;
            case Method(name, args):
                if (ptr.ref == null) {
                    trace('HaxePointer: pointerAccess - ptr.ref is null');
                    throw 'HaxePointer: Cannot call method on null pointer value';
                }
                var fn = Reflect.getProperty(ptr.ref, name);
                if (fn == null) {
                    trace('HaxePointer: pointerAccess - method ' + name + ' not found');
                    throw 'HaxePointer: Method not found: ' + name;
                }
                try {
                    return Reflect.callMethod(ptr.ref, fn, args);
                } catch (e:Dynamic) {
                    trace('HaxePointer: pointerAccess - exception occurred: ' + Std.string(e));
                    return null;
                }
            case Call(args):
                if (ptr.ref == null) {
                    trace('HaxePointer: pointerAccess - ptr.ref is null');
                    throw 'HaxePointer: Cannot call method on null pointer value';
                }
                var fn = ptr.ref;
                if (!Reflect.isFunction(fn)) {
                    trace('HaxePointer: pointerAccess - value is not a function');
                    throw 'HaxePointer: Value is not a function';
                }
                try {
                    return Reflect.callMethod(null, cast fn, args);
                } catch (e:Dynamic) {
                    trace('HaxePointer: pointerAccess - exception occurred: ' + Std.string(e));
                    return null;
                }
            case Raw:
                return ptr;
            case Mem | Memory:
                if (ptr.ref == null) {
                    trace('HaxePointer: pointerAccess - ptr.ref is null');
                    throw 'HaxePointer: Cannot access memory of null pointer value';
                }
                // Return a new HaxePointer wrapping the raw pointer
                return new HaxeAddress((ptr));
            case PointerHandle:
                return ptr; // Return the pointer itself
        }
    }

    @:from
    public static inline function fromPointer<T>(value:cpp.Pointer<T>):HaxePointer<T> {
        return new HaxePointer(value);
    }

    @:from
    public static inline function fromRawPointer<T>(value:cpp.RawPointer<T>):HaxePointer<T> {
        return new HaxePointer(value);
    }

    @:from
    public static inline function fromDynamic<T>(value:Dynamic):HaxePointer<T> {
        return new HaxePointer(value);
    }
    @:to
    public inline function toNativeString():String
        return Std.string(cpp.Pointer.fromRaw(this).ref) + " @ " + new PtrAddress(cpp.Pointer.fromRaw(this).ref);

    @:to
    public inline function toAddress():PtrAddress {
        return new PtrAddress(cpp.Pointer.fromRaw(this).ref);
    }

    @:to
    public inline function toStar():cpp.Star<T> {
        return cpp.Native.addressOf(cast cpp.Pointer.fromRaw(this).ref);
    }

    @:op(a.b) public inline function opFieldAccessGet(field:String):Dynamic {
        trace('opFieldAccess get: ' + field);
        return new Fields(cpp.Pointer.fromRaw(this).ref)[field];
    }

    @:op(a.b) public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
        trace('opFieldAccess set: ' + field + ' = ' + value);
        var fields:Fields = new Fields(cpp.Pointer.fromRaw(this).ref);
        fields[field] = value;
        return value;
    }
}

abstract Assertion(() -> Bool) {
    public inline function new(value:() -> Bool) {
        if (value == null) {
            throw 'Assertion cannot be constructed with null value';
        }
        this = value;
    }

    @:to
    public inline function toValue():Dynamic -> Bool {
        return cast this;
    }

    @:from
    public static inline function fromLambda(value:() -> Bool):Assertion {
        return new Assertion(value);
    }

    @:to
    public inline function toDynamic():Dynamic {
        return cast this;
    }

    // @:from
    // public static inline function fromBool(value:Bool):Assertion {
    //     return new Assertion(function():Bool {
    //         return cast cpp.Pointer.fromRaw(new HaxePointer<Bool>(value)).ref;
    //     });
    // }

    @:op(a())
    public inline function opCall():Bool {
        return cast this();
    }
}

/**
 * ResultData is a private enum used internally by the Result abstract type.
 * It has two constructors: Ok(value:T) for successful results and Err(error:E) for errors.
 */
private enum ResultData<T, E> {
    Ok(value:T);
    Err(error:E);
}

/**
 * Result<T, E> is an abstract type representing either a successful result of type T or an error of type E.
 * It can be implicitly cast to T, but will throw an error if the Result is an error.
 */
abstract Result<T, E>(ResultData<T, E>) {
    public inline function new(value:ResultData<T, E>) {
        this = value;
    }

    public static inline function ok<T, E>(value:T):Result<T, E> {
        return new Result(Ok(value));
    }

    public static inline function err<T, E>(error:E):Result<T, E> {
        return new Result(Err(error));
    }

    @:from
    public static inline function fromReturn<T, E>(v:T):Result<T, E> {
        return ok(v);
    }

    @:from
    public static inline function fromThrow<T, E>(e:E):Result<T, E> {
        return err(e);
    }

    @:from
    public static inline function fromOk<T, E>(value:T):Result<T, E> {
        return ok(value);
    }

    @:from
    public static inline function fromErr<T, E>(error:E):Result<T, E> {
        return err(error);
    }

    @:to
    public inline function toValue():T {
        return switch (this) {
            case Ok(v): v;
            case Err(e): throw 'Result: Attempted to access value, but was error: ' + Std.string(e);
        }
    }

    public inline function isOk():Bool {
        return switch (this) {
            case Ok(_): true;
            case Err(_): false;
        }
    }

    public inline function isErr():Bool {
        return !isOk();
    }

    public inline function unwrap():T {
        return cast this;
    }

    public inline function unwrapErr():E {
        return switch (this) {
            case Ok(_): throw 'Result: Attempted to access error, but was Ok';
            case Err(e): e;
        }
    }

    public inline function map<U>(f:T->U):Result<U, E> {
        return switch (this) {
            case Ok(v): Result.ok(f(v));
            case Err(e): Result.err(e);
        }
    }

    public inline function mapErr<F>(f:E->F):Result<T, F> {
        return switch (this) {
            case Ok(v): Result.ok(v);
            case Err(e): Result.err(f(e));
        }
    }
}

abstract Immutable<T>(Dynamic) {
    public inline function new(value:Dynamic) {
        if (value == null) {
            throw 'Immutable cannot be constructed with null value';
        }
        this = value;
    }

    @:to
    public inline function toValue():T {
        return cast this;
    }

    @:from
    public static inline function fromValue<T>(value:T):Immutable<T> {
        return new Immutable(value);
    }

    @:to
    public inline function toDynamic():Dynamic {
        return cast this;
    }

    // Allow field read, but not write
    @:op(a.b) public inline function opFieldAccessGet(field:String):Dynamic {
        return Reflect.field(this, field);
    }

    @:op(a.b) public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
        throw 'Immutable: Cannot write to field "' + field + '"';
    }

    // Prevent array write, allow array read
    @:arrayAccess
    public inline function arrayRead(idx:Dynamic):Dynamic {
        return this[idx];
    }

    @:arrayAccess
    public inline function arrayWrite(idx:Dynamic, value:Dynamic):Dynamic {
        throw 'Immutable: Cannot write to array index ' + idx;
    }
}
#if cpp
// abstract Mutable<T>(cpp.Pointer<T>) {
//     public inline function new(value:Dynamic) {
//         if (value == null) {
//             throw 'Mutable cannot be constructed with null value';
//         }
//         // If value is already a cpp.Pointer, use it; otherwise, create a new pointer
//         if (Std.isOfType(value, cpp.Pointer)) {
//             this = value;
//         } else {
//             this = cpp.Pointer.fromRaw(cpp.RawPointer.addressOf(cast value));
//         }
//     }

//     @:to
//     public inline function toValue():T {
//         return (cast this : cpp.Pointer<T>).ref;
//     }

//     @:from
//     public static inline function fromValue<T>(value:T):Mutable<T> {
//         return new Mutable(value);
//     }

//     @:to
//     public inline function toDynamic():Dynamic {
//         return (cast this : cpp.Pointer<T>).ref;
//     }

//     // Allow field read and write on the referenced value
//     @:op(a.b) public inline function opFieldAccessGet(field:String):Dynamic {
//         return Reflect.field((cast this : cpp.Pointer<T>).ref, field);
//     }

//     @:op(a.b) public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
//         Reflect.setField((cast this : cpp.Pointer<T>).ref, field, value);
//         return value;
//     }

//     // Allow array read and write on the referenced value
//     @:arrayAccess
//     public inline function arrayRead(idx:Dynamic):Dynamic {
//         return (cast this : cpp.Pointer<T>).ref[idx];
//     }

//     @:arrayAccess
//     public inline function arrayWrite(idx:Dynamic, value:Dynamic):Dynamic {
//         (cast this : cpp.Pointer<T>).ref[idx] = value;
//         return value;
//     }
// }
#end

/**
 * GlobalPointer is an abstract type that wraps a HaxePointer<T> and provides methods to convert between
 * GlobalPointer and HaxePointer, as well as to/from Dynamic.
 * It is useful for cases where you want to work with global pointers in Haxe, especially when interfacing with C++ code.
 */

abstract GlobalPointer<T>(HaxePointer<T>) {
    public inline function new(value:Dynamic) {
        if (value == null) {
            throw 'GlobalPointer cannot be constructed with null value';
        }
        this = value;
        TypeTools.ptrMap.set(this, this);
    }

    @:to
    public inline function toGlobalPointer():GlobalPointer<T> {
        return cast this;
    }

    @:from
    public static inline function fromGlobalPointer<T>(value:GlobalPointer<T>):GlobalPointer<T> {
        return new GlobalPointer(value);
    }

    @:from
    public static inline function fromDynamic<T>(value:Dynamic):GlobalPointer<T> {
        if (value == null) {
            throw 'GlobalPointer cannot be constructed with null value';
        }
        return new GlobalPointer(value);
    }

    @:to
    public inline function toDynamic():Dynamic {
        return cast cpp.Pointer.fromRaw(this).ref;
    }

    @:to
    public inline function toHXPointer():HaxePointer<T> {
        return cast this;
    }

    @:from
    public static inline function fromHXPointer<T>(value:HaxePointer<T>):GlobalPointer<T
> {
        if (value == null) {
            throw 'GlobalPointer cannot be constructed with null value';
        }
        return cast value;
    }

}

class PointerString {}

abstract Corrupted<T>(Dynamic) {
    public inline function new(value:Dynamic) {
        if (value == null) {
            throw 'Corrupted cannot be constructed with null value';
        }
        this = corruptValue(value);
    }

    @:to
    public inline function toValue():T {
        return cast this;
    }

    @:from
    public static inline function fromValue<T>(value:T):Corrupted<T> {
        return new Corrupted(value);
    }

    static function corruptValue(value:Dynamic):Dynamic {
        try {
            if (Std.isOfType(value, String)) {
                return corruptString(value);
            } else if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
                return corruptNumber(value);
            } else if (Std.isOfType(value, Bool)) {
                return corruptBool(value);
            } else if (Std.isOfType(value, Array)) {
                return corruptArray(value);
            } else if (Reflect.isObject(value) && Type.getClass(value) != null) {
                return corruptObject(value);
            } else if (Reflect.isObject(value)) {
                return corruptAnon(value);
            }
        } catch (e:Dynamic) {
            trace("Corrupted: Exception during corruption: " + Std.string(e));
        }
        // Fallback: just wrap in a string with weird chars
        return "¤" + Std.string(value) + "§";
    }

    static function corruptString(str:String):String {
        var weirds = ["¤", "§", "¿", "¡", "ø", "ß", "µ", "þ", "ƒ", "∑", "Ω", "≈", "ç", "√", "∫"];
        var arr = str.split("");
        for (i in 0...arr.length) {
            if (i % 2 == 0 && arr[i] != " ") arr[i] = weirds[Std.random(weirds.length)] + arr[i];
            if (Std.random(10) == 0) arr[i] += weirds[Std.random(weirds.length)];
        }
        if (Std.random(2) == 0) arr.reverse();
        if (Std.random(2) == 0) arr.unshift(weirds[Std.random(weirds.length)]);
        if (Std.random(2) == 0) arr.push(weirds[Std.random(weirds.length)]);
        return arr.join("");
    }

    static function corruptNumber(n:Dynamic):Dynamic {
        var weird = [1, -1, 0, 42, 666, 1337, 9001, 123456, -9999];
        var op = Std.random(5);
        switch (op) {
            case 0: return n + weird[Std.random(weird.length)];
            case 1: return n - weird[Std.random(weird.length)];
            case 2: return n * (Std.random(3) + 1);
            case 3: return n / (Std.random(5) + 1);
            case 4: return -n;
            default: return n;
        }
    }

    static function corruptBool(b:Bool):Bool {
        // Sometimes flip, sometimes always true, sometimes always false
        var op = Std.random(4);
        switch (op) {
            case 0: return !b;
            case 1: return true;
            case 2: return false;
            default: return b;
        }
    }

    static function corruptArray(arr:Array<Dynamic>):Array<Dynamic> {
        var out = [];
        for (item in arr) {
            if (Std.random(3) == 0) out.push("¤" + Std.string(item) + "§");
            else out.push(corruptValue(item));
            if (Std.random(5) == 0) out.push("∑" + Std.string(Std.random(1000)));
        }
        if (Std.random(2) == 0) out.reverse();
        if (Std.random(3) == 0) out.unshift("Ω");
        return out;
    }

    static function corruptAnon(obj:Dynamic):Dynamic {
        var fields = Reflect.fields(obj);
        var out = {};
        for (f in fields) {
            try {
                var v = Reflect.field(obj, f);
                if (Std.random(2) == 0) Reflect.setField(out, f + "¤", corruptValue(v));
                else Reflect.setField(out, f, corruptValue(v));
            } catch (e:Dynamic) {
                trace("Corrupted: Exception corrupting anon field " + f + ": " + Std.string(e));
            }
        }
        if (Std.random(2) == 0) Reflect.setField(out, "weird" + Std.random(100), "§" + Std.string(Std.random(9999)));
        return out;
    }

    static function corruptObject(obj:Dynamic):Dynamic {
        var cls = Type.getClass(obj);
        var fields = Type.getInstanceFields(cls);
        for (f in fields) {
            try {
                var v = Reflect.field(obj, f);
                if (Std.random(2) == 0) Reflect.setField(obj, f, corruptValue(v));
                else if (Std.random(3) == 0) Reflect.setField(obj, f + "§", corruptValue(v));
            } catch (e:Dynamic) {
                trace("Corrupted: Exception corrupting object field " + f + ": " + Std.string(e));
            }
        }
        if (Std.random(2) == 0) Reflect.setField(obj, "corrupt" + Std.random(100), "¤" + Std.string(Std.random(9999)));
        return obj;
    }

    // Operator overloads: make them act weird
    @:op(a + b)
    public inline function opAdd(b:Dynamic):Dynamic {
        try {
            if (Std.isOfType(this, String) || Std.isOfType(b, String))
                return corruptString(Std.string(this) + Std.string(b));
            if (Std.isOfType(this, Int) || Std.isOfType(this, Float))
                return corruptNumber(this) + corruptNumber(b);
        } catch (e:Dynamic) {
            trace("Corrupted: Exception in opAdd: " + Std.string(e));
        }
        return "¤" + Std.string(this) + " + " + Std.string(b) + "§";
    }

    @:op(a - b)
    public inline function opSub(b:Dynamic):Dynamic {
        try {
            if (Std.isOfType(this, Int) || Std.isOfType(this, Float))
                return corruptNumber(this) - corruptNumber(b);
        } catch (e:Dynamic) {
            trace("Corrupted: Exception in opSub: " + Std.string(e));
        }
        return "§" + Std.string(this) + " - " + Std.string(b) + "¤";
    }

    @:op(a == b)
    public inline function opEq(b:Dynamic):Bool {
        return Std.random(2) == 0;
    }

    @:op(a != b)
    public inline function opNeq(b:Dynamic):Bool {
        return Std.random(2) == 0;
    }

    @:op(a < b)
    public inline function opLt(b:Dynamic):Bool {
        return Std.random(2) == 0;
    }

    @:op(a > b)
    public inline function opGt(b:Dynamic):Bool {
        return Std.random(2) == 0;
    }

    @:op(a <= b)
    public inline function opLte(b:Dynamic):Bool {
        return Std.random(2) == 0;
    }

    @:op(a >= b)
    public inline function opGte(b:Dynamic):Bool {
        return Std.random(2) == 0;
    }

    @:op(a.b)
    public inline function opFieldAccessGet(field:String):Dynamic {
        try {
            var v = Reflect.field(this, field);
            return corruptValue(v);
        } catch (e:Dynamic) {
            trace("Corrupted: Exception in opFieldAccessGet: " + Std.string(e));
            return "¤" + field + "§";
        }
    }

    @:op(a.b)
    public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
        try {
            Reflect.setField(this, field, corruptValue(value));
            return corruptValue(value);
        } catch (e:Dynamic) {
            trace("Corrupted: Exception in opFieldAccessSet: " + Std.string(e));
            return "§" + field + "¤";
        }
    }
}

abstract CorruptedPointer<T>(HaxePointer<T>) {
    public inline function new(value:Dynamic) {
        if (value == null) {
            throw 'CorruptedPointer cannot be constructed with null value';
        }
        this = value;
    }

    @:to
    public inline function toHaxePointer():HaxePointer<T> {
        return cast this;
    }

    @:from
    public static inline function fromHaxePointer<T>(value:HaxePointer<T>):CorruptedPointer<T> {
        // Actually corrupt the referenced value
        try {
            var ptr:cpp.Pointer<T> = cast value;
            if (ptr != null && ptr.ref != null) {
                var corrupted = Corrupted.fromValue(ptr.ref);
                ptr.ref = corrupted;
            }
        } catch (e:Dynamic) {
            trace("CorruptedPointer: Exception corrupting pointer: " + Std.string(e));
        }
        return new CorruptedPointer(value);
    }
}

abstract JSON({JSONData:Dynamic, pointer:HaxePointer<Dynamic>, stringified:String}) {
    public inline function new(value:Dynamic) {
        this = toJsonValue(value);
    }

    public var json(get, never):Dynamic;
    private function get_json():Dynamic {
        return this.JSONData;
    }



    @:from
    public static inline function fromValue(value:Dynamic):JSON {
        return new JSON(value);
    }

    // @:from
    // public static inline function fromFilePath(value:FilePath):JSON {
    //     return new JSON(value.fileData);
    // }

    // @:from
    // public static inline function fromFile(value:File):JSON {
    //     return new JSON(value.fileData);
    // }

    @:to
    public inline function toString():String {
        return haxe.Json.stringify(this, null, '\t');
    }

    static function toJsonValue(value:Dynamic):Dynamic {
        var pointerValue:HaxePointer<Dynamic>;
        var stringified:String = "";
        try {
            #if cpp
            pointerValue = try new HaxePointer(value) catch (_:Dynamic) null;
            #else
            pointerValue = value;
            #end
        } catch (_:Dynamic) {
            pointerValue = null;
        }
        try {
            stringified = Std.string(value);
        } catch (_:Dynamic) {
            try stringified = Std.string(value) catch (_:Dynamic) stringified = "<null_string>";
        }

        return {
            JSONData: new Fields(value),
            pointer: pointerValue,
            stringified: stringified
        };
    }
}

/**
 * File is an abstract type that represents a file in the system.
 * It provides methods to convert between FilePath and File, as well as to handle field access.
 * It is useful for cases where you want to work with files in Haxe, especially when interfacing with the file system.
 */
abstract File({filePath:FilePath, fileData:Dynamic}) {
    public inline function new(value:FilePath) {
        this = {filePath: value, fileData: sys.io.File.getBytes(value)};
    }

    @:to
    public inline function toString():String {
        return sys.io.File.getContent(this.filePath);
    }

    @:to
    public inline function toFilePath():FilePath {
        return this.filePath;
    }

    @:to
    public inline function toJSON():JSON
    {
        return new JSON(this.fileData);
    }

    @:from
    public static inline function fromValue(value:Dynamic):File {
        return new File(value);
    }
}

abstract Folder({folderPath:FilePath, folderData:Dynamic}) {
    public inline function new(value:FilePath) {
        this = {folderPath: value, folderData: sys.FileSystem.readDirectory(value)};
    }

    @:to
    public inline function toValue():Dynamic {
        return cast this;
    }

    @:to
    public inline function toString():String {
        return sys.io.File.getContent(this.folderPath);
    }

    @:to
    public inline function toFilePath():FilePath {
        return this.folderPath;
    }

    @:to
    public inline function toJSON():JSON
    {
        return new JSON(this.folderData);
    }

    @:from
    public static inline function fromValue(value:Dynamic):Folder {
        return new Folder(value);
    }
}

abstract FolderPath(Path) {
    public inline function new(value:String) {
        if (value == null) throw 'FolderPath cannot be constructed with null value';
        var str = Std.string(value);
        if (!sys.FileSystem.exists(str)) throw 'FolderPath: Path does not exist: ' + str;
        if (!sys.FileSystem.isDirectory(str)) throw 'FolderPath: Path is not a directory: ' + str;
        this = str;
    }

    @:to
    public inline function toValue():String {
        return cast this;
    }

    @:from
    public static inline function fromValue(value:String):FolderPath {
        return new FolderPath(value);
    }
}



abstract FolderTree(Dynamic) {
    public inline function new(value:Dynamic) {
        this = buildTree(value);
    }

    @:to
    public inline function toValue():Dynamic {
        return cast this;
    }

    @:from
    public static inline function fromValue(value:Dynamic):FolderTree {
        return new FolderTree(value);
    }

    @:to
    public inline function toJSON():JSON {
        return new JSON(this);
    }

    @:to
    public inline function toString():String {
        return treeToString(this, "", true);
    }

    static function buildTree(path:Dynamic):Dynamic {
        var strPath:String = Std.string(path);
        if (!FileSystem.exists(strPath)) throw 'FolderTree: Path does not exist: ' + strPath;
        if (!FileSystem.isDirectory(strPath)) throw 'FolderTree: Path is not a directory: ' + strPath;

        var obj = {};
        for (entry in FileSystem.readDirectory(strPath)) {
            var fullPath = strPath + "/" + entry;
            if (FileSystem.isDirectory(fullPath)) {
                Reflect.setField(obj, entry, buildTree(fullPath));
            } else {
                Reflect.setField(obj, entry, null);
            }
        }
        return obj;
    }

    static function treeToString(tree:Dynamic, prefix:String, isRoot:Bool):String {
        var lines = [];
        var keys = Reflect.fields(tree);
        keys.sort(function(a, b) return a < b ? -1 : 1);
        for (i in 0...keys.length) {
            var key = keys[i];
            var isLast = (i == keys.length - 1);
            var value = Reflect.field(tree, key);
            var connector = isRoot ? "" : (isLast ? "└── " : "├── ");
            lines.push(prefix + connector + key);
            if (value != null) {
                var newPrefix = prefix + (isRoot ? "" : (isLast ? "    " : "│   "));
                lines.push(treeToString(value, newPrefix, false));
            }
        }
        return lines.join("\n");
    }
}

abstract Path(String) {
    public inline function new(value:String) {
        if (value == null) throw 'Path cannot be constructed with null value';
        var str = Std.string(value);
        if (!sys.FileSystem.exists(str)) throw 'Path: Path does not exist: ' + str;
        this = str;
    }

    @:to
    public inline function toValue():String {
        return cast this;
    }

    @:from
    public static inline function fromValue(value:String):Path {
        return new Path(value);
    }
}

/**
 * FilePath is an abstract type that represents a file path in the system.
 * It provides methods to check if the path exists and to convert between String and FilePath.
 * It is useful for cases where you want to work with file paths in Haxe, especially when interfacing with the file system.
 */
abstract FilePath(String) {
    public inline function new(value:String) {
        if (value == null) throw 'FilePath cannot be constructed with null value';
        var str = Std.string(value);
        if (!FilePath.exists(str)) throw 'FilePath: Path does not exist: ' + str;
        this = str;
    }

    @:to
    public inline function toValue():String {
        return cast this;
    }

    @:from
    public static inline function fromValue(value:String):FilePath {
        return new FilePath(value);
    }

    @:from
    public static inline function fromArray(value:Array<String>):FilePath {
        if (value.length == 0) throw 'FilePath: Cannot create from empty array';
        var path = value.join("/");
        return new FilePath(path);
    }

    public static function exists(path:String):Bool {
        return sys.FileSystem.exists(path);
    }
}

/**
 * Collapsed<T> is an abstract that recursively flattens nested arrays or maps into a single array or map.
 * For arrays: [[1, 2], [3, [4, 5]], 6] => [1, 2, 3, 4, 5, 6]
 * For maps: {a: {b: 1}, c: 2} => {b: 1, c: 2}
 * For other types, returns as-is.
 */
abstract Collapsed<T>(Dynamic) {
    public inline function new(value:Dynamic) {
        this = collapse(value);
    }

    @:to
    public inline function toValue():T {
        return cast this;
    }

    @:from
    public static inline function fromValue<T>(value:Dynamic):Collapsed<T> {
        return new Collapsed(value);
    }

    // Recursively collapse arrays and maps
    static function collapse(value:Dynamic):Dynamic {
        if (Std.isOfType(value, Array)) {
            var result = [];
            for (item in (value:Array<Dynamic>)) {
                var collapsed = collapse(item);
                if (Std.isOfType(collapsed, Array)) {
                    result = result.concat(collapsed);
                } else {
                    result.push(cast collapsed);
                }
            }
            return result;
        } else if (Std.isOfType(value, haxe.ds.StringMap)) {
            var result = new haxe.ds.StringMap<Dynamic>();
            for (k in (cast value : haxe.ds.StringMap<Dynamic>).keys()) {
                var v = collapse((cast value : haxe.ds.StringMap<Dynamic>).get(k));
                if (Std.isOfType(v, haxe.ds.StringMap)) {
                    for (subk in (cast v : haxe.ds.StringMap<Dynamic>).keys()) {
                        result.set(subk, (cast v : haxe.ds.StringMap<Dynamic>).get(subk));
                    }
                } else {
                    result.set(k, v);
                }
            }
            return result;
        } else if (value.isMap()) {
            throw 'Collapsed<T> does not support Map types currently.';
        }
        return value;
    }
}

#end

abstract FieldAccTest<T>(Dynamic) {
    public function new(value:Dynamic) {
        this = value;
    }

    @:to
    public inline function toValue():T {
        return cast this;
    }

    @:from
    public static inline function fromValue<T>(value:T):FieldAccTest<T> {
        return new FieldAccTest(value);
    }

    @:op(a.b) public inline function opFieldAccessGet(field:String):Dynamic {
        trace('opFieldAccess get: ' + field);
        return field;
    }

    @:op(a.b) public inline function opFieldAccessSet(field:String, value:Dynamic):Dynamic {
        trace('opFieldAccess set: ' + field + ' = ' + value);
        return value;
    }
}
