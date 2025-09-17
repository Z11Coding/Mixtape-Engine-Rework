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

    @:op(A - B) public inline function subtract(rhs:Num):Num
        return this - rhs.toFloat();

    @:op(A * B) public inline function multiply(rhs:Num):Num
        return this * rhs.toFloat();

    @:op(A / B) public inline function divide(rhs:Num):Num
        return this / rhs.toFloat();

    @:op(A % B) public inline function modulo(rhs:Num):Num
        return this % rhs.toFloat();

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

    @:op(A != B) public inline function notEquals(rhs:Num):Bool
        return this != rhs.toFloat();

    @:op(A < B) public inline function lessThan(rhs:Num):Bool
        return this < rhs.toFloat();

    @:op(A <= B) public inline function lessThanOrEqual(rhs:Num):Bool
        return this <= rhs.toFloat();

    @:op(A > B) public inline function greaterThan(rhs:Num):Bool
        return this > rhs.toFloat();

    @:op(A >= B) public inline function greaterThanOrEqual(rhs:Num):Bool
        return this >= rhs.toFloat();

    // Assignment operators
    @:op(A += B) public inline function addAssign(rhs:Num):Num
        return this = this + rhs.toFloat();

    @:op(A -= B) public inline function subtractAssign(rhs:Num):Num
        return this = this - rhs.toFloat();

    @:op(A *= B) public inline function multiplyAssign(rhs:Num):Num
        return this = this * rhs.toFloat();

    @:op(A /= B) public inline function divideAssign(rhs:Num):Num
        return this = this / rhs.toFloat();

    @:op(A %= B) public inline function moduloAssign(rhs:Num):Num
        return this = this % rhs.toFloat();

    // Utility methods

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
