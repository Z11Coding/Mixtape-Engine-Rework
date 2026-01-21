import {
  Hover,
  MarkupKind,
  Position
} from 'vscode-languageserver/node';

import { Program, ASTNode } from './parser';

export class YScriptHover {

  getHoverInfo(ast: Program, offset: number, position: Position): Hover | null {
    const node = this.findNodeAtPosition(ast, offset);

    if (!node) {
      return null;
    }

    const hoverInfo = this.getNodeHoverInfo(node);
    if (!hoverInfo) {
      return null;
    }

    return {
      contents: {
        kind: MarkupKind.Markdown,
        value: hoverInfo
      },
      range: {
        start: { line: node.line - 1, character: node.column },
        end: { line: node.line - 1, character: node.column + (node.end - node.start) }
      }
    };
  }

  private findNodeAtPosition(node: ASTNode, offset: number): ASTNode | null {
    // Check if this node contains the offset
    if (offset < node.start || offset > node.end) {
      return null;
    }

    // Check children first for more specific matches
    for (const key in node) {
      const value = (node as any)[key];

      if (Array.isArray(value)) {
        for (const item of value) {
          if (item && typeof item === 'object' && item.type) {
            const result = this.findNodeAtPosition(item, offset);
            if (result) return result;
          }
        }
      } else if (value && typeof value === 'object' && value.type) {
        const result = this.findNodeAtPosition(value, offset);
        if (result) return result;
      }
    }

    return node;
  }

  private getNodeHoverInfo(node: ASTNode): string | null {
    switch (node.type) {
      case 'Identifier':
        return this.getIdentifierHover(node as any);

      case 'VariableDeclaration':
        return this.getVariableDeclarationHover(node as any);

      case 'FunctionDeclaration':
        return this.getFunctionDeclarationHover(node as any);

      case 'ClassDeclaration':
        return this.getClassDeclarationHover(node as any);

      case 'Literal':
        return this.getLiteralHover(node as any);

      case 'BinaryExpression':
        return this.getBinaryExpressionHover(node as any);

      case 'CallExpression':
        return this.getCallExpressionHover(node as any);

      case 'EmbeddedCode':
        return this.getEmbeddedCodeHover(node as any);

      case 'TypeExpression':
        return this.getTypeExpressionHover(node as any);

      default:
        return null;
    }
  }

  private getIdentifierHover(node: any): string {
    const name = node.name;

    // Check if it's a built-in type
    if (this.isBuiltinType(name)) {
      return this.getBuiltinTypeDocumentation(name);
    }

    // Check if it's a keyword
    if (this.isKeyword(name)) {
      return this.getKeywordDocumentation(name);
    }

    // For variables, we'd need symbol resolution
    return `**${name}**\\n\\n*Identifier*`;
  }

  private getVariableDeclarationHover(node: any): string {
    const name = node.identifier?.name || 'unknown';
    const kind = node.kind;
    const type = this.getTypeString(node.typeAnnotation);

    let hover = `**(${kind}) ${name}**`;
    if (type !== 'Dynamic') {
      hover += `: ${type}`;
    }

    hover += '\\n\\n';

    if (kind === 'const') {
      hover += 'Immutable constant declaration. Must be initialized and cannot be reassigned.';
    } else {
      hover += 'Variable declaration. Can be reassigned after initialization.';
    }

    return hover;
  }

  private getFunctionDeclarationHover(node: any): string {
    const name = node.name?.name || 'anonymous';
    const params = this.formatParameters(node.params);
    const returnType = this.getTypeString(node.returnType) || 'Void';

    let hover = `**function ${name}**(${params})`;
    if (returnType !== 'Void') {
      hover += `: ${returnType}`;
    }

    hover += '\\n\\n';

    if (node.body?.type === 'EmbeddedCode') {
      hover += `*Contains embedded ${node.body.language} code*\\n\\n`;
    }

    hover += 'Function declaration in YScript.';

    return hover;
  }

