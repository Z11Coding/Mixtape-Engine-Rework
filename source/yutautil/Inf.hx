package yutautil;

class Inf {
    public static inline var value:Float = 1.0 / 0.0;
    public static inline function isInfinity(x:Float):Bool return x == value;
    public static inline function isFinite(x:Float):Bool return !isInfinity(x);
}

// THIS IS A WORK IN PROGRESS! MEANT TO REPLACE Float/Int FOR HANDLING ARBITRARY PRECISION NUMBERS.
// This class is designed to handle arbitrary precision numbers with a floating point.
// It supports addition, subtraction, multiplication, division, and negation.
// It can handle very large numbers and very small fractions, but it is not optimized for performance
// and may not be suitable for all use cases.
// It is designed to be used as a drop-in replacement for Float/Int in most cases, but it may not
// be compatible with all existing code that uses Float/Int.
// It is recommended to use this class only for cases where precision is critical and the range of
// numbers is beyond the limits of Float/Int.

// Note: This is mostly useful for displaying large numbers in a human-readable format
// and performing arithmetic operations on them without losing precision.
// It may not be usable for x and y coordinates in a game or application,
// as those typically require fixed-point or floating-point numbers directly.

class InfNum {
    public var value:Array<Int>;
    public var floatPoint:Array<Int>;
    public var isNegative:Bool;
    public var allowOverflow:Bool;
    public var allowNegative:Bool;

    public function new(allowedDigits:Int = 10, ?allowOverflow:Bool, ?allowNegative:Bool, ?initialValue:Float) {
        value = [];
        floatPoint = [];
        this.allowNegative = allowNegative != null ? allowNegative : false;
        this.allowOverflow = allowOverflow != null ? allowOverflow : false;

        for (i in 0...allowedDigits) value.push(0);

        if (initialValue != null) fromFloat(initialValue);
        else isNegative = false;
    }

    public function fromFloat(f:Float) {
        isNegative = f < 0;
        if (isNegative) f = -f;
        var s = Std.string(f);
        var parts = s.split(".");
        var intPart = parts[0];
        var fracPart = parts.length > 1 ? parts[1] : "";

        value = [];
        for (i in 0...intPart.length) value.push(Std.parseInt(intPart.charAt(i)));
        floatPoint = [];
        for (i in 0...fracPart.length) floatPoint.push(Std.parseInt(fracPart.charAt(i)));
    }

    public function toFloat():Float {
        var s = (isNegative ? "-" : "") + value.join("");
        if (floatPoint.length > 0) s += "." + floatPoint.join("");
        return Std.parseFloat(s);
    }

    public function toString():String {
        var str = isNegative ? "-" : "";
        str += value.join("");
        if (floatPoint.length > 0) str += "." + floatPoint.join("");
        return str;
    }

    public function clone():InfNum {
        var n = new InfNum();
        n.value = value.copy();
        n.floatPoint = floatPoint.copy();
        n.isNegative = isNegative;
        n.allowOverflow = allowOverflow;
        n.allowNegative = allowNegative;
        return n;
    }

    public function normalize() {
        // Normalize floatPoint (carry to value if needed)
        for (i in floatPoint.length - 1...0) {
            if (floatPoint[i] >= 10) {
                var carry = Math.floor(floatPoint[i] / 10);
                floatPoint[i] %= 10;
                if (i == 0) {
                    if (value.length > 0) value[value.length - 1] += carry;
                } else {
                    floatPoint[i - 1] += carry;
                }
            }
        }
        // Normalize value (carry to left)
        for (i in value.length - 1...0) {
            if (value[i] >= 10) {
                var carry = Math.floor(value[i] / 10);
                value[i] %= 10;
                if (i > 0) value[i - 1] += carry;
                else value.unshift(carry);
            }
        }
    }

