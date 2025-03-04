package backend.modules;

import haxe.macro.Expr;
import haxe.macro.Context;

class TimeFormatMacro {
	public static macro function fromExpression(expr:Expr):Expr {
		switch expr.expr {
			case EConst(CString(text)):
				var parts = text.split(":");
				var minutes = Std.parseInt(parts[0]);
				var seconds = 0;
				var decimals = 0;

				if (parts.length > 1) {
					var secondsParts = parts[1].split(".");
					seconds = Std.parseInt(secondsParts[0]);
					if (secondsParts.length > 1) {
						var decimalsString = secondsParts[1];
						decimals = Std.parseInt(decimalsString);
						decimals = decimals * Math.pow(10, 3 - decimalsString.length);
					}
				}

				return macro new TimeFormat($v{minutes}, $v{seconds}, $v{decimals});
			default:
				Context.error("Expected a string literal", expr.pos);
				return macro null;
		}
	}
}

