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
export declare class YScriptParser {
    private tokens;
    private current;
    private errors;
    private start;
    parse(tokens: Token[]): Program;
    getErrors(): ParseError[];
    private isAtEnd;
    private peek;
    private previous;
    private advance;
    private check;
    private match;
    private consume;
    private addError;
    private parseStatement;
    private parseVariableDeclaration;
    private parseFunctionDeclaration;
    private parseBlockStatement;
    private parseExpression;
}
//# sourceMappingURL=parser.d.ts.map