package yutautil;

import cpp.Float32;
//import states.PlayState.LuaScript;
import yutautil.Threader;
import yutautil.Threader.MemLimitThreadQ;
import yutautil.modules.SyncUtils;
import cpp.abi.Abi;
import haxe.Constraints.IMap;
import haxe.ds.StringMap;
using yutautil.ChanceSelector;
using yutautil.Table;
using yutautil.DataStorage;
using yutautil.IterSingle;
using yutautil.HoldableVariable;
using yutautil.CollectionUtils;

// @:inline
// enum ListFunc {
//     pop;
//     get(item:T):Bool;
// }

/**
 * A type similar to Java's Predicate type.
 */
@:generic typedef Predicate<T> = T->Bool;

enum FuncAndReturnItem<T>
{
	Item;
	TransformedItem(func:T->Dynamic, ?extraArgs:Array<Dynamic>);
}

typedef LuaScript = flixel.util.typeLimit.OneOfTwo<psychlua.FunkinLua, psychlua.LegacyFunkinLua>;

// abstract Collection<T>(Dynamic) from Array<T> to Array<T> {
//     @:from public static inline function fromList<T>(list:List<T>):Collection<T> {
//         return cast list;
//     }
//     @:from public static inline function fromMap<T>(map:IMap<Dynamic, T>):Collection<T> {
//         return cast map;
//     }
// }

/**
 * An abstract type that allows any form of input that will result in the required type.
 * If the input is a function, it will be executed to get the result.
 */
// @:generic abstract FCTInput<I>(I) {
//     public function new(value:I) {
//         this = value.toCallable()();
//         while (Reflect.isFunction(this)) {
//             trace("Unpacking and executing function...");
//             this = this();
//             trace("Function executed.");
//         }
//         var thee = this;
//         this = thee;
//     }
// }
// public inline function get():T {
//     if (Std.is(this, Function)) {
//         return (cast this: I -> T)();
//     } else {
//         return cast this;
//     }
// }



class KeyArray<K, V>
{
	// An array with keys, similar to a dictionary, allowing for use of keys with arrayaccess.
	public var keys:Array<K>;
	public var values:Array<V>;
	private var referenceMap:Array<{key:K, value:V, index:Int}>;

	public function new(keys:Array<K> = null, values:Array<V> = null)
	{
		this.keys = keys != null ? keys.copy() : [];
		this.values = values != null ? values.copy() : [];
		this.referenceMap = [];
		updateReferenceMap();
	}

	private function syncReferenceMap():Void
	{
		if (keys.length != values.length || keys.length != referenceMap.length)
		{
			desyncPanic("Length mismatch: keys=" + keys.length + ", values=" + values.length + ", referenceMap=" + referenceMap.length);
			return;
		}
		for (i in 0...keys.length)
		{
			var ref = referenceMap[i];
			if (ref == null || ref.key != keys[i] || ref.value != values[i] || ref.index != i)
			{
				desyncPanic("ReferenceMap desync at index " + i);
				return;
			}
		}
	}

	private function updateReferenceMap():Void
	{
		referenceMap = [];
		for (i in 0...keys.length)
		{
			referenceMap.push({key: keys[i], value: values[i], index: i});
		}
	}

	private function desyncPanic(msg:String):Void
	{
		trace("[KeyArray] Desync detected: " + msg);
		keys = null;
		values = null;
		referenceMap = null;
		throw new haxe.Exception("[KeyArray] CRASH PANIC: Internal data desync. All data nullified. Reason: " + msg);
	}

	public function get(key:K):V
	{
		syncReferenceMap();
		var index = keys.indexOf(key);
		if (index != -1)
		{
			return values[index];
		}
		else
		{
			return null;
		}
	}

	public function set(key:K, value:V):Void
	{
		syncReferenceMap();
		var index = keys.indexOf(key);
		if (index != -1)
		{
			values[index] = value;
			referenceMap[index] = {key: key, value: value, index: index};
		}
		else
		{
			keys.push(key);
			values.push(value);
			referenceMap.push({key: key, value: value, index: keys.length - 1});
		}
	}

	public function exists(key:K):Bool
	{
		syncReferenceMap();
		return keys.indexOf(key) != -1;
	}

	public function remove(key:K):Bool
	{
		syncReferenceMap();
		var idx = keys.indexOf(key);
		if (idx != -1)
		{
			keys.splice(idx, 1);
			values.splice(idx, 1);
			referenceMap.splice(idx, 1);
			updateReferenceMap();
			return true;
		}
		return false;
	}

	public function pop():{key:K, value:V}
	{
		syncReferenceMap();
		if (keys.length > 0 && values.length > 0)
		{
			var key = keys.pop();
			var value = values.pop();
			referenceMap.pop();
			updateReferenceMap();
			return {key: key, value: value};
		}
		return null;
	}

	public function push(key:K, value:V):Int
	{
		syncReferenceMap();
		keys.push(key);
		values.push(value);
		referenceMap.push({key: key, value: value, index: keys.length - 1});
		return keys.length;
	}

	public function clear():Void
	{
		keys = [];
		values = [];
		referenceMap = [];
	}

	public function length():Int
	{
		syncReferenceMap();
		return keys.length;
	}

	public function getAll():Array<{key:K, value:V}>
	{
		syncReferenceMap();
		var result = [];
		for (i in 0...keys.length)
		{
			result.push({key: keys[i], value: values[i]});
		}
		return result;
	}

	public function keysArray():Array<K>
	{
		syncReferenceMap();
		return keys.copy();
	}

	public function valuesArray():Array<V>
	{
		syncReferenceMap();
		return values.copy();
	}

	public function iterator():Iterator<{key:K, value:V}>
	{
		syncReferenceMap();
		var arr = [];
		for (i in 0...keys.length)
		{
			arr.push({key: keys[i], value: values[i]});
		}
		return arr.iterator();
	}
}


/**
 * An abstract type that allows for key-based access to a KeyIndexedArray.
 * This is a specialized array that allows for key-based access.
 * It provides array access support for getting and setting values using keys.
 */
 @:forward
abstract KeyIndexedArray<K, V>(KeyArray<K, V>)
{

			@:privateAccess
	public function new(keys:Array<K> = null, values:Array<V> = null)
	{
		this = new KeyArray<K, V>(keys, values);
	}

	@:arrayAccess
	public inline function get(key:K):V
	{
		return this.get(key);
	}

	@:arrayAccess
	public inline function set(key:K, value:V):Void
	{
		this.set(key, value);
	}

	public inline function exists(key:K):Bool
	{
		return this.exists(key);
	}

	public inline function remove(key:K):Bool
	{
		return this.remove(key);
	}

	public inline function pop():{key:K, value:V}
	{
		return this.pop();
	}

	public inline function push(key:K, value:V):Int
	{
		return this.push(key, value);
	}

	public inline function clear():Void
	{
		this.clear();
	}

	public inline function length():Int
	{
		return this.length();
	}

	public inline function getAll():Array<{key:K, value:V}>
	{
		return this.getAll();
	}

	public inline function keysArray():Array<K>
	{
		return this.keysArray();
	}

	public inline function valuesArray():Array<V>
	{
		return this.valuesArray();
	}

	public inline function iterator():Iterator<{key:K, value:V}>
	{
		return this.iterator();
	}

	public inline function toArray():Array<{key:K, value:V}>
	{
		return this.getAll();
	}

	public inline function toString():String
	{
		return "KeyIndexedArray: " + this.getAll().toString();
	}

	public inline function toDynamic():Dynamic
	{
		var result = {};
		for (i in 0...this.keys.length)
		{
			Reflect.setField(result, Std.string(this.keys[i]), this.values[i]);
		}
		return result;
	}

	public inline function toMap():Map<Dynamic, Dynamic>
	{
		var keys = this.keysArray();
		var values = this.valuesArray();
		// If there are no keys, just return a normal Map
		if (keys.length == 0) return new Map<Dynamic, Dynamic>();

		// Check if the first key is a class (not an instance)
		for (k in keys)
			if (Std.is(k, Class)) {
				// If the key is a class, we cannot use it as a key in a Map
				// because classes are not hashable in Haxe.
				// We can throw an error or handle it differently if needed.
			throw "Cannot use classes as keys in a Map.";
		}

		// If the key is an object (not a primitive or string), use HashMap
		var useHashMap = false;
		for (k in keys) {
			var t = Type.typeof(k);
			if (t == TObject || (Std.is(k, Class) && !Std.is(k, String))) {
				useHashMap = true;
				break;
			}
		}

		var result:Dynamic;
		if (useHashMap) {
			result = new haxe.ds.HashMap<Dynamic, V>();
		} else {
			result = new Map<Dynamic, V>();
		}

		for (i in 0...keys.length) {
			result.set(keys[i], values[i]);
		}
		return result;
	}
}


// /**
//  * A specialized array that allows for key-based access.
//  * This is a subclass of KeyArray, which provides the basic functionality.
//  * It adds array access support for getting and setting values using keys.
//  */
// class KeyIndexedArray<K, V> extends KeyArray<K, V>
// {
// 	public function new(?keys:Array<K>, ?values:Array<V>)
// 	{
// 		super(keys, values);
// 	}

// 	@:arrayAccess
// 	public override function get(key:K):V
// 	{
// 		return super.get(key);
// 	}

// 	@:arrayAccess
// 	public override function set(key:K, value:V):Void
// 	{
// 		super.set(key, value);
// 	}
// }

class DynamicMap<K, V>
{
	private var keys:Array<K>;
	private var values:Array<V>;
	private var referenceMap:Array<{key:K, value:V, index:Int}>;

