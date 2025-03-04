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

	private static function list<T>(l:List<T>):List<T>
	{
		return l;
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

	public static inline function funcAndReturn<T>(func:T->Void, item:T):T
	{
		func(item);
		return item;
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

	public static inline function toArray<T>(input:Dynamic, ?type):Array<Any>
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
				result.push({key: key, value: input.get(key)});
			}
			return result;
		}
		else if (Reflect.hasField(input, "iterator") || (Reflect.hasField(input, "hasNext") && Reflect.hasField(input, "next")))
		{
			var result = [];
			for (item in (input : Iterable<T>))
			{
				result.push(item);
			}
			return result;
		}
		else
		{
			return [input];
		}
	}

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

	public static inline function callOnGeneric<T>(CLASS:Class<T>, func:T->Dynamic):Dynamic
	{
		return func(Type.createEmptyInstance(CLASS));
	}

	public static inline function callFromGeneric<T>(CLASS:Class<T>, func:Any->Dynamic):Dynamic
	{
		return func(Type.createEmptyInstance(CLASS));
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
		if (Std.is(input, Array))
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
			return 1;
		}
	}

	// Only for Funkin Lua Legacy...

	/*public static inline function getScriptName(s:LuaScript):String
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
	}*/


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
