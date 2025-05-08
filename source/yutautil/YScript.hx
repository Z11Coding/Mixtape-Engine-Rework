package yutautil;

import cpp.Star;
import haxe.Constraints.Function;
import haxe.ds.StringMap;

typedef YVar =
{
	name:String,
	type:Dynamic,
	?value:Dynamic,
	pointer:
	{
		haxePointer:cpp.RawPointer<Dynamic>, ?virtualPointer:Int
	}
};

typedef YStruct =
{
	name:String,
	fields:Array<YVar>
};

typedef YEnum =
{
	name:String,
	values:Array<String>,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
};

typedef YEnumValue =
{
	name:String,
	value:Int,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
};

typedef YInterface =
{
	name:String,
	fields:Array<YVar>,
	methods:Array<YFunction>,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
};

typedef YBaseClass =
{
	name:String,
	fields:Array<YVar>,
	methods:Array<YFunction>,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
	extending:Array<YClass<Dynamic>>,
	implementing:Array<YInterface>,
	constructors:Array<YFunction>,
	destructors:Array<YFunction>,
};

typedef YTypedClass<T> =
{
	name:String,
	fields:Array<YVar>,
	methods:Array<YFunction>,
	type:Dynamic,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
	extending:Array<YClass<T>>,
	implementing:Array<YInterface>,
	constructors:Array<YFunction>,
	destructors:Array<YFunction>,
};

typedef YClass<T> = flixel.util.typeLimit.OneOfTwo<YBaseClass, YTypedClass<T>>;

typedef YClassInstance<T> =
{
	name:String,
	fields:Array<YVar>,
	methods:Array<YFunction>,
	type:Dynamic,
	CLASS:YClass<T>,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
	extending:flixel.util.typeLimit.OneOfTwo<YClass<T>, Class<T>>,
	implementing:Array<YInterface>,
	constructors:Array<YFunction>,
	destructors:Array<YFunction>,
	?haxeClassInstance:Dynamic, // Haxe class instance, if this is a YClass extending a Haxe class.
};

typedef YFunction =
{
	name:String,
	returnType:Dynamic,
	parameters:Array<YVar>,
	body:String,
	parseBody:YSyntaxAST,
	functionData:Function,
	type:
	{ // Private and Protected are reversed from how Java does it, as it makes sense when interfacing with Haxe.
		isLambda:Bool, isClosure:Bool, isMethod:Bool, isStatic:Bool, isConstructor:Bool, isDestructor:Bool, isVirtual:Bool, isAbstract:Bool, isOverride:Bool,
		isFinal:Bool, isNative:Bool, isLua:Bool, isHaxe:Bool, isC:Bool, isCPlusPlus:Bool, isForLoop:Bool, isWhileLoop:Bool,
	},
	access:
	{
		isPublic:Bool, isPrivate:Bool, isProtected:Bool, isInternal:Bool, isDynamic:Bool
	},
	attachment:Array<Dynamic> // Attachment shows what this function is a part of, class, variable, struct, etc.
};

typedef YFunctionCall =
{
	func:YFunction,
	args:Array<Dynamic>,
	?returnType:Dynamic,
	?returnValue:Dynamic,
	?returnPointer:{haxePointer:cpp.RawPointer<Dynamic>, ?virtualPointer:Int}
};

typedef YUse =
{
	name:String,
	?alias:String,
	?type:Dynamic, // Type of the use, since this is for importing outside types.
};

typedef YFor =
{
	body:YFunction,
	condition:YVar,
	iterator:Dynamic,
}

typedef YWhile =
{
	body:YFunction,
	condition:YVar,
	?doBody:YDo,
}

typedef YDo =
{
	body:YFunction,
	condition:YVar,
}

typedef YIf =
{
	body:YFunction,
	condition:YVar,
	elseBody:YElse,
};

typedef YElse =
{
	body:YFunction,
	?condition:YVar,
};

