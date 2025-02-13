package yutautil;

#if hscript
import hscript.Parser;
import hscript.Interp;
import haxe.macro.Context;
import haxe.macro.Expr;


class HScriptUtil {
    public static macro function functionToString(func:Dynamic):Expr {
        var func = Context.makeExpr(func, Context.currentPos());
        var funcStr = StringTools.replace(Std.string(func), "function()", "");
        funcStr = StringTools.replace(funcStr, "{", "");
        funcStr = StringTools.replace(funcStr, "}", "");
        return macro funcStr;
    }

    public static function runFunctionFromString(funcStr:String, context:Dynamic):Dynamic {
        var parser = new Parser();
        var interp = new Interp();
        interp.variables.set("context", context);
        var expr = parser.parseString(funcStr);
        return interp.execute(expr);
    }
}
#end
