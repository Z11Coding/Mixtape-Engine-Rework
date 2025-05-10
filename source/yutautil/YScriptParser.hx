package yutautil;

import haxe.Json;
import hscript.Expr;
import hscript.Parser;
import yutautil.YScript;

    // Token types
     enum Token {
        TKeyword(name:String);    // class, enum, function, etc.
        TIdentifier(name:String); // variable/type names
        TLBrace; TRBrace;         // { }
        TLParen; TRParen;         // ( )
        TLBracket; TRBracket;     // [ ]
        TColon; TComma; TSemi;    // : , ;
        TOperator(op:String);     // = + - etc.
        TStringLiteral(s:String);
        TNumberLiteral(n:Float);
        TCodeBlock(lang:String, content:String); // haxe/lua blocks
        TEof;
    }

class YScriptParser {
    // -------------------------
    // TOKENIZATION (LEXER)
    // -------------------------
    


    // Lexer state
    private var input:String;
    private var pos:Int = 0;
    private var line:Int = 1;
    
    public function new() {}
    
    public function parse(source:String):YScriptProgram {
        this.input = source;
        var tokens = tokenize();
        return parseProgram(tokens);
    }

    private function tokenize():Array<Token> {
        var tokens = [];
        while (pos < input.length) {
            var c = input.charAt(pos);
            
            // Skip whitespace
            if (isWhitespace(c)) {
                pos++;
                continue;
            }
            
            // Handle code blocks first
            if (peekWord("haxe") || peekWord("lua")) {
                var lang = readWord();
                var blockContent = readCodeBlock();
                tokens.push(TCodeBlock(lang, blockContent));
                continue;
            }
            
            // Keywords and identifiers
            if (isAlpha(c)) {
                var word = readWord();
                tokens.push(isKeyword(word) ? TKeyword(word) : TIdentifier(word));
                continue;
            }
            
            // String literals
            if (c == '"' || c == "'") {
                tokens.push(TStringLiteral(readString(c)));
                continue;
            }
            
            // Numbers
            if (isDigit(c)) {
                tokens.push(TNumberLiteral(readNumber()));
                continue;
            }
            
            // Symbols
            switch (c) {
                case '{': tokens.push(TLBrace); pos++;
                case '}': tokens.push(TRBrace); pos++;
                case '(': tokens.push(TLParen); pos++;
                case ')': tokens.push(TRParen); pos++;
                case '[': tokens.push(TLBracket); pos++;
                case ']': tokens.push(TRBracket); pos++;
                case ':': tokens.push(TColon); pos++;
                case ',': tokens.push(TComma); pos++;
                case ';': tokens.push(TSemi); pos++;
                case '=', '+', '-', '*', '/', '%', '!', '&', '|', '<', '>':
                    tokens.push(TOperator(c)); pos++;
                default:
                    throw 'Unexpected character: $c at line $line';
            }
        }
        tokens.push(TEof);
        return tokens;
    }

    // -------------------------
    // PARSER
    // -------------------------
    
    private var currentToken:Token;
    private var tokenIndex:Int = -1;
    
    private function parseProgram(tokens:Array<Token>):YScriptProgram {
        var program:YScriptProgram = {
            classes: [],
            functions: [],
            variables: [],
            enums: [],
            imports: [],
            haxeBlocks: [],
            luaBlocks: []
        };
        
        tokenIndex = -1;
        advance(tokens);
        
        while (currentToken != TEof) {
            switch currentToken {
                case TKeyword("class"):
                    program.classes.push(parseClass(tokens));
                case TKeyword("enum"):
                    program.enums.push(parseEnum(tokens));
                case TKeyword("function"):
                    program.functions.push(parseFunction(tokens));
                case TKeyword("var") | TKeyword("const"):
                    program.variables.push(parseVariable(tokens));
                case TKeyword("use"):
                    program.imports.push(parseImport(tokens));
                case TCodeBlock("haxe", content):
                    program.haxeBlocks.push(content);
                    advance(tokens);
                case TCodeBlock("lua", content):
                    program.luaBlocks.push(content);
                    advance(tokens);
                default:
                    throw 'Unexpected token at top level: ${currentToken}';
            }
        }
        
        return program;
    }