	public function new()
	{
		keys = [];
		values = [];
		referenceMap = [];
	}

	// Encodes the key for faster lookup, especially for primitive types.
	private function encodeKey(key:K):Dynamic
	{
		var t = Type.typeof(key);
		switch (t) {
			case TNull: return "null";
			case TInt: return "i:" + key;
			case TFloat: return "f:" + key;
			case TBool: return "b:" + (cast(key, Bool) ? "1" : "0");
			default:
				if (Std.is(key, String)) {
					return "s:" + key;
				}
				return key;
		}
	}

	// Finds the index of the key using encoded keys for speed.
	private function indexOfKey(key:K):Int
	{
		syncReferenceMap();
		var encoded = encodeKey(key);
		for (i in 0...keys.length)
		{
			if (encodeKey(keys[i]) == encoded)
				return i;
		}
		return -1;
	}

	private function syncReferenceMap():Void
	{
		// Check for desync
		if (keys.length != values.length || keys.length != referenceMap.length)
		{
			desyncPanic("Length mismatch: keys=" + keys.length + ", values=" + values.length + ", referenceMap=" + referenceMap.length);
			return;
		}
		for (i in 0...keys.length)
		{
			var ref = referenceMap[i];
			if (ref == null || ref.key != keys[i] || ref.value != values[i] || ref.index != i)
			{
				desyncPanic("ReferenceMap desync at index " + i);
				return;
			}
		}
		// If referenceMap is not up to date, rebuild it
		if (referenceMap.length != keys.length)
		{
			referenceMap = [];
			for (i in 0...keys.length)
			{
				referenceMap.push({key: keys[i], value: values[i], index: i});
			}
		}
	}

	private function updateReferenceMap():Void
	{
		referenceMap = [];
		for (i in 0...keys.length)
		{
			referenceMap.push({key: keys[i], value: values[i], index: i});
		}
	}

	private function desyncPanic(msg:String):Void
	{
		trace("[DynamicMap] Desync detected: " + msg);
		keys = null;
		values = null;
		referenceMap = null;
		throw new haxe.Exception("[DynamicMap] CRASH PANIC: Internal data desync. All data nullified. Reason: " + msg);
	}

	public function get(key:K):V
	{
		syncReferenceMap();
		var idx = indexOfKey(key);
		return idx != -1 ? values[idx] : null;
	}

	public function set(key:K, value:V):Void
	{
		syncReferenceMap();
		var idx = indexOfKey(key);
		if (idx != -1)
		{
			values[idx] = value;
			referenceMap[idx] = {key: key, value: value, index: idx};
		}
		else {
			keys.push(key);
			values.push(value);
			referenceMap.push({key: key, value: value, index: keys.length - 1});
		}
	}

	public function exists(key:K):Bool
	{
		syncReferenceMap();
		return indexOfKey(key) != -1;
	}

	public function remove(key:K):Bool
	{
		syncReferenceMap();
		var idx = indexOfKey(key);
		if (idx != -1)
		{
			keys.splice(idx, 1);
			values.splice(idx, 1);
			referenceMap.splice(idx, 1);
			updateReferenceMap();
			return true;
		}
		return false;
	}

	public function keysArray():Array<K>
	{
		syncReferenceMap();
		return keys.copy();
	}

	public function valuesArray():Array<V>
	{
		syncReferenceMap();
		return values.copy();
	}

	public function iterator():Iterator<V>
	{
		syncReferenceMap();
		return values.iterator();
	}

	private function clean():Void
	{
		keys = [];
		values = [];
		referenceMap = [];
	}

	public function clear():Void
	{
		clean();
	}

	public function length():Int
	{
		syncReferenceMap();
		return keys.length;
	}

	public function pop():V
	{
		syncReferenceMap();
		if (values.length > 0)
		{
			var value = values.pop();
			keys.pop();
			referenceMap.pop();
			updateReferenceMap();
			return value;
		}
		return null;
	}

	public function setAll(newKeys:Array<K>, newValues:Array<V>):Void
	{
		if (newKeys.length != newValues.length)
		{
			desyncPanic("setAll: newKeys and newValues length mismatch");
			return;
		}
		keys = newKeys.copy();
		values = newValues.copy();
		updateReferenceMap();
	}

	public function getAll():Array<{key:K, value:V}>
	{
		syncReferenceMap();
		var result = [];
		for (i in 0...keys.length)
		{
			result.push({key: keys[i], value: values[i]});
		}
		return result;
	}
}

enum Size
{
	Bytes;
	KB;
	MB;
	Auto;
}

/**
 * A utility class for working with collections, providing various methods
 * to check types, estimate sizes, and convert between different collection types.
 */
