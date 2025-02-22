/**
 * The `FuncEmbed` class provides utility functions for working with function expressions in Haxe.
 * It includes methods to convert function expressions to string representations, execute functions
 * from string representations, and test function expressions for errors.
 *
 * This class is particularly useful when working with dynamic code execution and macro expressions.
 *
 * Methods:
 * - `functionToString(func:Expr, ?unsafe:Bool = false):Expr`: Converts a function expression to its string representation and optionally checks for errors.
 * - `runFunctionFromString(funcStr:String, context:Dynamic, ?run = false):Dynamic`: Executes a function from a string representation within a given context.
 * - `testForErrors(f:Expr):{success:Bool, ?error:Exception}`: Tests the given expression for errors by parsing and executing it.
 */
package yutautil.save;

import haxe.Exception;
#if hscript
import hscript.Parser;
import hscript.Interp;
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;
using StringTools;
using haxe.macro.MacroStringTools;


class FuncEmbed {
    /**
     * Converts a function expression to its string representation and optionally checks for errors.
     *
     * @param func The function expression to convert to a string.
     * @param unsafe Optional boolean flag to skip error checking. Defaults to false. Should only be used when a function needs a context.
     * @return The string representation of the function expression.
     *
     * If `unsafe` is false, the function will check for errors in the function expression.
     * If errors are found, a compile-time error will be raised with the error message.
     */
    public static macro function functionToString(func:Expr, ?unsafe:Bool = false):Expr {
        var funcStr = func.toString();
        if (!unsafe) {
            var result = testForErrors(func);
            if (!result.success) {
                var errorMsg = Std.string(result.error).replace("hscript:", "Line -").replace(":", " -");
                Context.error("Error in function expression: " + errorMsg, func.pos);
            }
        }
        return macro $v{funcStr};
    }

    // public static function functionRefToString(funcRef:String, ?unsafe:Bool = false):String {
    //     var func = Context.getLocalFunction(funcRef);
    //     if (func == null) {
    //         Context.error("Function reference not found: " + funcRef, Context.currentPos());
    //     }
    //     var funcStr = func.toString();
    //     if (!unsafe) {
    //         var result = testForErrors(func);
    //         if (!result.success) {
    //             var errorMsg = Std.string(result.error).replace("hscript:", "Line -").replace(":", " -");
    //             Context.error("Error in function expression: " + errorMsg, func.pos);
    //         }
    //     }
    //     return funcStr;
    // }

    /**
     * Executes a function from a string representation within a given context.
     *
     * @param funcStr The string representation of the function to execute.
     * @param context The context in which the function should be executed.
     * @param run Optional parameter to determine if the function should be executed immediately.
     * @return The result of the function execution, or null if an error occurs.
     */
    public static function runFunctionFromString(funcStr:String, context:Dynamic, ?run = false):Dynamic {
        var parser = new Parser();
        var interp = new Interp();
        interp.variables.set("context", context);

        // Convert the expression string into a format that HScript can read
        var hscriptExprStr = funcStr;
        hscriptExprStr += (run && !hscriptExprStr.endsWith(";") && !hscriptExprStr.endsWith("()")) ? "()" : "";
        var expr = parser.parseString(hscriptExprStr);
        return try {
            interp.execute(expr);
        } catch (e:Dynamic) {
            var errorMsg = Std.string(e).replace("hscript:", "Line -").replace(":", " -");
            trace("Error executing function: " + errorMsg);
            trace("The Expression was: \n" + hscriptExprStr);
            null;
        }
    }

    /**
     * Tests the given expression for errors by parsing and executing it.
     *
     * @param f The expression to test.
     * @return An object containing a success flag and an optional error.
     *         - success: A boolean indicating whether the expression was successfully parsed and executed.
     *         - error: An optional exception object if an error occurred during parsing or execution.
     */
    static function testForErrors(f:Expr):{success:Bool, ?error:Exception}
    {
        var expr = f.toString();
        var parser = new Parser();
        var interp = new Interp();
        var hscriptExprStr = expr;
        
        return try {
            var expr = parser.parseString(hscriptExprStr);
            interp.execute(expr);
            {success: true};
        } catch (e:Dynamic) {
            var errorMsg = Std.string(e).replace("hscript:1: ", "");
            trace("Error parsing function: " + errorMsg + "\n" + hscriptExprStr);
            // Context.error("Error executing function: " + errorMsg, f.pos);
            {success: false, error: (e)};
        }
    }

    // private static function convertToHScriptExpr(exprStr:String):String {
    //     trace("exprStr: " + exprStr);
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.ExprDef.EFunction", "function");
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.FunctionKind.FAnonymous", "");
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.ExprDef.EBlock", "");
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.ExprDef.EReturn", "return");
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.ExprDef.EConst", "");
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.Constant.CString", "");
    //     exprStr = StringTools.replace(exprStr, "haxe.macro.Expr.StringLiteralKind.DoubleQuotes", "");
    //     exprStr = StringTools.replace(exprStr, "ret : null, params : [], expr :", "");
    //     exprStr = StringTools.replace(exprStr, "args : []", "");
    //     exprStr = StringTools.replace(exprStr, "expr :", "");
    //     exprStr = StringTools.replace(exprStr, "(", "");
    //     exprStr = StringTools.replace(exprStr, ")", "");
    //     exprStr = StringTools.replace(exprStr, "[", "");
    //     exprStr = StringTools.replace(exprStr, "]", "");
    //     exprStr = StringTools.replace(exprStr, ",", "");
    //     exprStr = StringTools.replace(exprStr, ":", "");
    //     exprStr = StringTools.replace(exprStr, ";", "");
    //     exprStr = StringTools.trim(exprStr);
    //     trace("Final exprStr: " + exprStr);
    //     return exprStr;
    // }
}
#end
