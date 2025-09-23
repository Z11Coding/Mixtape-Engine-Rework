package yutautil;

/**
 * Num - A universal number abstract that works with any numeric type
 *
 * This abstract provides a unified interface for working with different number types
 * (Int, Float, UInt, etc.) without having to worry about explicit casting.
 *
 * Usage:
 * ```haxe
 * var num:Num = 42;          // From Int
 * var num:Num = 3.14;        // From Float
 * var num:Num = 100.5;       // From any numeric type
 *
 * var result = num + 10;     // Works with any numeric operation
 * var floatVal:Float = num;  // Implicit conversion to Float
 * var intVal:Int = num;      // Implicit conversion to Int
 * ```
 * Warning: It may require explicit casting in some contexts, but easily can be bypassed by using the `cast` keyword.
 */
abstract Num(Float)
{
    // Constructors - implicit conversions FROM various number types
    @:from public static inline function fromInt(value:Int):Num
        return new Num(value);

    @:from public static inline function fromFloat(value:Float):Num
        return new Num(value);

    @:from public static inline function fromUInt(value:UInt):Num
        return new Num(value);

    #if (haxe_ver >= 4.0)
    @:from public static inline function fromInt64(value:haxe.Int64):Num
        return new Num(haxe.Int64.toInt(value));
    #end

    // Conversions TO various number types
    @:to public inline function toInt():Int
        return Std.int(this);

    @:to public inline function toFloat():Float
        return this;

    @:to public inline function toUInt():UInt
        return Std.int(Math.max(0, this));

    #if (haxe_ver >= 4.0)
    @:to public inline function toInt64():haxe.Int64
        return haxe.Int64.ofInt(Std.int(this));
    #end

    // Constructor
    public inline function new(value:Float)
        this = value;

    // Arithmetic operators
    @:op(A + B) public inline function add(rhs:Num):Num
        return this + rhs.toFloat();
    @:op(A + B) public inline function addFloat(rhs:Float):Num
        return this + rhs;
    @:op(A + B) public inline function addInt(rhs:Int):Num
        return this + rhs;
    @:op(A + B) public inline function addUInt(rhs:UInt):Num
        return this + rhs;
    #if (haxe_ver >= 4.0)
    @:op(A + B) public inline function addInt64(rhs:haxe.Int64):Num
        return this + haxe.Int64.toInt(rhs);
    #end

    @:op(A - B) public inline function subtract(rhs:Num):Num
        return this - rhs.toFloat();
    @:op(A - B) public inline function subtractFloat(rhs:Float):Num
        return this - rhs;
    @:op(A - B) public inline function subtractInt(rhs:Int):Num
        return this - rhs;
    @:op(A - B) public inline function subtractUInt(rhs:UInt):Num
        return this - rhs;
    #if (haxe_ver >= 4.0)
    @:op(A - B) public inline function subtractInt64(rhs:haxe.Int64):Num
        return this - haxe.Int64.toInt(rhs);
    #end

    @:op(A * B) public inline function multiply(rhs:Num):Num
        return this * rhs.toFloat();
    @:op(A * B) public inline function multiplyFloat(rhs:Float):Num
        return this * rhs;
    @:op(A * B) public inline function multiplyInt(rhs:Int):Num
        return this * rhs;
    @:op(A * B) public inline function multiplyUInt(rhs:UInt):Num
        return this * rhs;
    #if (haxe_ver >= 4.0)
    @:op(A * B) public inline function multiplyInt64(rhs:haxe.Int64):Num
        return this * haxe.Int64.toInt(rhs);
    #end

    @:op(A / B) public inline function divide(rhs:Num):Num
        return this / rhs.toFloat();
    @:op(A / B) public inline function divideFloat(rhs:Float):Num
        return this / rhs;
    @:op(A / B) public inline function divideInt(rhs:Int):Num
        return this / rhs;
    @:op(A / B) public inline function divideUInt(rhs:UInt):Num
        return this / rhs;
    #if (haxe_ver >= 4.0)
    @:op(A / B) public inline function divideInt64(rhs:haxe.Int64):Num
        return this / haxe.Int64.toInt(rhs);
    #end

    @:op(A % B) public inline function modulo(rhs:Num):Num
        return this % rhs.toFloat();
    @:op(A % B) public inline function moduloFloat(rhs:Float):Num
        return this % rhs;
    @:op(A % B) public inline function moduloInt(rhs:Int):Num
        return this % rhs;
    @:op(A % B) public inline function moduloUInt(rhs:UInt):Num
        return this % rhs;
    #if (haxe_ver >= 4.0)
    @:op(A % B) public inline function moduloInt64(rhs:haxe.Int64):Num
        return this % haxe.Int64.toInt(rhs);
    #end

    // Unary operators
    @:op(-A) public inline function negate():Num
        return -this;

    @:op(++A) public inline function preIncrement():Num
        return this = this + 1;
    @:op(A++) public inline function postIncrement():Num {
        var ret = this;
        this = this + 1;
        return ret;
    }

    @:op(--A) public inline function preDecrement():Num
        return this = this - 1;
    @:op(A--) public inline function postDecrement():Num {
        var ret = this;
        this = this - 1;
        return ret;
    }

    // Comparison operators
    @:op(A == B) public inline function equals(rhs:Num):Bool
        return this == rhs.toFloat();
    @:op(A == B) public inline function equalsFloat(rhs:Float):Bool
        return this == rhs;
    @:op(A == B) public inline function equalsInt(rhs:Int):Bool
        return this == rhs;
    @:op(A == B) public inline function equalsUInt(rhs:UInt):Bool
        return this == rhs;
    #if (haxe_ver >= 4.0)
    @:op(A == B) public inline function equalsInt64(rhs:haxe.Int64):Bool
        return this == haxe.Int64.toInt(rhs);
    #end

    @:op(A != B) public inline function notEquals(rhs:Num):Bool
        return this != rhs.toFloat();
    @:op(A != B) public inline function notEqualsFloat(rhs:Float):Bool
        return this != rhs;
    @:op(A != B) public inline function notEqualsInt(rhs:Int):Bool
        return this != rhs;
    @:op(A != B) public inline function notEqualsUInt(rhs:UInt):Bool
        return this != rhs;
    #if (haxe_ver >= 4.0)
    @:op(A != B) public inline function notEqualsInt64(rhs:haxe.Int64):Bool
        return this != haxe.Int64.toInt(rhs);
    #end

    @:op(A < B) public inline function lessThan(rhs:Num):Bool
        return this < rhs.toFloat();
    @:op(A < B) public inline function lessThanFloat(rhs:Float):Bool
        return this < rhs;
    @:op(A < B) public inline function lessThanInt(rhs:Int):Bool
        return this < rhs;
    @:op(A < B) public inline function lessThanUInt(rhs:UInt):Bool
        return this < rhs;
    #if (haxe_ver >= 4.0)
    @:op(A < B) public inline function lessThanInt64(rhs:haxe.Int64):Bool
        return this < haxe.Int64.toInt(rhs);
    #end

    @:op(A <= B) public inline function lessThanOrEqual(rhs:Num):Bool
        return this <= rhs.toFloat();
    @:op(A <= B) public inline function lessThanOrEqualFloat(rhs:Float):Bool
        return this <= rhs;
    @:op(A <= B) public inline function lessThanOrEqualInt(rhs:Int):Bool
        return this <= rhs;
    @:op(A <= B) public inline function lessThanOrEqualUInt(rhs:UInt):Bool
        return this <= rhs;
    #if (haxe_ver >= 4.0)
    @:op(A <= B) public inline function lessThanOrEqualInt64(rhs:haxe.Int64):Bool
        return this <= haxe.Int64.toInt(rhs);
    #end

    @:op(A > B) public inline function greaterThan(rhs:Num):Bool
        return this > rhs.toFloat();
    @:op(A > B) public inline function greaterThanFloat(rhs:Float):Bool
        return this > rhs;
    @:op(A > B) public inline function greaterThanInt(rhs:Int):Bool
        return this > rhs;
    @:op(A > B) public inline function greaterThanUInt(rhs:UInt):Bool
        return this > rhs;
    #if (haxe_ver >= 4.0)
    @:op(A > B) public inline function greaterThanInt64(rhs:haxe.Int64):Bool
        return this > haxe.Int64.toInt(rhs);
    #end

    @:op(A >= B) public inline function greaterThanOrEqual(rhs:Num):Bool
        return this >= rhs.toFloat();
    @:op(A >= B) public inline function greaterThanOrEqualFloat(rhs:Float):Bool
        return this >= rhs;
    @:op(A >= B) public inline function greaterThanOrEqualInt(rhs:Int):Bool
        return this >= rhs;
    @:op(A >= B) public inline function greaterThanOrEqualUInt(rhs:UInt):Bool
        return this >= rhs;
    #if (haxe_ver >= 4.0)
    @:op(A >= B) public inline function greaterThanOrEqualInt64(rhs:haxe.Int64):Bool
        return this >= haxe.Int64.toInt(rhs);
    #end

    // Assignment operators
    @:op(A += B) public inline function addAssign(rhs:Num):Num
        return this = this + rhs.toFloat();
    @:op(A += B) public inline function addAssignFloat(rhs:Float):Num
        return this = this + rhs;
    @:op(A += B) public inline function addAssignInt(rhs:Int):Num
        return this = this + rhs;
    @:op(A += B) public inline function addAssignUInt(rhs:UInt):Num
        return this = this + rhs;
    #if (haxe_ver >= 4.0)
    @:op(A += B) public inline function addAssignInt64(rhs:haxe.Int64):Num
        return this = this + haxe.Int64.toInt(rhs);
    #end

    @:op(A -= B) public inline function subtractAssign(rhs:Num):Num
        return this = this - rhs.toFloat();
    @:op(A -= B) public inline function subtractAssignFloat(rhs:Float):Num
        return this = this - rhs;
    @:op(A -= B) public inline function subtractAssignInt(rhs:Int):Num
        return this = this - rhs;
    @:op(A -= B) public inline function subtractAssignUInt(rhs:UInt):Num
        return this = this - rhs;
    #if (haxe_ver >= 4.0)
    @:op(A -= B) public inline function subtractAssignInt64(rhs:haxe.Int64):Num
        return this = this - haxe.Int64.toInt(rhs);
    #end

    @:op(A *= B) public inline function multiplyAssign(rhs:Num):Num
        return this = this * rhs.toFloat();
    @:op(A *= B) public inline function multiplyAssignFloat(rhs:Float):Num
        return this = this * rhs;
    @:op(A *= B) public inline function multiplyAssignInt(rhs:Int):Num
        return this = this * rhs;
    @:op(A *= B) public inline function multiplyAssignUInt(rhs:UInt):Num
        return this = this * rhs;
    #if (haxe_ver >= 4.0)
    @:op(A *= B) public inline function multiplyAssignInt64(rhs:haxe.Int64):Num
        return this = this * haxe.Int64.toInt(rhs);
    #end

    @:op(A /= B) public inline function divideAssign(rhs:Num):Num
        return this = this / rhs.toFloat();
    @:op(A /= B) public inline function divideAssignFloat(rhs:Float):Num
        return this = this / rhs;
    @:op(A /= B) public inline function divideAssignInt(rhs:Int):Num
        return this = this / rhs;
    @:op(A /= B) public inline function divideAssignUInt(rhs:UInt):Num
        return this = this / rhs;
    #if (haxe_ver >= 4.0)
    @:op(A /= B) public inline function divideAssignInt64(rhs:haxe.Int64):Num
        return this = this / haxe.Int64.toInt(rhs);
    #end

    @:op(A %= B) public inline function moduloAssign(rhs:Num):Num
        return this = this % rhs.toFloat();
    @:op(A %= B) public inline function moduloAssignFloat(rhs:Float):Num
        return this = this % rhs;
    @:op(A %= B) public inline function moduloAssignInt(rhs:Int):Num
        return this = this % rhs;
    @:op(A %= B) public inline function moduloAssignUInt(rhs:UInt):Num
        return this = this % rhs;
    #if (haxe_ver >= 4.0)
    @:op(A %= B) public inline function moduloAssignInt64(rhs:haxe.Int64):Num
        return this = this % haxe.Int64.toInt(rhs);
    #end

    // Utility methods

    /**
        * Returns the square of the number
        */
    public inline function square():Num
        return this * this;

    /**
     * Returns the cube of the number
     */
    public inline function cube():Num
        return this * this * this;


     @:to public inline function toFloatIterator():Iterator<Num> {
        return floatIterator(this, 1.0);
    }

    /**
     * Returns an iterator that iterates from this value up to (but not including) the target,
     * stepping by the given floating point step.
     *
     * Usage:
     * for (n in startNum.floatIterator(endNum, 0.1)) { ... }
     */
    public inline function floatIterator(target:Num, ?step:Float):Iterator<Num> {
        if (step == null) step = 1.0;
        var current:Num = this;
        var ascending = step > 0;
        return {
            hasNext: function():Bool {
                return ascending ? (current < target) : (current > target);
            },
            next: function():Num {
                var ret = current;
                current += step;
                return ret;
            }
        };
    }

    public static inline function range(start:Num, end:Num, ?step:Float):Array<Num> {
        var result = [];
        if (step == null) step = 1.0;
        var current:Num = start;
        var ascending = step > 0;
        while (ascending ? (current < end) : (current > end)) {
            result.push(current);
            current += step;
        }
        return result;
    }

    public static inline function inclusiveRange(start:Num, end:Num, ?step:Float):Array<Num> {
        var result = [];
        if (step == null) step = 1.0;
        var current:Num = start;
        var ascending = step > 0;
        while (ascending ? (current <= end) : (current >= end)) {
            result.push(current);
            current += step;
        }
        return result;
    }

    public static inline function floatIter(Iterated:Num, stp:Num):Iterator<Num> {
        return new Num(Iterated).floatIterator(stp);
    }

    /**
     * Returns the absolute value
     */
    public inline function abs():Num
        return Math.abs(this);

    /**
     * Rounds to the nearest integer
     */
    public inline function round():Num
        return Math.round(this);

    /**
     * Rounds down to the nearest integer
     */
    public inline function floor():Num
        return Math.floor(this);

    /**
     * Rounds up to the nearest integer
     */
    public inline function ceil():Num
        return Math.ceil(this);

    /**
     * Returns the minimum of this and another number
     */
    public inline function min(other:Num):Num
        return Math.min(this, other.toFloat());

    /**
     * Returns the maximum of this and another number
     */
    public inline function max(other:Num):Num
        return Math.max(this, other.toFloat());

    /**
     * Clamps this number between min and max values
     */
    public inline function clamp(min:Num, max:Num):Num
        return Math.max(min.toFloat(), Math.min(max.toFloat(), this));

    /**
     * Linear interpolation between this and target
     */
    public inline function lerp(target:Num, ratio:Float):Num
        return this + (target.toFloat() - this) * ratio;

    /**
     * Checks if this number is within a range (inclusive)
     */
    public inline function inRange(min:Num, max:Num):Bool
        return this >= min.toFloat() && this <= max.toFloat();

    /**
     * Checks if this number is approximately equal to another (within tolerance)
     */
    public inline function approxEquals(other:Num, tolerance:Float = 0.0001):Bool
        return Math.abs(this - other.toFloat()) <= tolerance;

    /**
     * Checks if this number is zero (or approximately zero)
     */
    public inline function isZero(tolerance:Float = 0.0001):Bool
        return Math.abs(this) <= tolerance;

    /**
     * Checks if this number is positive
     */
    public inline function isPositive():Bool
        return this > 0;

    /**
     * Checks if this number is negative
     */
    public inline function isNegative():Bool
        return this < 0;

    /**
     * Checks if this number is an integer (no fractional part)
     */
    public inline function isInteger():Bool
        return this == Math.floor(this);

    /**
     * Checks if this number is finite (not infinity or NaN)
     */
    public inline function isFinite():Bool
        return Math.isFinite(this);

    /**
     * Checks if this number is NaN
     */
    public inline function isNaN():Bool
        return Math.isNaN(this);

    /**
     * Returns the sign of this number (-1, 0, or 1)
     */
    public inline function sign():Int {
        if (this > 0) return 1;
        if (this < 0) return -1;
        return 0;
    }

    /**
     * Converts to string representation
     */
    public inline function toString():String
        return Std.string(this);

    /**
     * Converts to string with specified precision
     */
    public inline function toFixed(precision:Int):String {
        var factor = Math.pow(10, precision);
        var rounded = Math.round(this * factor) / factor;
        return Std.string(rounded);
    }
}
