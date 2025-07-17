package yutautil;

/**
 * YNumber - A simpler infinite precision number class
 * Uses arrays to store digits and handles overflow by carrying to the next digit
 * Supports both integer and floating point parts
 */
class YNumber {
    public var intPart:Array<Int>;
    public var floatPart:Array<Int>;
    public var isNegative:Bool;

    public function new(?value:Float) {
        intPart = [0];
        floatPart = [];
        isNegative = false;
        
        if (value != null) {
            fromFloat(value);
        }
    }

    public function fromFloat(f:Float) {
        isNegative = f < 0;
        if (isNegative) f = -f;
        
        var str = Std.string(f);
        var parts = str.split(".");
        
        // Handle integer part
        var intStr = parts[0];
        intPart = [];
        for (i in 0...intStr.length) {
            intPart.push(Std.parseInt(intStr.charAt(i)));
        }
        if (intPart.length == 0) intPart = [0];
        
        // Handle float part
        floatPart = [];
        if (parts.length > 1) {
            var floatStr = parts[1];
            for (i in 0...floatStr.length) {
                floatPart.push(Std.parseInt(floatStr.charAt(i)));
            }
        }
    }

    public function toFloat():Float {
        var str = (isNegative ? "-" : "") + intPart.join("");
        if (floatPart.length > 0) {
            str += "." + floatPart.join("");
        }
        return Std.parseFloat(str);
    }

    public function toString():String {
        var str = (isNegative ? "-" : "") + intPart.join("");
        if (floatPart.length > 0) {
            str += "." + floatPart.join("");
        }
        return str;
    }

    public function clone():YNumber {
        var clone = new YNumber();
        clone.intPart = intPart.copy();
        clone.floatPart = floatPart.copy();
        clone.isNegative = isNegative;
        return clone;
    }

    private function carryOverflow() {
        // Handle float part carry
        var i = floatPart.length - 1;
        while (i >= 0) {
            if (floatPart[i] >= 10) {
                var carry = Math.floor(floatPart[i] / 10);
                floatPart[i] %= 10;
                
                if (i == 0) {
                    // Carry to integer part
                    intPart[intPart.length - 1] += carry;
                } else {
                    floatPart[i - 1] += carry;
                }
            }
            i--;
        }
        
        // Handle integer part carry
        i = intPart.length - 1;
        while (i >= 0) {
            if (intPart[i] >= 10) {
                var carry = Math.floor(intPart[i] / 10);
                intPart[i] %= 10;
                
                if (i == 0) {
                    // Add new digit at the beginning
                    intPart.unshift(carry);
                    // Break to avoid infinite loop after unshift
                    break;
                } else {
                    intPart[i - 1] += carry;
                }
            }
            i--;
        }
    }

    public function add(other:YNumber):YNumber {
        var result = this.clone();
        var otherClone = other.clone();
        
        // Handle signs
        if (result.isNegative != otherClone.isNegative) {
            // Different signs, convert to subtraction
            if (result.isNegative) {
                result.isNegative = false;
                return otherClone.subtract(result);
            } else {
                otherClone.isNegative = false;
                return result.subtract(otherClone);
            }
        }
        
        // Same signs, proceed with addition
        // Pad arrays to same length
        while (result.floatPart.length < otherClone.floatPart.length) result.floatPart.push(0);
        while (otherClone.floatPart.length < result.floatPart.length) otherClone.floatPart.push(0);
        while (result.intPart.length < otherClone.intPart.length) result.intPart.unshift(0);
        while (otherClone.intPart.length < result.intPart.length) otherClone.intPart.unshift(0);
        
        var carry = 0;
        
        // Add float parts from right to left
        for (i in result.floatPart.length - 1...-1) {
            var sum = result.floatPart[i] + otherClone.floatPart[i] + carry;
            carry = Math.floor(sum / 10);
            result.floatPart[i] = sum % 10;
        }
        
        // Add integer parts from right to left
        for (i in result.intPart.length - 1...-1) {
            var sum = result.intPart[i] + otherClone.intPart[i] + carry;
            carry = Math.floor(sum / 10);
            result.intPart[i] = sum % 10;
        }
        
        if (carry > 0) {
            result.intPart.unshift(carry);
        }
        
        result.carryOverflow();
        return result;
    }

