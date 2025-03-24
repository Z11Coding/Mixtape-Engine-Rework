package lambda;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.Rest;

// Define structured types for lambda expressions
typedef LambdaVar = { name: String };
typedef LambdaAbs = { param: String, body: LambdaExpr };
typedef LambdaApp = { func: LambdaExpr, arg: LambdaExpr };
typedef LambdaExpr = LambdaVar | LambdaAbs | LambdaApp;

class LambdaCalculus {
    /**
     * Parse a string into a structured lambda expression.
     * Example: parse("(λx.λy.(x y))") -> { param: "x", body: { param: "y", body: { func: { name: "x" }, arg: { name: "y" } } } }
     */
    public static function parse(expr:String):LambdaExpr {
        var tokens = tokenize(expr);
        return parseTokens(tokens);
    }

    public static function call(expr:LambdaExpr, arg:LambdaExpr):LambdaExpr {
        return parse({ func: expr, arg: arg });
    }

    /**
     * Reduce a lambda expression using beta reduction.
     * Example: reduce({ func: { param: "x", body: { name: "x" } }, arg: { name: "y" } }) -> { name: "y" }
     */
    public static function reduce(expr:LambdaExpr):LambdaExpr {
        switch expr {
            case { func: { param, body }, arg }:
                return substitute(body, param, arg);
            case { func, arg }:
                return { func: reduce(func), arg: reduce(arg) };
            case { param, body }:
                return { param, body: reduce(body) };
            default:
                return expr;
        }
    }

    /**
     * Convert a structured lambda expression back to a string.
     * Example: toString({ param: "x", body: { param: "y", body: { func: { name: "x" }, arg: { name: "y" } } } }) -> "(λx.λy.(x y))"
     */
    public static function toString(expr:LambdaExpr):String {
        switch expr {
            case { name }:
                return name;
            case { param, body }:
                return "(λ" + param + "." + toString(body) + ")";
            case { func, arg }:
                return "(" + toString(func) + " " + toString(arg) + ")";
        }
    }

    // Helper: Tokenize a string into a list of tokens
    private static function tokenize(expr:String):Array<String> {
        return expr.replace("λ", "\\").split("").filter(c -> !c.match(/\s/));
    }

    // Helper: Parse tokens into a structured lambda expression
    private static function parseTokens(tokens:Array<String>):LambdaExpr {
        if (tokens.length == 0) throw "Unexpected end of input";
        var token = tokens.shift();
        switch token {
            case "(":
                var func = parseTokens(tokens);
                var arg = parseTokens(tokens);
                if (tokens.shift() != ")") throw "Expected ')'";
                return { func, arg };
            case "\\":
                var param = tokens.shift();
                if (tokens.shift() != ".") throw "Expected '.'";
                var body = parseTokens(tokens);
                return { param, body };
            case "Y": // Handle recursion using the Y combinator
                return parseTokens(["(", "\\", "f", ".", "(", "\\", "x", ".", "f", "(", "x", "x", ")", ")", "(", "\\", "x", ".", "f", "(", "x", "x", ")", ")", ")"].concat(tokens));
            default:
                return { name: token };
        }
    }

    // Helper: Substitute a variable with an expression in a lambda body
    private static function substitute(body:LambdaExpr, param:String, value:LambdaExpr):LambdaExpr {
        switch body {
            case { name }:
                return name == param ? value : body;
            case { param: p, body: b }:
                return { param: p, body: p == param ? b : substitute(b, param, value) };
            case { func, arg }:
                return { func: substitute(func, param, value), arg: substitute(arg, param, value) };
        }
    }

    public static macro function lambda(expr:Expr):Expr {
        switch expr {
            case { expr: EConst(c) }:
                return macro LambdaCalculus.parse($v{c});
            default:
                Context.error("Expected a string", expr.pos);
                return macro null;
        }
    }

    public static function succ(n:Int):Int {
        return n + 1;
    }

    public static function pred(n:Int):Int {
        return n - 1;
    }

    /**
     * Macro to convert a function body into a lambda expression.
     * Example:
     * @lambda
     * function example(x, y) return x + y;
     * ->
     * LambdaCalculus.parse("(λx.λy.(x + y))")
     */
    public static macro function simplifyFunction(expr:Expr):Expr {
        switch expr {
            case { expr: EFunction(f) }:
                var params = f.args.map(arg -> arg.name);
                var body = simplifyExpr(f.expr);
                return macro LambdaCalculus.parse($v{buildLambda(params, body)});
            default:
                Context.error("Expected a function", expr.pos);
                return macro null;
        }
    }

    private static function simplifyExpr(expr:Expr):String {
        // Simplify an expression into a string representation of a lambda expression
        switch expr {
            case { expr: EBinop(op, left, right) }:
                return "(" + simplifyExpr(left) + " " + op.toString() + " " + simplifyExpr(right) + ")";
            case { expr: EConst(c) }:
                return c.toString();
            case { expr: EField(obj, field) }:
                return simplifyExpr(obj) + "." + field;
            case { expr: ECall(func, args) }:
                return simplifyExpr(func) + "(" + args.map(simplifyExpr).join(", ") + ")";
            case { expr: EIdent(name) }:
                return name;
            default:
                Context.error("Unsupported expression", expr.pos);
                return "";
        }
    }

    private static function buildLambda(params:Array<String>, body:String):String {
        // Build a lambda expression string from parameters and a body
        return params.foldRight(body, (param, acc) -> "(λ" + param + "." + acc + ")");
    }
}
