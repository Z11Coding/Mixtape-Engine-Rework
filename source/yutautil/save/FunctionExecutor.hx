package yutautil.save;

import yutautil.save.ExpressionTree;
import yutautil.save.ScopeManager;

/**
 * Runtime execution system for captured functions using expression trees
 */
class FunctionExecutor {

    /**
     * Execute a captured function with the given arguments
     * @param func The captured function definition
     * @param args The arguments to pass
     * @param instance The instance to execute on (required for instance methods)
     * @return The result of the function execution
     */
    public static function execute(func:CapturedFunction, args:Array<Dynamic>, ?instance:Dynamic):Dynamic {
        // Validate execution context
        switch (func.functionType) {
            case Instance:
                if (instance == null) {
                    throw 'Instance function ${func.id} requires an instance of ${func.className}';
                }
                validateInstanceType(instance, func.className);
            case Static:
                // Static functions don't need instances
            case Lambda | Anonymous:
                // Lambda functions can optionally use context
        }

        // Validate arguments
        validateArguments(func.args, args);

        // Create execution scope
        var scope = new ScopeManager();
        scope.enterScope("function");

        // Add function arguments to scope
        for (i in 0...func.args.length) {
            var argDef = func.args[i];
            var value = i < args.length ? args[i] : getDefaultValue(argDef);
            scope.setVariable(argDef.name, value);
        }

        // Add 'this' context for instance functions
        if (func.functionType == Instance && instance != null) {
            scope.setVariable("this", instance);
        }

        try {
            var result = executeExpression(func.body, scope);
            scope.exitScope();
            return result;
        } catch (e:FunctionReturnException) {
            scope.exitScope();
            return e.value;
        } catch (e:Dynamic) {
            scope.exitScope();
            throw 'Error executing function ${func.id}: ${e}';
        }
    }

    /**
     * Execute an expression tree in the given scope
     */
    public static function executeExpression(expr:ExpressionTree, scope:ScopeManager):Dynamic {
        if (expr == null) return null;

        return switch (expr) {
            case ENull:
                null;

            case EConst(c):
                executeConstant(c);

            case EArray(e1, e2):
                var obj = executeExpression(e1, scope);
                var index = executeExpression(e2, scope);
                Reflect.getProperty(obj, Std.string(index));

            case EBinop(op, e1, e2):
                executeBinop(op, e1, e2, scope);

            case EField(e, field):
                var obj = executeExpression(e, scope);
                if (obj == null) throw 'Null object reference accessing field: ${field}';
                Reflect.field(obj, field);

            case EObjectDecl(fields):
                var obj = {};
                for (field in fields) {
                    var value = executeExpression(field.expr, scope);
                    Reflect.setField(obj, field.field, value);
                }
                obj;

            case EArrayDecl(values):
                [for (value in values) executeExpression(value, scope)];

            case ECall(e, params):
                executeCall(e, params, scope);

            case ENew(name, pack, params):
                executeNew(name, pack, params, scope);

            case EUnop(op, postFix, e):
                executeUnop(op, postFix, e, scope);

            case EVars(vars):
                for (v in vars) {
                    var value = v.expr != null ? executeExpression(v.expr, scope) : null;
                    scope.setVariable(v.name, value);
                }
                null;

            case EFunction(kind, func):
                // Create a lambda function - store the function definition for later execution
                new CapturedLambda(func, scope.cloneScope());

            case EBlock(exprs):
                scope.enterScope("block");
                var result:Dynamic = null;
                for (expr in exprs) {
                    result = executeExpression(expr, scope);
                }
                scope.exitScope();
                result;

            case EFor(it, expr):
                executeFor(it, expr, scope);

            case EIf(econd, eif, eelse):
                var condition = executeExpression(econd, scope);
                if (isTruthy(condition)) {
                    executeExpression(eif, scope);
                } else if (eelse != null && eelse != ENull) {
                    executeExpression(eelse, scope);
                } else {
                    null;
                }

            case EWhile(econd, e, normalWhile):
                var result:Dynamic = null;
                if (normalWhile) {
                    while (isTruthy(executeExpression(econd, scope))) {
                        try {
                            result = executeExpression(e, scope);
                        } catch (e:LoopBreakException) {
                            break;
                        } catch (e:LoopContinueException) {
                            continue;
                        }
                    }
                } else {
                    // do-while
                    do {
                        try {
                            result = executeExpression(e, scope);
                        } catch (e:LoopBreakException) {
                            break;
                        } catch (e:LoopContinueException) {
                            continue;
                        }
                    } while (isTruthy(executeExpression(econd, scope)));
                }
                result;

            case ESwitch(e, cases, edef):
                executeSwitch(e, cases, edef, scope);

            case ETry(e, catches):
                executeTry(e, catches, scope);

            case EReturn(e):
                var value = e != null && e != ENull ? executeExpression(e, scope) : null;
                throw new FunctionReturnException(value);

            case EBreak:
                throw new LoopBreakException();

            case EContinue:
                throw new LoopContinueException();

            case EThrow(e):
                var value = executeExpression(e, scope);
                throw value;

            case ECast(e, t):
                var value = executeExpression(e, scope);
                // TODO: Implement proper casting
                value;

            case ETernary(econd, eif, eelse):
                var condition = executeExpression(econd, scope);
                if (isTruthy(condition)) {
                    executeExpression(eif, scope);
                } else {
                    executeExpression(eelse, scope);
                }

            case ECheckType(e, t):
                // Type checking - for now just return the expression result
                executeExpression(e, scope);

            case EIs(e, t):
                var value = executeExpression(e, scope);
                // TODO: Implement proper type checking
                true; // Placeholder
        };
    }

