import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class ReflectCheck {
	public static function replaceVariableAccesses():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			if (field.kind == FieldType.FFun) {
				field.expr = replaceAccesses(field.expr);
			}
		}
		return fields;
	}

	static function replaceAccesses(expr:Expr):Expr {
		return MacroApi.map(expr, replaceAccess);
	}

	static function replaceAccess(e:Expr):Expr {
		switch (e.expr) {
			case EField(obj, field):
				// Replace obj.field with Reflect.getProperty(obj, "field")
				return macro Reflect.getProperty($obj, $(field.toString()));
			default:
				return e;
		}
	}
}