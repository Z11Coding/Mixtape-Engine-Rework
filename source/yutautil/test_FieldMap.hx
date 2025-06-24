package yutautil;

import yutautil.FieldMap;
import haxe.ds.StringMap;
import utest.Assert;
import utest.Test;

class test_FieldMap extends Test {
    public function test_getFields_withObject() {
        var obj = { foo: 42, bar: "baz" };
        var fmap = new FieldMap(obj);
        var fields = fmap.getFields();
        var names = [for (f in fields) f.name];
        Assert.isTrue(names.indexOf("foo") != -1);
        Assert.isTrue(names.indexOf("bar") != -1);
        Assert.equals(42, fields.filter(f -> f.name == "foo")[0].value);
        Assert.equals("baz", fields.filter(f -> f.name == "bar")[0].value);
    }

    public function test_getFields_withArray() {
        var arr = [1, 2, 3];
        var fmap = new FieldMap(arr);
        var fields = fmap.getFields();
        Assert.equals(3, fields.length);
        Assert.equals(1, fields[0].value);
        Assert.equals("0", fields[0].name);
    }

    public function test_getFields_withStringMap() {
        var smap = new StringMap<Int>();
        smap.set("a", 10);
        smap.set("b", 20);
        var fmap = new FieldMap(smap);
        var fields = fmap.getFields();
        var names = [for (f in fields) f.name];
        Assert.isTrue(names.indexOf("a") != -1);
        Assert.isTrue(names.indexOf("b") != -1);
        Assert.equals(10, fields.filter(f -> f.name == "a")[0].value);
        Assert.equals(20, fields.filter(f -> f.name == "b")[0].value);
    }

    public function test_getFields_withNull() {
        var fmap = new FieldMap(null);
        var fields = fmap.getFields();
        Assert.equals(0, fields.length);
    }

    public function test_getFields_withClassInstance() {
        class Dummy {
            public var x:Int = 5;
            public var y:String = "hi";
            public function new() {}
            public function foo() return 123;
        }
        var dummy = new Dummy();
        var fmap = new FieldMap(dummy);
        var fields = fmap.getFields();
        var names = [for (f in fields) f.name];
        Assert.isTrue(names.indexOf("x") != -1);
        Assert.isTrue(names.indexOf("y") != -1);
        Assert.isTrue(names.indexOf("foo") != -1);
        Assert.equals(5, fields.filter(f -> f.name == "x")[0].value);
        Assert.equals("hi", fields.filter(f -> f.name == "y")[0].value);
        Assert.isTrue(Reflect.isFunction(fields.filter(f -> f.name == "foo")[0].value));
    }
}