  private getClassDeclarationHover(node: any): string {
    const name = node.name?.name || 'unknown';
    let hover = `**class ${name}**`;

    if (node.superClass) {
      hover += ` extends ${node.superClass.name}`;
    }

    if (node.interfaces && node.interfaces.length > 0) {
      const interfaces = node.interfaces.map((i: any) => i.name).join(', ');
      hover += ` implements ${interfaces}`;
    }

    hover += '\\n\\n';
    hover += 'Class declaration in YScript.';

    // Count members
    if (node.body?.body) {
      const members = node.body.body;
      const methods = members.filter((m: any) => m.type === 'FunctionDeclaration').length;
      const fields = members.filter((m: any) => m.type === 'VariableDeclaration').length;

      if (methods > 0 || fields > 0) {
        hover += `\\n\\n**Members:**`;
        if (fields > 0) hover += ` ${fields} field${fields > 1 ? 's' : ''}`;
        if (methods > 0) hover += `${fields > 0 ? ', ' : ' '}${methods} method${methods > 1 ? 's' : ''}`;
      }
    }

    return hover;
  }

  private getLiteralHover(node: any): string {
    const value = node.value;
    const raw = node.raw;

    let type: string;
    if (typeof value === 'string') {
      type = 'String';
    } else if (typeof value === 'number') {
      type = Number.isInteger(value) ? 'Int' : 'Float';
    } else if (typeof value === 'boolean') {
      type = 'Bool';
    } else {
      type = 'Dynamic';
    }

    return `**${raw}**\\n\\nType: \`${type}\`\\nValue: \`${value}\``;
  }

  private getBinaryExpressionHover(node: any): string {
    const operator = node.operator;
    const operatorInfo = this.getOperatorDocumentation(operator);

    return `**Binary Expression**\\n\\nOperator: \`${operator}\`\\n\\n${operatorInfo}`;
  }

  private getCallExpressionHover(node: any): string {
    let callee = 'unknown';

    if (node.callee?.type === 'Identifier') {
      callee = node.callee.name;
    } else if (node.callee?.type === 'MemberExpression') {
      callee = 'method call';
    }

    const argCount = node.arguments?.length || 0;

    return `**Function Call**\\n\\nFunction: \`${callee}\`\\nArguments: ${argCount}`;
  }

  private getEmbeddedCodeHover(node: any): string {
    const language = node.language;
    const lineCount = node.code.split('\\n').length;

    return `**Embedded ${language.charAt(0).toUpperCase() + language.slice(1)} Code**\\n\\n` +
           `Lines of code: ${lineCount}\\n\\n` +
           `This block contains ${language} code that will be executed with variable synchronization between YScript and ${language}.`;
  }

  private getTypeExpressionHover(node: any): string {
    const typeName = node.name;
    const genericParams = node.genericParams;

    let hover = `**Type: ${typeName}**`;

    if (genericParams && genericParams.length > 0) {
      const params = genericParams.map((p: any) => p.name).join(', ');
      hover += `<${params}>`;
    }

    hover += '\\n\\n';

    if (this.isBuiltinType(typeName)) {
      hover += this.getBuiltinTypeDocumentation(typeName);
    } else {
      hover += 'Custom type definition.';
    }

    return hover;
  }

  private isBuiltinType(name: string): boolean {
    const builtinTypes = ['Int', 'Float', 'String', 'Bool', 'Dynamic', 'Void', 'Array'];
    return builtinTypes.includes(name);
  }

  private isKeyword(name: string): boolean {
    const keywords = [
      'var', 'const', 'function', 'class', 'interface', 'enum', 'struct',
      'public', 'private', 'static', 'override', 'extends', 'implements',
      'if', 'else', 'while', 'for', 'do', 'return', 'break', 'continue',
      'switch', 'case', 'default', 'try', 'catch',
      'new', 'this', 'super', 'null', 'void', 'cast', 'is', 'as',
      'import', 'using', 'package', 'haxe', 'lua',
      'true', 'false'
    ];
    return keywords.includes(name);
  }

