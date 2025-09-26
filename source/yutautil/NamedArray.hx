package yutautil;

import yutautil.NamedArrayI;

/**
 * Abstract wrapper for NamedArrayI providing array-like access and implicit conversions
 */
abstract NamedArray<T>(NamedArrayI<T>) from NamedArrayI<T> to NamedArrayI<T> {

    public var length(get, never):Int;

    public function new(?initialArray:Array<T>) {
        this = new NamedArrayI<T>(initialArray);
    }

    private function get_length():Int {
        return this.length;
    }

    /**
     * Array access operator for getting values by index
     */
    @:arrayAccess
    public function arrayGet(index:Int):Null<T> {
        return this.get(index);
    }

    /**
     * Array access operator for setting values by index
     */
    @:arrayAccess
    public function arraySet(index:Int, value:T):T {
        this.set(index, value);
        return value;
    }

    /**
     * Array access using Grabber for flexible access
     */
    @:arrayAccess
    public function grabberGet(grabber:Grabber):Null<T> {
        return this.get(grabber);
    }

    /**
     * Array access using Grabber for flexible setting
     */
    @:arrayAccess
    public function grabberSet(grabber:Grabber, value:T):T {
        this.set(grabber, value);
        return value;
    }

    // Forward all NamedArrayI methods
    public inline function push(object:T, ?name:String):Int {
        return this.push(object, name);
    }

    public inline function pop():Null<T> {
        return this.pop();
    }

    public inline function insert(position:Grabber, object:T, ?name:String):Void {
        this.insert(position, object, name);
    }

    public inline function remove(object:T):Bool {
        return this.remove(object);
    }

    public inline function removeAt(position:Grabber):Null<T> {
        return this.removeAt(position);
    }

    public inline function removeByName(name:String):Null<T> {
        return this.removeByName(name);
    }

    public inline function get(position:Grabber):Null<T> {
        return this.get(position);
    }

    public inline function getAt(index:Int):Null<T> {
        return this.getAt(index);
    }

    public inline function getByName(name:String):Null<T> {
        return this.getByName(name);
    }

    public inline function set(position:Grabber, object:T, ?name:String):Bool {
        return this.set(position, object, name);
    }

    public inline function setByName(targetName:String, object:T, ?newName:String):Bool {
        return this.setByName(targetName, object, newName);
    }

    public inline function indexOf(position:Grabber):Int {
        return this.indexOf(position);
    }

    public inline function indexOfObject(object:T):Int {
        return this.indexOfObject(object);
    }

    public inline function indexOfName(name:String):Int {
        return this.indexOfName(name);
    }

    public inline function nameAt(index:Int):Null<String> {
        return this.nameAt(index);
    }

    public inline function contains(position:Grabber):Bool {
        return this.contains(position);
    }

    public inline function containsObject(object:T):Bool {
        return this.containsObject(object);
    }

    public inline function containsName(name:String):Bool {
        return this.containsName(name);
    }

    public inline function slice(start:Int, ?end:Int):NamedArray<T> {
        return this.slice(start, end);
    }

    public inline function splice(start:Int, deleteCount:Int):Array<T> {
        return this.splice(start, deleteCount);
    }

    public inline function reverse():Void {
        this.reverse();
    }

    public inline function sort(f:T -> T -> Int):Void {
        this.sort(f);
    }

    public inline function join(sep:String):String {
        return this.join(sep);
    }

    public inline function toArray(keepNamed:Bool = true):Array<Dynamic> {
        return this.toArray(keepNamed);
    }

    public inline function clear():Void {
        this.clear();
    }

    public inline function copy():NamedArray<T> {
        return this.copy();
    }

    public inline function filter(f:T -> Bool):NamedArray<T> {
        return this.filter(f);
    }

    public inline function map<S>(f:T -> S):NamedArray<S> {
        return this.map(f);
    }

    public inline function iterator():Iterator<T> {
        return this.iterator();
    }

    public inline function keyIterator():Iterator<Int> {
        return this.keyIterator();
    }

    public inline function keyValueIterator():Iterator<{key:Int, value:T}> {
        return this.keyValueIterator();
    }

    public inline function namedKeyValueIterator():Iterator<{key:Int, name:Null<String>, value:T}> {
        return this.namedKeyValueIterator();
    }

    /**
     * Implicit conversion to regular Array<T> without names
     */
    @:to
    public function implicitArray():Array<T> {
        return this.implicitArray();
    }

    /**
     * Implicit conversion from regular Array<T>
     */
    @:from
    public static function fromArray<T>(array:Array<T>):NamedArray<T> {
        return new NamedArray<T>(array);
    }

    /**
     * String representation
     */
    @:to
    public function toString():String {
        return this.toString();
    }
}