class CollectionUtils
{
	public static inline function isIterable<T>(input:Dynamic):Bool
	{
		return Std.is(input, Array)
			|| Std.is(input, IMap)
			|| (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")));
	}

	public static inline function isMap<T>(input:Dynamic):Bool
	{
		return Std.is(input, IMap);
	}

	public static inline function isIterableOfType<T>(input:Dynamic, type:Class<T>):Bool
	{
		return (Std.is(input, Array) && (input : Array<T>).length > 0)
			|| (Std.is(input, IMap) && (input : Map<Dynamic, T>).keys().hasNext())
			|| (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")));
	}

	public static inline function objectDynamic<T>(input:Dynamic):Dynamic
	{
		if (Std.is(input, Array))
		{
			var result = {};
			for (i in 0...(input : Array<T>).length)
			{
				Reflect.setField(result, Std.string(i), input[i]);
			}
			return result;
		}
		else if (Std.is(input, IMap))
		{
			var result = {};
			for (key in (input : Map<Dynamic, T>).keys())
			{
				Reflect.setField(result, key, input.get(key));
			}
			return result;
		}
		else
		{
			return input;
		}
	}


	/**
	 * Estimates the memory size of an object in bytes.
	 * @param input The object to estimate.
	 * @param mode Display mode: "bytes", "kb", "mb", or "auto" (default: "auto").
	 * @return The estimated size as a String with units, or Int if mode is "bytes".
	 */
	public static function objectSize<T>(input:Dynamic, ?mode:String = "auto"):Dynamic
	{
		var seen = new Map<Dynamic, Bool>();
		function sizeof(obj:Dynamic):Int
		{
			if (obj == null) return 0;
			if (seen.exists(obj)) return 0;
			seen.set(obj, true);

			if (Std.is(obj, String)) {
				return (obj : String).length * 2;
			}

			switch (Type.typeof(obj))
			{
				case TNull: return 0;
				case TInt: return 4;
				case TFloat: return 8;
				case TBool: return 1;
				case TObject:
					var size = 0;
					for (field in Reflect.fields(obj))
					{
						size += sizeof(Reflect.field(obj, field));
					}
					return size;
				case TClass(_):
					if (Std.is(obj, Array))
					{
						var arr:Array<Dynamic> = cast obj;
						var size = 0;
						for (item in arr) size += sizeof(item);
						return size + 8 * arr.length;
					}
					else if (Std.is(obj, List))
					{
						var size = 0;
						for (item in (obj : List<Dynamic>)) size += sizeof(item);
						return size;
					}
					else if (Std.is(obj, IMap))
					{
						var size = 0;
						for (key in (obj : IMap<Dynamic, Dynamic>).keys())
						{
							size += sizeof(key) + sizeof(obj.get(key));
						}
						return size;
					}
					else
					{
						// Fallback for other class instances
						var size = 0;
						for (field in Reflect.fields(obj))
						{
							size += sizeof(Reflect.field(obj, field));
						}
						return size;
					}
				default: return 0;
			}
		}

		var bytes = sizeof(input);

		function format(size:Int):String
		{
			function to2dp(f:Float):String
				return StringTools.replace(Std.string(Math.round(f * 100) / 100), ".", ",").replace(",", ".");

			if (mode == "bytes") return size + " bytes";
			if (mode == "kb") return to2dp(size / 1024) + " KB";
			if (mode == "mb") return to2dp(size / (1024 * 1024)) + " MB";
			// auto
			if (size < 1024) return size + " bytes";
			if (size < 1024 * 1024) return to2dp(size / 1024) + " KB";
			return to2dp(size / (1024 * 1024)) + " MB";
		}

		return mode == "bytes" ? bytes : format(bytes);
	}

	public static inline function enumToArray<T:EnumValue>(enumType:Enum<T>):Array<Dynamic>
	{
		// Converts an Enum to an Array of its values.
		return Type.getEnumConstructs(enumType);
	}

	public static inline function nullify<T>(input:T, nullifyElements:Bool = true):Null<T>
	{
		// Nullifies the input object or its elements if it's an iterable.
		if (input == null) return null;

		try {
			// Array
			if (Std.is(input, Array)) {
				var arr:Array<Dynamic> = cast input;
				if (nullifyElements) {
					for (i in 0...arr.length) arr[i] = null;
				}
				untyped input = null;
				return null;
			}
			// List
			else if (Std.is(input, List)) {
				var list:List<Dynamic> = cast input;
				if (nullifyElements) {
					var arr = [];
					for (item in list) arr.push(item);
					list.clear();
					for (_ in arr) list.add(null);
				}
				untyped input = null;
				return null;
			}
			// Map/IMap
			else if (Std.is(input, IMap)) {
				var map:IMap<Dynamic, Dynamic> = cast input;
				if (nullifyElements) {
					for (key in map.keys()) {
						map.set(key, null);
					}
				}
				untyped input = null;
				return null;
			}
			// Iterable/Iterator
			else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next"))) {
				if (nullifyElements) {
					for (item in input.toIterable()) {
						nullify(item, true);
					}
				}
				untyped input = null;
				return null;
			}
			// Object or Class instance
			else if (Type.typeof(input) == TObject || Type.getClass(input) != null) {
				if (nullifyElements) {
					// Nullify all fields (including instance fields for classes)
					var fields = Reflect.fields(input);
					for (field in fields) {
						try {
							Reflect.setField(input, field, null);
						} catch (e:Dynamic) {
							trace('Error nullifying field "$field" on object: ' + e);
						}
					}
					// If it's a class, also nullify instance fields
					var cl = Type.getClass(input);
					if (cl != null) {
						var instanceFields = Type.getInstanceFields(cl);
						for (field in instanceFields) {
							try {
								Reflect.setField(input, field, null);
							} catch (e:Dynamic) {
								trace('Error nullifying instance field "$field" on class ${Type.getClassName(cl)}: ' + e);
							}
						}
					}
				}
				untyped input = null;
				return null;
			}
		} catch (e:Dynamic) {
			trace('Error in nullify: ' + e);
			// Fallback: just nullify input
			untyped input = null;
			return null;
		}
		// Fallback: just nullify input
		untyped input = null;
		return null;
	}

	public static inline function sizeIn(input:Dynamic, ?accuracy:Size, ?verbosity:{?verbose:Bool, ?showStack:Dynamic, ?showCurrent:Bool, ?showObjects:Bool}):Dynamic
	{
		// Returns the size of the object in the specified accuracy.
		// If accuracy is not provided, it defaults to "auto".
		if (accuracy == null) accuracy = Size.Auto;

		var size = realSizeOf(input, verbosity);

		return switch (accuracy)
		{
			case Size.Bytes: size;
			case Size.KB: Math.round(size / 1024 * 100) / 100; // Round to 2 decimal places
			case Size.MB: Math.round(size / (1024 * 1024) * 100) / 100; // Round to 2 decimal places
			case Size.Auto:
				if (size < 1024) size + " bytes";
				else if (size < 1024 * 1024) Math.round(size / 1024 * 100) / 100 + " KB"; // Round to 2 decimal places
				else Math.round(size / (1024 * 1024) * 100) / 100 + " MB"; // Round to 2 decimal places
		}
	}

	#if cpp
	/**
	 * Attempts to get the real memory size of an object in C++.
	 * Uses an explicit stack to avoid recursion/stack overflow for large objects.
	 */
	public static function realSizeOf<T>(input:T, ?options:{?verbose:Bool, ?showStack:Dynamic, ?showCurrent:Bool, ?showObjects:Bool}):Int
	{
		#if !cpp
		throw "realSizeOf is only available on cpp targets.";
		#end

		if (input == null) return 0;

		var seen = new Map<Dynamic, Bool>();
		var stack:Array<Dynamic> = [input];
		var totalSize = 0;
		var opts = options != null ? options : {};

		// Handle showStack as object with .size property (default 3 or 5)
		var showStackObj:Null<{size:Int}> = null;
		if (opts.showStack != null) {
			if (Std.is(opts.showStack, Bool)) {
				showStackObj = { size: opts.showStack ? 3 : 0 };
			} else if (Reflect.isObject(opts.showStack) && Reflect.hasField(opts.showStack, "size")) {
				showStackObj = { size: opts.showStack.size };
			} else if (Std.is(opts.showStack, Int)) {
				showStackObj = { size: opts.showStack };
			}
		}
		if (showStackObj == null) showStackObj = { size: 5 };

		function safeToString(obj:Dynamic):String {
			try {
				return Std.string(obj);
			} catch (e) {
				return "[error: " + Std.string(e) + "]";
			}
		}

		function classDisplay(obj:Dynamic):String {
			try {
				var cl = Type.getClass(obj);
				if (cl != null) {
					var className = Type.getClassName(cl);
					var str = safeToString(obj);
					if (str != null && str != "") {
						return className + " | \"" + str + "\"";
					} else {
						return className;
					}
				} else {
					return safeToString(obj);
				}
			} catch (e) {
				return "[error: " + Std.string(e) + "]";
			}
		}

		// Compose a single-line status string
		inline function statusString():String {
			var stackCount = stack.length + 1;
			var currentObj = stack.length > 0 ? stack[stack.length - 1] : null;
			var currentStr = "";
			if (opts.showCurrent && currentObj != null) {
				try {
					if (Type.getClass(currentObj) != null) {
						currentStr = " | Current: " + classDisplay(currentObj);
					} else {
						currentStr = " | Current: " + safeToString(currentObj);
					}
				} catch (e:Dynamic) {
					currentStr = " | Current: [error displaying object: " + Std.string(e) + "]";
				}
			}
			var stackStr = "";
			if ((opts.showStack != null && showStackObj.size > 0) || opts.showObjects) {
				var items = [];
				var start = stack.length - showStackObj.size;
				if (start < 0) start = 0;
				for (i in start...stack.length) {
					var item = stack[i];
					try {
						if (Type.getClass(item) != null) {
							items.push(classDisplay(item));
						} else {
							items.push(safeToString(item));
						}
					} catch (e:Dynamic) {
						items.push("[error displaying object: " + Std.string(e) + "]");
					}
				}
				stackStr = " | Stack(last " + showStackObj.size + "): [" + items.join(", ") + "]";
			}
			var result = "[realSizeOf] Stack size: " + stackCount + " | Total size: " + totalSize + currentStr + stackStr;
			return StringTools.replace(result, "\n", " ");
		}

		// Use Sys.print to update the same line
		inline function printStatus() {
			if (opts.verbose || (opts.showStack != null && showStackObj.size > 0) || opts.showObjects) {
				Sys.print("\r" + statusString());
			}
		}

		var erroredObjects:Array<Dynamic> = [];
		var errorCount = 0;
		while (stack.length > 0)
		{
			var current = stack.pop();
			if (current == null) continue;
			if (seen.exists(current)) continue;
			seen.set(current, true);

			printStatus();

			try {
				switch (Type.typeof(current))
				{
					case TNull:
						// nothing
					case TInt, TFloat, TBool:
						totalSize += untyped __cpp__('sizeof({0})', current);
					case TObject, TClass(_):
						if (Std.is(current, Array))
						{
							var arr:Array<Dynamic> = cast current;
							totalSize += untyped __cpp__('sizeof({0})', current);
							for (item in arr) stack.push(item);
						}
						else if (Std.is(current, String))
						{
							var str:cpp.ConstCharStar = cpp.ConstCharStar.fromString(cast current);
							var trueString = cpp.Pointer.fromRaw(cast str.toPointer()).ref;
							totalSize += untyped __cpp__('sizeof({0})', trueString) + untyped __cpp__('sizeof({0})', str);
						}
						else if (Std.is(current, haxe.ds.StringMap))
						{
							var map:haxe.ds.StringMap<Dynamic> = cast current;
							var mapPtr = cpp.Pointer.fromRaw(cpp.RawPointer.addressOf(map));
							var trueMap = mapPtr.ref;
							totalSize += untyped __cpp__('sizeof({0})', mapPtr) + untyped __cpp__('sizeof({0})', trueMap);
							for (k in map.keys())
							{
								stack.push(k);
								stack.push(map.get(k));
							}
						}
						else
						{
							var size = untyped __cpp__('sizeof(void*)');
							var ptr = cpp.Pointer.fromRaw(cpp.RawPointer.addressOf(current));
							var trueObj = ptr.ref;
							size += untyped __cpp__('sizeof({0})', trueObj);
							size += untyped __cpp__('sizeof({0})', ptr);
							totalSize += size;
							for (field in Reflect.fields(current))
							{
								stack.push(Reflect.field(current, field));
							}
						}
					default:
						totalSize += untyped __cpp__('sizeof(void*)');
				}
			} catch (e:Dynamic) {
				errorCount++;
				erroredObjects.push(current);
			}
		}

		// Print a newline at the end to finish the line
		if (opts.verbose || (opts.showStack != null && showStackObj.size > 0) || opts.showObjects) {
			Sys.println("");
		}

		if (errorCount > 0) {
			var report = "Errored Objects: " + errorCount + "\n";
			for (obj in erroredObjects) {
				try {
					report += "Object: " + Std.string(obj) + " | Type: " + (Type.getClassName(Type.getClass(obj))) + "\n";
				} catch (e:Dynamic) {
					report += "Object: [unstringifiable]\n";
				}
			}
			// Write report to crash folder
			var crashDir = "crash";
			if (!sys.FileSystem.exists(crashDir)) sys.FileSystem.createDirectory(crashDir);
			var fileName = crashDir + "/realSizeOf_error_report_" + Date.now().getTime() + ".txt";
			sys.io.File.saveContent(fileName, "Total Size: " + totalSize + "\n" + report);

			trace("Errored Objects: " + errorCount);

			lime.app.Application.current.window.alert("Error(s) occurred during realSizeOf:\n" + report, "realSizeOf Error Report");

		}
		return totalSize;
		// Print a newline at the end to finish the line
		if (opts.verbose || (opts.showStack != null && showStackObj.size > 0) || opts.showObjects) {
			Sys.println("");
		}
		return totalSize;
	}
	#end

	private static function list<T>(l:List<T>):List<T>
	{
		return l;
	}

	// public static inline function valTween<T>(value:T, start:T, finish:T, duration:Float, onUpdate:T->Void, onComplete:Void->Void):Void
	// {
	// 	if (Std.is(value, String))
	// 	{
	// 		var startStr = (start : String);
	// 		var finishStr = (finish : String);
	// 		var length = Math.max(startStr.length, finishStr.length);
	// 		var step = Math.ceil(length / (duration * 60)); // Assuming 60 FPS
	// 		var currentIndex = 0;

	// 		FlxTween.tween({index: 0}, {index: length}, duration, {
	// 			type: FlxTween.linear,
	// 			onUpdate: function(data) {
	// 				currentIndex = Math.min(Math.round(data.index), length);
	// 				var newValue = finishStr.substr(0, currentIndex);
	// 				onUpdate(cast newValue);
	// 			},
	// 			onComplete: onComplete
	// 		});
	// 	}
	// 	else if (Std.is(value, Float) || Std.is(value, Int))
	// 	{
	// 		FlxTween.tween({val: start}, {val: finish}, duration, {
	// 			type: FlxTween.linear,
	// 			onUpdate: function(data) {
	// 				onUpdate(cast data.val);
	// 			},
	// 			onComplete: onComplete
	// 		});
	// 	}
	// 	else if (Std.is(value, Array))
	// 	{
	// 		var startArr = (start : Array<Dynamic>);
	// 		var finishArr = (finish : Array<Dynamic>);
	// 		var maxLength = Math.max(startArr.length, finishArr.length);
	// 		var step = Math.ceil(maxLength / (duration * 60)); // Assuming 60 FPS
	// 		var currentIndex = 0;

	// 		FlxTween.tween({index: 0}, {index: maxLength}, duration, {
	// 			type: FlxTween.linear,
	// 			onUpdate: function(data) {
	// 				currentIndex = Math.min(Math.round(data.index), maxLength);
	// 				var newValue = [];
	// 				for (i in 0...currentIndex)
	// 				{
	// 					if (i < startArr.length && i < finishArr.length)
	// 					{
	// 						// Change items if they differ
	// 						newValue.push(finishArr[i]);
	// 					}
	// 					else if (i >= startArr.length)
	// 					{
	// 						// Add items from finishArr
	// 						newValue.push(finishArr[i]);
	// 					}
	// 					// If i >= finishArr.length, items are implicitly removed
	// 				}
	// 				onUpdate(cast newValue);
	// 			},
	// 			onComplete: onComplete
	// 		});
	// 	}
	// 	else if (Std.is(value, List))
	// 	{
	// 		var startList = (start : List<Dynamic>);
	// 		var finishList = (finish : List<Dynamic>);
	// 		var maxLength = Math.max(startList.length, finishList.length);
	// 		var step = Math.ceil(maxLength / (duration * 60)); // Assuming 60 FPS
	// 		var currentIndex = 0;

	// 		FlxTween.tween({index: 0}, {index: maxLength}, duration, {
	// 			type: FlxTween.linear,
	// 			onUpdate: function(data) {
	// 				currentIndex = Math.min(Math.round(data.index), maxLength);
	// 				var newValue = new List<Dynamic>();
	// 				for (i in 0...currentIndex)
	// 				{
	// 					if (i < startList.length && i < finishList.length)
	// 					{
	// 						// Change items if they differ
	// 						newValue.add(finishList[i]);
	// 					}
	// 					else if (i >= startList.length)
	// 					{
	// 						// Add items from finishList
	// 						newValue.add(finishList[i]);
	// 					}
	// 					// If i >= finishList.length, items are implicitly removed
	// 				}
	// 				onUpdate(cast newValue);
	// 			},
	// 			onComplete: onComplete
	// 		});
	// 	}
	// 	else
	// 	{
	// 		throw "Unsupported type for valTween";
	// 	}
	// }

	public static inline function arrayProperties<T>(a:Array<T>):{length:Int, first:T, last:T}
	{
		return {length: a.length, first: a[0], last: a[a.length - 1]};
	}

	// public static inline function propertiesFromObject<T>(o:Dynamic):{length:Int, first:T, last:T}
	// {
	// 	var keys = Reflect.fields(o);
	// 	var length = keys.length;
	// 	var first = length > 0 ? o[keys[0]] : null;
	// 	var last = length > 0 ? o[keys[length - 1]] : null;
	// 	return {length: length, first: first, last: last};
	// }

	public static inline function pluck<T, R>(input:Iterable<T>, property:String):Array<R>
	{
		var result = [];
		for (item in input)
		{
			result.push(Reflect.field(item, property));
		}
		return result;
	}

	// Maps to dictionaries, arrays, and other iterable types.
	public static inline function keyPairs<K, V>(input:Dynamic):Array<{key:Dynamic, value:Dynamic}>
	{
		var result:Array<{key:Dynamic, value:Dynamic}> = [];

		if (Std.is(input, Array))
		{
			for (i in 0...(input : Array<Dynamic>).length)
			{
				result.push({key: i, value: input[i]});
			}
		}
		else if (Std.is(input, IMap))
		{
			for (key in (input : Map<Dynamic, Dynamic>).keys())
			{
				result.push({key: key, value: input.get(key)});
			}
		}
		// else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		// {
		// 	for (item in (input : Iterable<K>))
		// 	{
		// 		result.push({key: item.key, value: item.value});
		// 	}
		// }
		return result;
	}

	public static inline extern overload function getFromList<T>(list:List<T>, index:Int):T
	{
		return listIndex(list, index);
	}

	public static inline extern overload function getFromList<T>(list:List<T>, func:Predicate<T>):T
	{
		return list.filter(func).first();
	}

	// public static inline extern overload function getFromMap<K, V>(map:Map<K, V>, key:K):V {
	//     return map.get(key);
	// }

	public static extern overload inline function addAndReturn<T>(l:List<T>, item:T):List<T>
	{
		l.add(item);
		return l;
	}

	public static extern overload inline function addAndReturn<K, V>(m:Map<K, V>, key:K, value:V):Map<K, V>
	{
		m.set(key, value);
		return m;
	}

	public static extern overload inline function addAndReturn<T>(a:Array<T>, item:T):Array<T>
	{
		a.push(item);
		return a;
	}

	/**
	 * Calls the provided function `func` with `item` as its argument, then returns `item`.
	 *
	 * @param item The value to be passed to `func` and returned.
	 * @param func A function that takes `item` as its argument and returns void.
	 * @return The original `item`.
	 */
	public static extern overload inline function funcAndReturn<T>(item:T, func:T->Void):T
	{
		func(item);
		return item;
	}

	/**
	 * Calls the provided function `func` with arguments determined by `item`, `a`, and `itemIsArg`, then returns `item`.
	 *
	 * @param item The value to be used as an argument or context for `func`, and returned.
	 * @param func The function to be called. Can be any function or method.
	 * @param a Optional array of additional arguments to pass to `func`.
	 * @param itemIsArg If true, `item` is prepended to the argument list for `func`. If false, only `a` is used as arguments.
	 * @return The original `item`.
	 */
	public static extern overload inline function funcAndReturn<T>(item:T, func:haxe.Constraints.Function, ?a:Array<Dynamic>, ?itemIsArg:Bool):T
	{
		// Helper to resolve FuncAndReturnItem, recursively for extraArgs
		function resolveArg(arg:Dynamic):Dynamic {
			if (Std.is(arg, FuncAndReturnItem)) {
				return switch (cast arg : FuncAndReturnItem<T>) {
					case Item:
						item;
					case TransformedItem(f, extraArgs):
						var resolvedExtraArgs = extraArgs != null ? extraArgs.map(resolveArg) : null;
						if (resolvedExtraArgs != null)
							Reflect.callMethod(item, f, [item].concat(resolvedExtraArgs));
						else
							f(item);
				}
			}
			return arg;
		}

		var args:Array<Dynamic> = [];
		if (itemIsArg) {
			args = [item];
			if (a != null) args = args.concat(a);
		} else if (a != null) {
			args = a.copy();
		}

		// Replace any FuncAndReturnItem in args, recursively
		for (i in 0...args.length) {
			args[i] = resolveArg(args[i]);
		}

		if (args.length > 0)
			Reflect.callMethod(item, func, args);
		else
			func(item);

		return item;
	}

	/**
	 * Calls the provided function `func` with `item` as its argument, then returns `item`.
	 * This version takes `func` as the first argument and `item` as the second.
	 *
	 * @param func A function that takes `item` as its argument and returns void.
	 * @param item The value to be passed to `func` and returned.
	 * @return The original `item`.
	 */
	public static extern overload inline function funcAndReturn<T>(func:T->Void, item:T):T
	{
		return item.funcAndReturn(func);
	}

	/**
	 * Calls the provided function `func` with arguments determined by `item`, `a`, and `itemIsArg`, then returns `item`.
	 * This version takes `func` as the first argument and `item` as the second.
	 *
	 * @param func The function to be called. Can be any function or method.
	 * @param item The value to be used as an argument or context for `func`, and returned.
	 * @param a Optional array of additional arguments to pass to `func`.
	 * @param itemIsArg If true, `item` is prepended to the argument list for `func`. If false, only `a` is used as arguments.
	 * @return The original `item`.
	 */
	public static extern overload inline function funcAndReturn<T>(func:haxe.Constraints.Function, item:T, ?a:Array<Dynamic>, ?itemIsArg:Bool):T
	{
		return item.funcAndReturn(func, a, itemIsArg);
	}

	/**
	 * Shorthand for funcAndReturn. Calls the provided function `func` with `item` as its argument, then returns `item`.
	 *
	 * @param item The value to be passed to `func` and returned.
	 * @param func A function that takes `item` as its argument and returns void.
	 * @return The original `item`.
	 */
	public static extern overload inline function fnr<T>(item:T, func:T->Void):T
	{
		return item.funcAndReturn(func);
	}

	/**
	 * Shorthand for funcAndReturn. Calls the provided function `func` with arguments determined by `item`, `a`, and `itemIsArg`, then returns `item`.
	 *
	 * @param item The value to be used as an argument or context for `func`, and returned.
	 * @param func The function to be called. Can be any function or method.
	 * @param a Optional array of additional arguments to pass to `func`.
	 * @param itemIsArg If true, `item` is prepended to the argument list for `func`. If false, only `a` is used as arguments.
	 * @return The original `item`.
	 */
	public static extern overload inline function fnr<T>(item:T, func:haxe.Constraints.Function, ?a:Array<Dynamic>, ?itemIsArg:Bool):T
	{
		return item.funcAndReturn(func, a, itemIsArg);
	}

	/**
	 * Shorthand for funcAndReturn. Calls the provided function `func` with `item` as its argument, then returns `item`.
	 * This version takes `func` as the first argument and `item` as the second.
	 *
	 * @param func A function that takes `item` as its argument and returns void.
	 * @param item The value to be passed to `func` and returned.
	 * @return The original `item`.
	 */
	public static extern overload inline function fnr<T>(func:T->Void, item:T):T
	{
		return item.funcAndReturn(func);
	}

	/**
	 * Shorthand for funcAndReturn. Calls the provided function `func` with arguments determined by `item`, `a`, and `itemIsArg`, then returns `item`.
	 * This version takes `func` as the first argument and `item` as the second.
	 *
	 * @param func The function to be called. Can be any function or method.
	 * @param item The value to be used as an argument or context for `func`, and returned.
	 * @param a Optional array of additional arguments to pass to `func`.
	 * @param itemIsArg If true, `item` is prepended to the argument list for `func`. If false, only `a` is used as arguments.
	 * @return The original `item`.
	 */
	public static extern overload inline function fnr<T>(func:haxe.Constraints.Function, item:T, ?a:Array<Dynamic>, ?itemIsArg:Bool):T
	{
		return item.funcAndReturn(func, a, itemIsArg);
	}



	public static inline function toList<T>(input:Dynamic):List<Any>
	{
		if (Std.is(input, Array))
		{
			var list = new List<T>();
			for (item in (input : Array<T>))
			{
				list.add(item);
			}
			return list;
		}
		else if (Std.is(input, IMap))
		{
			var list = new List<Any>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				list.add({key: key, value: input.get(key)});
			}
			return list;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var list = new List<T>();
			for (item in (input : Iterable<T>))
			{
				list.add(item);
			}
			return list;
		}
		else
		{
			return new List<T>().addAndReturn(input);
		}
	}


