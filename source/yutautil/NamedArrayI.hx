package yutautil;

/**
 * Enum for specifying how to grab items from NamedArrayI
 */
enum GrabType {
    INDEX;
    NAME;
}

/**
 * Object for grabbing items with different methods
 */
typedef ArrayGrabber = {
    var grabber:IDX;
    var type:GrabType;
}

abstract IDX (Dynamic) from Dynamic to Dynamic {
    public inline function new(v:Dynamic) this = v;
    @:from static public inline function fromInt(v:Int):IDX return v;
    @:from static public inline function fromString(v:String):IDX return v;
    @:to public inline function toDynamic():Dynamic return this;

    // Properties to access the underlying value
    public var value(get, never):Dynamic;
    private inline function get_value():Dynamic return this;

    public var isInt(get, never):Bool;
    private inline function get_isInt():Bool return Std.isOfType(this, Int);

    public var isString(get, never):Bool;
    private inline function get_isString():Bool return Std.isOfType(this, String);

    public var asInt(get, never):Int;
    private inline function get_asInt():Int return cast this;

    public var asString(get, never):String;
    private inline function get_asString():String return cast this;
}

abstract Grabber (ArrayGrabber) from ArrayGrabber to ArrayGrabber {
    public inline function new(v:ArrayGrabber) this = v;
    @:from static public inline function fromIndex(v:Int):Grabber return {grabber: v, type: INDEX};
    @:from static public inline function fromName(v:String):Grabber return {grabber: v, type: NAME};
    @:to public inline function toArrayGrabber():ArrayGrabber return this;

    // Properties to access the fields
    public var grabber(get, never):IDX;
    private inline function get_grabber():IDX return this.grabber;

    public var type(get, never):GrabType;
    private inline function get_type():GrabType return this.type;

    public var isIndex(get, never):Bool;
    private inline function get_isIndex():Bool return this.type == INDEX;

    public var isName(get, never):Bool;
    private inline function get_isName():Bool return this.type == NAME;

    public var asInt(get, never):Int;
    private inline function get_asInt():Int return cast this.grabber;

    public var asString(get, never):String;
    private inline function get_asString():String return cast this.grabber;
}

/**
 * Internal object that holds the actual data with optional name
 */
typedef NamedArrayObject<T> = {
    var ?name:String;
    var object:T;
}

/**
 * Main NamedArrayI class that provides array-like functionality with named indices
 */
class NamedArrayI<T> {
    private var _array:Array<NamedArrayObject<T>>;

    public var length(get, never):Int;

    public function new(?initialArray:Array<T>) {
        _array = [];
        if (initialArray != null) {
            for (item in initialArray) {
                push(item);
            }
        }
    }

    private function get_length():Int {
        return _array.length;
    }

    /**
     * Push an item to the end of the array
     * If name already exists, replace the existing named object instead of throwing
     */
    public function push(object:T, ?name:String):Int {
        // Check for duplicate names (null names are allowed)
        if (name != null && containsName(name)) {
            // Replace the existing named object instead of throwing
            var existingIndex = indexOfName(name);
            if (existingIndex != -1) {
                _array[existingIndex] = {
                    name: name,
                    object: object
                };
                return existingIndex; // Return the index where it was replaced
            }
        }

        return _array.push({
            name: name,
            object: object
        });
    }

    /**
     * Pop the last item from the array
     */
    public function pop():Null<T> {
        var popped = _array.pop();
        return popped != null ? popped.object : null;
    }

    /**
     * Insert an item at a specific position using Grabber
     * If name already exists, replace the existing named object instead of throwing
     */
    public function insert(position:Grabber, object:T, ?name:String):Void {
        // Check for duplicate names (null names are allowed)
        if (name != null && containsName(name)) {
            // Replace the existing named object instead of throwing
            var existingIndex = indexOfName(name);
            if (existingIndex != -1) {
                _array[existingIndex] = {
                    name: name,
                    object: object
                };
                return; // Exit early since we replaced existing
            }
        }

        var index:Int = switch (position.type) {
            case INDEX: position.grabber;
            case NAME: indexOfName(position.grabber);
        };

        if (index == -1) {
            throw 'NamedArrayI: Cannot find insertion point';
        }

        _array.insert(index, {
            name: name,
            object: object
        });
    }

