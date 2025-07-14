package yutautil;

import hscript.Parser;
import cpp.Star;
import haxe.Constraints.Function;
import haxe.ds.StringMap;

abstract YVar(YVarData) from YVarData to YVarData
{
	public var name(get, never):String;
	public var type(get, never):Dynamic;
	public var value(get, set):Dynamic;
	public var haxePointer(get, never):cpp.RawPointer<Dynamic>;

	public function new(name:String, type:Dynamic, ?value:Dynamic)
	{
		this = {
			name: name,
			type: type,
			value: value,
			pointer: {haxePointer: value != null ? cpp.RawPointer.addressOf(value) : null, virtualPointer: null}
		};
	}

	inline function get_name():String
		return this.name;

	inline function get_type():Dynamic
		return this.type;

	inline function get_value():Dynamic
		return this.value;

	inline function set_value(v:Dynamic):Dynamic
		return this.value = v;

	inline function get_haxePointer():cpp.RawPointer<Dynamic>
		return this.pointer.haxePointer;

	@:op(A == B) public function equals(other:YVar):Bool
	{
		return this.name == other.name && this.type == other.type;
	}

	@:to public function toString():String
	{
		return 'YVar(${this.name}:${this.type} = ${this.value})';
	}
}

typedef YVarData =
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
	values:Array<YEnumValue>,
	access:
	{
		isPublic:Bool, isPrivate:Bool, isInternal:Bool,
	},
};

