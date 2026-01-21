"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.YScriptParser = exports.YScriptTokenizer = void 0;
// Simple working version for testing
var tokenizer_1 = require("./tokenizer");
Object.defineProperty(exports, "YScriptTokenizer", { enumerable: true, get: function () { return tokenizer_1.YScriptTokenizer; } });
class YScriptParser {
    parse(tokens) {
        return {
            type: 'Program',
            body: []
        };
    }
    getErrors() {
        return [];
    }
}
exports.YScriptParser = YScriptParser;
//# sourceMappingURL=parser-simple.js.map