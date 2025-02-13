package backend.modules;

class Number {
	private var value:Dynamic;

	public function new(value:Dynamic) {
		this.value = value;
	}

	public static function fromInt(value:Int):Number {
		return new Number(value);
	}

	public static function fromFloat(value:Float):Number {
		return new Number(value);
	}

	public function toInt():Int {
		return Std.int(this.value);
	}

	public function toFloat():Float {
		return this.value;
	}

	// public inline overload extern static function implicit(value:Int):Number {
	// 	return new Number(value);
	// }

	// public inline overload extern static function implicit(value:Float):Number {
	// 	return new Number(value);
	// }

	// public inline overload static function implicit(value:Number):Int {
	// 	return value.toInt();
	// }

	// public inline overload static function implicit(value:Number):Float {
	// 	return value.toFloat();
	// }

	public function toString():String {
		return Std.string(this.value);
	}

}
