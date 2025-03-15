package backend;

import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;

class Pointer<T> {
    private var ref:Ref<T>;

    public function new(ref:Ref<T>) {
        this.ref = ref;
    }

    public function get():T {
        return ref.value;
    }

    public function set(value:T):Void {
        ref.value = value;
    }
}

class Ref<T> {
    public var value:T;

    public function new(value:T) {
        this.value = value;
    }
}

class HaxePointer {
    private var memory:StringMap<Dynamic>;
    private var pointer:Int;

    public function new() {
        memory = new StringMap<Dynamic>();
        pointer = 0;
    }

    public function allocate(size:Int):Int {
        var addr = pointer;
        pointer += size;
        return addr;
    }

    public function free(addr:Int):Void {
        memory.remove(addr);
    }

    public function write(addr:Int, data:Dynamic):Void {
        memory.set(addr, data);
    }

    public function read(addr:Int):Dynamic {
        return memory.get(addr);
    }

    public function findByType(type:String):Array<Int> {
        var result:Array<Int> = [];
        for (key in memory.keys()) {
            if (Type.typeof(memory.get(key)).toString() == type) {
                result.push(key);
            }
        }
        return result;
    }

    public function findByValue(value:Dynamic):Array<Int> {
        var result:Array<Int> = [];
        for (key in memory.keys()) {
            if (memory.get(key) == value) {
                result.push(key);
            }
        }
        return result;
    }

    public function dumpMemory():Void {
        for (key in memory.keys()) {
            trace('Address: $key, Value: ${memory.get(key)}');
        }
    }

    public static function createPointer<T>(value:T):Pointer<T> {
        var ref = new Ref<T>(value);
        return new Pointer<T>(ref);
    }
}
