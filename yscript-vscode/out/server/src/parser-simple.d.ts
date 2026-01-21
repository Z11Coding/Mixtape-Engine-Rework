export { YScriptTokenizer } from './tokenizer';
export interface Program {
    type: 'Program';
    body: any[];
}
export declare class YScriptParser {
    parse(tokens: any[]): Program;
    getErrors(): any[];
}
//# sourceMappingURL=parser-simple.d.ts.map