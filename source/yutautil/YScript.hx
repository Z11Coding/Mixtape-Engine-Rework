package yutautil;

import haxe.ds.StringMap;

typedef YVar = {
    name: String,
    type: Dynamic,
    ?value: Dynamic,
    pointer:{haxePointer:cpp.RawPointer<Dynamic>, ?virtualPointer:Int}
};
typedef YStruct = {
    name: String,
    fields: Array<YVar>
};

typedef YEnum = {
    name: String,
    values: Array<String>,
    access:{
        isPublic:Bool,
        isPrivate:Bool,
        isInternal:Bool,
    },
};
typedef YEnumValue = {
    name: String,
    value: Int,
    access:{
        isPublic:Bool,
        isPrivate:Bool,
        isInternal:Bool,
    },
};
typedef YInterface = {
    name: String,
    fields: Array<YVar>,
    methods: Array<YFunction>,
    access:{
        isPublic:Bool,
        isPrivate:Bool,
        isInternal:Bool,
    },
};
typedef YBaseClass = {
    name: String,
    fields: Array<YVar>,
    methods: Array<YFunction>,
    access:{
        isPublic:Bool,
        isPrivate:Bool,
        isInternal:Bool,
    },
    extending: Array<YClass>,
    implementing: Array<YInterface>,
    constructors: Array<YFunction>,
    destructors: Array<YFunction>,
};

typedef YTypedClass<T> = {
    name: String,
    fields: Array<YVar>,
    methods: Array<YFunction>,
    type:Dynamic,
    access:{
        isPublic:Bool,
        isPrivate:Bool,
        isInternal:Bool,
    },
    extending: Array<YClass>,
    implementing: Array<YInterface>,
    constructors: Array<YFunction>,
    destructors: Array<YFunction>,
};

typedef YClass<T> = flixel.util.typeLimit.OneOfTwo<YBaseClass, YTypedClass<T>>;

typedef YFunction = {
    name: String,
    returnType:Dynamic,
    parameters: Array<YVar>,
    body: String,
    type:{ // Private and Protected are reversed from how Java does it, as it makes sense when interfacing with Haxe.
        isLambda:Bool,
        isClosure:Bool,
        isMethod:Bool,
        isStatic:Bool,
        isConstructor:Bool,
        isDestructor:Bool,
        isVirtual:Bool,
        isAbstract:Bool,
        isOverride:Bool,
        isFinal:Bool,
        isNative:Bool,
        isLua:Bool,
        isHaxe:Bool,
        isC:Bool,
        isCPlusPlus:Bool,
        isForLoop:Bool,
        isWhileLoop:Bool,
    },
    access:{
        isPublic:Bool,
        isPrivate:Bool,
        isProtected:Bool,
        isInternal:Bool,
        isDynamic:Bool
    },
    attachment:Array<Dynamic> // Attachment shows what this function is a part of, class, variable, struct, etc.
};
typedef YUse = {
    name: String,
    ?alias: String
};

typedef YFor = {
    body: YFunction,
    condition: YVar,
    iterator: Dynamic,
}
typedef YWhile = {
    body: YFunction,
    condition: YVar,
}
typedef YIf = {
    body: YFunction,
    condition: YVar,
    elseBody: YFunction
};
typedef YSwitch = {
    body: YFunction,
    condition: YVar,
    cases: Array<YCase>
};
typedef YCase = {
    condition: YVar,
    body: YFunction
};
typedef YReturn = {
    value: Dynamic
};
typedef YBreak = {
    value: Dynamic
};

