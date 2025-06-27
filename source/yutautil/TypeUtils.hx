package yutautil;

/**
 * OneOrMore is an alias for OneOrMany<T> where T is the type of the items.
 * It allows a variable to take either a single item of type T or an array of items of type T.
 * This is useful for functions that can accept either a single item or multiple items of the same type.
 */
typedef OneOrMore<T> = OneOrMany<T>;

class TypeTools {
    public static final ptrMap:Map<PtrAddress, GlobalPointer<Dynamic>> = new Map<PtrAddress, GlobalPointer<Dynamic>>();

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

/* * HaxePointer is an abstract type that wraps a cpp.Pointer<T>.
 * It provides methods to convert from/to cpp.Pointer<T> and to handle field access.
 * It is useful for cases where you want to work with pointers in Haxe, especially when interfacing with C++ code.
 * !! DO NOT STACK THIS TYPE !!
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

abstract JSON({JSONData:Dynamic, pointer:HaxePointer<Dynamic>, stringified:String}) {
    public inline function new(value:Dynamic) {
        this = toJsonValue(value);
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
        return haxe.Json.stringify(this);
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

        var result:Dynamic = null;

        if (value == null) {
            result = {};
        } else if (Reflect.isObject(value) && !Std.isOfType(value, Array) && !Std.isOfType(value, String) && Type.getClass(value) == null) {
            // Anonymous object
            var obj = {};
            for (field in Reflect.fields(value)) {
                Reflect.setField(obj, field, toJsonValue(Reflect.field(value, field)));
            }
            result = obj;
        } else if (Type.getClass(value) != null) {
            // Class instance
            var cls = Type.getClass(value);
            var fields = Type.getInstanceFields(cls).concat(Reflect.fields(value));
            var obj = {};
            for (field in fields) {
                if (Reflect.hasField(value, field)) {
                    Reflect.setField(obj, field, toJsonValue(Reflect.field(value, field)));
                }
            }
            result = obj;
        } else if (Std.isOfType(value, String)) {
            // String, try parse as JSON
            try {
                var parsed = haxe.Json.parse(value);
                result = toJsonValue(parsed);
            } catch (_:Dynamic) {
                result = { failedString: value };
            }
        } else if (Std.isOfType(value, Array)) {
            // Array
            var arr:Array<Dynamic> = cast value;
            result = [for (v in arr) toJsonValue(v)];
        } else if (Std.isOfType(value, haxe.ds.StringMap)) {
            // StringMap
            var map:haxe.ds.StringMap<Dynamic> = cast value;
            var obj = {};
            for (k in map.keys()) {
                Reflect.setField(obj, k, toJsonValue(map.get(k)));
            }
            result = obj;
        } else if (value.isMap()) {
            // Map
            var map:Map<Dynamic, Dynamic> = cast value;
            var obj = {};
            for (k in map.keys()) {
                Reflect.setField(obj, Std.string(k), toJsonValue(map.get(k)));
            }
            result = obj;
        } else {
            // Other types (numbers, bool, etc)
            result = value;
        }

        return {
            JSONData: result,
            pointer: pointerValue,
            stringified: stringified
        };
    }
}

// /**
//  * File is an abstract type that represents a file in the system.
//  * It provides methods to convert between FilePath and File, as well as to handle field access.
//  * It is useful for cases where you want to work with files in Haxe, especially when interfacing with the file system.
//  */
// abstract File({filePath:FilePath, fileData:Dynamic}) {
//     public inline function new(value:FilePath) {
//         this = {filePath: value, fileData: sys.io.File.readBytes(value)};
//     }

//     @:to
//     public inline function toString():String {
//         return sys.io.File.getContent(this.filePath);
//     }

//     @:to
//     public inline function toFilePath():FilePath {
//         return this.filePath;
//     }

//     @:to
//     public inline function toJSON():JSON
//     {
//         return new JSON(this.fileData);
//     }

//     @:from
//     public static inline function fromValue(value:Dynamic):File {
//         return new File(value);
//     }
// }

// abstract Folder({folderPath:FilePath, folderData:Dynamic}) {
//     public inline function new(value:FilePath) {
//         this = {folderPath: value, folderData: sys.io.File.readDirectory(value)};
//     }

//     @:to
//     public inline function toValue():Dynamic {
//         return cast this;
//     }

//     @:to
//     public inline function toString():String {
//         return sys.io.File.getContent(this.folderPath);
//     }

//     @:to
//     public inline function toFilePath():FilePath {
//         return this.folderPath;
//     }

//     @:to
//     public inline function toJSON():JSON
//     {
//         return new JSON(this.folderData);
//     }

//     @:from
//     public static inline function fromValue(value:Dynamic):Folder {
//         return new Folder(value);
//     }
// }

// abstract FolderPath(Path) {
//     public inline function new(value:String) {
//         if (value == null) throw 'FolderPath cannot be constructed with null value';
//         var str = Std.string(value);
//         if (!sys.FileSystem.exists(str)) throw 'FolderPath: Path does not exist: ' + str;
//         if (!sys.FileSystem.isDirectory(str)) throw 'FolderPath: Path is not a directory: ' + str;
//         this = str;
//     }

//     @:to
//     public inline function toValue():String {
//         return cast this;
//     }

//     @:from
//     public static inline function fromValue(value:String):FolderPath {
//         return new FolderPath(value);
//     }
// }



// abstract FolderTree(Dynamic) {
//     public inline function new(value:Dynamic) {
//         this = buildTree(value);
//     }

//     @:to
//     public inline function toValue():Dynamic {
//         return cast this;
//     }

//     @:from
//     public static inline function fromValue(value:Dynamic):FolderTree {
//         return new FolderTree(value);
//     }

//     @:to
//     public inline function toJSON():JSON {
//         return new JSON(this);
//     }

//     @:to
//     public inline function toString():String {
//         return treeToString(this, "", true);
//     }

//     static function buildTree(path:Dynamic):Dynamic {
//         var strPath:String = Std.string(path);
//         if (!FileSystem.exists(strPath)) throw 'FolderTree: Path does not exist: ' + strPath;
//         if (!FileSystem.isDirectory(strPath)) throw 'FolderTree: Path is not a directory: ' + strPath;

//         var obj = {};
//         for (entry in FileSystem.readDirectory(strPath)) {
//             var fullPath = strPath + "/" + entry;
//             if (FileSystem.isDirectory(fullPath)) {
//                 Reflect.setField(obj, entry, buildTree(fullPath));
//             } else {
//                 Reflect.setField(obj, entry, null);
//             }
//         }
//         return obj;
//     }

//     static function treeToString(tree:Dynamic, prefix:String, isRoot:Bool):String {
//         var lines = [];
//         var keys = Reflect.fields(tree);
//         keys.sort(function(a, b) return a < b ? -1 : 1);
//         for (i in 0...keys.length) {
//             var key = keys[i];
//             var isLast = (i == keys.length - 1);
//             var value = Reflect.field(tree, key);
//             var connector = isRoot ? "" : (isLast ? "└── " : "├── ");
//             lines.push(prefix + connector + key);
//             if (value != null) {
//                 var newPrefix = prefix + (isRoot ? "" : (isLast ? "    " : "│   "));
//                 lines.push(treeToString(value, newPrefix, false));
//             }
//         }
//         return lines.join("\n");
//     }
// }

// abstract Path(String) {
//     public inline function new(value:String) {
//         if (value == null) throw 'Path cannot be constructed with null value';
//         var str = Std.string(value);
//         if (!sys.FileSystem.exists(str)) throw 'Path: Path does not exist: ' + str;
//         this = str;
//     }

//     @:to
//     public inline function toValue():String {
//         return cast this;
//     }

//     @:from
//     public static inline function fromValue(value:String):Path {
//         return new Path(value);
//     }
// }

// /**
//  * FilePath is an abstract type that represents a file path in the system.
//  * It provides methods to check if the path exists and to convert between String and FilePath.
//  * It is useful for cases where you want to work with file paths in Haxe, especially when interfacing with the file system.
//  */
// abstract FilePath(String) {
//     public inline function new(value:String) {
//         if (value == null) throw 'FilePath cannot be constructed with null value';
//         var str = Std.string(value);
//         if (!FilePath.exists(str)) throw 'FilePath: Path does not exist: ' + str;
//         this = str;
//     }

//     @:to
//     public inline function toValue():String {
//         return cast this;
//     }

//     @:from
//     public static inline function fromValue(value:String):FilePath {
//         return new FilePath(value);
//     }

//     @:from
//     public static inline function fromArray(value:Array<String>):FilePath {
//         if (value.length == 0) throw 'FilePath: Cannot create from empty array';
//         var path = value.join("/");
//         return new FilePath(path);
//     }

//     public static function exists(path:String):Bool {
//         return sys.FileSystem.exists(path);
//     }
// }

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