typedef YSwitch =
{
	body:YFunction,
	condition:YVar,
	cases:Array<YCase>
};

typedef YCase =
{
	condition:YVar,
	body:YFunction
};

typedef YReturn =
{
	value:Dynamic
};

typedef YBreak =
{
	value:Dynamic
};

typedef YContinue =
{
	value:Dynamic
};

typedef YImport =
{
	name:String,
	alias:String
};

typedef YClosure =
{
	name:String,
	parameters:Array<YVar>,
	body:YFunction
};

typedef YLambda =
{
	name:String,
	parameters:Array<YVar>,
	body:YFunction
};

typedef YLambdaExpr =
{
	name:String,
	param:String,
	body:YFunction
};

typedef YLambdaCall =
{
	func:YLambdaExpr,
	arg:YLambdaExpr
};

typedef YLambdaReduce =
{
	func:YLambdaExpr,
	arg:YLambdaExpr
};

typedef YLambdaToString =
{
	name:String,
	param:String,
	body:YFunction
};

typedef YLambdaTokenize =
{
	name:String,
	param:String,
	body:YFunction
};

typedef YLuaTable =
{
	name:String,
	fields:Array<YVar>
};

typedef YLuaImport =
{ // Treated like a class, uses a Lua script as a class
	name:String,
	alias:String,
	script:llua.State
};

typedef YHaskellExpr =
{
	name:String,
	param:String,
	body:YFunction
};

typedef YHaskellCall =
{
	func:YHaskellExpr,
	arg:YHaskellExpr
};

typedef HaxeBlock =
{
	name:String,
	param:String,
	body:YFunction
};

typedef HaxeCall =
{
	func:HaxeBlock,
	arg:HaxeBlock
};

typedef HaxeExpr =
{
	name:String,
	param:String,
	body:YFunction
};

typedef LuaBlock =
{
	name:String,
	param:String,
	body:YFunction
};

typedef LuaCall =
{
	func:LuaBlock,
	arg:LuaBlock
};

typedef LuaExpr =
{
	name:String,
	param:String,
	body:YFunction
};

typedef CBlock =
{
	name:String,
	param:String,
	body:YFunction
};

typedef CCall =
{
	func:CBlock,
	arg:CBlock
};

typedef CExpr =
{
	name:String,
	param:String,
	body:YFunction
};

typedef CPlusPlusBlock =
{
	name:String,
	param:String,
	body:YFunction
};

typedef CPlusPlusCall =
{
	func:CPlusPlusBlock,
	arg:CPlusPlusBlock
};

typedef CPlusPlusExpr =
{
	name:String,
	param:String,
	body:YFunction
};

class YScriptError extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

class YscriptException extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

class YScriptParseError extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

class YScriptRuntimeError extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

class YScriptTypeError extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

class YScriptSyntaxError extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

class YScriptSemanticError extends haxe.Exception
{
	public function new(message:String)
	{
		super(message, null, null);
	}
}

typedef YSyntaxAST = Array<Dynamic>;

class YScriptSyntaxTree
{
	var tree:YSyntaxAST;
	var currentNode:Dynamic;
	var currentIndex:Int;
	var currentLine:Int;
	var currentColumn:Int;

	public function new()
	{
		tree = [];
		currentNode = null;
		currentIndex = 0;
		currentLine = 0;
		currentColumn = 0;
	}

	public function addNode(node:Dynamic):Void
	{
		tree.push(node);
		currentNode = node;
		currentIndex++;
	}

	public function getNode(index:Int):Dynamic
	{
		if (index < 0 || index >= tree.length)
			throw "Index out of bounds: " + index;
		return tree[index];
	}

	public function getCurrentNode():Dynamic
	{
		return currentNode;
	}

	public function getCurrentIndex():Int
	{
		return currentIndex;
	}

