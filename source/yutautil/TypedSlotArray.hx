package yutautil;

import yutautil.LimitedArray;

enum TypeMismatchStrategy {
    Ignore;
    Throw;
}
/**
 * OptionalArg is a wrapper to mark a class type as optional for TypedSlotArray.
 * It is used only as a marker for the type system and not as a runtime value.
 */
abstract OptionalArg<T>(Class<T>) {
    public inline function new(cl:Class<T>) {
        this = cl;
    }
    @:to public inline function toClass():Class<T> return this;
}

/**
 * TypedSlotArray allows for an array of values with per-slot type checking,
 * supporting optional slots via OptionalArg.
 */
class TypedSlotArray<T> extends LimitedArray<T> {
    final types:Array<Class<Dynamic>>;
    final optionalIndices:Array<Int> = [];
    public var defaultAct:TypeMismatchStrategy = Throw;
    public var throwAtOverflow:Bool = true;

    /**
     * Accepts an array of types, where a type can be a Class<T> or OptionalArg<T>.
     * OptionalArg<T> marks the slot as optional.
     */
    public function new(typeDefs:Array<Dynamic>, ?defaultAct:TypeMismatchStrategy, ?throwAtOverflow:Bool) {
        super(typeDefs.length);
        this.types = [];
        for (i in 0...typeDefs.length) {
            var t = typeDefs[i];
            // Detect OptionalArg by checking if it's an abstract over Class
            if (Std.isOfType(t, OptionalArg)) {
                // Unwrap the class from OptionalArg
                var cl:Class<Dynamic> = cast t;
                this.types.push(cl);
                this.optionalIndices.push(i);
            } else {
                this.types.push(cast t);
            }
        }
        if (defaultAct != null) this.defaultAct = defaultAct;
        if (throwAtOverflow != null) this.throwAtOverflow = throwAtOverflow;
    }

    override public function add(value:T, ?strategy:TypeMismatchStrategy):Void {
        if (this.length >= types.length) {
            if (throwAtOverflow) throw 'Array is full, cannot add more items';
            return;
        }
        var strat = strategy != null ? strategy : defaultAct;
        if (value != null && !Std.isOfType(value, types[this.length])) {
            switch (strat) {
                case Throw: throw 'Value at index ${this.length} must be of type ${types[this.length]}';
                case Ignore:
            }
        }
        super.add(value, null);
    }

    public override function remove(value:T):Bool {
        var index = this.indexOf(value);
        if (index == -1) return false;
        if (this.get(index) != null) {
            this.set(index, null);
            return true;
        }
        return false;
    }

    override public function set(index:Int, value:T, ?strategy:TypeMismatchStrategy):T {
        if (index < 0 || index >= types.length) throw 'Index out of bounds';
        var strat = strategy != null ? strategy : defaultAct;
        if (value != null && !Std.isOfType(value, types[index])) {
            switch (strat) {
                case Throw: throw 'Value at index $index must be of type ${types[index]}';
                case Ignore:
            }
        }
        return super.set(index, value);
    }

    override public function push(value:T, ?strategy:TypeMismatchStrategy):Null<Int> {
        var idx = this.length;
        if (idx >= types.length) {
            if (throwAtOverflow) throw 'Array is full, cannot push more items';
            return null;
        }
        var strat = strategy != null ? strategy : defaultAct;
        if (value != null && !Std.isOfType(value, types[idx])) {
            switch (strat) {
                case Throw: throw 'Value at index $idx must be of type ${types[idx]}';
                case Ignore:
            }
        }
        return super.push(value);
    }
}