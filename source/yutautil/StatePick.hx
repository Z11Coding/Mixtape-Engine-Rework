package yutautil;

import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Printer;
import haxe.macro.Expr;

class StatePick
{
	private static final StateMap:Map<String, Array<String>> = new Map<String, Array<String>>();
	private static var activated:Bool = false;
	private static var showedArray:Bool = false;

	public static macro function addToDatabase(base):Array<Field>
	{
		if (!activated)
		{
			activated = true;
			trace('StatePick is now scanning applied states...');
		}
		var parent = haxe.macro.ExprTools.toString(base);
		var names = StateMap[parent];
		if (names == null)
		{
			names = new Array<String>();
			StateMap[parent] = names;
		}
		names.push(Context.getLocalClass().toString());

		trace('Scanned state: $parent -> ${Context.getLocalClass().toString()}');

		Context.onAfterGenerate(function()
		{
			if (!showedArray)
			{
				trace('StatePick: Registered states: $StateMap');
				showedArray = true;
			}
		});
		return null;
	}

	public static inline function getStateNames(base:String):Array<String>
	{
		return StateMap[base] != null ? StateMap[base] : [];
	}

	public static inline function getSubStates(base:String):Array<Class<Dynamic>>
	{
		return StateMap[base] != null ? StateMap[base].filter(function(name) return name != base).map(function(name) return Type.resolveClass(name)) : [];
	}
}