	// More builders.
	public function buildFunction(name:String, parameters:Array<YVar>, body:YSyntaxAST):YSyntaxAST
	{
		var funcNode = {
			type: "function",
			name: name,
			parameters: parameters,
			body: body
		};
		addNode(funcNode);
		return [funcNode];
	}
}

// A Scripting Language which has a lot of control over the game, and is used to create mods for the game.
// It also has native control over types, and can be used to create new types, and modify existing ones.
// It is planned to also have compatibility with Lua, and Haxe, and be able to run Lua scripts, and Haxe scripts, as well as be able to run C++ code and C code directly in the future.
class YScript
{
    private var keywords:Map<String, EReg> = [
        // ———————— Type & Block Definitions ————————
        "class"     => ~/\bclass\s+\w+
                   (?:\s+extends\s+[\w\.]+)?
                   (?:\s+implements\s+[\w\.]+(?:\s*,\s*[\w\.]+)*)?
                   \s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a class definition, optionally with 'extends' and/or 'implements' clauses, and its body.

        "enum"      => ~/\benum\s+\w+\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches an enum definition with its body.

        "struct"    => ~/\bstruct\s+\w+\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a struct definition with its body.

        "interface" => ~/\binterface\s+\w+\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches an interface definition with its body.

        "const"     => ~/\bconst\s+\w+\s*:\s*[\w\.<>\[\]]+\s*=\s*[\s\S]*?;/s,
        // Matches a constant definition with a type and an initializer.

        "var"       => ~/\bvar\s+\w+\s*:\s*[\w\.<>\[\]]+\s*=\s*[\s\S]*?;/s,
        // Matches a variable definition with a type and an initializer.

        "function"  => ~/\bfunction\s+\w+\s*\([^)]*\)\s*:\s*[\w\.<>\[\]]+
                   \s*(?:haxe|lua)?\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a function definition with parameters, return type, and body.

        "if"        => ~/\bif\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches an 'if' statement with its condition and body.

        "else"      => ~/\belse\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches an 'else' statement with its body.

        "switch"    => ~/\bswitch\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a 'switch' statement with its condition and body.

        "case"      => ~/\bcase\b[^:]*:\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a 'case' statement with its condition and body.

        "default"   => ~/\bdefault:\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a 'default' statement with its body.

        "while"     => ~/\bwhile\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a 'while' loop with its condition and body.

        "do"        => ~/\bdo\s*\{(?:[^{}]|\{[^{}]*\})*\}\s*while\s*\([\s\S]*?\)\s*;/s,
        // Matches a 'do-while' loop with its body and condition.

        "for"       => ~/\bfor\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a 'for' loop with its initializer, condition, and body.

        "return"    => ~/\breturn\b[\s\S]*?;/s,
        // Matches a 'return' statement with an optional value.

        "break"     => ~/\bbreak\b\s*;/s,
        // Matches a 'break' statement.

        "continue"  => ~/\bcontinue\b\s*;/s,
        // Matches a 'continue' statement.

        "use"       => ~/\buse\s+[\w\.]+(?:\s+as\s+\w+)?\s*;/s,
        // Matches a 'use' statement for importing modules or aliases.

        "haxe"      => ~/\bhaxe\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
        // Matches a block of Haxe code embedded in the script.

