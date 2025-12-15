package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type;

/**
 * Crash Tracker Macro - Automatically injects monitoring code into classes
 * to track engine activity and help diagnose unexpected crashes
 *
 * WARNING: This macro instruments methods to track engine activity.
 * It may affect performance and should be used primarily for debugging.
 * Inline functions are ignored to prevent compilation issues.
 */
class CrashTracker {
    private static var instrumentedClasses:Array<String> = [];
    private static var activated:Bool = false;
    private static var baseInfrastructureClass:String = null; // Track which class has the infrastructure

    // Configuration flags - set these before compilation to enable features
    public static var ENABLE_DETAILED_EXPRESSION_TRACKING:Bool = true; // Re-enabled with safer expression handling
    public static var ENABLE_FUNCTION_WRAPPING:Bool = true; // Re-enabled
    public static var ENABLE_COMMAND_EXIT_TRACKING:Bool = true; // Re-enabled
    public static var ENABLE_VARIABLE_ACCESS_TRACKING:Bool = true; // Re-enabled with safer variable handling
    public static var ENABLE_COMPILATION_TRACING:Bool = #if verbose true #else false #end; // Re-enabled for debugging
    public static var ENABLE_DETAILED_COMPILATION_TRACING:Bool = #if verbose true #else false #end; // Re-enabled for debugging

    /**
     * Macro to inject crash tracking into a class
     * Usage: @:autoBuild(yutautil.CrashTracker.instrument())
     * To exclude a class from instrumentation, add @:noCrashTracker metadata to the class
     */
    public static macro function instrument():Array<Field> {
        if (!activated) {
            activated = true;
            trace('CrashTracker: Starting instrumentation...');
        }

        var localClass = Context.getLocalClass().get();
        var className = localClass.name;
        var fullClassName = localClass.pack.join(".") + "." + className;

        // Check if the class has @:noCrashTracker metadata to exclude it from instrumentation
        if (localClass.meta.has(":noCrashTracker")) {
            if (ENABLE_COMPILATION_TRACING) {
                trace('CrashTracker: Skipping class $fullClassName (has @:noCrashTracker metadata)');
            }
            return null; // Return null to skip instrumentation
        }

        if (instrumentedClasses.indexOf(fullClassName) != -1) {
            return null; // Already instrumented
        }

        instrumentedClasses.push(fullClassName);

        // Determine if this is the base infrastructure class
        var isBaseInfrastructureClass = (baseInfrastructureClass == null);
        if (isBaseInfrastructureClass) {
            baseInfrastructureClass = fullClassName;
            #if verbose trace('CrashTracker: Setting up base infrastructure in $fullClassName'); #end
        } else {
            #if verbose trace('CrashTracker: Instrumenting functions in $fullClassName'); #end
        }

        var fields = Context.getBuildFields();
        var newFields:Array<Field> = [];

        // Only the first class gets the infrastructure
        if (isBaseInfrastructureClass) {
            newFields.push(createTrackingField());
        }

        // Process existing fields
        for (field in fields) {
            switch (field.kind) {
                case FFun(func):
                    // Debug: Log what we're checking
                    var isInline = hasInlineMetadata(field);
                    var shouldInstrument = shouldInstrumentFunction(field.name, func);

                    if (ENABLE_COMPILATION_TRACING) {
                        trace('CrashTracker: Checking function ${field.name} in $fullClassName');
                        trace('  - Is inline: $isInline');
                        trace('  - Should instrument: $shouldInstrument');
                        if (func.expr != null) {
                            trace('  - Expression type: ${func.expr.expr}');
                            trace('Expression as String: \n${haxe.macro.ExprTools.toString(func.expr)}');
                        }
                    }

                    if (isInline) {
                        if (ENABLE_COMPILATION_TRACING) {
                            trace('CrashTracker: Skipping inline function ${field.name} in $fullClassName');
                        }
                    } else if (!shouldInstrument) {
                        if (ENABLE_COMPILATION_TRACING) {
                            trace('CrashTracker: Skipping function ${field.name} in $fullClassName (filtered out)');
                        }
                    } else {
                        if (ENABLE_COMPILATION_TRACING) {
                            trace('CrashTracker: Instrumenting function ${field.name} in $fullClassName');
                        }
                        var isStatic = field.access.indexOf(AStatic) != -1;
                        field.kind = FFun(instrumentFunction(func, fullClassName, field.name, isStatic, isBaseInfrastructureClass));
                    }
                case _:
                    // Keep other fields as-is
                    if (ENABLE_COMPILATION_TRACING) {
                        trace('CrashTracker: Keeping non-function field ${field.name} in $fullClassName');
                    }
            }
            newFields.push(field);
        }

        // Only the base infrastructure class gets the _initCrashTracking method
        if (isBaseInfrastructureClass) {
            newFields.push(createCleanupMethod(fullClassName));
        }

        return newFields;
    }

