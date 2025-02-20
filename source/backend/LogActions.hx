package backend;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;


class LogActions {
	public static function injectLogging(expr:Expr):Expr {
		return switch (expr) {
			case { expr: EBlock(exprs) }:
				{
					expr: EBlock(exprs.map(e -> {
						var logExpr = macro trace('Executing: ' + $v{haxe.macro.Tools.toString(e)});
						return { expr: EBlock([logExpr, e]) };
					}))
				};
			default:
				var logExpr = macro trace('Executing: ' + $v{haxe.macro.Tools.toString(expr)});
				{ expr: EBlock([logExpr, expr]) };
		}
	}

    public static function logActions(expr:Expr):Expr {
        return switch (expr) {
            case { expr: EFunction(f) }:
                var newExpr = {
                    expr: EBlock([
                        macro trace('Entering function: ' + $v{f.name}),
                        injectLogging(f.expr),
                        macro trace('Exiting function: ' + $v{f.name})
                    ])
                };
                { expr: EFunction(f.copy({ expr: newExpr })) };
            default:
                expr;
        }
    }

	public static function processAllClasses() {
		var types = Context.getTypes();
		for (t in types) {
			switch (t) {
				case TClassDecl(classDecl):
					for (field in classDecl.fields) {
						switch (field.kind) {
							case FFun(functionDecl):
								field.expr = logActions(field.expr);
							default:
						}
					}
				default:
			}
		}
	}

	public static function main() {
		processAllClasses();
	}
}

