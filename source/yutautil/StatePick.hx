package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Type;

class StatePick
{
	// Build-time storage for macro processing
	#if macro
	private static final StateMapBuildTime:Map<String, Array<String>> = new Map<String, Array<String>>();
	private static var activated:Bool = false;
	private static var showedArray:Bool = false;
	private static var resourceGenerated:Bool = false;
	#end



	public static macro function addToDatabase(base):Array<Field>
	{
		if (!activated)
		{
			activated = true;
			trace('StatePick is now scanning applied states...');

			// Use onGenerate instead of onAfterGenerate to ensure resources are added in time
			Context.onGenerate(function(types:Array<Type>) {
				generateRuntimeStateMap();
			});
		}

		var parent = haxe.macro.ExprTools.toString(base);
		var names = StateMapBuildTime[parent];
		if (names == null)
		{
			names = new Array<String>();
			StateMapBuildTime[parent] = names;
		}
		names.push(Context.getLocalClass().toString());

		#if verbose
		trace('Scanned state: $parent -> ${Context.getLocalClass().toString()}');
		#end

		return null;
	}

	#if macro
	private static function generateRuntimeStateMap():Void
	{
		if (resourceGenerated) return; // Only generate once
		resourceGenerated = true;

		if (!showedArray)
		{
			#if verbose
			trace('StatePick: Registered states: $StateMapBuildTime');
			#end
			showedArray = true;
		}

		// Create JSON data that will be embedded as a resource
		var jsonData = haxe.Json.stringify(StateMapBuildTime);

		// Add the data as a resource
		try {
			Context.addResource("statePickData", haxe.io.Bytes.ofString(jsonData));
			trace('StatePick: Added resource "statePickData" with ${Lambda.count(StateMapBuildTime)} base classes');
		} catch (e:Dynamic) {
			trace('StatePick: Failed to add resource: $e');
		}
	}
	#end

	public static function getStateNames(base:String):Array<String>
	{
		ensureInitialized();
		return StateMapStorage.getStateArray(base);
	}

	public static function getSubStates(base:String):Array<Class<Dynamic>>
	{
		ensureInitialized();
		if (!StateMapStorage.stateMapExists(base)) return [];

		return StateMapStorage.getStateArray(base)
			.filter(function(name) return name != base)
			.map(function(name) return Type.resolveClass(name))
			.filter(function(cls) return cls != null);
	}

	public static function getAllBaseBases():Array<String>
	{
		ensureInitialized();
		return [for (key in StateMapStorage.getStateMapKeys()) key];
	}

	private static function ensureInitialized():Void
	{
		if (StateMapStorage.getStateMap() == null)
		{
			StateMapStorage.initializeStateMap();
		}
	}
}
