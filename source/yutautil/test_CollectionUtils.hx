package yutautil;

import yutautil.CollectionUtils.KeyIndexedArray;
import utest.Test;
import utest.Assert;
import utest.Runner;

class test_CollectionUtils extends Test {
    public function test_basicGetSet() {
        var arr = new KeyIndexedArray<String, Int>(["a", "b"], [1, 2]);
        Assert.equals(1, arr["a"]);
        Assert.equals(2, arr["b"]);
        Assert.equals(null, arr["c"]);
    }

    public function test_setExistingKey() {
        var arr = new KeyIndexedArray<String, Int>(["x"], [10]);
        arr["x"] = 42;
        Assert.equals(42, arr["x"]);
    }

    public function test_setNewKey() {
        var arr = new KeyIndexedArray<String, Int>([], []);
        arr["foo"] = 7;
        Assert.equals(7, arr["foo"]);
        Assert.equals(1, arr.keys.length);
        Assert.equals(1, arr.values.length);
    }

    public function test_multipleKeys() {
        var arr = new KeyIndexedArray<Int, String>([1, 2], ["one", "two"]);
        arr[3] = "three";
        Assert.equals("one", arr[1]);
        Assert.equals("two", arr[2]);
        Assert.equals("three", arr[3]);
        Assert.equals(null, arr[4]);
    }

    public function test_overwriteValue() {
        var arr = new KeyIndexedArray<String, String>(["k"], ["v"]);
        arr["k"] = "new";
        Assert.equals("new", arr["k"]);
    }

    public static function main() {
        Runner.run([test_CollectionUtils]);
    }
}