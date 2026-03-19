package yutautil;

import haxe.Constraints.IMap;
import haxe.ds.IntMap;
import haxe.ds.StringMap;

/**
 * Verbosity levels for natural printing:
 * - MINIMAL: Just type name (e.g., "Array" or "MyClass")
 * - COMPACT: Type with brief content (e.g., "Array of String containing 3 items")
 * - DETAILED: Type with all contents listed (e.g., "Array of String containing "a", "b", "c"")
 * - VERBOSE: Detailed with class fields and full descriptions
 */
enum Verbosity {
	MINIMAL;
	COMPACT;
	DETAILED;
	VERBOSE;
}

/**
 * Display formatter providing pretty printing (pprint-style) and natural language printing.
 * Pretty printing structures complex objects for readability.
 * Natural printing generates human-readable descriptions with configurable verbosity.
 */
class DisplayFormatter
{
	private static var indentSize:Int = 4;
	private static var maxLineWidth:Int = 100;
	private static var maxDepth:Int = 10;

	/**
	 * Pretty print an object with structural formatting (Python pprint style)
	 */
	public static function prettyPrint(obj:Dynamic, ?depth:Int = 0):String
	{
		if (depth > maxDepth)
			return "...";

		var indent = StringTools.lpad("", " ", depth * indentSize);
		var nextIndent = StringTools.lpad("", " ", (depth + 1) * indentSize);

		// Handle null
		if (obj == null)
			return "null";

		// Handle primitives
		if (Std.isOfType(obj, Bool))
			return obj ? "true" : "false";

		if (Std.isOfType(obj, Int) || Std.isOfType(obj, Float))
			return Std.string(obj);

		if (Std.isOfType(obj, String))
			return '"${Std.string(obj).split('"').join('\\"')}"';

		// Handle arrays
		if (Std.isOfType(obj, Array))
		{
			var arr:Array<Dynamic> = cast obj;
			if (arr.length == 0)
				return "[]";

			var items = [];
			for (item in arr)
			{
				var itemStr = prettyPrint(item, depth + 1);
				// Indent multi-line items
				if (StringTools.contains(itemStr, "\n"))
				{
					var lines = itemStr.split("\n");
					items.push(lines[0]);
					for (i in 1...lines.length)
						items.push(StringTools.lpad("", " ", indentSize) + lines[i]);
				}
				else
				{
					items.push(itemStr);
				}
			}

			var itemStr = items.join(",\n" + nextIndent);
			return "[\n" + nextIndent + itemStr + "\n" + indent + "]";
		}

		// Handle maps
		if (Std.isOfType(obj, StringMap) || Std.isOfType(obj, IntMap) || Type.getClass(obj) == null)
		{
			var fields = Reflect.fields(obj);
			if (fields.length == 0)
				return "{}";

			var items = [];
			for (field in fields)
			{
				var value = Reflect.field(obj, field);
				var valueStr = prettyPrint(value, depth + 1);
				if (StringTools.contains(valueStr, "\n"))
				{
					var lines = valueStr.split("\n");
					var fieldLine = '"' + field + '": ' + lines[0];
					items.push(fieldLine);
					for (i in 1...lines.length)
						items.push(StringTools.lpad("", " ", indentSize) + lines[i]);
				}
				else
				{
					items.push('"' + field + '": ' + valueStr);
				}
			}

			var itemStr = items.join(",\n" + nextIndent);
			return "{\n" + nextIndent + itemStr + "\n" + indent + "}";
		}

		// Handle objects/classes
		var className = Type.getClassName(Type.getClass(obj));
		if (className != null)
		{
			var fields = Reflect.fields(obj);
			if (fields.length == 0)
				return '<${className} {}>';

			var items = [];
			for (field in fields)
			{
				var value = Reflect.field(obj, field);
				// Skip methods
				if (!Reflect.isFunction(value))
				{
					var valueStr = prettyPrint(value, depth + 1);
					if (StringTools.contains(valueStr, "\n"))
					{
						var lines = valueStr.split("\n");
						var fieldLine = field + ': ' + lines[0];
						items.push(fieldLine);
						for (i in 1...lines.length)
							items.push(StringTools.lpad("", " ", indentSize) + lines[i]);
					}
					else
					{
						items.push(field + ': ' + valueStr);
					}
				}
			}

			if (items.length == 0)
				return '<${className} {}>';

			var itemStr = items.join(",\n" + nextIndent);
			return '<${className} {\n' + nextIndent + itemStr + '\n' + indent + '}>';
		}

		return Std.string(obj);
	}