	public static inline function matchRegex(input:String, pattern:EReg):Bool {
		return pattern.match(input);
	}

	/**
	 * Sums a list of numbers provided as a `OneOrMore<FlexibleNum>`.
	 * 
	 * @param numbers A collection containing one or more numbers of type `FlexibleNum`.
	 * @return The sum of all numbers as a `Float`.
	 */

	// Sums a list of numbers (OneOrMore<FlexibleNum>), Array<Float>, or Array<Int>
	public static extern overload inline function sum(numbers:OneOrMore<FlexibleNum>):Float {
		var sum:Float = 0;
		var arr:Array<Float> = cast numbers;
		for (num in arr) {
			sum += num;
		}
		return sum;
	}
	/**
	 * Sums all elements in an array of `Float` values.
	 * 
	 * @param numbers An array of `Float` numbers to sum.
	 * @return The sum of all elements as a `Float`.
	 */
	public static extern overload inline function sum(numbers:Array<Float>):Float {
		return (function() {
			var sum:Float = 0;
			for (n in numbers) {
				sum += n;
			}
			return sum;
		})();
	}
	/**
	 * Sums all elements in an array of `Int` values.
	 * 
	 * @param numbers An array of `Int` numbers to sum.
	 * @return The sum of all elements as a `Float`.
	 */
	public static extern overload inline function sum(numbers:Array<Int>):Float {
		var arr:Array<Float> = [];
		for (n in numbers) arr.push(n);
		return sum(arr);
	}

