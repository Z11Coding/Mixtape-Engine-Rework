// Simple working version for testing
export { YScriptTokenizer } from './tokenizer';

// Simplified parser for initial compilation
export interface Program {
  type: 'Program';
  body: any[];
}

export class YScriptParser {
  parse(tokens: any[]): Program {
    return {
      type: 'Program',
      body: []
    };
  }

  getErrors(): any[] {
    return [];
  }
}
