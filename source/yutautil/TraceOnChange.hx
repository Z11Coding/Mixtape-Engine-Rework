// TraceOnChange.hx
import haxe.macro.Context;
import haxe.macro.Expr;

class TraceOnChange {
    public static function build():Array<Field> {
        var fields:Array<Field> = Context.getBuildFields();
        var newFields:Array<Field> = [];

        for (field in fields) {
            switch (field.kind) {
                case FVar(maybeType, _):
                    var privateName = "_${field.name}";
                    var publicName = field.name;
                    var getType = macro :$maybeType;
                    var privateField:Field = {
                        name: privateName,
                        access: [APrivate],
                        kind: FVar(maybeType, null),
                        pos: Context.currentPos(),
                        meta: []
                    };
                    var getter:Field = {
                        name: 'get_$publicName',
                        access: [AInline, APublic],
                        kind: FFun({
                            args: [],
                            expr: macro return $v{privateName},
                            ret: maybeType
                        }),
                        pos: Context.currentPos(),
                        meta: []
                    };
                    var setter:Field = {
                        name: 'set_$publicName',
                        access: [AInline, APublic],
                        kind: FFun({
                            args: [{name: 'value', type: getType, opt: false}],
                            expr: macro {
                                trace('Value of $publicName changed to: ', value);
                                $v{privateName} = value;
                                return value;
                            },
                            ret: maybeType
                        }),
                        pos: Context.currentPos(),
                        meta: []
                    };
                    newFields.push(privateField);
                    newFields.push(getter);
                    newFields.push(setter);
                case _:
            }
        }
        return newFields;
    }
}