    private function isWhitespace(c:String):Bool {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }

    private function isAlpha(c:String):Bool {
        var code = c.charCodeAt(0);
        return (code >= 65 && code <= 90) || // A-Z
               (code >= 97 && code <= 122);  // a-z
    }

    private function isDigit(c:String):Bool {
        var code = c.charCodeAt(0);
        return code >= 48 && code <= 57; // 0-9
    }

    private function peekWord(word:String):Bool {
        return input.substr(pos, word.length) == word;
    }

    private function readWord():String {
        var start = pos;
        while (pos < input.length && (isAlpha(input.charAt(pos)) || isDigit(input.charAt(pos)))) {
            pos++;
        }
        return input.substr(start, pos - start);
    }

    private function readString(quote:String):String {
        var start = pos;
        pos++; // Skip opening quote
        var escaped = false;
        var result = new StringBuf();
        
        while (pos < input.length) {
            var c = input.charAt(pos++);
            if (escaped) {
                result.add(c);
                escaped = false;
            } else if (c == '\\') {
                escaped = true;
            } else if (c == quote) {
                break;
            } else {
                result.add(c);
            }
        }
        return result.toString();
    }

    private function readNumber():Float {
        var start = pos;
        var hasDot = false;
        while (pos < input.length) {
            var c = input.charAt(pos);
            if (c == '.') {
                if (hasDot) break;
                hasDot = true;
                pos++;
            } else if (isDigit(c)) {
                pos++;
            } else {
                break;
            }
        }
        return Std.parseFloat(input.substr(start, pos - start));
    }

    private function isKeyword(word:String):Bool {
        return [
            "class", "enum", "struct", "interface", "function",
            "var", "const", "extends", "implements", "public",
            "private", "protected", "static", "override", "inline",
            "if", "else", "while", "for", "switch", "case", "default",
            "return", "break", "continue", "new", "super", "this",
            "true", "false", "null", "use", "as"
        ].contains(word);
    }

    private function parseExpression(t:Token):Dynamic {
        // Placeholder implementation for parsing an expression
        switch t {
            case TNumberLiteral(n): return n;
            case TStringLiteral(s): return s;
            case TIdentifier(name): return { type: "identifier", name: name };
            case TOperator(op): return { type: "operator", operator: op };
            default: throw 'Unsupported token in expression: $t';
        }
    }

    private function parseVariable(tokens:Array<Token>):YVar {
        var isConst = match(TKeyword("const"), tokens);
        expect(isConst ? TKeyword("const") : TKeyword("var"), tokens);
        
        var varName = expectIdentifier(tokens);
        expect(TColon, tokens);
        var type = parseTypeReference(tokens);
        
        var value = null;
        if (match(TOperator("="), tokens)) {
            advance(tokens);
            value = parseExpression(tokens);
        }
        expect(TSemi, tokens);
        
        return {
            name: varName,
            type: type,
            value: value,
            pointer: { haxePointer: null }
        };
    }

    private function parseEnum(tokens:Array<Token>):YEnum {
        expect(TKeyword("enum"), tokens);
        var enumName = expectIdentifier(tokens);
        expect(TLBrace, tokens);
        
        var values = [];
        while (!match(TRBrace, tokens)) {
            values.push(expectIdentifier(tokens));
            if (!match(TComma, tokens)) break;
            advance(tokens);
        }
        expect(TRBrace, tokens);
        
        return {
            name: enumName,
            values: values,
            access: parseAccessModifiers(tokens)
        };
    }

    private function parseFunction(tokens:Array<Token>):YFunction {
        expect(TKeyword("function"), tokens);
        var funcName = expectIdentifier(tokens);
        expect(TLParen, tokens);
        
        var params = [];
        while (!match(TRParen, tokens)) {
            params.push(parseParameter(tokens));
            if (!match(TComma, tokens)) break;
            advance(tokens);
        }
        expect(TRParen, tokens);
        
        var returnType = Dynamic;
        if (match(TColon, tokens)) {
            advance(tokens);
            returnType = parseTypeReference(tokens);
        }
        
        var body = parseBlock(tokens);
        
        return {
            name: funcName,
            returnType: returnType,
            parameters: params,
            body: body,
            parseBody: null, // To be implemented
            functionData: null,
            type: parseFunctionType(tokens),
            access: parseAccessModifiers(tokens),
            attachment: []
        };
    }