	/**
	 * Generate a natural language description of an object
	 */
	public static function naturalPrint(obj:Dynamic, ?verbosity:Verbosity = DETAILED):String
	{
		if (verbosity == null)
			verbosity = DETAILED;
		return naturalPrintInternal(obj, verbosity);
	}

	private static function naturalPrintInternal(obj:Dynamic, verbosity:Verbosity):String
	{
		// Handle null
		if (obj == null)
			return "null";

		// Handle primitives
		if (Std.isOfType(obj, Bool))
			return obj ? "true" : "false";

		if (Std.isOfType(obj, Int))
			return 'An Int with value ${obj}';

		if (Std.isOfType(obj, Float))
		{
			var floatVal:Float = cast obj;
			return 'A Float with value ${floatVal}';
		}

		if (Std.isOfType(obj, String))
		{
			var str:String = cast obj;
			var escaped = str.split('"').join('\\"');
			return 'A String containing "${escaped}"';
		}

		// Handle arrays
		if (Std.isOfType(obj, Array))
		{
			var arr:Array<Dynamic> = cast obj;
			if (arr.length == 0)
				return "An empty Array";

			var elementType = getIndividualElementType(arr);

			switch (verbosity)
			{
				case MINIMAL:
					return 'An Array of ${elementType}';
				case COMPACT:
					return 'An Array of ${elementType} containing ${arr.length} item${arr.length != 1 ? "s" : ""}';
				case DETAILED:
					var items = [];
					for (item in arr)
						items.push(formatArrayElement(item));
					var itemList = joinWithAnd(items);
					return 'An Array of ${elementType} containing ${itemList}';
				case VERBOSE:
					var items = [];
					for (i in 0...arr.length)
					{
						var item = arr[i];
						items.push('[${i}]: ${formatArrayElement(item)}');
					}
					var itemList = items.join(",\n  ");
					return 'An Array of ${elementType} containing ${arr.length} items:\n  ${itemList}';
			}
		}

		// Handle maps
		var isMap = false;
		var mapFields:Array<String> = [];
		if (Std.isOfType(obj, StringMap) || Std.isOfType(obj, IntMap))
		{
			isMap = true;
			mapFields = Reflect.fields(obj);
		}

		if (isMap && mapFields.length > 0)
		{
			switch (verbosity)
			{
				case MINIMAL:
					return 'A Map';
				case COMPACT:
					return 'A Map containing ${mapFields.length} entr${mapFields.length != 1 ? "ies" : "y"}';
				case DETAILED:
					var items = [];
					for (field in mapFields)
					{
						var value = Reflect.field(obj, field);
						items.push('"${field}": ${stripArticle(naturalPrintInternal(value, COMPACT))}');
					}
					var itemList = joinWithAnd(items);
					return 'A Map containing ${itemList}';
				case VERBOSE:
					var items = [];
					for (field in mapFields)
					{
						var value = Reflect.field(obj, field);
						items.push('"${field}": ${naturalPrintInternal(value, DETAILED)}');
					}
					var itemList = items.join(",\n  ");
					return 'A Map containing ${mapFields.length} entries:\n  ${itemList}';
			}
		}

		// Handle classes/objects
		var className = getTypeName(obj);

		var fields = Reflect.fields(obj);
		var publicFields = fields.filter(f -> !Reflect.isFunction(Reflect.field(obj, f)));

		if (publicFields.length == 0)
		{
			switch (verbosity)
			{
				case MINIMAL:
					return 'A Class of ${className}';
				case COMPACT | DETAILED:
					return 'A Class of ${className} with no public fields';
				case VERBOSE:
					return 'An instance of ${className}\n  This object has no public fields.';
			}
		}

		switch (verbosity)
		{
			case MINIMAL:
				return 'A Class of ${className}';
			case COMPACT:
				return 'A Class of ${className} with ${publicFields.length} field${publicFields.length != 1 ? "s" : ""}';
			case DETAILED:
				var fieldDescriptions = [];
				for (field in publicFields)
				{
					var value = Reflect.field(obj, field);
					var desc = stripArticle(naturalPrintInternal(value, COMPACT));
					fieldDescriptions.push('${field}: ${desc}');
				}
				var fieldList = joinWithAnd(fieldDescriptions);
				return 'A Class of ${className} with fields: ${fieldList}';
			case VERBOSE:
				var fieldDescriptions = [];
				for (field in publicFields)
				{
					var value = Reflect.field(obj, field);
					var desc = naturalPrintInternal(value, DETAILED);
					fieldDescriptions.push('${field}: ${desc}');
				}
				var fieldList = fieldDescriptions.join(",\n  ");
				return 'An instance of ${className} with ${publicFields.length} public field${publicFields.length != 1 ? "s" : ""}:\n  ${fieldList}';
		}
	}