  private getBuiltinTypeDocumentation(typeName: string): string {
    const docs: { [key: string]: string } = {
      'Int': '32-bit signed integer type.\\n\\nRange: -2,147,483,648 to 2,147,483,647',
      'Float': '64-bit floating point number type.\\n\\nSupports decimal numbers and scientific notation.',
      'String': 'Unicode string type.\\n\\nSupports escape sequences and string interpolation.',
      'Bool': 'Boolean type with values `true` and `false`.\\n\\nUsed for logical operations and conditions.',
      'Dynamic': 'Dynamic type that can hold any value.\\n\\nAllows runtime type checking and flexibility.',
      'Void': 'Void type representing no value.\\n\\nUsed as function return type when no value is returned.',
      'Array': 'Generic array type.\\n\\nStores multiple elements of the specified type.\\n\\nExample: `Array<Int>`'
    };

    return docs[typeName] || 'Built-in type.';
  }

  private getKeywordDocumentation(keyword: string): string {
    const docs: { [key: string]: string } = {
      'var': 'Declares a mutable variable.\\n\\nCan be reassigned after initialization.',
      'const': 'Declares an immutable constant.\\n\\nMust be initialized and cannot be reassigned.',
      'function': 'Declares a function.\\n\\nCan have parameters and a return type.',
      'class': 'Declares a class.\\n\\nCan extend other classes and implement interfaces.',
      'if': 'Conditional statement.\\n\\nExecutes code based on a boolean condition.',
      'else': 'Alternative branch for if statements.\\n\\nExecutes when the if condition is false.',
      'while': 'Loop statement.\\n\\nRepeats while the condition is true.',
      'for': 'Loop statement.\\n\\nIncludes initialization, condition, and increment.',
      'return': 'Returns a value from a function.\\n\\nExits the function execution.',
      'new': 'Creates a new instance of a class.\\n\\nCalls the class constructor.',
      'this': 'Reference to the current instance.\\n\\nUsed within class methods.',
      'super': 'Reference to the parent class.\\n\\nUsed to call parent methods or constructor.',
      'null': 'Represents no value or null reference.\\n\\nUsed for uninitialized or empty values.',
      'haxe': 'Embedded Haxe code block.\\n\\nExecutes native Haxe code with variable sync.',
      'lua': 'Embedded Lua code block.\\n\\nExecutes Lua code with variable sync.',
      'true': 'Boolean literal true value.',
      'false': 'Boolean literal false value.'
    };

    return docs[keyword] || 'YScript keyword.';
  }

  private getOperatorDocumentation(operator: string): string {
    const docs: { [key: string]: string } = {
      '+': 'Addition operator.\\n\\nAdds two numbers or concatenates strings.',
      '-': 'Subtraction operator.\\n\\nSubtracts the right operand from the left.',
      '*': 'Multiplication operator.\\n\\nMultiplies two numbers.',
      '/': 'Division operator.\\n\\nDivides the left operand by the right.',
      '%': 'Modulo operator.\\n\\nReturns the remainder of division.',
      '==': 'Equality operator.\\n\\nCompares two values for equality.',
      '!=': 'Inequality operator.\\n\\nCompares two values for inequality.',
      '<': 'Less than operator.\\n\\nChecks if left is less than right.',
      '<=': 'Less than or equal operator.\\n\\nChecks if left is less than or equal to right.',
      '>': 'Greater than operator.\\n\\nChecks if left is greater than right.',
      '>=': 'Greater than or equal operator.\\n\\nChecks if left is greater than or equal to right.',
      '&&': 'Logical AND operator.\\n\\nReturns true if both operands are true.',
      '||': 'Logical OR operator.\\n\\nReturns true if either operand is true.',
      '=': 'Assignment operator.\\n\\nAssigns the right value to the left variable.'
    };

    return docs[operator] || 'Binary operator.';
  }

  private getTypeString(typeAnnotation: any): string {
    if (!typeAnnotation?.typeAnnotation) return 'Dynamic';

    const type = typeAnnotation.typeAnnotation;
    let result = type.name;

    if (type.genericParams && type.genericParams.length > 0) {
      const params = type.genericParams.map((p: any) => p.name).join(', ');
      result += `<${params}>`;
    }

    return result;
  }

  private formatParameters(params: any[]): string {
    if (!params || params.length === 0) {
      return '';
    }

    return params.map((param: any) => {
      const name = param.name?.name || 'param';
      const type = this.getTypeString(param.typeAnnotation);
      return type !== 'Dynamic' ? `${name}: ${type}` : name;
    }).join(', ');
  }
}
