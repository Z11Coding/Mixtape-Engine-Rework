import { Program } from './parser';
export interface ValidationError {
    message: string;
    start: number;
    end: number;
    line: number;
    column: number;
    details?: string;
}
export declare class YScriptValidator {
    private errors;
    validate(ast: Program): ValidationError[];
    private validateNode;
    private validateProgram;
    private validateVariableDeclaration;
    private validateFunctionDeclaration;
    private validateClassDeclaration;
    private validateBinaryExpression;
    private validateCallExpression;
    private validateAssignmentExpression;
    private validateIdentifier;
    private validateChildren;
    private isValidIdentifier;
    private isValidClassName;
    private isReservedKeyword;
    private isValidType;
    private addError;
}
//# sourceMappingURL=validator.d.ts.map