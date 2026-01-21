import { CompletionItem, Position } from 'vscode-languageserver/node';
import { Program } from './parser';
export declare class YScriptCompletion {
    private keywords;
    private builtinTypes;
    getCompletionItems(ast: Program, offset: number, position: Position): CompletionItem[];
    resolveCompletionItem(item: CompletionItem): CompletionItem;
    private addKeywordCompletions;
    private addTypeCompletions;
    private addContextualCompletions;
    private findContext;
    private addScopeCompletions;
    private collectDeclarations;
    private extractDeclaration;
    private addClassMemberCompletions;
    private addMethodCompletions;
    private getTypeString;
    private getParent;
}
//# sourceMappingURL=completion.d.ts.map