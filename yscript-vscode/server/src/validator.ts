import { Program, ASTNode, ParseError } from './parser';

export interface ValidationError {
  message: string;
  start: number;
  end: number;
  line: number;
  column: number;
  details?: string;
}

export class YScriptValidator {
  private errors: ValidationError[] = [];

  validate(ast: Program): ValidationError[] {
    this.errors = [];
    this.validateNode(ast);
    return this.errors;
  }

  private validateNode(node: ASTNode): void {
    switch (node.type) {
      case 'Program':
        this.validateProgram(node as Program);
        break;
      case 'VariableDeclaration':
        this.validateVariableDeclaration(node as any);
        break;
      case 'FunctionDeclaration':
        this.validateFunctionDeclaration(node as any);
        break;
      case 'ClassDeclaration':
        this.validateClassDeclaration(node as any);
        break;
      case 'BinaryExpression':
        this.validateBinaryExpression(node as any);
        break;
      case 'CallExpression':
        this.validateCallExpression(node as any);
        break;
      case 'AssignmentExpression':
        this.validateAssignmentExpression(node as any);
        break;
      case 'Identifier':
        this.validateIdentifier(node as any);
        break;
      // Add more validation cases as needed
    }

    // Recursively validate child nodes
    this.validateChildren(node);
  }

  private validateProgram(node: Program): void {
    // Validate that the program has valid structure
    if (!node.body || !Array.isArray(node.body)) {
      this.addError(node, 'Program must have a valid body');
      return;
    }

    // Check for duplicate declarations at top level
    const declarations = new Set<string>();
    for (const stmt of node.body) {
      if (stmt.type === 'VariableDeclaration' || stmt.type === 'FunctionDeclaration' || stmt.type === 'ClassDeclaration') {
        const name = (stmt as any).name?.name || (stmt as any).identifier?.name;
        if (name) {
          if (declarations.has(name)) {
            this.addError(stmt, `Duplicate declaration: '${name}'`);
          } else {
            declarations.add(name);
          }
        }
      }
    }
  }

  private validateVariableDeclaration(node: any): void {
    // Validate identifier
    if (!node.identifier || !node.identifier.name) {
      this.addError(node, 'Variable declaration must have a valid identifier');
      return;
    }

    // Validate identifier naming
    if (!this.isValidIdentifier(node.identifier.name)) {
      this.addError(node.identifier, `Invalid variable name: '${node.identifier.name}'`);
    }

    // For const declarations, require initialization
    if (node.kind === 'const' && !node.init) {
      this.addError(node, 'Const declarations must have an initializer');
    }

    // Validate type annotation if present
    if (node.typeAnnotation && !this.isValidType(node.typeAnnotation.typeAnnotation.name)) {
      this.addError(node.typeAnnotation, `Unknown type: '${node.typeAnnotation.typeAnnotation.name}'`);
    }
  }

  private validateFunctionDeclaration(node: any): void {
    // Validate function name
    if (!node.name || !node.name.name) {
      this.addError(node, 'Function declaration must have a valid name');
      return;
    }

    if (!this.isValidIdentifier(node.name.name)) {
      this.addError(node.name, `Invalid function name: '${node.name.name}'`);
    }

    // Validate parameters
    if (node.params) {
      const paramNames = new Set<string>();
      for (const param of node.params) {
        if (!param.name || !param.name.name) {
          this.addError(param, 'Parameter must have a valid name');
          continue;
        }

        if (!this.isValidIdentifier(param.name.name)) {
          this.addError(param.name, `Invalid parameter name: '${param.name.name}'`);
        }

        // Check for duplicate parameter names
        if (paramNames.has(param.name.name)) {
          this.addError(param, `Duplicate parameter name: '${param.name.name}'`);
        } else {
          paramNames.add(param.name.name);
        }

        // Validate parameter type if present
        if (param.typeAnnotation && !this.isValidType(param.typeAnnotation.typeAnnotation.name)) {
          this.addError(param.typeAnnotation, `Unknown parameter type: '${param.typeAnnotation.typeAnnotation.name}'`);
        }
      }
    }

    // Validate return type if present
    if (node.returnType && !this.isValidType(node.returnType.typeAnnotation.name)) {
      this.addError(node.returnType, `Unknown return type: '${node.returnType.typeAnnotation.name}'`);
    }

    // Validate function body
    if (!node.body) {
      this.addError(node, 'Function must have a body');
    }
  }