    private function parseParameter(tokens:Array<Token>):YVar {
        var paramName = expectIdentifier(tokens);
        expect(TColon, tokens);
        var paramType = parseTypeReference(tokens);
        
        return {
            name: paramName,
            type: paramType,
            value: null,
            pointer: { haxePointer: null }
        };
    }

    private function parseTypeReference(tokens:Array<Token>):Dynamic {
        var typeName = expectIdentifier(tokens);
        var typeParams = [];
        
        if (match(TLBracket, tokens)) {
            advance(tokens);
            while (!match(TRBracket, tokens)) {
                typeParams.push(parseTypeReference(tokens));
                if (!match(TComma, tokens)) break;
                advance(tokens);
            }
            expect(TRBracket, tokens);
        }
        
        return if (typeParams.length > 0) {
            { name: typeName, params: typeParams };
        } else {
            typeName;
        }
    }

    private function parseImport(tokens:Array<Token>):YUse {
        expect(TKeyword("use"), tokens);
        var path = expectIdentifier(tokens);
        var alias = null;
        
        if (match(TKeyword("as"), tokens)) {
            advance(tokens);
            alias = expectIdentifier(tokens);
        }
        expect(TSemi, tokens);
        
        return {
            name: path,
            alias: alias
        };
    }

    private function parseAccessModifiers(tokens:Array<Token>):{ 
        isPublic:Bool, isPrivate:Bool, isProtected:Bool, 
        isInternal:Bool, isDynamic:Bool 
    } {
        var access = {
            isPublic: false,
            isPrivate: false,
            isProtected: false,
            isInternal: false,
            isDynamic: false
        };
        
        while (true) {
            switch currentToken {
                case TKeyword("public"): access.isPublic = true;
                case TKeyword("private"): access.isPrivate = true;
                case TKeyword("protected"): access.isProtected = true;
                case TKeyword("internal"): access.isInternal = true;
                case TKeyword("dynamic"): access.isDynamic = true;
                default: break;
            }
            if (!match(TKeyword("public"), tokens) &&
                !match(TKeyword("private"), tokens) &&
                !match(TKeyword("protected"), tokens) &&
                !match(TKeyword("internal"), tokens) &&
                !match(TKeyword("dynamic"), tokens)) break;
            advance(tokens);
        }
        return access;
    }

    private function parseBlock(tokens:Array<Token>):String {
        expect(TLBrace, tokens);
        var depth = 1;
        var start = tokenIndex;
        
        while (depth > 0 && !match(TEof, tokens)) {
            if (match(TLBrace, tokens)) depth++;
            if (match(TRBrace, tokens)) depth--;
            advance(tokens);
        }
        
        var end = tokenIndex - 1;
        return tokens.slice(start, end)
            .map(token -> tokenToString(token))
            .join(" ");
    }

    private function tokenToString(token:Token):String {
        switch token {
            case TKeyword(name): return name;
            case TIdentifier(name): return name;
            case TLBrace: return "{";
            case TRBrace: return "}";
            case TLParen: return "(";
            case TRParen: return ")";
            case TLBracket: return "[";
            case TRBracket: return "]";
            case TColon: return ":";
            case TComma: return ",";
            case TSemi: return ";";
            case TOperator(op): return op;
            case TStringLiteral(s): return '"' + s + '"';
            case TNumberLiteral(n): return Std.string(n);
            default: throw 'Unknown token type';
        }
    }

    private function expectIdentifier(tokens:Array<Token>):String {
        return switch currentToken {
            case TIdentifier(name): advance(tokens); name;
            default: throw 'Expected identifier, got $currentToken';
        }
    }

    private function isHaxeType(typeName:String):Bool {
        // Simple check - could be enhanced with actual Haxe type resolution
        return typeName.charAt(0).toUpperCase() == typeName.charAt(0) &&
            !["YClass", "YEnum", "YVar"].contains(typeName);
    }

    private function parseFunctionType(tokens:Array<Token>):Dynamic {
        // Placeholder for function type parsing
        return null;
    }