	public static extern overload inline function sum(number:Float):Float {
		return number;
	}

	public static extern overload inline function sum(number:Int):Float {
		return cast number;
	}

	public static inline function exists(input:Dynamic, ?checkUninitialized:Bool = false):Dynamic {
		if (checkUninitialized) {
			try {
				if (input == null) {
					return false;
				}
				return true;
			} catch (e:Dynamic) {
				return null;
			}
		} else {
			return input != null;
		}
	}

	public static inline function catchWith<T>(tryFunc:Void->T, catchFunc:Dynamic->T):Dynamic {
		return try {
			tryFunc();
		} catch (e:Dynamic) {
			catchFunc(e);
		}
	}

	public static inline function catchWithVoid(tryFunc:Void->Void, catchFunc:Dynamic->Void):Void {
		try {
			tryFunc();
		} catch (e:Dynamic) {
			catchFunc(e);
		}
	}




	public static inline function toArray<T>(input:Dynamic, ?type):Array<Any>
	{
		var arr:Array<Any>;
		if (Std.is(input, Array))
		{
			arr = input;
		}
		else if (Std.is(input, IMap))
		{
			arr = [];
			for (key in (input : Map<Dynamic, T>).keys())
			{
				arr.push({key: key, value: input.get(key)});
			}
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			arr = [];
			for (item in (input : Iterable<T>))
			{
				arr.push(item);
			}
		}
		else
		{
			arr = [input];
		}
		// If type is provided, cast to Array<type>
		return type != null ? cast arr : arr;
	}

	/**
	 * Casts an `Int` to a `Float`.
	 * Only useful for casting Ints to Floats in Abstracts, as the implicit casting is disabled in these cases.
	 */
	public static extern overload inline function asFloat(input:Int):Float
	{
		"Imagine having to do this just because of Abstracts not allowing implicit casting...".NativeComment();
		return cast input;
	}

	/**
	 * Casts a `Float` to a `Float`.
	 * This is just a placeholder to allow for overload resolution in Abstracts where implicit casting is disabled.
	 */
	public static extern overload inline function asFloat(input:Float):Float
	{
		"This doesn't even make sense. Why would you do this?".NativeComment();
		return input;
	}

	/**
	 * Casts an `Array<Int>` to an `Array<Float>`.
	 * This is useful for Abstracts where implicit casting is disabled.
	 */
	public static extern overload inline function asFloat(input:Array<Int>):Array<Float>
	{
		"This is just a workaround for Abstracts not allowing implicit casting...".NativeComment();
		var arr:Array<Float> = [];
		for (n in input) {
			arr.push(cast n);
		}
		return arr;
	}

	/**
	 * Casts an `Array<Float>` to an `Array<Float>`.
	 * This is just a placeholder to allow for overload resolution in Abstracts where implicit casting is disabled.
	 */
	public static extern overload inline function asFloat(input:Array<Float>):Array<Float>
	{
		"This doesn't even make sense. Why would you do this?".NativeComment();
		return input;
	}

	public static inline function forceCast<T>(input:Dynamic, ?type:Suggestion<Class<T>>, ?catchError:Bool = false):T
	{
		try {
			if (type == null || Std.is(input, type))
			{
				return cast input;
			}
			else
			{
				"If you get here, this will 100% throw an error.".NativeComment();
				throw "Cannot force cast " + Std.string(input) + " (type: " + (Type.getClass(input) != null ? Type.getClassName(Type.getClass(input)) : Std.string(Type.typeof(input))) + ") to " + (type != null ? Type.getClassName(type) : "unknown type");
			}
		} catch (e:Dynamic) {
			if (catchError) {
				"Because this is an inline function, this will only appear in this C++ file if you actually have enabled the `catchError` parameter.".NativeComment();
				trace('[forceCast] Error caught: ' + Std.string(e) + '. Hope you can handle a null value now.');
				return null;
			} else {
				throw e;
			}
		}
	}

	// // Version of forceCast which checks basic types like Int, Float, String, etc.
	// public static extern overload inline function forceCast<T>(input:BasicTypes, ?type:Suggestion<Type.ValueType>, ?catchError:Bool = false):T
	// {
	// 	try {
	// 		if (type == null || Type.typeof(input) == type)
	// 		{
	// 			return switch (type) {
	// 				case _ if (type == Type.ValueType.TUnknown):
	// 					// If type is not specified or unknown, try a basic cast
	// 					try {
	// 						cast input;
	// 					} catch (e:Dynamic) {
	// 						throw "forceCast: Could not cast input to requested type (unknown/null type): " + Std.string(e);
	// 					}
	// 				case Type.ValueType.TInt:
	// 					if (Std.is(input, Int)) cast input;
	// 					var parsed = Std.parseInt(Std.string(input));
	// 					if (parsed == null) throw "forceCast: Cannot cast input to Int: " + Std.string(input);
	// 					cast parsed;
	// 				case Type.ValueType.TFloat:
	// 					if (Std.is(input, Float)) cast input;
	// 					var parsed = Std.parseFloat(Std.string(input));
	// 					if (Math.isNaN(parsed)) throw "forceCast: Cannot cast input to Float: " + Std.string(input);
	// 					cast parsed;
	// 				case Type.ValueType.TBool:
	// 					if (Std.is(input, Bool)) cast input;
	// 					var str = Std.string(input).toLowerCase();
	// 					if (str == "true" || str == "1") true;
	// 					if (str == "false" || str == "0") false;
	// 					throw "forceCast: Cannot cast input to Bool: " + Std.string(input);
	// 				case Type.ValueType.TNull:
	// 					null;
	// 				case Type.ValueType.TObject:
	// 					if (Std.is(input, Dynamic)) input;
	// 					try {
	// 						cast input;
	// 					} catch (e:Dynamic) {
	// 						throw "forceCast: Cannot cast input to TObject: " + Std.string(e);
	// 					}
	// 				case Type.ValueType.TFunction:
	// 					if (Std.is(input, haxe.Constraints.Function)) return cast input;
	// 					throw "forceCast: Cannot cast input to Function: " + Std.string(input);
	// 				case Type.ValueType.TClass(c):
	// 					if (Std.is(input, c)) cast input;
	// 					throw "forceCast: Cannot cast input to Class: " + Std.string(input);
	// 				case Type.ValueType.TEnum(e):
	// 					if (Std.is(input, e)) cast input;
	// 					throw "forceCast: Cannot cast input to Enum: " + Std.string(input);
	// 				default:
	// 					cast input.forceCast(); // This will throw an error if the type is not handled
	// 			}
	// 		}
	// 		else
	// 		{
	// 			throw "Cannot force cast " + Std.string(input) + " (type: " + (Type.getClass(input) != null ? Type.getClassName(Type.getClass(input)) : Std.string(Type.typeof(input))) + ") to " + (type != null ? Type.getClassName(type) : "unknown type");
	// 		}
	// 	} catch (e:Dynamic) {
	// 		if (catchError) {
	// 			trace('[forceCastBasic] Error caught: ' + Std.string(e) + '. Returning null.');
	// 			return null;
	// 		} else {
	// 			throw e;
	// 		}
	// 	}
	// }