    // Mutating add
    public function add(other:InfNum):InfNum {
        // Pad floatPoint to same length
        while (this.floatPoint.length < other.floatPoint.length) this.floatPoint.push(0);
        while (other.floatPoint.length < this.floatPoint.length) other.floatPoint.push(0);
        // Pad value to same length
        while (this.value.length < other.value.length) this.value.unshift(0);
        while (other.value.length < this.value.length) other.value.unshift(0);

        var carry = 0;
        // Add floatPoint
        for (i in this.floatPoint.length - 1...-1) {
            var sum = this.floatPoint[i] + other.floatPoint[i] + carry;
            carry = Math.floor(sum / 10);
            this.floatPoint[i] = sum % 10;
        }
        // Add value
        for (i in this.value.length - 1...-1) {
            var sum = this.value[i] + other.value[i] + carry;
            carry = Math.floor(sum / 10);
            this.value[i] = sum % 10;
        }
        if (carry > 0) this.value.unshift(carry);
        this.normalize();
        return this;
    }

    // Mutating subtract
    public function subtract(other:InfNum):InfNum {
        // Pad floatPoint to same length
        while (this.floatPoint.length < other.floatPoint.length) this.floatPoint.push(0);
        while (other.floatPoint.length < this.floatPoint.length) other.floatPoint.push(0);
        // Pad value to same length
        while (this.value.length < other.value.length) this.value.unshift(0);
        while (other.value.length < this.value.length) other.value.unshift(0);

        var borrow = 0;
        // Subtract floatPoint
        for (i in this.floatPoint.length - 1...-1) {
            var diff = this.floatPoint[i] - other.floatPoint[i] - borrow;
            if (diff < 0) {
                diff += 10;
                borrow = 1;
            } else borrow = 0;
            this.floatPoint[i] = diff;
        }
        // Subtract value
        for (i in this.value.length - 1...-1) {
            var diff = this.value[i] - other.value[i] - borrow;
            if (diff < 0) {
                diff += 10;
                borrow = 1;
            } else borrow = 0;
            this.value[i] = diff;
        }
        this.normalize();
        return this;
    }

    // Mutating multiply
    public function multiply(other:InfNum):InfNum {
        var f = this.toFloat() * other.toFloat();
        this.fromFloat(f);
        return this;
    }

    // Mutating divide
    public function divide(other:InfNum):InfNum {
        var f = this.toFloat() / other.toFloat();
        this.fromFloat(f);
        return this;
    }

    // Mutating negate
    public function negate():InfNum {
        this.isNegative = !this.isNegative;
        return this;
    }

    public function isZero():Bool {
        for (v in value) if (v != 0) return false;
        for (v in floatPoint) if (v != 0) return false;
        return true;
    }
}

// Abstract Num for seamless usage
@:forward
abstract INum(InfNum) from InfNum {
    public inline function new(v:Dynamic) {
        if (Std.isOfType(v, InfNum)) this = v;
        else if (Std.isOfType(v, Int) || Std.isOfType(v, Float)) {
            var n = new InfNum();
            n.fromFloat(Std.parseFloat(Std.string(v)));
            this = n;
        } else throw "Unsupported type";
    }

    @:from
    public static function fromInt(i:Int):INum {
        var n = new InfNum();
        n.fromFloat(i);
        return new INum(n);
    }

    @:from
    public static function fromFloat(f:Float):INum {
        var n = new InfNum();
        n.fromFloat(f);
        return new INum(n);
    }

    @:op(A + B) public static function add(a:INum, b:INum):INum return (cast a : InfNum).add((cast b : InfNum));
    @:op(A - B) public static function sub(a:INum, b:INum):INum return (cast a : InfNum).subtract((cast b : InfNum));
    @:op(A * B) public static function mul(a:INum, b:INum):INum return (cast a : InfNum).multiply((cast b : InfNum));
    @:op(A / B) public static function div(a:INum, b:INum):INum return (cast a : InfNum).divide((cast b : InfNum));

    public function toString():String return this.toString();
    @:to public function toInt():Int return Std.parseInt(this.toString());
    @:to
    public function toFloat():Float return this.toFloat();
}