    /**
     * Remove an item at a specific index
     */
    public function remove(object:T):Bool {
        for (i in 0..._array.length) {
            if (_array[i].object == object) {
                _array.splice(i, 1);
                return true;
            }
        }
        return false;
    }

    /**
     * Remove an item using Grabber (supports both index and name via abstracts)
     */
    public function removeAt(position:Grabber):Null<T> {
        var index:Int = switch (position.type) {
            case INDEX: position.grabber;
            case NAME: indexOfName(position.grabber);
        };

        if (index >= 0 && index < _array.length) {
            var removed = _array.splice(index, 1)[0];
            return removed.object;
        }
        return null;
    }

    /**
     * Remove an item by name
     */
    public function removeByName(name:String):Null<T> {
        for (i in 0..._array.length) {
            if (_array[i].name == name) {
                var removed = _array.splice(i, 1)[0];
                return removed.object;
            }
        }
        return null;
    }

    /**
     * Get an item by index
     */
    public function getAt(index:Int):Null<T> {
        if (index >= 0 && index < _array.length) {
            return _array[index].object;
        }
        return null;
    }

    /**
     * Get an item by name
     */
    public function getByName(name:String):Null<T> {
        for (item in _array) {
            if (item.name == name) {
                return item.object;
            }
        }
        return null;
    }

    /**
     * Get an item using Grabber (supports both index and name via abstracts)
     */
    public function get(position:Grabber):Null<T> {
        return switch (position.type) {
            case INDEX: getAt(position.grabber);
            case NAME: getByName(position.grabber);
        }
    }

    /**
     * Set an item using Grabber (supports both index and name via abstracts)
     */
    public function set(position:Grabber, object:T, ?name:String):Bool {
        // Check for duplicate names (null names are allowed, but only if not replacing with same name)
        if (name != null) {
            var existingIndex = indexOfName(name);
            var targetIndex:Int = switch (position.type) {
                case INDEX: position.grabber;
                case NAME: indexOfName(position.grabber);
            };

            // Only throw error if name exists and it's not the same position we're setting
            if (existingIndex != -1 && existingIndex != targetIndex) {
                throw 'NamedArrayI: Name "${name}" already exists';
            }
        }

        var index:Int = switch (position.type) {
            case INDEX: position.grabber;
            case NAME: indexOfName(position.grabber);
        };

        if (index >= 0 && index < _array.length) {
            _array[index] = {
                name: name,
                object: object
            };
            return true;
        }
        return false;
    }

    /**
     * Set an item by name (replaces first match)
     */
    public function setByName(targetName:String, object:T, ?newName:String):Bool {
        // Check for duplicate names if changing name
        if (newName != null && newName != targetName && containsName(newName)) {
            throw 'NamedArrayI: Name "${newName}" already exists';
        }

        for (i in 0..._array.length) {
            if (_array[i].name == targetName) {
                _array[i] = {
                    name: newName != null ? newName : targetName,
                    object: object
                };
                return true;
            }
        }
        return false;
    }

    /**
     * Find the index using Grabber (supports both index and name via abstracts)
     */
    public function indexOf(position:Grabber):Int {
        return switch (position.type) {
            case INDEX: position.grabber; // Return the index directly
            case NAME: indexOfName(position.grabber);
        }
    }

