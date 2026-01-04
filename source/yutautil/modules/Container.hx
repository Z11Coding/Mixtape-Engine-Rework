package yutautil.modules;

import flixel.FlxBasic;
import flixel.group.*;
import haxe.ds.*;
import yutautil.CollectionUtils.DynamicMap;
import yutautil.CollectionUtils.KeyIndexedArray;
import yutautil.FreeMap;
import yutautil.Table.DTable;
import yutautil.Table.HTable;
import yutautil.Threader.ThreadQueue;

// ===== STRUCTURAL CONTAINER TYPEDEFS =====
// These allow implicit typing like Haxe's Iterable<T>

/**
 * FlxGroup-style container with members array and length
 */
typedef FlxGroupLike<T> = {
    var members:Array<T>;
    var length:Int;
    @:optional function add(item:T):Void;
    @:optional function remove(item:T):Dynamic;
}

/**
 * Array-like container with push/iterator methods
 */
typedef ArrayLike<T> = {
    function push(item:T):Dynamic;
    function iterator():Iterator<T>;
    @:optional var length:Int;
    @:optional function remove(item:T):Bool;
}

/**
 * Collection-like container with add/remove/iterator
 */
typedef CollectionLike<T> = {
    function add(item:T):Dynamic;
    function remove(item:T):Bool;
    function iterator():Iterator<T>;
    @:optional var length:Int;
    @:optional function clear():Void;
}

/**
 * Minimal iterable container with just iterator and length
 */
typedef IterableLike<T> = {
    function iterator():Iterator<T>;
    var length:Int;
}

/**
 * Queue-like container with length property
 */
typedef QueueLike<T> = {
    var length:Int;
    function add(item:T):Dynamic;
    @:optional function push(item:T):Dynamic;
    @:optional function pop():T;
    @:optional function iterator():Iterator<T>;
}

/**
 * A universal container abstract that works with all collection types and auto-detects container-like objects.
 * Supports Array, Vector, List, all Map types, Flixel Groups, YutaUtil containers, and structural typing.
 *
 * Examples of structural typing (similar to Haxe's Iterable<T>):
 * ```haxe
 * // These will automatically work as Container<T>:
 * var customGroup = { members: [], length: 0 };  // FlxGroupLike
 * var customArray = { push: function(x) {}, iterator: function() {} };  // ArrayLike
 * var customCollection = { add: function(x) {}, remove: function(x) {}, iterator: function() {} };  // CollectionLike
 * var customIterable = { iterator: function() {}, length: 5 };  // IterableLike
 * var customQueue = { length: 0, add: function(x) {} };  // QueueLike
 *
 * var container:Container<String> = customGroup;  // Implicit conversion!
 * container.add("item");  // Works automatically
 * ```
 */