    #if macro
    private static function createTrackingField():Field {
        return {
            name: "_crashTrackerInit",
            pos: Context.currentPos(),
            kind: FVar(macro:Bool, macro false),
            access: [APrivate]
        };
    }

    private static function createCleanupMethod(className:String):Field {
        var cleanupExpr = macro {
            if (!_crashTrackerInit) {
                _crashTrackerInit = true;
                yutautil.CrashReporter.registerInstance($v{className}, this);
            }
        };

        return {
            name: "_initCrashTracking",
            pos: Context.currentPos(),
            kind: FFun({
                args: [],
                ret: macro:Void,
                expr: cleanupExpr
            }),
            access: [APrivate]
        };
    }

    private static function shouldInstrumentFunction(funcName:String, func:Function):Bool {
        // Skip certain functions to avoid overhead
        var skipFunctions = [
            "new", "toString", "get_", "set_", "_get", "_set",
            "_crashTracker", "_initCrashTracking", "destroy"
        ];

        for (skip in skipFunctions) {
            if (funcName.indexOf(skip) == 0) {
                if (ENABLE_COMPILATION_TRACING) {
                    trace('CrashTracker: Skipping function $funcName (in skip list)');
                }
                return false;
            }
        }

        // Skip macro functions - check for macro metadata
        #if macro
        try {
            var localClass = Context.getLocalClass().get();
            var classField = null;
            for (field in localClass.fields.get()) {
                if (field.name == funcName) {
                    classField = field;
                    break;
                }
            }

            if (classField != null && classField.meta.has(":macro")) {
                if (ENABLE_COMPILATION_TRACING) {
                    trace('CrashTracker: Skipping macro function $funcName');
                }
                return false;
            }
        } catch (e:Dynamic) {
            // If we can't check, proceed with caution
            if (ENABLE_COMPILATION_TRACING) {
                trace('CrashTracker: Could not check macro status for $funcName: $e');
            }
        }
        #end

        return true;
    }

