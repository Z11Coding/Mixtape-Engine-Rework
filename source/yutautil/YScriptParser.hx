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
        var statements = [];
        var scope:YScriptScope = {
            variables: new Map(),
            functions: new Map(),
            classes: new Map(),
            enums: new Map(),
            imports: new Map(),
            parent: null
        };
        
        tokenIndex = -1;
        advance(tokens);
        
        while (currentToken != TEof) {
            var stmt = parseStatement(tokens, scope);
            if (stmt != null) {
                statements.push(stmt);
            }
        }
        
        return {
            ast: YASTNode.Program(statements),
            scope: scope
        };
    }
    
    private function parseStatement(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        return switch currentToken {
            case TKeyword("class"):
                parseClassDeclaration(tokens, scope);
            case TKeyword("enum"):
                parseEnumDeclaration(tokens, scope);
            case TKeyword("function"):
                parseFunctionDeclaration(tokens, scope);
            case TKeyword("var") | TKeyword("const"):
                parseVariableDeclaration(tokens, scope);
            case TKeyword("use"):
                parseImportDeclaration(tokens, scope);
            case TKeyword("if"):
                parseIfStatement(tokens, scope);
            case TKeyword("while"):
                parseWhileStatement(tokens, scope);
            case TKeyword("for"):
                parseForStatement(tokens, scope);
            case TKeyword("return"):
                parseReturnStatement(tokens, scope);
            case TKeyword("break"):
                advance(tokens);
                expect(TSemi, tokens);
                YASTNode.Break;
            case TKeyword("continue"):
                advance(tokens);
                expect(TSemi, tokens);
                YASTNode.Continue;
            case TLBrace:
                parseBlock(tokens, scope);
            case TCodeBlock("haxe", content):
                advance(tokens);
                YASTNode.HaxeBlock(content);
            case TCodeBlock("lua", content):
                advance(tokens);
                YASTNode.LuaBlock(content);
            default:
                var expr = parseExpression(tokens, scope);
                if (expr != null) {
                    expect(TSemi, tokens);
                    YASTNode.Expression(expr);
                } else {
                    throw 'Unexpected token: ${currentToken}';
                }
        };
    }

    private function parseClassDeclaration(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("class"), tokens);
        var className = expectIdentifier(tokens);
        
        var superClass:Null<String> = null;
        var interfaces:Array<String> = [];
        
        if (match(TKeyword("extends"), tokens)) {
            advance(tokens);
            superClass = expectIdentifier(tokens);
        }
        
        if (match(TKeyword("implements"), tokens)) {
            advance(tokens);
            do {
                interfaces.push(expectIdentifier(tokens));
            } while (match(TComma, tokens) && {advance(tokens); true;});
        }
        
        expect(TLBrace, tokens);
        var body = [];
        
        while (!match(TRBrace, tokens)) {
            var stmt = parseStatement(tokens, scope);
            if (stmt != null) body.push(stmt);
        }
        
        expect(TRBrace, tokens);
        return YASTNode.ClassDecl(className, superClass, interfaces, body);
    }
    
    private function parseFunctionDeclaration(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("function"), tokens);
        var funcName = expectIdentifier(tokens);
        
        expect(TLParen, tokens);
        var params = [];
        while (!match(TRParen, tokens)) {
            var paramName = expectIdentifier(tokens);
            expect(TColon, tokens);
            var paramType = parseTypeReference(tokens);
            params.push(new YVar(paramName, paramType));
            
            if (!match(TComma, tokens)) break;
            advance(tokens);
        }
        expect(TRParen, tokens);
        
        var returnType = Dynamic;
        if (match(TColon, tokens)) {
            advance(tokens);
            returnType = parseTypeReference(tokens);
        }
        
        var body = parseStatement(tokens, scope);
        
        // Add to scope
        var func = new YFunction(funcName, returnType, params, "");
        scope.functions.set(funcName, func);
        
        return YASTNode.FunctionDecl(funcName, params, returnType, body);
    }
    
    private function parseVariableDeclaration(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var isConst = match(TKeyword("const"), tokens);
        advance(tokens); // consume var/const
        
        var varName = expectIdentifier(tokens);
        expect(TColon, tokens);
        var type = parseTypeReference(tokens);
        
        var init:Null<YASTNode> = null;
        if (match(TOperator("="), tokens)) {
            advance(tokens);
            init = parseExpression(tokens, scope);
        }
        
        expect(TSemi, tokens);
        
        // Add to scope
        var variable = new YVar(varName, type);
        scope.variables.set(varName, variable);
        
        return YASTNode.VariableDecl(varName, type, init);
    }
    
    private function parseEnumDeclaration(tokens:Array<Token>, scope:YScriptScope):YASTNode {
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
        
        return YASTNode.EnumDecl(enumName, values);
    }
    
    private function parseImportDeclaration(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("use"), tokens);
        var path = expectIdentifier(tokens);
        
        var alias = null;
        if (match(TKeyword("as"), tokens)) {
            advance(tokens);
            alias = expectIdentifier(tokens);
        }
        expect(TSemi, tokens);
        
        // Add to scope
        var use:YUse = { name: path, alias: alias };
        scope.imports.set(alias != null ? alias : path, use);
        
        return YASTNode.VariableDecl("import_" + path, Dynamic, null); // Temporary representation
    }
    
    private function parseIfStatement(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("if"), tokens);
        expect(TLParen, tokens);
        var condition = parseExpression(tokens, scope);
        expect(TRParen, tokens);
        
        var thenStmt = parseStatement(tokens, scope);
        
        var elseStmt:Null<YASTNode> = null;
        if (match(TKeyword("else"), tokens)) {
            advance(tokens);
            elseStmt = parseStatement(tokens, scope);
        }
        
        return YASTNode.If(condition, thenStmt, elseStmt);
    }
    
    private function parseWhileStatement(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("while"), tokens);
        expect(TLParen, tokens);
        var condition = parseExpression(tokens, scope);
        expect(TRParen, tokens);
        
        var body = parseStatement(tokens, scope);
        
        return YASTNode.While(condition, body);
    }
    
    private function parseForStatement(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("for"), tokens);
        expect(TLParen, tokens);
        
        var init:Null<YASTNode> = null;
        if (!match(TSemi, tokens)) {
            init = parseStatement(tokens, scope);
        } else {
            advance(tokens); // consume semicolon
        }
        
        var condition:Null<YASTNode> = null;
        if (!match(TSemi, tokens)) {
            condition = parseExpression(tokens, scope);
        }
        expect(TSemi, tokens);
        
        var increment:Null<YASTNode> = null;
        if (!match(TRParen, tokens)) {
            increment = parseExpression(tokens, scope);
        }
        expect(TRParen, tokens);
        
        var body = parseStatement(tokens, scope);
        
        return YASTNode.For(init, condition, increment, body);
    }
    
    private function parseReturnStatement(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TKeyword("return"), tokens);
        
        var value:Null<YASTNode> = null;
        if (!match(TSemi, tokens)) {
            value = parseExpression(tokens, scope);
        }
        expect(TSemi, tokens);
        
        return YASTNode.Return(value);
    }
    
    private function parseBlock(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        expect(TLBrace, tokens);
        var statements = [];
        
        while (!match(TRBrace, tokens)) {
            var stmt = parseStatement(tokens, scope);
            if (stmt != null) statements.push(stmt);
        }
        
        expect(TRBrace, tokens);
        return YASTNode.Block(statements);
    }
    
    // -------------------------
    // EXPRESSION PARSING
    // -------------------------
    
    private function parseExpression(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        return parseAssignment(tokens, scope);
    }
    
    private function parseAssignment(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseLogicalOr(tokens, scope);
        
        if (match(TOperator("="), tokens)) {
            advance(tokens);
            var right = parseAssignment(tokens, scope);
            return YASTNode.Assignment(left, right);
        }
        
        return left;
    }
    
    private function parseLogicalOr(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseLogicalAnd(tokens, scope);
        
        while (match(TOperator("||"), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var right = parseLogicalAnd(tokens, scope);
            left = YASTNode.BinaryOp(left, op, right);
        }
        
        return left;
    }
    
    private function parseLogicalAnd(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseEquality(tokens, scope);
        
        while (match(TOperator("&&"), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var right = parseEquality(tokens, scope);
            left = YASTNode.BinaryOp(left, op, right);
        }
        
        return left;
    }
    
    private function parseEquality(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseComparison(tokens, scope);
        
        while (match(TOperator("=="), tokens) || match(TOperator("!="), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var right = parseComparison(tokens, scope);
            left = YASTNode.BinaryOp(left, op, right);
        }
        
        return left;
    }
    
    private function parseComparison(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseAddition(tokens, scope);
        
        while (match(TOperator("<"), tokens) || match(TOperator("<="), tokens) || 
               match(TOperator(">"), tokens) || match(TOperator(">="), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var right = parseAddition(tokens, scope);
            left = YASTNode.BinaryOp(left, op, right);
        }
        
        return left;
    }
    
    private function parseAddition(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseMultiplication(tokens, scope);
        
        while (match(TOperator("+"), tokens) || match(TOperator("-"), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var right = parseMultiplication(tokens, scope);
            left = YASTNode.BinaryOp(left, op, right);
        }
        
        return left;
    }
    
    private function parseMultiplication(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parseUnary(tokens, scope);
        
        while (match(TOperator("*"), tokens) || match(TOperator("/"), tokens) || match(TOperator("%"), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var right = parseUnary(tokens, scope);
            left = YASTNode.BinaryOp(left, op, right);
        }
        
        return left;
    }
    
    private function parseUnary(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        if (match(TOperator("!"), tokens) || match(TOperator("-"), tokens) || match(TOperator("+"), tokens)) {
            var op = getCurrentTokenString();
            advance(tokens);
            var operand = parseUnary(tokens, scope);
            return YASTNode.UnaryOp(op, operand);
        }
        
        return parsePostfix(tokens, scope);
    }
    
    private function parsePostfix(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        var left = parsePrimary(tokens, scope);
        
        while (true) {
            if (match(TLParen, tokens)) {
                // Function call
                advance(tokens);
                var args = [];
                while (!match(TRParen, tokens)) {
                    args.push(parseExpression(tokens, scope));
                    if (!match(TComma, tokens)) break;
                    advance(tokens);
                }
                expect(TRParen, tokens);
                left = YASTNode.FunctionCall(left, args);
            } else if (match(TLBracket, tokens)) {
                // Array access
                advance(tokens);
                var index = parseExpression(tokens, scope);
                expect(TRBracket, tokens);
                left = YASTNode.ArrayAccess(left, index);
            } else if (match(TOperator("."), tokens)) {
                // Member access
                advance(tokens);
                var member = expectIdentifier(tokens);
                left = YASTNode.MemberAccess(left, member);
            } else {
                break;
            }
        }
        
        return left;
    }
    
    private function parsePrimary(tokens:Array<Token>, scope:YScriptScope):YASTNode {
        return switch currentToken {
            case TIdentifier(name):
                advance(tokens);
                YASTNode.Identifier(name);
            case TStringLiteral(s):
                advance(tokens);
                YASTNode.Literal(s);
            case TNumberLiteral(n):
                advance(tokens);
                YASTNode.Literal(n);
            case TKeyword("true"):
                advance(tokens);
                YASTNode.Literal(true);
            case TKeyword("false"):
                advance(tokens);
                YASTNode.Literal(false);
            case TKeyword("null"):
                advance(tokens);
                YASTNode.Literal(null);
            case TLParen:
                advance(tokens);
                var expr = parseExpression(tokens, scope);
                expect(TRParen, tokens);
                expr;
            default:
                throw 'Unexpected token in expression: ${currentToken}';
        };
    }
    
    private function getCurrentTokenString():String {
        return switch currentToken {
            case TOperator(op): op;
            case TKeyword(name): name;
            case TIdentifier(name): name;
            default: "";
        };
    }
    // Add missing helper methods
    private function readCodeBlock():String {
        var depth = 1;
        var start = pos;
        
        // Skip the opening brace
        pos++;
        
        while (pos < input.length && depth > 0) {
            var c = input.charAt(pos);
            if (c == '{') depth++;
            else if (c == '}') depth--;
            pos++;
        }
        
        return input.substring(start + 1, pos - 1); // Exclude braces
    }
    
    private function isKeyword(word:String):Bool {
        return [
            "class", "enum", "struct", "interface", "function",
            "var", "const", "extends", "implements", "public",
            "private", "protected", "static", "override", "inline",
            "if", "else", "while", "for", "switch", "case", "default",
            "return", "break", "continue", "new", "super", "this",
            "true", "false", "null", "use", "as", "haxe", "lua"
        ].contains(word);
    }
    
    private function isWhitespace(c:String):Bool {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }
    
    private function isAlpha(c:String):Bool {
        var code = c.charCodeAt(0);
        return (code >= 65 && code <= 90) || // A-Z
               (code >= 97 && code <= 122) || // a-z
               c == '_';
    }
    
    private function isDigit(c:String):Bool {
        var code = c.charCodeAt(0);
        return code >= 48 && code <= 57; // 0-9
    }
    
    private function isAlphaNumeric(c:String):Bool {
        return isAlpha(c) || isDigit(c);
    }
    
    private function peekWord(word:String):Bool {
        return input.substr(pos, word.length) == word;
    }
    
    private function readWord():String {
        var start = pos;
        while (pos < input.length && isAlphaNumeric(input.charAt(pos))) {
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

    // -------------------------
    // LEGACY PARSING FUNCTIONS (Updated)
    // -------------------------
    
    private function parseVariable(tokens:Array<Token>):YVar {
        var isConst = match(TKeyword("const"), tokens);
        expect(isConst ? TKeyword("const") : TKeyword("var"), tokens);
        
        var varName = expectIdentifier(tokens);
        expect(TColon, tokens);
        var type = parseTypeReference(tokens);
        
        var value = null;
        if (match(TOperator("="), tokens)) {
            advance(tokens);
            value = parseExpressionValue(tokens);
        }
        expect(TSemi, tokens);
        
        return new YVar(varName, type, value);
    }
    
    private function parseExpressionValue(tokens:Array<Token>):Dynamic {
        // Simple expression value parsing for legacy compatibility
        switch currentToken {
            case TNumberLiteral(n):
                advance(tokens);
                return n;
            case TStringLiteral(s):
                advance(tokens);
                return s;
            case TIdentifier(name):
                advance(tokens);
                return { type: "identifier", name: name };
            case TKeyword("true"):
                advance(tokens);
                return true;
            case TKeyword("false"):
                advance(tokens);
                return false;
            case TKeyword("null"):
                advance(tokens);
                return null;
            default:
                throw 'Unsupported token in expression: $currentToken';
        }
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
        
        var body = parseBlockString(tokens);
        
        return new YFunction(funcName, returnType, params, body);
    }
    
    private function parseParameter(tokens:Array<Token>):YVar {
        var paramName = expectIdentifier(tokens);
        expect(TColon, tokens);
        var paramType = parseTypeReference(tokens);
        
        return new YVar(paramName, paramType);
    }
    
    private function parseBlockString(tokens:Array<Token>):String {
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
        };
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
        
        // Default to public if no modifiers specified
        if (!match(TKeyword("private"), tokens) && 
            !match(TKeyword("protected"), tokens) && 
            !match(TKeyword("internal"), tokens)) {
            access.isPublic = true;
        }
        
        while (true) {
            switch currentToken {
                case TKeyword("public"):
                    access.isPublic = true;
                    advance(tokens);
                case TKeyword("private"):
                    access.isPrivate = true;
                    advance(tokens);
                case TKeyword("protected"):
                    access.isProtected = true;
                    advance(tokens);
                case TKeyword("internal"):
                    access.isInternal = true;
                    advance(tokens);
                case TKeyword("dynamic"):
                    access.isDynamic = true;
                    advance(tokens);
                default:
                    break;
            }
            
            if (!match(TKeyword("public"), tokens) &&
                !match(TKeyword("private"), tokens) &&
                !match(TKeyword("protected"), tokens) &&
                !match(TKeyword("internal"), tokens) &&
                !match(TKeyword("dynamic"), tokens)) {
                break;
            }
        }
        
        return access;
    }
    
    private function tokenToString(token:Token):String {
        return switch token {
            case TKeyword(name): name;
            case TIdentifier(name): name;
            case TLBrace: "{";
            case TRBrace: "}";
            case TLParen: "(";
            case TRParen: ")";
            case TLBracket: "[";
            case TRBracket: "]";
            case TColon: ":";
            case TComma: ",";
            case TSemi: ";";
            case TOperator(op): op;
            case TStringLiteral(s): '"' + s + '"';
            case TNumberLiteral(n): Std.string(n);
            case TCodeBlock(lang, content): lang + " {" + content + "}";
            case TEof: "EOF";
        };
    }
    
    private function isHaxeType(typeName:String):Bool {
        // Simple check - could be enhanced with actual Haxe type resolution
        return typeName.charAt(0).toUpperCase() == typeName.charAt(0) &&
            !["YClass", "YEnum", "YVar", "YFunction"].contains(typeName);
    }
    
    private function parseFunctionType(tokens:Array<Token>):Dynamic {
        // Placeholder for function type parsing
        return null;
    }
    
    private function getCurrentToken():Token {
        return currentToken;
    }
}

// -------------------------
// PROGRAM STRUCTURE
// -------------------------

// Enhanced AST-based program structure
typedef YScriptProgram = {
    ast:YASTNode,
    scope:YScriptScope
};

typedef YScriptScope = {
    variables:Map<String, YVar>,
    functions:Map<String, YFunction>,
    classes:Map<String, YClass<Dynamic>>,
    enums:Map<String, YEnum>,
    imports:Map<String, YUse>,
    parent:Null<YScriptScope>
};

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
                    if (isHaxeType(Std.string(typeName))) {
                        // Handle Haxe class extension
                        cls.extending.push(cast typeName);
                    } else {
                        // Handle YScript class extension
                        cls.extending.push(cast typeName);
                    }
                case TKeyword("implements"):
                    cls.implementing.push({name: Std.string(typeName), fields: [], methods: [], access: {isPublic: true, isPrivate: false, isInternal: false}});
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
                    advance(tokens); // Skip unknown tokens
            }
        }
        
        expect(TRBrace, tokens);
        return cls;
    }