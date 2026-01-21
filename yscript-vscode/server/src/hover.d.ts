import { Hover, Position } from 'vscode-languageserver/node';
import { Program } from './parser';
export declare class YScriptHover {
    getHoverInfo(ast: Program, offset: number, position: Position): Hover | null;
    private findNodeAtPosition;
    private getNodeHoverInfo;
    private getIdentifierHover;
    private getVariableDeclarationHover;
    private getFunctionDeclarationHover;
    private getClassDeclarationHover;
    private getLiteralHover;
    private getBinaryExpressionHover;
    private getCallExpressionHover;
    private getEmbeddedCodeHover;
    private getTypeExpressionHover;
    private isBuiltinType;
    private isKeyword;
    private getBuiltinTypeDocumentation;
    private getKeywordDocumentation;
    private getOperatorDocumentation;
    private getTypeString;
    private formatParameters;
}
