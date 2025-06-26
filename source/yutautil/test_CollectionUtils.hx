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
public function test_funcAndReturn_basic() {
    var called = false;
    var result = yutautil.CollectionUtils.funcAndReturn(5, function(x) called = true);
    Assert.isTrue(called);
    Assert.equals(5, result);
}

public function test_funcAndReturn_withArgs() {
    var sum = 0;
    function add(a:Int, b:Int) sum = a + b;
    var result = yutautil.CollectionUtils.funcAndReturn(3, add, [4], true);
    Assert.equals(7, sum);
    Assert.equals(3, result);
}

public function test_funcAndReturn_noArgs() {
    var called = false;
    function f(x:Int) called = true;
    var result = yutautil.CollectionUtils.funcAndReturn(10, f);
    Assert.isTrue(called);
    Assert.equals(10, result);
}

public function test_funcAndReturn_itemIsArg_false() {
    var gotArgs:Array<Dynamic> = [];
    function f(a:Int, b:Int) gotArgs = [a, b];
    var result = yutautil.CollectionUtils.funcAndReturn(2, f, [5], false);
    Assert.equals(5, gotArgs[0]);
    Assert.isNull(gotArgs[1]);
    Assert.equals(2, result);
}

public function test_funcAndReturn_itemIsArg_true() {
    var gotArgs:Array<Dynamic> = [];
    function f(a:Int, b:Int) gotArgs = [a, b];
    var result = yutautil.CollectionUtils.funcAndReturn(2, f, [5], true);
    Assert.equals(2, gotArgs[0]);
    Assert.equals(5, gotArgs[1]);
    Assert.equals(2, result);
}
public function test_FuncAndReturnItem_Item() {
    var item = FuncAndReturnItem.Item;
    switch (item) {
        case Item:
            Assert.isTrue(true);
        case TransformedItem(_,_):
            Assert.fail("Should not be TransformedItem");
    }
}

public function test_FuncAndReturnItem_TransformedItem_noArgs() {
    var called = false;
    function f(x:Int):Int { called = true; return x + 1; }
    var item = FuncAndReturnItem.TransformedItem(f, null);
    switch (item) {
        case Item:
            Assert.fail("Should be TransformedItem");
        case TransformedItem(func, extraArgs):
            var result = func(10);
            Assert.isTrue(called);
            Assert.equals(11, result);
            Assert.isNull(extraArgs);
    }
}

public function test_FuncAndReturnItem_TransformedItem_withArgs() {
    var gotArgs:Array<Dynamic> = [];
    function f(x:Int, y:Int):Int { gotArgs = [x, y]; return x + y; }
    var item = FuncAndReturnItem.TransformedItem(f, [5]);
    switch (item) {
        case Item:
            Assert.fail("Should be TransformedItem");
        case TransformedItem(func, extraArgs):
            var result = Reflect.callMethod(null, func, [2, extraArgs != null && extraArgs.length > 0 ? extraArgs[0] : null]);
            Assert.equals(7, result);
            Assert.equals(2, gotArgs[0]);
            Assert.equals(5, gotArgs[1]);
    }
}

public function test_FuncAndReturnItem_patternMatching() {
    var items = [
        FuncAndReturnItem.Item,
        FuncAndReturnItem.TransformedItem(function(x) return x * 2, null)
    ];
    var results = [];
    for (item in items) {
        switch (item) {
            case Item:
                results.push("item");
            case TransformedItem(func, _):
                results.push(func(3));
        }
    }
    Assert.equals("item", results[0]);
    Assert.equals(6, results[1]);
}

public function test_funcAndReturn_with_FuncAndReturnItem() {
	var called = false;
	function f(x:Int, y:Int) {
		called = true;
		return x + y;
	}
	var item = 10;
	// Use FuncAndReturnItem.TransformedItem as an argument
	var arg = yutautil.CollectionUtils.FuncAndReturnItem.TransformedItem(
		function(x:Int):Int { return x * 2; }, null
	);
	// The resolveArg logic in funcAndReturn should resolve arg to item * 2 = 20
	var result = yutautil.CollectionUtils.funcAndReturn(item, f, [arg], true);
	Assert.isTrue(called);
	// f(10, 20) should be called, but funcAndReturn always returns item
	Assert.equals(10, result);
}