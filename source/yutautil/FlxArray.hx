package yutautil;

import flixel.FlxBasic;
import flixel.group.FlxGroup;

abstract FlxArray<T:FlxBasic>(FlxTypedGroup<T>) {

    public var length(get, never):Int;
    public var capacity(get, set):Int;

    public function new(?capacity:Int) {
        this = new FlxTypedGroup<T>(capacity);
    }

    public function add(item:T):Void {
        this.add(item);
    }

    public function remove(item:T):Void {
        this.remove(item);
    }

    public function clear():Void {
        this.clear();
    }

    public function get_length():Int {
        return this.length;
    }

    public function get_capacity():Int {
        return this.maxSize;
    }

    public function set_capacity(value:Int):Void {
        this.maxSize = value;
    }

    // Array access: a[index]
    @:arrayAccess
    public function get(index:Int):T {
        return this.members[index];
    }

    @:arrayAccess
    public function set(index:Int, value:T):Void {
        this.members[index] = value;
    }

    @:to
    public function toArray():Array<T> {
        return this.members;
    }

    @:from
    public static function fromArray<T:FlxBasic>(array:Array<T>):FlxArray<T> {
        var flxArray = new FlxArray<T>();
        for (item in array) {
            flxArray.add(item);
        }
        return flxArray;
    }

    @:from
    public static function fromFlxTypedGroup<T:FlxBasic>(group:FlxTypedGroup<T>):FlxArray<T> {
        var flxArray = new FlxArray<T>(group.maxSize);
        for (item in group.members) {
            flxArray.add(item);
        }
        return flxArray;
    }

    public function toString():String {
        return "FlxArray<" + Type.getClassName(Type.getClass(this.members[0])) + ">(" + this.length + " items)";
    }

    public function destroy():Void {
        this.clear();
        this.maxSize = 0;
        this.destroy();
    }

    public function superDestroy():Void {
        // Try/catch destroy each member
        for (member in this.members) {
            try {
                if (member != null) member.destroy();
            } catch (e:Dynamic) {
                trace("Warning: Failed to destroy member: " + e);
            }
        }
        this.clear();
        @:privateAccess
        this.members = null;
        this.maxSize = 0;
        destroy();
    }

    public inline function iterator():Iterator<T> {
        return this.members.iterator();
    }


}