    private static function executeConstant(c:ConstantTree):Dynamic {
        return switch (c) {
            case CInt(v): Std.parseInt(v);
            case CFloat(f): Std.parseFloat(f);
            case CString(s): s;
            case CIdent(s):
                // Handle special identifiers
                switch (s) {
                    case "null": null;
                    case "true": true;
                    case "false": false;
                    case _: s; // Return as string for now
                }
            case CRegexp(r, opt): new EReg(r, opt);
        };
    }

    private static function executeBinop(op:String, e1:ExpressionTree, e2:ExpressionTree, scope:ScopeManager):Dynamic {
        return switch (op) {
            case "+":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                v1 + v2;
            case "-":
                var v1:Float = executeExpression(e1, scope);
                var v2:Float = executeExpression(e2, scope);
                v1 - v2;
            case "*":
                var v1:Float = executeExpression(e1, scope);
                var v2:Float = executeExpression(e2, scope);
                v1 * v2;
            case "/":
                var v1:Float = executeExpression(e1, scope);
                var v2:Float = executeExpression(e2, scope);
                v1 / v2;
            case "%":
                var v1:Float = executeExpression(e1, scope);
                var v2:Float = executeExpression(e2, scope);
                v1 % v2;
            case "==":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                v1 == v2;
            case "!=":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                v1 != v2;
            case "<":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                Reflect.compare(v1, v2) < 0;
            case ">":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                Reflect.compare(v1, v2) > 0;
            case "<=":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                Reflect.compare(v1, v2) <= 0;
            case ">=":
                var v1 = executeExpression(e1, scope);
                var v2 = executeExpression(e2, scope);
                Reflect.compare(v1, v2) >= 0;
            case "&&":
                var v1 = executeExpression(e1, scope);
                if (!isTruthy(v1)) return v1;
                executeExpression(e2, scope);
            case "||":
                var v1 = executeExpression(e1, scope);
                if (isTruthy(v1)) return v1;
                executeExpression(e2, scope);
            case "=":
                // Assignment
                var value = executeExpression(e2, scope);
                assignToExpression(e1, value, scope);
                value;
            case _:
                throw 'Unsupported binary operator: ${op}';
        };
    }