	/**
	 * Get the element type of an array
	 */
	private static function getIndividualElementType(arr:Array<Dynamic>):String
	{
		if (arr.length == 0)
			return "Dynamic";

		var types:Map<String, Bool> = new Map();
		for (item in arr)
		{
			var type = getTypeName(item);
			types.set(type, true);
		}

		var typeList = [for (t in types.keys()) t];

		if (typeList.length == 1)
			return typeList[0];
		if (typeList.length == 2)
			return typeList[0] + " or " + typeList[1];

		var result = "";
		for (i in 0...typeList.length)
		{
			if (i > 0)
				result += i < typeList.length - 1 ? ", " : ", or ";
			result += typeList[i];
		}
		return result;
	}

	/**
	 * Format a single array element for display
	 */
	private static function formatArrayElement(item:Dynamic):String
	{
		if (Std.isOfType(item, String))
		{
			var str:String = cast item;
			var escaped = str.split('"').join('\\"');
			return '"${escaped}"';
		}

		if (Std.isOfType(item, Int) || Std.isOfType(item, Float))
			return Std.string(item);

		if (Std.isOfType(item, Bool))
			return item ? "true" : "false";

		if (item == null)
			return "null";

		var className = getTypeName(item);
		return className;
	}

	/**
	 * Get a human-readable type name
	 */
	private static function getTypeName(obj:Dynamic):String
	{
		if (obj == null)
			return "Null";

		if (Std.isOfType(obj, String))
			return "String";

		if (Std.isOfType(obj, Bool))
			return "Bool";

		if (Std.isOfType(obj, Int))
			return "Int";

		if (Std.isOfType(obj, Float))
			return "Float";

		if (Std.isOfType(obj, Array))
			return "Array";

		var cls = Type.getClass(obj);
		if (cls != null)
		{
			var className = Type.getClassName(cls);
			if (className != null)
		return className.split(".").pop();
		}

		return "Dynamic";
	}

	/**
	 * Join an array of items with commas and "and"
	 * ["a", "b", "c"] -> "a, b, and c"
	 */
	private static function joinWithAnd(items:Array<String>):String
	{
		if (items.length == 0)
			return "";
		if (items.length == 1)
			return items[0];
		if (items.length == 2)
			return items[0] + " and " + items[1];

		var result = "";
		for (i in 0...items.length)
		{
			if (i > 0)
				result += i < items.length - 1 ? ", " : ", and ";
			result += items[i];
		}
		return result;
	}

	/**
	 * Strip the leading article from a string (e.g., "A", "An")
	 */
	private static function stripArticle(text:String):String
	{
		if (StringTools.startsWith(text, "A "))
			return text.substring(2);
		if (StringTools.startsWith(text, "An "))
			return text.substring(3);
		return text;
	}

	/**
	 * Configure display formatter settings
	 */
	public static function configure(?indent:Int, ?lineWidth:Int, ?depth:Int):Void
	{
		if (indent > 0)
			indentSize = indent;
		if (lineWidth > 0)
			maxLineWidth = lineWidth;
		if (depth > 0)
			maxDepth = depth;
	}
}