typedef YContinue = {
    value: Dynamic
};
typedef YImport = {
    name: String,
    alias: String
};
typedef YClosure = {
    name: String,
    parameters: Array<YVar>,
    body: YFunction
};
typedef YLambda = {
    name: String,
    parameters: Array<YVar>,
    body: YFunction
};
typedef YLambdaExpr = {
    name: String,
    param: String,
    body: YFunction
};
typedef YLambdaCall = {
    func: YLambdaExpr,
    arg: YLambdaExpr
};
typedef YLambdaReduce = {
    func: YLambdaExpr,
    arg: YLambdaExpr
};
typedef YLambdaToString = {
    name: String,
    param: String,
    body: YFunction
};
typedef YLambdaTokenize = {
    name: String,
    param: String,
    body: YFunction
};
typedef YLuaTable = {
    name: String,
    fields: Array<YVar>
};
typedef YLuaImport = { // Treated like a class, uses a Lua script as a class
    name: String,
    alias: String,
    script: llua.State
};

typedef YHaskellExpr = {
    name: String,
    param: String,
    body: YFunction
};
typedef YHaskellCall = {
    func: YHaskellExpr,
    arg: YHaskellExpr
};


class YScriptError extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

class YscriptException extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

class YScriptParseError extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

class YScriptRuntimeError extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

class YScriptTypeError extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

class YScriptSyntaxError extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

class YScriptSemanticError extends haxe.Exception {
    public function new(message:String) {
        super(message, null, null);
    }
}

typedef YSyntaxAST = Array<Dynamic>;

class YScriptSyntaxTree {

    var tree:YSyntaxAST;
    var currentNode:Dynamic;
    var currentIndex:Int;
    var currentLine:Int;
    var currentColumn:Int;


    public function new() {
        tree = [];
        currentNode = null;
        currentIndex = 0;
        currentLine = 0;
        currentColumn = 0;
    }

    public function addNode(node:Dynamic):Void {
        tree.push(node);
        currentNode = node;
        currentIndex++;
    }
    public function getNode(index:Int):Dynamic {
        if (index < 0 || index >= tree.length) throw "Index out of bounds: " + index;
        return tree[index];
    }
    public function getCurrentNode():Dynamic {
        return currentNode;
    }
    public function getCurrentIndex():Int {
        return currentIndex;
    }

    // More builders.
    public function buildFunction(name:String, parameters:Array<YVar>, body:YSyntaxAST):YSyntaxAST {
        var funcNode = { type: "function", name: name, parameters: parameters, body: body };
        addNode(funcNode);
        return [funcNode];
    }
    
    

}

// A Scripting Language which has a lot of control over the game, and is used to create mods for the game. 
// It also has native control over types, and can be used to create new types, and modify existing ones.

// It is planned to also have compatibility with Lua, and Haxe, and be able to run Lua scripts, and Haxe scripts, as well as be able to run C++ code and C code directly in the future.
class YScript {
    private var keywords:Map<String, String>;

    public var varTable:Map<String, YVar>;
    public var structTable:Map<String, YStruct>;
    public var classTable:Map<String, YClass>;

    public function new() {
        keywords = new StringMap<String>();
        keywords.set("class", "class");
        keywords.set("var", "var");
        keywords.set("struct", "struct");
        keywords.set("function", "function");
        keywords.set("use", "use");
        keywords.set("if", "if");
        keywords.set("while", "while");
        keywords.set("for", "for");
    }

    public function parse(script:String):Void {
        var lines = script.split("\n");
        for (line in lines) {
            line = line.trim();
            if (line == "" || line.startsWith("//")) continue; // Skip empty lines and comments

            try {
                parseLine(line);
            } catch (e:Dynamic) {
                trace("Error parsing line: " + line + "\n" + e);
            }
        }
    }

    private function parseLine(line:String):Void {
        if (line.indexOf(";") == -1) throw "Missing semicolon at the end of the line.";

        var tokens = line.split(" ");
        var keyword = tokens[0];

        if (!keywords.exists(keyword)) throw "Unknown keyword: " + keyword;

        switch (keyword) {
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

    private function parseClass(line:String):Void {
        // Implement class parsing logic
    }

    private function parseVariable(line:String):Void {
        // Implement variable parsing logic
    }

    private function parseStruct(line:String):Void {
        // Implement struct parsing logic
    }

    private function parseFunction(line:String):Void {
        // Implement function parsing logic
    }

    private function parseUse(line:String):Void {
        // Implement use parsing logic
    }
}

