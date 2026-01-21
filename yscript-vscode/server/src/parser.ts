import { Token } from './tokenizer';

export interface ParseError {
    message: string;
    line: number;
    column: number;
}

export interface ASTNode {
    type: string;
    line: number;
    column: number;
    start: number;
    end: number;
}

export interface Program extends ASTNode {
    type: 'Program';
    body: ASTNode[];
}

export interface VariableDeclaration extends ASTNode {
    type: 'VariableDeclaration';
    id: Identifier;
    init?: ASTNode;
}

export interface FunctionDeclaration extends ASTNode {
    type: 'FunctionDeclaration';
    id: Identifier;
    params: Identifier[];
    body: BlockStatement;
}

export interface Identifier extends ASTNode {
    type: 'Identifier';
    name: string;
}

export interface BlockStatement extends ASTNode {
    type: 'BlockStatement';
    body: ASTNode[];
}

export class YScriptParser {
    private tokens: Token[] = [];
    private current: number = 0;
    private errors: ParseError[] = [];
    private start: number = 0;

    parse(tokens: Token[]): Program {
        this.tokens = tokens;
        this.current = 0;
        this.errors = [];

        const statements: ASTNode[] = [];

        while (!this.isAtEnd()) {
            try {
                const stmt = this.parseStatement();
                if (stmt) {
                    statements.push(stmt);
                }
            } catch (error) {
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

    getErrors(): ParseError[] {
        return this.errors;
    }

    private isAtEnd(): boolean {
        return this.peek().type === 'EOF';
    }

    private peek(): Token {
        return this.tokens[this.current] || { type: 'EOF', value: '', line: 0, column: 0 };
    }

    private previous(): Token {
        return this.tokens[this.current - 1];
    }

    private advance(): Token {
        if (!this.isAtEnd()) this.current++;
        return this.previous();
    }

    private check(type: string): boolean {
        if (this.isAtEnd()) return false;
        return this.peek().type === type;
    }

    private match(...types: string[]): boolean {
        for (const type of types) {
            if (this.check(type)) {
                this.advance();
                return true;
            }
        }
        return false;
    }

    private consume(type: string, message: string): Token {
        if (this.check(type)) return this.advance();

        this.addError(message);
        throw new Error(message);
    }

    private addError(message: string): void {
        const token = this.peek();
        this.errors.push({
            message: message,
            line: token.line,
            column: token.column
        });
    }

    private parseStatement(): ASTNode | null {
        this.start = this.current;
        try {
            if (this.match('VAR')) return this.parseVariableDeclaration();
            if (this.match('FUNCTION')) return this.parseFunctionDeclaration();

            // Skip unknown statements for now
            const token = this.advance();
            return {
                type: 'Unknown',
                line: token.line,
                column: token.column,
                start: this.start,
                end: this.current
            };
        } catch (error) {
            return null;
        }
    }

    private parseVariableDeclaration(): VariableDeclaration {
        const name = this.consume('IDENTIFIER', 'Expected variable name');

        let init: ASTNode | undefined;
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

    private parseFunctionDeclaration(): FunctionDeclaration {
        const name = this.consume('IDENTIFIER', 'Expected function name');

        this.consume('LEFT_PAREN', 'Expected opening parenthesis after function name');

        const params: Identifier[] = [];
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

    private parseBlockStatement(): BlockStatement {
        const opening = this.consume('LEFT_BRACE', 'Expected opening brace');

        const statements: ASTNode[] = [];
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

    private parseExpression(): ASTNode {
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
