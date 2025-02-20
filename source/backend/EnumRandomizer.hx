import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.ExprTools;
using backend.ChanceSelector;

class EnumRandomizer {
    public static macro function randomizeEnum(enumType:Expr):Expr {
        var t = Context.getType(enumType.toString());
        switch (t) {
            case TEnum(enumDef, params):
                var fields = enumDef.get().constructs;
                var randomField = fields[Math.floor(Math.random() * fields.length)];
                var fieldType = enumDef.get().statics[randomField];
                return randomizeField(fieldType);
            default:
                Context.error("Provided type is not an enum", enumType.pos);
                return macro null;
        }
    }

    static function randomizeField(fieldType:Type):Expr {
        switch (fieldType) {
            case TFun(args, ret):
                var randomArgs = args.map(function(arg) {
                    return randomizeType(arg.t);
                });
                return macro $v{randomArgs};
            case TInst(c, params):
                Context.error("Cannot randomize typedef or object", Context.currentPos());
                return macro null;
            default:
                return macro $v{Math.random()};
        }
    }

    static function randomizeType(t:Type):Expr {
        switch (t) {
            case TEnum(enumDef, params):
                return randomizeEnum(macro $t{enumDef});
            case TInst(c, params):
                Context.error("Cannot randomize typedef or object", Context.currentPos());
            default:
                return macro $v{Math.random()};
        }
        return null;
    }

    public static macro function randomizeEnumConstant(enumType:Expr):Expr {
        var t = Context.getType(enumType);
        switch (t) {
            case TEnum(enumDef, params):
                var fields = enumDef.get().constructs;
                var fieldArray = fields.map(function(field) {
                    return macro $v{enumType}.$v{field};
                });
                return macro chanceArray($v{fieldArray});
            default:
                Context.error("Provided type is not an enum", enumType.pos);
        }
        return null{
            expr: enumType,
            pos: enumType.pos
        }
    }
}