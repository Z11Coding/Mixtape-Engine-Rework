package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class ChanceValidator {
	public static function checkChanceRange():Void {
		var fields = Context.getLocalClass().get().fields;
		for (field in fields.get()) {
			switch field.kind {
				case FVar(t, e):
					if (field.name == "chance" && field.type == Float) {
						switch e {
							case macro :$v:
								var value = Context.resolveMacroValue(e);
								if (Std.is(value, Float)) {
									var floatValue:Float = cast value;
									if (floatValue < 0 || floatValue > 100) {
										Context.error("Chance value must be between 0 and 100, got " + Std.string(floatValue), field.pos);
									}
								}
							case _: // Ignore if not a literal value
						}
					}
				case _: // Ignore other field kinds
			}
		}
	}
}

