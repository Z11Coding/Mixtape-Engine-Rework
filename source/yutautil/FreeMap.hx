package yutautil;

import haxe.ds.StringMap;

import haxe.crypto.Sha1;

enum IterationType {
    Keys;
    Values;
    KeyValuePairs;
}

class FreeMap<K, V> {
    private var internalMap: StringMap<V>;

    public function new() {
        internalMap = new StringMap<V>();
    }

    public function set(key: K, value: V): Void {
        var stringKey = keyToString(key);
        internalMap.set(stringKey, value);
    }

    public function get(key: K): Null<V> {
        var stringKey = keyToString(key);
        return internalMap.get(stringKey);
    }

    public function exists(key: K): Bool {
        var stringKey = keyToString(key);
        return internalMap.exists(stringKey);
    }

    public function remove(key: K): Bool {
        var stringKey = keyToString(key);
        return internalMap.remove(stringKey);
    }

    public function iterate(): Array<V> {
        var result = [];
        var it = internalMap.iterator();
        while (it.hasNext()) {
            result.push(it.next());
        }
        return result;
    }

    public function iterateFor(type: IterationType): Iterable<Dynamic> {
        return switch (type) {
            case IterationType.Keys:
                internalMap.keys();
            case IterationType.Values:
                internalMap.iterator();
            case IterationType.KeyValuePairs:
                var mapping = {};
                for (key in internalMap.keys()) {
                    mapping[key] = internalMap.get(key);
                }
                mapping;
        };
    }

    private function keyToString(key: K): String {
        switch (key) {
            case true: 
                return "true-" + Std.string(Lambda.array(internalMap.keys().toArray()).filter(k -> k.startsWith("true-")).length);
            case false: 
                return "false-" + Std.string(Lambda.array(internalMap.keys().toArray()).filter(k -> k.startsWith("false-")).length);
            case _: 
                if (Std.is(key, String) || Std.is(key, Int) || Std.is(key, Float) || Std.is(key, Bool)) {
                    return Std.string(key);
                } else {
                    return Sha1.encode(haxe.Json.stringify(key));
                }
        }
    }
}