typedef YEnumValue =
{
	name:String,
	?args:Array<Dynamic>, // Arguments for enum constructors, if any
	?value:Int, // Optional integer value (for simple enums)
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

abstract YFunction(YFunctionData) from YFunctionData to YFunctionData
{
	public var name(get, never):String;
	public var returnType(get, never):Dynamic;
	public var parameters(get, never):Array<YVar>;
	public var body(get, set):String;
	public var isHaxe(get, never):Bool;
	public var isLua(get, never):Bool;
	public var isPublic(get, never):Bool;

	public function new(name:String, returnType:Dynamic, parameters:Array<YVar>, body:String)
	{
		this = {
			name: name,
			returnType: returnType,
			parameters: parameters,
			body: body,
			parseBody: null,
			functionData: null,
			type: {
				isLambda: false,
				isClosure: false,
				isMethod: false,
				isStatic: false,
				isConstructor: false,
				isDestructor: false,
				isVirtual: false,
				isAbstract: false,
				isOverride: false,
				isFinal: false,
				isNative: false,
				isLua: false,
				isHaxe: false,
				isC: false,
				isCPlusPlus: false,
				isForLoop: false,
				isWhileLoop: false
			},
			access: {
				isPublic: true,
				isPrivate: false,
				isProtected: false,
				isInternal: false,
				isDynamic: false
			},
			attachment: []
		};
	}

	inline function get_name():String
		return this.name;

	inline function get_returnType():Dynamic
		return this.returnType;

	inline function get_parameters():Array<YVar>
		return this.parameters;

	inline function get_body():String
		return this.body;

	inline function set_body(v:String):String
		return this.body = v;

	inline function get_isHaxe():Bool
		return this.type.isHaxe;

	inline function get_isLua():Bool
		return this.type.isLua;

	inline function get_isPublic():Bool
		return this.access.isPublic;

	public function call(args:Array<Dynamic>):Dynamic
	{
		// Implementation for calling the function
		return null;
	}

	@:to public function toString():String
	{
		return 'YFunction(${this.name}(${this.parameters.map(p -> p.toString()).join(", ")}):${this.returnType})';
	}
}

typedef YFunctionData =
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

// Enhanced AST node types
enum YASTNode
{
	// Program structure
	Program(statements:Array<YASTNode>);

	// Declarations
	ClassDecl(name:String, superClass:Null<String>, interfaces:Array<String>, body:Array<YASTNode>);
	FunctionDecl(name:String, params:Array<YVar>, returnType:Dynamic, body:YASTNode);
	VariableDecl(name:String, type:Dynamic, init:Null<YASTNode>);
	EnumDecl(name:String, values:Array<String>);

	// Statements
	Block(statements:Array<YASTNode>);
	If(condition:YASTNode, thenStmt:YASTNode, elseStmt:Null<YASTNode>);
	While(condition:YASTNode, body:YASTNode);
	For(init:Null<YASTNode>, condition:Null<YASTNode>, increment:Null<YASTNode>, body:YASTNode);
	Return(value:Null<YASTNode>);
	Break;
	Continue;
	Expression(expr:YASTNode);

	// Expressions
	Identifier(name:String);
	Literal(value:Dynamic);
	BinaryOp(left:YASTNode, op:String, right:YASTNode);
	UnaryOp(op:String, operand:YASTNode);
	FunctionCall(func:YASTNode, args:Array<YASTNode>);
	MemberAccess(object:YASTNode, member:String);
	ArrayAccess(array:YASTNode, index:YASTNode);
	Assignment(left:YASTNode, right:YASTNode);

	// Language blocks
	HaxeBlock(code:String);
	LuaBlock(code:String);
}

// AST visitor pattern
interface YASTVisitor<T>
{
	function visitProgram(statements:Array<YASTNode>):T;
	function visitClassDecl(name:String, superClass:Null<String>, interfaces:Array<String>, body:Array<YASTNode>):T;
	function visitFunctionDecl(name:String, params:Array<YVar>, returnType:Dynamic, body:YASTNode):T;
	function visitVariableDecl(name:String, type:Dynamic, init:Null<YASTNode>):T;
	function visitBlock(statements:Array<YASTNode>):T;
	function visitIf(condition:YASTNode, thenStmt:YASTNode, elseStmt:Null<YASTNode>):T;
	function visitWhile(condition:YASTNode, body:YASTNode):T;
	function visitFor(init:Null<YASTNode>, condition:Null<YASTNode>, increment:Null<YASTNode>, body:YASTNode):T;
	function visitReturn(value:Null<YASTNode>):T;
	function visitExpression(expr:YASTNode):T;
	function visitIdentifier(name:String):T;
	function visitLiteral(value:Dynamic):T;
	function visitBinaryOp(left:YASTNode, op:String, right:YASTNode):T;
	function visitUnaryOp(op:String, operand:YASTNode):T;
	function visitFunctionCall(func:YASTNode, args:Array<YASTNode>):T;
	function visitMemberAccess(object:YASTNode, member:String):T;
	function visitAssignment(left:YASTNode, right:YASTNode):T;
	function visitHaxeBlock(code:String):T;
	function visitLuaBlock(code:String):T;
}

typedef YSyntaxAST = YASTNode;

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
	private var runtime:YScriptRuntime;

	private var keywords:Map<String, EReg> = [
		// ———————— Type & Block Definitions ————————
		"class" => ~/\bclass\s+\w+(?:\s+extends\s+[\w\.]+)?(?:\s+implements\s+[\w\.]+(?:\s*,\s*[\w\.]+)*)?\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a class definition, optionally with 'extends' and/or 'implements' clauses, and its body.
		"enum" => ~/\benum\s+\w+\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches an enum definition with its body.
		"struct" => ~/\bstruct\s+\w+\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a struct definition with its body.
		"interface" => ~/\binterface\s+\w+\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches an interface definition with its body.
		"const" => ~/\bconst\s+\w+\s*:\s*[\w\.<>\[\]]+\s*=\s*[\s\S]*?;/s,
		// Matches a constant definition with a type and an initializer.
		"var" => ~/\bvar\s+\w+\s*:\s*[\w\.<>\[\]]+\s*=\s*[\s\S]*?;/s,
		// Matches a variable definition with a type and an initializer.
		"function" => ~/\bfunction\s+\w+\s*\([^)]*\)\s*:\s*[\w\.<>\[\]]+\s*(?:haxe|lua)?\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a function definition with parameters, return type, and body.
		"if" => ~/\bif\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches an 'if' statement with its condition and body.
		"else" => ~/\belse\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches an 'else' statement with its body.
		"switch" => ~/\bswitch\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a 'switch' statement with its condition and body.
		"case" => ~/\bcase\b[^:]*:\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a 'case' statement with its condition and body.
		"default" => ~/\bdefault:\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a 'default' statement with its body.
		"while" => ~/\bwhile\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a 'while' loop with its condition and body.
		"do" => ~/\bdo\s*\{(?:[^{}]|\{[^{}]*\})*\}\s*while\s*\([\s\S]*?\)\s*;/s,
		// Matches a 'do-while' loop with its body and condition.
		"for" => ~/\bfor\s*\([\s\S]*?\)\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a 'for' loop with its initializer, condition, and body.
		"return" => ~/\breturn\b[\s\S]*?;/s,
		// Matches a 'return' statement with an optional value.
		"break" => ~/\bbreak\b\s*;/s,
		// Matches a 'break' statement.
		"continue" => ~/\bcontinue\b\s*;/s,
		// Matches a 'continue' statement.
		"use" => ~/\buse\s+[\w\.]+(?:\s+as\s+\w+)?\s*;/s,
		// Matches a 'use' statement for importing modules or aliases.
		"haxe" => ~/\bhaxe\s*\{(?:[^{}]|\{[^{}]*\})*\}/s,
		// Matches a block of Haxe code embedded in the script.
		"lua" => ~/\blua\s*\{(?:[^{}]|\{[^{}]*\})*\}/s // Matches a block of Lua code embedded in the script.
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
		runtime = new YScriptRuntime();

		// Initialize tables for backward compatibility
		varTable = new Map();
		structTable = new Map();
		classTable = new Map();
		enumTable = new Map();
		functionTable = new Map();
		useTable = new Map();
		importTable = new Map();
		luaTable = new Map();
	}

	public function execute(source:String):Dynamic
	{
		return runtime.execute(source);
	}

	public function setVariable(name:String, value:Dynamic, ?type:Dynamic):Void
	{
		if (type == null)
			type = Dynamic;
		var variable = new YVar(name, type, value);
		runtime.globalScope.variables.set(name, variable);
		varTable.set(name, variable);
	}

	public function getVariable(name:String):Dynamic
	{
		if (runtime.globalScope.variables.exists(name))
		{
			return runtime.globalScope.variables.get(name).value;
		}
		return null;
	}

	public function defineFunction(name:String, func:YFunction):Void
	{
		runtime.globalScope.functions.set(name, func);
		functionTable.set(name, func);
	}

	public function callFunction(name:String, args:Array<Dynamic>):Dynamic
	{
		if (runtime.globalScope.functions.exists(name))
		{
			var func = runtime.globalScope.functions.get(name);
			return runtime.callFunction(func, args, runtime.globalScope);
		}
		throw new YScriptRuntimeError('Function not found: $name');
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
				type: Type.getClassName(Type.getClass(Reflect.getProperty(haxeClass, stuff))),
				value: Reflect.getProperty(haxeClass, stuff),
				pointer: {
					haxePointer: cpp.RawPointer.addressOf(Reflect.getProperty(haxeClass, stuff)),
					virtualPointer: null
				}
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

typedef YScriptScopeData =
{
	variables:Map<String, YVar>,
	functions:Map<String, YFunction>,
	classes:Map<String, YClass<Dynamic>>,
	enums:Map<String, YEnum>,
	imports:Map<String, YUse>,
	parent:Null<YScriptScope>
};

abstract YScriptScope(YScriptScopeData) from YScriptScopeData to YScriptScopeData
{
	public var variables(get, never):Map<String, YVar>;
	public var functions(get, never):Map<String, YFunction>;
	public var classes(get, never):Map<String, YClass<Dynamic>>;
	public var enums(get, never):Map<String, YEnum>;
	public var imports(get, never):Map<String, YUse>;
	public var parent(get, never):Null<YScriptScope>;
	public function new()
	{
		this = {
			variables: new Map(),
			functions: new Map(),
			classes: new Map(),
			enums: new Map(),
			imports: new Map(),
			parent: null
		};
	}
	inline function get_variables():Map<String, YVar>
		return this.variables;
	inline function get_functions():Map<String, YFunction>
		return this.functions;
	inline function get_classes():Map<String, YClass<Dynamic>>
		return this.classes;
	inline function get_enums():Map<String, YEnum>
		return this.enums;
	inline function get_imports():Map<String, YUse>
		return this.imports;
	inline function get_parent():Null<YScriptScope>
		return this.parent;
	inline function set_parent(scope:Null<YScriptScope>):Null<YScriptScope>
	{
		this.parent = scope;
		return this.parent;
	}
	inline function createChildScope():YScriptScope
	{
		var childScope = new YScriptScope();
		childScope.parent = this;
		return childScope;
	}
	inline function getVariable(name:String):Null<YVar>
	{
		if (this.variables.exists(name))
			return this.variables.get(name);
		else if (this.parent != null)
			return this.parent.getVariable(name);
		else
			return null;
	}
	inline function setVariable(name:String, variable:YVar):Void
	{
		this.variables.set(name, variable);
	}
	inline function getFunction(name:String):Null<YFunction>
	{
		if (this.functions.exists(name))
			return this.functions.get(name);
		else if (this.parent != null)
			return this.parent.getFunction(name);
		else
			return null;
	}
	inline function setFunction(name:String, func:YFunction):Void
	{
		this.functions.set(name, func);
	}
	inline function getClass(name:String):Null<YClass<Dynamic>>
	{
		if (this.classes.exists(name))
			return this.classes.get(name);
		else if (this.parent != null)
			return this.parent.getClass(name);
		else
			return null;
	}
	inline function setClass(name:String, yClass:YClass<Dynamic>):Void
	{
		this.classes.set(name, yClass);
	}
	inline function getEnum(name:String):Null<YEnum>
	{
		if (this.enums.exists(name))
			return this.enums.get(name);
		else if (this.parent != null)
			return this.parent.getEnum(name);
		else
			return null;
	}
	inline function setEnum(name:String, yEnum:YEnum):Void
	{
		this.enums.set(name, yEnum);
	}
	inline function getImport(name:String):Null<YUse>
	{
		if (this.imports.exists(name))
			return this.imports.get(name);
		else if (this.parent != null)
			return this.parent.getImport(name);
		else
			return null;
	}
	inline function setImport(name:String, use:YUse):Void
	{
		this.imports.set(name, use);
	}
	inline function getUse(name:String):Null<YUse>
	{
		if (this.imports.exists(name))
			return this.imports.get(name);
		else if (this.parent != null)
			return this.parent.getUse(name);
		else
			return null;
	}
	inline function setUse(name:String, use:YUse):Void
	{
		this.imports.set(name, use);
	}
	inline function getImportAlias(alias:String):Null<YUse>
	{
		for (use in this.imports)
		{
			if (use.value.alias == alias)
				return use.value;
		}
		if (this.parent != null)
			return this.parent.getImportAlias(alias);
		else
			return null;
	}
	inline function setImportAlias(alias:String, use:YUse):Void
	{
		for (useEntry in this.imports)
		{
			if (useEntry.value.alias == alias)
			{
				useEntry.value = use;
				return;
			}
		}
		this.imports.set(alias, use);
	}
	inline function getImportByName(name:String):Null<YUse>
	{
		for (use in this.imports)
		{
			if (use.value.name == name)
				return use.value;
		}
		if (this.parent != null)
			return this.parent.getImportByName(name);
		else
			return null;
	}
	inline function setImportByName(name:String, use:YUse):Void
	{
		for (useEntry in this.imports)
		{
			if (useEntry.value.name == name)
			{
				useEntry.value = use;
				return;
			}
		}
		this.imports.set(name, use);
	}
	inline function getImportByAlias(alias:String):Null<YUse>
	{
		for (use in this.imports)
		{
			if (use.value.alias == alias)
				return use.value;
		}
		if (this.parent != null)
			return this.parent.getImportByAlias(alias);
		else
			return null;
	}
	inline function setImportByAlias(alias:String, use:YUse):Void
	{
		for (useEntry in this.imports)
		{
			if (useEntry.value.alias == alias)
			{
				useEntry.value = use;
				return;
			}
		}
		this.imports.set(alias, use);
	}

	public inline function getAllInScope(name:String):Array<YVar>
	{
		var result:Array<YVar> = [];
		var scope:Null<YScriptScope> = this;
		while (scope != null)
		{
			if (scope.variables.exists(name))
				result.push(scope.variables.get(name));
			scope = scope.parent;
		}
		return result;
	}
}

// YScript Runtime and Interpreter
class YScriptRuntime
{
	public var globalScope:YScriptScope;
	public var currentScope:YScriptScope;
	public var parser:YScriptParser;

	public function new()
	{
		globalScope = {
			variables: new Map(),
			functions: new Map(),
			classes: new Map(),
			enums: new Map(),
			imports: new Map(),
			parent: null
		};
		currentScope = globalScope;
		parser = new YScriptParser();
	}

	public function execute(source:String):Dynamic
	{
		var program = parser.parse(source);
		return evaluateAST(program.ast, program.scope);
	}

	public function evaluateAST(node:YASTNode, scope:YScriptScope):Dynamic
	{
		return switch node
		{
			case YASTNode.Program(statements):
				var result:Dynamic = null;
				for (stmt in statements)
				{
					result = evaluateAST(stmt, scope);
				}
				result;

			case YASTNode.Block(statements):
				var blockScope = createChildScope(scope);
				var result:Dynamic = null;
				for (stmt in statements)
				{
					result = evaluateAST(stmt, blockScope);
				}
				result;

			case YASTNode.VariableDecl(name, type, init):
				var value = init != null ? evaluateAST(init, scope) : null;
				var variable = new YVar(name, type, value);
				scope.variables.set(name, variable);
				value;

			case YASTNode.FunctionDecl(name, params, returnType, body):
				var func = new YFunction(name, returnType, params, "");
				// Store the parsed body for later execution
				func.body = body;
				scope.functions.set(name, func);
				func;

			case YASTNode.ClassDecl(name, superClass, interfaces, body):
				var cls:YBaseClass = {
					name: name,
					fields: [],
					methods: [],
					access: {isPublic: true, isPrivate: false, isInternal: false},
					extending: [],
					implementing: [],
					constructors: [],
					destructors: []
				};

				// Create class scope
				var classScope = createChildScope(scope);

				// Process class body
				for (stmt in body)
				{
					switch stmt
					{
						case YASTNode.VariableDecl(fieldName, fieldType, fieldInit):
							var field = new YVar(fieldName, fieldType, fieldInit != null ? evaluateAST(fieldInit, classScope) : null);
							cls.fields.push(field);
						case YASTNode.FunctionDecl(methodName, methodParams, methodReturnType, methodBody):
							var method = new YFunction(methodName, methodReturnType, methodParams, "");
							method.body = methodBody;
							if (methodName == "new")
							{
								cls.constructors.push(method);
							}
							else if (methodName == "destroy")
							{
								cls.destructors.push(method);
							}
							else
							{
								cls.methods.push(method);
							}
						default:
					}
				}

				scope.classes.set(name, cls);
				cls;

			case YASTNode.If(condition, thenStmt, elseStmt):
				var conditionValue = evaluateAST(condition, scope);
				if (isTruthy(conditionValue))
				{
					evaluateAST(thenStmt, scope);
				}
				else if (elseStmt != null)
				{
					evaluateAST(elseStmt, scope);
				}
				else
				{
					null;
				}

			case YASTNode.While(condition, body):
				var result:Dynamic = null;
				while (isTruthy(evaluateAST(condition, scope)))
				{
					result = evaluateAST(body, scope);
				}
				result;

			case YASTNode.For(init, condition, increment, body):
				var forScope = createChildScope(scope);
				if (init != null)
					evaluateAST(init, forScope);

				var result:Dynamic = null;
				while (condition == null || isTruthy(evaluateAST(condition, forScope)))
				{
					result = evaluateAST(body, forScope);
					if (increment != null)
						evaluateAST(increment, forScope);
				}
				result;

			case YASTNode.Return(value):
				throw new YScriptReturnException(value != null ? evaluateAST(value, scope) : null);

			case YASTNode.Break:
				throw new YScriptBreakException();

			case YASTNode.Continue:
				throw new YScriptContinueException();

			case YASTNode.Expression(expr):
				evaluateAST(expr, scope);

			case YASTNode.Identifier(name):
				getVariable(name, scope);

			case YASTNode.Literal(value):
				value;

			case YASTNode.BinaryOp(left, op, right):
				var leftValue = evaluateAST(left, scope);
				var rightValue = evaluateAST(right, scope);
				evaluateBinaryOp(leftValue, op, rightValue);

			case YASTNode.UnaryOp(op, operand):
				var operandValue = evaluateAST(operand, scope);
				evaluateUnaryOp(op, operandValue);

			case YASTNode.Assignment(left, right):
				var rightValue = evaluateAST(right, scope);
				switch left
				{
					case YASTNode.Identifier(name):
						setVariable(name, rightValue, scope);
					case YASTNode.MemberAccess(object, member):
						// Handle member assignment
						var objValue = evaluateAST(object, scope);
						Reflect.setField(objValue, member, rightValue);
					default:
						throw new YScriptRuntimeError("Invalid assignment target");
				}
				rightValue;

			case YASTNode.FunctionCall(func, args):
				var funcValue = evaluateAST(func, scope);
				var argValues = [for (arg in args) evaluateAST(arg, scope)];
				callFunction(funcValue, argValues, scope);

			case YASTNode.MemberAccess(object, member):
				var objValue = evaluateAST(object, scope);
				Reflect.field(objValue, member);

			case YASTNode.ArrayAccess(array, index):
				var arrayValue = evaluateAST(array, scope);
				var indexValue = evaluateAST(index, scope);
				Reflect.field(arrayValue, Std.string(indexValue));

			case YASTNode.HaxeBlock(code):
				executeHaxeCode(code, scope);

			case YASTNode.LuaBlock(code):
				executeLuaCode(code, scope);

			case YASTNode.EnumDecl(name, values):
				var enumData:YEnum = {
					name: name,
					values: values,
					access: {isPublic: true, isPrivate: false, isInternal: false}
				};
				scope.enums.set(name, enumData);
				enumData;
		};
	}

	private function createChildScope(parent:YScriptScope):YScriptScope
	{
		return {
			variables: new Map(),
			functions: new Map(),
			classes: new Map(),
			enums: new Map(),
			imports: new Map(),
			parent: parent
		};
	}

	private function getVariable(name:String, scope:YScriptScope):Dynamic
	{
		if (scope.variables.exists(name))
		{
			return scope.variables.get(name).value;
		}
		else if (scope.parent != null)
		{
			return getVariable(name, scope.parent);
		}
		else
		{
			throw new YScriptRuntimeError('Undefined variable: $name');
		}
	}

	private function setVariable(name:String, value:Dynamic, scope:YScriptScope):Void
	{
		if (scope.variables.exists(name))
		{
			scope.variables.get(name).value = value;
		}
		else if (scope.parent != null)
		{
			setVariable(name, value, scope.parent);
		}
		else
		{
			throw new YScriptRuntimeError('Undefined variable: $name');
		}
	}

	private function isTruthy(value:Dynamic):Bool
	{
		if (value == null)
			return false;
		if (Std.is(value, Bool))
			return value;
		if (Std.is(value, Int))
			return value != 0;
		if (Std.is(value, Float))
			return value != 0.0;
		if (Std.is(value, String))
			return value != "";
		return true;
	}

	private function evaluateBinaryOp(left:Dynamic, op:String, right:Dynamic):Dynamic
	{
		return switch op
		{
			case "+": left + right;
			case "-": left - right;
			case "*": left * right;
			case "/": left / right;
			case "%": left % right;
			case "==": left == right;
			case "!=": left != right;
			case "<": left < right;
			case "<=": left <= right;
			case ">": left > right;
			case ">=": left >= right;
			case "&&": isTruthy(left) && isTruthy(right);
			case "||": isTruthy(left) || isTruthy(right);
			default: throw new YScriptRuntimeError('Unknown binary operator: $op');
		};
	}

	private function evaluateUnaryOp(op:String, operand:Dynamic):Dynamic
	{
		return switch op
		{
			case "!": !isTruthy(operand);
			case "-": -operand;
			case "+": + operand;
			default: throw new YScriptRuntimeError('Unknown unary operator: $op');
		};
	}

	private function callFunction(func:Dynamic, args:Array<Dynamic>, scope:YScriptScope):Dynamic
	{
		if (Std.is(func, YFunction))
		{
			var yfunc:YFunction = func;
			var funcScope = createChildScope(scope);

			// Bind parameters
			for (i in 0...yfunc.parameters.length)
			{
				if (i < args.length)
				{
					var param = yfunc.parameters[i];
					funcScope.variables.set(param.name, new YVar(param.name, param.type, args[i]));
				}
			}

			try
			{
				return evaluateAST(yfunc.body, funcScope);
			}
			catch (e:YScriptReturnException)
			{
				return e.value;
			}
		}
		else if (Reflect.isFunction(func))
		{
			return Reflect.callMethod(null, func, args);
		}
		else
		{
			throw new YScriptRuntimeError('Cannot call non-function value');
		}
	}

	private function executeHaxeCode(code:String, scope:YScriptScope):Dynamic
	{
		var hscript:Dynamic = Parser.parseString(code);
		if (hscript == null)
		{
			throw new YScriptRuntimeError('Failed to parse Haxe code');
		}
		var interpreter:Dynamic = new hscript.Interp();
		for (var varName
		in scope.variables.keys()
	)
		{
			interpreter.variables.set(varName, scope.variables.get(varName).value);
		}
		return try
		{
			interpreter.execute(hscript);
		}
		catch (e:Dynamic)
		{
			throw new YScriptRuntimeError('Haxe execution error: ' + e.message);
		}
	}

	private function executeLuaCode(code:String, scope:YScriptScope):Dynamic
	{
		throw new YScriptRuntimeError('Lua execution not implemented yet');
		// This is a placeholder for Lua execution logic.
		return null;
	}
}

// Control flow exceptions
class YScriptReturnException extends haxe.Exception
{
	public var value:Dynamic;

	public function new(value:Dynamic)
	{
		super("Return");
		this.value = value;
	}
}

class YScriptBreakException extends haxe.Exception
{
	public function new()
	{
		super("Break");
	}
}

class YScriptContinueException extends haxe.Exception
{
	public function new()
	{
		super("Continue");
	}
}
