package yutautil;

abstract ReadOnlyArray<T>(Array<T>) from Array<T> to Array<T> {

  public var length(get, never):Int;
    public inline function get_length():Int {
        return this.length;
    }

    public inline function get(index:Int):T {
        return this[index];
    }

    @:from public static function fromArray<T>(arr:Array<T>):ReadOnlyArray<T> {
        return arr;
    }
    @:to public static function toArray<T>(arr:ReadOnlyArray<T>):Array<T> {
        return arr;
    }

    public inline function iterator():Iterator<T> {
        return this.iterator();
    }

    @:arrayAccess public inline function get_index(index:Int):T {
        return this[index];
    }

    // @:arrayAccess public inline function set_index(index:Int, value:T):Void {
    //     throw "ReadOnlyArray is read-only";
    // }


}