abstract Container<T>(Dynamic) from Dynamic to Dynamic {

    public inline function new() {
        this = [];
    }

    // ===== @:from CONVERSIONS =====

    @:from public static inline function fromArray<T>(array:Array<T>):Container<T> {
        var c:Container<T> = cast array;
        return c;
    }

    @:from public static inline function fromVector<T>(vector:Vector<T>):Container<T> {
        var c:Container<T> = cast vector;
        return c;
    }

    @:from public static inline function fromList<T>(list:List<T>):Container<T> {
        var c:Container<T> = cast list;
        return c;
    }

    @:from public static inline function fromMap<T>(map:Map<Dynamic, T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromStringMap<T>(map:StringMap<T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromIntMap<T>(map:IntMap<T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromObjectMap<T>(map:ObjectMap<Dynamic, T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromEnumValueMap<T>(map:EnumValueMap<Dynamic, T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromFlxGroup<T>(group:FlxGroup):Container<T> {
        var c:Container<T> = cast group;
        return c;
    }

    @:from public static inline function fromFlxTypedGroup<T>(group:FlxTypedGroup<T>):Container<T> {
        var c:Container<T> = cast group;
        return c;
    }

    @:from public static inline function fromFlxContainer<T>(container:FlxTypedContainer<T>):Container<T> {
        var c:Container<T> = cast container;
        return c;
    }

    @:from public static inline function fromDTable<T>(table:DTable<T>):Container<T> {
        var c:Container<T> = cast table;
        return c;
    }

    @:from public static inline function fromHTable<T>(table:HTable<T>):Container<T> {
        var c:Container<T> = cast table;
        return c;
    }

    @:from public static inline function fromKeyIndexedArray<T>(array:KeyIndexedArray<Dynamic, T>):Container<T> {
        var c:Container<T> = cast array;
        return c;
    }

    @:from public static inline function fromDynamicMap<T>(map:DynamicMap<Dynamic, T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromFreeMap<T>(map:FreeMap<Dynamic, T>):Container<T> {
        var c:Container<T> = cast map;
        return c;
    }

    @:from public static inline function fromThreadQueue(queue:ThreadQueue):Container<() -> Void> {
        var c:Container<() -> Void> = cast queue;
        return c;
    }

    // ===== STRUCTURAL @:from CONVERSIONS =====

    @:from public static inline function fromFlxGroupLike<T>(groupLike:FlxGroupLike<T>):Container<T> {
        var c:Container<T> = cast groupLike;
        return c;
    }

    @:from public static inline function fromArrayLike<T>(arrayLike:ArrayLike<T>):Container<T> {
        var c:Container<T> = cast arrayLike;
        return c;
    }

    @:from public static inline function fromCollectionLike<T>(collectionLike:CollectionLike<T>):Container<T> {
        var c:Container<T> = cast collectionLike;
        return c;
    }

    @:from public static inline function fromIterableLike<T>(iterableLike:IterableLike<T>):Container<T> {
        var c:Container<T> = cast iterableLike;
        return c;
    }

    @:from public static inline function fromQueueLike<T>(queueLike:QueueLike<T>):Container<T> {
        var c:Container<T> = cast queueLike;
        return c;
    }

    // ===== @:to CONVERSIONS =====

    @:to public inline function toArray():Array<T> {
        return convertToArray();
    }

    @:to public inline function toVector():Vector<T> {
        var arr = convertToArray();
        return Vector.fromArrayCopy(arr);
    }

    @:to public inline function toList():List<T> {
        var list = new List<T>();
        forEach(function(item) list.add(item));
        return list;
    }

    @:to public inline function toMap():Map<String, T> {
        var map = new Map<String, T>();
        forEachWithIndex(function(item, index) map.set(Std.string(index), item));
        return map;
    }

    // ===== CONTAINER INTERFACE =====

    /**
     * Add an item to the container
     */
    public function add(item:T):Container<T> {
        if (isArray()) {
            cast(this, Array<Dynamic>).push(item);
        } else if (isVector()) {
            // Vectors have fixed size, so convert to array first
            var vec:Vector<T> = cast(this, Vector<Dynamic>);
            var arr = [for (i in 0...vec.length) vec[i]];
            arr.push(item);
            this = Vector.fromArrayCopy(arr);
        } else if (isList()) {
            cast(this, List<Dynamic>).add(item);
        } else if (isMap()) {
            // For maps, use item's string representation as key
            cast(this, Map<String, Dynamic>).set(Std.string(item), item);
        } else if (isFlxGroup()) {
            cast(this, FlxGroup).add(cast item);
        } else if (isFlxTypedGroup()) {
            cast(this, FlxTypedGroup<Dynamic>).add(item);
        } else if (isDTable()) {
            // For tables, we'd need row/col coordinates - use linear indexing
            var table:DTable<T> = cast(this, DTable<Dynamic>);
            var linearIndex = getLinearLength();
            var row = Math.floor(linearIndex / table.cols);
            var col = linearIndex % table.cols;
            if (row < table.rows && col < table.cols) {
                table.setCell(row, col, item);
            }
        } else if (isHTable()) {
            var table:HTable<T> = cast(this, HTable<Dynamic>);
            var linearIndex = getLinearLength();
            var row = Math.floor(linearIndex / table.cols);
            var col = linearIndex % table.cols;
            if (row < table.rows && col < table.cols) {
                table.setCell(row, col, item);
            }
        } else if (isKeyIndexedArray()) {
            cast(this, KeyIndexedArray<String, Dynamic>).set(Std.string(item), item);
        } else if (isDynamicMap()) {
            cast(this, DynamicMap<String, Dynamic>).set(Std.string(item), item);
        } else if (isFreeMap()) {
            cast(this, FreeMap<String, Dynamic>).set(Std.string(item), item);
        } else if (isThreadQueue() && Std.is(item, Function)) {
            cast(this, ThreadQueue).add(cast item);
        } else if (isFlxGroupLike() || isArrayLike() || isCollectionLike() || isQueueLike()) {
            // Try structural add
            tryStructuralAdd(item);
        } else {
            throw "Cannot add to unsupported container type: " + Type.typeof(this);
        }
        return cast this;
    }

    /**
     * Remove an item from the container
     */
    public function remove(item:T):Bool {
        if (isArray()) {
            return cast(this, Array<Dynamic>).remove(item);
        } else if (isVector()) {
            // Vectors are immutable, convert to array
            var vec:Vector<T> = cast(this, Vector<Dynamic>);
            var arr = [for (i in 0...vec.length) vec[i]];
            var removed = arr.remove(item);
            this = Vector.fromArrayCopy(arr);
            return removed;
        } else if (isList()) {
            return cast(this, List<Dynamic>).remove(item);
        } else if (isMap()) {
            var map:Map<String, T> = cast this;
            for (key in map.keys()) {
                if (map.get(key) == item) {
                    return map.remove(key);
                }
            }
            return false;
        } else if (isFlxGroup()) {
            var group:FlxGroup = cast this;
            group.remove(cast item);
            return true;
        } else if (isFlxTypedGroup()) {
            var group:FlxTypedGroup<T> = cast this;
            return group.remove(item) != null;
        } else if (isKeyIndexedArray()) {
            var kia:KeyIndexedArray<String, T> = cast this;
            for (key in kia.keysArray()) {
                if (kia.get(key) == item) {
                    return kia.remove(key);
                }
            }
            return false;
        } else if (isDynamicMap()) {
            var dm:DynamicMap<String, T> = cast(this, DynamicMap<String, Dynamic>);
            for (key in dm.keysArray()) {
                if (dm.get(key) == item) {
                    return dm.remove(key);
                }
            }
            return false;
        } else if (isFlxGroupLike() || isArrayLike() || isCollectionLike()) {
            return tryStructuralRemove(item);
        }

        throw "Cannot remove from unsupported container type: " + Type.typeof(this);
    }

    /**
     * Array access - get item by index
     */
    @:arrayAccess
    public function get(index:Int):Null<T> {
        if (isArray()) {
            var arr:Array<T> = cast this;
            return index >= 0 && index < arr.length ? arr[index] : null;
        } else if (isVector()) {
            var vec:Vector<T> = cast(this, Vector<Dynamic>);
            return index >= 0 && index < vec.length ? vec[index] : null;
        } else if (isList()) {
            var list:List<T> = cast(this, List<Dynamic>);
            var i = 0;
            for (item in list) {
                if (i == index) return item;
                i++;
            }
            return null;
        } else if (isMap()) {
            // For maps, treat index as string key
            return cast(this, Map<String, Dynamic>).get(Std.string(index));
        } else if (isFlxGroup()) {
            var group:FlxGroup = cast this;
            return index >= 0 && index < group.members.length ? cast group.members[index] : null;
        } else if (isFlxTypedGroup()) {
            var group:FlxTypedGroup<T> = cast this;
            return index >= 0 && index < group.members.length ? group.members[index] : null;
        } else if (isDTable()) {
            var table:DTable<Dynamic> = cast this;
            var row = Math.floor(index / table.cols);
            var col = index % table.cols;
            return (row >= 0 && row < table.rows && col >= 0 && col < table.cols) ?
                   table.getCell(row, col) : null;
        } else if (isHTable()) {
            var table:HTable<Dynamic> = cast this;
            var row = Math.floor(index / table.cols);
            var col = index % table.cols;
            return (row >= 0 && row < table.rows && col >= 0 && col < table.cols) ?
                   table.getCellValue(row, col) : null;
        } else if (isKeyIndexedArray()) {
            var kia:KeyIndexedArray<String, T> = cast this;
            var keys = kia.keysArray();
            return index >= 0 && index < keys.length ? kia.get(keys[index]) : null;
        } else if (isFlxGroupLike() || isIterableLike()) {
            return tryStructuralGet(index);
        }

        throw "Cannot get from unsupported container type: " + Type.typeof(this);
    }

    /**
     * Array access - set item by index
     */
    @:arrayAccess
    public function set(index:Int, item:T):T {
        if (isArray()) {
            cast(this, Array<Dynamic>)[index] = item;
        } else if (isVector()) {
            cast(this, Vector<Dynamic>)[index] = item;
        } else if (isMap()) {
            cast(this, Map<String, Dynamic>).set(Std.string(index), item);
        } else if (isFlxGroup()) {
            var group:FlxGroup = cast this;
            if (index >= 0 && index < group.members.length) {
                group.members[index] = cast item;
            }
        } else if (isFlxTypedGroup()) {
            var group:FlxTypedGroup<T> = cast this;
            if (index >= 0 && index < group.members.length) {
                group.members[index] = item;
            }
        } else if (isDTable()) {
            var table:DTable<Dynamic> = cast this;
            var row = Math.floor(index / table.cols);
            var col = index % table.cols;
            if (row >= 0 && row < table.rows && col >= 0 && col < table.cols) {
                table.setCell(row, col, item);
            }
        } else if (isHTable()) {
            var table:HTable<Dynamic> = cast this;
            var row = Math.floor(index / table.cols);
            var col = index % table.cols;
            if (row >= 0 && row < table.rows && col >= 0 && col < table.cols) {
                table.setCell(row, col, item);
            }
        } else if (isKeyIndexedArray()) {
            cast(this, KeyIndexedArray<String, Dynamic>).set(Std.string(index), item);
        } else if (isFlxGroupLike()) {
            tryStructuralSet(index, item);
        } else {
            throw "Cannot set on unsupported container type: " + Type.typeof(this);
        }
        return item;
    }

    /**
     * Get container length/size
     */
    public function length():Int {
        if (isArray()) {
            return cast(this, Array<Dynamic>).length;
        } else if (isVector()) {
            return cast(this, Vector<Dynamic>).length;
        } else if (isList()) {
            return cast(this, List<Dynamic>).length;
        } else if (isMap()) {
            var count = 0;
            for (_ in cast(this, Map<String, Dynamic>).keys()) count++;
            return count;
        } else if (isFlxGroup()) {
            return cast(this, FlxGroup).length;
        } else if (isFlxTypedGroup()) {
            return cast(this, FlxTypedGroup<Dynamic>).length;
        } else if (isDTable()) {
            var table:DTable<T> = cast(this, DTable<Dynamic>);
            return table.rows * table.cols;
        } else if (isHTable()) {
            var table:HTable<T> = cast(this, HTable<Dynamic>);
            return table.rows * table.cols;
        } else if (isKeyIndexedArray()) {
            return cast(this, KeyIndexedArray<String, Dynamic>).length();
        } else if (isDynamicMap()) {
            return cast(this, DynamicMap<String, Dynamic>).length();
        } else if (isThreadQueue()) {
            return cast(this, ThreadQueue).length;
        } else if (isFlxGroupLike() || isArrayLike() || isCollectionLike() || isIterableLike() || isQueueLike()) {
            return tryStructuralLength();
        }

        throw "Cannot get length of unsupported container type: " + Type.typeof(this);
    }

    /**
     * Check if container is empty
     */
    public inline function isEmpty():Bool {
        return length() == 0;
    }

    /**
     * Clear all items from container
     */
    public function clear():Container<T> {
        if (isArray()) {
            cast(this, Array<Dynamic>).resize(0);
        } else if (isVector()) {
            this = new Vector<T>(0);
        } else if (isList()) {
            cast(this, List<Dynamic>).clear();
        } else if (isMap()) {
            cast(this, Map<String, Dynamic>).clear();
        } else if (isFlxGroup()) {
            cast(this, FlxGroup).clear();
        } else if (isFlxTypedGroup()) {
            cast(this, FlxTypedGroup<Dynamic>).clear();
        } else if (isKeyIndexedArray()) {
            cast(this, KeyIndexedArray<String, Dynamic>).clear();
        } else if (isDynamicMap()) {
            cast(this, DynamicMap<String, Dynamic>).clear();
        } else if (isFlxGroupLike() || isCollectionLike()) {
            tryStructuralClear();
        } else {
            throw "Cannot clear unsupported container type: " + Type.typeof(this);
        }
        return cast this;
    }

    /**
     * Check if container contains an item
     */
    public function contains(item:T):Bool {
        if (isArray()) {
            return cast(this, Array<Dynamic>).indexOf(item) != -1;
        } else if (isVector()) {
            var vec:Vector<Dynamic> = cast this;
            for (i in 0...vec.length) {
                if (vec[i] == item) return true;
            }
            return false;
        } else if (isList()) {
            for (listItem in cast(this, List<Dynamic>)) {
                if (listItem == item) return true;
            }
            return false;
        } else if (isMap()) {
            var map:Map<String, T> = cast this;
            for (value in map) {
                if (value == item) return true;
            }
            return false;
        } else if (isFlxGroup()) {
            return cast(this, FlxGroup).members.indexOf(cast item) != -1;
        } else if (isFlxTypedGroup()) {
            return cast(this, FlxTypedGroup<Dynamic>).members.indexOf(item) != -1;
        }

        // Fallback: iterate through all items
        for (containerItem in iterator()) {
            if (containerItem == item) return true;
        }
        return false;
    }

    /**
     * Iterate through all items in container
     */
    public function iterator():Iterator<T> {
        if (isArray()) {
            return cast(this, Array<Dynamic>).iterator();
        } else if (isVector()) {
            var vec:Vector<Dynamic> = cast this;
            var arr = [for (i in 0...vec.length) vec[i]];
            return arr.iterator();
        } else if (isList()) {
            return cast(this, List<Dynamic>).iterator();
        } else if (isMap()) {
            return cast(this, Map<String, Dynamic>).iterator();
        } else if (isFlxGroup()) {
            return cast cast(this, FlxGroup).members.iterator();
        } else if (isFlxTypedGroup()) {
            return cast(this, FlxTypedGroup<Dynamic>).iterator();
        } else if (isKeyIndexedArray()) {
            return cast(this, KeyIndexedArray<String, Dynamic>).valuesArray().iterator();
        } else if (isDynamicMap()) {
            return cast(this, DynamicMap<String, Dynamic>).iterator();
        } else if ((isFlxGroupLike() || isArrayLike() || isCollectionLike() || isIterableLike() || isQueueLike()) && tryStructuralIterator() != null) {
            return tryStructuralIterator();
        }

        // Fallback: create array and iterate
        return convertToArray().iterator();
    }

    /**
     * Apply function to each item
     */
    public function forEach(func:T -> Void):Container<T> {
        for (item in iterator()) {
            func(item);
        }
        return cast this;
    }

    /**
     * Apply function to each item with index
     */
    public function forEachWithIndex(func:T -> Int -> Void):Container<T> {
        var index = 0;
        for (item in iterator()) {
            func(item, index);
            index++;
        }
        return cast this;
    }

    /**
     * Map container to new container with transformed items
     */
    public function map<U>(func:T -> U):Container<U> {
        var result = new Array<U>();
        for (item in iterator()) {
            result.push(func(item));
        }
        return cast result;
    }

    /**
     * Filter container to new container with filtered items
     */
    public function filter(predicate:T -> Bool):Container<T> {
        var result = new Array<T>();
        for (item in iterator()) {
            if (predicate(item)) {
                result.push(item);
            }
        }
        return cast result;
    }

    /**
     * Find first item matching predicate
     */
    public function find(predicate:T -> Bool):Null<T> {
        for (item in iterator()) {
            if (predicate(item)) return item;
        }
        return null;
    }

    /**
     * Convert container to Array
     */
    public function convertToArray():Array<T> {
        if (isArray()) {
            return cast this;
        }

        var result = new Array<T>();
        for (item in iterator()) {
            result.push(item);
        }
        return result;
    }

    /**
     * Merge another container into this one
     */
    public function merge(other:Container<T>):Container<T> {
        for (item in other.iterator()) {
            add(item);
        }
        return cast this;
    }

    /**
     * Create a copy of this container
     */
    public function copy():Container<T> {
        var result:Container<T> = new Container<T>();
        for (item in iterator()) {
            result.add(item);
        }
        return result;
    }

    /**
     * Reverse the container (creates new array-based container)
     */
    public function reverse():Container<T> {
        var arr = convertToArray();
        arr.reverse();
        return cast arr;
    }

    /**
     * Sort the container (creates new array-based container)
     */
    public function sort(compareFunc:T -> T -> Int):Container<T> {
        var arr = convertToArray();
        arr.sort(compareFunc);
        return cast arr;
    }

    /**
     * Get first item in container
     */
    public function first():Null<T> {
        for (item in iterator()) {
            return item;
        }
        return null;
    }

    /**
     * Get last item in container
     */
    public function last():Null<T> {
        if (isArray()) {
            var arr:Array<T> = cast(this, Array<Dynamic>);
            return arr.length > 0 ? arr[arr.length - 1] : null;
        }

        var lastItem:Null<T> = null;
        for (item in iterator()) {
            lastItem = item;
        }
        return lastItem;
    }

    /**
     * Pop (remove and return) last item
     */
    public function pop():Null<T> {
        if (isArray()) {
            return cast(this, Array<Dynamic>).pop();
        } else if (isList()) {
            return cast(this, List<Dynamic>).pop();
        } else if (isKeyIndexedArray()) {
            var kia:KeyIndexedArray<String, T> = cast(this, KeyIndexedArray<String, Dynamic>);
            var popped = kia.pop();
            return popped != null ? popped.value : null;
        } else if ((isArrayLike() || isQueueLike()) && Reflect.hasField(this, "pop")) {
            return Reflect.callMethod(this, Reflect.field(this, "pop"), []);
        }

        // Fallback: remove last item manually
        var lastItem = last();
        if (lastItem != null) {
            remove(lastItem);
        }
        return lastItem;
    }

    /**
     * Push item to end of container
     */
    public function push(item:T):Container<T> {
        add(item);
        return cast this;
    }

    /**
     * Shift (remove and return) first item
     */
    public function shift():Null<T> {
        if (isArray()) {
            return cast(this, Array<Dynamic>).shift();
        } else if (isList()) {
            return cast(this, List<Dynamic>).pop(); // List.pop() removes from front
        }

        // Fallback: remove first item manually
        var firstItem = first();
        if (firstItem != null) {
            remove(firstItem);
        }
        return firstItem;
    }

    /**
     * Unshift (add item to beginning)
     */
    public function unshift(item:T):Container<T> {
        if (isArray()) {
            cast(this, Array<Dynamic>).unshift(item);
        } else if (isList()) {
            cast(this, List<Dynamic>).push(item); // List.push() adds to front
        } else {
            // For other containers, we'll add normally (no guaranteed order)
            add(item);
        }
        return cast this;
    }

    /**
     * Reduce container to single value
     */
    public function reduce<U>(func:U -> T -> U, initialValue:U):U {
        var accumulator = initialValue;
        for (item in iterator()) {
            accumulator = func(accumulator, item);
        }
        return accumulator;
    }

    /**
     * Check if any item matches predicate
     */
    public function any(predicate:T -> Bool):Bool {
        for (item in iterator()) {
            if (predicate(item)) return true;
        }
        return false;
    }

    /**
     * Check if all items match predicate
     */
    public function all(predicate:T -> Bool):Bool {
        for (item in iterator()) {
            if (!predicate(item)) return false;
        }
        return true;
    }

    /**
     * Count items matching predicate
     */
    public function count(predicate:T -> Bool = null):Int {
        if (predicate == null) {
            return length();
        }

        var count = 0;
        for (item in iterator()) {
            if (predicate(item)) count++;
        }
        return count;
    }

    /**
     * Get unique items (creates new array-based container)
     */
    public function unique():Container<T> {
        var result = new Array<T>();
        var seen = new Map<String, Bool>();

        for (item in iterator()) {
            var key = Std.string(item);
            if (!seen.exists(key)) {
                seen.set(key, true);
                result.push(item);
            }
        }

        return cast result;
    }

    /**
     * Slice container (creates new array-based container)
     */
    public function slice(start:Int, ?end:Int):Container<T> {
        var arr = convertToArray();
        return cast arr.slice(start, end);
    }

    /**
     * Splice container (modifies if array, otherwise creates copy)
     */
    public function splice(pos:Int, len:Int, ?items:Array<T>):Container<T> {
        if (isArray()) {
            var arr:Array<T> = cast this;
            if (items != null) {
                for (i in 0...items.length) {
                    arr.insert(pos + i, items[i]);
                }
            }
            if (len > 0) {
                for (i in 0...len) {
                    if (pos < arr.length) {
                        arr.splice(pos, 1);
                    }
                }
            }
            return cast this;
        } else {
            // For non-arrays, create a new array and splice that
            var arr = convertToArray();
            arr.splice(pos, len);
            if (items != null) {
                for (i in 0...items.length) {
                    arr.insert(pos + i, items[i]);
                }
            }
            return cast arr;
        }
    }

    /**
     * Concatenate with another container (creates new array-based container)
     */
    public function concat(other:Container<T>):Container<T> {
        var result = convertToArray();
        for (item in other.iterator()) {
            result.push(item);
        }
        return cast result;
    }

    /**
     * Join items to string
     */
    public function join(separator:String = ","):String {
        var parts = new Array<String>();
        for (item in iterator()) {
            parts.push(Std.string(item));
        }
        return parts.join(separator);
    }

    // ===== TYPE DETECTION =====

    private inline function isArray():Bool {
        return Std.is(this, Array);
    }

    private inline function isVector():Bool {
        return Std.is(this, Vector);
    }

    private inline function isList():Bool {
        return Std.is(this, List);
    }

    private inline function isMap():Bool {
        return Std.is(this, Map) || Std.is(this, StringMap) ||
               Std.is(this, IntMap) || Std.is(this, ObjectMap) ||
               Std.is(this, EnumValueMap);
    }

    private inline function isFlxGroup():Bool {
        return Std.is(this, FlxGroup);
    }

    private inline function isFlxTypedGroup():Bool {
        return Std.is(this, FlxTypedGroup);
    }

    private inline function isDTable():Bool {
        return Std.is(this, DTable);
    }

    private inline function isHTable():Bool {
        return Std.is(this, HTable);
    }

    private inline function isKeyIndexedArray():Bool {
        return Std.is(this, KeyIndexedArray);
    }

    private inline function isDynamicMap():Bool {
        return Std.is(this, DynamicMap);
    }

    private inline function isFreeMap():Bool {
        return Std.is(this, FreeMap);
    }

    private inline function isThreadQueue():Bool {
        return Std.is(this, ThreadQueue);
    }

    /**
     * Auto-detect container-like objects using typedef-based structural typing
     * Similar to how Haxe handles Iterable<T> and other structural types
     */
    private inline function isFlxGroupLike():Bool {
        return (this != null &&
                Reflect.hasField(this, "members") &&
                Reflect.hasField(this, "length") &&
                Std.is(Reflect.field(this, "members"), Array));
    }

    private inline function isArrayLike():Bool {
        return (this != null &&
                Reflect.hasField(this, "push") &&
                Reflect.hasField(this, "iterator") &&
                Reflect.isFunction(Reflect.field(this, "push")) &&
                Reflect.isFunction(Reflect.field(this, "iterator")));
    }

    private inline function isCollectionLike():Bool {
        return (this != null &&
                Reflect.hasField(this, "add") &&
                Reflect.hasField(this, "remove") &&
                Reflect.hasField(this, "iterator") &&
                Reflect.isFunction(Reflect.field(this, "add")) &&
                Reflect.isFunction(Reflect.field(this, "remove")) &&
                Reflect.isFunction(Reflect.field(this, "iterator")));
    }

    private inline function isIterableLike():Bool {
        return (this != null &&
                Reflect.hasField(this, "iterator") &&
                Reflect.hasField(this, "length") &&
                Reflect.isFunction(Reflect.field(this, "iterator")));
    }

    private inline function isQueueLike():Bool {
        return (this != null &&
                Reflect.hasField(this, "length") &&
                Reflect.hasField(this, "add") &&
                Reflect.isFunction(Reflect.field(this, "add")));
    }

    // ===== STRUCTURAL CONTAINER HELPERS =====

    private function tryStructuralAdd(item:T):Void {
        if (isCollectionLike() && Reflect.hasField(this, "add")) {
            Reflect.callMethod(this, Reflect.field(this, "add"), [item]);
        } else if (isArrayLike() && Reflect.hasField(this, "push")) {
            Reflect.callMethod(this, Reflect.field(this, "push"), [item]);
        } else if (isQueueLike() && Reflect.hasField(this, "add")) {
            Reflect.callMethod(this, Reflect.field(this, "add"), [item]);
        } else if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            cast(Reflect.field(this, "members"), Array<Dynamic>).push(item);
        } else if (isFlxGroupLike() && Reflect.hasField(this, "add")) {
            Reflect.callMethod(this, Reflect.field(this, "add"), [item]);
        } else {
            throw "Structural container doesn't support adding items";
        }
    }

    private function tryStructuralRemove(item:T):Bool {
        if ((isCollectionLike() || isFlxGroupLike()) && Reflect.hasField(this, "remove")) {
            var result = Reflect.callMethod(this, Reflect.field(this, "remove"), [item]);
            return result != null ? (Std.is(result, Bool) ? result : true) : false;
        } else if (isArrayLike() && Reflect.hasField(this, "remove")) {
            var result = Reflect.callMethod(this, Reflect.field(this, "remove"), [item]);
            return result != null ? (Std.is(result, Bool) ? result : true) : false;
        } else if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            return cast(Reflect.field(this, "members"), Array<Dynamic>).remove(item);
        }
        return false;
    }

    private function tryStructuralGet(index:Int):Null<T> {
        if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            var members:Array<Dynamic> = cast Reflect.field(this, "members");
            return index >= 0 && index < members.length ? members[index] : null;
        } else if (isIterableLike()) {
            // For other iterable types, iterate to find the index
            var i = 0;
            for (item in cast(this, IterableLike<T>).iterator()) {
                if (i == index) return item;
                i++;
            }
        }
        return null;
    }

    private function tryStructuralSet(index:Int, item:T):Void {
        if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            var members:Array<Dynamic> = cast Reflect.field(this, "members");
            if (index >= 0 && index < members.length) {
                members[index] = item;
            }
        }
    }

    private function tryStructuralLength():Int {
        if (Reflect.hasField(this, "length")) {
            var lengthField = Reflect.field(this, "length");
            if (Std.is(lengthField, Int)) {
                return lengthField;
            } else if (Reflect.isFunction(lengthField)) {
                return Reflect.callMethod(this, lengthField, []);
            }
        }
        if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            return cast(Reflect.field(this, "members"), Array<Dynamic>).length;
        }
        return 0;
    }

    private function tryStructuralClear():Void {
        if (isCollectionLike() && Reflect.hasField(this, "clear")) {
            Reflect.callMethod(this, Reflect.field(this, "clear"), []);
        } else if (isFlxGroupLike() && Reflect.hasField(this, "clear")) {
            Reflect.callMethod(this, Reflect.field(this, "clear"), []);
        } else if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            cast(Reflect.field(this, "members"), Array<Dynamic>).resize(0);
        }
    }

    private function tryStructuralIterator():Null<Iterator<T>> {
        if ((isArrayLike() || isCollectionLike() || isIterableLike()) && Reflect.hasField(this, "iterator")) {
            return Reflect.callMethod(this, Reflect.field(this, "iterator"), []);
        } else if (isFlxGroupLike() && Reflect.hasField(this, "members")) {
            return cast(Reflect.field(this, "members"), Array<Dynamic>).iterator();
        } else if (isQueueLike() && Reflect.hasField(this, "iterator")) {
            return Reflect.callMethod(this, Reflect.field(this, "iterator"), []);
        }
        return null;
    }

    private function getLinearLength():Int {
        // Helper for table operations
        var count = 0;
        try {
            for (_ in iterator()) count++;
        } catch (e:Dynamic) {
            return 0;
        }
        return count;
    }

    /**
     * Get string representation of container
     */
    public function toString():String {
        var typeName = Type.typeof(this);
        var items = [];
        var count = 0;
        for (item in iterator()) {
            if (count < 5) { // Show first 5 items
                items.push(Std.string(item));
            } else {
                items.push("...");
                break;
            }
            count++;
        }
        return 'Container<$typeName>[${items.join(", ")}] (${length()} items)';
    }
}