    private static function executeCall(e:ExpressionTree, params:Array<ExpressionTree>, scope:ScopeManager):Dynamic {
        var func = executeExpression(e, scope);
        var args = [for (param in params) executeExpression(param, scope)];

        if (Std.isOfType(func, CapturedLambda)) {
            var lambda:CapturedLambda = cast func;
            return executeLambda(lambda, args);
        } else if (Reflect.isFunction(func)) {
            return Reflect.callMethod(null, func, args);
        } else {
            throw 'Cannot call non-function value';
        }
    }

    private static function executeNew(name:String, pack:Array<String>, params:Array<ExpressionTree>, scope:ScopeManager):Dynamic {
        var fullPath = pack.concat([name]).join(".");
        var classType = Type.resolveClass(fullPath);

        if (classType == null) {
            throw 'Class not found: ${fullPath}';
        }

        var args = [for (param in params) executeExpression(param, scope)];
        return Type.createInstance(classType, args);
    }

    private static function executeUnop(op:String, postFix:Bool, e:ExpressionTree, scope:ScopeManager):Dynamic {
        return switch (op) {
            case "-":
                var value:Float = executeExpression(e, scope);
                -value;
            case "+":
                var value:Float = executeExpression(e, scope);
                +value;
            case "!":
                var value = executeExpression(e, scope);
                !isTruthy(value);
            case "++":
                if (postFix) {
                    var oldValue:Float = getVariableValue(e, scope);
                    var newValue = oldValue + 1;
                    assignToExpression(e, newValue, scope);
                    oldValue;
                } else {
                    var oldValue:Float = getVariableValue(e, scope);
                    var newValue = oldValue + 1;
                    assignToExpression(e, newValue, scope);
                    newValue;
                }
            case "--":
                if (postFix) {
                    var oldValue:Float = getVariableValue(e, scope);
                    var newValue = oldValue - 1;
                    assignToExpression(e, newValue, scope);
                    oldValue;
                } else {
                    var oldValue:Float = getVariableValue(e, scope);
                    var newValue = oldValue - 1;
                    assignToExpression(e, newValue, scope);
                    newValue;
                }
            case _:
                throw 'Unsupported unary operator: ${op}';
        };
    }

    private static function executeFor(it:ExpressionTree, expr:ExpressionTree, scope:ScopeManager):Dynamic {
        // TODO: Implement proper for loop handling based on iterator type
        // For now, this is a simplified implementation
        var result:Dynamic = null;
        scope.enterScope("for");

        // This would need more complex logic to handle different iterator types
        // For now, just execute the expression once
        try {
            result = executeExpression(expr, scope);
        } catch (e:LoopBreakException) {
            // Break out of loop
        } catch (e:LoopContinueException) {
            // Continue loop
        }

        scope.exitScope();
        return result;
    }

    private static function executeSwitch(e:ExpressionTree, cases:Array<CaseTree>, edef:ExpressionTree, scope:ScopeManager):Dynamic {
        var value = executeExpression(e, scope);

        for (caseItem in cases) {
            for (caseValue in caseItem.values) {
                var caseResult = executeExpression(caseValue, scope);
                if (value == caseResult) {
                    if (caseItem.guard != null && caseItem.guard != ENull) {
                        if (!isTruthy(executeExpression(caseItem.guard, scope))) {
                            continue;
                        }
                    }
                    return executeExpression(caseItem.expr, scope);
                }
            }
        }

        // Execute default case if no match
        if (edef != null && edef != ENull) {
            return executeExpression(edef, scope);
        }

        return null;
    }

    private static function executeTry(e:ExpressionTree, catches:Array<CatchTree>, scope:ScopeManager):Dynamic {
        try {
            return executeExpression(e, scope);
        } catch (exception:Dynamic) {
            for (catchItem in catches) {
                // TODO: Implement proper type matching for catch clauses
                scope.enterScope("catch");
                scope.setVariable(catchItem.name, exception);
                var result = executeExpression(catchItem.expr, scope);
                scope.exitScope();
                return result;
            }
            throw exception; // Re-throw if no catch clause handles it
        }
    }

