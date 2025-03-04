package backend.modules;

import haxe.ds.Map;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.Vector;
import flixel.group.FlxGroup;
import flixel.group.FlxTypedGroup;

abstract Container<T>(Dynamic) {
    public function new() {
        this = [];
    }

    public function newFromArray(array:Array<T>):Container<T> {
        this = array;
        return this;
    }

    public function newFromMap(map:Map<String, T>):Container<T> {
        this = map;
        return this;
    }

    public function newFromDTable(table:DTable<T>):Container<T> {
        this = table;
        return this;
    }

    public function newFromHTable(table:HTable<T>):Container<T> {
        this = table;
        return this;
    }

    public function newFromFlxGroup(group:FlxGroup):Container<T> {
        this = group;
        return this;
    }

    public function newFromFlxTypedGroup(group:FlxTypedGroup<T>):Container<T> {
        this = group;
        return this;
    }

    public function add(item:T):Void {
        switch (this) {
            case a:Array<T>:
                a.push(item);
            case m:Map<String, T>:
                m.set(Std.string(item), item);
            case g:FlxGroup:
                g.add(item);
            case tg:FlxTypedGroup<T>:
                tg.add(item);
            default:
                throw "Unsupported container type";
        }
    }

    public function remove(item:T):Void {
        switch (this) {
            case a:Array<T>:
                a.remove(item);
            case m:Map<String, T>:
                m.remove(Std.string(item));
            case g:FlxGroup:
                g.remove(item);
            case tg:FlxTypedGroup<T>:
                tg.remove(item);
            default:
                throw "Unsupported container type";
        }
    }

    public function get(index:Int):T {
        switch (this) {
            case a:Array<T>:
                return a[index];
            case m:Map<String, T>:
                return m.get(Std.string(index));
            case g:FlxGroup:
                return g.members[index];
            case tg:FlxTypedGroup<T>:
                return tg.members[index];
            default:
                throw "Unsupported container type";
        }
    }

    public function length():Int {
        switch (this) {
            case a:Array<T>:
                return a.length;
            case m:Map<String, T>:
                return m.keys().length;
            case g:FlxGroup:
                return g.length;
            case tg:FlxTypedGroup<T>:
                return tg.length;
            default:
                throw "Unsupported container type";
        }
    }
}