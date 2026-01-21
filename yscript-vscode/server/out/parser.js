"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.YScriptParser = void 0;
class YScriptParser {
    constructor() {
        this.tokens = [];
        this.current = 0;
        this.errors = [];
        this.start = 0;
    }
    parse(tokens) {
        this.tokens = tokens;
        this.current = 0;
        this.errors = [];
        const statements = [];
        while (!this.isAtEnd()) {
            try {
                const stmt = this.parseStatement();
                if (stmt) {
                    statements.push(stmt);
                }
            }
            catch (error) {
                this.addError(`Parse error: ${error}`);
                this.advance(); // Skip problematic token
            }
        }
        return {
            type: 'Program',
            body: statements,
            line: 1,
            column: 1,
            start: 0,
            end: this.current
        };
    }
    getErrors() {
        return this.errors;
    }
    isAtEnd() {
        return this.peek().type === 'EOF';
    }
    peek() {
        return this.tokens[this.current] || { type: 'EOF', value: '', line: 0, column: 0 };
    }
    previous() {
        return this.tokens[this.current - 1];
    }
    advance() {
        if (!this.isAtEnd())
            this.current++;
        return this.previous();
    }
    check(type) {
        if (this.isAtEnd())
            return false;
        return this.peek().type === type;
    }
    match(...types) {
        for (const type of types) {
            if (this.check(type)) {
                this.advance();
                return true;
            }
        }
        return false;
    }
    consume(type, message) {
        if (this.check(type))
            return this.advance();
        this.addError(message);
        throw new Error(message);
    }
    addError(message) {
        const token = this.peek();
        this.errors.push({
            message: message,
            line: token.line,
            column: token.column
        });
    }
    parseStatement() {
        this.start = this.current;
        try {
            if (this.match('VAR'))
                return this.parseVariableDeclaration();
            if (this.match('FUNCTION'))
                return this.parseFunctionDeclaration();
            // Skip unknown statements for now
            const token = this.advance();
            return {
                type: 'Unknown',
                line: token.line,
                column: token.column,
                start: this.start,
                end: this.current
            };
        }
        catch (error) {
            return null;
        }
    }
    parseVariableDeclaration() {
        const name = this.consume('IDENTIFIER', 'Expected variable name');
        let init;
        if (this.match('EQUAL')) {
            init = this.parseExpression();
        }
        this.consume('SEMICOLON', 'Expected semicolon after variable declaration');
        return {
            type: 'VariableDeclaration',
            id: {
                type: 'Identifier',
                name: name.value,
                line: name.line,
                column: name.column,
                start: this.start,
                end: this.current
            },
            init: init,
            line: name.line,
            column: name.column,
            start: this.start,
            end: this.current
        };
    }
    parseFunctionDeclaration() {
        const name = this.consume('IDENTIFIER', 'Expected function name');
        this.consume('LEFT_PAREN', 'Expected opening parenthesis after function name');
        const params = [];
        if (!this.check('RIGHT_PAREN')) {
            do {
                const param = this.consume('IDENTIFIER', 'Expected parameter name');
                params.push({
                    type: 'Identifier',
                    name: param.value,
                    line: param.line,
                    column: param.column,
                    start: this.start,
                    end: this.current
                });
            } while (this.match('COMMA'));
        }
        this.consume('RIGHT_PAREN', 'Expected closing parenthesis after parameters');
        const body = this.parseBlockStatement();
        return {
            type: 'FunctionDeclaration',
            id: {
                type: 'Identifier',
                name: name.value,
                line: name.line,
                column: name.column,
                start: this.start,
                end: this.current
            },
            params: params,
            body: body,
            line: name.line,
            column: name.column,
            start: this.start,
            end: this.current
        };
    }
    parseBlockStatement() {
        const opening = this.consume('LEFT_BRACE', 'Expected opening brace');
        const statements = [];
        while (!this.check('RIGHT_BRACE') && !this.isAtEnd()) {
            const stmt = this.parseStatement();
            if (stmt) {
                statements.push(stmt);
            }
        }
        this.consume('RIGHT_BRACE', 'Expected closing brace');
        return {
            type: 'BlockStatement',
            body: statements,
            line: opening.line,
            column: opening.column,
            start: this.start,
            end: this.current
        };
    }
    parseExpression() {
        // Simplified expression parsing for now
        const token = this.advance();
        return {
            type: 'Literal',
            line: token.line,
            column: token.column,
            start: this.start,
            end: this.current
        };
    }
}
exports.YScriptParser = YScriptParser;
//# sourceMappingURL=parser.js.map