        "lua"       => ~/\blua\s*\{(?:[^{}]|\{[^{}]*\})*\}/s
        // Matches a block of Lua code embedded in the script.
    ];

    public var varTable:Map<String, YVar>;
    public var structTable:Map<String, YStruct>;
    public var classTable:Map<String, YClass<Dynamic>>;
    public var enumTable:Map<String, YEnum>;
    public var functionTable:Map<String, YFunction>;
    public var useTable:Map<String, YUse>;
    public var importTable:Map<String, YImport>;
    public var luaTable:Map<String, YLuaImport>;

    public function new()
    {
        // Initialization logic if needed
    }

	public function parse(script:String):Void
	{
		var lines = script.split("\n");
		for (line in lines)
		{
			line = line.trim();
			if (line == "" || line.startsWith("//"))
				continue; // Skip empty lines and comments

			try
			{
				parseLine(line);
			}
			catch (e:Dynamic)
			{
				trace("Error parsing line: " + line + "\n" + e);
			}
		}
	}

	private function parseLine(line:String):Void
	{
		if (line.indexOf(";") == -1)
			throw "Missing semicolon at the end of the line.";

		var tokens = line.split(" ");
		var keyword = tokens[0];

		if (!keywords.exists(keyword))
			throw "Unknown keyword: " + keyword;

		switch (keyword)
		{
			case "class":
				parseClass(line);
			case "var":
				parseVariable(line);
			case "struct":
				parseStruct(line);
			case "function":
				parseFunction(line);
			case "use":
				parseUse(line);
			default:
				throw "Unhandled keyword: " + keyword;
		}
	}

	// Function for casting a YClass extending a Haxe class.
	// public function castHaxeClass<T>(haxeClass:Dynamic):YClass<T> {
	//     var yClass:YClass<T> = { name: haxeClass.__name__, fields: [], methods: [], type: haxeClass };
	//     return yClass;
	// }

	private function createHaxeSuper<CLASS>(haxeClass:Class<CLASS>, superArgs:Array<Dynamic>):CLASS
	{
		var instance:CLASS = Type.createInstance(haxeClass, superArgs);
		return instance;
	}

	private function createHaxeExtendedYClassInstance<CLASS>(haxeClass:Class<CLASS>, name:String):YClassInstance<CLASS>
	{
		var yClass:YClassInstance<CLASS> = {
			name: name,
			fields: [],
			methods: [],
			type: haxeClass,
			extending: (haxeClass),
			implementing: [],
			constructors: [],
			destructors: [],
			CLASS: null, // Placeholder, should be set to the appropriate YClass<CLASS>
			access: {
				isPublic: true,
				isPrivate: false,
				isInternal: false
			}
		};
		yClass.haxeClassInstance = createHaxeSuper(haxeClass, []);
		// Fill with fields and methods from the Haxe class, as well as the YClass fields and methods.
		for (stuff in Type.getInstanceFields(haxeClass))
		{
			var field:YVar = {
				name: stuff,
				type: Type.getClassName(Type.getClass(Reflect.field(haxeClass, stuff))),
				value: Reflect.field(haxeClass, stuff),
				pointer: { haxePointer: cpp.RawPointer.addressOf(Reflect.field(haxeClass, stuff)), virtualPointer: null }
			};
			yClass.fields.push(field);
		}
		return yClass;
	}



    private function toHaxeType(type:String):Dynamic
    {
        // Convert YScript type to Haxe type
        switch (type.toLowerCase())
        {
            case "int":
                return Int;
            case "float":
                return Float;
            case "string":
                return String;
            case "bool":
                return Bool;
            case "void":
				return cpp.Void;
            case "void*":
				return null; // Pointer type, can be handled differently if needed
            case "null":
                return null;
            default:
                // Check the UseTable for a matching key
                var useEntry = useTable.get(type);
                if (useEntry != null && useEntry.type != null)
                {
                    return useEntry.type;
                }

                // Get class.
                var classType = Type.resolveClass(type);
                if (classType != null)
                {
                    return classType;
                }
                else
                {
                    // Handle types for YScript classes.
                    var yClass = classTable.get(type);
                    if (yClass != null)
                    {
                        return yClass;
                    }
                    return null; // Unknown type
                }
        }
    }

private function parseClass(line:String):Void
{
	// Implement class parsing logic
}

private function parseVariable(line:String):Void
{
	// Implement variable parsing logic
}

private function parseStruct(line:String):Void
{
	// Implement struct parsing logic
}

private function parseFunction(line:String):Void
{
	// Implement function parsing logic
}

private function parseUse(line:String):Void
{
	// Implement use parsing logic
}
}