    /**
     * Find the index of an object by value
     */
    public function indexOfObject(object:T):Int {
        for (i in 0..._array.length) {
            if (_array[i].object == object) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Find the index by name
     */
    public function indexOfName(name:String):Int {
        for (i in 0..._array.length) {
            if (_array[i].name == name) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Get the name at a specific index
     */
    public function nameAt(index:Int):Null<String> {
        if (index >= 0 && index < _array.length) {
            return _array[index].name;
        }
        return null;
    }

    /**
     * Check if array contains a position using Grabber
     */
    public function contains(position:Grabber):Bool {
        return indexOf(position) != -1;
    }

    /**
     * Check if array contains an object by value
     */
    public function containsObject(object:T):Bool {
        return indexOfObject(object) != -1;
    }

    /**
     * Check if array contains a name
     */
    public function containsName(name:String):Bool {
        return indexOfName(name) != -1;
    }

    /**
     * Slice the array
     */
    public function slice(start:Int, ?end:Int):NamedArrayI<T> {
        var result = new NamedArrayI<T>();
        var sliced = _array.slice(start, end);
        for (item in sliced) {
            result.push(item.object, item.name);
        }
        return result;
    }

    /**
     * Splice the array
     */
    public function splice(start:Int, deleteCount:Int):Array<T> {
        var removed = _array.splice(start, deleteCount);
        return [for (item in removed) item.object];
    }

    /**
     * Reverse the array
     */
    public function reverse():Void {
        _array.reverse();
    }

    /**
     * Sort the array by objects
     */
    public function sort(f:T -> T -> Int):Void {
        _array.sort(function(a:NamedArrayObject<T>, b:NamedArrayObject<T>):Int {
            return f(a.object, b.object);
        });
    }

    /**
     * Join array elements into a string
     */
    public function join(sep:String):String {
        var strings = [];
        for (item in _array) {
            if (item.name != null) {
                strings.push('${item.name}: ${Std.string(item.object)}');
            } else {
                strings.push(Std.string(item.object));
            }
        }
        return strings.join(sep);
    }

    /**
     * Convert to regular array keeping NamedArrayObject structure
     */
    public function toArray(keepNamed:Bool = true):Array<Dynamic> {
        if (keepNamed) {
            return _array.copy();
        } else {
            return [for (item in _array) item.object];
        }
    }

    /**
     * Convert to regular array without names (implicit conversion)
     */
    public function implicitArray():Array<T> {
        return [for (item in _array) item.object];
    }

    /**
     * Clear the array
     */
    public function clear():Void {
        _array = [];
    }

    /**
     * Copy the array
     */
    public function copy():NamedArrayI<T> {
        var result = new NamedArrayI<T>();
        for (item in _array) {
            result.push(item.object, item.name);
        }
        return result;
    }

    /**
     * Filter the array
     */
    public function filter(f:T -> Bool):NamedArrayI<T> {
        var result = new NamedArrayI<T>();
        for (item in _array) {
            if (f(item.object)) {
                result.push(item.object, item.name);
            }
        }
        return result;
    }

    /**
     * Map the array to a new type
     */
    public function map<S>(f:T -> S):NamedArrayI<S> {
        var result = new NamedArrayI<S>();
        for (item in _array) {
            result.push(f(item.object), item.name);
        }
        return result;
    }

    /**
     * Iterator for objects only
     */
    public function iterator():Iterator<T> {
        var index = 0;
        var arr = _array;
        return {
            hasNext: function():Bool {
                return index < arr.length;
            },
            next: function():T {
                return arr[index++].object;
            }
        };
    }

    /**
     * Key iterator (returns indices)
     */
    public function keyIterator():Iterator<Int> {
        var index = 0;
        var length = _array.length;
        return {
            hasNext: function():Bool {
                return index < length;
            },
            next: function():Int {
                return index++;
            }
        };
    }

    /**
     * KeyValue iterator that returns {key: index, value: object}
     */
    public function keyValueIterator():Iterator<{key:Int, value:T}> {
        var index = 0;
        var arr = _array;
        return {
            hasNext: function():Bool {
                return index < arr.length;
            },
            next: function():{key:Int, value:T} {
                var current = index++;
                return {key: current, value: arr[current].object};
            }
        };
    }

    /**
     * NamedKeyValue iterator that returns {key: index, name: name, value: object}
     */
    public function namedKeyValueIterator():Iterator<{key:Int, name:Null<String>, value:T}> {
        var index = 0;
        var arr = _array;
        return {
            hasNext: function():Bool {
                return index < arr.length;
            },
            next: function():{key:Int, name:Null<String>, value:T} {
                var current = index++;
                var item = arr[current];
                return {key: current, name: item.name, value: item.object};
            }
        };
    }

    /**
     * ToString representation
     */
    public function toString():String {
        return '[${join(", ")}]';
    }
}