	public static function getInfinity(t:Dynamic, positive:Bool = true):Dynamic {
		if (Std.isOfType(t, Float)) {
			return positive ? Math.POSITIVE_INFINITY : Math.NEGATIVE_INFINITY;
		} else if (Std.isOfType(t, Int)) {
			var POSITIVE_INFINITY_INT = 0x7fffffff;
			var NEGATIVE_INFINITY_INT = -0x80000000;
			return positive ? POSITIVE_INFINITY_INT : NEGATIVE_INFINITY_INT;
		// } else if (Std.isOfType(t, haxe.Int32)) {
		// 	var POSITIVE_INFINITY_INT32 = 0x7fffffff;
		// 	var NEGATIVE_INFINITY_INT32 = -0x80000000;
		// 	return positive ? POSITIVE_INFINITY_INT32 : NEGATIVE_INFINITY_INT32;
		// } else if (Std.isOfType(t, haxe.Int64)) {
		// 	var POSITIVE_INFINITY_INT64 = haxe.Int64.make(0x7fffffff, 0xffffffff);
		// 	var NEGATIVE_INFINITY_INT64 = haxe.Int64.make(0x80000000, 0x00000000);
		// 	return positive ? POSITIVE_INFINITY_INT64 : NEGATIVE_INFINITY_INT64;
		// } else if (Std.isOfType(t, cpp.Int8)) {
		// 	var POSITIVE_INFINITY_INT8 = 0x7f;
		// 	var NEGATIVE_INFINITY_INT8 = -0x80;
		// 	return positive ? POSITIVE_INFINITY_INT8 : NEGATIVE_INFINITY_INT8;
		// } else if (Std.isOfType(t, cpp.Int16)) {
		// 	var POSITIVE_INFINITY_INT16 = 0x7fff;
		// 	var NEGATIVE_INFINITY_INT16 = -0x8000;
		// 	return positive ? POSITIVE_INFINITY_INT16 : NEGATIVE_INFINITY_INT16;
		// } else if (Std.isOfType(t, UInt)) {
		// 	var POSITIVE_INFINITY_UINT = 0xffffffff;
		// 	return positive ? POSITIVE_INFINITY_UINT : 0;
		// } else if (Std.isOfType(t, cpp.UInt8)) {
		// 	var POSITIVE_INFINITY_UINT8 = 0xff;
		// 	return positive ? POSITIVE_INFINITY_UINT8 : 0;
		// } else if (Std.isOfType(t, cpp.UInt16)) {
		// 	var POSITIVE_INFINITY_UINT16 = 0xffff;
		// 	return positive ? POSITIVE_INFINITY_UINT16 : 0;
		// } else if (Std.isOfType(t, cpp.UInt32)) {
		// 	var POSITIVE_INFINITY_UINT32 = 0xffffffff;
		// 	return positive ? POSITIVE_INFINITY_UINT32 : 0;
		// } else if (Std.isOfType(t, cpp.UInt64)) {
		// 	var POSITIVE_INFINITY_UINT64 = haxe.Int64.make(0xffffffff, 0xffffffff);
		// 	return positive ? POSITIVE_INFINITY_UINT64 : haxe.Int64.make(0, 0);
		// } else if (Std.isOfType(t, Float32)) {
		// 	return positive ? Math.POSITIVE_INFINITY : Math.NEGATIVE_INFINITY;
		} else {
			throw "Unsupported type for infinity";
		}
	}

	public static inline function pushMulti<T>(a:Array<T>, items:Array<T>):{indices:Array<Int>, length:Int}
	{
		var indices = [];
		for (item in items)
		{
			indices.push(a.push(item) - 1);
		}
		return {indices: indices, length: a.length};
	}

	public static inline function concatMulti<T>(a:Array<T>, items:Array<Array<T>>):Array<T>
	{
		for (item in items)
		{
			a.concat(item);
		}
		return a;
	}

	public static inline function concatPush<T>(a:Array<T>, items:Array<Array<T>>):Array<T>
	{
		for (array in items)
		{
			a.pushMulti(array);
		}
		return a;
	}

	public static inline function maybePush<T>(a:Array<T>, item:T, chance:Float):Bool
	{
		if (ChanceExtensions.chanceBool(true, chance))
		{
			a.push(item);
			return true;
		}
		return false;
	}

	public static inline function pushUnique<T>(a:Array<T>, item:T):Bool
	{
		if (a.indexOf(item) == -1)
		{
			a.push(item);
			return true;
		}
		return false;
	}

	public static inline function listIndexOf<T>(list:List<T>, item:T):Int
	{
		var index = 0;
		for (current in list)
		{
			if (current == item)
			{
				return index;
			}
			index++;
		}
		return -1;
	}

	public static function listIndex<T>(list:List<T>, index:Int):T
	{
		var i = 0;
		for (item in list)
		{
			if (i == index)
			{
				return item;
			}
			i++;
		}
		return null;
	}

	// public static inline function getFromList<T>(list:List<T>, func:ListFunc):Dynamic {
	//     switch (func) {
	//         case ListFunc.pop:
	//             return list.pop();
	//         case ListFunc.get(item):
	//             return list.filter(function(i) return i == item).first();
	//     }
	//     return null;
	// }

	public static inline function mapIndexOf<T>(map:Map<Dynamic, T>, item:T):Dynamic
	{
		for (key in map.keys())
		{
			if (map.get(key) == item)
			{
				return key;
			}
		}
		return null;
	}

	public static inline function mapIndex<T>(map:Map<Dynamic, T>, index:Int):Dynamic
	{
		var i = 0;
		for (key in map.keys())
		{
			if (i == index)
			{
				return key;
			}
			i++;
		}
		return null;
	}

	public static inline function mapKYIndexOf<K, V>(map:Map<K, V>, key:K, value:V):Int
	{
		var index = 0;
		for (k in map.keys())
		{
			if (k == key && map.get(k) == value)
			{
				return index;
			}
			index++;
		}
		return -1;
	}

	public static inline function mapKYIndex<K, V>(map:Map<K, V>, index:Int):{key:K, value:V}
	{
		var i = 0;
		for (key in map.keys())
		{
			if (i == index)
			{
				return {key: key, value: map.get(key)};
			}
			i++;
		}
		return null;
	}

	public static inline function fields<T>(input:Dynamic):Array<Dynamic>
	{
		if (Std.is(input, Array))
		{
			var arr:Array<Dynamic> = cast input;
			var result = [];
			for (i in 0...arr.length)
				result.push(i);
			return result;
		}
		else if (Std.is(input, IMap))
		{
			var keys = [];
			for (key in (input : IMap<Dynamic, Dynamic>).keys())
				keys.push(key);
			return keys;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			// For iterables, try to enumerate indices
			var result = [];
			var idx = 0;
			for (_ in (input : Iterable<Dynamic>))
			{
				result.push(idx);
				idx++;
			}
			return result;
		}
		else
		{
			var fields = Reflect.fields(input);
			if (fields.length > 0)
				return fields;
			var cl = Type.getClass(input);
			if (cl != null)
				return Type.getInstanceFields(cl);
			return [];
		}
	}

	public static inline function pressedKeys():Array<flixel.input.keyboard.FlxKey>
	{
		var keys = [];
		for (key in FlxG.keys.pressed.fields())
		{
			keys.push(key);
		}
		return keys;
	}

	public static inline function callOnGeneric<T>(CLASS:Class<T>, func:T->Dynamic):Dynamic
	{
		return func(Type.createEmptyInstance(CLASS));
	}

	public static inline function callFromGeneric<T>(CLASS:Class<T>, func:Any->Dynamic):Dynamic
	{
		return func(Type.createEmptyInstance(CLASS));
	}

	public static inline function toInstance<T>(CLASS:Class<T>, ?args:Array<Dynamic>):T
	{
			return Type.createInstance(CLASS, args != null ? args : []);
	}

	public static inline function hashcode(input:Dynamic):Int
	{
		if (Std.is(input, String))
		{
			var hash = 0;
			for (i in 0...input.length) {
				var char = input.charCodeAt(i);
				hash = (hash * 31 + char) & 0xffffffff;
			}
			return hash;
		}
		else if (Std.is(input, Int) || Std.is(input, Float))
		{
			return Std.int(input);
		}
		else if (Std.is(input, Array))
		{
			return input.hashCode();
		}
		else if (Std.is(input, IMap))
		{
			return input.hashCode();
		}
		else
		{
			return 0;
		}
	}