    private static function hasInlineMetadata(field:Field):Bool {
        // Check field metadata for :inline
        if (field.meta != null) {
            for (meta in field.meta) {
                if (meta.name == ":inline" || meta.name == "inline") {
                    Context.warning('CrashTracker: Skipping inline function ${field.name}', Context.currentPos());
                    return true;
                }
            }
        }

        // Also check if the field has inline access modifier
        if (field.access != null) {
            for (access in field.access) {
                if (access == AInline) {
                    Context.warning('CrashTracker: Skipping inline function ${field.name} (access modifier)', Context.currentPos());
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Check if an expression contains a return statement
     */
    private static function containsReturnStatement(expr:Expr):Bool {
        if (expr == null) return false;

        switch (expr.expr) {
            case EReturn(_):
                return true;
            case EBlock(exprs):
                for (e in exprs) {
                    if (containsReturnStatement(e)) return true;
                }
            case EIf(_, ifExpr, elseExpr):
                if (containsReturnStatement(ifExpr)) return true;
                if (elseExpr != null && containsReturnStatement(elseExpr)) return true;
            case ESwitch(_, cases, defaultExpr):
                if (cases != null) {
                    for (c in cases) {
                        if (c != null && c.expr != null && containsReturnStatement(c.expr)) return true;
                    }
                }
                // More careful handling of defaultExpr to avoid null access
                try {
                    if (defaultExpr != null && containsReturnStatement(defaultExpr)) return true;
                } catch (e:Dynamic) {
                    trace("For some reason, cannot read defaultExpr: " + defaultExpr);
                }
            case ETry(tryExpr, catches):
                if (containsReturnStatement(tryExpr)) return true;
                if (catches != null) {
                    for (c in catches) {
                        if (c != null && c.expr != null && containsReturnStatement(c.expr)) return true;
                    }
                }
            case EWhile(_, bodyExpr, _):
                if (containsReturnStatement(bodyExpr)) return true;
            case EFor(_, bodyExpr):
                if (containsReturnStatement(bodyExpr)) return true;
            case EFunction(_, func):
                // Don't check inside nested functions
                return false;
            case _:
                // For other expression types, we'll assume no returns for simplicity
        }
        return false;
    }

    /**
     * Analyze and describe what an expression is doing for detailed tracking
     */
    private static function analyzeExpressionAction(expr:Expr):String {
        if (expr == null) return "null_expression";

        return switch (expr.expr) {
            case EConst(c):
                switch (c) {
                    case CInt(v): 'constant_int_$v';
                    case CFloat(f): 'constant_float_$f';
                    case CString(s): 'constant_string_${s.length > 20 ? s.substr(0, 17) + "..." : s}';
                    case CIdent(s): 'accessing_$s';
                    case CRegexp(_): "constant_regex";
                    case _: "constant_value";
                }
            case EArray(e1, e2): "array_access";
            case EBinop(op, e1, e2):
                var opStr = switch (op) {
                    case OpAdd: "addition";
                    case OpMult: "multiplication";
                    case OpDiv: "division";
                    case OpSub: "subtraction";
                    case OpAssign: "assignment";
                    case OpEq: "equality_check";
                    case OpNotEq: "inequality_check";
                    case OpLt: "less_than";
                    case OpLte: "less_than_equal";
                    case OpGt: "greater_than";
                    case OpGte: "greater_than_equal";
                    case OpAnd: "logical_and";
                    case OpOr: "logical_or";
                    case OpBoolAnd: "boolean_and";
                    case OpBoolOr: "boolean_or";
                    case OpShl: "shift_left";
                    case OpShr: "shift_right";
                    case OpUShr: "unsigned_shift_right";
                    case OpMod: "modulo";
                    case OpAssignOp(aop): 'assignment_${aop}';
                    case OpInterval: "interval";
                    case OpArrow: "arrow";
                    case OpIn: "in_operator";
                    case OpNullCoal: "null_coalescing";
                    case _: "binary_operation";
                }
                'binary_op_$opStr';
            case EField(e, field): 'field_access_$field';
            case EParenthesis(e): "parentheses";
            case EObjectDecl(fields): "object_creation";
            case EArrayDecl(values): "array_creation";
            case ECall(e, params):
                var callTarget = switch (e.expr) {
                    case EField(_, field): 'method_$field';
                    case EConst(CIdent(name)): 'function_$name';
                    case _: "function_call";
                }
                'calling_$callTarget';
            case ENew(t, params): 'creating_new_${t.name}';
            case EUnop(op, postFix, e):
                var opStr = switch (op) {
                    case OpIncrement: "increment";
                    case OpDecrement: "decrement";
                    case OpNot: "logical_not";
                    case OpNeg: "negation";
                    case OpNegBits: "bitwise_not";
                    case OpSpread: "spread";
                    case _: "unary_operation";
                }
                'unary_op_$opStr';
            case EVars(vars):
                var varNames = [for (v in vars) v.name].join(",");
                'declaring_vars_$varNames';
            case EFunction(kind, f):
                switch (kind) {
                    case FAnonymous: 'declaring_function_anon';
                    case FNamed(name, _): 'declaring_function_$name';
                    case FArrow: 'declaring_function_lambda';
                    case _: 'declaring_function_unknown';
                }
            case EBlock(exprs): "code_block";
            case EFor(it, expr): "for_loop";
            case EIf(econd, eif, eelse): "if_statement";
            case EWhile(econd, e, normalWhile): "while_loop";
            case ESwitch(e, cases, edef): "switch_statement";
            case ETry(e, catches): "try_catch";
            case EReturn(e): e != null ? "returning_value" : "returning_void";
            case EBreak: "break_statement";
            case EContinue: "continue_statement";
            case EUntyped(e): "untyped_expression";
            case EThrow(e): "throwing_exception";
            case ECast(e, t): "type_casting";
            case EDisplay(e, displayKind): "display_expression";
            case ETernary(econd, eif, eelse): "ternary_operator";
            case ECheckType(e, t): "type_check";
            case EMeta(s, e): 'meta_${s.name}';
            case EIs(e, t): "is_type_check";
            case _: "unknown_expression";
        }
    }

    /**
     * Extract variable information from expressions for tracking
     */
    private static function extractVariableInfo(expr:Expr):{name:String, accessType:String, value:String} {
        if (expr == null) return null;

        return switch (expr.expr) {
            case EConst(CIdent(name)): {name: name, accessType: "read", value: "unknown"};
            case EBinop(OpAssign, {expr: EConst(CIdent(name))}, valueExpr):
                {name: name, accessType: "write", value: getExpressionValueString(valueExpr)};
            case EBinop(OpAssign, {expr: EField(_, field)}, valueExpr):
                {name: field, accessType: "write", value: getExpressionValueString(valueExpr)};
            case EField(_, field): {name: field, accessType: "read", value: "unknown"};
            case EVars(vars) if (vars.length > 0):
                var v = vars[0];
                {name: v.name, accessType: "declare", value: v.expr != null ? getExpressionValueString(v.expr) : "null"};
            case _: null;
        }
    }

    /**
     * Get string representation of expression value
     */
    private static function getExpressionValueString(expr:Expr):String {
        if (expr == null) return "null";

        return switch (expr.expr) {
            case EConst(c):
                switch (c) {
                    case CInt(v): Std.string(v);
                    case CFloat(f): Std.string(f);
                    case CString(s): '"$s"';
                    case CIdent(name): name;
                    case _: "constant";
                }
            case ENew(t, _): 'new ${t.name}()';
            case ECall(e, _): 'call(${getExpressionValueString(e)})';
            case _: "expression";
        }
    }

    /**
     * Get position information from expression at compile time
     */
    private static function getPositionString(pos:Position):String {
        #if macro
        try {
            var posInfo = Context.getPosInfos(pos);
            return '${posInfo.file}:${posInfo.min}-${posInfo.max}';
        } catch (e:Dynamic) {
            return "unknown_position";
        }
        #else
        return "runtime_position";
        #end
    }

    /**
     * Create a compile-time string literal for position info
     */
    private static function createPositionLiteral(pos:Position):Expr {
        #if macro
        var posString = getPositionString(pos);
        return macro $v{posString};
        #else
        return macro "runtime_position";
        #end
    }

    /**
     * Wrap individual expressions with detailed tracking
     */
    private static function wrapExpressionWithDetailedTracking(expr:Expr, className:String, funcName:String, exprIndex:Int):Expr {
        if (expr == null) return expr;
        if (!ENABLE_DETAILED_EXPRESSION_TRACKING) return expr;

        // Don't wrap expressions that break identifier resolution
        var shouldSkipWrapping = switch (expr.expr) {
            case EVars(_): true;  // Never wrap variable declarations
            case EConst(CIdent(_)): true;  // Never wrap variable access/identifiers
            case EField(_, _): true;  // Don't wrap field access to avoid breaking member access
            case EBinop(OpAssign, _, _): true;  // Don't wrap assignments to avoid breaking variable setting
            case EFunction(_, _): true;  // Don't wrap function declarations
            case _: false;
        };

        if (shouldSkipWrapping) {
            // Just log the variable access but don't wrap the expression
            if (ENABLE_VARIABLE_ACCESS_TRACKING) {
                var varInfo = extractVariableInfo(expr);
                if (varInfo != null) {
                    var varLogCall = {
                        expr: ECall({
                            expr: EField({
                                expr: EField({
                                    expr: EConst(CIdent("yutautil")),
                                    pos: Context.currentPos()
                                }, "CrashReporter"),
                                pos: Context.currentPos()
                            }, "logVariableAccess"),
                            pos: Context.currentPos()
                        }, [
                            {expr: EConst(CString(className)), pos: Context.currentPos()},
                            {expr: EConst(CString(funcName)), pos: Context.currentPos()},
                            {expr: EConst(CString(varInfo.name)), pos: Context.currentPos()},
                            {expr: EConst(CString(varInfo.accessType)), pos: Context.currentPos()},
                            {expr: EConst(CString(varInfo.value)), pos: Context.currentPos()},
                            createPositionLiteral(expr.pos)
                        ]),
                        pos: Context.currentPos()
                    };

                    // Return a block with logging before the original expression
                    return {
                        expr: EBlock([varLogCall, expr]),
                        pos: Context.currentPos()
                    };
                }
            }
            return expr; // Return as-is if no variable tracking needed
        }

        var action = analyzeExpressionAction(expr);
        var trackingAction = 'expr_${exprIndex}_$action';
        var positionLiteral = createPositionLiteral(expr.pos);

        // Create logging call using proper expression construction
        var logCall = {
            expr: ECall({
                expr: EField({
                    expr: EField({
                        expr: EConst(CIdent("yutautil")),
                        pos: Context.currentPos()
                    }, "CrashReporter"),
                    pos: Context.currentPos()
                }, "logExpressionExecution"),
                pos: Context.currentPos()
            }, [
                {expr: EConst(CString(className)), pos: Context.currentPos()},
                {expr: EConst(CString(funcName)), pos: Context.currentPos()},
                {expr: EConst(CString(trackingAction)), pos: Context.currentPos()}
            ]),
            pos: Context.currentPos()
        };

        // For safe expressions (function calls, operations), add logging before execution
        return {
            expr: EBlock([logCall, expr]),
            pos: Context.currentPos()
        };
    }

    /**
     * Process expressions in a block for detailed tracking
     */
    private static function processExpressionsForDetailedTracking(expr:Expr, className:String, funcName:String):Expr {
        if (!ENABLE_DETAILED_EXPRESSION_TRACKING) return expr;

        return switch (expr.expr) {
            case EBlock(exprs):
                var wrappedExprs = [];
                for (i in 0...exprs.length) {
                    var originalExpr = exprs[i];
                    // Be very conservative - only track certain safe expressions
                    var shouldTrack = switch (originalExpr.expr) {
                        case EVars(_): false; // Never track variable declarations
                        case EConst(_): false; // Don't track constants or identifiers
                        case EFunction(_, _): false; // Don't track function declarations
                        case EField(_, _): false; // Don't track field access
                        case EBinop(OpAssign, _, _): false; // Don't track assignments
                        case ECall(_, _): true; // Only track function calls
                        case ENew(_, _): true; // Only track object creation
                        case EUnop(_, _, _): true; // Only track unary operations
                        case EBinop(op, _, _): // Only track non-assignment binary operations
                            switch (op) {
                                case OpAssign | OpAssignOp(_): false;
                                case _: true;
                            }
                        case _: false; // Conservative default - don't track
                    }

                    if (shouldTrack) {
                        wrappedExprs.push(wrapExpressionWithDetailedTracking(originalExpr, className, funcName, i));
                    } else {
                        wrappedExprs.push(originalExpr); // Keep original without tracking
                    }
                }
                {expr: EBlock(wrappedExprs), pos: expr.pos};
            case _:
                // For non-block expressions, be conservative and don't wrap problematic ones
                var shouldTrack = switch (expr.expr) {
                    case EVars(_): false;
                    case EConst(_): false;
                    case EFunction(_, _): false;
                    case EField(_, _): false;
                    case EBinop(OpAssign, _, _): false;
                    case _: true;
                };

                if (shouldTrack) {
                    wrapExpressionWithDetailedTracking(expr, className, funcName, 0);
                } else {
                    expr; // Return as-is
                }
        };
    }

    /**
     * Recursively process expressions to find and track internal functions
     */
    private static function processInternalFunctions(expr:Expr, className:String, parentFuncName:String):Expr {
        if (expr == null || !ENABLE_FUNCTION_WRAPPING) return expr;

        return switch (expr.expr) {
            case EFunction(kind, f):
                // Found an internal function - instrument it
                var internalFuncName = switch (kind) {
                    case FAnonymous: '${parentFuncName}_anon';
                    case FNamed(name, _): '${parentFuncName}_$name';
                    case FArrow: '${parentFuncName}_lambda';
                    case _: '${parentFuncName}_internal';
                }

                // Instrument the internal function
                var instrumentedFunc = instrumentFunction(f, className, internalFuncName, false, false);
                {expr: EFunction(kind, instrumentedFunc), pos: expr.pos};

            case EBlock(exprs):
                var processedExprs = [for (e in exprs) processInternalFunctions(e, className, parentFuncName)];
                {expr: EBlock(processedExprs), pos: expr.pos};

            case EIf(condExpr, ifExpr, elseExpr):
                var processedIf = processInternalFunctions(ifExpr, className, parentFuncName);
                var processedElse = elseExpr != null ? processInternalFunctions(elseExpr, className, parentFuncName) : null;
                {expr: EIf(condExpr, processedIf, processedElse), pos: expr.pos};

            case ESwitch(switchExpr, cases, defaultExpr):
                var processedCases = [];
                for (c in cases) {
                    processedCases.push({
                        values: c.values,
                        guard: c.guard,
                        expr: processInternalFunctions(c.expr, className, parentFuncName)
                    });
                }
                // More careful handling of defaultExpr to avoid null access
                var processedDefault = null;
                try {
                    processedDefault = defaultExpr != null ? processInternalFunctions(defaultExpr, className, parentFuncName) : null;
                } catch (e:Dynamic) {
                    trace("There was probably no default here...");
                    processedDefault = defaultExpr;
                }
                {expr: ESwitch(switchExpr, processedCases, processedDefault), pos: expr.pos};

            case ETry(tryExpr, catches):
                var processedTry = processInternalFunctions(tryExpr, className, parentFuncName);
                var processedCatches = [];
                for (c in catches) {
                    processedCatches.push({
                        name: c.name,
                        type: c.type,
                        expr: processInternalFunctions(c.expr, className, parentFuncName)
                    });
                }
                {expr: ETry(processedTry, processedCatches), pos: expr.pos};

            case EWhile(condExpr, bodyExpr, normalWhile):
                var processedBody = processInternalFunctions(bodyExpr, className, parentFuncName);
                {expr: EWhile(condExpr, processedBody, normalWhile), pos: expr.pos};

            case EFor(iterExpr, bodyExpr):
                var processedBody = processInternalFunctions(bodyExpr, className, parentFuncName);
                {expr: EFor(iterExpr, processedBody), pos: expr.pos};

            case _:
                expr; // Return as-is for other expression types
        };
    }

    /**
     * Wrap an expression to add exit logging before any return statements
     */
    private static function wrapExpressionWithLogging(expr:Expr, className:String, funcName:String):Expr {
        if (expr == null) return expr;

        return switch (expr.expr) {
            case EReturn(returnExpr):
                var exitCall = {
                    expr: ECall({
                        expr: EField({
                            expr: EField({
                                expr: EConst(CIdent("yutautil")),
                                pos: Context.currentPos()
                            }, "CrashReporter"),
                            pos: Context.currentPos()
                        }, "logActivity"),
                        pos: Context.currentPos()
                    }, [
                        {expr: EConst(CString(className)), pos: Context.currentPos()},
                        {expr: EConst(CString(funcName)), pos: Context.currentPos()},
                        {expr: EConst(CString("exit")), pos: Context.currentPos()}
                    ]),
                    pos: Context.currentPos()
                };

                if (returnExpr != null) {
                    {
                        expr: EBlock([
                            exitCall,
                            {expr: EReturn(returnExpr), pos: Context.currentPos()}
                        ]),
                        pos: Context.currentPos()
                    };
                } else {
                    {
                        expr: EBlock([
                            exitCall,
                            {expr: EReturn(null), pos: Context.currentPos()}
                        ]),
                        pos: Context.currentPos()
                    };
                }
            case EBlock(exprs):
                var wrappedExprs = [];
                for (e in exprs) {
                    wrappedExprs.push(wrapExpressionWithLogging(e, className, funcName));
                }
                {expr: EBlock(wrappedExprs), pos: expr.pos};
            case EIf(condExpr, ifExpr, elseExpr):
                var wrappedIf = wrapExpressionWithLogging(ifExpr, className, funcName);
                var wrappedElse = elseExpr != null ? wrapExpressionWithLogging(elseExpr, className, funcName) : null;
                {expr: EIf(condExpr, wrappedIf, wrappedElse), pos: expr.pos};
            case ESwitch(switchExpr, cases, defaultExpr):
                var wrappedCases = [];
                for (c in cases) {
                    wrappedCases.push({
                        values: c.values,
                        guard: c.guard,
                        expr: wrapExpressionWithLogging(c.expr, className, funcName)
                    });
                }
                // More careful handling of defaultExpr to avoid null access
                var wrappedDefault = null;
                try {
                    wrappedDefault = defaultExpr != null ? wrapExpressionWithLogging(defaultExpr, className, funcName) : null;
                } catch (e:Dynamic) {
                    // Skip defaultExpr if it causes issues
                    trace("There was probably no default here...");
                    wrappedDefault = defaultExpr;
                }
                {expr: ESwitch(switchExpr, wrappedCases, wrappedDefault), pos: expr.pos};
            case ETry(tryExpr, catches):
                var wrappedTry = wrapExpressionWithLogging(tryExpr, className, funcName);
                var wrappedCatches = [];
                for (c in catches) {
                    wrappedCatches.push({
                        name: c.name,
                        type: c.type,
                        expr: wrapExpressionWithLogging(c.expr, className, funcName)
                    });
                }
                {expr: ETry(wrappedTry, wrappedCatches), pos: expr.pos};
            case EWhile(condExpr, bodyExpr, normalWhile):
                var wrappedBody = wrapExpressionWithLogging(bodyExpr, className, funcName);
                {expr: EWhile(condExpr, wrappedBody, normalWhile), pos: expr.pos};
            case EFor(iterExpr, bodyExpr):
                var wrappedBody = wrapExpressionWithLogging(bodyExpr, className, funcName);
                {expr: EFor(iterExpr, wrappedBody), pos: expr.pos};
            case _:
                expr; // Return as-is for other expression types
        };
    }

    private static function instrumentFunction(func:Function, className:String, funcName:String, isStatic:Bool, hasInfrastructure:Bool):Function {
        var originalExpr = func.expr;
        var returnType = func.ret;

        // Apply detailed expression tracking if enabled
        var processedExpr = processExpressionsForDetailedTracking(originalExpr, className, funcName);

        // Process internal functions if function wrapping is enabled
        if (ENABLE_FUNCTION_WRAPPING) {
            processedExpr = processInternalFunctions(processedExpr, className, funcName);
        }

        // Determine if this is a void function
        var isVoidFunction = switch (returnType) {
            case TPath({name: "Void", pack: []}): true;
            case null: true; // No explicit return type usually means void
            case _: false;
        };

        // Check if the original expression contains a return statement
        var hasReturnStatement = containsReturnStatement(originalExpr);

        // Create enter logging call
        var enterCall = {
            expr: ECall({
                expr: EField({
                    expr: EField({
                        expr: EConst(CIdent("yutautil")),
                        pos: Context.currentPos()
                    }, "CrashReporter"),
                    pos: Context.currentPos()
                }, "logActivity"),
                pos: Context.currentPos()
            }, [
                {expr: EConst(CString(className)), pos: Context.currentPos()},
                {expr: EConst(CString(funcName)), pos: Context.currentPos()},
                {expr: EConst(CString("enter")), pos: Context.currentPos()}
            ]),
            pos: Context.currentPos()
        };

        // Create exit logging call
        var exitCall = {
            expr: ECall({
                expr: EField({
                    expr: EField({
                        expr: EConst(CIdent("yutautil")),
                        pos: Context.currentPos()
                    }, "CrashReporter"),
                    pos: Context.currentPos()
                }, "logActivity"),
                pos: Context.currentPos()
            }, [
                {expr: EConst(CString(className)), pos: Context.currentPos()},
                {expr: EConst(CString(funcName)), pos: Context.currentPos()},
                {expr: EConst(CString("exit")), pos: Context.currentPos()}
            ]),
            pos: Context.currentPos()
        };

        // Create instrumented expression based on function type
        var instrumentedExpr = if (isVoidFunction) {
            if (hasReturnStatement) {
                // Void function with early returns - wrap to track exits
                var finalWrappedExpr = wrapExpressionWithLogging(processedExpr, className, funcName);
                {
                    expr: EBlock([
                        enterCall,
                        finalWrappedExpr,
                        exitCall
                    ]),
                    pos: Context.currentPos()
                };
            } else {
                // Void function without early returns - simple wrapper
                {
                    expr: EBlock([
                        enterCall,
                        processedExpr,
                        exitCall
                    ]),
                    pos: Context.currentPos()
                };
            }
        } else {
            if (hasReturnStatement) {
                // Function has explicit return - wrap the whole thing
                var finalWrappedExpr = wrapExpressionWithLogging(processedExpr, className, funcName);
                {
                    expr: EBlock([
                        enterCall,
                        finalWrappedExpr
                    ]),
                    pos: Context.currentPos()
                };
            } else {
                // Function without explicit return - evaluate and return the result
                {
                    expr: EBlock([
                        enterCall,
                        {
                            expr: EVars([{
                                name: "__result",
                                type: returnType,
                                expr: processedExpr
                            }]),
                            pos: Context.currentPos()
                        },
                        exitCall,
                        {
                            expr: EReturn({
                                expr: EConst(CIdent("__result")),
                                pos: Context.currentPos()
                            }),
                            pos: Context.currentPos()
                        }
                    ]),
                    pos: Context.currentPos()
                };
            }
        };

        return {
            args: func.args,
            ret: returnType, // Preserve original return type exactly
            expr: instrumentedExpr,
            params: func.params
        };
    }
    #end

    /**
     * Get list of instrumented classes
     */
    public static inline function getInstrumentedClasses():Array<String> {
        return instrumentedClasses.copy();
    }
}

@:autoBuild(yutautil.CrashTracker.instrument())
interface CrashMonitor {}
