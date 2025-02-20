package options;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

class OptionCheck {
	static function processOptions() {
		var shouldError = Context.defined("errorOnMissingVariable");

		Context.onAfterTyping(function(types) {
			for (type in types) {
				if (type.get().isClass()) {
					var fields = type.get().getClass().fields;
					for (field in fields) {
						var fieldType = TypeTools.toComplexType(field.type);
                        if (TypeTools.sameType(fieldType, macro:Option) || TypeTools.sameType(fieldType, macro:ToggleOption)) {
							var init = field.expr;
                            switch (init) {
                                case { expr: ECall({ expr: EField(_, "new") }, args) }:
								var varName = args[2].expr;
								var varType = args[3].expr;
								if (varName.expr == macro:EConst(CString(name))) {
									if (!ClientPrefs.SaveVariables.exists(name)) {
										if (shouldError) {
											Context.error("Variable " + name + " not found in ClientPrefs.SaveVariables", field.pos);
										} else {
											trace("Adding variable " + name + " of type " + varType + " to ClientPrefs.SaveVariables");
											ClientPrefs.SaveVariables.set(name, varType);
										}
									}
								}
							}
						}
					}
				}
			}
		});
	}
}
