package yutautil;

class CatagorizedMap<T> {

    private var map:Map<String, Array<T>> = new Map();
    private final stuck:Bool = false;
    private final allowDuplicates:Bool = true;

    public var length(get, never):Int;

    public function new(?cat:Array<String>, ?stuck:Bool) {
        if (cat != null) {
            for (c in cat) {
                map.set(c, []);
            }
        }

        if (stuck != null && map != null && map.lengthTo() != 0) {
            this.stuck = stuck;
        }

    }

    public function add(key:String, value:T):Void {
        if (!map.exists(key)) {
            map.set(key, []);
        }
        map.get(key).push(value);
    }

    public function remove(key:String, value:T):Bool {
        if (!map.exists(key)) {
            return false;
        }
        var arr = map.get(key);
        var index = arr.indexOf(value);
        if (index == -1) {
            return false;
        }
        arr.splice(index, 1);
        return true;
    }

    public function get(key:String):Array<T> {
        if (!map.exists(key)) {
            return [];
        }
        return map.get(key);
    }

    public function exists(key:String):Bool {
        return map.exists(key);
    }

    public function clear():Void {
        map = new Map();
    }

    public function clearCategory(key:String):Void {
        if (map.exists(key)) {
            map.set(key, []);
        }
    }

    public function removeCategory(key:String):Bool {
       return map.remove(key);
    }

    public function keys():Iterator<String> {
        return map.keys();
    }

    // public function values():Array<Array<T>> {
    //     return map.iterator().map(function(pair:MapPair<String, Array<T>>):Array<T> {
    //         return pair.value;
    //     });
    // }

    public function iterator():KeyValueIterator<String, Array<T>> {
        return map.keyValueIterator();
    }


    public function next():Dynamic {
        return map.keyValueIterator().next();
    }

    public function hasNext():Bool {
        return map.keyValueIterator().hasNext();
    }

    public function toString():String {
        var result = new StringBuf();
        for (key in map.keys()) {
            result.add(key + ": " + map.get(key).toString() + "\n");
        }
        return result.toString();
    }

    public function get_length():Int {
        return map.lengthTo();
    }

    // public function get(key:String):Array<T> {
    //     return get(key);
    // }

    public function set(key:String, value:Array<T>):Array<T> {
        map.set(key, value);
        return value;
    }

    // public function remove(key:String):Bool {
    //     return map.remove(key);
    // }
}