	public static inline function callOn<T>(item:T, func:T->Dynamic):Dynamic
	{
		return func(item);
	}

	public static inline function mapT<T, R>(input:Dynamic, func:T->R):Dynamic
	{
		if (Std.is(input, Array))
		{
			return (input : Array<T>).map(func);
		}
		else if (Std.is(input, IMap))
		{
			var result = new Map<Dynamic, R>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				result.set(key, func(input.get(key)));
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				result.push(func(item));
			}
			return result;
		}
		else
		{
			return func(input);
		}
	}

	public static inline function filterT<T>(input:Dynamic, func:T->Bool):Dynamic
	{
		if (Std.is(input, Array))
		{
			return (input : Array<T>).filter(func);
		}
		else if (Std.is(input, IMap))
		{
			var result = new Map<Dynamic, T>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				if (func(value))
				{
					result.set(key, value);
				}
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				if (func(item))
				{
					result.push(item);
				}
			}
			return result;
		}
		else
		{
			return func(input) ? input : null;
		}
	}

	public static inline function mapToObject(In:Dynamic):Dynamic
	{
		if (Std.is(In, Array))
		{
			var out = {};
			for (i in 0...(In : Array<Dynamic>).length)
			{
				Reflect.setField(out, Std.string(i), In[i]);
			}
			return out;
		}
		else if (Std.is(In, IMap))
		{
			var out = {};
			for (key in (In : Map<Dynamic, Dynamic>).keys())
			{
				Reflect.setField(out, key, In.get(key));
			}
			return out;
		}
		else if (Reflect.hasField(In, "iterator") || (Reflect.hasField(In, "hasNext") && Reflect.hasField(In, "next")))
		{
			var out = {};
			var i = 0;
			for (item in (In : Iterable<Dynamic>))
			{
				Reflect.setField(out, Std.string(i), item);
				i++;
			}
			return out;
		}
		else
		{
			return In;
		}
	}

	public static inline function enumToObj(In:Dynamic):Dynamic
	{
		var out = {};
		for (field in Type.getEnumConstructs(Type.getEnum(In)))
		{
			Reflect.setField(out, field, Type.createEnum(Type.getEnum(In), field));
		}
		return out;
	}



	public static inline function forEachT<T>(input:Dynamic, func:T->Void):Void
	{
		if (Std.is(input, Array))
		{
			for (item in (input : Array<T>))
			{
				func(item);
			}
		}
		else if (Std.is(input, IMap))
		{
			for (key in (input : Map<Dynamic, T>).keys())
			{
				func(input.get(key));
			}
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			for (item in (input : Iterable<T>))
			{
				func(item);
			}
		}
		else
		{
			func(input);
		}
	}

	public static inline function defaultOf<T>(CLASS:Class<T>):T
	{
		return Type.createEmptyInstance(CLASS);
	}

	public static inline function toIterable<T>(input:Dynamic):Iterable<T>
	{
		if (Std.is(input, Array))
		{
			return input;
		}
		else if (Std.is(input, IMap))
		{
			var result = [];
			for (key in (input : Map<Dynamic, T>).keys())
			{
				result.push(input.get(key));
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			return input;
		}
		else
		{
			return [input];
		}
	}

	public static inline function asCallable<T>(func:T->Void):Void->Void
	{
		return function() func(cast null);
	}

	public static inline function asVoidCallable<T>(func:Void->T):Void->T
	{
		return function() return func();
	}

	public static inline function asVoidCallableWithArgs<T>(func:Void->T):T->Void
	{
		return function(arg:T) return func();
	}

	// Special Functions for ThreadQueue classes.

	/**
	 * Processes a collection using ThreadQueue and waits for completion.
	 * @param items The collection of items to process.
	 * @param action The action to perform on each item.
	 * @param maxConcurrent The maximum number of concurrent threads.
	 */
	public static function processWithThreadQueue<T>(items:Dynamic, action:T->Void, maxConcurrent:Int = 1):Void
	{
		var queue = new ThreadQueue(maxConcurrent, true);
		forEachT(items, function(item:T)
		{
			queue.add(() -> action(item));
		});
		queue.run();
		SyncUtils.wait(() -> queue.length == 0 && queue.done, "Waiting for ThreadQueue to complete...");
	}

	/**
	 * Processes a collection using MemLimitThreadQ and waits for completion.
	 * @param items The collection of items to process.
	 * @param action The action to perform on each item.
	 * @param limit The maximum number of items in the queue.
	 * @param hasty Whether to use softAdd or regular add.
	 */
	public static function processWithMemLimitThreadQ<T>(items:Dynamic, action:T->Void, limit:Int, ?hasty:Bool = false):Void
	{
		var memLimitQueue = new MemLimitThreadQ(items, action, limit, hasty);
		memLimitQueue.run();
		SyncUtils.wait(() -> memLimitQueue.queue.length == 0 && memLimitQueue.queue.done, "Waiting for MemLimitThreadQ to complete...");
	}

	public static function processWithThreadQueueReturn<T, R>(items:Dynamic, action:T->R, maxConcurrent:Int = 1):Array<R>
	{
		var queue = new ThreadQueue(maxConcurrent, true);
		var results = new Array<R>();
		forEachT(items, function(item:T)
		{
			queue.add(() ->
			{
				var result:R = action(item);
				results.push(result);
			});
		});
		queue.run();
		SyncUtils.wait(() -> queue.length == 0 && queue.done, "Waiting for ThreadQueue to complete...");
		return results;
	}

	public static function processWithMemLimitThreadQReturn<T, R>(items:Dynamic, action:T->R, limit:Int, ?hasty:Bool = false):Array<R>
	{
		var results:Array<Any> = items.toArray();
		var memLimitQueue = new MemLimitThreadQ(results, action, limit, hasty);
		memLimitQueue.run();
		SyncUtils.wait(() -> memLimitQueue.queue.length == 0 && memLimitQueue.queue.done, "Waiting for MemLimitThreadQ to complete...");
		var result:Array<R> = cast results;
		// results.push(item);
		return result;
	}

	public static inline function asTypedCallable<T, R>(func:T->R):T->R
	{
		return func;
	}

	public static inline function toCallable<T>(item:T):Void->T
	{
		return function() return item;
	}

	// public static macro function toCallableWithArgs<T>(func:T -> Void):Void -> T {
	//     return function() return func();
	// }

	public static inline function forEachIf<T>(input:Dynamic, predicate:T->Bool, func:T->Void):Void
	{
		if (Std.is(input, Array))
		{
			for (item in (input : Array<T>))
			{
				if (predicate(item))
				{
					func(item);
				}
			}
		}
		else if (Std.is(input, IMap))
		{
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				if (predicate(value))
				{
					func(value);
				}
			}
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			for (item in (input : Iterable<T>))
			{
				if (predicate(item))
				{
					func(item);
				}
			}
		}
		else
		{
			if (predicate(input))
			{
				func(input);
			}
		}
	}

	public static inline function mapTIf<T, R>(input:Dynamic, predicate:T->Bool, func:T->R):Dynamic
	{
		inline function identity<T, R>(value:T):R
		{
			return cast value;
		}

		if (Std.is(input, Array))
		{
			return (input : Array<T>).map(function(item) return predicate(item) ? func(item) : identity(item));
		}
		else if (Std.is(input, IMap))
		{
			var result = new Map<Dynamic, R>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				result.set(key, predicate(value) ? func(value) : cast value);
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				result.push(predicate(item) ? func(item) : cast item);
			}
			return result;
		}
		else
		{
			return predicate(input) ? func(input) : input;
		}
	}

	public static inline function mapIfBreak<T, R>(input:Dynamic, predicate:T->Bool, func:T->R):Dynamic
	{
		if (Std.is(input, Array))
		{
			var result = [];
			for (item in (input : Array<T>))
			{
				if (predicate(item))
				{
					result.push(func(item));
					break;
				}
				else
				{
					// break;
				}
			}
			return result;
		}
		else if (Std.is(input, IMap))
		{
			var result = new Map<Dynamic, R>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				if (predicate(value))
				{
					result.set(key, func(value));
					break;
				}
				else
				{
					// break;
				}
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				if (predicate(item))
				{
					result.push(func(item));
					break;
				}
				else
				{
					// break;
				}
			}
			return result;
		}
		else
		{
			return predicate(input) ? func(input) : input;
		}
	}

	/**
	 * Made to run a "For Loop" similar to how C, and Java do it.
	 */
	public static inline function CForLoop<T>(i:Int, condition:Predicate<Int>, increment:Int->Int, func:Int->Void):Void
	{
		var i = i;
		while (condition(i))
		{
			func(i);
			i = increment(i);
		}
	}

	public static inline function forEachIfElse<T>(input:Dynamic, predicate:T->Bool, ifFunc:T->Void, elseFunc:T->Void):Void
	{
		if (Std.is(input, Array))
		{
			for (item in (input : Array<T>))
			{
				if (predicate(item))
				{
					ifFunc(item);
				}
				else
				{
					elseFunc(item);
				}
			}
		}
		else if (Std.is(input, IMap))
		{
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				if (predicate(value))
				{
					ifFunc(value);
				}
				else
				{
					elseFunc(value);
				}
			}
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			for (item in (input : Iterable<T>))
			{
				if (predicate(item))
				{
					ifFunc(item);
				}
				else
				{
					elseFunc(item);
				}
			}
		}
		else
		{
			if (predicate(input))
			{
				ifFunc(input);
			}
			else
			{
				elseFunc(input);
			}
		}
	}

	public static inline function forEachIfElseTree<T>(input:Dynamic, conditions:Map<T->Bool, T->Void>, elseFunc:T->Void):Void
	{
		if (Std.is(input, Array))
		{
			for (item in (input : Array<T>))
			{
				var matched = false;
				for (predicate in conditions.keys())
				{
					if (predicate(item))
					{
						conditions.get(predicate)(item);
						matched = true;
						break;
					}
				}
				if (!matched)
				{
					elseFunc(item);
				}
			}
		}
		else if (Std.is(input, IMap))
		{
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				var matched = false;
				for (predicate in conditions.keys())
				{
					if (predicate(value))
					{
						conditions.get(predicate)(value);
						matched = true;
						break;
					}
				}
				if (!matched)
				{
					elseFunc(value);
				}
			}
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			for (item in (input : Iterable<T>))
			{
				var matched = false;
				for (predicate in conditions.keys())
				{
					if (predicate(item))
					{
						conditions.get(predicate)(item);
						matched = true;
						break;
					}
				}
				if (!matched)
				{
					elseFunc(item);
				}
			}
		}
		else
		{
			var matched = false;
			for (predicate in conditions.keys())
			{
				if (predicate(input))
				{
					conditions.get(predicate)(input);
					matched = true;
					break;
				}
			}
			if (!matched)
			{
				elseFunc(input);
			}
		}
	}

	public static inline function mapTIfElse<T, R>(input:Dynamic, predicate:T->Bool, ifFunc:T->R, elseFunc:T->R):Dynamic
	{
		if (Std.is(input, Array))
		{
			return (input : Array<T>).map(function(item) return predicate(item) ? ifFunc(item) : elseFunc(item));
		}
		else if (Std.is(input, IMap))
		{
			var result = new Map<Dynamic, R>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				result.set(key, predicate(value) ? ifFunc(value) : elseFunc(value));
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				result.push(predicate(item) ? ifFunc(item) : elseFunc(item));
			}
			return result;
		}
		else
		{
			return predicate(input) ? ifFunc(input) : elseFunc(input);
		}
	}

	public static inline function mapTIfElseTree<T, R>(input:Dynamic, conditions:Map<T->Bool, T->R>, elseFunc:T->R):Dynamic
	{
		if (Std.is(input, Array))
		{
			return (input : Array<T>).map(function(item)
			{
				for (predicate in conditions.keys())
				{
					if (predicate(item))
					{
						return conditions.get(predicate)(item);
					}
				}
				return elseFunc(item);
			});
		}
		else if (Std.is(input, IMap))
		{
			var result = new Map<Dynamic, R>();
			for (key in (input : Map<Dynamic, T>).keys())
			{
				var value = input.get(key);
				for (predicate in conditions.keys())
				{
					if (predicate(value))
					{
						result.set(key, conditions.get(predicate)(value));
						break;
					}
				}
				if (!result.exists(key))
				{
					result.set(key, elseFunc(value));
				}
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				for (predicate in conditions.keys())
				{
					if (predicate(item))
					{
						result.push(conditions.get(predicate)(item));
						break;
					}
				}
				if (result.length == 0)
				{
					result.push(elseFunc(item));
				}
			}
			return result;
		}
		else
		{
			for (predicate in conditions.keys())
			{
				if (predicate(input))
				{
					return conditions.get(predicate)(input);
				}
			}
			return elseFunc(input);
		}
	}

	public static inline function generateRandomString(length:Int):String
	{
		var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
		var str = "";
		for (i in 0...length)
		{
			str += chars.charAt(Std.random(chars.length));
		}
		return str;
	}

	public static inline function generateRandomNumber():Float
	{
		return Math.random() * 1000000;
	}

	public static inline function enumValuesToIterable<T>(enumType:Enum<Dynamic>):Iterable<T>
	{
		return Type.getEnumConstructs(enumType).map(function(name) return Type.createEnum(enumType, name));
	}

	public static inline function enumValuesToArray<T>(enumType:Enum<Dynamic>):Array<T>
	{
		return Type.getEnumConstructs(enumType).map(function(name) return Type.createEnum(enumType, name));
	}

	public static inline function enumToString<T>(enumValue:Enum<Dynamic>):String
	{
		return Type.getEnumName(enumValue);
	}

	public static inline function enumStringList<T>(enumType:Enum<Dynamic>):Array<String>
	{
		return Type.getEnumConstructs(enumType).map(function(name) return name);
	}

	public static inline function isEmpty<T>(input:Dynamic):Bool
	{
		if (Std.is(input, Array))
		{
			return (input : Array<T>).length == 0;
		}
		else if (Std.is(input, IMap))
		{
			return !(input : Map<Dynamic, T>).keys().hasNext();
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			return !(input : Iterable<T>).iterator().hasNext();
		}
		else if (Std.is(input, String))
		{
			return StringTools.trim(input).length == 0;
		}
		else
		{
			return input == null;
		}
	}

	public static inline function isNotEmpty<T>(input:Dynamic):Bool
	{
		return !isEmpty(input);
	}

	public static inline function lengthTo<T>(input:Dynamic):Int
	{
		if (!exists(input, true))
		{
			return 0;
		}
		else if (Std.is(input, Array))
		{
			return (input : Array<T>).length;
		}
		else if (Std.is(input, IMap))
		{
			return (input : Map<Dynamic, T>).toArray().length;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var length = 0;
			for (item in (input : Iterable<T>))
			{
				length++;
			}
			return length;
		}
		else if (Std.is(input, String))
		{
			return (input).length;
		}
		else
		{
			return 0;
		}
	}

	// Only for Funkin Lua Legacy...

	public static inline function getScriptName(s:LuaScript):String
	{
		return switch (Type.getClass(s)) {
		case psychlua.FunkinLua:
			(s : psychlua.FunkinLua).scriptName;
		case psychlua.LegacyFunkinLua:
			(s : psychlua.LegacyFunkinLua).scriptName;
		default:
			throw "Unsupported LuaScript type";
		}
	}

	public static inline function callScript(s:LuaScript, funcName:String, args:Array<Dynamic>):Dynamic
	{
		return switch (Type.getClass(s)) {
		case psychlua.FunkinLua:
			(s : psychlua.FunkinLua).call(funcName, args);
		case psychlua.LegacyFunkinLua:
			(s : psychlua.LegacyFunkinLua).call(funcName, args);
		default:
			throw "Unsupported LuaScript type";
		}
	}

	public static inline function getScript(s:LuaScript):Dynamic
	{
		return switch (Type.getClass(s)) {
		case psychlua.FunkinLua:
			(s : psychlua.FunkinLua);
		case psychlua.LegacyFunkinLua:
			(s : psychlua.LegacyFunkinLua);
		default:
			throw "Unsupported LuaScript type";
		}
	}


	public static function createTestData():Void
	{
		var stringArray = [];
		var numberArray = [];
		var stringMap = new StringMap<String>();
		var numberMap = new StringMap<Float>();

		for (i in 0...1000)
		{
			var randomString = generateRandomString(100);
			var randomNumber = generateRandomNumber();
			stringArray.push(randomString);
			numberArray.push(randomNumber);
			stringMap.set("key" + i, randomString);
			numberMap.set("key" + i, randomNumber);
		}

		// Test mapT function
		trace("Testing mapT function:");
		trace(mapT(stringArray, function(s) return s.toUpperCase()));
		trace(mapT(numberArray, function(n) return n * 2));
		trace(mapT(stringMap, function(s) return s.toUpperCase()));
		trace(mapT(numberMap, function(n) return n * 2));

		// Test filterT function
		trace("Testing filterT function:");
		trace(filterT(stringArray, function(s) return s.length > 50));
		trace(filterT(numberArray, function(n) return n > 500000));
		trace(filterT(stringMap, function(s) return s.length > 50));
		trace(filterT(numberMap, function(n) return n > 500000));

		// Test forEachT function
		trace("Testing forEachT function:");
		forEachT(stringArray, function(s) trace(s));
		forEachT(numberArray, function(n) trace(n));
		forEachT(stringMap, function(s) trace(s));
		forEachT(numberMap, function(n) trace(n));

		// Test ChanceSelector functions
		trace("Testing ChanceSelector functions:");

		// Create chances for stringArray
		var stringChances = ChanceSelector.fromArray(stringArray);
		trace("String chances: " + stringChances);

		// Select a random string from stringArray
		var selectedString = ChanceSelector.selectOption(stringChances);
		trace("Selected string: " + selectedString);

		// Create chances for numberArray
		var numberChances = ChanceSelector.fromArray(numberArray);
		trace("Number chances: " + numberChances);

		// Select a random number from numberArray
		var selectedNumber = ChanceSelector.selectOption(numberChances);
		trace("Selected number: " + selectedNumber);

		// Create chances for stringMap
		var stringMapChances = ChanceExtensions.chanceDynamicMap(stringMap);
		trace("String map chances: " + stringMapChances);
		// Select a random string from stringMap
		// var selectedStringFromMap = ChanceSelector.selectOption(stringMapChances);
		// trace("Selected string from map: " + selectedStringFromMap);

		// Create chances for numberMap using ChanceExtension's chanceDynamicMap
		var numberMapChances = ChanceExtensions.chanceDynamicMap(numberMap);
		trace("Number map chances: " + numberMapChances);

		// // Select a random number from numberMap
		// var selectedNumberFromMap = ChanceSelector.selectOption(numberMapChances);
		// trace("Selected number from map: " + selectedNumberFromMap);
	}
}

// class CollectionMacro {

// 	macro public static function infinity<T>(t:Dynamic, ?positive:Bool = true):Dynamic {
// 		return macro CollectionUtils.getInfinity(t, true);
// 	}
// }
