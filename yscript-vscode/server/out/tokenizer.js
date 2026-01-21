"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.YScriptTokenizer = void 0;
class YScriptTokenizer {
    constructor() {
        this.source = '';
        this.tokens = [];
        this.start = 0;
        this.current = 0;
        this.line = 1;
        this.column = 1;
        this.keywords = {
            'auto': 'AUTO',
            'false': 'FALSE',
            'if': 'IF',
            'import': 'IMPORT',
            'noinline': 'NOINLINE',
            'null': 'NULL',
            'return': 'RETURN',
            'this': 'THIS',
            'true': 'TRUE',
            'var': 'VAR',
            'while': 'WHILE',
            'function': 'FUNCTION',
            'class': 'CLASS',
            'extends': 'EXTENDS',
            'override': 'OVERRIDE',
            'public': 'PUBLIC',
            'private': 'PRIVATE',
            'static': 'STATIC'
        };
    }
    tokenize(source) {
        this.source = source;
        this.tokens = [];
        this.start = 0;
        this.current = 0;
        this.line = 1;
        this.column = 1;
        while (!this.isAtEnd()) {
            this.start = this.current;
            this.scanToken();
        }
        this.tokens.push({
            type: 'EOF',
            value: '',
            line: this.line,
            column: this.column
        });
        return this.tokens;
    }
    isAtEnd() {
        return this.current >= this.source.length;
    }
    scanToken() {
        const char = this.advance();
        switch (char) {
            case '+':
                this.addToken('PLUS');
                break;
            case '-':
                this.addToken('MINUS');
                break;
            case '*':
                this.addToken('MULTIPLY');
                break;
            case '/':
                this.scanComment();
                break;
            case '&':
                this.addToken('AMPERSAND');
                break;
            case '|':
                this.scanPipe();
                break;
            case '!':
                this.scanBang();
                break;
            case '=':
                this.scanEqual();
                break;
            case '<':
                this.scanLess();
                break;
            case '>':
                this.scanGreater();
                break;
            case '(':
                this.addToken('LEFT_PAREN');
                break;
            case ')':
                this.addToken('RIGHT_PAREN');
                break;
            case '{':
                this.addToken('LEFT_BRACE');
                break;
            case '}':
                this.addToken('RIGHT_BRACE');
                break;
            case '[':
                this.addToken('LEFT_BRACKET');
                break;
            case ']':
                this.addToken('RIGHT_BRACKET');
                break;
            case ',':
                this.addToken('COMMA');
                break;
            case '.':
                this.addToken('DOT');
                break;
            case ';':
                this.addToken('SEMICOLON');
                break;
            case ':':
                this.addToken('COLON');
                break;
            case '"':
                this.scanString();
                break;
            case "'":
                this.scanString();
                break;
            case ' ':
            case '\r':
            case '\t':
                break; // Ignore whitespace
            case '\n':
                this.line++;
                this.column = 1;
                break;
            default:
                if (this.isAlpha(char)) {
                    this.scanIdentifier();
                }
                else if (this.isDigit(char)) {
                    this.scanNumber();
                }
                else {
                    // Ignore unknown characters for now
                }
                break;
        }
    }
    advance() {
        const char = this.source.charAt(this.current);
        this.current++;
        this.column++;
        return char;
    }
    peek() {
        if (this.isAtEnd())
            return '\0';
        return this.source.charAt(this.current);
    }
    peekNext() {
        if (this.current + 1 >= this.source.length)
            return '\0';
        return this.source.charAt(this.current + 1);
    }
    match(expected) {
        if (this.isAtEnd())
            return false;
        if (this.source.charAt(this.current) !== expected)
            return false;
        this.current++;
        this.column++;
        return true;
    }
    addToken(type, value) {
        const text = value || this.source.substring(this.start, this.current);
        this.tokens.push({
            type: type,
            value: text,
            line: this.line,
            column: this.column - text.length
        });
    }
    scanString() {
        const quote = this.source.charAt(this.current - 1);
        while (this.peek() !== quote && !this.isAtEnd()) {
            if (this.peek() === '\n') {
                this.line++;
                this.column = 1;
            }
            this.advance();
        }
        if (this.isAtEnd()) {
            // Unterminated string
            return;
        }
        // Closing quote
        this.advance();
        // Trim the surrounding quotes
        const value = this.source.substring(this.start + 1, this.current - 1);
        this.addToken('STRING', value);
    }
    scanNumber() {
        while (this.isDigit(this.peek())) {
            this.advance();
        }
        // Look for fractional part
        if (this.peek() === '.' && this.isDigit(this.peekNext())) {
            this.advance(); // Consume the "."
            while (this.isDigit(this.peek())) {
                this.advance();
            }
        }
        this.addToken('NUMBER');
    }
    scanIdentifier() {
        while (this.isAlphaNumeric(this.peek())) {
            this.advance();
        }
        const text = this.source.substring(this.start, this.current);
        const type = this.keywords[text] || 'IDENTIFIER';
        this.addToken(type);
    }
    scanComment() {
        if (this.match('/')) {
            // Single line comment
            while (this.peek() !== '\n' && !this.isAtEnd()) {
                this.advance();
            }
        }
        else if (this.match('*')) {
            // Multi-line comment
            while (!(this.peek() === '*' && this.peekNext() === '/') && !this.isAtEnd()) {
                if (this.peek() === '\n') {
                    this.line++;
                    this.column = 1;
                }
                this.advance();
            }
            if (!this.isAtEnd()) {
                this.advance(); // *
                this.advance(); // /
            }
        }
        else {
            // Division operator
            this.addToken('DIVIDE');
        }
    }
    scanPipe() {
        if (this.match('|')) {
            this.addToken('LOGICAL_OR');
        }
        else {
            this.addToken('PIPE');
        }
    }
    scanBang() {
        if (this.match('=')) {
            this.addToken('NOT_EQUAL');
        }
        else {
            this.addToken('NOT');
        }
    }
    scanEqual() {
        if (this.match('=')) {
            this.addToken('EQUAL_EQUAL');
        }
        else {
            this.addToken('EQUAL');
        }
    }
    scanLess() {
        if (this.match('=')) {
            this.addToken('LESS_EQUAL');
        }
        else {
            this.addToken('LESS');
        }
    }
    scanGreater() {
        if (this.match('=')) {
            this.addToken('GREATER_EQUAL');
        }
        else {
            this.addToken('GREATER');
        }
    }
    isDigit(char) {
        return char >= '0' && char <= '9';
    }
    isAlpha(char) {
        return (char >= 'a' && char <= 'z') ||
            (char >= 'A' && char <= 'Z') ||
            char === '_';
    }
    isAlphaNumeric(char) {
        return this.isAlpha(char) || this.isDigit(char);
    }
}
exports.YScriptTokenizer = YScriptTokenizer;
//# sourceMappingURL=tokenizer.js.map