package backend;

import haxe.Reflect;

class DynamicIterator {
	public static function create(dynamicObject:Dynamic):Dynamic {
		if (Std.is(dynamicObject, Array)) {
			return new ArrayIterator(dynamicObject);
		} else if (Std.is(dynamicObject, Map)) {
			return new MapKeyValueIterator(cast dynamicObject);
		} else if (Reflect.isObject(dynamicObject)) {
			return new ObjectKeyValueIterator(dynamicObject);
		}
		throw "Unsupported dynamic object type for iteration.";
	}
}

class ArrayIterator<T> {
	var array:Array<T>;
	var index:Int = 0;

	public function new(array:Array<T>) {
		this.array = array;
	}

	public function hasNext():Bool {
		return index < array.length;
	}

	public function next():T {
		return array[index++];
	}
}

class MapKeyValueIterator<K, V> {
	var keys:Array<K>;
	var map:Map<K, V>;
	var index:Int = 0;

	public function new(map:Map<K, V>) {
		this.map = map;
		this.keys = map.keys();
	}

	public function hasNext():Bool {
		return index < keys.length;
	}

	public function next():{ key: K, value: V } {
		var key = keys[index++];
		return { key: key, value: map.get(key) };
	}
}

class ObjectKeyValueIterator {
	var fields:Array<String>;
	var object:Dynamic;
	var index:Int = 0;

	public function new(object:Dynamic) {
		this.object = object;
		this.fields = Reflect.fields(object);
	}

	public function hasNext():Bool {
		return index < fields.length;
	}

	public function next():{ field: String, value: Dynamic } {
		var field = fields[index++];
		return { field: field, value: Reflect.field(object, field) };
	}
}