  private validateClassDeclaration(node: any): void {
    // Validate class name
    if (!node.name || !node.name.name) {
      this.addError(node, 'Class declaration must have a valid name');
      return;
    }

    if (!this.isValidClassName(node.name.name)) {
      this.addError(node.name, `Invalid class name: '${node.name.name}' (must start with uppercase letter)`);
    }

    // Validate superclass if present
    if (node.superClass && !this.isValidClassName(node.superClass.name)) {
      this.addError(node.superClass, `Invalid superclass name: '${node.superClass.name}'`);
    }

    // Validate interfaces if present
    if (node.interfaces) {
      for (const iface of node.interfaces) {
        if (!this.isValidClassName(iface.name)) {
          this.addError(iface, `Invalid interface name: '${iface.name}'`);
        }
      }
    }

    // Validate class body
    if (node.body && node.body.body) {
      const memberNames = new Set<string>();
      for (const member of node.body.body) {
        const name = member.name?.name || member.identifier?.name;
        if (name && memberNames.has(name)) {
          this.addError(member, `Duplicate member name: '${name}'`);
        } else if (name) {
          memberNames.add(name);
        }
      }
    }
  }

  private validateBinaryExpression(node: any): void {
    // Validate that both operands exist
    if (!node.left) {
      this.addError(node, 'Binary expression missing left operand');
    }
    if (!node.right) {
      this.addError(node, 'Binary expression missing right operand');
    }

    // Validate operator
    const validOperators = ['+', '-', '*', '/', '%', '==', '!=', '<', '<=', '>', '>=', '&&', '||'];
    if (!validOperators.includes(node.operator)) {
      this.addError(node, `Invalid binary operator: '${node.operator}'`);
    }
  }

  private validateCallExpression(node: any): void {
    // Validate callee
    if (!node.callee) {
      this.addError(node, 'Function call missing callee');
      return;
    }

    // Validate arguments array
    if (!Array.isArray(node.arguments)) {
      this.addError(node, 'Function call arguments must be an array');
    }
  }

  private validateAssignmentExpression(node: any): void {
    // Validate that left side is assignable
    if (!node.left) {
      this.addError(node, 'Assignment missing left side');
      return;
    }

    // Check that left side is a valid assignment target
    if (node.left.type !== 'Identifier' && node.left.type !== 'MemberExpression') {
      this.addError(node.left, 'Invalid assignment target');
    }

    if (!node.right) {
      this.addError(node, 'Assignment missing right side');
    }

    // Validate assignment operator
    const validOperators = ['='];
    if (!validOperators.includes(node.operator)) {
      this.addError(node, `Invalid assignment operator: '${node.operator}'`);
    }
  }

  private validateIdentifier(node: any): void {
    if (!node.name || typeof node.name !== 'string') {
      this.addError(node, 'Identifier must have a valid name');
      return;
    }

    if (!this.isValidIdentifier(node.name)) {
      this.addError(node, `Invalid identifier: '${node.name}'`);
    }
  }

  private validateChildren(node: ASTNode): void {
    // Recursively validate child nodes
    for (const key in node) {
      const value = (node as any)[key];

      if (Array.isArray(value)) {
        for (const item of value) {
          if (item && typeof item === 'object' && item.type) {
            this.validateNode(item);
          }
        }
      } else if (value && typeof value === 'object' && value.type) {
        this.validateNode(value);
      }
    }
  }

  private isValidIdentifier(name: string): boolean {
    // YScript identifier rules: start with letter or underscore, followed by letters, digits, or underscores
    return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(name) && !this.isReservedKeyword(name);
  }

  private isValidClassName(name: string): boolean {
    // Class names should start with uppercase letter
    return /^[A-Z][a-zA-Z0-9_]*$/.test(name) && !this.isReservedKeyword(name);
  }

  private isReservedKeyword(name: string): boolean {
    const reserved = [
      'var', 'const', 'function', 'class', 'interface', 'enum', 'struct',
      'public', 'private', 'static', 'override', 'extends', 'implements',
      'if', 'else', 'while', 'for', 'do', 'return', 'break', 'continue',
      'switch', 'case', 'default', 'try', 'catch',
      'new', 'this', 'super', 'null', 'void', 'cast', 'is', 'as',
      'import', 'using', 'package', 'haxe', 'lua',
      'true', 'false'
    ];
    return reserved.includes(name);
  }

  private isValidType(typeName: string): boolean {
    // Built-in types
    const builtinTypes = ['Int', 'Float', 'String', 'Bool', 'Dynamic', 'Void', 'Array'];

    if (builtinTypes.includes(typeName)) {
      return true;
    }

    // Custom types should follow class naming convention
    return this.isValidClassName(typeName);
  }

  private addError(node: ASTNode, message: string, details?: string): void {
    this.errors.push({
      message,
      start: node.start,
      end: node.end,
      line: node.line,
      column: node.column,
      details
    });
  }
}
