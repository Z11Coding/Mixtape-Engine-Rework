package yutautil;

class Fraction {
    public var numerator:Int;
    public var denominator:Int;

    public function new(numerator:Int, denominator:Int) {
        if (denominator == 0) {
            throw "Denominator cannot be zero.";
        }
        this.numerator = numerator;
        this.denominator = denominator;
        simplify();
    }

    // Simplify the fraction
    private function simplify():Void {
        var gcdValue = gcd(numerator, denominator);
        numerator /= gcdValue;
        denominator /= gcdValue;

        // Ensure the denominator is always positive
        if (denominator < 0) {
            numerator = -numerator;
            denominator = -denominator;
        }
    }

    // Find the greatest common divisor (GCD)
    private static function gcd(a:Int, b:Int):Int {
        return b == 0 ? a : gcd(b, a % b);
    }

    // Add two fractions
    public function add(other:Fraction):Fraction {
        var newNumerator = numerator * other.denominator + other.numerator * denominator;
        var newDenominator = denominator * other.denominator;
        return new Fraction(newNumerator, newDenominator);
    }

    // Subtract two fractions
    public function subtract(other:Fraction):Fraction {
        var newNumerator = numerator * other.denominator - other.numerator * denominator;
        var newDenominator = denominator * other.denominator;
        return new Fraction(newNumerator, newDenominator);
    }

    // Multiply two fractions
    public function multiply(other:Fraction):Fraction {
        var newNumerator = numerator * other.numerator;
        var newDenominator = denominator * other.denominator;
        return new Fraction(newNumerator, newDenominator);
    }

    // Divide two fractions
    public function divide(other:Fraction):Fraction {
        if (other.numerator == 0) {
            throw "Cannot divide by a fraction with a numerator of zero.";
        }
        var newNumerator = numerator * other.denominator;
        var newDenominator = denominator * other.numerator;
        return new Fraction(newNumerator, newDenominator);
    }

    // Convert the fraction to a string
    public function toString():String {
        return denominator == 1 ? Std.string(numerator) : numerator + "/" + denominator;
    }

    // Convert the fraction to a float
    public function toFloat():Float {
        return numerator / denominator;
    }

    // Check equality of two fractions
    public function equals(other:Fraction):Bool {
        return numerator == other.numerator && denominator == other.denominator;
    }
}

