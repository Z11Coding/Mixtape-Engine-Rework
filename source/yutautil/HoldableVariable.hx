package yutautil;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

@:generic
class HoldableVariable {
	public static macro function createVariable(expression:Expr):Expr {
		var exprType = Context.typeof(expression);
		switch exprType {
			case TFun(_, _):
				// If the expression is a function, use it directly
					trace("Creating a Variable with a function: + " + expression);
				return macro new Variable($expression);
			default:
				// Correctly embed the expression within an anonymous function
					var exprStr = Std.string(expression); // Step 1: Convert expression to string
					
					// Step 2 & 3: Check for "unknown" and replace with "extension"
					exprStr = StringTools.replace(exprStr, "(unknown)", "(extension)");
					
					// Step 4: Trace the modified string
					trace("Creating a Variable with an expression: " + exprStr);
				return macro new Variable(function() return $e{expression});
		}
	}
}

