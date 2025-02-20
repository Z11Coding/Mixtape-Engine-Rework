package backend;

@:generic
class Dial<T> {
    private var value:T;
    private var values:Array<T>;
    private var currentIndex:Int;

    public function new(values:Array<T>) {
        if (values.length == 0) {
            throw "Values array cannot be empty";
        }
        this.values = values;
        this.currentIndex = 0;
        this.value = this.values[0];
    }

    public function getCurrentValue():T {
        return this.values[this.currentIndex];
    }

    public function moveLeft():Void {
        this.currentIndex = (this.currentIndex - 1 + this.values.length) % this.values.length;
    }

    public function moveRight():Void {
        this.currentIndex = (this.currentIndex + 1) % this.values.length;
    }

    public static function fromEnum<E:Enum<Any>>(enumType:Enum<Any>):Dial<E> {
        var values:Array<E> = cast(Type.allEnums(enumType));
        return new Dial<E>(values);
    }
}