package states;

import haxe.macro.Context;
import haxe.macro.Expr;

class DebugMacro {
	public static function addDebugMethod():Array<Field> {
		var fields = Context.getBuildFields();
		var debugMethod:Field = {
			name: "debugMethod",
			access: [Access.APublic, Access.AStatic],
			kind: FieldType.FFun({
				args: [],
				expr: macro trace("Debug mode is active."),
				ret: null,
				params: []
			}),
			pos: Context.currentPos(),
			doc: null,
			meta: null
		};
		fields.push(debugMethod);
		return fields;
	}
}

