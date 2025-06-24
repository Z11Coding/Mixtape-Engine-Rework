package yutautil;

import yutautil.OneOrMany;
import utest.Assert;
import utest.Test;

class TestOneOrMany extends Test {
    public function testConstructFromSingleValue() {
        var o = new OneOrMany(42);
        Assert.equals(1, o.toArray().length);
        Assert.equals(42, o.getSingle());
        Assert.isTrue(o.isSingle());
    }

    public function testConstructFromArray() {
        var arr = [1, 2, 3];
        var o:OneOrMany<Int> = arr;
        Assert.equals(3, o.toArray().length);
        Assert.equals(1, o.getSingle());
        Assert.isFalse(o.isSingle());
    }

    public function testFromSingleStatic() {
        var o = OneOrMany.fromSingle("hello");
        Assert.equals(1, o.toArray().length);
        Assert.equals("hello", o.getSingle());
        Assert.isTrue(o.isSingle());
    }

    public function testFromArrayStatic() {
        var arr = ["a", "b"];
        var o = OneOrMany.fromArray(arr);
        Assert.equals(2, o.toArray().length);
        Assert.equals("a", o.getSingle());
        Assert.isFalse(o.isSingle());
    }

    public function testToSingleSuccess() {
        var o = new OneOrMany(99);
        Assert.equals(99, o.toSingle());
    }

    public function testToSingleFailure() {
        var o = new OneOrMany([1, 2]);
        var failed = false;
        try {
            o.toSingle();
        } catch (e:Dynamic) {
            failed = true;
        }
        Assert.isTrue(failed);
    }

    public function testIterator() {
        var o = new OneOrMany([10, 20, 30]);
        var sum = 0;
        for (v in o) sum += v;
        Assert.equals(60, sum);
    }
}