    private static function executeLambda(lambda:CapturedLambda, args:Array<Dynamic>):Dynamic {
        var scope = lambda.captureScope.cloneScope();
        scope.enterScope("lambda");

        // Set lambda arguments
        for (i in 0...lambda.func.args.length) {
            var argDef = lambda.func.args[i];
            var value = i < args.length ? args[i] : null; // TODO: Handle default values
            scope.setVariable(argDef.name, value);
        }

        try {
            var result = executeExpression(lambda.func.expr, scope);
            scope.exitScope();
            return result;
        } catch (e:FunctionReturnException) {
            scope.exitScope();
            return e.value;
        }
    }

    // Helper functions

    private static function isTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (Std.isOfType(value, Bool)) return cast value;
        if (Std.isOfType(value, Int)) return cast(value, Int) != 0;
        if (Std.isOfType(value, Float)) return cast(value, Float) != 0.0;
        if (Std.isOfType(value, String)) return cast(value, String) != "";
        return true;
    }

    private static function getVariableValue(expr:ExpressionTree, scope:ScopeManager):Dynamic {
        return switch (expr) {
            case EConst(CIdent(name)):
                scope.getVariable(name);
            case EField(e, field):
                var obj = executeExpression(e, scope);
                Reflect.field(obj, field);
            case EArray(e1, e2):
                var obj = executeExpression(e1, scope);
                var index = executeExpression(e2, scope);
                Reflect.getProperty(obj, Std.string(index));
            case _:
                throw 'Cannot get variable value from expression type';
        };
    }

    private static function assignToExpression(expr:ExpressionTree, value:Dynamic, scope:ScopeManager):Void {
        switch (expr) {
            case EConst(CIdent(name)):
                scope.setVariable(name, value);
            case EField(e, field):
                var obj = executeExpression(e, scope);
                Reflect.setField(obj, field, value);
            case EArray(e1, e2):
                var obj = executeExpression(e1, scope);
                var index = executeExpression(e2, scope);
                Reflect.setProperty(obj, Std.string(index), value);
            case _:
                throw 'Cannot assign to expression type';
        }
    }

    private static function validateInstanceType(instance:Dynamic, expectedClassName:String):Void {
        var instanceClass = Type.getClass(instance);
        if (instanceClass == null) {
            throw 'Instance is not a class instance';
        }

        var instanceClassName = Type.getClassName(instanceClass);
        if (instanceClassName != expectedClassName) {
            throw 'Instance type mismatch. Expected ${expectedClassName}, got ${instanceClassName}';
        }
    }

    private static function validateArguments(expected:Array<CapturedArg>, provided:Array<Dynamic>):Void {
        var requiredCount = 0;
        for (arg in expected) {
            if (!arg.isOptional) requiredCount++;
        }

        if (provided.length < requiredCount) {
            throw 'Not enough arguments provided. Expected at least ${requiredCount}, got ${provided.length}';
        }

        if (provided.length > expected.length) {
            throw 'Too many arguments provided. Expected at most ${expected.length}, got ${provided.length}';
        }
    }

    private static function getDefaultValue(arg:CapturedArg):Dynamic {
        if (arg.defaultValue == null) return null;

        // Parse default value string back to actual value
        // This is a simplified implementation
        return switch (arg.defaultValue) {
            case "null": null;
            case "true": true;
            case "false": false;
            case v if (Std.parseInt(v) != null): Std.parseInt(v);
            case v if (Std.parseFloat(v) != null): Std.parseFloat(v);
            case v: v; // String value
        };
    }
}

/**
 * Exception types for control flow
 */
class FunctionReturnException {
    public var value:Dynamic;
    public function new(value:Dynamic) {
        this.value = value;
    }
}

class LoopBreakException {
    public function new() {}
}

class LoopContinueException {
    public function new() {}
}

/**
 * Captured lambda function representation
 */
class CapturedLambda {
    public var func:FunctionTree;
    public var captureScope:ScopeManager;

    public function new(func:FunctionTree, captureScope:ScopeManager) {
        this.func = func;
        this.captureScope = captureScope;
    }
}
