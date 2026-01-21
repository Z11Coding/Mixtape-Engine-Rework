export interface Token {
    type: string;
    value: string;
    line: number;
    column: number;
}
export declare class YScriptTokenizer {
    private source;
    private tokens;
    private start;
    private current;
    private line;
    private column;
    private keywords;
    tokenize(source: string): Token[];
    private isAtEnd;
    private scanToken;
    private advance;
    private peek;
    private peekNext;
    private match;
    private addToken;
    private scanString;
    private scanNumber;
    private scanIdentifier;
    private scanComment;
    private scanPipe;
    private scanBang;
    private scanEqual;
    private scanLess;
    private scanGreater;
    private isDigit;
    private isAlpha;
    private isAlphaNumeric;
}
//# sourceMappingURL=tokenizer.d.ts.map