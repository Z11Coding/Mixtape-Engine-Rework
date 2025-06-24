package yutautil;

import yutautil.Tracked;
import utest.Test;
import utest.Assert;
import utest.Runner;

class TestTracked extends Test {
    public function testSetAndGet() {
        var tracked = new Tracked<Int>(10);
        Assert.equals(10, tracked.get());
        tracked.set(20);
        Assert.equals(20, tracked.get());
    }

    public function testCallbackOnSet() {
        var tracked = new Tracked<String>("foo");
        var called = false;
        tracked.addCallback((event, value, field, oldValue, newValue) -> {
            if (event == "set" && oldValue == "foo" && newValue == "bar") called = true;
        });
        tracked.set("bar");
        Assert.isTrue(called);
    }

    public function testCallbackOnGet() {
        var tracked = new Tracked<Float>(3.14);
        var called = false;
        tracked.addCallback((event, value, field, oldValue, newValue) -> {
            if (event == "get") called = true;
        });
        tracked.get();
        Assert.isTrue(called);
    }

    public function testUpdateField() {
        var obj = { a: 1, b: 2 };
        var tracked = new Tracked(obj);
        var fieldUpdated = false;
        tracked.addCallback((event, value, field, oldValue, newValue) -> {
            if (event == "fieldUpdate" && field == "a" && oldValue == 1 && newValue == 42) fieldUpdated = true;
        });
        tracked.updateField("a", 42);
        Assert.equals(42, tracked.get().a);
        Assert.isTrue(fieldUpdated);
    }

    public function testRemoveCallback() {
        var tracked = new Tracked<Int>(5);
        var called = false;
        var cb = (event, value, field, oldValue, newValue) -> called = true;
        tracked.addCallback(cb);
        tracked.removeCallback(cb);
        tracked.set(6);
        Assert.isFalse(called);
    }
}

class TestMain {
    static function main() {
        var runner = new Runner();
        runner.addCase(new TestTracked());
        runner.run();
    }
}