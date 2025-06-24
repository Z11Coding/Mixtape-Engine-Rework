package yutautil;


enum LimitedArrayStrategy {
    Ignore;
    RemoveOldest;
    RemoveNewest;
    Pop;
    ThrowError;
}
/**
 * LimitedArray is a utility class that maintains a fixed-size array.
 * When the limit is reached, it can either ignore new items, remove the oldest,
 * remove the newest, or pop the last item based on the specified strategy.
 */
class LimitedArray<T> {
    private var items:Array<T>;
    private var limit:Int;
    public var length(get, never):Int;
    public function get_length():Int {
        return items.length;
    }
    public var defaultStrategy:LimitedArrayStrategy = Ignore;

    public function new(limit:Int, defaultStrategy:LimitedArrayStrategy = Ignore) {
        this.limit = limit;
        this.items = [];
        this.defaultStrategy = defaultStrategy;
    }

    public function add(item:T, ?strategy:LimitedArrayStrategy):Void {
        if (items.length >= limit) {
            switch (strategy != null ? strategy : defaultStrategy) {
                case Pop:
                    items.pop();
                    items.push(item);
                case RemoveOldest:
                    items.shift();
                    items.push(item);
                case RemoveNewest:
                    items.pop();
                    items.push(item);
                case Ignore:
                    trace("Item not added, limit reached and strategy is Ignore.");
                case ThrowError:
                    throw "LimitedArray limit reached. Cannot add new item.";
                
            }
        } else {
            items.push(item);
        }
    }

    public function set(index:Int, item:T, ?strategy:LimitedArrayStrategy):T {
        if (index < 0 || index >= limit) throw 'Index out of bounds';
        if (items.length >= limit && items.length == limit && index >= items.length) {
            switch (strategy != null ? strategy : defaultStrategy) {
                case Pop:
                    items.pop();
                case RemoveOldest:
                    items.shift();
                case RemoveNewest:
                    items.pop();
                case Ignore:
                    trace("Item not set, limit reached and strategy is Ignore.");
                case ThrowError:
                    throw "LimitedArray limit reached. Cannot set item at index $index.";
            }
        }
        if (index < items.length) {
            items[index] = item;
        } else {
            items.push(item);
        }
        return item;
    }

    public function contains(item:T):Bool {
        return items.indexOf(item) != -1;
    }

    public function remove(item:T):Bool {
        var index = items.indexOf(item);
        if (index != -1) {
            items.splice(index, 1);
            return true;
        }
        return false;
    }

    public function push(item:T):Int {
        this.add(item, Ignore);
        return items.length-1;
    }

    public function get(index:Int):T {
        return items[index];
    }

    public function size():Int {
        return items.length;
    }

    public function indexOf(item:T):Int {
        return items.indexOf(item);
    }

    public function clear():Void {
        items = [];
    }
}