    public function subtract(other:YNumber):YNumber {
        var result = this.clone();
        var otherClone = other.clone();
        
        // Handle signs
        if (result.isNegative != otherClone.isNegative) {
            // Different signs, convert to addition
            otherClone.isNegative = !otherClone.isNegative;
            return result.add(otherClone);
        }
        
        // Same signs, proceed with subtraction
        // Pad arrays to same length
        while (result.floatPart.length < otherClone.floatPart.length) result.floatPart.push(0);
        while (otherClone.floatPart.length < result.floatPart.length) otherClone.floatPart.push(0);
        while (result.intPart.length < otherClone.intPart.length) result.intPart.unshift(0);
        while (otherClone.intPart.length < result.intPart.length) otherClone.intPart.unshift(0);
        
        var borrow = 0;
        
        // Subtract float parts from right to left
        for (i in result.floatPart.length - 1...-1) {
            var diff = result.floatPart[i] - otherClone.floatPart[i] - borrow;
            if (diff < 0) {
                diff += 10;
                borrow = 1;
            } else {
                borrow = 0;
            }
            result.floatPart[i] = diff;
        }
        
        // Subtract integer parts from right to left
        for (i in result.intPart.length - 1...-1) {
            var diff = result.intPart[i] - otherClone.intPart[i] - borrow;
            if (diff < 0) {
                diff += 10;
                borrow = 1;
            } else {
                borrow = 0;
            }
            result.intPart[i] = diff;
        }
        
        // If we still have a borrow, the result should be negative
        if (borrow > 0) {
            result.isNegative = !result.isNegative;
        }
        
        return result;
    }

    public function multiply(other:YNumber):YNumber {
        var result = new YNumber();
        
        // Simple multiplication using float conversion for now
        // Could be optimized with digit-by-digit multiplication later
        var thisFloat = this.toFloat();
        var otherFloat = other.toFloat();
        var product = thisFloat * otherFloat;
        
        result.fromFloat(product);
        return result;
    }

    public function divide(other:YNumber):YNumber {
        var result = new YNumber();
        
        // Simple division using float conversion for now
        // Could be optimized with long division later
        var thisFloat = this.toFloat();
        var otherFloat = other.toFloat();
        var quotient = thisFloat / otherFloat;
        
        result.fromFloat(quotient);
        return result;
    }

    public function negate():YNumber {
        var result = this.clone();
        result.isNegative = !result.isNegative;
        return result;
    }

    public function isZero():Bool {
        for (digit in intPart) {
            if (digit != 0) return false;
        }
        for (digit in floatPart) {
            if (digit != 0) return false;
        }
        return true;
    }
}

// Abstract wrapper for seamless usage
@:forward
abstract YNum(YNumber) from YNumber to YNumber {
    public inline function new(value:Dynamic) {
        if (Std.isOfType(value, YNumber)) {
            this = value;
        } else if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
            this = new YNumber(cast value);
        } else {
            this = new YNumber(0);
        }
    }

    @:from
    public static function fromInt(i:Int):YNum {
        return new YNum(new YNumber(i));
    }

    @:from
    public static function fromFloat(f:Float):YNum {
        return new YNum(new YNumber(f));
    }

    @:to
    public function toInt():Int {
        return Std.int(this.toFloat());
    }

    @:to
    public function toFloat():Float {
        return this.toFloat();
    }

    @:op(A + B)
    public static function add(a:YNum, b:YNum):YNum {
        var aNum:YNumber = a;
        var bNum:YNumber = b;
        return new YNum(aNum.add(bNum));
    }

    @:op(A - B)
    public static function subtract(a:YNum, b:YNum):YNum {
        var aNum:YNumber = a;
        var bNum:YNumber = b;
        return new YNum(aNum.subtract(bNum));
    }

    @:op(A * B)
    public static function multiply(a:YNum, b:YNum):YNum {
        var aNum:YNumber = a;
        var bNum:YNumber = b;
        return new YNum(aNum.multiply(bNum));
    }

    @:op(A / B)
    public static function divide(a:YNum, b:YNum):YNum {
        var aNum:YNumber = a;
        var bNum:YNumber = b;
        return new YNum(aNum.divide(bNum));
    }

    @:op(-A)
    public static function negate(a:YNum):YNum {
        var aNum:YNumber = a;
        return new YNum(aNum.negate());
    }

    @:op(A == B)
    public static function equals(a:YNum, b:YNum):Bool {
        var aNum:YNumber = a;
        var bNum:YNumber = b;
        var diff = aNum.subtract(bNum);
        return diff.isZero();
    }

    public function toString():String {
        return this.toString();
    }
}
