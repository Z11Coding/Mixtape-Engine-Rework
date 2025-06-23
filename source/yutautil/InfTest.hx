package yutautil;

import yutautil.Inf;
import utest.Test;
import utest.Assert;
import utest.Runner;

class TestInf extends Test {
    public function testInfValue() {
        Assert.isTrue(Inf.isInfinity(Inf.value));
        Assert.isFalse(Inf.isFinite(Inf.value));
        Assert.isTrue(Inf.isFinite(1.0));
        Assert.isFalse(Inf.isInfinity(1.0));
    }

    public function testInfNumFromFloatAndToFloat() {
        var n = new InfNum(123.456);
        Assert.equals(123.456, n.toFloat());
        Assert.equals("123.456", n.toString());
    }

    public function testInfNumClone() {
        var n = new InfNum(42.5);
        var c = n.clone();
        Assert.equals(n.toString(), c.toString());
        Assert.equals(n.toFloat(), c.toFloat());
        Assert.equals(n.isNegative, c.isNegative);
    }

    public function testInfNumAdd() {
        var a = new InfNum(12.34);
        var b = new InfNum(56.78);
        var sum = a.add(b);
        Assert.equals(12.34 + 56.78, sum.toFloat());
    }

    public function testInfNumSubtract() {
        var a = new InfNum(100.5);
        var b = new InfNum(50.25);
        var diff = a.subtract(b);
        Assert.equals(100.5 - 50.25, diff.toFloat());
    }

    public function testInfNumMultiply() {
        var a = new InfNum(3.5);
        var b = new InfNum(2.0);
        var prod = a.multiply(b);
        Assert.equals(3.5 * 2.0, prod.toFloat());
    }

    public function testInfNumDivide() {
        var a = new InfNum(10.0);
        var b = new InfNum(4.0);
        var div = a.divide(b);
        Assert.equals(10.0 / 4.0, div.toFloat());
    }

    public function testInfNumNegate() {
        var n = new InfNum(5.5);
        var neg = n.negate();
        Assert.equals(-5.5, neg.toFloat());
        Assert.isTrue(neg.isNegative);
    }

    public function testInfNumIsZero() {
        var n = new InfNum(0.0);
        Assert.isTrue(n.isZero());
        var m = new InfNum(1.0);
        Assert.isFalse(m.isZero());
    }

    public function testNumAbstract() {
        var a:Num = 7.5;
        var b:Num = 2.5;
        Assert.equals(10.0, (a + b).toFloat());
        Assert.equals(5.0, (a - b).toFloat());
        Assert.equals(18.75, (a * b).toFloat());
        Assert.equals(3.0, (a / b).toFloat());
    }
}

class TestMain {
    static function main() {
        Runner.run([TestInf]);
    }
}