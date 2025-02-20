import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.*;

class VariableInitializer {
	public static function build():Void {
		Context.onGenerate(function(types) {
			for (type in types) {
				switch (type) {
					case FProp(Variable):
						for (field in c.fields) {
							modifyFieldInitialization(field);
						}
					case _:
				}
			}
		});
	}

	static function modifyFieldInitialization(field:Field):Void {
		switch (field.kind) {
			case FVar(maybeType, optExpr):
				switch (maybeType) {
					case TPath({name: "Variable", pack: []}):
						if (optExpr != null) {
							field.variable = macro HoldableVariable.createVariable($v{optExpr});
						}
					case _:
				}
			case _:
		}
	}
}