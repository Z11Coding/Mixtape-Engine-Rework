package yutautil;

class LimitedArray<T> {
    private var items:Array<T>;
    private var limit:Int;

    public function new(limit:Int) {
        this.limit = limit;
        this.items = [];
    }

    public function add(item:T, strategy:String = "ignore"):Void {
        if (items.length >= limit) {
            switch (strategy) {
                case "pop":
                    items.pop();
                    items.push(item);
                case "remove_oldest":
                    items.shift();
                    items.push(item);
                case "remove_newest":
                    items.pop();
                    items.push(item);
                case "ignore":
                    // Do nothing
                default:
                    // Do nothing
            }
        } else {
            items.push(item);
        }
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
