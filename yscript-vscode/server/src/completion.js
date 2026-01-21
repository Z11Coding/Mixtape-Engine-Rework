"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.YScriptCompletion = void 0;
const node_1 = require("vscode-languageserver/node");
class YScriptCompletion {
    constructor() {
        this.keywords = [
            'var', 'const', 'function', 'class', 'interface', 'enum', 'struct',
            'public', 'private', 'static', 'override', 'extends', 'implements',
            'if', 'else', 'while', 'for', 'do', 'return', 'break', 'continue',
            'switch', 'case', 'default', 'try', 'catch',
            'new', 'this', 'super', 'null', 'void', 'cast', 'is', 'as',
            'import', 'using', 'package', 'haxe', 'lua',
            'true', 'false'
        ];
        this.builtinTypes = [
            'Int', 'Float', 'String', 'Bool', 'Dynamic', 'Void', 'Array'
        ];
    }
    getCompletionItems(ast, offset, position) {
        const completions = [];
        // Add keyword completions
        this.addKeywordCompletions(completions);
        // Add built-in type completions
        this.addTypeCompletions(completions);
        // Add context-aware completions
        this.addContextualCompletions(ast, offset, position, completions);
        return completions;
    }
    resolveCompletionItem(item) {
        // Add detailed information for specific completion items
        switch (item.label) {
            case 'function':
                item.detail = 'Function Declaration';
                item.documentation = 'Declares a new function with optional parameters and return type';
                item.insertText = 'function ${1:name}(${2:params}): ${3:ReturnType} {\n\t${4:// function body}\n}';
                break;
            case 'class':
                item.detail = 'Class Declaration';
                item.documentation = 'Declares a new class with optional inheritance and interfaces';
                item.insertText = 'class ${1:ClassName} {\n\t${2:// class body}\n}';
                break;
            case 'var':
                item.detail = 'Variable Declaration';
                item.documentation = 'Declares a mutable variable with optional type annotation';
                item.insertText = 'var ${1:name}: ${2:Type} = ${3:value};';
                break;
            case 'const':
                item.detail = 'Constant Declaration';
                item.documentation = 'Declares an immutable constant with required initialization';
                item.insertText = 'const ${1:NAME}: ${2:Type} = ${3:value};';
                break;
            case 'if':
                item.detail = 'If Statement';
                item.documentation = 'Conditional execution statement';
                item.insertText = 'if (${1:condition}) {\n\t${2:// if body}\n}';
                break;
            case 'while':
                item.detail = 'While Loop';
                item.documentation = 'Loop that continues while condition is true';
                item.insertText = 'while (${1:condition}) {\n\t${2:// loop body}\n}';
                break;
            case 'for':
                item.detail = 'For Loop';
                item.documentation = 'Loop with initialization, condition, and increment';
                item.insertText = 'for (${1:init}; ${2:condition}; ${3:increment}) {\n\t${4:// loop body}\n}';
                break;
            case 'haxe':
                item.detail = 'Embedded Haxe Code';
                item.documentation = 'Execute native Haxe code with variable synchronization';
                item.insertText = 'haxe {\n\t${1:// Haxe code}\n}';
                break;
            case 'lua':
                item.detail = 'Embedded Lua Code';
                item.documentation = 'Execute Lua code with variable synchronization';
                item.insertText = 'lua {\n\t${1:-- Lua code}\n}';
                break;
            // Built-in types
            case 'Array':
                item.detail = 'Array<T>';
                item.documentation = 'Dynamic array type with generic element type';
                item.insertText = 'Array<${1:ElementType}>';
                break;
        }
        return item;
    }
    addKeywordCompletions(completions) {
        for (const keyword of this.keywords) {
            completions.push({
                label: keyword,
                kind: node_1.CompletionItemKind.Keyword,
                data: { type: 'keyword', value: keyword }
            });
        }
    }
    addTypeCompletions(completions) {
        for (const type of this.builtinTypes) {
            completions.push({
                label: type,
                kind: node_1.CompletionItemKind.TypeParameter,
                data: { type: 'builtinType', value: type }
            });
        }
    }
    addContextualCompletions(ast, offset, position, completions) {
        // Find the scope context at the current position
        const context = this.findContext(ast, offset);
        if (context) {
            // Add variables and functions in scope
            this.addScopeCompletions(context, completions);
            // Add class members if in class context
            this.addClassMemberCompletions(context, completions);
            // Add method suggestions based on type
            this.addMethodCompletions(context, position, completions);
        }
    }
    findContext(node, offset) {
        // Find the most specific AST node containing the offset
        if (offset < node.start || offset > node.end) {
            return null;
        }
        // Check children first for more specific context
        for (const key in node) {
            const value = node[key];
            if (Array.isArray(value)) {
                for (const item of value) {
                    if (item && typeof item === 'object' && item.type) {
                        const result = this.findContext(item, offset);
                        if (result)
                            return result;
                    }
                }
            }
            else if (value && typeof value === 'object' && value.type) {
                const result = this.findContext(value, offset);
                if (result)
                    return result;
            }
        }
        return node;
    }
    addScopeCompletions(context, completions) {
        // Walk up the AST to collect variables and functions in scope
        let current = context;
        const seen = new Set();
        while (current) {
            this.collectDeclarations(current, completions, seen);
            current = this.getParent(current);
        }
    }
    collectDeclarations(node, completions, seen) {
        switch (node.type) {
            case 'Program':
            case 'BlockStatement':
            case 'ClassBody':
                const body = node.body;
                if (Array.isArray(body)) {
                    for (const stmt of body) {
                        this.extractDeclaration(stmt, completions, seen);
                    }
                }
                break;
            case 'FunctionDeclaration':
                // Add parameters to scope
                const params = node.params;
                if (Array.isArray(params)) {
                    for (const param of params) {
                        if (param.name && !seen.has(param.name.name)) {
                            completions.push({
                                label: param.name.name,
                                kind: node_1.CompletionItemKind.Variable,
                                detail: this.getTypeString(param.typeAnnotation),
                                data: { type: 'parameter' }
                            });
                            seen.add(param.name.name);
                        }
                    }
                }
                break;
        }
    }
    extractDeclaration(stmt, completions, seen) {
        switch (stmt.type) {
            case 'VariableDeclaration':
                const varDecl = stmt;
                if (varDecl.identifier && !seen.has(varDecl.identifier.name)) {
                    completions.push({
                        label: varDecl.identifier.name,
                        kind: varDecl.kind === 'const' ? node_1.CompletionItemKind.Constant : node_1.CompletionItemKind.Variable,
                        detail: this.getTypeString(varDecl.typeAnnotation),
                        data: { type: 'variable', kind: varDecl.kind }
                    });
                    seen.add(varDecl.identifier.name);
                }
                break;
            case 'FunctionDeclaration':
                const funcDecl = stmt;
                if (funcDecl.name && !seen.has(funcDecl.name.name)) {
                    const params = funcDecl.params?.map((p) => `${p.name.name}${p.typeAnnotation ? ': ' + this.getTypeString(p.typeAnnotation) : ''}`).join(', ') || '';
                    completions.push({
                        label: funcDecl.name.name,
                        kind: node_1.CompletionItemKind.Function,
                        detail: `function(${params})${funcDecl.returnType ? ': ' + this.getTypeString(funcDecl.returnType) : ''}`,
                        data: { type: 'function' }
                    });
                    seen.add(funcDecl.name.name);
                }
                break;
            case 'ClassDeclaration':
                const classDecl = stmt;
                if (classDecl.name && !seen.has(classDecl.name.name)) {
                    completions.push({
                        label: classDecl.name.name,
                        kind: node_1.CompletionItemKind.Class,
                        detail: 'class',
                        data: { type: 'class' }
                    });
                    seen.add(classDecl.name.name);
                }
                break;
        }
    }
    addClassMemberCompletions(context, completions) {
        // Find if we're in a class context
        let current = context;
        while (current && current.type !== 'ClassDeclaration') {
            current = this.getParent(current);
        }
        if (current?.type === 'ClassDeclaration') {
            const classNode = current;
            // Add 'this' keyword
            completions.push({
                label: 'this',
                kind: node_1.CompletionItemKind.Keyword,
                detail: classNode.name.name,
                data: { type: 'this' }
            });
            // Add 'super' if class extends something
            if (classNode.superClass) {
                completions.push({
                    label: 'super',
                    kind: node_1.CompletionItemKind.Keyword,
                    detail: classNode.superClass.name,
                    data: { type: 'super' }
                });
            }
        }
    }
    addMethodCompletions(context, position, completions) {
        // This would analyze the context to suggest methods available on objects
        // For now, provide basic method suggestions
        const commonMethods = [
            { name: 'toString', kind: node_1.CompletionItemKind.Method, detail: '(): String' },
            { name: 'valueOf', kind: node_1.CompletionItemKind.Method, detail: '(): Dynamic' }
        ];
        for (const method of commonMethods) {
            completions.push({
                label: method.name,
                kind: method.kind,
                detail: method.detail,
                data: { type: 'method' }
            });
        }
    }
    getTypeString(typeAnnotation) {
        if (!typeAnnotation?.typeAnnotation)
            return 'Dynamic';
        const type = typeAnnotation.typeAnnotation;
        let result = type.name;
        if (type.genericParams && type.genericParams.length > 0) {
            const params = type.genericParams.map((p) => p.name).join(', ');
            result += `<${params}>`;
        }
        return result;
    }
    getParent(node) {
        // This would require parent references in the AST
        // For now, return null - parent tracking would need to be added to the parser
        return null;
    }
}
exports.YScriptCompletion = YScriptCompletion;
