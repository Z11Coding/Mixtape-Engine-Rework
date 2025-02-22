import haxe.macro.Context;
import haxe.macro.Expr;

class TraceEverythingMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields(); // Get all fields (methods, variables) of the class being built
		for (field in fields) {
			switch field.kind {
				case FMethod(_, method):
					wrapMethodWithTrace(field, method);
				case _:
			}
		}
		return fields;
	}

	static function wrapMethodWithTrace(field:Field, method:Method):Void {
		var originalExpr = method.expr;
		switch originalExpr {
			case macro function($p) $expr:
				var params = [for (param in $p) param.name];
				var traceExpr = macro trace('Entering ${field.name} with args: ${$v{params}}');
				method.expr = macro {
					$traceExpr;
					$originalExpr;
				};
			case _:
		}
	}
}