export interface Token {
    type: string;
    value: string;
    line: number;
    column: number;
}

export class YScriptTokenizer {
    private source: string = '';
    private tokens: Token[] = [];
    private start: number = 0;
    private current: number = 0;
    private line: number = 1;
    private column: number = 1;

    private keywords: { [key: string]: string } = {
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

    tokenize(source: string): Token[] {
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

    private isAtEnd(): boolean {
        return this.current >= this.source.length;
    }

    private scanToken(): void {
        const char = this.advance();

        switch (char) {
            case '+': this.addToken('PLUS'); break;
            case '-': this.addToken('MINUS'); break;
            case '*': this.addToken('MULTIPLY'); break;
            case '/': this.scanComment(); break;
            case '&': this.addToken('AMPERSAND'); break;
            case '|': this.scanPipe(); break;
            case '!': this.scanBang(); break;
            case '=': this.scanEqual(); break;
            case '<': this.scanLess(); break;
            case '>': this.scanGreater(); break;
            case '(': this.addToken('LEFT_PAREN'); break;
            case ')': this.addToken('RIGHT_PAREN'); break;
            case '{': this.addToken('LEFT_BRACE'); break;
            case '}': this.addToken('RIGHT_BRACE'); break;
            case '[': this.addToken('LEFT_BRACKET'); break;
            case ']': this.addToken('RIGHT_BRACKET'); break;
            case ',': this.addToken('COMMA'); break;
            case '.': this.addToken('DOT'); break;
            case ';': this.addToken('SEMICOLON'); break;
            case ':': this.addToken('COLON'); break;
            case '"': this.scanString(); break;
            case "'": this.scanString(); break;
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
                } else if (this.isDigit(char)) {
                    this.scanNumber();
                } else {
                    // Ignore unknown characters for now
                }
                break;
        }
    }

    private advance(): string {
        const char = this.source.charAt(this.current);
        this.current++;
        this.column++;
        return char;
    }

    private peek(): string {
        if (this.isAtEnd()) return '\0';
        return this.source.charAt(this.current);
    }

    private peekNext(): string {
        if (this.current + 1 >= this.source.length) return '\0';
        return this.source.charAt(this.current + 1);
    }

    private match(expected: string): boolean {
        if (this.isAtEnd()) return false;
        if (this.source.charAt(this.current) !== expected) return false;

        this.current++;
        this.column++;
        return true;
    }

    private addToken(type: string, value?: string): void {
        const text = value || this.source.substring(this.start, this.current);
        this.tokens.push({
            type: type,
            value: text,
            line: this.line,
            column: this.column - text.length
        });
    }

    private scanString(): void {
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

    private scanNumber(): void {
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

    private scanIdentifier(): void {
        while (this.isAlphaNumeric(this.peek())) {
            this.advance();
        }

        const text = this.source.substring(this.start, this.current);
        const type = this.keywords[text] || 'IDENTIFIER';
        this.addToken(type);
    }

    private scanComment(): void {
        if (this.match('/')) {
            // Single line comment
            while (this.peek() !== '\n' && !this.isAtEnd()) {
                this.advance();
            }
        } else if (this.match('*')) {
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
        } else {
            // Division operator
            this.addToken('DIVIDE');
        }
    }

    private scanPipe(): void {
        if (this.match('|')) {
            this.addToken('LOGICAL_OR');
        } else {
            this.addToken('PIPE');
        }
    }

    private scanBang(): void {
        if (this.match('=')) {
            this.addToken('NOT_EQUAL');
        } else {
            this.addToken('NOT');
        }
    }

    private scanEqual(): void {
        if (this.match('=')) {
            this.addToken('EQUAL_EQUAL');
        } else {
            this.addToken('EQUAL');
        }
    }

    private scanLess(): void {
        if (this.match('=')) {
            this.addToken('LESS_EQUAL');
        } else {
            this.addToken('LESS');
        }
    }

    private scanGreater(): void {
        if (this.match('=')) {
            this.addToken('GREATER_EQUAL');
        } else {
            this.addToken('GREATER');
        }
    }

    private isDigit(char: string): boolean {
        return char >= '0' && char <= '9';
    }

    private isAlpha(char: string): boolean {
        return (char >= 'a' && char <= 'z') ||
               (char >= 'A' && char <= 'Z') ||
               char === '_';
    }

    private isAlphaNumeric(char: string): boolean {
        return this.isAlpha(char) || this.isDigit(char);
    }
}