    private function getCurrentToken():Token {
        return currentToken;
    }

    private function parseClass(tokens:Array<Token>):YClass<Dynamic> {
        expect(TKeyword("class"), tokens);
        var className = expectIdentifier(tokens);
        var cls:YBaseClass = {
            name: className,
            fields: [],
            methods: [],
            access: parseAccessModifiers(tokens),
            extending: [],
            implementing: [],
            constructors: [],
            destructors: []
        };
        
        // Handle inheritance
        while (match(TKeyword("extends"), tokens) || match(TKeyword("implements"), tokens)) {
            var keyword = getCurrentToken();
            advance(tokens);
            var typeName = parseTypeReference(tokens);
            
            switch keyword {
                case TKeyword("extends"):
                    if (isHaxeType(typeName)) {
                        // Special handling for Haxe superclasses
                        cls.extending.push({
                            name: typeName,
                            haxeClassInstance: Type.resolveClass(typeName)
                        });
                    } else {
                        cls.extending.push({name: typeName});
                    }
                case TKeyword("implements"):
                    cls.implementing.push({name: typeName});
                default:
            }
        }
        
        expect(TLBrace, tokens);
        
        while (!match(TRBrace, tokens)) {
            switch currentToken {
                case TKeyword("var"):
                    cls.fields.push(parseVariable(tokens));
                case TKeyword("function"):
                    var func = parseFunction(tokens);
                    if (func.name == "new") cls.constructors.push(func);
                    else if (func.name == "destroy") cls.destructors.push(func);
                    else cls.methods.push(func);
                default:
                    throw 'Unexpected token in class body: $currentToken';
            }
        }
        
        expect(TRBrace, tokens);
        return cls;
    }

    // -------------------------
    // HAXE INTEGRATION
    // -------------------------
    
    private function compileToHaxe(program:YScriptProgram):String {
        var output = [];
        
        for (cls in program.classes) {
            var cls:Dynamic = cls;
            output.push('// YScript class: ${cls.name}');
            if (cls.extending.length > 0) {
                var ext = cls.extending.map(e -> e.name).join(", ");
                output.push('class ${cls.name} extends $ext {');
            } else {
                output.push('class ${cls.name} {');
            }
            
            // Fields
            for (field in cls.fields) {
                output.push('    var ${field.name}:${field.type};');
            }
            
            // Methods
            for (method in cls.methods) {
                output.push('    function ${method.name}(${method.parameters.map(p -> '${p.name}:${p.type}').join(", ")})'
                    + ':${method.returnType} {');
                output.push('        ${method.body}');
                output.push('    }');
            }
            
            output.push('}\n');
        }
        
        // Add raw Haxe blocks
        for (block in program.haxeBlocks) {
            output.push('// Embedded Haxe code');
            output.push(block);
        }
        
        return output.join("\n");
    }

    // -------------------------
    // HELPER FUNCTIONS
    // -------------------------
    
    private inline function advance(tokens:Array<Token>) {
        tokenIndex++;
        currentToken = tokens[tokenIndex];
    }
    
    private function expect(expected:Token, tokens:Array<Token>) {
        if (!match(expected, tokens)) {
            throw 'Expected $expected but got $currentToken';
        }
        advance(tokens);
    }
    
    private function match(expected:Token, tokens:Array<Token>):Bool {
        return Type.enumEq(currentToken, expected);
    }
    
    private function readCodeBlock():String {
        var depth = 1;
        var start = pos;
        pos += 4; // Skip "haxe" or "lua"
        while (pos < input.length && depth > 0) {
            var c = input.charAt(pos++);
            if (c == '{') depth++;
            else if (c == '}') depth--;
        }
        return input.substring(start, pos - 1);
    }
    
    // (Include other helper functions from previous example)
}

// -------------------------
// PROGRAM STRUCTURE
// -------------------------
    
typedef YScriptProgram = {
    classes:Array<YClass<Dynamic>>,
    functions:Array<YFunction>,
    variables:Array<YVar>,
    enums:Array<YEnum>,
    imports:Array<YUse>,
    haxeBlocks:Array<String>,
    luaBlocks:Array<String>
};